import { canonicalJson, sha256Hex } from './crypto.ts';
export type StoreResult = { data?: any; code?: string; replayed?: boolean; retryAfterSeconds?: number };
export type Query = (sql: string, params: any[]) => Promise<{ rows: any[] }>;
export function createSqlStore(query: Query) {
  async function call(name: string, args: any[], casts: string[]): Promise<StoreResult> {
    const sql = `select schediel_private.${name}(${args.map((_, i) => `$${i + 1}::${casts[i]}`).join(',')}) as result`;
    const result = await query(sql, args);
    if (result.rows.length !== 1 || !result.rows[0].result) throw new Error('Invalid database result');
    return result.rows[0].result;
  }
  return {
    rate: (scope: string, subjectHash: string) => call('take_rate', [scope, subjectHash], ['text', 'text']),
    async create(owner: string, key: string, body: any) {
      return call('create_share', [owner, await sha256Hex(key), await sha256Hex(canonicalJson(body)), JSON.stringify(body.payload), body.tokenDigest, body.expiresAt, new TextEncoder().encode(JSON.stringify(body.payload)).byteLength], ['uuid', 'text', 'text', 'jsonb', 'text', 'timestamptz', 'integer']);
    },
    get: (owner: string, id: string) => call('get_share', [owner, id], ['uuid', 'uuid']),
    revoke: (owner: string, id: string) => call('revoke_share', [owner, id], ['uuid', 'uuid']),
    resolve: (id: string, digest: string, versions: string[], addressHash: string) => call('resolve_share', [id, digest, versions, addressHash], ['uuid', 'text', 'text[]', 'text']),
    async deleteBackendData(owner: string, key: string, body: any) {
      return call('delete_backend_data', [owner, await sha256Hex(key), await sha256Hex(canonicalJson(body)), body.confirm], ['uuid', 'text', 'text', 'text']);
    },
    deletionJob: (owner: string, id: string) => call('get_deletion_job', [owner, id], ['uuid', 'uuid']),
    list: (owner: string, cursor: string | null, limit: number) => call('list_shares', [owner, cursor, limit], ['uuid', 'uuid', 'integer']),
  };
}
export type ShareStore = ReturnType<typeof createSqlStore>;
