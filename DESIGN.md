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

**Status:** proposed design system for approval before app implementation. The product name is not a chosen brand. This document contains design instructions, not a claim that the app or native widgets have been built.

The primary surface is **Monitor**: people glance at a timeline to find the current or next schedule. A schedule editor is a secondary **Configure** surface. Composition follows the task: date and filter controls, an ordered timeline, then contextual actions. There is no marketing hero, decorative statistics, motivational slogan, or equal-weight feature-card grid.

The direction is minimal and Apple-inspired without cloning a branded screen. Hierarchy comes from type, spacing, alignment and restrained emphasis. Glass is limited to supported navigation/material treatments and widget holders. Important schedule text is not buried under blur.

Normative product behavior, security rules and platform limits live in [SCHEDULER_SPEC.md](SCHEDULER_SPEC.md). External references are in [SOURCES.md](SOURCES.md).

### Implementation-specific values

The interchange format exports only its supported token maps. The values below are normative prose for Flutter/native implementation; do not assume a generic token export includes them.

| Concern | Proposed value / rule |
|---|---|
| Units | Logical UI units, mapped to Flutter logical pixels and native points/dp |
| Fonts | Platform system fonts; no proprietary Apple font bundled for Android |
| Control motion | 160 ms |
| Screen motion | 220 ms; reduced motion uses immediate changes or a brief non-spatial fade |
| SVG family | Curated local Lucide assets with retained license notices |
| SVG geometry | 24 by 24 view box; 2-unit stroke; round caps/joins; nominal display size 22 |
| Clear widget root | Requested alpha 0, requested blur radius 0 |
| Next holder | Proposed alpha 0.18, subject to native rendering/readability tests |
| Upcoming holder | Proposed alpha 0.06, subject to native rendering/readability tests |
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

Do not reduce all upcoming-entry text opacity until it becomes unreadable. The next entry should be stronger; upcoming entries must still be legible.

## Layout

- Default page gutters: `md`; use `lg` when screen width permits.
- Group related fields using `sm` or `md`; separate sections with `lg`.
- Timeline rows are content-sized. A row can show time, title, selected details and status, but is not a fixed-height decorative card.
- Use a three-destination app shell: **Today**, **Week**, **Settings**. Keep Add, Import and Share contextual; do not add one tab per action.
- A compact preview uses a bottom sheet. A long import or shared timetable uses a full review page with a persistent confirmation action.
- Mobile actions have at least a 48-logical-unit target, with platform-specific validation. Small SVG artwork may sit inside that larger target.
- The week grid must have an equivalent chronological agenda view for narrow screens, screen readers and large text.
- Sheets respect safe areas, keyboard insets and dismissal behavior. Unsaved edits require a clear discard decision.

### Widget composition

1. No app-painted outer background in the requested Clear layout, where the native host permits it.
2. The next timed entry receives a brighter holder, stronger type and a more visible outline.
3. Upcoming entries receive quieter individual holders. Space between holders leaves wallpaper visible.
4. No wallpaper screenshot is copied into the widget. The user's wallpaper remains independent.
5. No artificial glowing frame, thick stroke, shimmer or perpetual animation.
6. Date-only entries use an explicit date/all-day label rather than an invented time.
7. A widget tap opens existing schedule details; it never creates a schedule or enables an alert.

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
- Widget holder radius: proposed 16 logical units, subject to native sizing and clipping tests.

## Components

### Timeline row

Time and title are primary. Room, professor and subtitle are optional and hidden when absent. An ongoing entry may say **Now**; the next future timed entry may say **Next**. These labels must derive from actual occurrence times, never a seeded demonstration schedule.

If multiple entries overlap, show the simultaneous entries and an overlap indicator. Never silently pick one and hide the others.

### Schedule editor

Progressively disclose **Details**, **Repeats** and **Reminders and alarms**. The title and date/time status are clear. Optional fields remain genuinely optional. Notification and alarm controls have independent desired settings and visible actual permission/scheduling states.

### Image import review

Keep the source image available. Each proposed entry can be selected, edited or removed. Unreadable or missing values say **Needs review** or remain blank. Do not use a fabricated confidence percentage. An explicit confirmation is required before events, notifications or alarms are created.

### Shared-link preview

Use **Preview**, **Edit before adding** and **Add selected schedules**. A long selection moves into a full-page review. The preview is read-only until the recipient edits their own draft. Never automatically save after opening a link.

### Appearance controls

Start with a small set of tested presets. App and each widget can share appearance settings or be configured independently. Hide or explain unavailable native options. Separate app colors from the system's control of native widget glass/tint.

### SVG assets

Use one curated icon family. Proposed family: Lucide, rendered from bundled SVG assets in Flutter. Preserve its upstream notices. Do not mix unrelated outline and filled sets by default. Native widgets receive equivalent approved native vector assets or build-time conversions, not an assumption that WidgetKit or Glance can run Flutter's SVG renderer.

Allowed core meanings: Today/calendar, week, add, image import, share, filter, room/location, person/professor, repeat, notification, alarm, appearance, edit, remove, confirm and close. Pair unfamiliar actions with text. Decorative SVGs are hidden from accessibility; actionable icon buttons have unique spoken labels.

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
