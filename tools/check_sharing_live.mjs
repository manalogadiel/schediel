// Opt-in live verification using synthetic contract data only. Credentials and
// bearer links stay in memory; output contains named checks and status only.
import { readFile } from 'node:fs/promises';
import { randomBytes, randomUUID, createHash } from 'node:crypto';
import { isDeepStrictEqual } from 'node:util';
import { execFileSync } from 'node:child_process';
import { setTimeout as delay } from 'node:timers/promises';

if (!process.argv.includes('--create-fixtures')) {
  console.error('Pass --create-fixtures to create disposable anonymous test identities and synthetic shares.');
  process.exit(1);
}
const root = new URL('../', import.meta.url);
const settings = JSON.parse((await readFile(new URL('env/sharing.json', root), 'utf8')).replace(/^\uFEFF/, ''));
const fixtures = JSON.parse(await readFile(new URL('contracts/fixtures/share-payload-cases.json', root), 'utf8'));
const payload = fixtures.cases.find(c => c.name === 'valid-single-item-no-optional-details').payload;
const sessions = [];
const deviceFlag = process.argv.indexOf('--device');
const device = deviceFlag < 0 ? null : process.argv[deviceFlag + 1];
const browserButton = process.argv.includes('--browser-button');
class CheckFailure extends Error {}
const check = (value, label) => { if (!value) throw new CheckFailure(label); };
let requestStage = 'startup';
async function api(path, {owner, body, key, origin, expected = 200, method = body ? 'POST' : 'GET'} = {}) {
  requestStage = path.replace(/[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}/g, '{id}');
  const headers = {apikey: settings.SCHEDIEL_SUPABASE_KEY, 'Content-Type': 'application/json'};
  if (owner) headers.Authorization = `Bearer ${owner.access_token}`;
  if (key) headers['Idempotency-Key'] = key;
  if (origin) headers.Origin = origin;
  const response = await fetch(settings.SCHEDIEL_SUPABASE_URL + path, {
    method, headers, body: body ? JSON.stringify(body) : undefined,
    redirect: 'error', signal: AbortSignal.timeout(20000),
  });
  check(response.headers.get('Content-Type')?.includes('application/json'), `Unexpected response format (HTTP ${response.status})`);
  const data = await response.json();
  const code = typeof data.code === 'string' && /^[a-z_]+$/.test(data.code) ? data.code : 'unknown';
  if (response.status !== expected && Array.isArray(data.fieldErrors)) {
    for (const field of data.fieldErrors) {
      if (/^[a-z_]+$/.test(field.code) && /^\/[A-Za-z0-9_\/-]{0,200}$/.test(field.path)) console.error(`Validation: ${field.path} ${field.code}`);
    }
  }
  check(response.status === expected, `${path.split('/').at(-1)} expected ${expected}, received ${response.status} (${code})`);
  return {data, headers: response.headers};
}
const endpoint = '/functions/v1/';
async function owner() {
  const {data} = await api('/auth/v1/signup', {body: {}});
  check(data.access_token && data.user?.is_anonymous, 'Anonymous session unavailable');
  sessions.push(data); return data;
}
async function create(owner) {
  const secret = randomBytes(32), token = secret.toString('base64url'), key = randomUUID();
  const body = {schemaVersion: '1.0', payload, tokenDigest: createHash('sha256').update(secret).digest('hex'), expiresAt: new Date(Date.now() + 86400000).toISOString()};
  const {data} = await api(endpoint + 'share-links', {owner, body, key, expected: 201});
  check(data.shareId && data.itemCount === payload.items.length && !data.token && !data.tokenDigest, 'Unsafe creation metadata');
  const fixture = {owner, token, shareId: data.shareId};
  const replay = await api(endpoint + 'share-links', {owner, body, key, expected: 201});
  check(replay.data.shareId === data.shareId && replay.headers.get('Idempotent-Replayed') === 'true', 'Creation replay mismatch');
  return fixture;
}
async function checkDevice(fixture) {
  requestStage = 'phone browser handoff';
  check(device && /^[A-Za-z0-9][A-Za-z0-9:_-]*$/.test(device), 'A device serial is required');
  const adb = (...args) => execFileSync('adb', ['-s', device, ...args], {encoding: 'utf8', timeout: 20000});
  const screen = () => {
    adb('shell', 'uiautomator', 'dump', '/sdcard/schediel-review-check.xml');
    return adb('exec-out', 'cat', '/sdcard/schediel-review-check.xml');
  };
  function buttonCenter(xml, label) {
    for (const match of xml.matchAll(/<node\b[^>]*>/g)) {
      const node = match[0];
      if (!node.includes(`text="${label}"`) && !node.includes(`content-desc="${label}"`)) continue;
      const bounds = /bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/.exec(node);
      if (bounds) return [String(Math.round((+bounds[1] + +bounds[3]) / 2)), String(Math.round((+bounds[2] + +bounds[4]) / 2))];
    }
    return null;
  }
  let opened = 0;
  try {
    for (const host of [settings.SCHEDIEL_SHARE_HOST, settings.SCHEDIEL_APP_LINK_HOST].filter(Boolean)) {
      const args = ['shell', 'am', 'start', '-W', '-a', 'android.intent.action.VIEW', '-c', 'android.intent.category.BROWSABLE'];
      if (browserButton) args.push('-p', 'com.android.chrome');
      const launch = adb(...args, '-d', `https://${host}/s/#${fixture.token}`);
      if (browserButton) {
        check(launch.includes('com.android.chrome'), 'Could not open the synthetic preview in Chrome');
        let center;
        for (let attempt = 0; attempt < 5; attempt++) {
          await delay(1000); center = buttonCenter(screen(), 'Open in Schediel');
          if (center) break;
        }
        check(center, 'Chrome did not show the Open in Schediel button');
        adb('shell', 'input', 'tap', ...center);
      } else {
        check(launch.includes('com.manalogadiel.schediel'), 'Android did not route the verified link to Schediel');
        opened++;
      }
      let ready = false;
      for (let attempt = 0; attempt < 5; attempt++) {
        await delay(1000);
        const xml = screen();
        ready = ['Shared schedules', payload.items[0].title, 'Edit', 'Add selected schedules'].every(text => xml.includes(text));
        if (ready) break;
      }
      check(ready, 'Phone did not show the editable review and Add action');
      if (browserButton) opened++;
      console.log(browserButton ? 'PASS real Chrome Open in Schediel button launches the native editable review'
        : `PASS phone ${opened === 1 ? 'first' : 'warm'} link opens editable review through Android verification`);
    }
  } finally {
    // No Add or Edit action is tapped. Close only the unmodified test reviews.
    for (let i = 0; i < opened; i++) adb('shell', 'input', 'keyevent', 'KEYCODE_BACK');
    adb('shell', 'rm', '-f', '/sdcard/schediel-review-check.xml');
  }
}
try {
  await api(endpoint + 'health');
  const a = await owner(), b = await owner();
  await api(endpoint + 'share-links', {expected: 401});
  const first = await create(a), second = await create(b);
  console.log('PASS account-free creation, protected management and idempotent retry');
  await api(endpoint + 'share-links/' + first.shareId, {owner: b, expected: 404});
  await api(endpoint + 'share-links/' + first.shareId, {owner: b, method: 'DELETE', expected: 404});
  const resolve = (fixture, extras = {}, options = {}) => api(endpoint + 'share-resolve', {
    body: {token: fixture.token, supportedSchemaVersions: ['1.0'], ...extras}, ...options,
  });
  const compact = await resolve(first);
  check(compact.data.shareId === first.shareId && isDeepStrictEqual(compact.data.payload, payload), 'Compact snapshot mismatch');
  await resolve(first, {shareId: first.shareId});
  await resolve(first, {shareId: randomUUID()}, {expected: 404});
  await resolve(first, {token: randomBytes(32).toString('base64url')}, {expected: 404});
  await resolve(first, {supportedSchemaVersions: ['2.0']}, {expected: 422});
  for (const host of [settings.SCHEDIEL_SHARE_HOST, settings.SCHEDIEL_APP_LINK_HOST].filter(Boolean)) {
    const origin = `https://${host}`;
    const result = await resolve(first, {}, {origin});
    check(result.headers.get('Access-Control-Allow-Origin') === origin, 'Origin policy mismatch');
    check(result.headers.get('Cache-Control') === 'no-store, private', 'Missing private cache policy');
  }
  await resolve(first, {}, {origin: 'https://unapproved.example', expected: 403});
  console.log('PASS compact and legacy resolution, owner isolation, wrong-link rejection and browser origins');
  if (deviceFlag >= 0) await checkDevice(first);
  await api(endpoint + 'share-links/' + first.shareId, {owner: a, method: 'DELETE'});
  await resolve(first, {}, {expected: 410});
  const deletion = await api(endpoint + 'privacy/delete-backend-data', {owner: a, body: {confirm: 'delete-backend-data'}, key: randomUUID(), expected: 202});
  const job = await api(endpoint + 'privacy/deletion-jobs/' + deletion.data.deletionJobId, {owner: a});
  check(job.data.status === 'completed', 'Deletion did not complete');
  await resolve(first, {}, {expected: 404});
  const replacement = structuredClone(payload); replacement.items[0].title = 'Synthetic replacement';
  await api(endpoint + 'share-links', {owner: b, key: randomUUID(), expected: 400, body: {
    schemaVersion: '1.0', payload: replacement,
    tokenDigest: createHash('sha256').update(Buffer.from(first.token, 'base64url')).digest('hex'),
    expiresAt: new Date(Date.now() + 86400000).toISOString(),
  }});
  await resolve(first, {}, {expected: 404});
  await resolve(second);
  console.log('PASS revocation, deletion readback, rejection of link replacement and preservation of another owner’s share');
} catch (error) {
  // Only explicit fixed assertions are reported, never fetch details or bodies.
  const kind = /^[A-Za-z]+Error$/.test(error?.name) ? error.name : 'request failure';
  console.error(`Live sharing verification failed at ${requestStage}: ` + (error instanceof CheckFailure ? error.message : kind));
  process.exitCode = 1;
} finally {
  for (const session of sessions) {
    try {
      await api(endpoint + 'privacy/delete-backend-data', {owner: session, body: {confirm: 'delete-backend-data'}, key: randomUUID(), expected: 202});
      await fetch(settings.SCHEDIEL_SUPABASE_URL + '/auth/v1/logout', {method: 'POST', headers: {apikey: settings.SCHEDIEL_SUPABASE_KEY, Authorization: `Bearer ${session.access_token}`}});
    } catch { console.error('Fixture cleanup could not be confirmed.'); process.exitCode = 1; }
  }
  console.log('Synthetic fixture cleanup finished; no schedules from the phone were used.');
}
