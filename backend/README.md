# Schediel sharing backend

This is the optional backend for immutable, expiring and revocable schedule links. Local schedules, widgets and on-device image review do not depend on it. **Nothing has been deployed.** Cloud image scanning is intentionally disabled.

## Layout and local checks

- `supabase/migrations/202610180001_sharing.sql`: unexposed `schediel_private` schema, deny-by-default RLS/grants, atomic ownership/idempotency/quota/revoke/resolve/deletion operations.
- `supabase/functions/_shared/`: strict payload validator, canonical token helpers, safe HTTP handlers, Auth verifier, parameterized Postgres store and runtime composition.
- `supabase/functions/{share-links,share-resolve,scan,privacy,health}`: thin Deno entry points.
- `test/`: shared payload fixtures, real Postgres SQL via PGlite, two-owner/public authorization, replay, quota, resolver, HTTP and runtime wiring tests. Auth and network inputs are injected test doubles; PGlite is not a deployed Supabase environment.

```sh
npm ci
npm test
npx --yes deno@2.5.4 check --node-modules-dir=none supabase/functions/share-links/index.ts supabase/functions/share-resolve/index.ts supabase/functions/privacy/index.ts supabase/functions/scan/index.ts supabase/functions/health/index.ts
```

Node 24+ is needed for TypeScript type stripping. `--node-modules-dir=none` makes Deno resolve the `npm:postgres@3.4.9` driver from its own cache instead of this test-only `node_modules`; the driver import is a literal so deployment bundling can include it. Deno check verifies source types, not a real database connection or edge deployment. See `../contracts/openapi.yaml` for the frozen `/functions/v1` transport.

## Required backend environment

Supply credentials through the platform secret manager, never Flutter, browser JavaScript, git or chat:

| Variable | Purpose |
|---|---|
| `SUPABASE_URL` | Actual Supabase project origin |
| `SUPABASE_PUBLISHABLE_KEYS` | Platform-provided JSON mapping with the `default` public key, when available |
| `SUPABASE_PUBLISHABLE_KEY` / `SUPABASE_ANON_KEY` | Public-key fallback when the mapping is absent |
| `SCHEDIEL_DATABASE_URL` / `SUPABASE_DB_URL` | Private Postgres connection for a role allowed to `SET ROLE service_role`; a TLS connection is required except localhost |
| `SCHEDIEL_DATABASE_CA` | PEM of the Supabase database root certificate (Dashboard → Database → Settings → SSL Configuration → Download certificate). Supabase certificates are not signed by a public CA, so verified TLS needs it; public, not a secret |
| `SCHEDIEL_ALLOWED_ORIGINS` | Comma-separated exact browser origins, including the owned share site |
| `SCHEDIEL_RATE_HASH_SECRET` | Server-only random HMAC key of at least 32 UTF-8 bytes; never publish it |
| `SCHEDIEL_TRUST_PROXY_HEADERS` | Must be explicitly `true` **only after** the ingress header overwrite behavior is verified |
| `SCHEDIEL_TRUSTED_IP_HEADER` | Verified single-address header: `cf-connecting-ip`, `x-real-ip` or `x-forwarded-for` |

Resolver requests fail closed with 503 if the trusted-address policy is not configured. A forwarded list of addresses is deliberately rejected. Never trust an arbitrary caller-supplied header. Production ingress/proxy behavior must be demonstrated before enabling public sharing.

The config disables the gateway's `verify_jwt` checks deliberately: public resolution must accept non-JWT publishable keys, and management authorization is performed inside the handler using **Supabase Auth GET /user**, followed by strict subject/issuer/role/expiry checks. Management requests without verified user credentials return 401. This is custom verification, not an unauthenticated management API. Do not remove the verifier. Review against Supabase's current authentication guidance before deployment.

## Server policy

Single authoritative quota configuration is the `schediel_private.policy` row created by the migration:

- 20 active links per owner.
- 50 creations per owner per UTC day; 5,000 global per UTC day.
- 60 resolver attempts per hashed network address per minute; 120 management calls per owner per minute.

These are conservative engineering defaults, not measured capacity or paid-provider allowances. Public rollout requires approval and load testing. Snapshot expiry accepts one hour through seven days with five-minute clock tolerance; app choices are one or seven days. Idempotency outcomes last 24 hours; expired records remain anti-replay tombstones and never create new resources. Snapshots contain at most 250 items, 500 exceptions and 512 KiB canonical UTF-8 JSON. Distinct category-label metadata is bounded to 20; over-limit snapshots are rejected, not silently shortened.

Deletion is a bounded sharing-only transaction. The POST returns a real completed deletion job when it finishes; the app reads the exact owner job before reporting completion. Other owners' rows and local schedules remain untouched. Minimal deletion receipts, anti-replay tombstones and hashed usage records remain. This does not delete a Supabase Auth identity or recall downloaded copies. There are no image objects/provider jobs while scanning is gated.

## Deployment (manual release gate)

Install the Supabase CLI using its documented method. From `backend/`, authenticate and link the **approved** project, review the migration, configure secret environment values, then run:

```sh
supabase db push
supabase functions deploy share-links
supabase functions deploy share-resolve
supabase functions deploy privacy
supabase functions deploy scan
supabase functions deploy health
```

Do not expose `schediel_private` in Data API schemas. Enable anonymous sign-ins only for explicit online creation, configure abuse/CAPTCHA policy before public rollout, and test management/resolution with two real identities and a public browser. Verify proxy overwrites, CORS, TLS, request-body log redaction and real Postgres behavior. A deployment still needs a verified owned domain, signing associations and cold/warm mobile link tests. Use separate staging/production projects; no project, region, signing identity or domain is invented here.

The API never returns a bearer secret in owner metadata. The client stores the random secret locally and sends only its digest on creation; public resolution sends the canonical token in a no-store POST body. Rate-limit hashes and request IDs are not personal schedule logs. Do not enable body/URL logging upstream. Retention, monitoring, backup, load and security review remain production gates; these local tests are not certification.
