import test from 'node:test';
import assert from 'node:assert/strict';
import { A, B } from './db.ts';
import { createOwnerVerifier } from '../supabase/functions/_shared/auth.ts';
import { ApiError } from '../supabase/functions/_shared/errors.ts';
const token=(claims:any)=>`${Buffer.from('{"alg":"RS256"}').toString('base64url')}.${Buffer.from(JSON.stringify(claims)).toString('base64url')}.c2ln`;
const claims=(sub=A)=>({sub,role:'authenticated',aud:'authenticated',iss:'https://project.test/auth/v1',exp:Math.floor(Date.now()/1000)+3600,is_anonymous:true});
const request=(jwt:string)=>new Request('https://project.test/functions/v1/share-links',{headers:{authorization:`Bearer ${jwt}`}});

test('owner verifier calls trusted Supabase Auth and only uses its verified JWT subject',async()=>{
  const jwt=token(claims()); let calls=0;
  const verify=createOwnerVerifier({url:'https://project.test',publishableKey:'sb_publishable_fixture',fetch:async(input,init)=>{
    calls++; assert.equal(String(input),'https://project.test/auth/v1/user');
    const headers=new Headers(init?.headers); assert.equal(headers.get('authorization'),`Bearer ${jwt}`); assert.equal(headers.get('apikey'),'sb_publishable_fixture');
    return Response.json({id:A,role:'authenticated',is_anonymous:true,user_metadata:{ownerId:B,sub:B}});
  }});
  assert.deepEqual(await verify(request(jwt)),{sub:A}); assert.equal(calls,1);
});
test('self-asserted, mismatched, expired, wrong-role and API-key bearer credentials cannot own resources',async()=>{
  const rejected=createOwnerVerifier({url:'https://project.test',publishableKey:'sb_publishable_fixture',fetch:async()=>Response.json({message:'untrusted private error'},{status:401})});
  assert.equal(await rejected(request(token(claims()))),null);
  const verify=createOwnerVerifier({url:'https://project.test',publishableKey:'sb_publishable_fixture',fetch:async()=>Response.json({id:A})});
  for(const bad of [token(claims(B)),token({...claims(),role:'anon'}),token({...claims(),role:'service_role'}),token({...claims(),exp:1}),token({...claims(),iss:'https://evil.test/auth/v1'}),'sb_publishable_fixture','malformed']) assert.equal(await verify(request(bad)),null);
  assert.equal(await verify(new Request('https://project.test')),null);
});
test('missing Auth configuration or upstream outage fails closed with a safe service error',async()=>{
  const jwt=token(claims());
  for(const verify of [createOwnerVerifier({}),createOwnerVerifier({url:'https://project.test',publishableKey:'sb_publishable_fixture',fetch:async()=>{throw new Error('sensitive upstream failure');}}),createOwnerVerifier({url:'https://project.test',publishableKey:'sb_publishable_fixture',fetch:async()=>Response.json({private:'data'},{status:503})})]) {
    await assert.rejects(verify(request(jwt)),(e:any)=>e instanceof ApiError && e.code==='service_unavailable' && !e.message.includes('sensitive'));
  }
});
