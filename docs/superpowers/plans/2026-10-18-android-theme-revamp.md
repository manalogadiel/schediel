# Android Theme Revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship eight personal themes (Lilac, Clay, Pop, Mint, Midnight, Pixel, Sketch, Custom), a local profile, a restyled Android UI and themed home-screen widgets, after first landing the pending review fixes.

**Architecture:** One `SchedielTheme` (palette + style family + fonts, light/dark) feeds a `ThemeData` extension; reusable themed primitives render the four style families (soft, pop, pixel, sketch) so screens never hard-code colors. Preferences and profile persist in Drift (schema v2). The widget snapshot moves to contract 1.1 carrying both palettes; Android RemoteViews pick a per-style layout and tint holder drawables at runtime.

**Tech Stack:** Flutter 3.47.4 / Dart 3.13.3, Riverpod 3, Drift, go_router, home_widget 0.10, material_color_utilities (HCT), Kotlin RemoteViews (minSdk 26), Node 24 for contract fixtures.

**Spec:** `docs/superpowers/specs/2026-10-18-android-theme-revamp-design.md` (approved direction; mockup `docs/superpowers/specs/assets/2026-10-18-today-themes.html`).

## Global Constraints

- Repo `C:/Users/Diel/Documents/GitHub/schediel`, branch `main`; never force-push or reinitialize; commits via `git -c core.safecrlf=false commit`.
- Windows Git Bash: native tools take `C:/...` paths; Gradle via `cmd.exe /c "gradlew.bat ..."` from `android/`.
- Device: Samsung SM-A326B, Android 13/API 33, 720×1600, wireless adb (`adb devices` shows it). Install with `flutter install -d <id>` or `adb install -r build/app/outputs/flutter-apk/app-debug.apk`; screenshots via `adb exec-out screencap -p > file.png`.
- No invented UI content: every shown string/number comes from user data or fixed labels. No sample data outside tests.
- Contrast: text ≥ 4.5:1 against its real background; large display text ≥ 3:1; non-text indicators ≥ 3:1 — all themes × light/dark, Custom hues every 15°.
- Body/detail/form/error text always uses the system font; Silkscreen/Caveat only for display roles (spec §5.6).
- Fonts bundled offline under SIL OFL 1.1 with license text registered; no runtime font downloads.
- Profile never enters share payloads, widget snapshots, logs or network requests.
- Widget root stays transparent; no wallpaper reading.
- Reduce Motion (`MediaQuery.disableAnimationsOf`) makes all transitions instant and removes Sketch tilt.
- Touch targets ≥ 48dp. Text scale 2.0 on 320dp width: no overflow exceptions.
- Existing passing suites stay green (Flutter 191, Kotlin 21, backend 78, web 127 at last checkpoint).

## Review Focus

1. A Custom hue whose generated accent/on-accent or category-fill/card-ink pair falls below 4.5:1 → generator must darken/lighten tone until it passes (test sweeps 0–345 step 15, both brightnesses).
2. An existing v1 database (user already has schedules and `accentKey='teal'`) upgraded to v2 → schedules intact, theme = Mint, no profile row required.
3. A widget snapshot 1.1 with a missing/malformed `theme` object or bad hex color → Android renders the unthemed (1.0) look, never crashes or shows "Open Schediel".
4. Translucent themed widget holder over unknown wallpaper → opacity chosen so text passes over both black and white; an opaque fallback when nothing below 100% passes.
5. Floating nav covering the last timeline row or the system gesture bar at 200% text → bottom padding = bar height + inset; test scrolls to the last row and asserts it is hit-testable.

---

## Phase 0 — Land pending work (prerequisite)

### Task 0.1: R1 — backend-deletion cleanup scope

**Files:** Modify `lib/features/privacy/data/privacy_repository.dart`, `lib/features/privacy/presentation/privacy_screen.dart`; Test `test/features/privacy/privacy_repository_test.dart`

**Interfaces:** Produces `PrivacyRepository.requestBackendDeletion()` that persists a request context JSON in KeyValues key `backend-deletion-request` = `{"key": <idempotencyKey>, "shareIds": [...owned share ids at request time]}` before the POST; `refreshBackendDeletion(jobId)` cleans only `shareIds` from that context; pending creations untouched.

- [ ] Inspect working-tree edits left by interrupted helpers (`git diff -- lib/features/privacy test/features/privacy`); keep only what the tests below justify.
- [ ] Write failing test `first completed readback after a failed status read keeps links created later`: request deletion with owned link `old`; fake `deletionJob` throws once; insert owned link `new` + its secret; refresh succeeds with `completed` → `old` row and secret removed, `new` row and secret remain.
- [ ] Write failing test `pending creations and their secrets survive backend deletion`.
- [ ] Run `flutter test test/features/privacy/` → FAIL for the stated reasons.
- [ ] Implement; legacy plain-string request key (no JSON context) → refresh cleans nothing and logs nothing sensitive.
- [ ] Run privacy tests → PASS; run `flutter analyze`.

### Task 0.2: R3 — expired deletion request recovery

**Files:** same as 0.1.

- [ ] Failing test `idempotency_expired with no saved job offers a fresh confirmed request`: fake `deleteBackendData` throws `ShareApiException(status: 409, code: 'idempotency_expired')` → repository surfaces `BackendDeletionExpired`; calling `requestBackendDeletion(fresh: true)` uses a new key and new captured `shareIds`.
- [ ] Failing widget test in `privacy_screen_test.dart`: after expiry the screen shows "The earlier request can't be confirmed. Request deletion again?" with a confirm dialog; nothing is sent before confirmation.
- [ ] Implement; run privacy tests → PASS.

### Task 0.3: R2 — identity-bound share retry

**Files:** Modify `lib/features/sharing/data/share_api.dart`, `lib/features/sharing/application/{share_sender,sharing_runtime}.dart`, `lib/features/sharing/presentation/{create_share_screen,shared_links_screen}.dart`; Test `test/features/sharing/{share_sender_test,sharing_screens_test}.dart`

**Interfaces:** `ShareApi.currentOwnerId() → Future<String?>` (no session creation); `ShareApi.ensureOwner() → Future<String>` (may create anonymous session; used only by fresh `create`); `ShareApi.create(..., required String expectedOwnerId)` throws `ShareApiException(status: 0, code: 'owner_changed')` without network when the current owner differs. Owner id persisted in KeyValues `share-pending-owner:<idempotencyKey>` before the POST.

- [ ] Inspect existing helper edits; reconcile with this interface.
- [ ] Failing tests: `retry after session loss neither signs in nor posts` (fake API counts signIn/create calls = 0, pending row + secret kept, error `owner_changed`); `retry under a different owner keeps the attempt`; `same-owner retry succeeds and clears pending`.
- [ ] Failing widget test: saved attempt with `owner_changed` shows "This attempt belongs to an earlier online identity. Keep it or discard it." with Keep/Discard; Discard requires confirmation.
- [ ] Implement; `DeferredShareApi` forwards new methods; update test fakes in `test/features/sharing/`, `test/features/imports/`, `test/features/privacy/` mechanically.
- [ ] Run `flutter test test/features/sharing/ test/features/privacy/ test/features/imports/` → PASS.

### Task 0.4: R4 — distinct app-link handoff in browser preview

**Files:** Modify `web-preview/src/{app.js,settings.js,index.html}`, `web-preview/scripts/configure.mjs`, `lib/features/sharing/application/sharing_config.dart`, `lib/app/deep_links.dart`, `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`; Tests `web-preview/test/{app,configure}.test.js`, `test/app/deep_links_test.dart`, `test/native/platform_configuration_test.dart`

**Interfaces:** Optional `SCHEDIEL_APP_LINK_ORIGIN` (web, HTTPS origin ≠ share origin) and `SCHEDIEL_APP_LINK_HOST` (Flutter define) / Gradle property `schediel.appLinkHost` (default `schediel.invalid`). `DeepLinkCoordinator.routeFor` accepts share links on either configured host exactly.

- [ ] Inspect existing helper edits in `web-preview/`.
- [ ] Failing JS tests: `default navigation never targets the preview origin` (real default `navigate`, no injected spy; assert no hashchange, location hash empty); `no app action without a distinct app-link origin` (button hidden, status text explains reopening the original link); `configure rejects an app-link origin equal to the share origin`.
- [ ] Failing Dart tests: app-link host accepted, unrelated/userinfo hosts rejected, bearer passed only as route extra.
- [ ] Implement; Android manifest gets a second `<data android:host="${appLinkHost}">` in the verified HTTPS intent filter.
- [ ] Run `npm test` in `web-preview/`, `flutter test test/app/`, Gradle unit tests → PASS.

### Task 0.5: Backend driver packaging

**Files:** Modify `backend/supabase/functions/_shared/runtime.ts`; Test `backend/test/runtime.test.ts`

- [ ] Failing test `runtime source imports the postgres driver with a literal specifier`: read `runtime.ts`, assert a static `import(` / `import ... from` with a literal `npm:postgres@3.4.9`-style specifier and no variable-specifier import.
- [ ] Replace the variable import with a literal dynamic import; run `npx --yes deno@2.5.4 info supabase/functions/share-links/index.ts` and confirm `postgres` appears in the npm graph.
- [ ] `npm test` in `backend/` → 78+ pass; Deno check five entrypoints → exit 0.

### Task 0.6: Verify, review, commit and push Phase 0

- [ ] Full checks: `flutter analyze`; `flutter test`; `flutter build apk --debug`; Gradle `:app:testDebugUnitTest :app:lintDebug`; backend & web `npm test`; Deno check; `python3 tools/spec_bundle.py` then `--check`.
- [ ] Update `VALIDATION.md` (replace the "Review checkpoint" paragraph with what was fixed and fresh counts); regenerate bundle/checksums.
- [ ] Independent read-only review of the staged diff (requesting-code-review); fix blocking findings; re-run affected tests.
- [ ] `git add -A`; commit `feat: sharing, imports, privacy and image import with review fixes`; `git push origin main`; verify `git ls-remote origin main` equals local HEAD.

---

## Phase 1 — Theme foundation

### Task 1.1: Theme model, palettes and Custom generator

**Files:** Create `lib/app/theme/schediel_theme.dart`, `lib/app/theme/theme_catalog.dart`, `lib/app/theme/custom_palette.dart`; Test `test/app/theme_catalog_test.dart`

**Interfaces:**
- `enum ThemeId { lilac, clay, pop, mint, midnight, pixel, sketch, custom }`
- `enum StyleFamily { soft, pop, pixel, sketch }`
- `enum CategoryColorKey { blue, green, orange, red, purple, gray }` (reuse `CategoryColor` names)
- `class ThemePalette { Color canvas, surface, ink, secondaryInk, divider, accent, onAccent, navBackground, navInk, navSelected, navOnSelected, nowBadge, onNowBadge, cardInk, outline; Map<CategoryColorKey, Color> categoryFills; }`
- `class SchedielTheme { ThemeId id; StyleFamily style; double radius; String? displayFont; FontWeight displayWeight; ThemePalette light, dark; bool darkOnly; }`
- `SchedielTheme themeFor(ThemeId id, {int customHue = 250})`
- `ThemePalette customPalette(int hue, Brightness b)` using `Hct` from `material_color_utilities`.

- [ ] Add `material_color_utilities` as a direct dependency pinned to the version already in `pubspec.lock` (it is currently only transitive; importing it otherwise fails `depend_on_referenced_packages`).
- [ ] Write failing tests:
  - `every built-in theme meets text contrast in both brightnesses` — for each theme/brightness assert `contrastRatio(ink, canvas) >= 4.5`, `(ink, surface)`, `(onAccent, accent)`, `(cardInk, fill)` for all six fills, `(navInk, navBackground)`, `(navOnSelected, navSelected)`, `(onNowBadge, nowBadge)`.
  - `custom palettes pass contrast for every 15° hue` (0..345, both brightnesses, same pairs).
  - `light values match the approved mockup` — e.g. `themeFor(ThemeId.lilac).light.canvas == Color(0xFFF4F2FC)`, `.accent == Color(0xFF6A5AE0)`; Pop accent `0xFFFFD400` with onAccent `0xFF111111`; Pixel radius `0` and display font `'Silkscreen'`; Sketch display font `'Caveat'`; Midnight `darkOnly == true`.
  - `category fills keep their hue family in Custom` — for hues 0..345, Custom red fill hue within 20° of the base red fill's hue.
- [ ] Run `flutter test test/app/theme_catalog_test.dart` → FAIL (missing symbols).
- [ ] Implement with spec §5.2 values; fill `*` slots and dark variants; tone-adjust loop for failing pairs.
- [ ] Run test → PASS; `flutter analyze`.

### Task 1.2: Bundled display fonts

**Files:** Create `assets/fonts/Silkscreen-Regular.ttf`, `assets/fonts/Silkscreen-Bold.ttf`, `assets/fonts/Caveat-VariableFont_wght.ttf` (or static 500/700), `assets/fonts/LICENSE-Silkscreen.txt`, `assets/fonts/LICENSE-Caveat.txt`; Modify `pubspec.yaml`, `lib/main.dart`; Test `test/app/fonts_test.dart`

- [ ] Download the fonts and OFL texts from the official google/fonts GitHub repository (`ofl/silkscreen`, `ofl/caveat`); record source URLs + SHA-256 in `assets/fonts/SOURCES.md`.
- [ ] Failing test `font licenses are registered` — collect `LicenseRegistry.licenses` and assert packages `Silkscreen` and `Caveat` present; `font assets are declared` — `rootBundle.load('assets/fonts/Silkscreen-Regular.ttf')` succeeds.
- [ ] Declare `fonts:` families `Silkscreen` and `Caveat` in `pubspec.yaml`; register licenses in `main.dart` via `LicenseRegistry.addLicense`.
- [ ] Run test → PASS.

### Task 1.3: Preferences + profile persistence (Drift v2)

**Files:** Modify `lib/data/local/database.dart` (+ regenerate `database.g.dart` with `dart run build_runner build --delete-conflicting-outputs`), `lib/features/appearance/appearance.dart`; Create `lib/features/profile/data/profile_repository.dart`, `lib/features/profile/domain/profile.dart`; Tests `test/data/migration_v2_test.dart`, `test/features/appearance/appearance_repository_test.dart`, `test/features/profile/profile_repository_test.dart`

**Interfaces:**
- `AppearancePreferences` adds `themeKey TEXT DEFAULT 'lilac'`, `customHue INT DEFAULT 250`; keeps `accentKey` (read only for migration).
- New table `ProfilePreferences(id INT PK =1, displayName TEXT NULL, photoPath TEXT NULL, updatedAt)`.
- `schemaVersion => 2`; `onUpgrade` from 1: add columns, create table, map `accentKey`: blue→lilac, teal→mint, indigo→lilac, graphite→ (themeMode=='dark' ? midnight : clay).
- `AppearanceSettings { ThemeMode themeMode; ThemeId theme; int customHue; Density density; bool showCategoryColors; }` (replaces `accent`).
- `class Profile { String? name; String? photoPath; }`; `ProfileRepository { Future<Profile> load(); Future<void> setName(String? name); Future<void> setPhoto(Uint8List squareJpeg); Future<void> removePhoto(); Future<void> clear(); Stream<Profile> watch(); }` — photo written to `getApplicationSupportDirectory()/profile/photo-<timestamp>.jpg`, previous file deleted.
- [ ] Failing tests: `v1 database with schedules and teal accent upgrades to v2 as Mint` (create v1 schema via a raw SQL fixture `test/data/fixtures/v1_schema.sql` captured from current `database.dart` before editing); `graphite+dark maps to Midnight`; `name is trimmed, 1–40 chars, empty clears it`; `replacing photo deletes previous file`; `removePhoto deletes file and clears path`; `clear removes name and photo`.
- [ ] Capture the v1 schema fixture **before** changing the table definitions (`sqlite3`-free: generate via `AppDatabase(NativeDatabase.memory())` + `SELECT sql FROM sqlite_master`).
- [ ] Implement; run tests → PASS; full `flutter test` stays green.

### Task 1.4: Wire themes into ThemeData

**Files:** Modify `lib/app/theme/app_theme.dart`, `lib/app/theme/tokens.dart`, `lib/app/app.dart`, `lib/features/appearance/appearance.dart`; Test `test/app/theme_test.dart`

**Interfaces:** `ThemeData buildTheme({required SchedielTheme theme, required Brightness brightness, required Density density, required bool showCategoryColors})`; `ThemeExtension<SchedielColors>` replacing `ScheduleColors`, exposing palette, `style`, `radius`, `displayFont`, `displayWeight`, `density`, `showCategoryColors`, and `Color categoryFill(String? colorKey)`; `extension on BuildContext { SchedielColors get schediel; }` — keep `scheduleColors` as a deprecated alias until all screens migrate, delete in Task 3.6.
- [ ] Failing tests: `Midnight forces dark regardless of mode`; `display text styles use the theme display font and body styles do not` (`headlineMedium.fontFamily == 'Silkscreen'` for Pixel; `bodyMedium.fontFamily == null`); `theme switch animates over 220ms and is instant with reduced motion` (`AnimatedTheme` duration).
- [ ] Implement; remove `AccentPreset` and its uses (search `AccentPreset`).
- [ ] `flutter test` full → PASS; `flutter analyze`.

### Task 1.5: Themed primitives

**Files:** Create `lib/app/widgets/themed.dart` (`ThemedCard`, `ThemedPill`, `ThemedIconButton`, `ThemedChip`, `ThemedAvatar`), `lib/app/widgets/sketch_border.dart` (`SketchBorderPainter(seed)`), `lib/app/widgets/pixel_border.dart`; Test `test/app/themed_widgets_test.dart`, goldens under `test/goldens/primitives/`

**Interfaces:** `ThemedCard({Color? fill, bool emphasized = false, Object? seed, EdgeInsets padding, VoidCallback? onTap, required Widget child})` — soft: radius + faint shadow; pop: 2dp `outline` + hard offset shadow 3dp; pixel: square with stepped 3dp notched outline; sketch: `SketchBorderPainter` outline (deterministic from `seed`) + tilt ≤1° unless reduced motion.
- [ ] Failing tests: `sketch outline is deterministic for a seed` (paint twice → identical path bounds/points); `sketch tilt removed under reduced motion`; `ThemedCard onTap target ≥ 48dp`; goldens `primitives_<theme>_<brightness>.png` for all 8×2 (Midnight once).
- [ ] Implement; generate goldens with `flutter test --update-goldens test/app/themed_widgets_test.dart`; inspect the PNGs visually before accepting.
- [ ] Re-run without update → PASS.

---

## Phase 2 — Screens

### Task 2.1: Floating navigation shell

**Files:** Modify `lib/app/shell.dart`; Test `test/app/shell_test.dart`

**Interfaces:** `AppShell` renders body with `extendBody: true` and a `FloatingNavBar` (pill with three destinations; selected expands to icon+label) plus round add button calling `showAddMenu(context)`. Exposes `static double bottomInset(BuildContext)` = bar height + 16 + `MediaQuery.viewPaddingOf(context).bottom` for scroll views.
- [ ] Failing tests: `tapping Today tab while on Today selects today's date`; `add button opens the add menu`; `last Today row is hit-testable above the bar at text scale 2` (Review Focus 5); `nav labels and add button have semantics labels`.
- [ ] Implement; remove the share/add icons from Today header that move (share stays in header; add moves to bar).
- [ ] Run tests → PASS; update existing tests that tapped `find.byTooltip('Add')` to the new add button tooltip `Add` (keep the same tooltip so tests stay stable).

### Task 2.2: Today redesign

**Files:** Modify `lib/features/schedules/presentation/today_screen.dart`, `timeline_row.dart`; Create `lib/features/schedules/presentation/today_header.dart`, `day_strip.dart`, `next_card.dart`; Modify `lib/features/schedules/application/day_view.dart` only if a week-dots query is needed; Tests `test/features/schedules/today_screen_test.dart`, update `schedule_screens_test.dart`, goldens `test/goldens/today/`

**Interfaces:** `greetingFor(DateTime local) → String` ("Good morning" 05:00–11:59, "Good afternoon" 12:00–17:59, else "Good evening"); `DayStrip({required LocalDate selected, required Set<LocalDate> daysWithSchedules, required ValueChanged<LocalDate> onSelect})` (swipe ±7 days); `NextCard({required Occurrence next, required Duration until})` label `Next · in <relative>` using existing `Formats` relative helpers.
- [ ] Failing tests: greeting boundaries (04:59 evening, 05:00 morning, 11:59, 12:00, 17:59, 18:00); `header shows photo, else initial, else no avatar`; `day strip dots come from real occurrences`; `Next card hidden when nothing is next`; `ongoing row shows Now badge and elapsed bar`; `Today pill appears only off-today and returns to today`; `filter pill is in the timeline header and filters Week too`; `text scale 2 at 320dp has no overflow`.
- [ ] Implement per spec §4; keep existing semantics labels where tests depend on them (`Selected date …`).
- [ ] Goldens: `today_<theme>_<brightness>.png` at 360×800 with deterministic clock and fixture schedules in test only; inspect PNGs.
- [ ] Full `flutter test` → PASS.

### Task 2.3: Week restyle

**Files:** Modify `lib/features/schedules/presentation/week_screen.dart`; Tests update `schedule_screens_test.dart`; goldens `test/goldens/week/`
- [ ] Failing golden + test `week blocks use category fills from the theme`.
- [ ] Implement with `DayStrip` header + themed agenda/grid blocks; keep existing interactions.
- [ ] Tests → PASS.

### Task 2.4: Editor, occurrence sheet, add menu

**Files:** Modify `lib/features/schedules/presentation/{schedule_editor_screen,occurrence_sheet,add_menu}.dart`, `lib/features/reminders/presentation/alert_editor.dart`; Tests existing editor/sheet tests + goldens `test/goldens/editor/`
- [ ] Failing goldens for editor (Lilac light, Pop light, Pixel light, Midnight); `editor form fields never use display fonts` test.
- [ ] Restyle: pill inputs, themed segmented chips, full-pill primary save button, themed sheet surfaces. No flow changes; pending-save and dirty-discard tests must stay green.
- [ ] Tests → PASS.

### Task 2.5: Theme picker and Custom color

**Files:** Replace `lib/features/appearance/appearance_screen.dart` with theme grid; Create `lib/features/appearance/custom_color_sheet.dart`; Modify `lib/features/settings/settings_screen.dart`, router; Test `test/features/appearance/theme_picker_test.dart`, goldens
- [ ] Failing tests: `selecting a theme applies immediately and persists`; `mode selector disabled with explanation for Midnight`; `custom sheet previews live and Use this color saves hue`; `tiles are labelled for screen readers`.
- [ ] Implement tile = mini Today card in that theme (built with `ThemedCard`).
- [ ] Tests → PASS.

### Task 2.6: Profile settings

**Files:** Create `lib/features/profile/presentation/profile_section.dart`, `lib/features/profile/presentation/avatar_crop_screen.dart` (adapt `ImageCropScreen` to square crop + circle mask); Modify settings screen, privacy screen + `privacy_repository.dart` (delete local data offers "Also remove profile", default checked); Tests `test/features/profile/profile_screen_test.dart`, privacy tests
**Interfaces:** photo pipeline reuses `LocalImagePreparer` signature/size limits, then crops and encodes 512×512 JPEG without metadata (`package:image`, already present via image import — verify in `pubspec.yaml`).
- [ ] Failing tests: `choose photo → crop → save writes 512×512 JPEG without EXIF`; `cancel crop leaves profile unchanged`; `remove photo asks confirmation`; `name field validates 40 chars`; `delete local data with profile box checked clears profile`; `profile absent from share payload and widget snapshot` (build both and assert no name/photo path substrings).
- [ ] Implement; tests → PASS.

### Task 2.7: Remaining screens restyle

**Files:** `lib/features/{sharing,imports,image_import,reminders,categories,privacy,widgets}/presentation/*.dart`, `lib/app/widgets/common.dart`; Tests existing suites + goldens for categories and import review
- [ ] Categories: swatches show current theme fills with key names (failing test `category swatches follow theme`).
- [ ] Restyle each screen with themed primitives; no behavior or copy changes except labels required by the spec.
- [ ] Remove deprecated `scheduleColors` alias; `flutter analyze` clean; full `flutter test` → PASS.

---

## Phase 3 — Widgets

### Task 3.1: Snapshot contract 1.1

**Files:** Create `contracts/schemas/widget-snapshot-v1_1.schema.json`, `contracts/fixtures/widget-snapshot-v1_1-cases.json`; Modify `CONTRACTS.md` §6, `lib/features/widgets/application/{widget_snapshot_builder,widget_snapshot_reader,widget_snapshot_service}.dart`, `lib/features/widgets/domain/widget_config.dart` (+ `useAppTheme`, Drift column in v2 migration from Task 1.3 — add there if not yet released, otherwise v3); Tests `test/features/widgets/widget_snapshot_test.dart`, `test/contracts/widget_snapshot_contract_test.dart`
**Interfaces:** `theme: {id, style, light: Palette, dark: Palette}`; `Palette {accent, onAccent, neutralFill, cardInk, outline, categoryFills{six}, opacity{clear, softTint}}`; occurrence `categoryColor`; configuration `useAppTheme`.
- [ ] Failing tests: builder emits `schemaVersion: '1.1'` and both palettes; System mode → light≠dark for Lilac, Light/Dark/Midnight → identical palettes; `opacity.clear` is the lowest value ≥0.70 where cardInk passes 4.5:1 composited over #000000 and #FFFFFF, else 1.0 (Review Focus 4); every fixture case validates against the 1.1 schema; Dart reader accepts 1.0 and 1.1, rejects 1.2.
- [ ] Implement; tests → PASS.

### Task 3.2: Android native themed widget

**Files:** Modify `android/app/src/main/kotlin/com/manalogadiel/schediel/widget/{SnapshotReader,WidgetPlanner,WidgetRenderer}.kt`; Create layouts `widget_schedule_{soft,pop,pixel,sketch}.xml` (holders = `FrameLayout` with background `ImageView` + text), drawables `widget_shape_{soft,pop,pixel,sketch}.xml` (white shapes; sketch as vector path), `res/font/silkscreen.ttf`, `res/font/caveat.ttf`; Tests `android/app/src/test/.../SnapshotReaderThemeTest.kt`, `WidgetThemeTest.kt`
**Interfaces:** `ThemePalette` Kotlin data class; `SnapshotReader` → `ReadResult.theme: WidgetTheme?`; renderer picks palette by `Configuration.UI_MODE_NIGHT_MASK`, layout by style, tints via `setInt(imageViewId, "setColorFilter", color)` and `setInt(imageViewId, "setImageAlpha", alpha)`.
- [ ] Failing JVM tests: parse 1.1 theme; malformed theme/hex → `theme == null` and unthemed render path (Review Focus 3); 1.0 still parses; style→layout mapping; night-mode palette selection; `useAppTheme=false` keeps legacy drawables.
- [ ] Implement; Gradle `:app:testDebugUnitTest :app:lintDebug` → pass, 0 lint errors.

### Task 3.3: iOS reader accepts 1.1

**Files:** Modify `ios/ScheduleWidget/ScheduleWidget.swift`; Test `test/native/platform_configuration_test.dart` (static source assertion)
- [ ] Failing static test: Swift reader accepts `"1.0"` and `"1.1"` and ignores `theme`.
- [ ] Implement minimal change; note "unbuilt on Windows" in VALIDATION.

### Task 3.4: Widget settings option

**Files:** Modify `lib/features/widgets/presentation/widget_settings_screen.dart`; Test widget settings test
- [ ] Failing test: `Use app theme` toggle defaults on for new widget keys, off for existing configs, persists and triggers a snapshot write.
- [ ] Implement; tests → PASS.

---

## Phase 4 — Device verification, docs, ship

### Task 4.1: On-device check (SM-A326B)

- [ ] `flutter build apk --debug`; `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.
- [ ] For each theme (and dark where applicable): set via the app, capture Today, Week, editor, Settings → Theme with `adb exec-out screencap -p > C:/Users/Diel/AppData/Local/hermes/cache/scratch/device/<screen>-<theme>.png`; inspect each image for clipping, contrast, font rendering and nav overlap.
- [ ] Ask the user to add the Schediel widget to the home screen; capture it per style family (soft, pop, pixel, sketch) with surface clear and solid; check fonts render in RemoteViews and text is legible.
- [ ] Ask the user to pick a profile photo once; capture Today header.
- [ ] Record findings; fix defects with a failing test first; repeat until clean.

### Task 4.2: Documentation and final verification

**Files:** `DESIGN.md`, `SCHEDULER_SPEC.md`, `CONTRACTS.md`, `VALIDATION.md`, `README.md`, regenerated `FULL_SPEC.md`, `CHECKSUMS.sha256`
- [ ] DESIGN.md: theme tokens (per theme palette summary), style families, fonts + licenses, profile, widget theming; `npx -y -p @google/design.md@0.4.0 designmd lint DESIGN.md` → 0 errors (warnings explained).
- [ ] SCHEDULER_SPEC: appearance/theme, profile, widget theming sections; keep R01–R24/AT01–AT48 numbering (add new requirements only as sub-bullets of existing ones or a clearly marked addendum the checker accepts).
- [ ] VALIDATION: fresh counts and device-check evidence (what was seen on SM-A326B, what remains unverified).
- [ ] Run all checks from Task 0.6; independent review of the revamp diff; fix; commit `feat: themes, profile and themed widgets for Android`; push; verify remote HEAD.
