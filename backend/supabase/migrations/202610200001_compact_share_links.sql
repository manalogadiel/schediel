-- Resolve compact links by their full 256-bit capability digest. No raw token
-- is stored, and bearer material remains outside web-server request URLs.
create index share_links_token_digest on schediel_private.share_links(token_digest);

create or replace function schediel_private.resolve_share(p_id uuid,p_digest text,p_supported text[],p_address_hash text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare s schediel_private.share_links; rate jsonb; m jsonb;
begin
  if p_digest is null or p_digest !~ '^[0-9a-f]{64}$' then return jsonb_build_object('code','invalid_token'); end if;
  if p_supported is null or cardinality(p_supported) not between 1 and 5 then return jsonb_build_object('code','invalid_request'); end if;
  rate:=schediel_private.take_rate('resolve',p_address_hash);
  if rate ? 'code' then return rate; end if;
  -- Rate-limit before either lookup. Strict selection fails closed in the
  -- unlikely event of duplicate capabilities; legacy ID links remain scoped.
  begin
    if p_id is null then
      select * into strict s from schediel_private.share_links where token_digest=p_digest for update;
    else
      select * into strict s from schediel_private.share_links where id=p_id for update;
    end if;
  exception when no_data_found or too_many_rows then
    return jsonb_build_object('code','not_found');
  end;
  if not schediel_private.digest_matches(s.token_digest,p_digest) then return jsonb_build_object('code','not_found'); end if;
  if s.revoked_at is not null then return jsonb_build_object('code','link_revoked'); end if;
  if s.expires_at<=clock_timestamp() then return jsonb_build_object('code','link_expired'); end if;
  if s.schema_version<>all(p_supported) then return jsonb_build_object('code','unsupported_schema_version'); end if;
  m:=schediel_private.share_metadata(s);
  return jsonb_build_object('data',jsonb_build_object('shareId',s.id,'schemaVersion',s.schema_version,'snapshotVersion',s.snapshot_version,
    'createdAt',m->'createdAt','expiresAt',m->'expiresAt','itemCount',s.item_count,'payload',s.payload));
end $$;
