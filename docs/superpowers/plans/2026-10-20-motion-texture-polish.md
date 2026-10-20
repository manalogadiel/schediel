# Motion, Texture & Polish Plan

Branch: `feat/motion-texture-polish` (from `feat/pdf-ui-refinement`)
Follows: `2026-10-20-pdf-ui-refinement.md` (completed)
Status: **plan only — nothing implemented yet**

## 1. PDF audit ("problems and fixes.pdf")

| # | PDF item | Status | Evidence |
|---|----------|--------|----------|
| 1 | Background reaches status/nav bars | Done* | `16f330a` |
| 2 | Animation when tapping nav / icons | **Not done** | Only the pill width animates; page swap is instant (`StatefulShellRoute.indexedStack`); 0 `AnimatedSwitcher`/`AnimatedScale` in `lib/` |
| 3 | Illustrated empty state | Done | `assets/illustrations/schedule-empty.svg` |
| 4 | Month date picker, clickable dates | Done* | `d803d6b` |
| 5 | Week view 24 h + spacing | Done* | `d803d6b` |
| 6 | Settings icons plain / privacy too long | Partial | Privacy trimmed (`7938290`); icons still mono Lucide |
| 7 | Instagram-style field labels | Done | `widgets/labeled_field.dart` |
| 8 | Occurrence editor as bottom sheet, modern buttons | Done | `9504413` |
| 9 | Reminder chips → better selector | Verify | `alert_editor.dart` |
| 10 | Widget shows 3 cards in all styles | Done* | `130b885` |
| 11 | Timeline: consistent spacing, centered time | Verify | `timeline_row.dart` |
| 12 | Categories soft folder design | **Redo** | Plain `ListTile` + folder icon; wanted a folder-shaped card |
| 13 | Light default, per-theme hue + lightness | Done, but **buggy UX** | Sliders show no color, only numbers |
| 14 | Textures | **Partial** | Only None/Stripes/Paper/Gradient, very faint, background only |
| 15 | Modern mode selector (no grid) | **Not done** | Still `SegmentedButton` |
| 16 | Better font | **Not done** | Body uses system default; only Caveat/Silkscreen bundled |
| 17 | End time on by default | Partial | On for new schedules only (`_hasEnd = scope == create`) |
| 18 | Stepped editor with back | Done | `9504413` |
| 19 | Time picker with motion | Verify | `schedule_time_picker.dart` |
| 20 | Minimal 7-day strip | Done | `d803d6b` |
| 21 | Share icon + link sharing | Done | `3f36ac8` |
| 22 | Slow cold start | **Not done** | `main()` awaits license file, timezone, appearance, filter before `runApp` |
| 23 | App icon | Done | `c80b672` (concept files untracked) |

\* = committed; confirm on device during QA.

## 2. New requests → work items

### A. Navigation motion (highest impact)
- Shell: replace instant branch swap with a fade-through (old page fades + scales 0.98 out, new fades in, ~220 ms, `easeOutCubic`) via a custom `navigatorContainerBuilder`, keeping branch state.
- Nav pill: one sliding highlight that glides between items instead of each item recolouring in place; label slides + fades in.
- Icon micro-motion on select: Today = page flip, Week = columns rise, Settings = gear turns 60°; small scale bounce.
- Haptic `selectionClick`. All motion respects Reduce Motion (`AppMotion`).

### B. Distinct icon set
Today and Week currently share the same calendar outline (`calendar` vs `calendar-days`, only dots differ).
- **Today**: calendar with a single highlighted day.
- **Week**: seven vertical columns.
- Audit all `AppIcons` for look-alikes (`category`/`folder`, `agenda`/`filter`); add filled variants for selected nav state.
- Settings rows: tinted squircle behind each icon (finishes PDF #6).

### C. Color selector fix
Problem: grey Material sliders + a number; you can't see the color.
- Hue track painted as the hue spectrum; thumb filled with the current color.
- Lightness track painted dark → light of the chosen hue.
- Live "Main" / "Background" swatches beside the sliders.
- Preset swatch row for one-tap picks; sliders move under "Fine-tune".
- Fix draft/saved mismatch (`_draftTheme`/`_draft` vs provider) so preview = saved state.

### D. Theme & mode selectors
- Theme: snapping carousel of mini phone previews (focused one scales up) instead of text pills.
- Mode: animated sun ↔ moon toggle; "Auto" chip for System.
- Density: two small illustrated cards instead of a segmented button.

### E. Textures (background **and** cards/widgets)
Painter-generated (sharp at any density, no heavy PNGs):
Carbon fiber · Graphite/brushed · Abstract flow lines · Topographic · Mesh gradient · Paper grain (visible) · Dots · Stripes · Grid paper.
- Two levels: canvas texture + softer card/widget texture so cards and home widgets match.
- Picker: scrolling row of live texture swatches.
- Keep the contrast guard in `textureOverlay`, but allow higher intensity per texture so they're actually visible.
- Native widgets get pre-rendered texture bitmaps.

### F. Categories redesign
A card that *is* a folder: tab on top-left (custom `ShapeBorder`), body tinted with category color, name + schedule count inside, drag handle. Color choice in the sheet becomes tappable swatch circles instead of chips.

### G. Splash / launch intro
Why it looks blurry: Android 12+ splash uses the **raster** `mipmap/ic_launcher_foreground.png`, then Flutter swaps to a separate 640 px PNG; scaling between them softens it.
- Vector logo (VectorDrawable for system splash, SVG/CustomPaint in Flutter) → sharp from frame 1.
- ~1.1 s intro: logo stroke-draws in → calendar tab flips → **Schediel** wordmark staggers in letter by letter + short tagline → sheet slides up into the app.
- Skipped on Reduce Motion; never blocks input.

### H. Typography & long-text cleanup
- Bundle one UI font for Soft themes (Inter or Plus Jakarta Sans, OFL); keep Caveat/Silkscreen for Sketch/Pixel.
- Type-scale pass; shorten helper/subtitle copy in Settings, Privacy, Appearance, Reminders.
- Timeline row spacing (PDF #11).

### I. Remaining PDF gaps
- End time on by default when editing a schedule that has none (#17).
- Cold start (#22): `runApp` right away; defer license registration, filter load, timezone lookup until after first frame.
- Verify #9, #11, #19 on device.

## 3. Order of work
1. A + B — nav motion & icons
2. C + D — Appearance screen
3. E — textures (incl. widgets)
4. F — categories
5. G + cold start
6. H + remaining I
7. QA: `flutter analyze`, `flutter test`, run on Android, screenshots in Soft/Pop/Pixel/Sketch × light/dark

## 4. Skills applied during implementation
`design-motion-principles` / `improve-animations` (A, G) · `design-systems:icon-system` (B) · `ui-design:color-system` (C) · `impeccable` / `high-end-visual-design` (D–F) · `typography` + `design:ux-copy` (H) · `design-review` + `verification-before-completion` (QA).

## 5. Open questions
1. UI font: **Inter** (neutral, iOS-like) or **Plus Jakarta Sans** (rounder)?
2. Textures on cards/widgets too, or background only?
3. Splash tagline — e.g. "Your week, in order."?

---

## 6. Auto-mode brief (2026-10-20, user away — no questions)

**Goal:** a release build on the user's phone that looks designed, not default. References: glass card with
huge date + arched day strip (pink/orange aura), timeline with node line and filled "current" card,
gradient hero card with big start→end times, soft neumorphic light UI.

**Design language — "Soft Aura"**
- Inter for Soft themes; Caveat/Silkscreen kept for Sketch/Pixel.
- Today header: small weekday overline + oversized date ("October 20"), greeting demoted.
- Ambient aura: blurred accent/category blobs behind the header (Soft style only).
- Arched 7-day strip: days ride a gentle arc, selected day = gradient orb.
- Timeline: vertical rail with nodes; rows are cards (title left, time right, details below);
  ongoing row is accent-filled.
- **Next card always visible** (searches today → next 14 days), gradient hero with big
  `09:24 → 12:41` numerals, countdown chip, location.
- Own illustration for empty states (theme-colored painter, no stock art).
- Glass (blurred) floating nav bar.

**Also**
- Editor: replace "1 / 3" with a small segmented step indicator + step name.
- Appearance: Lightroom-style rows (label · thin hue/lightness track · value).
- Sharing: works without a server — schedules packed into a `schediel://import` link via the
  Android share sheet; receiver opens the existing import review. Cloud links stay when configured.
- Textures E, categories F, splash G (vector logo + typed wordmark + tagline "Your week, in order."),
  cold start.
- Ship: analyze, full tests, release APK installed with `adb install -r` (debug-key signed, keeps data).
