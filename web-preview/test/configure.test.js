import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { access, mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { JSDOM } from 'jsdom';

const script = fileURLToPath(new URL('../scripts/configure.mjs', import.meta.url));
const baseEnvironment = { ...process.env };
for (const key of ['SCHEDIEL_API_BASE', 'SCHEDIEL_SHARE_HOST', 'SCHEDIEL_APP_LINK_ORIGIN', 'SCHEDIEL_PUBLISHABLE_KEY', 'ANDROID_CERT_SHA256', 'ANDROID_PACKAGE_NAME', 'APPLE_TEAM_ID', 'APPLE_BUNDLE_ID']) delete baseEnvironment[key];
const required = { SCHEDIEL_API_BASE: 'https://api.example/functions/v1/', SCHEDIEL_SHARE_HOST: 'https://share.example' };
async function target(t) {
  const directory = await mkdtemp(join(process.env.TMPDIR || tmpdir(), 'schediel-preview-test-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  return { directory, out: join(directory, 'dist') };
}
function configure(out, environment = {}) {
  return spawnSync(process.execPath, [script, '--out', out], { encoding: 'utf8', env: { ...baseEnvironment, ...environment } });
}
async function exists(path) { return access(path).then(() => true, () => false); }

for (const missing of ['SCHEDIEL_API_BASE', 'SCHEDIEL_SHARE_HOST']) {
  test(`configuration fails without ${missing} and writes no output`, async t => {
    const { out } = await target(t);
    const env = { ...required };
    delete env[missing];
    const run = configure(out, env);
    assert.notEqual(run.status, 0);
    assert.match(run.stderr, new RegExp(missing));
    assert.equal(await exists(out), false);
  });
}

test('configuration creates a self-contained static tree with restrictive routing and privacy headers', async t => {
  const { out } = await target(t);
  const run = configure(out, { ...required, SCHEDIEL_PUBLISHABLE_KEY: 'sb_publishable_test_only' });
  assert.equal(run.status, 0, run.stderr);
  assert.match(run.stdout, /ANDROID_CERT_SHA256.*not set/);
  assert.match(run.stdout, /APPLE_TEAM_ID.*not set/);
  assert.equal(run.stdout.includes('sb_publishable_test_only'), false);
  const html = await readFile(join(out, 's/index.html'), 'utf8');
  const document = new JSDOM(html).window.document;
  const policy = document.querySelector('meta[http-equiv="Content-Security-Policy"]').content;
  assert.ok(policy.includes('connect-src https://api.example'));
  assert.equal(policy.includes('/functions/v1'), false);
  assert.doesNotMatch(policy, /unsafe-inline|unsafe-eval|\*/);
  for (const file of ['main.js', 'app.js', 'link.js', 'settings.js', 'validate.js', 'render.js', 'style.css']) assert.equal(await exists(join(out, 'assets', file)), true, file);
  const configSource = await readFile(join(out, 'assets/config.js'), 'utf8');
  const { config } = await import(`data:text/javascript,${encodeURIComponent(configSource)}`);
  assert.deepEqual(config, { apiBase: 'https://api.example/functions/v1', shareHost: 'https://share.example', publishableKey: 'sb_publishable_test_only' });
  assert.match(await readFile(join(out, '_redirects'), 'utf8'), /^\/s\/\*\s+\/s\/index\.html\s+200\s*$/);
  const headers = await readFile(join(out, '_headers'), 'utf8');
  for (const header of ['Cache-Control: no-store, private', 'Referrer-Policy: no-referrer', 'X-Content-Type-Options: nosniff', "frame-ancestors 'none'"]) assert.ok(headers.includes(header), header);
  assert.ok(headers.includes(policy));
  assert.equal(await exists(join(out, '.well-known/assetlinks.json')), false);
  assert.equal(await exists(join(out, '.well-known/apple-app-site-association')), false);
});

test('explicit app-link origin is emitted without synthesizing an origin or a token link', async t => {
  const { out } = await target(t);
  const run = configure(out, { ...required, SCHEDIEL_APP_LINK_ORIGIN: 'https://app.example' });
  assert.equal(run.status, 0, run.stderr);
  const { config } = await import(`data:text/javascript,${encodeURIComponent(await readFile(join(out, 'assets/config.js'), 'utf8'))}`);
  assert.equal(config.appLinkOrigin, 'https://app.example');
  const html = await readFile(join(out, 's/index.html'), 'utf8');
  assert.equal(html.includes('https://app.example'), false);
  assert.doesNotMatch(html, /#token=|href="https:/);
  const next = configure(out, required);
  assert.equal(next.status, 0, next.stderr);
  const { config: fallback } = await import(`data:text/javascript,${encodeURIComponent(await readFile(join(out, 'assets/config.js'), 'utf8'))}`);
  assert.equal(Object.hasOwn(fallback, 'appLinkOrigin'), false);
});

for (const origin of ['https://share.example', 'https://share.example/', 'http://app.example', 'https://app.example/path', 'https://app.example:8443']) {
  test(`rejects app-link origin ${origin} before writing build files`, async t => {
    const { out } = await target(t);
    const run = configure(out, { ...required, SCHEDIEL_APP_LINK_ORIGIN: origin });
    assert.notEqual(run.status, 0);
    assert.equal(await exists(out), false);
  });
}

// Explicit synthetic association inputs, used only in temporary test output.
const fingerprint = Array(32).fill('A1').join(':');
test('Android associations are emitted only from supplied signing inputs', async t => {
  const { out } = await target(t);
  const run = configure(out, { ...required, ANDROID_CERT_SHA256: fingerprint });
  assert.equal(run.status, 0, run.stderr);
  const links = JSON.parse(await readFile(join(out, '.well-known/assetlinks.json'), 'utf8'));
  assert.deepEqual(links, [{ relation: ['delegate_permission/common.handle_all_urls'], target: { namespace: 'android_app', package_name: 'com.manalogadiel.schediel', sha256_cert_fingerprints: [fingerprint] } }]);
  assert.equal(await exists(join(out, '.well-known/apple-app-site-association')), false);
});
test('Apple associations use only a supplied team and the configured app identity', async t => {
  const { out } = await target(t);
  const run = configure(out, { ...required, APPLE_TEAM_ID: 'TESTTEAM01', APPLE_BUNDLE_ID: 'com.example.fixture' });
  assert.equal(run.status, 0, run.stderr);
  const association = JSON.parse(await readFile(join(out, '.well-known/apple-app-site-association'), 'utf8'));
  assert.deepEqual(association, { applinks: { apps: [], details: [{ appID: 'TESTTEAM01.com.example.fixture', paths: ['/s/*'] }] } });
  assert.equal(await exists(join(out, '.well-known/assetlinks.json')), false);
  assert.match(await readFile(join(out, '_headers'), 'utf8'), /\/\.well-known\/apple-app-site-association\n\s+Content-Type: application\/json/);
});
test('associations default to the actual app package when no override is supplied', async t => {
  const { out } = await target(t);
  const run = configure(out, { ...required, APPLE_TEAM_ID: 'TESTTEAM01', ANDROID_CERT_SHA256: fingerprint, ANDROID_PACKAGE_NAME: 'com.example.fixture' });
  assert.equal(run.status, 0, run.stderr);
  const apple = JSON.parse(await readFile(join(out, '.well-known/apple-app-site-association'), 'utf8'));
  assert.equal(apple.applinks.details[0].appID, 'TESTTEAM01.com.manalogadiel.schediel');
  const android = JSON.parse(await readFile(join(out, '.well-known/assetlinks.json'), 'utf8'));
  assert.equal(android[0].target.package_name, 'com.example.fixture');
  assert.match(await readFile(join(out, '_headers'), 'utf8'), /\/\.well-known\/assetlinks\.json\n\s+Content-Type: application\/json/);
});
test('reconfiguration without signing inputs removes stale generated associations', async t => {
  const { out } = await target(t);
  const first = configure(out, { ...required, APPLE_TEAM_ID: 'TESTTEAM01', ANDROID_CERT_SHA256: fingerprint });
  assert.equal(first.status, 0, first.stderr);
  assert.equal(await exists(join(out, '.well-known/assetlinks.json')), true);
  assert.equal(await exists(join(out, '.well-known/apple-app-site-association')), true);
  const next = configure(out, required);
  assert.equal(next.status, 0, next.stderr);
  assert.equal(await exists(join(out, '.well-known/assetlinks.json')), false);
  assert.equal(await exists(join(out, '.well-known/apple-app-site-association')), false);
  const { config } = await import(`data:text/javascript,${encodeURIComponent(await readFile(join(out, 'assets/config.js'), 'utf8'))}`);
  assert.equal(config.publishableKey, '');
});
for (const [name, environment] of [
  ['HTTP API', { SCHEDIEL_API_BASE: 'http://api.example' }],
  ['API credentials', { SCHEDIEL_API_BASE: 'https://secret:password@api.example' }],
  ['API query', { SCHEDIEL_API_BASE: 'https://api.example?token=must-not-echo' }],
  ['share host path', { SCHEDIEL_SHARE_HOST: 'https://share.example/s' }],
  ['placeholder fingerprint', { ANDROID_CERT_SHA256: 'YOUR_CERT_SHA256' }],
  ['malformed team ID', { APPLE_TEAM_ID: 'YOUR_TEAM_ID' }],
  ['malformed Android identity', { ANDROID_CERT_SHA256: fingerprint, ANDROID_PACKAGE_NAME: 'com.example/attack' }],
  ['malformed Apple identity', { APPLE_TEAM_ID: 'TESTTEAM01', APPLE_BUNDLE_ID: 'com.example.*' }],
  ['secret key', { SCHEDIEL_PUBLISHABLE_KEY: 'sb_secret_must_not_echo' }],
]) {
  test(`rejects ${name} before writing build files`, async t => {
    const { out } = await target(t);
    const run = configure(out, { ...required, ...environment });
    assert.notEqual(run.status, 0);
    assert.equal(await exists(out), false);
    assert.doesNotMatch(run.stderr + run.stdout, /must.not.echo|secret:password|YOUR_CERT_SHA256|YOUR_TEAM_ID/);
  });
}
