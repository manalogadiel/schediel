import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const validation = await import('../src/validate.js').catch(error => {
  if (error.code === 'ERR_MODULE_NOT_FOUND') return {};
  throw error;
});
const { cases } = JSON.parse(await readFile(new URL('../../contracts/fixtures/share-payload-cases.json', import.meta.url), 'utf8'));
function fixtureTests(names) {
  for (const name of names) {
    const fixture = cases.find(entry => entry.name === name);
    assert.ok(fixture, name);
    test(`payload contract: ${name}`, () => {
      assert.equal(typeof validation.validatePayload, 'function', 'payload validation is missing');
      const result = validation.validatePayload(fixture.payload);
      assert.equal(result.valid, fixture.valid, JSON.stringify(result.errors));
      if (fixture.valid) assert.deepEqual(result.errors, []);
      else assert.ok(result.errors.some(error => error.code === fixture.expectError.code && error.path === fixture.expectError.path), JSON.stringify(result.errors));
    });
  }
}
fixtureTests([
  'valid-single-item-no-optional-details', 'valid-title-120-emoji-code-points',
  'invalid-unsupported-version', 'invalid-unknown-top-level-field', 'invalid-missing-items',
  'invalid-items-not-array', 'invalid-empty-items', 'invalid-empty-title', 'invalid-untrimmed-title',
  'invalid-title-121-code-points', 'invalid-empty-location', 'invalid-unknown-detail-field',
  'invalid-source-item-id-not-uuid', 'invalid-revision-zero', 'invalid-revision-not-integer',
  'invalid-category-label-too-long', 'invalid-missing-shared-field-policy',
]);
fixtureTests([
  'valid-mixed-items', 'valid-weekly-start-on-unselected-weekday',
  'invalid-impossible-date', 'invalid-year-out-of-range', 'invalid-clock-24-00',
  'invalid-unknown-zone', 'invalid-fixed-offset-zone', 'invalid-end-time-without-day-offset',
  'invalid-day-offset-without-end-time', 'invalid-end-before-start-same-day', 'invalid-end-day-offset-2',
  'invalid-unknown-resolution', 'invalid-date-only-end-not-after-start',
  'invalid-recurring-date-only-multi-day', 'invalid-date-only-span-over-366-days',
]);
fixtureTests([
  'invalid-weekly-empty-weekdays', 'invalid-weekly-duplicate-weekday', 'invalid-weekday-out-of-range',
  'invalid-daily-with-weekdays', 'invalid-interval-2', 'invalid-until-before-start',
  'invalid-exception-on-one-time-item', 'invalid-exception-key-wrong-weekday',
  'invalid-exception-key-after-until', 'invalid-exception-key-before-start',
  'invalid-duplicate-exception-key', 'invalid-cancel-with-replacement',
  'invalid-override-without-replacement', 'invalid-override-kind-mismatch',
  'invalid-replacement-with-recurrence', 'invalid-duplicate-source-item-id',
  'invalid-notes-present-but-excluded', 'invalid-replacement-professor-excluded',
]);

function base() { return structuredClone(cases.find(entry => entry.name === 'valid-mixed-items').payload); }
function expectBad(payload, code, path) {
  const result = validation.validatePayload(payload);
  assert.equal(result.valid, false);
  assert.ok(result.errors.some(error => error.code === code && error.path === path), JSON.stringify(result));
}
test('bounds payload UTF-8 bytes rather than UTF-16 character count', () => {
  const payload = base();
  payload.sharedFieldPolicy.notes = true;
  payload.items = Array.from({ length: 40 }, (_, index) => ({ ...structuredClone(payload.items[1]), sourceItemId: `00000000-0000-4000-8000-${String(index).padStart(12, '0')}`, details: { location: null, professor: null, subtitle: null, notes: '🙂'.repeat(4000) } }));
  expectBad(payload, 'payload_too_large', '');
});
test('bounds total exceptions across items', () => {
  const payload = base();
  payload.items = payload.items.filter(item => item.recurrence !== null);
  for (const item of payload.items) {
    item.recurrence = { frequency: 'daily', interval: 1, weekdays: [], untilDateInclusive: null };
    item.exceptions = Array.from({ length: 251 }, (_, index) => ({ action: 'cancel', replacement: null, originalOccurrenceKey: new Date(Date.parse(`${item.time.startDate}T00:00:00Z`) + index * 86400000).toISOString().slice(0, 10) }));
  }
  expectBad(payload, 'too_many', '/items');
});
test('trims Unicode whitespace including next-line characters', () => {
  const payload = base();
  payload.items[0].title = '\u0085title';
  expectBad(payload, 'invalid_text', '/items/0/title');
});
test('bounds items before inspecting their contents', () => {
  const payload = base();
  payload.items = Array(251).fill(payload.items[0]);
  expectBad(payload, 'too_many', '/items');
});
