import test from 'node:test';
import assert from 'node:assert/strict';
import { fixtures } from './fixtures.ts';
import { validatePayload } from '../supabase/functions/_shared/validator.ts';

for (const c of fixtures) {
  test(`payload fixture: ${c.name}`, () => {
    if (c.valid) assert.deepEqual(validatePayload(c.payload), []);
  else {
    const errors = validatePayload(c.payload);
    assert.ok(errors.some(e => e.code === c.expectError.code && e.path === c.expectError.path), JSON.stringify(errors));
  }
  });
}
