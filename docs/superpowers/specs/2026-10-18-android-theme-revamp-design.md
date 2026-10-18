# Android interface revamp: themes, profile and themed widgets

**Status:** design for approval · **Date:** 2026-10-18 · **Platform in scope:** Android (Flutter app + native home-screen widget)
**Approved direction:** the user approved the Today mockup and its themes in the conversation on 2026-10-18 (mockup file: `today-themes-v2.html`, copied to `docs/superpowers/specs/assets/2026-10-18-today-themes.html`).

Items marked **(builder's call)** were decided by the assistant, not the user, and may be changed if a better choice appears during implementation. Everything else was asked for or approved by the user.

## 1. Intent

Schediel works but looks plain: one neutral palette with a small accent choice. The user wants the app to feel modern and personal, with soft color, a friendlier Today screen, theme choices well beyond monochrome, an optional profile photo, and home-screen widgets that carry the same look. The aim is an app people *want* to open every morning, without turning schedules into decoration or showing invented content.

References the user supplied: pastel task-manager concepts with colored cards, a day strip, a large greeting/date header and a floating pill navigation bar. Only their visual language is borrowed. Their features (avatars on tasks, progress rings, priority tags, chat, team members) are **not** Schediel features and are excluded.

## 2. Goals

1. Restyle every Android screen to the approved visual language: Today, Week, schedule editor, occurrence details sheet, add menu, Settings and its sub-screens (appearance/themes, alerts, categories, widgets, privacy), sharing (create, open, shared links), import review, and image import (choose, crop, resolve).
2. Eight themes chosen in Settings and applied immediately: **Lilac, Clay, Pop, Mint, Midnight, Pixel, Sketch, Custom color**.
3. An optional local profile: display name and photo, shown on Today.
4. The Android home-screen widget follows the chosen theme (colors, shape style and display font), while keeping its clear, wallpaper-friendly character.
5. No loss of behavior: all existing flows, tests and accessibility guarantees keep working.

## 3. Non-goals and anti-goals

- **Non-goals now:** iOS visual polish (iOS only receives the minimal compatibility change in §8.4), lock-screen widgets, cloud/profile sync, sharing a profile, new schedule features.
- **Anti-goals (a failure even if it "works"):**
  - Sample or invented content in the shipped UI (no fake avatars, progress, priorities, counts or placeholder people). Every word and number shown comes from the user's data or fixed interface labels.
  - Themes that hide information or drop below contrast minimums.
  - Wallpaper replacement or reading the wallpaper (unchanged rule from the main spec).
  - Decorative gradients, glass blur, or motion that delays the user.
  - Pixel or handwriting fonts used for body text such as room, professor or notes.

## 4. Visual language (applies to all themes)

The approved mockup is the reference for proportions. Surface archetype: Today and Week are **Monitor** surfaces (glanceable, the next thing dominates); editor/settings are **Configure** surfaces (quiet, progressive disclosure).

- **Canvas** is a tinted background; content sits on rounded cards with generous spacing (16dp page margins, 8–12dp between rows).
- **Header (Today):** avatar circle (photo or initial), a two-line greeting ("Good morning" + name), and a round share button on the right. Below: a large date heading (two lines, ~30sp, weight per theme).
- **Day strip:** seven days of the selected week; the selected day is a filled pill in the accent color; days that have schedules show a small dot (computed from real data). Tapping a day selects it; horizontal swipe moves by week. The existing date picker remains reachable by tapping the date heading.
- **Controls that move, not disappear (builder's call):** the previous/next-day buttons are replaced by the day strip (tap any day; swipe for other weeks). When the selected day is not today, a "Today" pill appears beside the date heading, and tapping the Today tab while already on Today also jumps back. The category filter pill moves to the right of the timeline's section header ("Today ··· Filter") and keeps sharing `appFilterProvider` with Week. At 200% text the header wraps (greeting above, buttons stay 48dp) rather than truncating.
- **Next card:** large accent-filled card for the next timed occurrence: "Next · in 40 min" (relative label computed live), title, then time range, location and professor with small icons. If something is ongoing, the Next card still shows the *next* item; ongoing items appear in the timeline with a **Now** badge and an elapsed-time bar. If nothing is next, the card is not shown (no placeholder).
- **Timeline:** rows with a time column (start bold, end muted) and a colored card per occurrence: title, category chip, and detail line (location, professor). Card fill comes from the category's color as interpreted by the theme (§5.3). Past rows are dimmed; "Earlier today" collapse stays.
- **Floating navigation:** a pill-shaped bar floating above the content with Today, Week and Settings; the selected destination expands to icon + label. A separate round **+** button beside it opens the existing add menu (create, import image, open shared link). The bar respects the system gesture inset and never covers the last list item (bottom padding equals bar height + inset).
- **Other screens** keep their structure; they adopt theme surfaces, card radius, button shapes (full-pill primary buttons, round icon buttons), chip styles and the display font for screen titles.
- **Icons:** existing SVG icon set, stroke style kept consistent; new icons only where a control needs one (clock, location pin, person, share, plus).
- **Motion:** theme changes cross-fade (~220ms). Day-strip selection animates the pill position (~160ms). Next card count-down text updates each minute without animation. With Reduce Motion / "Remove animations", all of these become instant and Sketch's slight card tilt is removed.

## 5. Themes

### 5.1 Theme model

A theme defines:

- **Palette:** canvas, surface, ink, secondary ink, accent, on-accent, divider, nav background, nav ink, nav selected background, nav selected ink, Now badge colors, and six **category fills** with a card ink color (one fill per existing `CategoryColor` key: blue, green, orange, red, purple, gray).
- **Shape style family:** `soft` (rounded cards, faint shadow), `pop` (2dp black outlines + hard 3dp offset shadow), `pixel` (square, notched pixel corners drawn with stepped outlines), `sketch` (hand-drawn irregular outlines, lined-paper canvas, ≤1° card tilt).
- **Fonts:** display font (headings, date, card titles, day numbers, Next title) and body font (everything else). Body font is the system font in every theme.
- **Brightness variants:** light and dark. Theme choice combines with the existing appearance mode (System / Light / Dark). **Midnight is dark-only** and ignores the mode. All other themes get a dark variant **(builder's call:** derived to keep the theme's character; Pop dark = near-black canvas with the same saturated fills; Sketch dark = dark slate "chalkboard" paper with pale lines; Pixel dark = deep navy with the same fills**)**.

### 5.2 Theme definitions (light values from the approved mockup)

| Theme | Style | Canvas | Accent / on-accent | Category fills (blue, green, orange, red, purple, gray) | Display font |
|---|---|---|---|---|---|
| Lilac (default) | soft, radius 22 | #F4F2FC | #6A5AE0 / #FFFFFF | #DDEBFF, #DDF3E6 *, #FFF1C7, #FFE1EC, #E7E1FF, #ECEBF2 * | system, bold |
| Clay | soft, radius 26 | #F3ECE4 | #A9502C / #FFFFFF | #DCE3EA *, #D9E2CC, #EBDDBF, #F0D3C2, #E6CFD0, #E7E0D8 * | system, bold |
| Pop | pop, radius 18 | #FFF4D6 | #FFD400 / #111111 | #6FD3FF, #B6F36A, #FFB547, #FF9EC4, #C9B6FF *, #E5E5E5 * | system, black (900) |
| Mint | soft, radius 20 | #EDF5F0 | #17805A / #FFFFFF | #D8E8F6, #D3EFDF, #F6E4D1, #F6D9D9 *, #E9E1F6, #E6ECE8 * | system, bold |
| Midnight (dark only) | soft, radius 22 | #0F1117 | #9DB8FF / #0F1117 | #23304A, #24382F, #3A3226 *, #3A2632, #2E2742, #262A33 * | system, bold |
| Pixel | pixel, radius 0 | #EDEBDD | #3D5AFE / #FFFFFF | #A0C4FF, #9BE7C4, #FFD166, #FF8FA3, #C3B1FF *, #D8D6CB * | Silkscreen |
| Sketch | sketch | #FBFAF5 (lined) | #FFE066 / #2B2B2B | #B3E5FC, #C8E6C9, #FFE0B2, #F8BBD0, #E1BEE7 *, #E0E0E0 * | Caveat |
| Custom color | soft, radius 22 | generated | generated | generated | system, bold |

`*` = value not in the mockup, chosen to complete six slots **(builder's call)**. Exact values may be adjusted to meet §5.5; the mockup's visible character must remain.

### 5.3 Category colors

Categories keep their stored color key (`CategoryColor`). The theme decides how each key looks (its fill + card ink). The existing "show category colors" setting still applies: when off, cards use the theme's neutral fill (gray slot). Category color is never the only signal: the category name chip is always shown on cards.

### 5.4 Custom color

A hue slider (0–359) plus a live preview. The palette is generated with Material's HCT color space (`material_color_utilities`, already a transitive Flutter dependency): accent at tone ~40 (light) / ~80 (dark), canvas at tone ~98/~6 with low chroma. **Category fills keep their own hue family (builder's call):** a "red" category stays reddish in every theme, including Custom; Custom only sets the accent, canvas, nav and neutral colors, and nudges each category fill slightly toward the chosen hue (≤ 20° shift) so the palette feels unified. Generated pairs must satisfy §5.5 for every hue; if a pair fails, the generator adjusts tone (not hue) until it passes.

The category editor's swatches show the *current theme's* fills, still labelled with the key names (Blue, Green, Orange, Red, Purple, Gray), so what the user picks is what they see.

### 5.5 Contrast and readability rules (enforced by tests)

- Body and label text against its actual background (canvas, surface, card fill, accent, nav, badge): **≥ 4.5:1** in every theme, both brightnesses, and for custom hues sampled every 15°.
- Large display text (≥ 24sp regular or ≥ 18.5sp bold) ≥ 3:1; non-text indicators (selected day pill boundary, focus ring, outlines) ≥ 3:1.
- Text scale 200% on a 320dp-wide screen: no overflow exceptions on Today, Week, editor, theme picker and profile screens. Pixel/Sketch display fonts scale with the user's text size.
- Display fonts never render location, professor, subtitle, notes, error messages, or form input text.

### 5.6 Fonts

Bundle two open-licensed (SIL OFL 1.1) font files as app assets: **Silkscreen** (Pixel) and **Caveat** (Sketch), with their license texts registered in Flutter's license registry (visible under Settings → About/licenses). No runtime font downloading (the app works offline). The same font files are copied into Android `res/font` for the widget.

## 6. Profile

- **Fields:** optional display name (1–40 characters, trimmed) and optional photo. Both are stored only on the device.
- **Photo flow:** Settings → Profile → "Choose photo" opens the system photo picker (gallery; camera optional via the existing image picker). The user crops to a circle (pan/zoom, explicit Save/Cancel). The saved image is re-encoded as a 512×512 JPEG with metadata stripped, written to app-private storage; the previous file is deleted on replace. "Remove photo" deletes the file.
- **Display:** Today header shows the photo; without a photo, a circle with the name's first letter in the theme's accent tint; with neither name nor photo, no avatar is shown and the greeting stands alone ("Good morning").
- **Greeting:** "Good morning" 05:00–11:59, "Good afternoon" 12:00–17:59, "Good evening" otherwise, from device local time; updates on the existing minute ticker.
- **Privacy:** the profile is never included in share links, widget snapshots, logs or backend requests. The Privacy screen states this, and "Delete local data" offers removing the profile too (separate checkbox, default checked) **(builder's call)**.
- **Storage:** new Drift columns/table via a proper schema migration (version 2) with a migration test from version 1 data.

## 7. Settings changes

- **Appearance** becomes **Theme**: a grid of theme preview tiles (mini Today card in each theme's colors and shape), selected state with a check and outline; mode selector (System / Light / Dark, disabled with explanation when Midnight is selected); Custom color tile opens the hue slider sheet with live preview and "Use this color".
- **Migration of existing users:** the stored `accentKey` maps to a theme **(builder's call)**: blue→Lilac, teal→Mint, indigo→Lilac, graphite→Midnight when dark mode is set, otherwise Clay. New installs default to Lilac. Density and category-color toggles remain.
- **Profile** section at the top of Settings: avatar, name field, photo actions.

## 8. Home-screen widget

### 8.1 Behavior

- New per-widget option **"Use app theme"** (default **on** for newly added widgets; existing widgets keep their current look until the user turns it on) **(builder's call)**.
- With the app theme on, the widget keeps a transparent root (wallpaper visible around holders, as today) and themes the holders:
  - **Next holder:** accent fill, on-accent text, display-font title.
  - **Upcoming holders:** category fill (or neutral fill when category colors are off), card ink text.
  - **Surface option still applies:** *clear* = theme fills at reduced opacity with a thin theme outline for edge definition; *soft tint* = higher opacity; *solid* = fully opaque. Text tone is derived from each holder's fill. **Contrast rule for translucent holders (builder's call):** the fill is composited over both pure black and pure white wallpaper, and the opacity used for each theme/holder is the lowest value (starting at ~70% for clear, ~88% for soft tint) at which card text meets 4.5:1 over *both*; if no value below 100% passes, that holder renders opaque. Opacities are computed in Dart when writing the snapshot and tested; the widget never guesses from the wallpaper.
  - **Style family:** soft/pop/pixel/sketch holder shapes (rounded; outlined with hard shadow; notched square; hand-drawn outline) and the display font for titles (Silkscreen/Caveat for Pixel/Sketch).
- With the app theme off, the widget renders exactly as now.
- Changing theme in the app refreshes all widgets through the existing snapshot write.

### 8.2 Snapshot contract change

The widget snapshot schema moves from `1.0` to **`1.1`** (additive):

- New optional top-level object `theme`: `{ id, style: soft|pop|pixel|sketch, light: Palette, dark: Palette }` where `Palette = { accent, onAccent, neutralFill, cardInk, outline, categoryFills: { blue, green, orange, red, purple, gray }, opacity: { clear, softTint } }`, colors as `#RRGGBB`. **Both palettes are always written (builder's call)** so the widget follows the phone's night mode even while the app is closed: when the app mode is System the native side picks by the system night mode; when the app is set to Light or Dark (or the theme is Midnight), `light` and `dark` carry the same palette.
- New optional per-occurrence field `categoryColor` (one of the six keys, or null).
- New per-widget configuration field `useAppTheme` (boolean, default false when absent).
- Readers accept `1.0` and `1.1`; any other version keeps the existing safe "Open Schediel" state.
- Update `contracts/schemas/` (new `widget-snapshot-v1_1.schema.json`), fixtures, `CONTRACTS.md` §6 and the reader rules. The `1.0` file stays for history.

### 8.3 Android implementation constraints

RemoteViews cannot change fonts or arbitrary shapes at runtime, so:

- One widget layout per style family (soft, pop, pixel, sketch), each declaring its fonts via `res/font` (supported for XML-inflated widget layouts on API 26+).
- Holder backgrounds are white shape drawables per style tinted at runtime (`setColorFilter` on a background `ImageView`, available on API 26), so Custom-color themes need no pre-generated drawables.
- The Kotlin planner/reader/renderer gain unit tests for: parsing `1.1`, fallback when `theme` is missing or malformed, color parsing, text-tone derivation, and holder-style selection.

### 8.4 iOS compatibility (minimal)

The iOS WidgetKit reader currently rejects anything but `1.0`. It is updated to accept `1.1` and ignore the theme fields, so the iOS widget does not regress to "Open Schediel". No iOS visual theming in this project. Still unbuilt on Windows (existing gate).

## 9. Implementation boundaries

- Theme is the single source: `ThemeData` + the `ScheduleColors` extension grow into a `SchedielTheme` extension carrying palette, style family and fonts; screens read from it rather than hard-coding colors. Remove the old `AccentPreset` once migration is in place.
- Shape styles are reusable widgets (`ThemedCard`, `ThemedPill`, `ThemedIconButton`, `ThemedChip`) so every screen picks up pop outlines, pixel notches and sketch outlines consistently. Sketch outlines are drawn by a `CustomPainter` with a deterministic seed per card (no jitter on rebuild).
- Fonts are declared in `pubspec.yaml` assets; license files under `assets/fonts/LICENSE-*.txt`.
- No new third-party UI packages except an image-crop solution if the existing crop screen cannot be reused **(builder's call:** prefer adapting the existing `ImageCropScreen` for a square crop with circle mask before adding a dependency**)**.
- **Phase 0, prerequisite (part of the plan):** finish and commit the pending, currently staged sharing/import/privacy/image work together with its open review fixes, before any revamp code lands, so the two changes stay reviewable separately and the shared documents (`DESIGN.md`, `CONTRACTS.md`, `VALIDATION.md`, `FULL_SPEC.md`) do not collide. The open fixes are:
  - **R1** — completing a backend-deletion job must only clean the local share records that existed when deletion was requested, never newer links or their secrets; unresolved pending creations are kept.
  - **R2** — a pending share-creation retry is bound to the online identity that first submitted it; if that session is lost or changed, the retry fails safely (keeps the attempt) instead of signing in again and creating a duplicate link.
  - **R3** — a backend-deletion request whose response was lost and whose idempotency key expired gets an explicit, user-confirmed "request again" path with a fresh key.
  - **R4** — the browser preview's "Open in Schediel" must not navigate the same page to a token fragment; it uses an explicitly configured, distinct app-link host, and without one the button is not shown.
  - **Backend packaging** — the PostgreSQL driver import in `backend/supabase/functions/_shared/runtime.ts` must be statically discoverable so deployment bundles include it.
  Partial edits for R1–R4 exist in the working tree from interrupted helpers and must be re-verified, not trusted.

## 10. Verification

- **Unit/widget tests:** theme definitions (all eight × light/dark, custom hue sweep) against §5.5; theme persistence and `accentKey` migration; profile repository (save/replace/remove, file cleanup, metadata stripping, name validation); greeting boundaries; Today header with/without name/photo; day strip selection and dots from data; Next card hidden when nothing is next; floating nav does not cover last row; reduce-motion paths; large-text overflow tests; existing 191 tests stay green.
- **Golden images:** Today, Week, editor and theme picker rendered per theme (light and dark) at 360×800 and committed as golden files, used both as regression tests and as the visual review artifact.
- **Widget:** Kotlin JVM tests per §8.3; snapshot builder tests for `1.1`; schema fixture validation in Dart and Node.
- **Build checks:** `flutter analyze`, `flutter test`, `flutter build apk --debug`, Gradle unit tests + lint, DESIGN lint after `DESIGN.md` gains the theme tokens.
- **Device checks (still required, not provable here):** real launcher rendering of themed widgets in all four style families, font rendering in RemoteViews, wallpaper legibility, photo picker and crop on a phone. Available device: the user's Samsung Galaxy A32 5G (SM-A326B, Android 13 / API 33, 720×1600, One UI launcher) over wireless adb. The assistant installs debug builds and captures screenshots with `adb exec-out screencap`; placing the widget on the home screen and choosing a photo are done by the user on the phone.

## 11. Documentation

Update `DESIGN.md` (theme tokens, style families, fonts, profile, widget theming), `SCHEDULER_SPEC.md` appearance/profile/widget sections, `CONTRACTS.md` §6 and `VALIDATION.md`; regenerate `FULL_SPEC.md` and checksums with `tools/spec_bundle.py`.

## 12. Left to the builder

Exact dark-variant values, the six-slot fills marked `*`, icon drawings for new controls, animation curves within the stated durations, internal file/class names, and test organization — all within the rules above.
