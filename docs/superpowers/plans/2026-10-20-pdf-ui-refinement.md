# PDF-led UI Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` for native execution, or `subagent-driven-development` if the user selects it. Steps use checkbox (`- [ ]`) syntax for tracking. Do not execute before the user reviews this plan.

**Goal:** Apply the user's PDF fixes and references while preserving Schediel's old bottom navigation and removing the oversized left gap in the Week date selector.

**Architecture:** Keep Flutter/Riverpod/GoRouter, Drift and the existing schedule/reminder/import engines. Reuse the actual shell, themed components, date selector and occurrence sheet; change presentation rather than rebuilding the app. Keep native-widget sizing, live-sharing verification, startup performance and app-icon approval as separately testable batches, not one all-or-nothing rewrite.

**Tech Stack:** Existing Flutter/Dart, Riverpod, GoRouter, Drift, flutter_svg, Material color utilities; Kotlin RemoteViews widgets. No new package is assumed necessary.

**Spec:** `docs/superpowers/specs/2026-10-20-pdf-ui-refinement-design.md` (proposed, read with this plan).

## Global Constraints

- Plan first. No implementation, revised mockup, device install, backend deployment, commit or push is authorized by this planning turn.
- Keep the old `FloatingNavBar`: Today / Week / Settings, selected label, separate Add button, current placement and theme-family shape.
- The Week date selector has seven equal date cells and normal 16dp outer padding. It must not reserve a 44–56dp empty time-column slot on its left.
- User PDF annotations and references outrank skill templates; the unapproved HTML v1 is not the spec.
- Preserve existing theme families, Pixel/Silkscreen and Sketch/Caveat fonts, local-only removable profile, editable import drafts and explicit confirmation.
- No invented UI content or hidden scope expansion. Do not remove safety disclosures/confirmations to simplify Privacy.
- Android first; source checks are not iOS build verification. No wallpaper or lock-screen-widget work.
- Keep current 160ms control / 220ms screen motion and Reduce Motion behavior. Standard action targets are 48dp; narrow seven-date cells are non-overlapping and at least 48dp tall.
- Use existing 4/8/16/24/32/48dp spacing, 12dp controls, 18dp cards and 28dp sheet tokens where the theme family permits.
- Keep sharing unavailable without real configuration; no pretend live link or invented startup benchmark. No credentials or personal photos in commits/logs.

## Review Focus

1. A dirty editor opened by a deep link or import must survive Back, keyboard changes, save failure and cancellation — Task 3.
2. Midnight/overnight, overlapping, all-day, unresolved and DST-zone occurrences must remain correctly dated in the full-day grid — Task 2.
3. Extreme hue/tone settings and textures must not hide controls/text or reset existing users' preferences — Task 5.
4. Small/large-text widgets must not clip or promise three cards when the host cannot fit them — Task 6.
5. A cold open with slow/offline services must show correct persisted date/theme/filter and never auto-import a link — Tasks 7–8.

## Execution order and approval gates

1. User reviews the plan and proposed choices in the spec. No further prototype is required unless requested.
2. Calendar/core UI batch: Tasks 1–4. Visually check the actual old bar and reference-led dates before expanding scope.
3. Appearance and widget batch: Tasks 5–6, each with its own migration/native checks.
4. Sharing verification, measured startup, icon concepts: Tasks 7–9 are independent follow-ups, not reasons to delay a checked calendar fix. Icon replacement requires a separate concept choice; production sharing requires real deployment prerequisites.
5. Task 10 verifies the completed scope and records any deliberately blocked platform/live checks.

Recommend **Native** execution to minimize credit/context overhead, with one independent whole-diff review at the end. A subagent per task is optional, not assumed.

## File structure and stable boundaries

Existing files below are targeted, not permission to rewrite them wholesale:

| Area | Files / responsibility |
|---|---|
| Shell | `lib/app/shell.dart` — preserve bar; `lib/app/app.dart`, `lib/app/theme/app_theme.dart` — system-area colors and app-level presentation |
| Shared visuals | `lib/app/widgets/common.dart`, `lib/app/widgets/themed.dart`, `lib/app/icons.dart`, `assets/icons/` — current primitives/assets |
| Calendar | `lib/features/schedules/presentation/{today_screen,today_header,day_strip,timeline_row,week_screen}.dart` — selected date, compact dates, full-day grid |
| Editor/details | `lib/app/router.dart`; `lib/features/schedules/presentation/{schedule_editor_screen,occurrence_sheet,add_menu}.dart`; `lib/features/reminders/presentation/alert_editor.dart` |
| Settings | `lib/features/settings/settings_screen.dart`; `lib/features/categories/presentation/categories_screen.dart`; `lib/features/profile/presentation/profile_screen.dart`; `lib/features/privacy/presentation/privacy_screen.dart` |
| Appearance | `lib/features/appearance/{appearance,appearance_screen}.dart`; `lib/app/theme/{schediel_theme,theme_catalog,app_theme}.dart`; `lib/data/local/database.dart` and generated Drift output |
| Widgets | `lib/features/widgets/presentation/widget_settings_screen.dart`; native `android/app/src/main/kotlin/com/manalogadiel/schediel/widget/{WidgetPlanner,WidgetRenderer,ThemeStyle}.kt`; `tools/gen_widget_layouts.py` |
| Sharing | `lib/features/sharing/`, `test/features/sharing/`, `test/app/deep_links_test.dart`, `backend/`, `web-preview/` — existing production path, not a new service |
| Startup | `lib/main.dart`, `lib/app/lifecycle.dart`; new local diagnostic `tools/measure_startup.py` if useful |
| Icon | New editable `assets/branding/app-icon.svg` only after concept approval; then actual Android/iOS launcher resource targets |

Create only these focused UI units where needed:
- `lib/app/widgets/labeled_field.dart`: `LabeledField({Key? key, required String label, required TextEditingController controller, String? errorText, int maxLines = 1, bool enabled = true})`; label inside top of field, value beneath, no border notch. Callers retain controller ownership and accessible names.
- `lib/app/widgets/bottom_sheet_page.dart`: `BottomSheetPage<T>({required Widget child, LocalKey? key}) extends Page<T>`; `Route<T> createRoute(BuildContext context)` produces the bottom-origin route. Editor dismissal remains explicitly guarded.
- `lib/features/schedules/presentation/schedule_time_picker.dart`: `Future<TimeOfDay?> showScheduleTimePicker(BuildContext context, {required TimeOfDay initialTime})`; null on Cancel, no schedule mutation while selecting.
- `lib/features/appearance/theme_customization.dart`: `ThemeTexture { none, stripes, paper, gradient }`; immutable `ThemeCustomization` with nullable `double accentHue`, `accentTone`, `backgroundHue`, `backgroundTone`, plus `ThemeTexture texture = ThemeTexture.none`. Null uses family defaults. JSON parsing ignores unknown fields, safely defaults invalid values; editing clamps hue to 0–359 and tone to 0–100.

Do not introduce a second schedule model, separate editor persistence store, generic animation framework, new sharing backend or wholesale component library.

---

## Task 1: Preserve the shell; repair edges, empty states and feedback

**Requirements:** R01, R06, R07, R08, R19.
**Modify:** shell/app/theme/shared visuals and Today empty state from the table.
**Create:** `assets/illustrations/schedule-empty.svg` — small original calendar/time motif, no words or fake schedule data.
**Tests:** `test/app/shell_test.dart`, `test/app/app_appearance_test.dart`, `test/app/themed_widgets_test.dart`, `test/features/schedules/today_screen_test.dart`.
**Interfaces:** Keep `FloatingNavBar` and `AppShell.bottomInset` public behavior unchanged; extend `EmptyState` only with optional `Widget? illustration` so errors need not receive decorative artwork.

- [ ] Write regression tests `old_nav_keeps_three_destinations_and_separate_add`, `theme_canvas_covers_system_areas`, `empty_state_keeps_real_copy_and_action`, `reduced_motion_disables_new_feedback`. Assert existing `nav-today`, `nav-week`, `nav-settings` keys, Add outside the destination group, old selection behavior, unchanged route count, matching system-area canvas and no invented data.
- [ ] Run `flutter test test/app/shell_test.dart test/app/app_appearance_test.dart test/app/themed_widgets_test.dart test/features/schedules/today_screen_test.dart`; establish existing passes and failures for added behavior. Do not force passing baseline tests to fail.
- [ ] Apply theme-aware system chrome through existing app/theme ownership. Add the restrained empty illustration and existing-token feedback; do not change the bar layout, order or Add geometry.
- [ ] Run the same tests; inspect Today/Settings against PDF p1–2 at phone width, including Android status and navigation areas.
- [ ] Commit only this batch after approval and verification: `git -c core.safecrlf=false commit -m "fix: preserve navigation and polish app surfaces"`.

## Task 2: Reference-led seven-day selector and complete Week timeline

**Requirements:** R02, R03, R04, R05.
**Modify:** calendar files in the map; reuse `DayStripView` rather than a second seven-date implementation.
**Tests:** `test/features/schedules/{today_screen,week_screen,day_view}_test.dart`; add `test/features/schedules/day_strip_test.dart`.
**Interfaces:** Preserve `DayStripView(start, selected, today, daysWithSchedules, onSelect)` and `selectedDateProvider`; Week's date selection must consume the same selected-date source. Existing previous/next-week controls move that state by seven days. Preserve `showOccurrenceSheet(BuildContext, Occurrence)`.

- [ ] Add `week_selector_has_no_reserved_left_gutter` using the existing `appTest` harness at `Size(360, 800)`. Seed `classDraft()`, tap Week, assert `day-2026-11-01` through `day-2026-11-07` exist, first cell begins within normal 16–20dp inset, seven widths differ by at most 1dp, and no overflow is raised. Add the same geometry assertion for an empty week.
- [ ] Add tests `week_dates_are_clickable_without_switching_tab`, `month_picker_selects_real_dates`, `empty_week_keeps_full_day_grid`, `week_can_scroll_to_00_and_23_hours`, `today_time_range_centers_against_card`. Assert selected-date state after each tap, seven targets, full 24-hour scroll extent and single-line hour labels. Retain filter-specific empty copy and clear-filter action.
- [ ] Add fixtures for 00:15, 23:45, a next-day end, simultaneous overlaps, all-day, unresolved timing and a non-Manila DST transition. Assert event day/position and accessible time/date range; use existing occurrence/time-zone resolution, not hand-made UTC arithmetic.
- [ ] Run `flutter test test/features/schedules/day_strip_test.dart test/features/schedules/week_screen_test.dart test/features/schedules/today_screen_test.dart test/features/schedules/day_view_test.dart`; confirm the new missing-behavior tests fail for their intended reasons.
- [ ] Restyle the shared selector from PDF p8: compact day/number tiles, seven equal cells, selected fill, real event dots only. Open the month picker from the date heading. Use normal horizontal padding, never `_gutter` padding, around the selector. Keep the rail only in the grid below; verify day identity stays clear instead of claiming misaligned selector tiles are column headers.
- [ ] Replace the grid's 08:00–18:00 minimum/auto-cropping with a full 00:00–24:00 display in empty and populated states. Keep 24/12-hour formatting, accessible agenda, overlaps, all-day/review strip and bottom-bar clearance. Auto-scroll only on initial week entry/change, not on every clock tick/rebuild.
- [ ] Center the entire time-range column against the whole Today card; preserve long title/detail wrapping and no-end events. Run the focused tests, then inspect 320/360/412dp widths, text scale 1.0/1.5/2.0 and all eight families. Check p1/p4/p8 references directly.
- [ ] Commit checked calendar changes separately with message `feat: refine date selection and show the full day`.

**Concrete geometry assertion pattern (inside the existing `appTest` callback):**
```dart
final first = find.byKey(const ValueKey('day-2026-11-01'));
expect(h.tester.getTopLeft(first).dx, inInclusiveRange(16.0, 20.0));
expect(h.tester.takeException(), isNull);
```
These dates are the harness's fixture week, not claims about today's date.

## Task 3: Bottom-sheet editor, three stages and usable time/alert controls

**Requirements:** R11, R12, R13, R20, R21, R22.
**Modify:** router/editor/details/add-menu/alert-editor files; relevant import review caller if the shared editor return contract changes.
**Create:** `labeled_field.dart`, `bottom_sheet_page.dart`, `schedule_time_picker.dart` as defined above.
**Tests:** existing `schedule_screens_test.dart`, `pending_save_test.dart`, `editor_theme_test.dart`, `test/features/imports/import_review_test.dart`, `test/app/deep_links_test.dart`; add `test/features/schedules/schedule_time_picker_test.dart`.
**Interfaces:** Keep `ScheduleEditorScreen` constructor, `EditorScope`, schedule repository calls and import-review return behavior. Add private `_EditorStep { details, time, alerts }`, retain a single controller/state owner across stages; no per-step reconstructed drafts.

- [ ] Update/add test `editor_opens_as_bottom_sheet_without_new_destination`: create/edit routes use `BottomSheetPage<void>`, old navigation stays underneath, and new/edit/occurrence/review scopes resolve the correct existing data. Cold widget/deep-link opening establishes a real base route before presenting a sheet, without saving anything.
- [ ] Write `editor_stages_keep_all_fields_on_back`, `end_default_only_for_new_timed_drafts`, `late_night_default_end_advances_date`, `dirty_sheet_all_exit_paths_confirm`, `failed_and_double_save_do_not_lose_or_duplicate_data`. Assert no repository write before final Save; existing no-end and import drafts stay no-end; close, system Back and attempted scrim/drag dismissal cannot bypass the guard.
- [ ] Write `fields_have_inside_labels_without_notched_border`, `wheel_cancel_keeps_original_time`, `time_picker_supports_keyboard_12h_and_24h`, `alerts_keep_preferences_and_permission_states`. Assert `showScheduleTimePicker` returns null on Cancel; AM/PM and 00:00/23:59 survive; stage changes preserve notification/alarm offsets, repeats, zone and exceptions.
- [ ] Run `flutter test test/features/schedules test/features/imports/import_review_test.dart test/app/deep_links_test.dart`; observe failures only where the planned UI/behavior is absent and update old tests to follow the staged interaction, not bypass it.
- [ ] Present create/edit as bottom-origin modal routes. Keep the existing occurrence sheet and occurrence/series scope prompt. Use guarded Close/Back and disable unguarded editor scrim/drag dismissal. Reuse the existing save/validation/error paths; route validation errors to their owning stage and focus the field.
- [ ] Render Details → Time → Alerts exactly as the spec lists; use `LabeledField`, filled rounded actions, Back/Next and final Save/Confirm. On new timed drafts initialize end one hour later, handling next-day rollover; preserve stored/imported values when loading. Keep all-day and unresolved-time behavior.
- [ ] Implement the platform-control wheel picker with Done/Cancel and typed alternative; keep existing localization/formatting and motion tokens. Replace scattered reminder chips with one coherent offset-selection sheet per alert, retaining existing choices/custom offset and privacy/permission controls.
- [ ] Run all focused tests; inspect keyboard-up, long title/notes, save error, cancel confirmation, review mode, Reduce Motion and large text beside PDF p2–3/p6–7.
- [ ] Commit as `feat: stage schedule editing in a bottom sheet`.

## Task 4: Settings/categories/profile and readable Privacy

**Requirements:** R09, R10, R11.
**Modify:** settings/categories/profile/privacy files and existing themed primitives. Reuse Task 3's `LabeledField`.
**Tests:** `test/features/profile/profile_screen_test.dart`, `test/features/profile/profile_isolation_test.dart`, `test/features/privacy/privacy_screen_test.dart`, `test/features/categories/category_swatch_test.dart`; add `test/features/categories/categories_screen_test.dart`.
**Interfaces:** Repository/profile/deletion APIs stay unchanged; presentation only.

- [ ] Add tests `categories_have_spaced_named_color_marks`, `profile_label_is_inside_field_above_value`, `privacy_summaries_expand_to_existing_disclosures`, `destructive_controls_remain_confirmed`. Assert local/backend deletion remain distinct, configured/unconfigured states are truthful, status/retry controls remain reachable and profile data is still excluded from shares/widgets.
- [ ] Run `flutter test test/features/profile test/features/privacy test/features/categories`; record new behavior failures.
- [ ] Add restrained soft icon backplates/folder-like category marks using real category colors and names. Improve row spacing without inventing new destinations. Restructure Privacy into concise expandable summaries; preserve the full disclosures, busy/error/deletion status and all confirmation behavior.
- [ ] Run the same tests and check long category names, dark/Pixel/Sketch styles and large text against p2/p5.
- [ ] Commit as `refactor: simplify settings without removing privacy controls`.

## Task 5: Per-family color/texture customization with a non-grid selector

**Requirements:** R15, R16, R17, R18, R19.
**Modify:** appearance/theme/database files; widget refresh listeners if new color dependencies need watching.
**Create:** `theme_customization.dart`; `lib/app/widgets/theme_texture.dart` for a small non-animated, cached/decorative surface treatment.
**Tests:** existing appearance/theme catalog/widget theme tests; add `test/features/appearance/theme_customization_test.dart`, `test/data/migration_v3_test.dart`, `test/app/theme_texture_test.dart`.
**Interfaces:** Add `Map<ThemeId, ThemeCustomization> customizations` to `AppearanceSettings`, including `copyWith`, equality, hash, load/save. Extend `themeFor(ThemeId id, {int customHue = 250, ThemeCustomization? customization})`; preserve the current integer `customHue` signature and existing call compatibility. Add `themeCustomizationsJson` text column default `'{}'` to `AppearancePreferences`, advance Drift schema 2→3 with additive migration; keep existing `customHue` for legacy Custom color fallback.

- [ ] Test fresh-install `ThemeMode.light`, existing v1/v2 theme/mode/customHue preservation, per-family round-trip isolation and malformed JSON fallback. Use valid new JSON fields only; ignore unknown keys and clamp/non-finite values safely. Existing saved System is preserved, not silently converted to Light.
- [ ] Test hue 0/359 and tone 0/100 for foreground/background/control contrast, readable category fills and unchanged Silkscreen/Caveat families. Assert text contrast at least 4.5:1 and required control boundaries at least 3:1; accessibility adjustments must be deterministic. Test None/Stripes/Paper/Gradient do not add semantics or obscure input values.
- [ ] Run `flutter test test/features/appearance test/app/theme_catalog_test.dart test/app/theme_test.dart test/features/widgets/widget_theme_test.dart test/data/migration_v3_test.dart`; establish intended failures.
- [ ] Implement the minimal additive persistence and palette overrides using the existing HCT/contrast logic. Keep null overrides at the exact family defaults; changing families retains their respective saved choices. Update generated Drift code using the repository's existing generation command; never hand-edit generated output.
- [ ] Replace the theme grid with one live preview plus horizontal style choices and a compact mode chooser. Add Main/Background hue and tone controls and optional texture selection with None. Do not import Cal.com's monochrome palette or marketing whitespace. Preserve special style fonts and old widget opt-in/default behavior.
- [ ] Render quiet static textures only on safe canvas/surface areas, including on dark backgrounds; no blur-heavy scene or animation package. Existing widget snapshot colors reflect the resolved palette; texture stays app-only unless separately justified.
- [ ] Run focused tests plus `flutter test test/features/widgets/widget_settings_theme_test.dart test/data/migration_v2_test.dart`; visually review all styles with extreme settings, large text and Reduce Motion. Confirm widget color refresh, not a contract-version bump.
- [ ] Commit as `feat: add per-theme colors and optional textures`.

## Task 6: Coherent widget controls and equal usable capacity

**Requirements:** R13, R14.
**Modify:** widget settings/preview, `WidgetPlanner.kt`, `WidgetRenderer.kt`, `ThemeStyle.kt`, generator and generated layout/drawable files only where sizing evidence requires it.
**Tests:** Dart widget settings tests and `android/app/src/test/kotlin/com/manalogadiel/schediel/widget/WidgetPlannerTest.kt`; add a themed-capacity test alongside it if clearer.
**Interfaces:** Preserve `WidgetPlanner.plan(result, heightDp, fontScale, extraChromeDp, titleLineSp)` and snapshot 1.0/1.1 compatibility. Keep compact maximum 2 and expanded maximum 4; the request is equal same-size capacity, not always exactly three.

- [ ] Reproduce the user's three-vs-two discrepancy with the same expanded widget dimensions, three available entries and each style's actual chrome/font metrics. Write `expandedStylesFitThreeAtReferenceHeight` and a one-pixel-below-boundary counterpart. For reference, at 260dp, 1.0 font scale and current 74dp detail-row estimate, three standard rows should fit; replace that fixture height only if device-measured reference dimensions differ, recording why.
- [ ] Keep/add tests for short widgets showing fewer, compact showing two, font scale ≥1.3 hiding details before entries, no clipped title/time, all-day captions and real Next ordering. Verify using both pure planning and actual generated-layout rendering/launcher inspection; a planner count alone is insufficient.
- [ ] Run `flutter test test/features/widgets` and, from `android`, `cmd.exe /c "gradlew.bat :app:testDebugUnitTest"`.
- [ ] Fix wasted style padding/row measurement at the shared source/generator, not by forcing three rows into every host. Reorganize settings around a preview and labelled single-choice controls instead of scattered chips; preserve instance/default distinction and explicit legacy look.
- [ ] Run generator/contract checks, native and Dart tests; install only when authorized, then compare the same three-entry expanded widget in all four style families on the same launcher size. Capture actual dp bounds/font scale and any unavoidable host limit.
- [ ] Commit as `fix: normalize widget controls and themed capacity`.

## Task 7: Share icon and evidence-backed link-sharing fixes

**Requirement:** R23.
**Modify:** `lib/app/icons.dart` and the selected original SVG share asset; sharing/deep-link/backend/web code only for a reproduced failure.
**Tests:** `test/features/sharing/`, `test/features/imports/import_review_test.dart`, `test/app/deep_links_test.dart`; existing backend/web-preview tests.
**Interfaces:** Preserve `AppIcons.share`, `SharingConfig`, payload/link formats, sender inclusion options, ownership-bound retries and preview/import separation.

- [ ] Replace the connected-nodes share glyph with a restrained original arrow-out-of-tray glyph while keeping accessible Share labels. Do not change the whole icon family.
- [ ] Test/trace unconfigured state, valid/expired/revoked/malformed links, cancel, sender omitted fields, offline/retry and opening a link without importing. Assert recipient review remains editable and no schedule is activated before explicit confirmation.
- [ ] Run `flutter test test/features/sharing test/features/imports/import_review_test.dart test/app/deep_links_test.dart`; run the existing `npm test` in `backend` and `web-preview` separately. If a defect is reproduced, write its failing regression before the smallest code fix; otherwise leave working backend logic alone.
- [ ] Check whether real backend/domain/HTTPS associations and release signing configuration have been supplied. If missing, keep sharing gated and record live E2E as blocked; do not invent deployment, domains or keys.
- [ ] With explicit deployment approval and prerequisites, test sender → actual browser preview → Android app handoff → editable review → confirmed import, plus revocation/expiry and a cold start. Read back the exact created/revoked share before claiming success; avoid profile data in payload/logs.
- [ ] Commit verified local fixes separately; do not label production sharing fixed until the live chain passes.

## Task 8: Measure and fix fresh-launch delay

**Requirement:** R24.
**Modify only after measurement:** `lib/main.dart`, `lib/app/lifecycle.dart` and a specifically identified blocking initializer. Optional diagnostic `tools/measure_startup.py` writes local raw results, not fabricated data.
**Tests:** `test/app/app_appearance_test.dart`, `test/app/deep_links_test.dart`; add `test/app/startup_state_test.dart`.
**Interfaces:** Preserve loaded appearance/filter/device-zone overrides before they drive schedule rendering, existing reconciliation ownership and initial-link behavior.

- [ ] Add tests `startup_preserves_theme_filter_and_zone`, `startup_corrupt_filter_falls_back_safely`, `cold_link_never_auto_imports`, `startup_initializer_failure_has_recoverable_state`. Keep correct persisted values and no duplicate initialization/reconciliation.
- [ ] Capture baseline from five force-stop fresh launches of the same profile/release build on the authorized SM-A326B: first frame, first meaningful schedule/empty content, Android launch total and any visible blank/flash. Force-stop each time; do not clear app data. Store raw logs with build/device/mode, including any debug comparison separately.
- [ ] Profile the slow span: pre-`runApp` zone lookup, database/open/migration, appearance/filter load or lifecycle widget/reminder reconciliation. Choose the measured bottleneck, not a guessed one. After baseline, record a numerical target before editing; if no substantial app-controlled delay is found, report that instead of adding speculative async complexity.
- [ ] Make one justified change: parallelize independent reads, cache a stable lookup or move genuinely noncritical reconciliation after the first frame with existing error handling. Do not flash default themes, display wrong-time schedules, drop pending links or postpone required migration validation.
- [ ] Run startup/theme/deep-link tests; repeat five same-condition launches, compare medians and worst observations programmatically. No speed claim without raw before/after data. Device unavailable means the performance task remains unverified, not completed by unit tests.
- [ ] Commit a measured fix as `perf: reduce measured cold-start blocking` only if evidence supports it.

## Task 9: Original icon concepts, then selected launcher integration

**Requirement:** R25. Separate approval gate.
**Create after plan approval:** three small editable vector concepts in `assets/branding/concepts/`; selected source becomes `assets/branding/app-icon.svg`.
**Modify after concept selection only:** actual Android adaptive/legacy/monochrome and iOS AppIcon resource files discovered from the current project; do not replace the user profile image.
**Interfaces:** No identity feature, avatar sync or portrait upload. The portrait is a private visual reference, not an app asset.

- [ ] Sketch three low-detail original concepts combining a simplified hair/glasses/head silhouette with a calendar/check/time cue. Use flat purposeful shapes, no tiny facial detail or copied institution/calendar branding. Image generation is optional, not a new dependency or permission to upload the portrait.
- [ ] Render at 24/48/108 logical-pixel review sizes and under Android circular/rounded-square/squircle masks; check dark, light and monochrome. Verify SVG XML has no script, external references or embedded photo.
- [ ] Present concepts and stop for the user's selection. Do not treat plan approval as icon-concept approval.
- [ ] Integrate the selected vector into platform-required assets using available local rendering tools. Preserve adaptive safe-area/mask behavior and inspect on the actual launcher; run Android assemble/lint. iOS resource inspection remains source-only without a Mac.
- [ ] Commit selected assets as `design: add approved Schediel launcher icon`.

## Task 10: Reference audit, regressions and handoff

**Modify after implementation:** `DESIGN.md`, `SCHEDULER_SPEC.md`, `README.md`, `VALIDATION.md`; regenerate the existing spec bundle/checksums using the repo tool. These are not being changed in the planning turn.

- [ ] Check every R01–R25 against its owning task and PDF page. Separate functional tests, visual evidence, actual-device checks and blocked checks; no invented test totals or stale device state.
- [ ] Run `flutter analyze` and `flutter test`; run `python3 tools/check_widget_contracts.py` and `python3 tools/gen_widget_layouts.py --check` if native-widget outputs changed. Run the existing spec-bundle validation/generation workflow after reading its current CLI.
- [ ] From `android`, run `cmd.exe /c "gradlew.bat :app:testDebugUnitTest :app:lintDebug :app:assembleDebug"`; run backend/web tests if those paths changed. Record warnings rather than silently treating them as new errors or claiming zero warnings.
- [ ] On the authorized phone, check Today/Week/old bar/month picker/staged editor/keyboard/permissions/privacy/all eight styles and same-size widgets. Test text scaling, TalkBack, Reduce Motion and night mode where possible; inspect 23:00 and midnight, not just the first screen.
- [ ] One independent whole-diff review, then fix material findings and rerun affected checks. Run the repository's secret scan; review the diff for personal/reference-photo inclusion, accidental generated output and unplanned redesigns.
- [ ] Confirm user authorization for commit/push before shipping. Use `git -c core.safecrlf=false commit`; never force-push/reinitialize. Verify remote state after an authorized push. Report exact checked scope and anything still gated (live sharing, icon choice, device performance, iOS).

## Planning self-review

- R01–R25 each have an owning task; the blank ninth PDF page adds no hidden requirement.
- Calendar/header correction is explicit and is tested geometrically; old navigation is a preservation constraint, not an approximation in HTML.
- Every new shared interface is declared once; current schedule/editor/import/ownership contracts remain stable.
- Editor defaults, appearance migration, widget short-host behavior and cold links have named checks, not just happy-path screenshots.
- No product implementation or verification is claimed by this document. Approval is still required before Task 1.
