import { UUID, validatePayload, validDate } from './validator.ts';
import { digestToken, sha256Hex } from './crypto.ts';
import { ApiError, errors } from './errors.ts';
import type { ShareStore, StoreResult } from './sql-store.ts';
export type Dependencies = {
  store: ShareStore;
  verifyOwner: (request: Request) => Promise<{ sub: string } | null>;
  addressHash: (request: Request) => Promise<string>;
  allowedOrigins?: string[];
};
const object = (v: any) => v !== null && typeof v === 'object' && !Array.isArray(v);
function shape(v: any, allowed: string[]) {
  if (!object(v) || Object.keys(v).some(k => !allowed.includes(k)) || allowed.some(k => !Object.hasOwn(v, k))) throw new ApiError('invalid_request');
}
function idempotency(req: Request) {
  const key = req.headers.get('Idempotency-Key');
  if (!key || !UUID.test(key)) throw new ApiError('idempotency_key_required');
  return key;
}
async function jsonBody(req: Request, max: number): Promise<any> {
  if (!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(req.headers.get('content-type') ?? '') || !['identity', null].includes(req.headers.get('content-encoding'))) throw new ApiError('unsupported_media_type');
  const length = req.headers.get('content-length');
  if (length !== null && (!/^\d+$/.test(length) || Number(length) > max)) throw new ApiError('payload_too_large');
  const reader = req.body?.getReader();
  if (!reader) throw new ApiError('invalid_request');
  const chunks: Uint8Array[] = []; let size = 0;
  try {
    while (true) {
      const { value, done } = await reader.read(); if (done) break;
      size += value.byteLength;
      if (size > max) { await reader.cancel(); throw new ApiError('payload_too_large'); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(size); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  try { return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)); }
  catch { throw new ApiError('invalid_request'); }
}
function checked(result: StoreResult) {
  if (result.code) throw new ApiError(result.code, undefined, result.retryAfterSeconds);
  if (result.data === undefined) throw new Error('Missing result');
  return result.data;
}
function timestamp(v: unknown) {
  return typeof v === 'string' && /^\d{4}-\d{2}-\d{2}T([01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,9})?Z$/.test(v) && validDate(v.slice(0, 10)) && Number.isFinite(Date.parse(v));
}
export function createHandler(deps: Dependencies) {
  return async function handle(req: Request): Promise<Response> {
    const requestId = crypto.randomUUID();
    const headers = new Headers({ 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store, private', 'Referrer-Policy': 'no-referrer', 'X-Content-Type-Options': 'nosniff', 'Vary': 'Origin' });
    const reply = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers });
    try {
      const url = new URL(req.url), origin = req.headers.get('origin');
      if (origin) {
        if (!deps.allowedOrigins?.includes(origin)) throw new ApiError('forbidden');
        headers.set('Access-Control-Allow-Origin', origin);
        headers.set('Access-Control-Expose-Headers', 'Idempotent-Replayed, Retry-After');
      }
      if (req.method === 'OPTIONS') {
        headers.set('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
        headers.set('Access-Control-Allow-Headers', 'authorization, apikey, content-type, idempotency-key');
        return new Response(null, { status: 204, headers });
      }
      if (!url.pathname.startsWith('/functions/v1/')) throw new ApiError('not_found');
      const path = url.pathname.slice('/functions/v1'.length);
      if (path === '/health' && req.method === 'GET') {
        if (url.search) throw new ApiError('invalid_request');
        return reply({ status: 'ok' });
      }
      if (path === '/share-resolve') {
        if (req.method !== 'POST') throw new ApiError('not_found');
        if (url.search) throw new ApiError('invalid_request');
        const body = await jsonBody(req, 4096);
        shape(body, ['shareId', 'token', 'supportedSchemaVersions']);
        const digest = await digestToken(body.token);
        if (!digest) throw new ApiError('invalid_token');
        if (typeof body.shareId !== 'string' || !UUID.test(body.shareId) || !Array.isArray(body.supportedSchemaVersions) || body.supportedSchemaVersions.length < 1 || body.supportedSchemaVersions.length > 5 || body.supportedSchemaVersions.some((v: unknown) => typeof v !== 'string' || [...v].length > 10)) throw new ApiError('invalid_request');
        const addressHash = await deps.addressHash(req);
        return reply(checked(await deps.store.resolve(body.shareId, digest, body.supportedSchemaVersions, addressHash)));
      }
      const scan = (path === '/scan/assets' && req.method === 'POST') || (path === '/scan/jobs' && req.method === 'POST') || (/^\/scan\/assets\/[^/]+$/.test(path) && req.method === 'DELETE') || (/^\/scan\/jobs\/[^/]+$/.test(path) && ['GET', 'DELETE'].includes(req.method));
      if (!scan && !/^\/share-links(?:\/[^/]+)?$/.test(path) && path !== '/privacy/delete-backend-data' && !/^\/privacy\/deletion-jobs\/[^/]+$/.test(path)) throw new ApiError('not_found');
      const owner = await deps.verifyOwner(req);
      if (!owner || !UUID.test(owner.sub)) throw new ApiError('unauthenticated');
      if (scan) throw new ApiError('scan_unavailable');
      checked(await deps.store.rate('management', await sha256Hex(owner.sub)));
      if (path === '/privacy/delete-backend-data' && req.method === 'POST') {
        if (url.search) throw new ApiError('invalid_request');
        const key = idempotency(req), body = await jsonBody(req, 1024);
        shape(body, ['confirm']);
        if (body.confirm !== 'delete-backend-data') throw new ApiError('invalid_request');
        return reply(checked(await deps.store.deleteBackendData(owner.sub, key, body)), 202);
      }
      const deletion = /^\/privacy\/deletion-jobs\/([^/]+)$/.exec(path);
      if (deletion && req.method === 'GET') {
        if (!UUID.test(deletion[1])) throw new ApiError('not_found');
        if (url.search) throw new ApiError('invalid_request');
        return reply(checked(await deps.store.deletionJob(owner.sub, deletion[1])));
      }
      if (path === '/share-links' && req.method === 'POST') {
        if (url.search) throw new ApiError('invalid_request');
        const key = idempotency(req), body = await jsonBody(req, 524288 + 16384);
        shape(body, ['schemaVersion', 'payload', 'tokenDigest', 'expiresAt']);
        if (body.schemaVersion !== '1.0') throw new ApiError('unsupported_schema_version');
        if (typeof body.tokenDigest !== 'string' || !/^[0-9a-f]{64}$/.test(body.tokenDigest) || !timestamp(body.expiresAt)) throw new ApiError('invalid_request');
        const issues = validatePayload(body.payload);
        if (issues.length) {
          if (issues.some(e => e.code === 'unsupported_version')) throw new ApiError('unsupported_schema_version');
          if (issues.some(e => e.code === 'payload_too_large')) throw new ApiError('payload_too_large');
          // Unknown key names are attacker-controlled text; do not reflect them.
          const fields = issues.slice(0, 50).map(e => ({ code: e.code, path: '/payload' + (e.code === 'unknown_field' ? e.path.slice(0, e.path.lastIndexOf('/')) : e.path) })).filter(e => e.path.length <= 200);
          throw new ApiError('validation_failed', fields);
        }
        const result = await deps.store.create(owner.sub, key, body), data = checked(result);
        headers.set('Idempotent-Replayed', String(result.replayed === true));
        return reply(data, 201);
      }
      if (path === '/share-links' && req.method === 'GET') {
        for (const key of url.searchParams.keys()) if (!['limit', 'cursor'].includes(key) || url.searchParams.getAll(key).length !== 1) throw new ApiError('invalid_request');
        const limit = url.searchParams.get('limit') ?? '20', cursor = url.searchParams.get('cursor');
        if (!/^[1-9]\d?$/.test(limit) || Number(limit) > 50 || cursor !== null && !UUID.test(cursor)) throw new ApiError('invalid_request');
        return reply(checked(await deps.store.list(owner.sub, cursor, Number(limit))));
      }
      const match = /^\/share-links\/([^/]+)$/.exec(path);
      if (match && ['GET', 'DELETE'].includes(req.method)) {
        if (!UUID.test(match[1])) throw new ApiError('not_found');
        if (url.search) throw new ApiError('invalid_request');
        return reply(checked(await (req.method === 'DELETE' ? deps.store.revoke(owner.sub, match[1]) : deps.store.get(owner.sub, match[1]))));
      }
      throw new ApiError('not_found');
    } catch (failure) {
      const error = failure instanceof ApiError && Object.hasOwn(errors, failure.code) ? failure : new ApiError('internal_error');
      const spec = errors[error.code];
      const body: Record<string, unknown> = { code: error.code, message: spec.message, requestId, retryable: spec.retryable ?? false };
      if (error.fields?.length) body.fieldErrors = error.fields;
      if (Number.isInteger(error.retryAfterSeconds) && error.retryAfterSeconds! >= 0) { body.retryAfterSeconds = error.retryAfterSeconds; headers.set('Retry-After', String(error.retryAfterSeconds)); }
      return reply(body, spec.status);
    }
  };
}
