# Schediel — PDF-led UI refinement design

**Status:** Proposed for user review; not approval to implement.
**Source:** `C:/Users/Diel/Downloads/problems and fixes.pdf`, pages 1–8. Page 9 was visually checked and is blank.
**Latest direction:** Keep the old bottom navigation, remove the oversized left space in the Week date selector, use the supplied references, and plan before further UI work.
**Baseline inspected:** `91e187a`. The HTML v1 prototype is rejected as an implementation/design baseline; do not copy its navigation or 56px Week-header inset.

## Locked boundaries

- Preserve `FloatingNavBar` in `lib/app/shell.dart`: Today, Week, Settings; the selected destination label; separate Add button; existing placement, silhouettes and route behavior. No top-level replacement navigation.
- Reference priority: latest user correction > PDF annotations > PDF reference pictures > existing Schediel tokens/components > design-skill examples. Never replace the supplied references with a generic dashboard or a brand clone.
- Calendar is primarily an **Operate** surface: select a date and inspect schedules. Editor and settings are **Configure** surfaces: progressive controls and clear confirmation, not decorative dashboards.
- Use Claude Design for reference-led composition, content discipline and visual checking; Popular Web Designs only for supporting spacing/type/control principles. Its Cal.com marketing palette, large whitespace and navigation are NOT the requested design.
- Keep the existing eight theme families and their identities. Preserve Silkscreen/Pixel and Caveat/Sketch fonts. Use the platform Roboto/SF system face for ordinary UI; do not bundle Apple SF fonts on Android.
- No invented schedule content, profile information, statistics or features. Reference examples do not authorize collaboration, accounts, chat, priorities or wallpaper editing.
- Android first. iOS source compatibility is not a successful iOS build. Profile remains optional and local-only; never add it to links/widgets/logs.
- Image/link imports remain editable inactive drafts until explicit confirmation. Do not weaken permissions, validation, deletion confirmation or backend ownership checks for a cleaner screen.

## Reference-to-requirement map

| ID | Source | Required outcome | Owning plan task |
|---|---|---|---|
| R01 | Latest correction; p1–2 existing screenshots | Keep the actual old bottom bar and separate Add; improve press feedback without redesigning it | 1 |
| R02 | Latest correction; p1, p8 date references | Full-width, compact seven-date selector; no reserved left time-gutter spacer in that selector | 2 |
| R03 | p1 | Date targets work, month picker works, previous/next week and return-to-today work | 2 |
| R04 | p1 | All 24 hours are reachable, even with no schedules or no filter matches | 2 |
| R05 | p1, p4 | Readable hour spacing; center Today time ranges against their cards, not against just the first title line | 2 |
| R06 | p1 | Theme canvas extends behind status/navigation areas; system icons remain readable | 1 |
| R07 | p1 | Small original schedule-related empty-state asset; preserve honest empty/filter/error copy and actions | 1 |
| R08 | p1 | Subtle navigation/icon press and selection motion; respect Reduce Motion | 1 |
| R09 | p2, p5 | Better-spaced settings/categories with restrained colored, soft folder-like icon treatments | 4 |
| R10 | p2 | Simplify Privacy and data presentation, not its protections or disclosures | 4 |
| R11 | p2 Instagram reference | Labels sit inside the field above the value; never interrupt the field border | 3, 4 |
| R12 | p3, p7 | Schedule inspection/editing opens from the bottom; rounded, filled modern actions rather than outlined action rows | 3 |
| R13 | p3–4 | Reminder/widget selection becomes grouped and coherent, not scattered chips | 3, 6 |
| R14 | p4 | Same-size expanded widgets show three entries across styles when three fit; intentional compact/short-widget limits remain | 6 |
| R15 | p5–6 | Replace dense appearance grids with a live preview and a compact horizontal style selector | 5 |
| R16 | p6 | Light is the fresh-install default; preserve saved users' Light/Dark/System choice | 5 |
| R17 | p6 | Each family supports editable main/accent and background color, with hue and lightness controls | 5 |
| R18 | p6, p8 | Optional selectable subtle stripes/paper/gradient surface treatments on suitable styles, with a None option | 5 |
| R19 | p6, p8 | Improve ordinary typography without replacing the special fonts in other styles | 1, 5 |
| R20 | p6 | End time enabled for newly created timed schedules; do not silently add ends to existing/imported point events | 3 |
| R21 | p7 | Three stages: title/subtexts → time/category/repeat → notifications/alarms; Back retains the whole draft | 3 |
| R22 | p7 | Animated, clearer time selection with an accessible typed alternative and 12/24-hour support | 3 |
| R23 | p8 | Replace share glyph and verify actual link-sharing behavior; no fake working service | 7 |
| R24 | p8 | Diagnose and reduce measured fresh-launch delay without losing correct startup state | 8 |
| R25 | p8 portrait/calendar references | Original low-detail vector app icon combining a simplified portrait cue and scheduling cue; approval before replacing launcher assets | 9 |

## Proposed layout decisions — subject to plan approval

### Calendar and dates

Use the page-8 compact day/number tile posture, adapted to each theme. Seven equal-width cells span the content width with the normal `Tokens.md` outer inset (16dp), not a blank 44–56dp slot before Sunday/Monday. Do not push the first date right merely to align it with the time rail.

The selector is independent of the time-grid rail. The grid below may retain a narrow, measured rail for readable hours; it must not dictate the selector's left padding. Each event has an unambiguous day/date in semantics; selected-day focus is visible in its grid column. Date selection stays in Week and focuses that day, rather than unexpectedly switching tabs. Today and Week share the selected-date source; changing weeks keeps their state consistent. Tapping the already-active Today destination still returns to today.

The month/date heading opens a functional month picker. Keep previous/next-week controls and accessible equivalents for swipes. Preserve the week/agenda alternative, especially for large text and assistive navigation.

The time grid always spans midnight to next midnight (24 hours, not the existing 08:00–18:00 minimum). Initially scroll near the current time for the current week, or the first real occurrence for another week; never hide the rest of the day. Empty weeks still show dates and the full-day grid with a compact honest empty state, not a replacement blank page. Keep all-day/review entries, overlaps, overnight events and existing time-zone semantics.

### Bottom sheets and input

Preserve the current occurrence-details sheet; make normal create/edit routes use the same bottom-origin presentation. Keep deep-link destinations reachable, with a real base screen behind a cold-opened sheet. A sheet is not permission to lose edit scope or draft data.

Proposed editor stages:
1. **Details:** title, subtitle, room/location, person and notes. Labels remain visible inside the upper field area, with values below them.
2. **Time:** category, timed/all-day, date, start, enabled end, zone, recurrence. Existing exceptional-time review remains available.
3. **Alerts:** notification/alarm toggles, one grouped offset selector per enabled type, existing privacy/permission status, final Save or import confirmation.

Only the final action writes. Back changes stage, never discards. Close/system Back asks before abandoning a dirty draft. Disable unguarded swipe/scrim dismissal in the editor. Save failure retains inputs; double taps cannot duplicate writes. Review mode still returns a draft to the import review flow rather than activating it.

Use an inline progress label and Back/Next controls rather than three new destinations. Proposed time picker: compact hour/minute wheel using Flutter's existing platform controls, clear AM/PM where applicable, Done/Cancel, and a labelled keyboard alternative. Do not implement a custom gesture/time engine or new dependency.

New timed drafts start with end enabled and a proposed one-hour duration. Preserve existing duration/overnight validation; late-night defaults must advance to the next day correctly. Existing edits/imports keep their supplied end or absence of end.

### Appearance and supporting screens

Retain the current token scale: 4/8/16/24/32/48dp, 12dp controls, 18dp cards, 28dp sheets, 48dp standard action targets. Seven equal date cells can be narrower on small phones; keep them non-overlapping and at least 48dp high, and provide accessible date navigation. Keep 160ms control and 220ms screen motion, reduced to zero with accessibility settings. Preserve theme-specific square/ink treatments rather than rounding everything indiscriminately.

Use one live theme preview, a horizontal family selector and a compact Light/Dark/System chooser. Each family remembers its own color/texture edits; switching families does not wipe them. Main/accent and background each expose Hue (0–359) and Lightness/HCT tone (0–100); the derived readable ink/control tokens may be contrast-corrected. Explain that the preview shows the resolved accessible result. Keep category colors distinguishable and preserve the existing widget-theme refresh path.

Proposed texture set: None, Stripes, Paper, Gradient. Keep low-contrast treatments on canvas/secondary surfaces, not behind field values or tiny text. No animated backgrounds, heavy photo textures or automatic wallpaper changes. App texture need not appear in native widgets: widgets consume resolved colors through the existing contract; do not expand the snapshot contract without a separately justified need.

Privacy presents short summaries for On this device, Image scanning and Online sharing; full existing details expand on request. Destructive actions remain separated and explicitly confirmed. Colored icon backplates/folder-like category marks use existing category color plus visible names, not color alone.

### Sharing, launch speed and icon

Sharing diagnosis is a separate verification gate, not a cosmetic promise. Preserve preview → editable draft → explicit import confirmation, sender field selection and revocation. A real deployment needs the user's backend/domain and association setup; without them, verify local tests and the honest unavailable state and mark live end-to-end verification blocked.

Measure fresh startup in profile/release on the same device, not a debug hot launch. Inspect the pre-`runApp` timezone/database/appearance/filter work and lifecycle reconciliation before deciding what to defer. Never replace correct persisted state with defaults just to make the first frame faster. Define a measured target after capturing baseline, rather than inventing an improvement percentage.

The app icon is a distinct approval gate: propose a few simple SVG silhouettes from the supplied portrait cue plus a calendar/check/time cue, readable at small sizes and in Android masks/monochrome form. Do not embed the original photo, detailed facial features, college logo or copied calendar brand. Do not replace launcher assets before a concept is selected. Image generation is optional only if an appropriate tool exists; a clean editable SVG is the required source.

## Approval and delivery boundary

This document and the implementation plan are the only deliverables in the current turn. No changes to Flutter/native code, installed app, mockup, backend, launcher icon or existing product specifications. After approval, implement in small independently checked batches, starting with the preserved shell and corrected calendar. Check each changed screen beside its PDF reference; do not claim visual fidelity from passing unit tests alone.
