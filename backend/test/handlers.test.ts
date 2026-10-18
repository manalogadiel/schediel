import test from 'node:test';
import assert from 'node:assert/strict';
import { database, A, B } from './db.ts';
import { validPayload } from './fixtures.ts';
import { digestToken } from '../supabase/functions/_shared/crypto.ts';
import { createSqlStore } from '../supabase/functions/_shared/sql-store.ts';
import { createHandler } from '../supabase/functions/_shared/handlers.ts';

const base='https://project.test/functions/v1';
const secret=Buffer.alloc(32,7).toString('base64url');
async function setup(t: any) {
  const db=await database(); t.after(()=>db.close());
  await db.exec('set role service_role');
  const queries: {sql:string,params:any[]}[]=[];
  const store=createSqlStore(async(sql,params)=>{ queries.push({sql,params}); return db.query(sql,params); });
  let authCalls=0;
  const handler=createHandler({store,verifyOwner: async(req: Request)=>{authCalls++; const bearer=req.headers.get('authorization'); return bearer==='Bearer owner-a'?{sub:A}:bearer==='Bearer owner-b'?{sub:B}:null;},addressHash:async()=> 'c'.repeat(64),allowedOrigins:['https://share.test']});
  return {db,store,handler,queries,authCalls:()=>authCalls};
}
function request(path: string, method='GET', body?: unknown, owner='owner-a', key=crypto.randomUUID()) {
  return new Request(base+path,{method,headers:{'content-type':'application/json','authorization':`Bearer ${owner}`,'Idempotency-Key':key,apikey:'sb_publishable_fixture'},body:body===undefined?undefined:JSON.stringify(body)});
}
async function createBody() { return {schemaVersion:'1.0',payload:validPayload(),tokenDigest:await digestToken(secret),expiresAt:new Date(Date.now()+86400000).toISOString()}; }
async function error(response: Response,status: number,code: string) {
  assert.equal(response.status,status);
  const body=await response.json(); assert.equal(body.code,code);
  assert.ok(typeof body.requestId==='string' && body.requestId.length<=64);
  assert.equal(typeof body.retryable,'boolean'); assert.ok(body.message.length<=300);
  return body;
}
test('HTTP create/replay/list/get/revoke metadata uses verified identity and real PostgreSQL',async t=>{
  const {handler}=await setup(t), body=await createBody(), key=crypto.randomUUID();
  const response=await handler(request('/share-links','POST',body,'owner-a',key));
  assert.equal(response.status,201); assert.equal(response.headers.get('Idempotent-Replayed'),'false');
  const created=await response.json(); assert.equal(created.itemCount,3);
  assert.equal(created.tokenDigest,undefined); assert.equal(created.payload,undefined);
  assert.ok(!JSON.stringify(created).includes(secret));
  const replay=await handler(request('/share-links','POST',body,'owner-a',key));
  assert.equal(replay.status,201); assert.equal(replay.headers.get('Idempotent-Replayed'),'true'); assert.deepEqual(await replay.json(),created);
  const get=await handler(request(`/share-links/${created.shareId}`)); assert.equal(get.status,200); assert.deepEqual(await get.json(),created);
  const list=await handler(request('/share-links?limit=1')); assert.deepEqual(await list.json(),{items:[created],nextCursor:null});
  await error(await handler(request(`/share-links/${created.shareId}`,'GET',undefined,'owner-b')),404,'not_found');
  const empty=await handler(request('/share-links','GET',undefined,'owner-b')); assert.deepEqual(await empty.json(),{items:[],nextCursor:null});
  await error(await handler(request('/share-links','POST',{...body,ownerId:B})),400,'invalid_request');
  await error(await handler(request('/share-links','POST',body,'invalid')),401,'unauthenticated');
});
test('HTTP input errors are bounded, safe, and never reflect payload/digest/unknown keys',async t=>{
  const {handler}=await setup(t), body=await createBody();
  const req=request('/share-links','POST',body); req.headers.delete('Idempotency-Key');
  await error(await handler(req),400,'idempotency_key_required');
  const bad=structuredClone(body); bad.payload.items[0].title='';
  const e=await error(await handler(request('/share-links','POST',bad)),422,'validation_failed');
  assert.ok(e.fieldErrors.some((f:any)=>f.path==='/payload/items/0/title' && f.code==='invalid_text'));
  bad.payload[secret]='sensitive';
  const safe=await error(await handler(request('/share-links','POST',bad)),422,'validation_failed');
  assert.ok(!JSON.stringify(safe).includes(secret)); assert.ok(!JSON.stringify(safe).includes(body.tokenDigest));
  await error(await handler(request('/share-links','POST',{...body,schemaVersion:'2.0'})),422,'unsupported_schema_version');
  const wrongMedia=request('/share-links','POST',body); wrongMedia.headers.set('content-type','text/plain');
  await error(await handler(wrongMedia),415,'unsupported_media_type');
  const malformed=new Request(base+'/share-links',{method:'POST',headers:{authorization:'Bearer owner-a','content-type':'application/json','Idempotency-Key':crypto.randomUUID()},body:'{"payload":'});
  await error(await handler(malformed),400,'invalid_request');
});

test('public resolver accepts a non-JWT publishable key, never authenticates, and fails closed before lookup',async t=>{
  const ctx=await setup(t), {handler,queries}=ctx, body=await createBody();
  const created=await (await handler(request('/share-links','POST',body))).json();
  const before=ctx.authCalls(), resolve={shareId:created.shareId,token:secret,supportedSchemaVersions:['1.0']};
  const publicReq=request('/share-resolve','POST',resolve); publicReq.headers.delete('authorization');
  publicReq.headers.set('origin','https://share.test');
  const response=await handler(publicReq);
  assert.equal(response.status,200); assert.equal(ctx.authCalls(),before);
  assert.equal(response.headers.get('cache-control'),'no-store, private'); assert.equal(response.headers.get('referrer-policy'),'no-referrer');
  assert.equal(response.headers.get('access-control-allow-origin'),'https://share.test');
  const data=await response.json(); assert.deepEqual(data.payload,body.payload); assert.equal(data.tokenDigest,undefined); assert.equal(data.ownerId,undefined);
  const lookups=()=>queries.filter(q=>q.sql.includes('.resolve_share(')).length, count=lookups();
  for(const token of ['A'.repeat(42)+'B', secret+'=', '', 17]) await error(await handler(request('/share-resolve','POST',{...resolve,token})),400,'invalid_token');
  assert.equal(lookups(),count);
  await error(await handler(request('/share-resolve','POST',{...resolve,token:Buffer.alloc(32,8).toString('base64url')})),404,'not_found');
  await error(await handler(request('/share-resolve','POST',{...resolve,supportedSchemaVersions:['2.0']})),422,'unsupported_schema_version');
  const revoked=await handler(request(`/share-links/${created.shareId}`,'DELETE')); assert.equal(revoked.status,200);
  const metadata=await revoked.json(); assert.ok(metadata.revokedAt);
  const readback=await handler(request(`/share-links/${created.shareId}`)); assert.deepEqual(await readback.json(),metadata);
  const twice=await handler(request(`/share-links/${created.shareId}`,'DELETE')); assert.deepEqual(await twice.json(),metadata);
  await error(await handler(request('/share-resolve','POST',resolve)),410,'link_revoked');
  await error(await handler(request('/share-resolve','GET')),404,'not_found');
  for(const q of queries) {
    assert.ok(!JSON.stringify(q.params).includes(secret));
    assert.ok(!JSON.stringify(q.params).includes('sb_publishable_fixture'));
  }
});
test('health and preflight have no side effects; all documented scanning routes stay gated',async t=>{
  const ctx=await setup(t), {handler,queries}=ctx;
  const health=await handler(request('/health','GET',undefined,'invalid')); assert.equal(health.status,200); assert.deepEqual(await health.json(),{status:'ok'});
  const options=new Request(base+'/share-resolve',{method:'OPTIONS',headers:{origin:'https://share.test','access-control-request-method':'POST'}});
  assert.equal((await handler(options)).status,204); assert.equal(ctx.authCalls(),0); assert.equal(queries.length,0);
  const id=crypto.randomUUID();
  for(const [path,method] of [['/scan/assets','POST'],[`/scan/assets/${id}`,'DELETE'],['/scan/jobs','POST'],[`/scan/jobs/${id}`,'GET'],[`/scan/jobs/${id}`,'DELETE']]) {
    await error(await handler(request(path,method,undefined,'invalid')),401,'unauthenticated');
    const gated=await error(await handler(request(path,method)),503,'scan_unavailable'); assert.equal(gated.retryable,false);
  }
  assert.equal(queries.length,0);
  await error(await handler(new Request(base+'/health',{headers:{origin:'https://unapproved.test'}})),403,'forbidden');
});
test('HTTP explicit backend deletion returns 202 with exact owner-only verifiable progress',async t=>{
  const {handler}=await setup(t), body=await createBody();
  const created=await (await handler(request('/share-links','POST',body))).json();
  await error(await handler(request('/privacy/delete-backend-data','POST',{confirm:'wrong'})),400,'invalid_request');
  const key=crypto.randomUUID(), confirm={confirm:'delete-backend-data'};
  const response=await handler(request('/privacy/delete-backend-data','POST',confirm,'owner-a',key)); assert.equal(response.status,202);
  const job=await response.json(); assert.equal(job.status,'completed'); assert.equal(job.deletedShareCount,1);
  assert.deepEqual(Object.keys(job).sort(),['deletionJobId','status','requestedAt','completedAt','revokedShareCount','deletedShareCount'].sort());
  const status=await handler(request(`/privacy/deletion-jobs/${job.deletionJobId}`)); assert.deepEqual(await status.json(),job);
  await error(await handler(request(`/privacy/deletion-jobs/${job.deletionJobId}`,'GET',undefined,'owner-b')),404,'not_found');
  const replay=await handler(request('/privacy/delete-backend-data','POST',confirm,'owner-a',key)); assert.equal(replay.status,202); assert.deepEqual(await replay.json(),job);
  await error(await handler(request(`/share-links/${created.shareId}`)),404,'not_found');
  await error(await handler(request('/share-resolve','POST',{shareId:created.shareId,token:secret,supportedSchemaVersions:['1.0']})),404,'not_found');
});
