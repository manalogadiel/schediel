# Static share preview implementation plan

**Goal:** locally verified, read-only browser resolution of approved Schediel snapshots. No deployment or commits.

**Spec:** `../contracts/openapi.yaml` (`resolveSharePreview`), `../contracts/schemas/share-payload-v1.schema.json`, shared fixtures, `../SCHEDULER_SPEC.md` 9.3/13.4, and `../DESIGN.md`.

**Architecture:** static HTML, system-font CSS and browser ES modules. A small pure contract validator is independent of the DOM. The browser controller owns the fragment secret in a closure. An environment-driven Node script creates the complete static `dist/` tree; tests configure only isolated temporary directories.

**Constraints:** modify only `web-preview/`; no runtime dependencies, bundler, third-party resources, analytics, identity creation, import action, custom-scheme links, fabricated store listings or association identities. No token in query, path, headers, logs or storage. Strict canonical lowercase-UUID/32-byte-base64url links only.

**Design:** single left-aligned agenda column with an understated product name, status/live region, read-only explanation, one open-app action and content-sized schedule rows. Tokens: canvas `#F5F5F7`, ink `#1D1D1F`, surface `#FFFFFF`, secondary `#5A5A60`, action `#0066CC`; coherent dark tokens from DESIGN.md. System type at 30/22/17/14px, 16/24/32px spacing, 18px grouped-surface radius and 48px actions. No hero, ornamental metrics, gradients, animations or fake sample content.

## Vertical TDD slices

1. `src/link.js`, `test/link.test.js`: canonical link parsing, invalid input rejection and immediate history scrubbing. Write/run RED before implementation, then GREEN.
2. `src/validate.js`, `test/validate.test.js`: payload version/shape/semantic validation with JSON Pointer errors; valid and invalid shared fixtures, Unicode/size/policy/exception boundaries. RED/GREEN each behavior group.
3. `src/index.html`, `src/app.js`, `src/main.js`, `src/style.css`, `test/app.test.js`, `test-support/browser.js`: real HTML and controller in jsdom, body-only token POST with strict fetch options, loading/success, terminal errors and explicit retry. Add fixture rendering, source/local zone and date-only/point/recurrence coverage, safe text, accessibility and metadata/resource constraints in successive RED/GREEN cycles.
4. `scripts/configure.mjs`, `test/configure.test.js`: required HTTPS origins, safe generated config/CSP, static routing/privacy headers and opt-in real association inputs. Spawn configuration in isolated directories; prove missing required/optional cases and reconfiguration cleanup.
5. `README.md`: commands, security model and honest deployment/native-verification limits. Run the full suite and an isolated static build/smoke check, inspect changes and report exact test totals.

## Review focus

- Noncanonical token padding bits, encoded/duplicated fragments and invalid routes must never cause a fetch.
- Mismatched metadata counts, unknown fields and policy-excluded details must fail closed.
- Date-only end-exclusive ranges and point times must never acquire a fabricated timestamp/end.
- Weekly seeds on unselected weekdays and DST resolution flags must not be displayed as invented occurrences.
- Generated build artifacts must not accidentally contain stale associations or permissive CSP after reconfiguration.
