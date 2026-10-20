-- A received capability grants read access, not permission to replace its
-- destination. Keep only its digest reserved even after snapshot deletion.
create table schediel_private.reserved_share_capabilities (
  digest text primary key check (digest ~ '^[0-9a-f]{64}$')
);
alter table schediel_private.reserved_share_capabilities enable row level security;
revoke all on schediel_private.reserved_share_capabilities from public, anon, authenticated, service_role;
insert into schediel_private.reserved_share_capabilities(digest)
select distinct token_digest from schediel_private.share_links;

alter function schediel_private.create_share(uuid,text,text,jsonb,text,timestamptz,integer)
rename to create_share_unreserved;
revoke all on function schediel_private.create_share_unreserved(uuid,text,text,jsonb,text,timestamptz,integer)
from public, anon, authenticated, service_role;

create function schediel_private.create_share(p_owner uuid,p_key_hash text,p_request_hash text,p_payload jsonb,p_digest text,p_expires timestamptz,p_bytes integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare outcome jsonb;
begin
  -- The inner operation retains its quota locks, ownership checks and exact
  -- idempotency semantics. The reservation and snapshot commit atomically.
  begin
    outcome := schediel_private.create_share_unreserved(p_owner,p_key_hash,p_request_hash,p_payload,p_digest,p_expires,p_bytes);
    if outcome ? 'code' or outcome->>'replayed' = 'true' then return outcome; end if;
    insert into schediel_private.reserved_share_capabilities(digest) values(p_digest);
    return outcome;
  exception when unique_violation then
    -- This subtransaction also rolls back the new snapshot, quotas and retry
    -- record. Never overwrite, revoke, or reveal the existing destination.
    return jsonb_build_object('code','invalid_request');
  end;
end $$;
revoke all on function schediel_private.create_share(uuid,text,text,jsonb,text,timestamptz,integer) from public, anon, authenticated;
grant execute on function schediel_private.create_share(uuid,text,text,jsonb,text,timestamptz,integer) to service_role;
