# Review Fixes & Sharing Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the six issues from the 2026-10-21 review PDF, connect online sharing to a real Supabase project, and ship a release build to the phone.

**Architecture:** UI fixes stay inside existing widgets (day strip, date picker, occurrence sheet, week grid, categories, native widget planner). Sharing reuses the finished backend (`backend/supabase`) and web preview (`web-preview`); the work is provisioning, configuration and build wiring, not new protocol code.

**Tech Stack:** Flutter 3.47 / Dart, Riverpod, Kotlin RemoteViews widgets, Supabase (Postgres 17, Edge Functions, anonymous auth), static web preview (Vercel).

**Spec:** review PDF "On this first image I see that you tried to do the curve effect on the day" (2026-10-21) + `backend/README.md` + `web-preview/README.md`. Follows `2026-10-20-motion-texture-polish.md`.

## Analysis of the review (observed → root cause → design decision)

| # | Observation | Root cause | Decision |
|---|---|---|---|
| 1 | Day-strip curve runs *through* the labels; the reference has a curved glass band *behind* the dates | `_ArcPainter` draws two thin lines at fixed heights that ignore the per-cell arc offset; the selected day also gets a full-column rectangle outline on low-contrast themes | Replace lines with a **curved band**: a filled lens shape (area between two parallel arcs) behind the number row only, soft shadow beneath, 1 px highlight on its top edge. Weekday labels sit above the band. Selected = gradient orb; the low-contrast edge becomes a ring on the orb, never a column box |
| 2 | Date picker is the stock Material dialog | `pickDate` calls `showDatePicker` | Custom **bottom-sheet month calendar** (Task 2 design) |
| 3 | Sheet buttons have borders; Remove hides its trash icon | Global `filledButtonTheme` adds an outline when accent contrast < 3:1 (pink theme); destructive button's icon inherits the red fill | No outlines on Soft buttons; low contrast solved with a darker fill. Destructive = **soft red container** (error @ 12%) with error-colored text **and** icon |
| 4 | Week header days don't line up with grid columns | Header `DayStripView` spans full width with `Tokens.md` padding; the grid starts after a 44 px gutter (`_gutter`) and ends `Tokens.md` early | Header built from the **same column geometry** as the grid (gutter + 7 × `colWidth`); the selected day is one continuous rounded column (header pill flowing into a tinted column). Event blocks: left color bar, 2-line title with ellipsis (no mid-word wrap), start time |
| 5 | Categories: folder icon in every card; wanted a normal card with a folder-tab accent on its top-left, colorable; schedule tags colored and borderless | Folder card added an icon badge; timeline tag is an ink-tinted neutral pill | Remove the badge. Normal card + folder tab top-left in the category color. Timeline tag = **filled pill in the category color**, no border |
| 6 | Home widget shows 2 cards in some styles, Pixel shows 3 | `WidgetPlanner` estimates row height with constants (`HOLDER_CHROME_DP = 22`, title 20/25/17 sp) that overshoot the real XML layouts for Soft/Pop/Sketch | Calibrate per-style metrics to the actual layout XML so the estimate matches reality; stretch shown holders to fill leftover height. Larger widgets still add rows |

Plus: the last release build failed in R8 (`minifyReleaseWithR8`).

## Global Constraints

- Every animation respects Reduce Motion (`AppMotion` / `MediaQuery.disableAnimationsOf`).
- Text contrast ≥ 4.5:1 on its actual background; non-text marks ≥ 3:1.
- Pixel keeps square corners; Sketch/Pixel keep their display fonts.
- Never commit secrets (DB password, service keys, `SCHEDIEL_RATE_HASH_SECRET`, keystore passwords). Only URLs and the publishable key, in git-ignored `env/sharing.json`.
- Opening any link never adds schedules without confirmation.

## Review Focus

1. 200% text on the arched strip and month sheet — no clipping; arc flattens when text scale ≥ 1.5.
2. 3+ overlapping events in one narrow week column — titles ellipsize, never split mid-word, blocks ≥ 20 px tall.
3. Widget one row tall — still shows next title + time, no overflow.
4. Sharing offline / backend down — honest error on Create link; Send link (offline) still works.
5. Category with no color — neutral tab and tag, contrast holds.

---

### Task 1: Curved glass band behind the day numbers

**Files:** Modify `lib/features/schedules/presentation/day_strip.dart` (`DayStripView`, `_ArcPainter` → `_BandPainter`, `_DayCell`); Test `test/features/schedules/day_strip_test.dart`, `test/app/customized_surfaces_test.dart`.

**Interfaces:** `DayStripView(arched: true)` unchanged; static `DayStripView.bandTop(double x, Size size)` for tests.

- [ ] **Step 1: Failing tests** — `arched band sits behind numbers, not labels`: every weekday label's bottom is above `bandTop` at its centre x; `low-contrast selected day rings the orb`: the `day-…` Material side is `BorderSide.none`, orb `BoxDecoration.border` non-null.
- [ ] **Step 2: Run** `flutter test test/features/schedules/day_strip_test.dart` → FAIL.
- [ ] **Step 3: Implement.** Band = closed path between two quadratic arcs 44 px apart around the number row, following `archDepth * ((x/w*6 - 3)/3)^2`; fill surface @ 55% (light) / white @ 6% (dark); shadow ink @ 8% blur 14 offset (0,6); top highlight white @ 60% 1 px. Arc depth → 0 at text scale ≥ 1.5.
- [ ] **Step 4: Run** → PASS (update `customized_surfaces_test` from Material side to orb border).
- [ ] **Step 5: Commit** `fix: curved glass band behind day numbers`.

### Task 2: Month calendar sheet (replaces stock date picker)

**Design:** bottom sheet, 28 px top radius, drag handle. Header: oversized month (heavy) + year (light, accent) with round chevrons; horizontal swipe pages months with slide+fade. Weekday row small caps, weekend letters accent. 7 × 6 grid of 44 px cells: other-month days at 30% ink; dot for days with schedules; today = accent ring; selected = the strip's gradient orb with glow. Grid sits on a raised soft card (top-left highlight, bottom-right soft shadow). Footer: "Today" text button, primary "Done" (no outlines).

**Files:** Create `lib/app/widgets/month_sheet.dart`; Modify `lib/features/schedules/presentation/today_header.dart` (`pickDate` delegates); Test `test/app/month_sheet_test.dart`.

**Interfaces:** `Future<LocalDate?> showMonthSheet(BuildContext context, {required LocalDate initial, Set<LocalDate> marked = const {}})`; keys `month-day-YYYY-MM-DD`, `month-next`, `month-prev`, `month-today`, `month-done`.

- [ ] **Step 1: Failing tests** — opens showing `October 2026`; tap `month-day-2026-10-21` + `month-done` → `LocalDate(2026,10,21)`; `month-next` → `November 2026`; `month-today` jumps to today's month; dismiss → null; 320×700 at 200% → no exception.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** with `showModalBottomSheet(isScrollControlled: true, useSafeArea: true)`; first weekday from `MaterialLocalizations.firstDayOfWeekIndex`.
- [ ] **Step 4: Run** → PASS (+ `today_screen_test`, `calendar_interaction_test` finders).
- [ ] **Step 5: Commit** `feat: month calendar sheet`.

### Task 3: Borderless buttons and a visible destructive action

**Files:** Modify `lib/app/theme/app_theme.dart` (`filledButtonTheme`), `lib/features/schedules/presentation/occurrence_sheet.dart:170-200, 340-350`; Test `test/features/schedules/occurrence_sheet_test.dart`.

- [ ] **Step 1: Failing tests** — Soft theme with low-contrast custom accent: resolved `FilledButton` shape side is `BorderSide.none`; Remove button icon color == label color == `colorScheme.error`, background ≈ error @ 0.12.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** Soft: no side; contrast < 3:1 → fill `Color.lerp(accent, ink, .35)` with readable foreground. Pop/Pixel/Sketch keep drawn outlines. Radius 16, min height 52. Remove: tonal with `backgroundColor: error @ .12`, `foregroundColor: error`, `iconColor: error`.
- [ ] **Step 4: Run** → PASS (+ `theme_catalog_test`, contrast tests).
- [ ] **Step 5: Commit** `fix: borderless buttons, visible remove icon`.

### Task 4: Aligned week header and readable blocks

**Files:** Modify `lib/features/schedules/presentation/week_screen.dart` (header :136-150, grid :340-440); Test `week_screen_test.dart`, `day_strip_test.dart` (Week case).

**Interfaces:** one `LayoutBuilder` provides `colWidth = (maxWidth - _gutter - Tokens.md) / 7` to a new `_WeekHeader` and the grid. Header cells keep keys `day-YYYY-MM-DD`; columns get `week-column-i`; highlight `week-selected-column`.

- [ ] **Step 1: Failing tests** — header cell i centre x == column i centre x ± 1; `week-selected-column` spans header top → grid bottom; narrow-column event `Automata Theory` uses `maxLines: 2`, `softWrap: true`, `TextOverflow.ellipsis`. Update the Week left-edge expectation to `_gutter`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** Gutter header shows week number (`W43`). Selected: 14 px-radius accent pill in header continuing as accent @ 7% column. Blocks: category fill, 3 px left bar in category strong color, title 11.5/600, start time 10.5 when height ≥ 38.
- [ ] **Step 4: Run** → PASS (+ `calendar_geometry_test`).
- [ ] **Step 5: Commit** `fix: align week header with grid columns`.

### Task 5: Card with folder tab; colored borderless tags

**Files:** Modify `lib/features/categories/presentation/categories_screen.dart` (`_FolderCard`), `lib/features/schedules/presentation/timeline_row.dart` (`_CategoryTag`); Test `categories_screen_test.dart`, `test/features/schedules/timeline_row_test.dart`.

- [ ] **Step 1: Failing tests** — no `AppIcons.folder` inside a category card; key `category-icon-<id>` moves to the tab so the existing test still finds one per category; a `red` category's timeline tag has `color == palette.fillFor('red')`, `border == null`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** Card body = surface; tab top-left (42% width, 14 px tall, curved shoulder) in the category strong color, i.e. the reference folder silhouette on top of a normal card. Tag: filled pill in the category fill, no border.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `fix: folder-tab category cards, colored tags`.

### Task 6: Widgets always fill their height

**Files:** Modify `android/app/src/main/kotlin/com/manalogadiel/schediel/widget/WidgetPlanner.kt`, `ThemeStyle.kt`, `WidgetRenderer.kt`; read metrics from `res/layout/widget_schedule_{soft,pop,pixel,sketch}.xml`; Test JVM `WidgetPlannerTest` + `tools/check_widget_contracts.py`.

**Interfaces:** `ThemeStyle.holderChromeDp(style: String?): Float`; `WidgetPlanner.plan(..., holderChromeDp: Float)`.

- [ ] **Step 1: Failing test** — at the height where Pixel shows 3, `plan()` returns 3 holders for every style at font scale 1.0.
- [ ] **Step 2: Run** `android\gradlew :app:testDebugUnitTest` → FAIL for soft/pop/sketch.
- [ ] **Step 3: Implement.** Chrome = holder vertical padding + margins + border from each XML; title line = text size × font line height (Caveat 1.25, Silkscreen 1.0, system 1.17). Spread leftover height as extra holder padding so the stack fills the container.
- [ ] **Step 4: Run** → PASS; on the phone every style shows 3 at the current size, more when enlarged.
- [ ] **Step 5: Commit** `fix: widget rows fill the container in every style`.

### Task 7: Release build and signing

**Files:** Modify `android/app/build.gradle.kts` (release signing from `key.properties`, R8 rules), `android/app/proguard-rules.pro`, `.gitignore` (`key.properties`, `*.jks`).

- [ ] **Step 1:** `flutter build apk --release -v`; read the R8 missing-class error; add the specific `-keep`/`-dontwarn` rules.
- [ ] **Step 2 (you):** `keytool -genkey -v -keystore %USERPROFILE%\schediel-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`; keep the passwords. I wire git-ignored `key.properties`.
- [ ] **Step 3:** release build passes; print SHA-256 for `assetlinks.json`.
- [ ] **Step 4:** a new signing key can't update the debug install → first **Send link** all schedules to yourself, uninstall, install release, re-import.
- [ ] **Step 5: Commit** `build: release signing and R8 rules`.

### Task 8: Connect online sharing to Supabase

**You do (account steps I'm not allowed to do for you):**
1. Create a free Supabase project (region: Singapore). Keep the DB password private.
2. Authentication → Providers → enable **Anonymous sign-ins**.
3. In this repo's terminal: `npx supabase login` (browser opens) once.
4. `npx vercel login` once (hosts the share page at `https://<name>.vercel.app/s/<id>`).
5. Send me only: project ref, Project URL, publishable key (`sb_publishable_…`), and the Vercel name you want.

**Files:** Create `env/sharing.example.json` (placeholders, committed), `env/sharing.json` (git-ignored), `tools/deploy_sharing.ps1`; Modify `.gitignore`, `README.md` (sharing setup), web-preview build config.

- [ ] **Step 1:** in `backend/`: `npx supabase link --project-ref <ref>`, `npx supabase db push`. Verify `npx supabase migration list` shows `202610180001` remote.
- [ ] **Step 2:** set secrets with `npx supabase secrets set` — `SCHEDIEL_RATE_HASH_SECRET` (generated locally, never printed), `SCHEDIEL_ALLOWED_ORIGINS=https://<name>.vercel.app`, `SCHEDIEL_TRUSTED_IP_HEADER=x-real-ip`, `SCHEDIEL_TRUST_PROXY_HEADERS=true`, `SCHEDIEL_DATABASE_URL` (you paste the pooled connection string into the prompt yourself). Verify `npx supabase secrets list`.
- [ ] **Step 3:** `npx supabase functions deploy share-links share-resolve privacy health scan`. Verify `GET <url>/functions/v1/health` → 200.
- [ ] **Step 4:** configure + deploy `web-preview` (`SCHEDIEL_API_BASE=<url>/functions/v1`, `SCHEDIEL_SHARE_HOST=https://<name>.vercel.app`, publishable key) with `/.well-known/assetlinks.json` (SHA-256 from Task 7). Verify page and assetlinks respond.
- [ ] **Step 5:** app: `--dart-define-from-file=env/sharing.json` + Gradle `-Pschediel.shareHost=<name>.vercel.app`.
- [ ] **Step 6: End-to-end on the phone:** create link → open it (App Link) → review → confirm adds; revoke → reopening shows "Shared link revoked"; offline → honest error, Send link still works.
- [ ] **Step 7: Commit** `feat: wire online sharing to Supabase` after checking `git diff --cached` has no `sb_secret`, `postgres://` or passwords.

## Order

Tasks 1–6 (UI, each checked on the phone with a debug build) → 7 (signing, needed for App Links) → 8 (needs your account steps; you can do them any time and send the details).
