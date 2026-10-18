# Frozen sharing backend implementation plan

**Goal:** implement `contracts/openapi.yaml` locally, without deployments, credentials, contract edits or commits.

**Architecture:** injectable Fetch handlers call a parameterized SQL store. Security-definer operations in the unexposed `schediel_private` schema enforce explicit verified-owner/capability checks. Node 24 runs erasable TypeScript; PGlite runs the actual migration and PostgreSQL functions, never a replacement database.

**Specifications:** `../CONTRACTS.md` sections 5/7/8; `../SCHEDULER_SPEC.md` sections 9/13–16; frozen schemas and fixtures in `../contracts/`.

## Vertical slices (RED → GREEN each)

1. Payload validation and canonical bearer-token decoding: fixture-by-fixture validation plus byte/count/Unicode boundaries.
2. Atomic create and owner metadata: actual PostgreSQL migration; RLS/grants, owner isolation, idempotency and quotas.
3. Public resolve/revoke: digest-first availability checks, serialized authorization and persistent hashed-address rate limits.
4. Privacy deletion: explicit confirmation, atomic revocation/deletion and owner-only progress; no image/scan subsystem is enabled.
5. Fetch HTTP handlers over the same PGlite store: exact status/envelope/headers, strict inputs, pagination, secret-safe failures and closed scanning gate.
6. Thin Deno/Supabase runtime wiring: verified Auth subject only, publishable-key-compatible public resolver, private Postgres connection; documentation and full local verification.

## Review focus

- Replays after expiry/revocation/deletion must not recreate a capability.
- Wrong tokens must not disclose expired/revoked/unsupported states.
- Unknown keys and malformed encodings must be rejected without reflecting their values in errors.
- Concurrent create/revoke/resolve/deletion operations must take consistent locks.
- Missing production configuration must fail closed; cloud scanning stays disabled.

All product changes remain under `backend/`. Test runs and actual results are recorded in the final report, not represented by invented output.
