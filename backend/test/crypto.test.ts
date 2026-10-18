import test from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes, createHash, createHmac } from 'node:crypto';
import { digestToken, sha256Hex, canonicalJson, hashAddress } from '../supabase/functions/_shared/crypto.ts';

test('canonical base64url token hashes raw 32 bytes, not encoded text', async () => {
  for (let i = 0; i < 32; i++) {
    const bytes = randomBytes(32), token = bytes.toString('base64url');
    assert.equal(token.length, 43);
    assert.equal(await digestToken(token), createHash('sha256').update(bytes).digest('hex'));
    assert.notEqual(await digestToken(token), await sha256Hex(token));
  }
});
test('rejects padding, noncanonical low bits, whitespace, wrong length and nonstrings', async () => {
  const token = Buffer.alloc(32).toString('base64url');
  for (const bad of [null, 1, {}, '', 'A'.repeat(42), 'A'.repeat(44), token + '=', token.slice(0, 42) + 'B', token.slice(0, 42) + '/', ' ' + token, token.toLowerCase().slice(0, 42) + '+']) assert.equal(await digestToken(bad), null);
});
test('hashing copies typed-array bytes into a WebCrypto-compatible owned buffer', async () => {
  const value = new Uint8Array(new SharedArrayBuffer(32)); value.fill(7);
  assert.equal(await sha256Hex(value), createHash('sha256').update(Buffer.from(value)).digest('hex'));
});
test('request hashing is stable across JSON key order; address hashes use secret keyed HMAC', async () => {
  assert.equal(canonicalJson({ b: 2, a: { z: '🙂', b: null } }), canonicalJson({ a: { b: null, z: '🙂' }, b: 2 }));
  assert.equal(await hashAddress('192.0.2.1', 'test-secret'), createHmac('sha256', 'test-secret').update('192.0.2.1').digest('hex'));
  assert.notEqual(await hashAddress('192.0.2.1', 'test-secret'), await sha256Hex('192.0.2.1'));
});
