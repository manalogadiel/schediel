import { UUID } from './validator.ts';
import { ApiError } from './errors.ts';
type AuthOptions = { url?: string; publishableKey?: string; fetch?: typeof globalThis.fetch };
/** Supabase Auth's GET /user is the server-side signature/session verifier.
 * JWT decoding below is only shape validation until that request succeeds.
 * Never create/refresh a session and never trust user_metadata as authorization.
 */
export function createOwnerVerifier(options: AuthOptions) {
  return async (req: Request): Promise<{ sub: string } | null> => {
    const auth = req.headers.get('authorization');
    if (!auth || auth.length > 16384) return null;
    const match = /^Bearer ([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)$/i.exec(auth);
    if (!match) return null;
    if (!options.url || !options.publishableKey) throw new ApiError('service_unavailable');
    const base = options.url.replace(/\/$/, '');
    let claims: any;
    try {
      const part = match[1].split('.')[1].replaceAll('-', '+').replaceAll('_', '/');
      const bytes = Uint8Array.from(atob(part + '='.repeat((4 - part.length % 4) % 4)), c => c.charCodeAt(0));
      claims = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
    } catch { return null; }
    const aud = claims?.aud;
    if (typeof claims?.sub !== 'string' || !UUID.test(claims.sub) || claims.role !== 'authenticated' || !(aud === 'authenticated' || Array.isArray(aud) && aud.includes('authenticated')) || claims.iss !== `${base}/auth/v1` || !Number.isFinite(claims.exp) || claims.exp * 1000 <= Date.now()) return null;
    try {
      const response = await (options.fetch ?? globalThis.fetch)(`${base}/auth/v1/user`, {
        method: 'GET', headers: { apikey: options.publishableKey, Authorization: `Bearer ${match[1]}` },
        redirect: 'error', cache: 'no-store', signal: AbortSignal.timeout(5000),
      });
      if (response.status === 401 || response.status === 403) { await response.body?.cancel(); return null; }
      if (!response.ok) { await response.body?.cancel(); throw new ApiError('service_unavailable'); }
      const user = await response.json();
      if (user?.id !== claims.sub) return null;
      return { sub: claims.sub };
    } catch { throw new ApiError('service_unavailable'); }
  };
}
