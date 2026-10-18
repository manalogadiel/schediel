import { createOwnerVerifier } from './auth.ts';
import { createHandler } from './handlers.ts';
import { hashAddress } from './crypto.ts';
import { createSqlStore } from './sql-store.ts';
import type { Query } from './sql-store.ts';
import { ApiError } from './errors.ts';
type Environment = Record<string, string | undefined>;
function publicKey(env: Environment) {
  if (env.SUPABASE_PUBLISHABLE_KEYS) {
    try { const key = JSON.parse(env.SUPABASE_PUBLISHABLE_KEYS).default; if (typeof key === 'string' && key) return key; } catch { return undefined; }
  }
  return env.SUPABASE_PUBLISHABLE_KEY || env.SUPABASE_ANON_KEY;
}
function projectUrl(env: Environment) {
  try {
    const url = new URL(env.SUPABASE_URL ?? '');
    const local = ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname);
    if (url.username || url.password || url.search || url.hash || url.pathname !== '/' || url.protocol !== 'https:' && !(local && url.protocol === 'http:')) return undefined;
    return url.origin;
  } catch { return undefined; }
}
function canonicalAddress(value: string | null): string | null {
  if (!value || value.length > 64 || value.trim() !== value) return null;
  if (/^(0|[1-9]\d{0,2})(\.(0|[1-9]\d{0,2})){3}$/.test(value)) return value.split('.').every(p => Number(p) <= 255) ? value : null;
  if (!/^[0-9A-Fa-f:.]+$/.test(value) || !value.includes(':')) return null;
  try { return new URL(`http://[${value}]/`).hostname.slice(1, -1).toLowerCase(); } catch { return null; }
}
function databaseQuery(env: Environment): Query {
  let connection: Promise<any> | undefined;
  return async (text, params) => {
    try {
      const databaseUrl = env.SCHEDIEL_DATABASE_URL || env.SUPABASE_DB_URL;
      if (!databaseUrl) throw new Error('Missing database configuration');
      if (!connection) connection = (async () => {
        const url = new URL(databaseUrl);
        if (!['postgres:', 'postgresql:'].includes(url.protocol)) throw new Error('Invalid database configuration');
        const local = ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname);
        // A literal specifier keeps the driver in the deployment module graph
        // (the bundler only packages statically discoverable npm imports).
        // Dynamic, so Node/PGlite tests that inject `query` never load it.
        const { default: postgres } = await import('npm:postgres@3.4.9');
        return postgres(databaseUrl, {
          max: 1, prepare: false, connect_timeout: 5, idle_timeout: 20,
          ssl: local ? false : { rejectUnauthorized: true },
          debug: false, onnotice: () => {},
        });
      })();
      const sql = await connection;
      return await sql.begin(async (transaction: any) => {
        await transaction.unsafe("set local role service_role; set local statement_timeout='5s'; set local lock_timeout='3s'");
        return { rows: await transaction.unsafe(text, params) };
      });
    } catch { connection = undefined; throw new ApiError('service_unavailable'); }
  };
}
/** No Deno globals here: the same runtime composition is exercised by Node/PGlite. */
export function createRuntimeHandler(env: Environment, injected: { query?: Query; fetch?: typeof globalThis.fetch } = {}) {
  const store = createSqlStore(injected.query ?? databaseQuery(env));
  return createHandler({
    store,
    verifyOwner: createOwnerVerifier({ url: projectUrl(env), publishableKey: publicKey(env), fetch: injected.fetch }),
    allowedOrigins: (env.SCHEDIEL_ALLOWED_ORIGINS ?? '').split(',').map(s => s.trim()).filter(Boolean),
    addressHash: async req => {
      // No proxy/header trust is guessed. The operator must verify overwrite behavior.
      const header = env.SCHEDIEL_TRUSTED_IP_HEADER;
      const secret = env.SCHEDIEL_RATE_HASH_SECRET;
      if (env.SCHEDIEL_TRUST_PROXY_HEADERS !== 'true' || !header || !['cf-connecting-ip', 'x-real-ip', 'x-forwarded-for'].includes(header) || !secret || new TextEncoder().encode(secret).byteLength < 32) throw new ApiError('service_unavailable');
      const address = canonicalAddress(req.headers.get(header));
      if (!address) throw new ApiError('service_unavailable');
      return hashAddress(address, secret);
    },
  });
}
