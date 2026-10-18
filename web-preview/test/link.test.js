import test from 'node:test';
import assert from 'node:assert/strict';

const link = await import('../src/link.js').catch(error => {
  if (error.code === 'ERR_MODULE_NOT_FOUND') return {};
  throw error;
});
const shareId = '00000000-0000-4000-8000-000000000001';
const token = Buffer.from(Array.from({ length: 32 }, (_, i) => i)).toString('base64url');
const url = `https://share.example/s/${shareId}#token=${token}`;

test('reads a canonical bearer link and immediately removes its fragment', () => {
  assert.equal(typeof link.captureShareLink, 'function', 'fragment capture is missing');
  let cleared = false;
  const location = new URL(url);
  const history = { replaceState(state, title, path) {
    assert.equal(state, null);
    assert.equal(title, '');
    assert.equal(path, `/s/${shareId}`);
    cleared = true;
  } };
  const result = link.captureShareLink({ location, history });
  assert.equal(cleared, true);
  assert.deepEqual(result, { shareId, token });
});

const invalidLinks = [
  '/s/not-a-uuid', `/s/${shareId.replace('4000', 'A000')}`,
  `/s/${shareId}/`, `/s/%30${shareId.slice(1)}`,
  `/s/${shareId}?token=${token}#token=${token}`,
  `/s/${shareId}#token=${token}=`, `/s/${shareId}#token=${token.slice(0, -1)}9`,
  `/s/${shareId}#token=${token.slice(1)}`, `/s/${shareId}#token=${token}&token=${token}`,
  `/s/${shareId}#token=%41${token.slice(1)}`, `/s/${shareId}#other=${token}`,
  `/s/${shareId}#token=${token}&extra=1`, `/s/${shareId}`,
  `http://share.example/s/${shareId}#token=${token}`,
];
for (const [index, path] of invalidLinks.entries()) {
  test(`rejects noncanonical link ${index + 1} and scrubs history`, () => {
    const location = new URL(path, 'https://share.example');
    let cleared = false;
    const browser = { location, history: { replaceState(_state, _title, cleanPath) {
      location.hash = '';
      location.search = '';
      cleared = true;
      assert.equal(cleanPath.includes('#'), false);
    } } };
    assert.equal(link.captureShareLink(browser), null);
    assert.equal(cleared, true);
  });
}

test('fails closed when history cannot be scrubbed', () => {
  assert.equal(link.captureShareLink({ location: new URL(url), history: {
    replaceState() { throw new Error('blocked'); },
  } }), null);
});
