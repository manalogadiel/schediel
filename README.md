# Scheduling app specification bundle

**Status:** pre-implementation draft for approval. No mobile app or backend has been implemented by this task.

## Read in this order

Start with [FULL_SPEC.md](FULL_SPEC.md) for the complete standalone Markdown specification, including all appendices and internal navigation.

For modular implementation work:

- [SCHEDULER_SPEC.md](SCHEDULER_SPEC.md) — product scope, requirement traceability, UI/UX, Flutter/frontend architecture, native widgets and alerts, local/server data, API behavior, security, test plan, implementation sequence and open decisions.
- [DESIGN.md](DESIGN.md) — machine-readable design tokens and visual/component rules for the minimal Apple-inspired app and wallpaper-independent native widgets.
- [CONTRACTS.md](CONTRACTS.md) — typed schedule, import, native snapshot and backend request/response contracts.
- [SOURCES.md](SOURCES.md) — primary references and limits of what each source supports.
- [VALIDATION.md](VALIDATION.md) — actual documentation checks and what has not been tested.

## Confirmed direction

Flutter for Android and iOS; repeating schedules; room/professor/subtitle details; next/upcoming transparent widget without replacing wallpaper; minimal customizable app/widget design and consistent SVG icons; optional reminders/alarms with honest full-screen/Clock limitations; image extraction with editable confirmation; categories and filtered/all-schedule sharing by preview-first editable links.

## Decisions are not silently invented

Architecture choices, backend provider, anonymous identity, independent snapshot imports, defaults, limits and retention are labelled **proposed**. Audience/minor eligibility, AI provider/privacy, device baseline, native capability compromises, recovery/backups and Mac/Xcode access remain explicit decisions.

## Important constraints

- A clear widget does not mean identical transparent rendering on both OSes.
- App-owned alarms are not two-way synchronization with every default Clock app.
- A normal reminder cannot be promised to force a custom full-screen takeover everywhere.
- Source images and shared links do not activate schedules or alerts before confirmation.
- No fabricated schedule names, rooms, professors, statistics or confidence scores belong in release UI.
- Schedules do not become wallpaper images; users keep their chosen wallpaper.

Start implementation only after reviewing and approving the applicable decisions and future proof tasks in the main specification.
