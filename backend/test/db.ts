import { PGlite } from '@electric-sql/pglite';
import { readFileSync, readdirSync } from 'node:fs';
export const A = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
export const B = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
export async function database() {
  const db = new PGlite();
  await db.exec(`
    create role anon nologin; create role authenticated nologin; create role service_role nologin;
    create schema auth;
    create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  `);
  const directory = new URL('../supabase/migrations/', import.meta.url);
  for (const file of readdirSync(directory).filter(name => name.endsWith('.sql')).sort()) {
    await db.exec(readFileSync(new URL(file, directory), 'utf8'));
  }
  return db;
}
export async function call(db: PGlite, name: string, args: unknown[], casts: string[]) {
  const sql = `select schediel_private.${name}(${args.map((_, i) => `$${i + 1}::${casts[i]}`).join(',')}) as result`;
  return (await db.query<{result: any}>(sql, args)).rows[0].result;
}
