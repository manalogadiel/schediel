---
version: alpha
name: Scheduling App
description: "Minimal, Apple-inspired scheduling UI with wallpaper-independent native widgets."
colors:
  primary: "#1D1D1F"
  secondary: "#5A5A60"
  tertiary: "#0066CC"
  neutral: "#F5F5F7"
  surface: "#FFFFFF"
  on-accent: "#FFFFFF"
  error: "#B3261E"
  input-boundary: "#8A8A92"
  divider: "#D6D6DC"
  dark-canvas: "#0C0C0E"
  dark-surface: "#1C1C1E"
  dark-ink: "#F5F5F7"
  dark-secondary: "#B2B2BA"
  dark-accent: "#64A7FF"
  dark-on-accent: "#081322"
  dark-error: "#FFB4AB"
typography:
  h1:
    fontFamily: system-ui
    fontSize: 30px
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: "-0.02em"
  h2:
    fontFamily: system-ui
    fontSize: 22px
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.01em"
  body-md:
    fontFamily: system-ui
    fontSize: 17px
    fontWeight: 400
    lineHeight: 1.45
  body-emphasis:
    fontFamily: system-ui
    fontSize: 17px
    fontWeight: 600
    lineHeight: 1.4
  caption:
    fontFamily: system-ui
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.4
  time:
    fontFamily: system-ui
    fontSize: 15px
    fontWeight: 500
    lineHeight: 1.35
rounded:
  control: 12px
  card: 18px
  sheet: 28px
  pill: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
components:
  button-primary:
    backgroundColor: "{colors.tertiary}"
    textColor: "{colors.on-accent}"
    typography: "{typography.body-emphasis}"
    rounded: "{rounded.control}"
    padding: 12px
    height: 48px
  button-primary-pressed:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-accent}"
  button-primary-dark:
    backgroundColor: "{colors.dark-accent}"
    textColor: "{colors.dark-on-accent}"
    rounded: "{rounded.control}"
    height: 48px
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    rounded: "{rounded.card}"
    padding: 16px
  card-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.secondary}"
    rounded: "{rounded.card}"
  card-dark:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.dark-ink}"
    rounded: "{rounded.card}"
    padding: 16px
  canvas:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.primary}"
  canvas-dark:
    backgroundColor: "{colors.dark-canvas}"
    textColor: "{colors.dark-ink}"
  metadata-dark:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.dark-secondary}"
  error-message:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.error}"
  error-message-dark:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.dark-error}"
  input-boundary:
    backgroundColor: "{colors.input-boundary}"
    height: 1px
  divider:
    backgroundColor: "{colors.divider}"
    height: 1px
---

## Overview

**Status:** proposed design requirements and review criteria, not an implementation report or evidence of user approval. The product name is not a chosen brand. Existing Flutter code must be checked against these requirements; this document does not certify app or native-widget behavior.

The primary surface is **Monitor**: people glance at a timeline to find the current or next schedule. A schedule editor is a secondary **Configure** surface. Composition follows the task: date and filter controls, an ordered timeline, then contextual actions. There is no marketing hero, decorative statistics, motivational slogan, or equal-weight feature-card grid.

The direction is minimal and Apple-inspired without cloning a branded screen. Hierarchy comes from type, spacing, alignment and restrained emphasis. Glass is limited to supported navigation/material treatments and widget holders. Important schedule text is not buried under blur.

People choose one of eight themes (see **Themes** below) so the app feels like theirs, not a gray utility. Themes change color, shape and heading type only; layout, copy, flows and behavior are identical in every theme. The front-matter tokens above are the neutral base used by the browser preview and these documents; the app's themes are defined in `lib/app/theme/theme_catalog.dart` and summarized here. A detailed rationale is in [docs/superpowers/specs/2026-10-18-android-theme-revamp-design.md](docs/superpowers/specs/2026-10-18-android-theme-revamp-design.md).

Normative product behavior, security rules and platform limits live in [SCHEDULER_SPEC.md](SCHEDULER_SPEC.md). External references are in [SOURCES.md](SOURCES.md).

### Implementation-specific values

The interchange format exports only its supported token maps. The values below are normative prose for Flutter/native implementation; do not assume a generic token export includes them.

| Concern | Proposed value / rule |
|---|---|
| Units | Logical UI units, mapped to Flutter logical pixels and native points/dp |
| Fonts | Platform system fonts for all body text and form fields. Two bundled OFL display fonts for headings only: Silkscreen (Pixel) and Caveat (Sketch); sources, SHA-256 and licenses in `assets/fonts/` and the app's license page. No proprietary Apple font is bundled |
| Themes | Lilac (default), Clay, Pop, Mint, Midnight, Pixel, Sketch, Custom color; four style families: soft, pop, pixel, sketch |
| Custom color | One hue control (0–359°, saved on release). Palette generated in HCT; text tones are moved until each pair passes contrast; category fills move at most 8° toward the hue |
| Control motion | 160 ms |
| Screen motion | 220 ms; reduced motion uses immediate changes or a brief non-spatial fade |
| SVG family | Curated local Lucide assets with retained license notices |
| SVG geometry | 24 by 24 view box; 2-unit stroke; round caps/joins; nominal display size 22 |
| Clear widget root | Requested alpha 0, requested blur radius 0 |
| Next holder | Without app theme: proposed alpha 0.18. With app theme: theme accent at the computed surface opacity |
| Upcoming holder | Without app theme: proposed alpha 0.06. With app theme: category fill (neutral when none) at the computed surface opacity |
| Themed holder opacity | Clear starts at 0.70, Soft tint at 0.88; raised in 2% steps until every holder text pair has 4.5:1 composited over black and over white; else opaque |
| Holder radius | Proposed 16 logical units, subject to native clipping and sizing |
| Clear-mode contrast | No guarantee over arbitrary wallpaper; offer a solid accessible preset |
| iOS widget material | System rendering mode may replace the background and tint content |

## Colors

### Light appearance

- `primary`: primary text, titles and schedule names.
- `secondary`: room, professor, date labels and supporting text; not disabled text.
- `tertiary`: selected controls, links and the primary action. It is not used to color every surface.
- `neutral`: app canvas; `surface`: grouped content and sheets.
- `error`: invalid input or an actionable problem, accompanied by text.
- `input-boundary`: interactive field boundaries where a visible boundary is necessary.
- `divider`: decorative separation only; never the sole outline identifying an essential control.

### Dark appearance

Use `dark-canvas`, `dark-surface`, `dark-ink`, `dark-secondary`, `dark-accent` and `dark-on-accent` as a coherent set. Do not simply invert each light color. The bright blue dark-mode action has dark text; do not replace that text with white without another contrast check.

Category colors are optional accents, never the only way to identify School, Work, Personal or a custom category. Every category has a visible name and accessible label. Additional accent choices must ship as tested foreground/background pairs, not as an unrestricted color picker that can silently make text unreadable.

### Themes

Each theme ships a tested light and dark palette (Midnight is dark only and disables the mode choice with the text **Midnight is always dark.**). Category colors keep their hue family in every theme, so "green" is still recognizably green, and they are never the only identifier.

| Theme | Style | Light canvas / accent | Dark canvas / accent | Character |
|---|---|---|---|---|
| Lilac | soft | `#F4F2FC` / `#6A5AE0` | `#15131F` / `#A99CFF` | Default; calm violet with pastel category cards |
| Clay | soft | `#F3ECE4` / `#A9502C` | `#1C1714` / `#E39A73` | Warm paper and terracotta |
| Pop | pop | `#FFF4D6` / `#FFD400` | `#141414` / `#FFD400` | Bold fills, 2-unit ink outlines, hard offset shadow, heavy headings |
| Mint | soft | `#EDF5F0` / `#17805A` | `#0F1813` / `#5FD3A0` | Fresh green, quiet surfaces |
| Midnight | soft | dark only | `#0F1117` / `#9DB8FF` | Always dark |
| Pixel | pixel | `#EDEBDD` / `#3D5AFE` | `#101226` / `#8FA2FF` | Square corners, notched pixel outlines, Silkscreen headings |
| Sketch | sketch | `#FBFAF5` / `#FFE066` | `#1F2A27` / `#FFE066` | Hand-drawn outlines (deterministic per item), Caveat headings |
| Custom color | soft | generated | generated | The user's hue, contrast-checked |

Tests (`test/app/theme_catalog_test.dart`) require every text pair in every palette to reach 4.5:1, selected pills 3:1 against their surroundings, and Custom palettes to pass at every 15° hue step.

### Contrast policy

Opaque text/background pairings must meet the text-contrast targets in the product specification. Transparent widgets are an explicit exception in capability, not an accessibility claim: arbitrary wallpaper is unknown, so a fixed translucent fill cannot guarantee contrast.

Provide **Clear**, **Soft tint** and **Solid accessible** widget treatments where supported. Offer light/dark text and stronger next-entry emphasis only when the platform can honor them. Respect the operating system's accessibility and rendering settings. When Reduce Transparency or an equivalent accessible treatment is requested, prefer the solid preset instead of preserving decoration.

## Typography

Use the native system font deliberately. In Flutter, inherit the platform theme rather than shipping SF Pro font files. Use tabular figures for schedule times where the platform supports them. Avoid all-caps body copy and very light text weights.

- Main date/page title: `h1`; never a full-screen hero.
- Schedule title: `body-emphasis`, with `h2` reserved for a focused detail view.
- Room, professor and subtitle: body or caption depending on density, not illegibly small text.
- Time column: `time`, aligned consistently and not distinguished by color alone.
- User font scaling takes precedence over the nominal sizes above. At large sizes, wrap, expand or switch to an agenda layout instead of clipping essential content.

Display fonts appear only in headings (page title, greeting, the Next card title, theme names in the picker and themed widget titles). They never appear in body text, schedule details, form fields, buttons or numbers that must be read precisely.

Do not reduce all upcoming-entry text opacity until it becomes unreadable. The next entry should be stronger; upcoming entries must still be legible.

## Layout

- Default page gutters: `md`; use `lg` when screen width permits.
- Group related fields using `sm` or `md`; separate sections with `lg`.
- Timeline rows are content-sized. A row can show time, title, selected details and status, but is not a fixed-height decorative card.
- Use a three-destination app shell: **Today**, **Week**, **Settings**. Keep Add, Import and Share contextual; do not add one tab per action.
- A compact preview uses a bottom sheet. A long import or shared timetable uses a full review page with a persistent confirmation action.
- Mobile actions have at least a 48-logical-unit target, with platform-specific validation. Small SVG artwork may sit inside that larger target; adjacent hit regions must not overlap. Compact density does not shrink targets. Nominal control heights are minimums: grow or stack labels and actions at large text sizes.
- The week grid must have an equivalent chronological agenda view for narrow screens, screen readers and large text.
- Sheets respect safe areas, keyboard insets and dismissal behavior. Keep confirmation and error recovery reachable with the keyboard open. Unsaved edits require a clear discard decision; an unchanged read-only preview closes without a needless prompt. Provide a labelled Close/Cancel action rather than requiring a swipe.

### Widget composition

1. No app-painted outer background in the requested Clear layout, where the native host permits it.
2. The next timed entry receives a brighter holder, stronger type and a more visible outline.
3. Upcoming entries receive quieter individual holders. Space between holders leaves wallpaper visible.
4. No wallpaper screenshot is copied into the widget. The user's wallpaper remains independent.
5. No artificial glowing frame, thick stroke, shimmer or perpetual animation.
6. Date-only entries use an explicit date/all-day label rather than an invented time.
7. A widget tap opens existing schedule details; it never creates a schedule or enables an alert.
8. **Use app theme** (per widget; on for new installs, off after upgrading so existing widgets keep their look): holders take the theme's accent (Next) or category fills, its outline and its heading font, at the computed opacity for the chosen surface. The widget follows the phone's night mode with the theme's light or dark palette (Android 12+ switches immediately; Android 8–11 at the next widget update). Holder opacity uses the more opaque of the two palettes so both stay readable. Hard shadows appear only on solid holders, because a translucent holder would show the shadow through it. The root stays transparent in every theme, so the wallpaper is never replaced.

Widget reading order must expose the actual date/time, Now/Next or review status, title and permitted visible details without depending on holder brightness. In a constrained family, remove optional details or show fewer entries before clipping essential content; the app remains the accessible route to full details. Appearance previews use actual saved data or an honest empty state over a labelled neutral preview backdrop, not invented schedules or a copy of the user's wallpaper. A readable preview does not certify Clear mode over arbitrary wallpaper.

The alpha values in the implementation-specific table are a starting hypothesis for a dark-wallpaper preview, not an implemented result. Test light, dark and busy wallpaper fixtures before choosing release values. On iOS, the native Clear/tinted rendering mode controls the material and can replace the requested background. Do not expose a cross-platform opacity slider that the platform cannot actually honor.

## Elevation & Depth

The default app surface is flat. Prefer background separation and spacing over shadows. Navigation may use a native translucent material if supported; content remains on a readable surface.

Widget **Clear** means no requested blur. **Soft tint** adds a translucent fill, not a promise of live wallpaper blur. A real native material may be used when the operating system provides it, but a Flutter backdrop filter is not assumed to work inside a home-screen widget.

Use a thin outline or a subtle text shadow only when it improves separation. Do not add multiple heavy shadows to imitate expensive glass. The solid accessible treatment is a first-class option, not an error state.

## Shapes

- Controls: `rounded.control`.
- App cards: `rounded.card`, used only for meaningful grouping.
- Bottom sheets: `rounded.sheet`, with native presentation behavior where practical.
- Pills: filters and selected states, not every label.
- Native widget outer shape: obey the host's clipping and corner behavior rather than assuming an arbitrary app radius.
- Widget holder radius: proposed 16 logical units, subject to native sizing and clipping tests. Themed holders: soft 16, pop 14, sketch 18, pixel square with 3-unit notched corners.
- Style families: **soft** uses the theme radius and no outline; **pop** adds a 2-unit ink outline and a hard 3-unit offset shadow; **pixel** uses square, notched outlines; **sketch** draws a slightly irregular hand-drawn outline that is stable for each item, so it never jitters between frames.

## Components

### Timeline row

Time and title are primary. Room, professor and subtitle are optional and hidden when absent. An ongoing entry may say **Now**; the next future timed entry may say **Next**. These labels must derive from actual occurrence times, never a seeded demonstration schedule.

If multiple entries overlap, show the simultaneous entries and an overlap indicator. Never silently pick one and hide the others.

### Schedule editor

Progressively disclose **Details**, **Repeats** and **Reminders and alarms**. The title and date/time status are clear. Optional fields remain genuinely optional. Notification and alarm controls have independent desired settings and visible actual permission/scheduling states.

Use a single reading column, persistent field labels above each control and explicit optional-field labels. Labels stay outside textbox fills and outlines in empty, focused and filled states; placeholders are hints, not labels or stored values. Collapsed groups summarize actual choices and retain warnings. Reveal an invalid group and bring its labelled error into view on submission. Preserve entered values on failure; a transient message alone is not sufficient recovery. Visible manual-entry defaults are editable choices, never evidence for filling an unresolved import.

### Image import review

Keep the source image available. Each proposed entry can be selected, edited or removed. Unreadable or missing values say **Needs review** or remain blank. Do not use a fabricated confidence percentage. An explicit confirmation is required before events, notifications or alarms are created.

Edits and **Use changes** update only the review draft. **Add selected schedules** is the activation boundary, with a count from the current validated selection. Source evidence and unresolved-field warnings remain discoverable without relying on the image alone; do not invent a transcription when OCR is unavailable. Cancellation, pending work and recovery follow SCHEDULER_SPEC.md section 4.9.

### Shared-link preview

Use **Preview**, **Edit before adding** and **Add selected schedules**. A long selection moves into a full-page review. The preview is read-only until the recipient edits their own draft. Never automatically save after opening a link.

Keep the sender snapshot separate from recipient edits. Show one primary action for the current step, with Edit and Cancel as supporting actions. Pending link resolution is not an empty timetable, and an unavailable link has no fabricated preview. Sharing and cloud scanning disclose their network/privacy boundary at the action, not through a new onboarding flow.

### Appearance controls

Start with a small set of tested presets. App and each widget can share appearance settings or be configured independently. Hide or explain unavailable native options. Separate app colors from the system's control of native widget glass/tint.

**Settings → Appearance** shows the eight themes as a grid of small swatches (the theme's canvas, two category cards and its accent, with the theme name in its heading font), each labelled "*Name* theme" for screen readers. A choice applies at once and is saved. Custom color reveals one hue slider; there is no free color picker, so text stays readable.

### Profile

An optional, local-only name (up to 40 characters) and photo personalize the Today greeting. The photo is cropped (round mask; square in Pixel), re-encoded as a 512×512 JPEG without metadata and stored in the app's private folder. The profile is never uploaded, shared or written into the widget snapshot; with no profile, the greeting simply has no name and no avatar. Deleting local data offers **Also remove profile name and photo**.

### SVG assets

Use one curated icon family. Proposed family: Lucide, rendered from bundled SVG assets in Flutter. Preserve its upstream notices. Do not mix unrelated outline and filled sets by default. Native widgets receive equivalent approved native vector assets or build-time conversions, not an assumption that WidgetKit or Glance can run Flutter's SVG renderer.

Allowed core meanings: Today/calendar, week, add, image import, share, filter, room/location, person/professor, repeat, notification, alarm, appearance, edit, remove, confirm and close. Pair unfamiliar actions with text. Decorative SVGs are hidden from accessibility; actionable icon buttons have unique spoken labels.

### Motion and feedback requirements

These are interaction criteria, not measured timings or verified rendering. Use the existing 160 ms control and 220 ms screen motion values for app-controlled transitions; native presentations retain supported platform behavior. Motion explains state, never grants permission or delays a commit. No new gesture, animation library, sound or haptic feature is required.

| Trigger | Rules and feedback | Motion / repetition | Reduced motion and accessibility |
|---|---|---|---|
| Press, focus or semantic activation | Show pressed/focus feedback immediately; activate only on a completed tap or equivalent action, not pointer-down. A cancelled press has no side effect. | State feedback settles within control motion; no decorative bounce or forced delay. | Keep visible focus and pressed state without movement; preserve the full target and spoken action. |
| Expand/collapse Details, Repeats or alerts | Reveal the existing group in place; expose expanded state and preserve values. Do not hide focused invalid input. | Control motion, ease-out without overshoot; repeated toggles retarget from the current presentation. | Immediate layout change or non-spatial fade; reading and focus order still match the form. |
| Open/close details or review | Keep entry/exit paths spatially consistent and restore focus to the initiating control on return. Dismissal still obeys the draft/discard rule. | Screen motion; interrupt/reverse supported transitions without jumping or waiting for completion. | Remove slides, scale and spring motion; use an immediate change or brief fade with the same dismissal controls. |
| Start scan, resolve, save or create link | Name the actual stage and keep context visible. Only verified stages/counts may be shown; use indeterminate progress when completion is unknown. | Animate progress only while work is active; no fake percentage, perpetual shimmer or delayed success reveal. | A static working label and state-change announcement must convey progress without a looping animation. |
| Confirm save/import or receive its result | Guard repeated/conflicting submission for that operation. Show saved/added only after the local commit; expose alert failure separately. | Feedback follows the actual outcome once, not an animation timer; transitions do not unlock duplicate work. | Same textual outcome and enabled/disabled semantics; no dependence on motion, sound or color. |
| Validation or recoverable failure | Show what failed beside the affected field/action, retain edits and expose the specific correction or safe retry. | Immediate, persistent feedback until resolved or dismissed deliberately; no shake or flashing error loop. | Announce the failure once per attempt; on submit, reveal/focus the error summary or first invalid field, not every keystroke. |

All manual, image-review and shared-review actions must remain operable through screen-reader and keyboard/switch activation, not just touch. Expose selection, expansion, busy state and the reason a confirmation is unavailable. State announcements occur on meaningful changes, not every poll or rebuilt frame. Reduced motion changes presentation only, not validation, cancellation or outcome semantics.

### Content and empty states

Only user-entered data, source-supported extracted candidates and approved interface copy belong in the product. No invented names, rooms, professors, schedules, metrics, testimonials or slogans. Test fixtures stay out of release storage.

Approved concise state labels include **No schedules yet**, **No schedules in this filter**, **Nothing else today**, **Needs review**, **Notifications are off**, **Alarm permission needed**, **Shared link expired**, and **Shared link unavailable**. Show only the state that is actually true.

## Do's and Don'ts

**Do**

- Keep the next schedule immediately recognizable without hiding other relevant entries.
- Preserve the user's wallpaper and choice of native appearance.
- Test accessibility, text scaling, clipping and transparent-widget readability on devices.
- Use actual saved/imported values, explicit uncertainty and truthful status labels.
- Keep share, scan and alert actions deliberate and reversible where the platform permits.
- Treat native OS appearance constraints as product requirements, not styling bugs to hack around.

**Don't**

- Replace the wallpaper with a timetable image, or require a wallpaper screenshot.
- Promise identical transparency, full-screen alerts or default-Clock synchronization on both platforms.
- Add a hero, statistics dashboard, motivational copy, heavy gradients or decorative illustrations.
- Indicate that an alarm is scheduled merely because an external Clock intent was sent.
- Add missing dates, room numbers or professors to make an imported card look complete.
- Ship unsupported controls, unlimited styling options or a misleadingly universal glass slider.
- Use a display font for schedule details, form fields or precise numbers.
- Let a theme change copy, layout, flows or what data is shown.
