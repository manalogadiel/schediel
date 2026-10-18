import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { database, A } from './db.ts';
import { validPayload } from './fixtures.ts';
import { digestToken } from '../supabase/functions/_shared/crypto.ts';
import { createRuntimeHandler } from '../supabase/functions/_shared/runtime.ts';

const base='https://project.test/functions/v1';
const jwt=()=>`${Buffer.from('{"alg":"RS256"}').toString('base64url')}.${Buffer.from(JSON.stringify({sub:A,role:'authenticated',aud:'authenticated',iss:'https://project.test/auth/v1',exp:Math.floor(Date.now()/1000)+3600})).toString('base64url')}.c2ln`;
test('runtime wiring uses real SQL store, verified Auth, and secret-keyed trusted-address rate buckets',async t=>{
  const db=await database(); t.after(()=>db.close()); await db.exec('set role service_role');
  let authCalls=0; const parameters:any[][]=[];
  const handler=createRuntimeHandler({SUPABASE_URL:'https://project.test',SUPABASE_PUBLISHABLE_KEYS:JSON.stringify({default:'sb_publishable_fixture'}),SCHEDIEL_ALLOWED_ORIGINS:'https://share.test',SCHEDIEL_RATE_HASH_SECRET:'fixture-secret-with-at-least-32-bytes',SCHEDIEL_TRUSTED_IP_HEADER:'x-real-ip',SCHEDIEL_TRUST_PROXY_HEADERS:'true'}, {
    query:async(sql,params)=>{parameters.push(params); return db.query(sql,params);},
    fetch:async(input,init)=>{authCalls++; assert.equal(String(input),'https://project.test/auth/v1/user'); assert.equal(new Headers(init?.headers).get('apikey'),'sb_publishable_fixture'); return Response.json({id:A});},
  });
  const token=Buffer.alloc(32,9).toString('base64url');
  const body={schemaVersion:'1.0',payload:validPayload(),tokenDigest:await digestToken(token),expiresAt:new Date(Date.now()+86400000).toISOString()};
  const created=await handler(new Request(base+'/share-links',{method:'POST',headers:{authorization:`Bearer ${jwt()}`,'Idempotency-Key':crypto.randomUUID(),'content-type':'application/json'},body:JSON.stringify(body)}));
  assert.equal(created.status,201); const meta=await created.json(); assert.equal(authCalls,1);
  const resolve=await handler(new Request(base+'/share-resolve',{method:'POST',headers:{apikey:'sb_publishable_fixture','content-type':'application/json','x-real-ip':'192.0.2.7',origin:'https://share.test'},body:JSON.stringify({shareId:meta.shareId,token,supportedSchemaVersions:['1.0']})}));
  assert.equal(resolve.status,200); assert.equal(authCalls,1);
  assert.ok(!JSON.stringify(parameters).includes('192.0.2.7'));
  assert.ok(!JSON.stringify(parameters).includes(token));
});
test('missing database/auth/proxy policy configuration fails closed but health remains minimal',async()=>{
  const handler=createRuntimeHandler({});
  const health=await handler(new Request(base+'/health')); assert.deepEqual(await health.json(),{status:'ok'});
  const scan=await handler(new Request(base+'/scan/jobs',{method:'POST'})); assert.equal(scan.status,401);
  const create=await handler(new Request(base+'/share-links',{method:'POST',headers:{authorization:`Bearer ${jwt()}`}})); assert.equal(create.status,503); assert.equal((await create.json()).code,'service_unavailable');
  const resolve=await handler(new Request(base+'/share-resolve',{method:'POST',headers:{'content-type':'application/json','x-forwarded-for':'192.0.2.1'},body:JSON.stringify({shareId:crypto.randomUUID(),token:Buffer.alloc(32).toString('base64url'),supportedSchemaVersions:['1.0']})}));
  assert.equal(resolve.status,503); assert.equal((await resolve.json()).code,'service_unavailable');
});
test('the PostgreSQL driver import is statically discoverable by the deployment bundler',()=>{
  const source=readFileSync(new URL('../supabase/functions/_shared/runtime.ts',import.meta.url),'utf8');
  assert.match(source,/import\(\s*'npm:postgres@3\.4\.9'\s*\)/);
  assert.doesNotMatch(source,/import\(\s*[A-Za-z_$][\w$]*\s*\)/);
});
test('Supabase function names and gateway auth configuration match frozen transport',()=>{
  const config=readFileSync(new URL('../supabase/config.toml',import.meta.url),'utf8');
  for(const name of ['share-links','share-resolve','scan','privacy','health']) {
    assert.match(config,new RegExp(`\\[functions\\.${name}\\]\\s+verify_jwt\\s*=\\s*false`));
    const entry=readFileSync(new URL(`../supabase/functions/${name}/index.ts`,import.meta.url),'utf8');
    assert.match(entry,/Deno\.serve\(createRuntimeHandler\(Deno\.env\.toObject\(\)\)\)/);
  }
});
