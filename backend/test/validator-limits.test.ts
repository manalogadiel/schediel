import test from 'node:test';
import assert from 'node:assert/strict';
import { validPayload, singlePayload } from './fixtures.ts';
import { validatePayload } from '../supabase/functions/_shared/validator.ts';

test('strict types, escaped JSON pointers, whitespace and nested required keys', () => {
  for (const value of [null, [], 'value', 7]) assert.deepEqual(validatePayload(value), [{ code: 'invalid_type', path: '' }]);
  const p = validPayload();
  p['a/b~c'] = 'sensitive';
  delete p.items[0].details.notes;
  p.items[1].title = '\u0085not trimmed';
  p.sharedFieldPolicy.notes = 'false';
  const e = validatePayload(p);
  assert.ok(e.some(e => e.path === '/a~1b~0c' && e.code === 'unknown_field'));
  assert.ok(e.some(e => e.path === '/items/0/details/notes' && e.code === 'missing_field'));
  assert.ok(e.some(e => e.path === '/items/1/title' && e.code === 'invalid_text'));
  assert.ok(e.some(e => e.path === '/sharedFieldPolicy/notes' && e.code === 'invalid_type'));
});
test('enforces 250 items and 500 exceptions total without truncation', () => {
  const p = singlePayload();
  p.items = Array.from({ length: 251 }, (_, i) => ({ ...p.items[0], sourceItemId: `00000000-0000-4000-8000-${i.toString(16).padStart(12, '0')}` }));
  assert.ok(validatePayload(p).some(e => e.code === 'too_many' && e.path === '/items'));
  const q = validPayload();
  q.items[2].exceptions = Array.from({ length: 501 }, () => ({ originalOccurrenceKey: '2026-11-06', action: 'cancel', replacement: null }));
  assert.ok(validatePayload(q).some(e => e.code === 'too_many'));
});
function payloadOfSize(bytes: number) {
  const p = singlePayload();
  p.sharedFieldPolicy.notes = true;
  p.items = Array.from({ length: 140 }, (_, i) => ({ ...structuredClone(p.items[0]), sourceItemId: `00000000-0000-4000-8000-${i.toString(16).padStart(12, '0')}` }));
  for (const item of p.items) item.details.notes = 'x';
  let remaining = bytes - Buffer.byteLength(JSON.stringify(p));
  for (const item of p.items) {
    const extra = Math.min(3999, remaining);
    item.details.notes += 'x'.repeat(extra);
    remaining -= extra;
  }
  assert.equal(remaining, 0);
  assert.equal(Buffer.byteLength(JSON.stringify(p)), bytes);
  return p;
}
test('canonical UTF-8 payload limit includes exact 512 KiB and rejects one byte more', () => {
  assert.deepEqual(validatePayload(payloadOfSize(524288)), []);
  assert.deepEqual(validatePayload(payloadOfSize(524289)), [{ code: 'payload_too_large', path: '' }]);
  const p = payloadOfSize(524288);
  p.items[0].details.notes = p.items[0].details.notes.replace('x', '🙂');
  assert.ok(validatePayload(p).some(e => e.code === 'payload_too_large'));
});
