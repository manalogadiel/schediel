const encoder = new TextEncoder();
function hex(bytes: ArrayBuffer) { return Array.from(new Uint8Array(bytes), b => b.toString(16).padStart(2, '0')).join(''); }
export async function sha256Hex(value: string | Uint8Array): Promise<string> {
  const bytes = typeof value === 'string' ? encoder.encode(value) : Uint8Array.from(value);
  return hex(await crypto.subtle.digest('SHA-256', bytes));
}
export async function digestToken(value: unknown): Promise<string | null> {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(value)) return null;
  try {
    const binary = atob(value.replaceAll('-', '+').replaceAll('_', '/') + '=');
    if (binary.length !== 32 || btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '') !== value) return null;
    return await sha256Hex(Uint8Array.from(binary, c => c.charCodeAt(0)));
  } catch { return null; }
}
export function canonicalJson(value: unknown): string {
  function sorted(v: any): any {
    if (Array.isArray(v)) return v.map(sorted);
    if (v !== null && typeof v === 'object') return Object.fromEntries(Object.keys(v).sort().map(k => [k, sorted(v[k])]));
    return v;
  }
  return JSON.stringify(sorted(value));
}
export async function hashAddress(address: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey('raw', encoder.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return hex(await crypto.subtle.sign('HMAC', key, encoder.encode(address)));
}
