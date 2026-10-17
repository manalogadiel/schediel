# Scheduling app: typed data and integration contracts

**Status:** proposed version 1.0 contracts for approval before code. These tables define payloads and behavior; they are not live API responses, generated data, database migrations or claims that endpoints exist.

Read [SCHEDULER_SPEC.md](SCHEDULER_SPEC.md) for scope, platform limits, privacy and acceptance tests, and [DESIGN.md](DESIGN.md) for visual rules. If a table here conflicts with the main specification, resolve the inconsistency before implementation rather than silently choosing one.

## 1. Common conventions

- Wire field names use `camelCase`; local SQL names may use `snake_case` with explicit mapping.
- Contract version is a required string, initially `1.0`. Unknown major versions are rejected; optional-field compatibility must be explicitly tested.
- UUIDs are opaque valid identifiers generated through a vetted implementation, not display labels or security credentials.
- Calendar dates are validated `YYYY-MM-DD` values. Clock values are validated 24-hour `HH:mm` values. Pattern matching alone does not validate a real date.
- Timed schedules carry a valid IANA time-zone identifier. A fixed offset is not a replacement for a zone.
- Transport timestamps are UTC RFC 3339 values. Device clock time is not trusted as server creation/expiry authority.
- Optional known fields use explicit nullability. Unknown keys in security-sensitive payloads are rejected rather than silently interpreted as new capabilities.
- Preserve original user/source content. Validation must not repair malformed identifiers, guess dates or rewrite names to make a request pass.
- Text-length limits use Unicode code-point counts consistently on client and server; UTF-8 payload byte limits are enforced separately. Rendering must remain safe for combining marks, emoji and bidirectional text.
- Descriptions are plain text. No untrusted HTML, executable theme data or arbitrary remote SVG is accepted.
- Every list has an enforced maximum. Every recurrence query has a finite window and expansion cap.

## 2. Canonical schedule item

This shape is shared conceptually across manual events, validated imports and share snapshots. A local record adds local IDs/timestamps/alert rules; it must not accidentally serialize those private fields into a share.

| Field | Type | Required | Validation / meaning |
|---|---|---|---|
| `sourceItemId` | UUID string | Yes for import/share | Stable within the source snapshot; remap to a new local series ID on import |
| `revision` | Positive integer | Yes | Source revision, not an authorization claim |
| `title` | String | Yes | Nonempty, at most 120 code points |
| `categoryLabel` | String or null | Yes, nullable | Shared label only; never a trusted foreign local category ID |
| `time` | `TimedSpec` or `DateOnlySpec` | Yes | Discriminated union; required fields depend on kind |
| `recurrence` | `RecurrenceSpec` or null | Yes, nullable | Null for one-time entry |
| `details` | `DetailsSpec` | Yes | Nullable detail values; no filler text |
| `exceptions` | Array of `ExceptionSpec` | Yes | Empty is allowed; enforce configured count and uniqueness |

### 2.1 TimedSpec

| Field | Type | Validation |
|---|---|---|
| `kind` | Literal `timed` | Discriminator |
| `startDate` | Calendar date | Seed date / earliest allowed recurrence date |
| `startTime` | Clock time | Explicitly resolved; not inferred from an unspecified date |
| `timeZone` | IANA zone string | Supported by the pinned zone database |
| `endTime` | Clock time or null | Null means explicitly no end time; do not invent a duration |
| `endDayOffset` | Nonnegative integer or null | Required with end time; null without it; recurring v1 supports same-day or next-day ending only |
| `seedTimeResolution` | `earlier`, `later` or null | Explicit resolution for an ambiguous seed instant; normal unambiguous times use null |

For a one-time multi-day timed event, any broader end-day range must be explicitly approved and bounded in implementation. Do not pretend the recurring subset already supports arbitrary multi-day recurrence.

Each recurrence uses local clock semantics in the source zone. A future ambiguous/nonexistent instance is unresolved unless an explicit valid occurrence override resolves it. Never silently use the device zone or carry forward a fixed UTC offset.

### 2.2 DateOnlySpec

| Field | Type | Validation |
|---|---|---|
| `kind` | Literal `dateOnly` | Discriminator |
| `startDate` | Calendar date | Required known date |
| `endDateExclusive` | Calendar date | Must be after start; a single-date item ends on the following calendar date by representation, not by inventing a time |

No start time, UTC midnight, fixed offset or duration is inserted into date-only data. A reminder anchor time/zone belongs to the recipient's local alert rule, not the shared date-only item.

### 2.3 RecurrenceSpec

| Field | Type | Validation |
|---|---|---|
| `frequency` | `daily` or `weekly` | Only supported v1 values |
| `interval` | Literal integer `1` | Advanced intervals are future scope unless the product decision changes |
| `weekdays` | Array of ISO weekday integers | Weekly: nonempty unique values from 1 through 7; daily: empty |
| `untilDateInclusive` | Calendar date or null | Not before seed start; null is unbounded recurrence definition, not permission for unbounded expansion |

The seed date limits the first occurrence. Weekly selection can begin on a later selected day. Display-week start is a preference, not a reason to reinterpret stored weekday identities. Unsupported count/month/year/complex recurrence fields are rejected with an editable explanation rather than dropped.

### 2.4 DetailsSpec

| Field | Type | Bound / behavior |
|---|---|---|
| `location` | String or null | 240 code points |
| `professor` | String or null | 160 code points; optional for non-school use |
| `subtitle` | String or null | 240 code points |
| `notes` | String or null | 4,000 code points; may be excluded from a share |

Absence removes the corresponding display line. Empty optional input may be stored as null by an explicit schema rule; do not replace it with an invented room, instructor or subtitle.

### 2.5 ExceptionSpec

| Field | Type | Meaning |
|---|---|---|
| `originalOccurrenceKey` | Validated structured identity/string | Refers to the original recurrence instance, not its moved time |
| `action` | `cancel` or `override` | Explicit operation |
| `replacement` | Complete resolved one-time item or null | Required for override; null for cancel; has no nested recurrence/exceptions |

The original key is scoped to the source series. On recipient import, remap it to the new local series identity without changing the referenced original occurrence. Duplicate exception keys are invalid.

An override must remain within supported time-kind behavior. Do not silently convert an entire weekly series when the user edits one instance. A whole-series change that invalidates exception keys requires a review/reconciliation step.

## 3. Local alert rule and native status

Alert preferences are local-only. They are not inherited from a shared snapshot unless the recipient explicitly creates their own rule during import.

### 3.1 Desired rule

| Field | Type | Meaning |
|---|---|---|
| `id` | Local UUID | Stable local alert identity |
| `scope` | Series or occurrence identity | One entire rule or explicit occurrence override |
| `kind` | `notification` or `alarm` | Independent rules may coexist |
| `enabled` | Boolean | User preference, not OS permission status |
| `offsetMinutes` | Nonnegative integer | Zero is at the anchor; upper bound configured before release |
| `dateOnlyAnchorTime` | Clock time or null | Required for an enabled alert on a date-only item |
| `dateOnlyAnchorZone` | IANA zone or null | Required with a date-only anchor time |
| `lockScreenDetails` | `titleOnly` or `detailsRequested` | Requested disclosure; OS privacy remains authoritative |
| `presentationPreference` | `standard` or `prominentIfSupported` | Does not force an unsupported full-screen takeover |
| `snoozePreference` | Supported duration or null | Only offered where the native implementation can honor it |

Alarm lead times are calculated from actual occurrence instants using the selected zone. If the resulting trigger is already past, ask or leave it unscheduled; do not automatically ring on import.

### 3.2 Actual scheduled request

| Field | Type | Meaning |
|---|---|---|
| `requestKey` | Stable opaque local key | Deterministic identity for rule + occurrence + platform |
| `sourceRevision` | Integer | Detects stale requests after edits |
| `nativeRequestId` | Platform opaque string or null | Only stored when returned/assigned by the adapter |
| `triggerAt` | UTC timestamp | Intended trigger, not a delivery receipt |
| `status` | Explicit enum | See states below |
| `errorCode` | Safe enum/string or null | User-visible category, not raw native/provider stack trace |
| `lastReconciledAt` | UTC timestamp | Diagnostic state |

States: `off`, `needsPermission`, `pendingSchedule`, `scheduled`, `blocked`, `failed`, `unscheduledCapacity`, `externalUnverified`, `cancelled`.

Mapping between camelCase contract state and local enum/storage names must be explicit. A Clock hand-off stays `externalUnverified`; it is not automatically promoted to `scheduled`. Native acceptance does not prove eventual ringing or override device settings.

### 3.3 Reconciliation invariants

- Domain save + outbox insertion is one transaction.
- A retry uses the same request identity; it does not append a duplicate alarm.
- A changed occurrence invalidates obsolete requests before claiming the new state is scheduled.
- Filter changes affect visibility only; they do not enable/disable unrelated alert rules.
- Snooze changes only the supported alert's next action, never the schedule's start date/time.
- Capacity/horizon exhaustion is visible and tested, not hidden behind an enabled toggle.

## 4. Import candidate contract

Import candidates deliberately allow unresolved fields that the canonical active-schedule contract does not.

| Field | Type | Meaning |
|---|---|---|
| `candidateId` | Opaque unique string | Stable across edits/review within a draft |
| `sourceRevision` | Integer | Identifies the image/snapshot revision analyzed |
| `proposedItem` | Partial canonical fields | Missing values stay null/unresolved |
| `fieldEvidence` | Array of `FieldEvidence` | Source-backed context per field |
| `warnings` | Bounded array of typed warnings | Missing year/time, ambiguity, association, duplicate, overlap, unsupported pattern |
| `selectionState` | Local boolean | Recipient/user decision; not model authority |
| `reviewState` | `needsReview`, `ready`, `excluded` | Local validation status |

`FieldEvidence` contains field path, origin (`observed`, `userSupplied`, `inferredSuggestion`, `unresolved`), optional exact OCR span and optional validated image region. A region includes normalized coordinates and image revision/dimensions; invalid or unsupported coordinates are not drawn as if verified.

An inferred suggestion must be labelled. The model cannot mark its own output as user-confirmed. Do not expose model self-confidence as a calibrated percentage.

### 4.1 Required unknown-field behavior

| Source condition | Contract result |
|---|---|
| Printed date has no year | Year unresolved; confirmation required |
| Weekdays but no term start | Series start unresolved until user supplies context |
| Time lacks AM/PM and is ambiguous | Unresolved choice, not guessed locale certainty |
| End time absent | Null end; explicit no-end/date-only choice where appropriate |
| Room/professor absent | Null fields; no generated fallback |
| Table alignment unclear | Association warning; candidate cannot silently become ready |
| No relevant schedule found | Honest empty result; not a fabricated candidate |
| Candidate count beyond configured limit | Explicit density/truncation problem and smaller-crop action |

### 4.2 Import transaction

Input is a draft ID, selected candidate IDs, final validated items, category mappings and explicit local alert choices. Confirmed data is written once with provenance and reconciliation work. The transaction must reject duplicate submission or recover by looking up provenance after uncertain completion.

A failed alert API call after commit does not roll back already saved schedules without telling the user. It changes alert status and offers a targeted retry.

## 5. Share snapshot contract

### 5.1 Shareable payload

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | Literal supported version string | Validated before parsing items |
| `items` | Bounded canonical-item array | Exactly the sender-approved selection |
| `sharedFieldPolicy` | Whitelisted field policy | Describes included/excluded optional details |

Server envelope adds snapshot ID/version, actual serialized item count, server creation/expiry and applicable availability state. Server-computed values are not trusted from the client.

Excluded by contract: source images, local file paths, owner/auth IDs, device IDs, native request IDs, active sender alert settings, hidden local schedules and unpublished drafts.

### 5.2 Scope semantics

- `Current filter` uses selected categories; it does not secretly mean only the rows currently visible on today's screen.
- If a date-range scope is offered, it is a separate explicit choice with a clear preview.
- `All schedules` includes saved series/one-time records in the selected scope, including past/ended records unless excluded visibly.
- A series is serialized as a rule plus exceptions, not expanded indefinitely.
- The preview's count is computed from the actual validated payload. Never reuse a client/model-declared total without checking.

### 5.3 Import semantics

Recipients create new local series IDs. Retain source snapshot/item/version provenance for repeated-import detection. Map category labels by choice. Preserve the time kind, source zone, recurrence and exceptions. Sender and recipient do not share editable database rows.

Exact source-identity duplicates default to skip, with an explicit keep-copy choice. Similar content/overlaps are warnings, not destructive automatic merges.

### 5.4 Availability and token semantics

- A valid bearer token grants only the intended read-only preview.
- It is not a session credential, owner ID or permission to mutate the source.
- Expired/revoked/invalid tokens do not return personal payloads.
- Revocation does not reach into recipient-local imported copies.
- Already downloaded previews cannot be recalled, and a response authorized before revocation commits may still finish. Subsequent authorization must fail.
- Creator link metadata does not reconstruct a token from its hash.
- The client creates and protects at least 32 random secret bytes before creation, sends only the digest, and composes an HTTPS `/s/{shareId}#token={secret}` link from returned non-secret metadata. Fragment preservation is a native/web proof gate.
- The backend, management responses and idempotency records contain no raw secret or complete bearer URL. Replay returns the existing metadata, not a new capability. Expired replays fail safely instead of creating another resource under the old key.

## 6. Native widget snapshot contract

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | Version string | Native reader compatibility gate |
| `dataRevision` | Monotonic local revision | Prevents mixed old/new snapshots |
| `generatedAt` | UTC timestamp | Actual generation time |
| `widgetInstanceId` | Native opaque ID | Per-widget isolation |
| `timeZoneContext` | Validated zone/display context | Needed for actual date/time labels |
| `configuration` | Supported configuration values | Layout/filter/detail/appearance/privacy choices |
| `occurrences` | Bounded resolved list | Actual IDs, start/end/date-only values, selected visible details and status |
| `futureStates` | Bounded native timeline/update description | Only strategies the platform can honor |
| `coverageEnd` | Timestamp/date bound or null | Known data coverage, not a promise of continuous execution |
| `warnings` | Bounded typed list | Unresolved time, stale coverage or safe open-app state |

A snapshot has no provider key, backend bearer URL, full image or active editor draft. Native writers/readers use an atomic/versioned hand-off. An unsupported version yields a safe open-app state.

Widget configuration is scoped per native widget ID. Rendering respects current native appearance; requested alpha, colors or glass style are not a platform guarantee. Never repaint wallpaper from an image into a widget.

## 7. Backend request and response envelopes

### 7.1 Safe error envelope

| Field | Type | Meaning |
|---|---|---|
| `code` | Stable machine-readable string | Transport/domain error category |
| `message` | Safe interface text | No secrets, private source text or provider stack trace |
| `requestId` | Opaque string | Correlates content-free diagnostics |
| `fieldErrors` | Optional bounded array | Field path + safe validation code |
| `retryable` | Boolean | A retry is permitted, not guaranteed to succeed |
| `retryAfterSeconds` | Optional nonnegative integer | Provided only when meaningful and safe |

Do not include a fake response body or pretend the provider was called when a job was rejected before execution.

### 7.2 Share creation

Input: supported payload, expiry choice, client-generated token digest and an idempotency key. The client has already persisted the cryptographically random secret in protected storage. Server verifies identity, digest format, schema, limits and quota; computes actual counts/payload hash; commits the snapshot/link/idempotency outcome atomically or with a recoverable documented equivalent. It never receives the raw secret during creation.

Proposed create body fields: `schemaVersion`, `payload`, `tokenDigest`, `expiresAt`; `Idempotency-Key` is a header. `expiresAt` is validated against server policy/time, not trusted device time. The response contains `shareId`, `snapshotVersion`, `routePath`, `createdAt`, `expiresAt` and server-computed `itemCount`, never the raw token.

Token encoding is canonical unpadded base64url of exactly 32 random bytes. `tokenDigest` is the lowercase hexadecimal SHA-256 digest of those raw bytes, not of an arbitrarily normalized text representation. At redemption, enforce a small encoded-length/character bound, decode exactly 32 bytes, verify canonical re-encoding, then hash/compare. Reject malformed tokens before lookup; never silently repair a received link or token.

Output: created resource ID/version, non-secret route metadata and server expiry/count. The client composes the bearer URL using the retained secret. A repeated identical request returns the same resource outcome while replay remains valid. A changed body with the same key conflicts. No raw secret/complete bearer URL is needed in the replay cache.

Owner list output contains paginated metadata and a cursor. Do not claim `total` or `hasMore` unless computed from the actual authorized query. Revoke is idempotent and never mutates recipient copies.

An exact owner status endpoint supports revoke read-back before the app claims the link is revoked. Losing the local secret does not make a hash recoverable; offer an explicit replacement-link action when ownership still exists.

### 7.3 Public resolve

Input: share ID, fragment-derived bearer token and supported schema versions, submitted in a redacted POST body. Output: only the permitted versioned snapshot and safe availability metadata. The resolver is read-only and rate-limited. It does not create an anonymous user, an import, a notification or a scan job.

Resolve body fields: `shareId`, `token`, `supportedSchemaVersions`. Only a matching capability may receive the payload or a known expired/revoked `410` state. Wrong/unknown capabilities and cross-owner management access do not expose owner metadata.

The fragment keeps the secret out of the ordinary HTTP route but not browser history, page scripts or application state. Do not log full incoming deep-link URIs. Demonstrate fragment preservation, no third-party scripts, no-store behavior and redaction before launch. Do not use a storage signed-download URL as a supposedly immediately revocable share capability.

### 7.4 Cloud scan job

Input: an owned validated asset ID, consent context, requested interpretation mode, supported candidate schema and optional bounded OCR evidence. No arbitrary provider URL, executable instruction, model credential or trusted owner ID is accepted from the client.

States:

`queued -> running -> reviewReady | failed | cancelled | unknown`

A result is a review draft, not active schedules. Polling or reopening a completed job cannot run another paid provider request. Atomically reserve owner/global usage and concurrency before dispatch, with a consistent lock order and no database lock held during network work. An uncertain provider outcome stays `unknown` with a conservative reservation; do not repeat a possibly billed call without provider idempotency or verified reconciliation. A cancelled job may already have incurred usage.

Cloud images must meet the main specification's normalized JPEG/PNG byte, pixel and dimension limits. Benchmark bounded decoding in the actual runtime; use an isolated worker rather than assuming hosted edge CPU/memory limits can accommodate it.

Asset cleanup is scoped to app-controlled storage. Privacy copy must not turn an app-side deletion into a promise that third-party operational logs instantly disappear.

### 7.5 Backend deletion

Input: authenticated identity and explicit confirmation scope. Output: deletion job/progress state. Revoke owned links, cancel owned pending jobs and clean private objects/results according to policy. Preserve local schedules unless a separate local deletion action was selected.

## 8. Validation and contract tests

Before implementation contracts are frozen:

- Test strict field/type/enum/date/zone and size validation on client and server.
- Test null/unresolved versus known optional values distinctly.
- Test scope/count consistency on the exact serialized snapshot.
- Test category mapping and source-ID remapping without cross-user mutation.
- Test canonical source identity/fingerprints with Unicode and identical times.
- Test future schema versions and malformed recurrence/exception relationships.
- Test owner A/owner B/public reads, writes, signed uploads and deletion attempts.
- Test idempotency crash/retry/expired-cache behavior, including secret response handling.
- Test source-image instructions as untrusted data, not executable authorization.
- Test widget schema changes and interrupted writes on native readers.
- Test alert desired/actual state divergence and honest UI after API/permission failure.

Implementation should generate or share schema definitions from these approved contracts and run cross-language fixtures. No production API, payload or test result is fabricated by this document.
