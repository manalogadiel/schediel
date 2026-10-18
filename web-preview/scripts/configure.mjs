#!/usr/bin/env node
import { copyFile, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readSettings } from '../src/settings.js';

const root = fileURLToPath(new URL('..', import.meta.url));
const source = join(root, 'src');

async function configure() {
  const args = process.argv.slice(2);
  if (args.length && (args.length !== 2 || args[0] !== '--out' || !args[1])) throw new Error('Usage: node scripts/configure.mjs [--out DIRECTORY]');
  const out = args.length ? resolve(args[1]) : join(root, 'dist');
  for (const name of ['SCHEDIEL_API_BASE', 'SCHEDIEL_SHARE_HOST']) {
    if (!process.env[name]) throw new Error(`${name} is required; no output was generated.`);
  }
  let config;
  try {
    config = readSettings({ apiBase: process.env.SCHEDIEL_API_BASE, shareHost: process.env.SCHEDIEL_SHARE_HOST, publishableKey: process.env.SCHEDIEL_PUBLISHABLE_KEY || '', appLinkOrigin: process.env.SCHEDIEL_APP_LINK_ORIGIN || '' });
  } catch {
    throw new Error('SCHEDIEL_API_BASE and SCHEDIEL_SHARE_HOST must be HTTPS URLs without credentials, queries or fragments; the share host must be an origin. SCHEDIEL_APP_LINK_ORIGIN, when set, must be a different HTTPS origin. SCHEDIEL_PUBLISHABLE_KEY may only be an sb_publishable_ key.');
  }
  if (!config.appLinkOrigin) console.log('SCHEDIEL_APP_LINK_ORIGIN is not set: the preview offers no app hand-off button.');
  const fingerprint = process.env.ANDROID_CERT_SHA256 || '';
  const team = process.env.APPLE_TEAM_ID || '';
  const androidPackage = process.env.ANDROID_PACKAGE_NAME || 'com.manalogadiel.schediel';
  const appleBundle = process.env.APPLE_BUNDLE_ID || 'com.manalogadiel.schediel';
  if (fingerprint && !/^(?:[0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}$/.test(fingerprint)) throw new Error('ANDROID_CERT_SHA256 must be a real colon-separated SHA-256 signing certificate fingerprint.');
  if (fingerprint && !/^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)+$/.test(androidPackage)) throw new Error('ANDROID_PACKAGE_NAME must be an Android package identifier.');
  if (team && !/^[A-Z0-9]{10}$/.test(team)) throw new Error('APPLE_TEAM_ID must be the actual ten-character team identifier.');
  if (team && !/^[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$/.test(appleBundle)) throw new Error('APPLE_BUNDLE_ID must be a bundle identifier without wildcards.');
  const associations = [];
  if (fingerprint) associations.push(['assetlinks.json', [{ relation: ['delegate_permission/common.handle_all_urls'], target: { namespace: 'android_app', package_name: androidPackage, sha256_cert_fingerprints: [fingerprint] } }]]);
  if (team) associations.push(['apple-app-site-association', { applinks: { apps: [], details: [{ appID: `${team}.${appleBundle}`, paths: ['/s/*'] }] } }]);
  const origin = new URL(config.apiBase).origin;
  const html = (await readFile(join(source, 'index.html'), 'utf8')).replace("connect-src 'none'", `connect-src ${origin}`);
  const policy = /http-equiv="Content-Security-Policy" content="([^"]+)"/.exec(html)[1];
  await mkdir(join(out, 's'), { recursive: true });
  await mkdir(join(out, 'assets'), { recursive: true });
  await writeFile(join(out, 's/index.html'), html, 'utf8');
  for (const file of ['main.js', 'app.js', 'link.js', 'settings.js', 'validate.js', 'render.js', 'style.css']) await copyFile(join(source, file), join(out, 'assets', file));
  await writeFile(join(out, 'assets/config.js'), `// Public build settings, not credentials.\nexport const config = Object.freeze(${JSON.stringify(config, null, 2)});\n`, 'utf8');
  await writeFile(join(out, '_redirects'), '/s/* /s/index.html 200\n', 'utf8');
  const associationHeaders = associations.map(([name]) => `\n/.well-known/${name}\n  Content-Type: application/json\n`).join('');
  await writeFile(join(out, '_headers'), `/*\n  Cache-Control: no-store, private\n  Referrer-Policy: no-referrer\n  X-Content-Type-Options: nosniff\n  X-Frame-Options: DENY\n  Content-Security-Policy: ${policy}; frame-ancestors 'none'\n${associationHeaders}`, 'utf8');
  // Only remove these two known generated files, never other output content.
  for (const name of ['assetlinks.json', 'apple-app-site-association']) await rm(join(out, '.well-known', name), { force: true });
  if (associations.length) await mkdir(join(out, '.well-known'), { recursive: true });
  for (const [name, data] of associations) await writeFile(join(out, '.well-known', name), `${JSON.stringify(data, null, 2)}\n`, 'utf8');
  if (!fingerprint) console.log('ANDROID_CERT_SHA256 is not set: Android association file omitted.');
  if (!team) console.log('APPLE_TEAM_ID is not set: Apple association file omitted.');
  console.log('Static share preview generated locally. Nothing was deployed.');
}
try { await configure(); }
catch (error) {
  console.error(error instanceof Error ? error.message : 'Static preview configuration failed.');
  process.exitCode = 1;
}
