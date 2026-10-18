begin;

-- This schema MUST remain absent from the Supabase Data API exposed schemas.
create schema schediel_private;
revoke all on schema schediel_private from public, anon, authenticated;
grant usage on schema schediel_private to service_role;
alter default privileges in schema schediel_private revoke all on tables from public, anon, authenticated;
alter default privileges in schema schediel_private revoke execute on functions from public, anon, authenticated;

create table schediel_private.share_links (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  schema_version text not null check (schema_version = '1.0'),
  snapshot_version integer not null default 1 check (snapshot_version = 1),
  payload jsonb not null,
  payload_hash text not null check (payload_hash ~ '^[0-9a-f]{64}$'),
  payload_bytes integer not null check (payload_bytes between 1 and 524288),
  token_digest text not null check (token_digest ~ '^[0-9a-f]{64}$'),
  item_count integer not null check (item_count between 1 and 250),
  category_labels jsonb not null check (jsonb_array_length(category_labels) <= 20),
  created_at timestamptz not null default clock_timestamp(),
  expires_at timestamptz not null,
  revoked_at timestamptz,
  check (expires_at > created_at)
);
create index share_links_owner_order on schediel_private.share_links (owner_id, created_at desc, id desc);
alter table schediel_private.share_links enable row level security;

create table schediel_private.policy (
  singleton boolean primary key default true check (singleton),
  active_shares integer not null default 20 check (active_shares > 0),
  owner_creates_daily integer not null default 50 check (owner_creates_daily > 0),
  global_creates_daily integer not null default 5000 check (global_creates_daily > 0),
  resolves_per_minute integer not null default 60 check (resolves_per_minute > 0),
  management_per_minute integer not null default 120 check (management_per_minute > 0)
);
insert into schediel_private.policy default values;
alter table schediel_private.policy enable row level security;
create table schediel_private.idempotency_records (
  owner_id uuid not null,
  route text not null check (route in ('share-links','delete-backend-data')),
  key_hash text not null check (key_hash ~ '^[0-9a-f]{64}$'),
  request_hash text not null check (request_hash ~ '^[0-9a-f]{64}$'),
  resource_id uuid,
  outcome jsonb,
  created_at timestamptz not null,
  expires_at timestamptz not null,
  primary key(owner_id,route,key_hash)
);
alter table schediel_private.idempotency_records enable row level security;
create table schediel_private.usage_buckets (
  scope text not null,
  subject_hash text not null check (subject_hash ~ '^[0-9a-f]{64}$'),
  window_start timestamptz not null,
  used integer not null check (used >= 0),
  primary key(scope,subject_hash,window_start)
);
alter table schediel_private.usage_buckets enable row level security;

create function schediel_private.canonical_json(v jsonb) returns text
language sql immutable security definer set search_path = '' as $$
  select case jsonb_typeof(v)
    when 'object' then '{' || coalesce((select string_agg(to_jsonb(key)::text || ':' || schediel_private.canonical_json(value), ',' order by key) from jsonb_each(v)), '') || '}'
    when 'array' then '[' || coalesce((select string_agg(schediel_private.canonical_json(value), ',' order by n) from jsonb_array_elements(v) with ordinality a(value,n)), '') || ']'
    else v::text end
$$;
create function schediel_private.share_metadata(s schediel_private.share_links) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('shareId', s.id, 'snapshotVersion', s.snapshot_version,
    'routePath', '/s/' || s.id::text, 'createdAt', to_char(s.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'expiresAt', to_char(s.expires_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'revokedAt', case when s.revoked_at is null then null else to_char(s.revoked_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') end,
    'itemCount', s.item_count, 'categoryLabels', s.category_labels)
$$;
create function schediel_private.create_share(p_owner uuid, p_key_hash text, p_request_hash text, p_payload jsonb, p_digest text, p_expires timestamptz, p_bytes integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  s schediel_private.share_links;
  labels jsonb;
  canonical text;
  idem schediel_private.idempotency_records;
  limits schediel_private.policy;
  owner_hash text;
  day_start timestamptz;
  server_now timestamptz := clock_timestamp();
begin
  if p_owner is null then return jsonb_build_object('code','unauthenticated'); end if;
  if p_key_hash is null or p_key_hash !~ '^[0-9a-f]{64}$' or p_request_hash is null or p_request_hash !~ '^[0-9a-f]{64}$' then return jsonb_build_object('code','invalid_request'); end if;
  -- Consistent lock order: global create quota -> owner -> share row.
  perform pg_advisory_xact_lock(7001);
  perform pg_advisory_xact_lock(hashtextextended(p_owner::text,0));
  server_now := clock_timestamp();
  select * into idem from schediel_private.idempotency_records where owner_id=p_owner and route='share-links' and key_hash=p_key_hash;
  if found then
    if idem.expires_at <= server_now or not exists(select 1 from schediel_private.share_links where id=idem.resource_id and owner_id=p_owner and expires_at>server_now) then return jsonb_build_object('code','idempotency_expired'); end if;
    if idem.request_hash <> p_request_hash then return jsonb_build_object('code','idempotency_mismatch'); end if;
    return jsonb_build_object('data',idem.outcome,'replayed',true);
  end if;
  if p_digest is null or p_digest !~ '^[0-9a-f]{64}$' then return jsonb_build_object('code','invalid_request'); end if;
  if p_payload->>'schemaVersion' is distinct from '1.0' then return jsonb_build_object('code','unsupported_schema_version'); end if;
  if jsonb_typeof(p_payload->'items') is distinct from 'array' then return jsonb_build_object('code','validation_failed'); end if;
  if jsonb_array_length(p_payload->'items') not between 1 and 250 then return jsonb_build_object('code','validation_failed'); end if;
  canonical := schediel_private.canonical_json(p_payload);
  if octet_length(convert_to(canonical, 'UTF8')) > 524288 then return jsonb_build_object('code','payload_too_large'); end if;
  if p_bytes is distinct from octet_length(convert_to(canonical, 'UTF8')) then return jsonb_build_object('code','invalid_request'); end if;
  if p_expires is null or not isfinite(p_expires) or p_expires < server_now + interval '55 minutes' or p_expires > server_now + interval '7 days 5 minutes' then return jsonb_build_object('code','validation_failed'); end if;
  select coalesce(jsonb_agg(label order by first_n), '[]'::jsonb) into labels from (
    select value->>'categoryLabel' label, min(n) first_n from jsonb_array_elements(p_payload->'items') with ordinality a(value,n)
    where value->>'categoryLabel' is not null group by value->>'categoryLabel'
  ) d;
  if jsonb_array_length(labels) > 20 then return jsonb_build_object('code','validation_failed'); end if;
  select * into strict limits from schediel_private.policy where singleton;
  owner_hash := encode(sha256(convert_to(p_owner::text,'UTF8')),'hex');
  day_start := date_trunc('day',server_now at time zone 'UTC') at time zone 'UTC';
  if (select count(*) from schediel_private.share_links where owner_id=p_owner and revoked_at is null and expires_at>server_now) >= limits.active_shares
    or coalesce((select used from schediel_private.usage_buckets where scope='create-owner' and subject_hash=owner_hash and window_start=day_start),0)>=limits.owner_creates_daily
    or coalesce((select used from schediel_private.usage_buckets where scope='create-global' and subject_hash=repeat('0',64) and window_start=day_start),0)>=limits.global_creates_daily
    then return jsonb_build_object('code','quota_exceeded'); end if;
  insert into schediel_private.share_links(owner_id,schema_version,payload,payload_hash,payload_bytes,token_digest,item_count,category_labels,created_at,expires_at)
  values(p_owner,'1.0',p_payload,encode(sha256(convert_to(canonical,'UTF8')),'hex'),p_bytes,p_digest,jsonb_array_length(p_payload->'items'),labels,server_now,p_expires) returning * into s;
  insert into schediel_private.usage_buckets(scope,subject_hash,window_start,used)
  values('create-owner',owner_hash,day_start,1),('create-global',repeat('0',64),day_start,1)
  on conflict(scope,subject_hash,window_start) do update set used=schediel_private.usage_buckets.used+1;
  insert into schediel_private.idempotency_records(owner_id,route,key_hash,request_hash,resource_id,outcome,created_at,expires_at)
  values(p_owner,'share-links',p_key_hash,p_request_hash,s.id,schediel_private.share_metadata(s),server_now,server_now+interval '24 hours');
  return jsonb_build_object('data',schediel_private.share_metadata(s),'replayed',false);
end $$;
create function schediel_private.get_share(p_owner uuid, p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare s schediel_private.share_links;
begin
  if p_owner is null then return jsonb_build_object('code','unauthenticated'); end if;
  select * into s from schediel_private.share_links where id=p_id and owner_id=p_owner;
  if not found then return jsonb_build_object('code','not_found'); end if;
  return jsonb_build_object('data',schediel_private.share_metadata(s));
end $$;
create function schediel_private.list_shares(p_owner uuid, p_cursor uuid, p_limit integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare c schediel_private.share_links; rows_json jsonb; next_id uuid;
begin
  if p_owner is null then return jsonb_build_object('code','unauthenticated'); end if;
  if p_limit is null or p_limit not between 1 and 50 then return jsonb_build_object('code','invalid_request'); end if;
  if p_cursor is not null then
    select * into c from schediel_private.share_links where id=p_cursor and owner_id=p_owner;
    if not found then return jsonb_build_object('code','invalid_request'); end if;
  end if;
  select coalesce(jsonb_agg(schediel_private.share_metadata(s) order by s.created_at desc,s.id desc),'[]'::jsonb) into rows_json
  from (select * from schediel_private.share_links where owner_id=p_owner and (p_cursor is null or (created_at,id)<(c.created_at,c.id)) order by created_at desc,id desc limit p_limit+1) s;
  if jsonb_array_length(rows_json)>p_limit then
    rows_json := rows_json - p_limit;
    next_id := (rows_json->(p_limit-1)->>'shareId')::uuid;
  end if;
  return jsonb_build_object('data',jsonb_build_object('items',rows_json,'nextCursor',next_id));
end $$;

create function schediel_private.take_rate(p_scope text, p_subject_hash text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare maximum integer; n integer; server_now timestamptz := clock_timestamp(); window_at timestamptz;
begin
  if p_scope is null or p_scope not in ('resolve','management') or p_subject_hash is null or p_subject_hash !~ '^[0-9a-f]{64}$' then return jsonb_build_object('code','invalid_request'); end if;
  select case when p_scope='resolve' then resolves_per_minute else management_per_minute end into strict maximum from schediel_private.policy where singleton;
  window_at := date_trunc('minute',server_now);
  insert into schediel_private.usage_buckets(scope,subject_hash,window_start,used) values(p_scope,p_subject_hash,window_at,1)
  on conflict(scope,subject_hash,window_start) do update set used=least(schediel_private.usage_buckets.used+1,maximum+1) returning used into n;
  if n>maximum then return jsonb_build_object('code','rate_limited','retryAfterSeconds',greatest(1,ceil(extract(epoch from window_at+interval '1 minute'-server_now))::integer)); end if;
  return jsonb_build_object('data',true);
end $$;
create function schediel_private.digest_matches(a text,b text) returns boolean
language plpgsql immutable security definer set search_path = '' as $$
declare x bytea; y bytea; difference integer := 0;
begin
  if a is null or b is null or a !~ '^[0-9a-f]{64}$' or b !~ '^[0-9a-f]{64}$' then return false; end if;
  x:=decode(a,'hex'); y:=decode(b,'hex');
  for i in 0..31 loop difference:=difference | (get_byte(x,i) # get_byte(y,i)); end loop;
  return difference=0;
end $$;
create function schediel_private.resolve_share(p_id uuid,p_digest text,p_supported text[],p_address_hash text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare s schediel_private.share_links; rate jsonb; m jsonb;
begin
  if p_digest is null or p_digest !~ '^[0-9a-f]{64}$' then return jsonb_build_object('code','invalid_token'); end if;
  if p_supported is null or cardinality(p_supported) not between 1 and 5 then return jsonb_build_object('code','invalid_request'); end if;
  rate:=schediel_private.take_rate('resolve',p_address_hash);
  if rate ? 'code' then return rate; end if;
  -- Hold the row lock through authorization and reading the immutable snapshot.
  select * into s from schediel_private.share_links where id=p_id for update;
  if not found or not schediel_private.digest_matches(s.token_digest,p_digest) then return jsonb_build_object('code','not_found'); end if;
  if s.revoked_at is not null then return jsonb_build_object('code','link_revoked'); end if;
  if s.expires_at<=clock_timestamp() then return jsonb_build_object('code','link_expired'); end if;
  if s.schema_version<>all(p_supported) then return jsonb_build_object('code','unsupported_schema_version'); end if;
  m:=schediel_private.share_metadata(s);
  return jsonb_build_object('data',jsonb_build_object('shareId',s.id,'schemaVersion',s.schema_version,'snapshotVersion',s.snapshot_version,
    'createdAt',m->'createdAt','expiresAt',m->'expiresAt','itemCount',s.item_count,'payload',s.payload));
end $$;
create function schediel_private.revoke_share(p_owner uuid,p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare s schediel_private.share_links;
begin
  if p_owner is null then return jsonb_build_object('code','unauthenticated'); end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner::text,0));
  select * into s from schediel_private.share_links where id=p_id and owner_id=p_owner for update;
  if not found then return jsonb_build_object('code','not_found'); end if;
  if s.revoked_at is null then update schediel_private.share_links set revoked_at=clock_timestamp() where id=s.id and owner_id=p_owner returning * into s; end if;
  return jsonb_build_object('data',schediel_private.share_metadata(s));
end $$;

create table schediel_private.deletion_jobs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  status text not null check (status in ('queued','running','completed','failed')),
  requested_at timestamptz not null,
  completed_at timestamptz,
  revoked_share_count integer not null default 0 check (revoked_share_count >= 0),
  deleted_share_count integer not null default 0 check (deleted_share_count >= 0)
);
alter table schediel_private.deletion_jobs enable row level security;
create function schediel_private.deletion_metadata(j schediel_private.deletion_jobs) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('deletionJobId',j.id,'status',j.status,
    'requestedAt',to_char(j.requested_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'completedAt',case when j.completed_at is null then null else to_char(j.completed_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') end,
    'revokedShareCount',j.revoked_share_count,'deletedShareCount',j.deleted_share_count)
$$;
create function schediel_private.delete_backend_data(p_owner uuid,p_key_hash text,p_request_hash text,p_confirm text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare j schediel_private.deletion_jobs; idem schediel_private.idempotency_records; revoked integer; deleted integer; server_now timestamptz;
begin
  if p_owner is null then return jsonb_build_object('code','unauthenticated'); end if;
  if p_confirm is distinct from 'delete-backend-data' or p_key_hash is null or p_key_hash !~ '^[0-9a-f]{64}$' or p_request_hash is null or p_request_hash !~ '^[0-9a-f]{64}$' then return jsonb_build_object('code','invalid_request'); end if;
  perform pg_advisory_xact_lock(hashtextextended(p_owner::text,0));
  server_now:=clock_timestamp();
  select * into idem from schediel_private.idempotency_records where owner_id=p_owner and route='delete-backend-data' and key_hash=p_key_hash;
  if found then
    if idem.expires_at<=server_now then return jsonb_build_object('code','idempotency_expired'); end if;
    if idem.request_hash<>p_request_hash then return jsonb_build_object('code','idempotency_mismatch'); end if;
    return jsonb_build_object('data',idem.outcome,'replayed',true);
  end if;
  insert into schediel_private.deletion_jobs(owner_id,status,requested_at) values(p_owner,'running',server_now) returning * into j;
  -- Sharing-only cleanup is bounded and finishes in this transaction; no fake worker.
  perform id from schediel_private.share_links where owner_id=p_owner order by id for update;
  update schediel_private.share_links set revoked_at=server_now where owner_id=p_owner and revoked_at is null;
  get diagnostics revoked = row_count;
  delete from schediel_private.share_links where owner_id=p_owner;
  get diagnostics deleted = row_count;
  -- Keep only minimal anti-replay tombstones; remove private metadata from old outcomes.
  update schediel_private.idempotency_records set outcome=null,resource_id=null,expires_at=least(expires_at,server_now) where owner_id=p_owner and route='share-links';
  update schediel_private.deletion_jobs set status='completed',completed_at=clock_timestamp(),revoked_share_count=revoked,deleted_share_count=deleted where id=j.id and owner_id=p_owner returning * into j;
  insert into schediel_private.idempotency_records(owner_id,route,key_hash,request_hash,resource_id,outcome,created_at,expires_at)
  values(p_owner,'delete-backend-data',p_key_hash,p_request_hash,j.id,schediel_private.deletion_metadata(j),server_now,server_now+interval '24 hours');
  return jsonb_build_object('data',schediel_private.deletion_metadata(j),'replayed',false);
end $$;
create function schediel_private.get_deletion_job(p_owner uuid,p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare j schediel_private.deletion_jobs;
begin
  if p_owner is null then return jsonb_build_object('code','unauthenticated'); end if;
  select * into j from schediel_private.deletion_jobs where id=p_id and owner_id=p_owner;
  if not found then return jsonb_build_object('code','not_found'); end if;
  return jsonb_build_object('data',schediel_private.deletion_metadata(j));
end $$;

revoke all on all tables in schema schediel_private from public, anon, authenticated, service_role;
revoke all on all functions in schema schediel_private from public, anon, authenticated;
grant execute on all functions in schema schediel_private to service_role;
commit;
