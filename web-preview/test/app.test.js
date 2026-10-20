import test from 'node:test';
import assert from 'node:assert/strict';
import { browser, config, fixtures, response, resolved, shareId, shareUrl, token } from '../test-support/browser.js';
const app = await import('../src/app.js').catch(error => {
  if (error.code === 'ERR_MODULE_NOT_FOUND') return {};
  throw error;
});

for (const origin of ['https://share.example', 'https://app.example']) {
  test(`compact link resolves without an ID and hands off across hosts from ${origin}`, async t => {
    const calls = [], navigated = [];
    const window = await browser(t, {url: `${origin}/s/#${token}`, fetch: async (url, options) => {
      calls.push({url, options});
      assert.equal(window.location.hash, '');
      return response(200, resolved());
    }});
    await app.startPreview({window, config: {...config, appLinkOrigin: 'https://app.example'}, navigate: url => navigated.push(url)});
    assert.equal(window.document.querySelector('main').dataset.state, 'preview');
    assert.deepEqual(JSON.parse(calls[0].options.body), {token, supportedSchemaVersions: ['1.0']});
    assert.ok(!calls[0].url.includes(token));
    window.document.querySelector('#open-app').click();
    const destination = origin === 'https://app.example' ? 'https://share.example' : 'https://app.example';
    assert.deepEqual(navigated, [`${destination}/s/#${token}`]);
    assert.ok(!window.document.documentElement.outerHTML.includes(token));
  });
}

// Exercise the production default navigator, not only the injected callback.
function navigationWindow(window, assigned) {
  return new Proxy({}, { get(_, key) {
    if (key === 'location') return new Proxy({}, { get(_, property) {
      return property === 'assign' ? url => assigned.push(url) : Reflect.get(window.location, property);
    } });
    return Reflect.get(window, key);
  } });
}

for (const injected of [false, true]) {
  test(`no handoff origin hides the Open action and never restores a bearer (${injected ? 'injected' : 'default'} navigator)`, async t => {
    const window = await browser(t);
    const assigned = [];
    const navigated = [];
    const options = { window: navigationWindow(window, assigned), config };
    if (injected) options.navigate = url => navigated.push(url);
    await app.startPreview(options);
    assert.equal(window.document.querySelector('main').dataset.state, 'preview');
    const button = window.document.querySelector('#open-app');
    assert.equal(button.hidden, true);
    assert.match(window.document.querySelector('#app-help').textContent, /reopen the original link/i);
    assert.equal(window.document.querySelector('#app-action').hidden, false);
    button.click(); // Hidden controls must not retain a nonfunctional handler.
    assert.deepEqual(assigned, []);
    assert.deepEqual(navigated, []);
    assert.equal(window.location.href, shareUrl.split('#')[0]);
    assert.equal(window.document.documentElement.outerHTML.includes(token), false);
  });
}

test('default navigator assigns a distinct origin only after the user clicks', async t => {
  const window = await browser(t);
  const assigned = [];
  await app.startPreview({ window: navigationWindow(window, assigned), config: { ...config, appLinkOrigin: 'https://app.example' } });
  assert.deepEqual(assigned, []);
  assert.equal(window.location.href, shareUrl.split('#')[0]);
  assert.equal(window.document.documentElement.outerHTML.includes(token), false);
  assert.equal(window.document.querySelector('#open-app').hidden, false);
  window.document.querySelector('#open-app').click();
  assert.deepEqual(assigned, [`https://app.example/s/${shareId}#token=${token}`]);
  assert.equal(window.location.href, shareUrl.split('#')[0]);
  assert.equal(window.document.documentElement.outerHTML.includes(token), false);
});

test('resolves only through a body-only POST after clearing the fragment', async t => {
  let finish;
  const calls = [];
  const window = await browser(t, { fetch: (url, options) => {
    assert.equal(window.location.hash, '');
    calls.push({ url, options });
    return new Promise(resolve => { finish = resolve; });
  } });
  assert.equal(typeof app.startPreview, 'function', 'browser controller is missing');
  const ready = app.startPreview({ window, config: { ...config, publishableKey: 'sb_publishable_test' } });
  assert.equal(window.location.hash, '');
  assert.equal(window.document.querySelector('main').dataset.state, 'loading');
  assert.match(window.document.querySelector('[role=status]').textContent, /Loading/);
  assert.equal(calls.length, 1);
  const { url, options } = calls[0];
  assert.equal(url, 'https://api.example/functions/v1/share-resolve');
  assert.equal(options.method, 'POST');
  assert.deepEqual(JSON.parse(options.body), { shareId, token, supportedSchemaVersions: ['1.0'] });
  assert.equal(options.credentials, 'omit');
  assert.equal(options.cache, 'no-store');
  assert.equal(options.referrerPolicy, 'no-referrer');
  assert.equal(options.redirect, 'error');
  assert.deepEqual(options.headers, { 'Content-Type': 'application/json', apikey: 'sb_publishable_test' });
  assert.equal(JSON.stringify({ url, ...options, body: undefined }).includes(token), false);
  finish(response());
  await ready;
  assert.equal(window.document.querySelector('main').dataset.state, 'preview');
  assert.equal(window.document.querySelector('#item-count').textContent, '3 schedules');
  assert.match(window.document.querySelector('#expires').textContent, /Expires/);
  assert.equal(window.localStorage.length, 0);
  assert.equal(window.sessionStorage.length, 0);
  assert.equal(window.document.cookie, '');
});

for (const [name, path] of [
  ['missing token', `/s/${shareId}`],
  ['bad UUID', '/s/not-a-uuid#token=' + token],
  ['padding bits', `/s/${shareId}#token=${token.slice(0, -1)}9`],
  ['encoded token', `/s/${shareId}#token=%41${token.slice(1)}`],
  ['query token', `/s/${shareId}?token=${token}`],
  ['duplicate fragment', `/s/${shareId}#token=${token}&token=${token}`],
]) {
  test(`invalid ${name} clears history without a request or preview`, async t => {
    let calls = 0;
    const window = await browser(t, { url: `https://share.example${path}`, fetch: async () => { calls++; return response(); } });
    await app.startPreview({ window, config });
    assert.equal(calls, 0);
    assert.equal(window.location.hash, '');
    assert.equal(window.document.querySelector('main').dataset.state, 'unavailable');
    assert.equal(window.document.querySelector('#preview').hidden, true);
    assert.equal(window.document.querySelector('#retry').hidden, true);
    assert.equal(window.document.querySelector('#app-action').hidden, true);
  });
}
for (const [status, code, state, message, retry] of [
  [410, 'link_expired', 'expired', /expired/, false],
  [410, 'link_revoked', 'revoked', /revoked/, false],
  [410, 'unknown', 'unavailable', /unavailable/, false],
  [404, 'not_found', 'unavailable', /unavailable/, false],
  [400, 'invalid_token', 'unavailable', /unavailable/, false],
  [422, 'unsupported_schema_version', 'unsupported', /version/, false],
  [429, 'rate_limited', 'rate-limited', /Too many requests/, true],
  [500, 'internal_error', 'error', /could not be loaded/, true],
  [503, 'service_unavailable', 'error', /could not be loaded/, true],
]) {
  test(`HTTP ${status} ${code} has a safe ${state} state`, async t => {
    const window = await browser(t, { fetch: async () => response(status, { code, message: '<img src=x onerror=alert(1)>server-private-content', retryable: retry, retryAfterSeconds: 30 }) });
    await app.startPreview({ window, config });
    const document = window.document;
    assert.equal(document.querySelector('main').dataset.state, state);
    assert.match(document.querySelector('[role=status]').textContent, message);
    assert.equal(document.querySelector('#preview').hidden, true);
    assert.equal(document.querySelector('#app-action').hidden, true);
    assert.equal(document.querySelector('#retry').hidden, !retry);
    assert.equal(document.body.textContent.includes('server-private-content'), false);
    if (status === 429) assert.match(document.querySelector('[role=status]').textContent, /30 seconds/);
  });
}

test('network error can explicitly retry using only the secret still in memory', async t => {
  const requests = [];
  const window = await browser(t, { fetch: async (url, options) => {
    requests.push({ url, options });
    if (requests.length === 1) throw new TypeError('offline private details');
    return response();
  } });
  await app.startPreview({ window, config });
  assert.equal(window.document.querySelector('main').dataset.state, 'error');
  assert.equal(requests.length, 1);
  const retry = window.document.querySelector('#retry');
  retry.click();
  retry.click();
  await new Promise(resolve => setTimeout(resolve, 0));
  assert.equal(requests.length, 2);
  assert.deepEqual(JSON.parse(requests[1].options.body), { shareId, token, supportedSchemaVersions: ['1.0'] });
  assert.equal('apikey' in requests[1].options.headers, false);
  assert.equal(window.location.hash, '');
  assert.equal(window.document.querySelector('main').dataset.state, 'preview');
  assert.equal(window.document.body.textContent.includes('offline private details'), false);
});

test('invalid configuration does not disclose a secret to another origin', async t => {
  for (const bad of [{ ...config, apiBase: 'http://api.example' }, { ...config, apiBase: 'https://user:pass@api.example' }, { ...config, shareHost: 'https://other.example' }]) {
    let calls = 0;
    const window = await browser(t, { fetch: async () => { calls++; return response(); } });
    await app.startPreview({ window, config: bad });
    assert.equal(calls, 0);
    assert.equal(window.location.hash, '');
    assert.equal(window.document.querySelector('#preview').hidden, true);
  }
});

for (const [name, mutate, state] of [
  ['metadata count mismatch', result => { result.itemCount = 2; }, 'error'],
  ['wrong share', result => { result.shareId = '00000000-0000-4000-8000-000000000099'; }, 'error'],
  ['unknown envelope field', result => { result.ownerId = 'must-not-display'; }, 'error'],
  ['missing creation time', result => { delete result.createdAt; }, 'error'],
  ['invalid expiry', result => { result.expiresAt = '2026-02-30T00:00:00Z'; }, 'error'],
  ['unsupported version', result => { result.schemaVersion = '2.0'; }, 'unsupported'],
  ['unsupported payload version', result => { result.payload.schemaVersion = '2.0'; }, 'unsupported'],
  ['invalid policy', result => { result.payload.items[0].details.notes = 'excluded-private-note'; }, 'error'],
  ['invalid recurrence', result => { result.payload.items[0].recurrence.weekdays = []; }, 'error'],
]) {
  test(`refuses a successful but invalid response: ${name}`, async t => {
    const result = resolved();
    mutate(result);
    const window = await browser(t, { fetch: async () => response(200, result) });
    await app.startPreview({ window, config });
    assert.equal(window.document.querySelector('main').dataset.state, state);
    assert.equal(window.document.querySelector('#preview').hidden, true);
    assert.equal(window.document.querySelector('#app-action').hidden, true);
    assert.equal(window.document.querySelector('#items').children.length, 0);
    assert.equal(window.document.body.textContent.includes('Fixture'), false);
  });
}

test('malformed JSON fails safely without exposing any response', async t => {
  const window = await browser(t, { fetch: async () => ({ ok: true, status: 200, json: async () => { throw new SyntaxError('private invalid JSON'); } }) });
  await app.startPreview({ window, config });
  assert.equal(window.document.querySelector('main').dataset.state, 'error');
  assert.equal(window.document.querySelector('#retry').hidden, false);
});

for (const fixture of fixtures.filter(entry => entry.valid)) {
  test(`renders every sender-approved schedule in ${fixture.name}`, async t => {
    const window = await browser(t, { fetch: async () => response(200, resolved(fixture.payload)) });
    await app.startPreview({ window, config, timeZone: 'UTC', locale: 'en-US' });
    const rows = [...window.document.querySelectorAll('#items > li')];
    assert.equal(rows.length, fixture.payload.items.length);
    assert.equal(window.document.querySelector('#item-count').textContent, `${rows.length} ${rows.length === 1 ? 'schedule' : 'schedules'}`);
    for (const [index, item] of fixture.payload.items.entries()) {
      assert.equal(rows[index].querySelector('h2').textContent, item.title);
      assert.equal(rows[index].querySelector('.category').textContent, item.categoryLabel ?? 'Uncategorized');
      const labels = [...rows[index].querySelectorAll(':scope > .details dt')].map(node => node.textContent);
      const values = [...rows[index].querySelectorAll(':scope > .details dd')].map(node => node.textContent);
      assert.deepEqual(values, Object.values(item.details).filter(value => value !== null));
      assert.equal(labels.length, values.length);
      if (item.recurrence) assert.match(rows[index].querySelector('.recurrence').textContent, item.recurrence.frequency === 'weekly' ? /Weekly.*Monday.*Wednesday.*Dec 16, 2026.*inclusive/ : /Daily.*no end date/);
    }
    const expires = window.document.querySelector('#expires time');
    assert.equal(expires.dateTime, '2026-10-25T00:00:00Z');
    assert.match(expires.textContent, /Oct 25, 2026/);
    assert.match(window.document.querySelector('#expires').textContent, /UTC/);
  });
}

test('shows source wall times, overnight relationship and inclusive all-day dates', async t => {
  const window = await browser(t);
  await app.startPreview({ window, config, timeZone: 'UTC', locale: 'en-US' });
  const rows = [...window.document.querySelectorAll('#items > li')];
  assert.match(rows[0].querySelector('.schedule-time').textContent, /From Nov 2, 2026.*09:00.*10:30/);
  assert.equal(rows[0].querySelector('.source-zone').textContent, 'Asia/Manila time');
  assert.match(rows[1].querySelector('.schedule-time').textContent, /All day.*Dec 1, 2026.*Dec 3, 2026/);
  assert.doesNotMatch(rows[1].textContent, /Dec 4|00:00|UTC|time zone/);
  assert.match(rows[2].querySelector('.schedule-time').textContent, /22:00.*06:00.*next day/);
  assert.equal(rows[2].querySelector('.source-zone').textContent, 'America/New_York time');
  assert.equal(rows[0].querySelector('.exceptions summary').textContent, '2 exceptions');
  assert.match(rows[0].querySelector('.exceptions').textContent, /Nov 4, 2026.*Cancelled/s);
  assert.match(rows[0].querySelector('.exceptions').textContent, /Nov 9, 2026.*Fixture weekly class \(moved\).*Nov 10, 2026.*13:00.*14:30/s);
});

test('same-zone point time has no invented end or redundant zone', async t => {
  const result = resolved();
  result.payload.items = [result.payload.items[0]];
  result.itemCount = 1;
  Object.assign(result.payload.items[0].time, { endTime: null, endDayOffset: null, seedTimeResolution: 'later' });
  result.payload.items[0].recurrence = null;
  result.payload.items[0].exceptions = [];
  const window = await browser(t, { fetch: async () => response(200, result) });
  await app.startPreview({ window, config, timeZone: 'Asia/Manila', locale: 'en-US' });
  const row = window.document.querySelector('#items > li');
  assert.match(row.querySelector('.schedule-time').textContent, /09:00.*no end time/);
  assert.equal(row.querySelector('.source-zone'), null);
  assert.equal(row.querySelector('.recurrence'), null);
  assert.match(row.querySelector('.time-resolution').textContent, /Start time resolution: later/);
  assert.doesNotMatch(row.querySelector('.schedule-time').textContent, /10:|–|—/);
});

test('one-day all-day recurrence has one calendar date and no midnight conversion', async t => {
  const result = resolved();
  const item = result.payload.items[1];
  result.payload.items = [item];
  result.itemCount = 1;
  item.time.endDateExclusive = '2026-12-02';
  item.recurrence = { frequency: 'daily', interval: 1, weekdays: [], untilDateInclusive: null };
  const window = await browser(t, { fetch: async () => response(200, result) });
  await app.startPreview({ window, config, timeZone: 'Pacific/Honolulu', locale: 'en-US' });
  const row = window.document.querySelector('#items > li');
  assert.match(row.textContent, /All day.*Dec 1, 2026/);
  assert.doesNotMatch(row.textContent, /Dec 2|Nov 30|00:00/);
});

test('untrusted titles and detail strings remain inert text', async t => {
  const result = resolved();
  const attack = '<img src=x onerror="window.pwned=1">';
  result.payload.items[0].title = attack;
  result.payload.items[0].categoryLabel = '<svg onload="evil()">';
  result.payload.items[0].details.location = attack;
  result.payload.sharedFieldPolicy.notes = true;
  result.payload.items[0].details.notes = '<script>alert(1)</script>\nhttps://evil.example';
  const window = await browser(t, { fetch: async () => response(200, result) });
  await app.startPreview({ window, config });
  assert.equal(window.document.querySelector('#items h2').textContent, attack);
  assert.equal(window.document.querySelector('#items img, #items svg, #items script, #items a'), null);
  assert.equal(window.pwned, undefined);
  assert.equal(window.document.querySelector('#items').textContent.includes(result.payload.items[0].details.notes), true);
});

test('Open in Schediel targets only an explicitly configured distinct HTTPS origin on click', async t => {
  const window = await browser(t);
  const navigations = [];
  await app.startPreview({ window, config: { ...config, appLinkOrigin: 'https://app.example' }, navigate: url => navigations.push(url) });
  assert.deepEqual(navigations, []);
  assert.equal(window.document.documentElement.outerHTML.includes(token), false);
  assert.equal(window.document.documentElement.outerHTML.includes('https://app.example'), false);
  assert.match(window.document.querySelector('#app-help').textContent, /app is required.*Nothing is added here/);
  const button = window.document.querySelector('#open-app');
  assert.equal(button.textContent, 'Open in Schediel');
  button.click();
  assert.deepEqual(navigations, [`https://app.example/s/${shareId}#token=${token}`]);
  assert.equal(window.location.href, shareUrl.split('#')[0]);
  assert.equal(window.document.documentElement.outerHTML.includes(token), false);
  assert.equal(window.document.querySelector('a[href*="store"], form, input'), null);
  assert.equal([...window.document.querySelectorAll('button')].some(button => /import|add selected/i.test(button.textContent)), false);
});
