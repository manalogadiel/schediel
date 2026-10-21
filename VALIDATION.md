# Implementation and documentation validation

**Recorded:** October 18–22, 2026 (Windows 11, UTC+08:00).

## Status and boundaries

Schediel now has a Flutter implementation, Android native code, iOS source, a locally tested optional sharing backend and a static browser preview. **This is a development build, not a production or real-device certification.** The optional sharing backend and HTTPS domains were deployed on October 20; the live checks below are distinct from production certification. Cloud scanning stays off. No schedule data, credentials or signing identities were invented to make a test look deployed.

Local implementation phases are distinct from the specification's acceptance/release gates. A unit/widget/source test must not be reported as a passing hardware, lifecycle, platform-policy, accessibility or OCR-accuracy scenario. The 48 acceptance IDs remain requirements, not 48 claimed passing device tests.

## October 22: calendar selectors for scanned dates

The shared class form and individual Resolve fields screen now use calendar selectors for start, term-end and optional last dates. Labels stay above the controls, dates display with month names and years, and the calendar opens without a text-entry mode or numeric keyboard. Its month/year heading opens a year selector. Done commits the selected day to the inactive draft; Cancel and accepting an unchanged date preserve existing confirmation. Optional last dates can be cleared. End/last-date calendars exclude days before the selected start; changing the start still requires applying and validating the new context before review.

Widget checks exercise actual calendar day/month/year selection, cancellation, date bounds, optional clearing, 200% text, and the shared form's reconfirmation behavior. Existing weekly and one-time import tests now choose dates through the calendar and retain their no-write-before-Add assertions.

All **419 Flutter tests passed**, whole-project analysis reported **no issues**, and all three split release APKs built. The release scanner constructor check passed for each ABI. ARM64 build **4010** retained the existing signing certificate and installed successfully with `adb install -r`. On the user's Samsung SM-A326B, a fresh scan opened the new start/end calendars and year selector without a keyboard. Both dialogs were cancelled, leaving the dates unselected and the scan draft open for the user's choices. No schedules were added, no data was cleared, and the unsaved pre-update scan was replaced by a fresh scan of the supplied image as disclosed before installation.

## October 21: release-only scanner initialization failure

The reported failure was reproduced on the user's Samsung SM-A326B (Android 13), running the installed ARM64 release **4008**, using the supplied 922 × 1012 university timetable. Device startup logs showed `NoSuchMethodException` for the public no-argument constructors of `CommonComponentRegistrar`, `VisionCommonRegistrar` and `TextRegistrar`. R8's removal report confirmed all three constructors were removed. ML Kit then threw a native null-pointer exception while preparing the image, before text recognition. The earlier profile scan and mocked/native-adapter tests did not exercise this minified-release failure.

The app's R8 rules now explicitly retain the constructors of ML Kit component registrars discovered through manifest names. `python tools/check_release_scanner.py <apk>` inspects actual DEX methods: it failed against build 4008 with all three constructors missing and passed against the rebuilt release. Shrinking remains enabled; no whole-library keep or debug-build substitution was used.

All **416 Flutter tests passed**, whole-project analysis reported **no issues**, and all three split release APKs built. The ARM64 APK reports **1.0.1 / 4009**, with the same existing signing certificate. `adb install -r` updated the phone successfully. A fresh scan through the normal release UI produced **14 meeting cards**, reached Continue to review, and showed both **One time / Weekly** controls. The first course showed Thursday 08:30–10:00 in room 105 and Friday 16:00–17:30 in room 402. No schedule import/save confirmation was pressed, no data was cleared, and no image/OCR text was uploaded. This verifies the supplied table on this phone; it does not certify every image, language or device.

## October 21: scanned class repeat choices

The newly attached table has identical pixels to the previously device-scanned university image. Its saved local OCR was rechecked against all **14 meetings**, including course codes, weekdays, both times and rooms; the first title/professor and all School/blank-notes defaults also passed. This is a regression using earlier real-device OCR, not a claim that a new phone scan was performed today. The personal source/OCR diagnostics remain ignored and absent from release assets.

Scanned classes now offer **One time / Weekly** in the shared class form and individual Resolve fields editor. Weekly remains the initial suggestion for weekday tables and needs term start/end dates. One time keeps the source weekday evidence but produces no recurrence: each meeting uses its first matching weekday on or after the explicit starting date. No current year, term dates or weekday associations are guessed. Changing shared date/repeat context invalidates prior confirmation until Apply; invalid shared input cannot partially change other classes. Per-class overrides stay independent. School, blank Notes, no alerts, and explicit Add remain unchanged.

The initial regression failed because an explicit one-time choice still required a term end from the detected weekdays. Domain, controller and widget checks now cover both modes, date alignment, switching back to weekly with missing context, no pre-Add writes, individual overrides and 200% text layout with labels above controls. The full Flutter suite passed **416 tests**, whole-project analysis reported **no issues**, and the separate local regression using the earlier device OCR passed for all 14 meetings in both repeat modes. Release split APKs built successfully; arm64 reports version **1.0.1**, code **4008** (Flutter build 2008 plus ABI offset), with the same signing certificate. Personal scan diagnostics/test fixtures are absent from the APK. The phone was disconnected, so this build has not been installed or freshly scanned on hardware.

## October 21: resilient image scanning and compact occurrence modals

The ML Kit native plugin can return null rectangles for blocks, elements or symbols, while its Dart factory requires maps. A regression reproduced `ocrFailed` from otherwise valid recognized text with missing optional geometry. The adapter now uses the same native recognizer channel with nullable, validated geometry, preserves text without inventing coordinates, and closes each recognizer after success or failure. This reproduces a concrete failure path; the phone was disconnected and the user's exact failing source image was not supplied, so its individual failure is not yet device-verified.

Still WebP, BMP, GIF and single-page TIFF inputs now join JPEG/PNG through actual byte/header admission and bounded decoding. Transparent screenshots are composited onto white before OCR. Android 9+ HEIC/HEIF and AVIF conversion runs on a serial background task queue, rejects oversized or animated headers before bitmap allocation, requests at most 4096 pixels per dimension/12 million pixels, and caps its PNG output before the shared metadata/crop pipeline. Codec availability varies by device. Synthetic fixtures contain solid colors only; AVIF tests verify the native-channel contract, not a Windows or Android codec. Animated files, multi-page TIFF, SVG and PDF remain explicit unsupported inputs.

Occurrence modals still use the root navigator above the floating navigation bar. They now shrink to their contents up to a bounded height instead of reserving 75% of the screen. Short Today/Week details leave only normal bottom padding; long notes scroll to Edit/Remove at 200% text on a small viewport. No schedule storage, scanner review/confirmation rule, signing key or texture caching behavior was changed.

The full Flutter suite passed **403 tests** and whole-project analysis reported **no issues**. Android compilation and all **45 JVM tests passed**, including header size/overflow checks and bounded decode target tests; `:app:lintDebug` also completed successfully. Release split APKs built; the arm64 APK reports version code **4006** and retains the existing debug certificate. Personal probe images and test fixtures were confirmed absent from the APK. Physical scan/codec checks and installation remain pending while the phone is disconnected.

## October 21: texture coverage behind widget detail headers

The widget deep link correctly opened the existing occurrence, but the shared AppBar painted an opaque canvas over the already full-screen texture. Textured themes now use a transparent app-bar surface and transparent status-bar color, with system-icon brightness chosen from the canvas contrast. Untextured app bars retain their existing solid surface. Existing zero elevation/tint prevents a solid strip after scrolling; the cached texture renderer was not changed.

Two pixel regressions open the actual `schediel://occurrence/...` route with a simulated system inset, compare textured/untextured status and toolbar regions in light and dark Pixel themes, scroll the details and check back navigation. Both first failed with zero visible texture pixels at the top, then passed after the theme correction. The focused texture/details suite passed **13 tests**, including cached-image reuse, contrast and existing details actions. The phone was disconnected during this change; no installation or physical widget-tap verification is claimed for this build.

Final whole-project checks: **391 Flutter tests passed**, analysis reported **no issues**, and release APKs built for all three ABIs using the existing debug signing configuration. The arm64 APK reports version code **4005** (Flutter build number 2005 plus the ABI offset) and is ready for an in-place update when the phone is reconnected.

## October 20: university timetable scanning and external input labels

- Added local recognition for the Code/Description/Units/Section/Instructor/Schedules format. The parser uses validated row/column geometry rather than OCR reading order, handles wrapped and merged cells and emits independent weekly meetings when time/room differs. Course codes become subtitles, instructors become professors, and Units/Section never fill Notes. Missing course anchors cannot absorb a neighboring course's fields. Unknown layouts keep the unresolved line-parser flow.
- Real native ML Kit OCR ran on the user-supplied university image on the Android 13 phone. A local diagnostic verified all **14 meetings**: subject/code associations, the requested first instructor, weekdays, start/end times and rooms. Character boxes distinguish the spaced slash misread as T/I/1 from true leading room characters; regression fixtures preserve genuine T104, 1104 and ITL. Enlarging this particular image did not improve OCR, so no automatic upscaling was added. Some instructor names/punctuation still require human review; no neural-model retraining or universal accuracy claim is made.
- A shared term form takes actual start/end dates once, confirms the displayed school time zone and requires an explicit source check. Each first date aligns with its own weekday. School is preselected from existing categories; the shared review allows editing and remains the only activation boundary. Notes and alerts stay empty. An end-to-end widget test verifies no database insert before Add, then correct School/category/details/recurrence on commit.
- All app-owned textbox/dropdown labels now sit above their controls, outside fills and outlines. Four style families were checked at 200% text with empty, focused and filled inputs, accessible labels and unchanged typed values. Existing editor/profile/import tests were adapted to locate the externally labeled input and keep their behavioral assertions.
- Full Flutter suite: **389 passed**. Native screenshot/OCR fixtures are kept in ignored build diagnostics; the personal image was removed from assets before the normal release build. No user schedules were imported, deleted or modified during these checks, and no image/OCR text was sent to an online service.
- Final whole-project analysis: **no issues**. Release split APKs built, the personal diagnostic image was confirmed absent from the APK, and the normal arm64 app updated in place successfully (version code **4004**). The existing signing certificate and both verified sharing domains were retained. External label placement was verified by widget tests; the optional final physical form inspection was unavailable while the phone displayed its system screen.

## October 20: texture rendering performance

The user isolated widespread stutter to enabling a texture. A regression reproduced ten full texture repaints during ten foreground animation frames. Repaint boundaries alone prevented those Dart paint calls but did not remove the expensive GPU work while scrolling behind the blurred navigation bar. Texture surfaces now rasterize their existing deterministic painter once and reuse an image through Flutter's bounded image cache. Cache identity includes pattern, size, pixel ratio, background, shade and accent; physical dimensions are capped at 2048 pixels per side. Framework image ownership handles eviction, disposal and memory pressure. No network or database is involved.

`tools/profile_textures.dart` exercised all eleven settings on the connected Android 13 phone in profile mode: the same thirty synthetic cards, navigation blur and four 1.2-second scrolls per setting, after a one-second warmup. No user schedules were read or changed. Median raster times before and after caching:

| Texture | Before | Cached |
|---|---:|---:|
| Paper | 66.1 ms | 11.6 ms |
| Dots | 24.1 ms | 11.7 ms |
| Carbon | 138.9 ms | 12.2 ms |

All cached textures measured 10.7–12.2 ms median and 12.7–13.2 ms at the 90th percentile in this workload. These are warmed synthetic rendering measurements on one phone, not a guarantee for every screen/device, cold texture generation, battery use or all app frame times. The probe temporarily replaces the app UI and must be followed by a normal release installation with `adb install -r`, preserving the existing key and local data.

Full Flutter suite: **377 passed**. The additional cache invalidation regression was then added and the focused texture suite passed **6 tests**, including retained-image reuse, size/pattern/palette changes, visible texture, contrast and preserved input/semantics. Full analysis reported no issues. Release split APKs built with the existing debug key and online-sharing configuration; `adb install -r` restored the normal app successfully (arm64 version code 4003, Flutter build number 2003 plus the ABI offset). The committed build number matches the installed release so future default builds remain installable over it. No uninstall, data clear, signing change or schedule import occurred.

## October 20: browser button handoff correction

The user reported that Open in Schediel stayed in Messenger/browser previews despite verified Android domains. The old button navigated to another HTTPS page, which a browser can keep internally. Android now receives a package-scoped intent directly from the user click; the full fragment is preserved and the original HTTPS preview is its fallback. No automatic launch or import was introduced, and no bearer is placed in page markup.

- Browser/jsdom suite: **142 passed**, covering compact/legacy links from both origins, user-gesture-only launch, explicit package, full fragment, fallback URL and no bearer in markup after the click.
- Android's own intent parser confirmed that the target package and complete share fragment survive parsing.
- The website-only update was deployed to both public production domains; no APK reinstall, signing change or local data operation was required.
- On the connected Android 13 phone, the real Chrome Open in Schediel button was tapped for synthetic previews on both domains and opened the installed native review with Edit and Add selected schedules. No Add action was tapped; synthetic server copies were cleaned up. Messenger's private conversations were not opened or changed; a restrictive embedded browser may still require Open in browser before the button.

## October 20: compact online sharing and Android installation

- `flutter analyze --no-pub`: no issues. Full `flutter test`: **376 passed**.
- Backend Node/PGlite suite: **82 passed**; browser/jsdom suite: **138 passed**. Deno 2.5.4 checked all five function entry points.
- Applied the sharing migrations, including permanent capability reservations, to the existing Schediel project; deployed functions and the static fallback. `schediel-share.vercel.app` and `schediel-open.vercel.app` both serve the matching Android association JSON publicly, without redirects. The second host is a production domain; preview authentication remains enabled for preview deployments.
- Live checks with two disposable anonymous identities and synthetic snapshots passed: creation, identical replay, management authorization, cross-owner read/revoke rejection, compact and legacy public resolution, invalid capabilities, unsupported versions, both browser origins, revocation, deletion-job readback, rejection of deleted-link replacement, and preservation of the other owner's snapshot. Synthetic snapshots were deleted afterward; test sessions were signed out. Anonymous test identity records can remain in Auth.
- Ingress was verified before use: `cf-connecting-ip` supports successful normal resolution, forged values receive 403 at the gateway, and spoofed `x-real-ip` / `x-forwarded-for` leave one resolver subject (three attempts) in aggregate database checks. No address or hash was printed.
- Live testing found and fixed two environment gaps: the hosted gateway strips `/functions/v1`, and Postgres.js must receive payload objects rather than pre-stringified JSONB. Both now have regression coverage.
- Built release split APKs with the existing PC debug signing key and the ignored public sharing settings. Updated the connected Android 13 phone with `adb install -r` successfully; no uninstall, key replacement, data clear, or schedule import occurred.
- Android reports **both hosts verified**. Real VIEW intents opened the app on first launch after installation and while already open; UI inspection found the synthetic title, Shared schedules, Edit and Add selected schedules in the review. The unmodified reviews were closed, and only the synthetic server copies were removed. Automated widget tests separately verify that edits stay inactive until Add and that first visits to Shared links do not sign in or report an authentication error.
- Some messaging apps may retain links in their own browser. The fallback preview offers an explicit cross-host Open action; actual Messenger/Viber/SMS behavior has not been certified. Recipients need a compatible installed Schediel APK. iOS remains unbuilt and unverified.

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
