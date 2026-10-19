# Implementation and documentation validation

**Recorded:** October 18–19, 2026 (Windows 11, UTC+08:00).

## Status and boundaries

Schediel now has a Flutter implementation, Android native code, iOS source, a locally tested optional sharing backend and a static browser preview. **This is a development build, not a production or real-device certification.** Supabase/domain deployment has not occurred. Cloud scanning stays off. No schedule data, credentials or signing identities were invented to make a test look deployed.

Local implementation phases are distinct from the specification's acceptance/release gates. A unit/widget/source test must not be reported as a passing hardware, lifecycle, platform-policy, accessibility or OCR-accuracy scenario. The 48 acceptance IDs remain requirements, not 48 claimed passing device tests.

## Independent review findings and fixes

Independent source reviews found five issues that the passing suites had not caught. Each now has a regression test that failed before its fix:

1. **Deletion cleanup scope (R1).** The first successful completion readback of a backend-deletion job cleared *all* local link records and secrets, including links created later. A deletion command now records the links owned when it was created; completion cleans only those, and never pending creations (which may commit after the deletion).
2. **Identity-bound retries (R2).** Retrying an uncertain share creation could sign in a new anonymous identity and create a duplicate link. The submitting identity is now stored before the request; a retry never signs in and refuses (keeping the attempt) when the identity is missing or different.
3. **Expired deletion replay (R3).** A lost deletion response could leave an expired idempotency key that failed forever. The app now reports this and offers **Request deletion again**, which needs a new confirmation and uses a new key and scope.
4. **Browser hand-off (R4).** The preview's **Open in Schediel** navigated the same page to the token fragment, which stays in the browser. The button now appears only when a separate owned app-link origin is configured, and the app and Android manifest accept that host explicitly.
5. **Backend driver packaging.** The PostgreSQL driver was imported through a variable, invisible to deployment bundling. It is now a literal import; `deno info` lists `npm:postgres@3.4.9` in the function graph.

A second independent review of those fixes found three more gaps, also fixed with failing-first tests:

6. **Deletion scope per identity.** The server deletes only the calling identity's links, but the local scope included links made under an earlier anonymous identity, so their still-live secrets were erased. Each owned link now records its identity (on creation and on refresh); a deletion command covers only links of the identity sending it, never signs in, and is not replayed under a different identity.
7. **Fresh request after a lost response.** After **Request deletion again** lost its response, the next tap minted another key. The new command is saved before sending, so the screen now replays it.
8. **Unset hand-off host.** The Android build used an unresolvable placeholder for the optional hand-off host. On Android 11 and lower every verified host must verify, so this would have stopped the real share host from opening the app. When unset, it now repeats the share host.

Also tightened: the deletion request is sent only as the identity its scope was computed for (pinned authorization); a share attempt kept after an auth or rate-limit rejection now blocks creating a second link until it is retried or discarded; an expired session is refreshed (same identity) before a retry; the web preview rejects an app-link origin with a non-default port, matching the app.

## Theme revamp (themes, profile, themed widgets)

Recorded October 19, 2026. An independent review found four medium issues, all fixed with failing-first tests: unconfigured widgets would have switched to the themed look on upgrade (the migration now saves the `default` widget settings off); turning category colors on/off did not refresh widgets; Reduce Motion did not reach the theme cross-fade in production; the themed widget did not follow night mode while the app was closed (Android 12+ now uses day/night colors; Android 8–11 updates at the next widget refresh). Smaller suggestions applied: taller title fonts fit fewer holders instead of clipping; the settings preview draws hard shadows only on solid; native opacity is never below the tested minimum.

**On the phone (Samsung SM-A326B, Android 13, wireless adb), seen in screenshots:**

- All eight themes apply on Today, Week and Appearance; Midnight disables Mode with its note; Custom shows the hue slider.
- After the upgrade the existing widget kept its original look; with **Use app theme** on it rendered Clay, Pop, Pixel (notched, hard shadow on solid), Sketch and Midnight holders over the wallpaper, root transparent.
- Profile photo picked, cropped and saved as a 512×512 JPEG with no EXIF (read back from app storage); Today shows the avatar and greeting.

**Defects found only on the device and fixed (each with a test):** the Next pill stretched across the card; unselected Mode labels were yellow on white in Pop and Sketch; Week hour labels wrapped ("10:00 A / M"); the Samsung launcher ignores app font resources in widget RemoteViews, so Pixel and Sketch titles are now drawn as tinted bitmaps (the handwritten last letter was clipped at first; fixed and rechecked).

**Not verified on the device:** dark mode switching of the widget, other launchers, multiple widget instances and resizing, 200% text on the device, TalkBack. iOS remains unbuilt.

## Checks actually executed

Toolchain: Flutter 3.47.4, Dart 3.13.3, Android SDK/Java 17; Node 24 and pinned npm dependencies; Deno 2.5.4 for runtime type checking. The committed lockfiles record dependency resolutions.

| Check | Actual local result | Evidence scope |
|---|---|---|
| `flutter analyze` | No issues found | Dart static analysis |
| `flutter test` | **279 passed** | Domain, Drift repositories, widget/UI flows, mocked native/plugin seams and static native-source checks |
| `flutter build apk --debug` | Exit 0; `build/app/outputs/flutter-apk/app-debug.apk` produced | Android debug compilation/packaging, not release signing or device execution |
| Android `:app:testDebugUnitTest` | **34 tests, 0 failures, 0 errors** | Kotlin planner/reader/theme/contract JVM tests |
| Android `:app:lintDebug` | Build successful; **0 errors, 16 warnings** | Android static lint, with a narrowly scoped generated-file exception described below |
| Backend `npm test` | **79 passed, 0 failed, 0 skipped** | Actual migration/functions in local PGlite, Fetch handlers, auth boundaries, limits, replay and deletion tests |
| Backend `npm audit --omit=dev --audit-level=high` | 0 vulnerabilities reported | Registry audit for production npm dependency graph at execution time, not a security guarantee |
| Deno `check --node-modules-dir=none` | Exit 0 for all five entrypoints | `share-links`, `share-resolve`, `privacy`, `scan`, `health`; no deployment |
| Browser preview `npm test` | **136 passed, 0 failed, 0 skipped** | JS contract/controller/jsdom/configuration/static checks, not real mobile browser hand-off |
| DESIGN linter 0.4.0 | **0 errors, 0 warnings**, 1 token-summary info | Token/reference/opaque contrast and document structure, not visual/device accessibility certification |

The Android debug build emits a `home_widget` Kotlin Gradle Plugin deprecation warning. Android lint warnings are six `UnusedAttribute`, one `GradleDependency`, one `NewerVersionAvailable`, one `ObsoleteSdkInt` and seven `UseKtx` findings. They have not been silently represented as zero warnings. Gradle also reports deprecated features requiring review before Gradle 10.

### Generated Windows-path lint exception

Flutter rewrites ignored `android/local.properties` during its assemble task. This SDK serializer escapes Windows backslashes but leaves drive colons unescaped. Java Properties accepts the values and compilation succeeds, while Android lint reports `PropertyEscape` for that generated file. Manual rewrites are overwritten again by Flutter.

`android/app/lint.xml` ignores **only `PropertyEscape` in `../local.properties`**. No source rule or other file is excluded. The complete JVM-test/lint command was rerun successfully with the exception in place. A Flutter SDK upgrade should recheck whether this workaround is still necessary.

### Representative regression coverage

- Strict share-host/UUID/token parsing; bearer material passed ephemerally rather than persisted in router paths.
- Ordinary local use and public resolving do not initialize an anonymous owner identity. Share creation persists its command/secret before network use; uncertain creation cannot start a fresh second link and exposes saved-attempt recovery.
- Import selection, editable inactive review, local category mapping, explicit confirmation, transaction rollback/idempotency and duplicate/independent-copy decisions.
- Editing a title preserves an explicit next-day end relationship. A pending schedule save disables close/discard/form edits until completion.
- Reopening a completed backend-deletion job does not repeatedly erase newer local share metadata. Local schedule deletion and online snapshot deletion remain different operations.
- Image signature/byte/pixel limits, metadata-free normalization, local OCR mapping, conservative parser boundaries, explicit resolution, cancellation/stale-result rejection and crop/rotation source-revision invalidation.
- One labelled Today share action; a 320px-wide Today screen at text scale 2 has no captured layout exception and passes Flutter's labelled-target guideline. This single-screen check is **not** an app-wide WCAG/VoiceOver/TalkBack audit.
- iOS static-source assertions require querying actual AlarmKit records and preserving failed cancellations. Swift/AlarmKit behavior itself remains unbuilt and untested here.

Tests use isolated fixtures and mocked platform boundaries where Windows cannot exercise mobile plugins. Mock success is not evidence of actual camera, OCR, notifications or alarm delivery.

## Documentation validation

`python3 tools/spec_bundle.py` regenerates the readable edition and LF-canonical SHA-256 manifest. `python3 tools/spec_bundle.py --check` checks saved outputs rather than rewriting them. Its structural checks enforce:

- 24 sequential requirement IDs, R01–R24.
- 48 sequential acceptance IDs, AT01–AT48.
- A 35-entry primary-source register and no undefined numeric citation in the modular documents.
- Balanced code fences, main-spec table-of-contents anchors and existing relative document links.
- Exact generated-bundle and document-checksum freshness.

Machine transport/schema/fixtures and native calls remain authoritative separate artifacts under `contracts/`; prose refinement did not redesign frozen endpoints. The source register records documentation research; structural validation does not freshly re-verify every external webpage or prove all implementation behavior.

### Opaque contrast calculations

The previously executed sRGB relative-luminance calculations used the known opaque token pairs below, not visual estimates. The latest DESIGN lint independently reports no token contrast warning.

| Pair | Foreground | Background | Calculated ratio | Target |
|---|---|---|---|---|
| Light body | `#1D1D1F` | `#F5F5F7` | 15.457:1 | 4.5:1 |
| Light secondary | `#5A5A60` | `#FFFFFF` | 6.849:1 | 4.5:1 |
| Light action | `#FFFFFF` | `#0066CC` | 5.567:1 | 4.5:1 |
| Dark body | `#F5F5F7` | `#0C0C0E` | 17.948:1 | 4.5:1 |
| Dark secondary | `#B2B2BA` | `#1C1C1E` | 8.078:1 | 4.5:1 |
| Dark action | `#081322` | `#64A7FF` | 7.557:1 | 4.5:1 |
| Light error | `#B3261E` | `#FFFFFF` | 6.536:1 | 4.5:1 |
| Light input boundary | `#8A8A92` | `#FFFFFF` | 3.425:1 | 3:1 |

Transparent widgets over arbitrary wallpapers are not contrast-certified by these figures. Stronger/solid alternatives still require native readability tests.

## Remaining release gates — not claimed complete

1. **Physical Android:** gallery/camera permissions and cancel, OCR accuracy/memory, widgets on supported launchers and multiple instances, refresh/resize/taps, notification delivery, alarms/full-screen eligibility/stop/reboot/force-stop, Clock hand-off and denial/recovery.
2. **Mac/iOS:** compile Runner against the target SDK, create/embed/sign the WidgetKit extension, App Groups and entitlements, test AlarmKit authorization/query/cancel behavior on iOS 26+, notification fallback below iOS 26, photo/camera/OCR and widget rendering. The Windows environment cannot certify these.
3. **Real sharing infrastructure:** configure an approved Supabase project and owned HTTPS domain; review role/grant/Auth/connection settings, apply the actual migration, deploy the five functions, validate real RLS/auth/rate-limit/network/deletion behavior and production origins. PGlite is real local PostgreSQL execution, not a deployed Supabase instance.
4. **Verified links/browser hand-off:** real Android signing fingerprints, Apple team/app association, Associated Domains and web hosting/CSP/headers. Test fragment preservation and browser-to-app behavior on both OSes. Default placeholder associations must not be published as real ones.
5. **Accessibility and smoothness:** full VoiceOver/TalkBack, large text across all screens, contrast on arbitrary wallpaper, Reduce Motion/Transparency, focus/keyboard/touch, empty/error/slow-I/O states and real frame/memory/battery profiling. No measured native smoothness claim is made.
6. **Release/security/product decisions:** independent code/security findings must be resolved; production signing, dependency/toolchain warnings, store permissions/policy, privacy/legal/region, minors/account/session-loss recovery, retention/backups and remaining marked decisions need approval. SQLite is not encrypted by this app; no untested backup/recovery promise is made.
7. **Cloud scan:** explicitly disabled. No provider request, paid scan, upload path, usage billing or accuracy test was performed. Enabling it later requires its own planned security, consent, quota and deletion verification.

No production deployment, real-device success, store approval or independent security certification is implied by this record.
