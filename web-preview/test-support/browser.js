import { readFile } from 'node:fs/promises';
import { JSDOM } from 'jsdom';

export const shareId = '00000000-0000-4000-8000-000000000001';
export const token = Buffer.from(Array.from({ length: 32 }, (_, i) => i)).toString('base64url');
export const shareUrl = `https://share.example/s/${shareId}#token=${token}`;
export const config = { apiBase: 'https://api.example/functions/v1', shareHost: 'https://share.example', publishableKey: '' };
export const fixtures = JSON.parse(await readFile(new URL('../../contracts/fixtures/share-payload-cases.json', import.meta.url), 'utf8')).cases;
export function resolved(payload = structuredClone(fixtures.find(fixture => fixture.name === 'valid-mixed-items').payload)) {
  return { shareId, schemaVersion: '1.0', snapshotVersion: 1, createdAt: '2026-10-18T00:00:00Z', expiresAt: '2026-10-25T00:00:00Z', itemCount: payload.items.length, payload };
}
export function response(status = 200, body = resolved()) {
  return { status, ok: status >= 200 && status < 300, json: async () => structuredClone(body) };
}
export async function browser(t, { url = shareUrl, fetch = async () => response() } = {}) {
  const html = await readFile(new URL('../src/index.html', import.meta.url), 'utf8').catch(error => {
    if (error.code === 'ENOENT') return '';
    throw error;
  });
  const dom = new JSDOM(html, { url, runScripts: 'outside-only', pretendToBeVisual: true });
  dom.window.fetch = fetch;
  t.after(() => dom.window.close());
  return dom.window;
}
