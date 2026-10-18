import test from 'node:test';
import assert from 'node:assert/strict';
import { database, call, A, B } from './db.ts';
import { validPayload } from './fixtures.ts';
import { sha256Hex } from '../supabase/functions/_shared/crypto.ts';

async function createRequest(owner = A, key = crypto.randomUUID(), payload = validPayload()) {
  const body = { payload, tokenDigest: 'a'.repeat(64), expiresAt: new Date(Date.now() + 86400000).toISOString() };
  return { args: [owner, await sha256Hex(key), await sha256Hex(JSON.stringify(body)), JSON.stringify(payload), body.tokenDigest, body.expiresAt, Buffer.byteLength(JSON.stringify(payload))], casts: ['uuid', 'text', 'text', 'jsonb', 'text', 'timestamptz', 'integer'] };
}
async function create(db: any, owner = A) {
  const {args, casts} = await createRequest(owner);
  return call(db, 'create_share', args, casts);
}
test('migration creates deny-by-default internal tables and service-only functions', async t => {
  const db = await database(); t.after(() => db.close());
  const tables = (await db.query<{tablename: string, rowsecurity: boolean}>("select tablename, rowsecurity from pg_tables where schemaname='schediel_private'" )).rows;
  assert.ok(tables.some(r => r.tablename === 'share_links'));
  assert.ok(tables.every(r => r.rowsecurity));
  for (const role of ['anon', 'authenticated']) {
    await db.exec(`set role ${role}`);
    await assert.rejects(db.query('select * from schediel_private.share_links'), /permission denied/);
    await assert.rejects(db.query("select schediel_private.create_share(null,null,null,null,null,null,null)"), /permission denied/);
    await db.exec('reset role');
  }
  const functions = (await db.query<{prosecdef: boolean, proconfig: string[]}>("select prosecdef,proconfig from pg_proc p join pg_namespace n on p.pronamespace=n.oid where n.nspname='schediel_private'" )).rows;
  assert.ok(functions.length > 0);
  assert.ok(functions.every(f => f.prosecdef && f.proconfig.includes('search_path=""')));
});
test('actual PostgreSQL create computes safe metadata, owners cannot read each other', async t => {
  const db = await database(); t.after(() => db.close());
  await db.exec('set role service_role');
  const created = await create(db);
  assert.equal(created.replayed, false);
  const m = created.data;
  assert.equal(m.itemCount, 3);
  assert.equal(m.snapshotVersion, 1);
  assert.equal(m.routePath, `/s/${m.shareId}`);
  assert.deepEqual(m.categoryLabels, ['Fixture school', 'Fixture work']);
  assert.deepEqual(Object.keys(m).sort(), ['shareId','snapshotVersion','routePath','createdAt','expiresAt','revokedAt','itemCount','categoryLabels'].sort());
  assert.equal((await call(db, 'get_share', [A, m.shareId], ['uuid','uuid'])).data.shareId, m.shareId);
  assert.equal((await call(db, 'get_share', [B, m.shareId], ['uuid','uuid'])).code, 'not_found');
  assert.equal((await call(db, 'get_share', [null, m.shareId], ['uuid','uuid'])).code, 'unauthenticated');
  const b = await call(db, 'list_shares', [B, null, 20], ['uuid','uuid','integer']);
  assert.deepEqual(b.data, { items: [], nextCursor: null });
});
test('identical retries replay one atomic outcome; mismatch and expired tombstones conflict', async t => {
  const db = await database(); t.after(() => db.close());
  const { args, casts } = await createRequest();
  const replies = await Promise.all(Array.from({ length: 5 }, () => call(db, 'create_share', args, casts)));
  assert.equal(new Set(replies.map(r => r.data.shareId)).size, 1);
  assert.equal(replies.filter(r => !r.replayed).length, 1);
  assert.deepEqual(replies[1].data, replies[0].data);
  const changed = [...args]; changed[2] = 'b'.repeat(64);
  assert.equal((await call(db, 'create_share', changed, casts)).code, 'idempotency_mismatch');
  await db.exec("update schediel_private.idempotency_records set expires_at=clock_timestamp()-interval '1 second'");
  assert.equal((await call(db, 'create_share', args, casts)).code, 'idempotency_expired');
  assert.equal((await db.query('select count(*)::integer n from schediel_private.share_links')).rows[0].n, 1);
  const rows = (await db.query('select * from schediel_private.idempotency_records')).rows;
  assert.ok(!JSON.stringify(rows).includes('a'.repeat(64)));
  assert.ok(!JSON.stringify(rows).includes('Fixture weekly class'));
});
test('owner/global daily and active quotas are enforced atomically; failed create rolls back', async t => {
  const db = await database(); t.after(() => db.close());
  await db.exec('update schediel_private.policy set active_shares=1, owner_creates_daily=2, global_creates_daily=3');
  const first = await create(db);
  assert.ok(first.data);
  const requests = await Promise.all(Array.from({ length: 4 }, () => create(db)));
  assert.ok(requests.every(r => r.code === 'quota_exceeded'));
  assert.equal((await db.query('select count(*)::integer n from schediel_private.idempotency_records')).rows[0].n, 1);
  await db.exec("update schediel_private.share_links set revoked_at=clock_timestamp()");
  assert.ok((await create(db)).data);
  await db.exec("update schediel_private.share_links set revoked_at=clock_timestamp()");
  assert.equal((await create(db)).code, 'quota_exceeded');
  assert.ok((await create(db, B)).data);
  await db.exec("update schediel_private.share_links set revoked_at=clock_timestamp()");
  assert.equal((await create(db, B)).code, 'quota_exceeded');
});
test('expiry, computed bytes, digest and label bounds are checked by SQL', async t => {
  const db = await database(); t.after(() => db.close());
  const { args, casts } = await createRequest();
  const badDigest = [...args]; badDigest[4] = 'RAW_SECRET';
  assert.equal((await call(db,'create_share',badDigest,casts)).code,'invalid_request');
  const badBytes = [...args]; badBytes[6] = 1;
  assert.equal((await call(db,'create_share',badBytes,casts)).code,'invalid_request');
  for (const delta of [0, 8*86400000]) {
    const badExpiry = [...args]; badExpiry[5] = new Date(Date.now()+delta).toISOString();
    assert.equal((await call(db,'create_share',badExpiry,casts)).code,'validation_failed');
  }
  const allowed = [...args]; allowed[5] = new Date(Date.now()+56*60000).toISOString();
  assert.ok((await call(db,'create_share',allowed,casts)).data);
});
test('capability resolution hides state until digest matches; revoke is owner-scoped and idempotent', async t => {
  const db = await database(); t.after(() => db.close());
  const created = await create(db), id = created.data.shareId;
  const resolve = (digest='a'.repeat(64), versions=['1.0'], shareId=id) => call(db,'resolve_share',[shareId,digest,versions,'c'.repeat(64)],['uuid','text','text[]','text']);
  assert.equal((await resolve('b'.repeat(64))).code,'not_found');
  assert.equal((await resolve('a'.repeat(64),['1.0'],crypto.randomUUID())).code,'not_found');
  assert.equal((await resolve('bad')).code,'invalid_token');
  assert.deepEqual((await resolve()).data.payload, validPayload());
  assert.equal((await resolve('a'.repeat(64),['2.0'])).code,'unsupported_schema_version');
  assert.equal((await call(db,'revoke_share',[B,id],['uuid','uuid'])).code,'not_found');
  const revoked = (await call(db,'revoke_share',[A,id],['uuid','uuid'])).data;
  assert.ok(revoked.revokedAt);
  assert.deepEqual((await call(db,'revoke_share',[A,id],['uuid','uuid'])).data,revoked);
  assert.equal((await resolve('b'.repeat(64),['2.0'])).code,'not_found');
  assert.equal((await resolve()).code,'link_revoked');
  const other = await create(db);
  await db.query("update schediel_private.share_links set created_at=clock_timestamp()-interval '2 days', expires_at=clock_timestamp()-interval '1 second' where id=$1",[other.data.shareId]);
  assert.equal((await resolve('b'.repeat(64),['1.0'],other.data.shareId)).code,'not_found');
  assert.equal((await resolve('a'.repeat(64),['1.0'],other.data.shareId)).code,'link_expired');
});
test('persistent rate buckets accept only hashes, cap attempts, and do not retain network addresses', async t => {
  const db = await database(); t.after(() => db.close());
  await db.exec('update schediel_private.policy set resolves_per_minute=2, management_per_minute=1');
  const args = [crypto.randomUUID(),'a'.repeat(64),['1.0'],'c'.repeat(64)], casts=['uuid','text','text[]','text'];
  assert.equal((await call(db,'resolve_share',args,casts)).code,'not_found');
  assert.equal((await call(db,'resolve_share',args,casts)).code,'not_found');
  const denied = await call(db,'resolve_share',args,casts);
  assert.equal(denied.code,'rate_limited'); assert.ok(denied.retryAfterSeconds>0);
  assert.equal((await call(db,'take_rate',['resolve','192.0.2.1'],['text','text'])).code,'invalid_request');
  assert.ok((await call(db,'take_rate',['management','d'.repeat(64)],['text','text'])).data);
  assert.equal((await call(db,'take_rate',['management','d'.repeat(64)],['text','text'])).code,'rate_limited');
  assert.ok(!JSON.stringify((await db.query('select * from schediel_private.usage_buckets')).rows).includes('192.0.2.1'));
});
test('resolve and mutation functions use PostgreSQL row locks with a consistent owner-first mutation order', async t => {
  const db = await database(); t.after(() => db.close());
  const definitions = (await db.query<{proname:string,definition:string}>("select proname,pg_get_functiondef(p.oid) definition from pg_proc p join pg_namespace n on p.pronamespace=n.oid where n.nspname='schediel_private' and proname in ('resolve_share','revoke_share')")).rows;
  assert.equal(definitions.length,2);
  assert.ok(definitions.every(r=> /for update/i.test(r.definition)));
  const revoked = definitions.find(r=>r.proname==='revoke_share')!.definition;
  assert.ok(revoked.indexOf('pg_advisory_xact_lock')<revoked.toLowerCase().indexOf('for update'));
});

test('backend deletion revokes/deletes only the verified owner and retains safe replay tombstones', async t => {
  const db = await database(); t.after(() => db.close());
  const own=await create(db), other=await create(db,B);
  const key=await sha256Hex(crypto.randomUUID()), hash=await sha256Hex('delete-backend-data');
  const args=[A,key,hash,'delete-backend-data'], casts=['uuid','text','text','text'];
  assert.equal((await call(db,'delete_backend_data',[A,key,hash,'wrong'],casts)).code,'invalid_request');
  const result=await call(db,'delete_backend_data',args,casts), job=result.data;
  assert.equal(job.status,'completed'); assert.ok(job.completedAt);
  assert.equal(job.revokedShareCount,1); assert.equal(job.deletedShareCount,1);
  assert.equal((await call(db,'get_share',[A,own.data.shareId],['uuid','uuid'])).code,'not_found');
  assert.ok((await call(db,'get_share',[B,other.data.shareId],['uuid','uuid'])).data);
  assert.deepEqual((await call(db,'get_deletion_job',[A,job.deletionJobId],['uuid','uuid'])).data,job);
  assert.equal((await call(db,'get_deletion_job',[B,job.deletionJobId],['uuid','uuid'])).code,'not_found');
  assert.deepEqual((await call(db,'delete_backend_data',args,casts)).data,job);
  assert.equal((await call(db,'delete_backend_data',[A,key,'b'.repeat(64),'delete-backend-data'],casts)).code,'idempotency_mismatch');
  const raw=JSON.stringify((await db.query('select * from schediel_private.idempotency_records where owner_id=$1',[A])).rows);
  assert.ok(!raw.includes('Fixture')); assert.ok(!raw.includes('a'.repeat(64)));
  const shareTombstone=(await db.query("select * from schediel_private.idempotency_records where owner_id=$1 and route='share-links'",[A])).rows[0];
  assert.equal(shareTombstone.outcome,null); assert.equal(shareTombstone.resource_id,null);
});

test('owner pagination is ordered, finite and rejects foreign cursors', async t => {
  const db = await database(); t.after(() => db.close());
  const all = [await create(db), await create(db), await create(db)];
  const p1 = (await call(db,'list_shares',[A,null,2],['uuid','uuid','integer'])).data;
  assert.equal(p1.items.length,2); assert.equal(p1.nextCursor,p1.items[1].shareId);
  const p2 = (await call(db,'list_shares',[A,p1.nextCursor,2],['uuid','uuid','integer'])).data;
  assert.equal(p2.items.length,1); assert.equal(p2.nextCursor,null);
  assert.equal(new Set([...p1.items,...p2.items].map(m=>m.shareId)).size, all.length);
  assert.equal((await call(db,'list_shares',[B,p1.nextCursor,2],['uuid','uuid','integer'])).code,'invalid_request');
});
