# Scheduling app: pre-implementation specification
**Standalone edition:** This file includes the complete product/frontend/backend specification plus the design tokens, typed contracts, primary sources and documentation-validation record. Its document links point to appendices inside this file. The modular originals remain in the downloadable bundle.

**Document version:** 0.1 — for product approval, not an implementation claim  
**Prepared:** October 18, 2026, using the current conversation and primary documentation  
**Platforms requested:** Android and iOS, built with Flutter  
**Implementation status:** documentation only; no Flutter app, backend deployment, device alarm, widget, or AI extraction has been implemented or certified by this document.

## Contents

1. [Document rules and decision status](#1-document-rules-and-decision-status)
2. [Confirmed requirements and traceability](#2-confirmed-requirements-and-traceability)
3. [Proposed scope and defaults](#3-proposed-scope-and-defaults)
4. [Information architecture and UI/UX](#4-information-architecture-and-uiux)
5. [Visual system and widget design](#5-visual-system-and-widget-design)
6. [Schedule and recurrence behavior](#6-schedule-and-recurrence-behavior)
7. [Reminders, alarms and full-screen behavior](#7-reminders-alarms-and-full-screen-behavior)
8. [Image import and review](#8-image-import-and-review)
9. [Categories, sharing and recipient import](#9-categories-sharing-and-recipient-import)
10. [Local data model](#10-local-data-model)
11. [Flutter frontend architecture](#11-flutter-frontend-architecture)
12. [Native integration contracts](#12-native-integration-contracts)
13. [Backend architecture and database](#13-backend-architecture-and-database)
14. [Backend API contracts](#14-backend-api-contracts)
15. [Security, privacy and AI governance](#15-security-privacy-and-ai-governance)
16. [Limits, reliability and operations](#16-limits-reliability-and-operations)
17. [Testing and acceptance criteria](#17-testing-and-acceptance-criteria)
18. [Implementation sequence](#18-implementation-sequence)
19. [Open decisions and risk register](#19-open-decisions-and-risk-register)
20. [Approval and implementation handoff](#20-approval-and-implementation-handoff)
21. [Sources](#21-sources)


### Standalone appendices

- [Appendix A: Visual system and design tokens](#appendix-a-visual-system-and-design-tokens)
- [Appendix B: Typed integration contracts](#appendix-b-typed-integration-contracts)
- [Appendix C: Primary-source register](#appendix-c-primary-source-register)
- [Appendix D: Documentation validation](#appendix-d-documentation-validation)

## 1. Document rules and decision status

### 1.1 What this document is

This is a buildable product and engineering brief. It records the requested behavior, recommended architecture, UI states, data contracts, platform compromises, and tests that must exist before release. It is not a visual prototype, production migration, API response dump, delivery estimate, or claim of successful device testing.

The app's name, logo, final accent color, supported device baseline, deployment region, AI provider, and commercial model have not been selected by the user. **Scheduling app** is a descriptive document title, not an invented brand.

### 1.2 Decision labels

- **Confirmed requirement:** directly requested in the conversation.
- **Proposed default:** recommended here, awaiting approval; do not present it as a user decision.
- **Platform constraint:** behavior documented by the OS/framework, cited below; still requires device verification in this app.
- **Release gate:** a question or test that must be resolved before the affected feature ships.
- **Future scope:** deliberately excluded from the first version unless the user changes priorities.

Normative words such as **must** define the proposed implementation contract, not something already built.

### 1.3 Non-negotiable boundaries

1. Users keep their own wallpaper. The product must not replace it with a timetable image or require a wallpaper screenshot to imitate transparency.
2. An image, OCR result, AI response, or incoming shared link must not create active schedules, reminders or alarms before explicit confirmation.
3. Missing information stays missing or is visibly marked for review. Do not invent dates, years, times, rooms, professors or confidence percentages.
4. App and widget styling must remain minimal and readable. No fake statistics, sample schedules in release storage, decorative slogans, or unsupported controls.
5. Do not promise cross-platform default-Clock synchronization, forced full-screen alerts, continuous background execution, or identical glass rendering.
6. Local schedules remain usable without a backend connection. Online actions must be separately identifiable.

## 2. Confirmed requirements and traceability

The requested capabilities are listed below. Platform-qualified requirements preserve the user's intent while making the unavoidable compromises explicit.

| ID | Requirement | Main specification | Acceptance coverage |
|---|---|---|---|
| R01 | Flutter app for Android and iOS | 3, 11, 12 | AT01, AT12, AT42 |
| R02 | Create schedules with title, subtitle, room/location, professor and important details | 4, 6, 10 | AT01, AT02 |
| R03 | Support repeating schedules rather than entering every occurrence manually | 6 | AT03, AT05 |
| R04 | Edit or cancel a single recurring occurrence without destroying the whole routine | 6 | AT04, AT17 |
| R05 | Provide an understandable chronological schedule and weekly view | 4, 6 | AT07, AT39 |
| R06 | Categorize and filter schedules, including School and Work | 4, 9 | AT08 |
| R07 | Home-screen widget shows the next and upcoming schedules | 5, 12 | AT09, AT47, AT48 |
| R08 | Clear/slightly transparent holders, no unnecessary outer backdrop, next schedule brighter | 5, 12 | AT10, AT11 |
| R09 | Minimal, modern, Apple-inspired visual direction | 4, 5, DESIGN.md | AT12, AT39 |
| R10 | Customize app and widget appearances | 5, 12 | AT09, AT11, AT12 |
| R11 | Use good, consistent SVG iconography | 5, DESIGN.md | AT12, AT39 |
| R12 | Optional reminders with a chosen number of minutes before the schedule | 7 | AT13, AT17 |
| R13 | Optional ringing alarms, with default-device Clock integration where supported | 7, 12 | AT14, AT15 |
| R14 | Optional prominent/full-screen presentation and on-screen schedule information, subject to OS limits | 7, 12 | AT16 |
| R15 | Extract scheduling information from images such as posters, publication materials and school timetables | 8 | AT19, AT21, AT35 |
| R16 | Review, select and edit extracted entries before confirmation | 8 | AT23, AT24, AT25 |
| R17 | Treat unclear or missing extraction fields as unresolved, not invented facts | 8, 15 | AT02, AT21, AT22, AT23 |
| R18 | Share the filtered selection or the whole schedule | 9, 14 | AT27, AT28 |
| R19 | Share using a convenient link that others can open | 9, 12, 14 | AT29, AT31 |
| R20 | On opening a shared link, show a preview and allow editing before adding | 9 | AT24, AT25, AT30 |
| R21 | Never silently import on link opening or image analysis | 8, 9 | AT24, AT25, AT29 |
| R22 | Keep wallpaper choice independent of schedules | 5, 12 | AT10 |
| R23 | No fabricated UI content or misleading permission/scheduling status | 4, 7, DESIGN.md | AT02, AT13, AT15, AT39 |
| R24 | Finish a UI/UX, frontend and backend Markdown specification before implementation | Entire document | Documentation validation and user approval |

**Known requirement compromises requiring approval:** R08 is limited by native widget material/tint behavior, especially on iOS. R13 cannot honestly mean the same two-way Clock integration on both platforms. R14 cannot mean an unconditional custom full-screen takeover. These are product decisions to accept or revise, not issues to conceal during implementation.

## 3. Proposed scope and defaults

### 3.1 Proposed first-version scope

- Local-first schedules and categories; core use does not require signup.
- Timed and date-only entries, one-time events, daily repeats and weekly repeats on selected weekdays.
- Start date, optional end date, single-occurrence edits/cancellations and overlap warnings.
- Today timeline, accessible Week/agenda view, details and schedule editor.
- Native compact and expanded home-screen widgets with per-widget filters and supported appearance options.
- Optional notification reminders, capability-gated app-owned alarms, and an optional Android Clock hand-off.
- Image picker/camera import, on-device OCR, opt-in cloud-assisted interpretation, source-backed editable review.
- Snapshot share links for current filters, all schedules or an edited selection.
- Browser preview plus app import, with explicit confirmation and independent editable copies.
- Privacy, permission and scheduling status surfaces; no hidden upload or automatic imported alarms.

### 3.2 Proposed technical defaults

| Decision | Recommendation | Status |
|---|---|---|
| Mobile UI | Flutter; feature-first modules and a thin domain layer | Proposed |
| State/dependency management | Riverpod providers/notifiers | Proposed |
| Routing | go_router, with cold/warm deep-link handling | Proposed |
| Local persistence | Drift over SQLite, with tested schema migrations | Proposed |
| Widget bridge | home_widget plus native SwiftUI/WidgetKit and Kotlin/Glance or RemoteViews | Proposed; native proof required |
| Reminder notifications | A maintained Flutter local-notification adapter, isolated behind a service | Proposed; dependency audit required |
| iOS alarms | AlarmKit on supported OS versions, native bridge | Platform-qualified proposal |
| Android ringing alarms | Native alarm adapter, explicit permissions and policy-compliant presentation | Release gate |
| External Clock | Separate Android hand-off action, never claimed as two-way sync | Platform-qualified proposal |
| Image analysis | Local preprocessing/OCR; optional vision API through a backend | Proposed |
| Backend | Supabase Postgres/Auth/private Storage/Edge Functions as a small managed stack | Proposed; provider and region not approved |
| Public link preview | Small semantic HTML/TypeScript page, independent of the Flutter app bundle | Proposed |
| Sharing semantics | Immutable snapshots; recipient imports independent copies | Proposed |
| Account model | No required account for local schedules; anonymous backend identity for online creation | Proposed; recovery trade-off must be approved |
| Appearance | System app theme, restrained blue default accent; requested Clear widget where supported | Proposed |
| Alerts | Both notification and alarm off until explicitly enabled or a user-chosen default is applied | Proposed |

Flutter's architecture guidance separates UI, repositories and services; that separation is the basis for this design.[1]

Riverpod, Drift and go_router are implementation candidates, not prerequisites for the product behavior.[2][3][4]

Do not pin guessed package versions in the spec. At scaffold time, verify compatible stable releases, SDK requirements, licenses and native setup, then commit exact dependency resolutions and migration policy. A package's existence is not proof that it satisfies this app's platform constraints.

### 3.3 Deliberately outside the first version

- Live collaborative/shared-calendar synchronization.
- Multi-device schedule synchronization, recovery accounts and cross-device backups, unless separately approved.
- A full generative vision model bundled as a required mobile download.
- Guaranteed recognition of every codec, script, poster or timetable layout.
- Arbitrary monthly/yearly recurrence expressions or full iCalendar import/export.
- Automatically accepting image or link suggestions.
- Wallpaper generation, wallpaper access, screenshot-based transparency and decorative wallpaper features.
- Arbitrary uploaded SVGs, downloadable themes executing code, or unrestricted custom fonts.
- Guaranteed custom full-screen alarms on every OS/version/launcher.

## 4. Information architecture and UI/UX

### 4.1 Surface and navigation

The main surface is **Monitor**: glance at a timeline to understand what is happening or next. Editing and appearance are **Configure** surfaces. Do not turn this into a marketing dashboard.

Three destinations:

1. **Today** — date navigation, current filter, chronological schedule and contextual Add/Import/Share.
2. **Week** — weekly timetable with an equivalent chronological agenda presentation.
3. **Settings** — appearance, widget setup, category management, alert status, privacy and shared-link management.

**Add** is an action, not a fourth destination. Its menu contains **Create schedule**, **Import image**, and **Open shared link**. A received verified deep link opens its preview directly, without routing through a new-user marketing screen.

### 4.2 First launch

- Open an honest empty Today view with **No schedules yet** and a clear Add action.
- Do not seed fake classes, professors, statistics or motivational text.
- Explain local storage and online features concisely when relevant, not as a forced multi-page onboarding flow.
- Do not request camera, photos, notification, exact-alarm or full-screen permissions together on launch.
- Ask for each permission only when the user starts the corresponding action.
- Explain that local-only storage is not cross-device backup. Do not imply data recovery exists if it does not.

### 4.3 Today screen

**Header:** selected date, date navigation, category filter, contextual Share and Add actions.

**Content order:**

1. Date-only entries for the selected day, explicitly labelled rather than assigned invented times.
2. Ongoing timed entries, if any.
3. The next timed entry and the remaining chronological entries.
4. Past entries, visually quieter and optionally collapsed without removing access.

If multiple schedules overlap, show them all. The focus treatment does not hide simultaneous events. For a date other than today, use actual times rather than implying **Now**.

The row hierarchy is time, title, then selected optional details. A missing room or professor removes that line; it does not become an invented value or a misleading dash.

**States:** no entries, no entries in filter, loading local data, local-data error with recovery action, overlapping entries, permission problem, and unscheduled alert warning. Show only the state that actually applies.

### 4.4 Week screen

- Day headers, clear date range and previous/next navigation.
- Time-based grid for timed events; date-only entries in their own strip.
- Multiple events occupying the same time remain individually accessible.
- An agenda alternative is always available for narrow screens, large text and screen readers.
- No fabricated free-time totals, productivity scores or attendance metrics.
- Filters are shared with the app's schedule view unless the user explicitly changes them. Widget filters are independent per widget.

### 4.5 Schedule details and editor

A tap opens a compact detail sheet. A dedicated editor provides enough room for changes.

Editor groups:

- **Basics:** title, category, timed/date-only choice, date and time, optional end.
- **Repeats:** none/daily/weekly, selected weekdays, start and optional end date.
- **Details:** room/location, professor/person, subtitle, longer notes.
- **Reminders and alarms:** independent notification and alarm controls, offsets, current permission state, privacy preference.

Title and usable date information are required to save an active schedule. A timed entry needs a resolved start time. An end time is optional; choosing **No end time** is different from guessing a duration. A date-only entry does not require an invented clock time.

For a recurring entry, editing asks **This occurrence** or **Entire series**. The UI must explain the scope before applying changes. Changing a series rule that invalidates existing exceptions requires an explicit reconciliation choice; never silently discard them. **This and future occurrences** is future scope unless deliberately added.

Save errors preserve entered values. Dismissing unsaved edits requires a discard decision. Destructive actions identify whether they affect one occurrence, the series, or only an external share link.

### 4.6 Import review screen

Use a bottom sheet for the first compact preview and a full review page for long timetables. Keep a visible confirmation action and selection count derived from actual parsed candidates.

- Display the source image or sender snapshot reference.
- Select, deselect, edit or remove entries.
- Show unclear fields as **Needs review**.
- Show duplicate and overlap warnings without silently merging or deleting entries.
- Let recipients map categories and choose their own alert settings.
- Do not save when the source is merely opened, analyzed or dismissed.

### 4.7 Appearance and widget settings

App settings: system/light/dark, tested accent presets, comfortable/compact density, and optional category colors.

Each widget: filter, compact/expanded layout, visible details, supported surface preset, text appearance where honored, and next-entry emphasis. **Match app** is an option, not forced coupling.

Controls are capability-driven. An unavailable native feature is either absent or explained, not presented as a functional slider.

### 4.8 Approved content rules

The UI may contain only actual user data, reviewable source-supported candidates and approved interface labels. Development fixtures are explicitly labelled and must not populate release storage.

Examples of genuine state copy: **No schedules yet**, **No schedules in this filter**, **Nothing else today**, **Needs review**, **Notifications are off**, **Alarm permission needed**, **Unable to scan this image**, **Shared link expired**, **Shared link unavailable**. Do not display a state merely to fill space.

## 5. Visual system and widget design

The complete machine-readable token spec and component rules are in [DESIGN.md](#appendix-a-visual-system-and-design-tokens). Exact typed payloads, native snapshot fields and request/response invariants are in [CONTRACTS.md](#appendix-b-typed-integration-contracts).

### 5.1 Direction

Minimal, modern and Apple-inspired: native system typography, quiet neutral surfaces, one restrained accent, clear spacing, consistent vectors and limited motion. No exact branded-screen clone, oversized hero, feature-tile grid, decorative gradient, repeated icon toppers, fake statistics or generic filler.

Use one curated SVG family. Proposed: Lucide local assets, rendered in Flutter through flutter_svg. Retain upstream notices and provide semantic labels for actions.[6][7] Native widgets use equivalent approved native vector assets or build-time conversions; do not assume Flutter's SVG renderer runs in WidgetKit or Glance.

### 5.2 Transparent widget contract

Requested composition:

- No app-painted outer panel in **Clear**, where supported.
- Wallpaper is visible directly through the available transparent surface and between holders.
- No blur by default: preserving sharp wallpaper is different from frosted glass.
- The next timed schedule is brighter through its holder, outline, type weight and spacing.
- Upcoming schedules are quieter, not illegible.
- Optional room, professor and subtitle lines appear only when available and enabled.
- No timetable baked into an image and no wallpaper screenshot imitation.

**Native constraint:** iOS Clear/tinted widget rendering can replace the app's widget background and recolor content. The design must adapt to system rendering rather than promise arbitrary background removal or exact app colors.[10] Android supports transparent widget backgrounds, but host clipping and background detection need real launcher tests.[11]

**Appearance presets:**

- **Clear:** requested transparent root, no requested blur, subtle individual holders.
- **Soft tint:** stronger translucent holders, without claiming universal live backdrop blur.
- **Solid accessible:** opaque high-contrast holders or host-supported surface.

Provide only options the host can honor. System accessibility/material settings can override visual preferences.

### 5.3 Readability and accessibility

- Opaque ordinary text pairings target at least 4.5:1; large text targets at least 3:1. Non-text essential control boundaries require an appropriate accessible treatment.[20]
- Transparent content over arbitrary wallpaper cannot carry a universal contrast guarantee. Offer light/dark text, stronger holders and a solid accessible option without reading or copying wallpaper.
- Respect large text, reduced motion and reduced transparency where available.
- Use generous platform-appropriate hit targets, clear focus states and spoken labels.
- Preserve meaning without relying only on color, translucency or animation.
- At large type sizes, hide optional widget details before essential title/time; if necessary show fewer entries and open the app for details.

## 6. Schedule and recurrence behavior

### 6.1 Entry types

1. **Timed:** resolved date, local start time and IANA time zone; optional end.
2. **Date-only:** a known date or date range, no inferred time. Label as a date/all-day item. A reminder requires a separately chosen clock time and zone.

These types support important dates found in posters without fabricating a time. A timed point event with no end is not treated as ongoing for an invented duration.

### 6.2 Recurrence subset

Proposed first version:

- None.
- Daily.
- Weekly on one or more selected weekdays.
- Start date and optional inclusive final local date.
- Optional single-occurrence cancellation or override.

Serialize a structured, versioned recurrence object. Do not accept arbitrary user-supplied recurrence expressions and then claim full standards support. Expansion always receives a bounded date window and output cap; no code enumerates an infinite series.

A week has an explicit locale presentation preference, but weekday identities remain stable across devices. Weekly occurrences start no earlier than the series start date. Date-only repeats use dates, not fabricated midnight UTC instants.

### 6.3 Time zone and daylight-saving rules

- Timed series preserve a wall-clock schedule in their source IANA time zone, not a fixed UTC offset.
- Actual occurrence instants are derived using a pinned, updateable time-zone database.
- Display a time-zone indicator when an imported or shared schedule differs from the device zone.
- Never silently reinterpret a shared class as the recipient's device-local time.
- For a nonexistent or ambiguous local time, the proposed safe policy is **Needs time review** for that occurrence until explicitly resolved. Do not silently shift a class or schedule duplicate alarms.
- An unresolved occurrence is visibly unscheduled; other valid occurrences remain usable.
- Time-zone changes, clock changes and relevant time-zone-data updates trigger reconciliation, subject to OS execution limits.

The exact recurrence library and DST resolution UX are release gates. This document does not assert that a chosen package already implements these policies.

### 6.4 Identity and exceptions

Each series has an app-generated UUID. Each occurrence has a stable logical key based on its series and original recurrence date/time identity, not its edited display time.

A cancellation or override points to that original key. Moving one class must not create a second active occurrence or orphan its old reminder. Whole-series edits must reconcile exceptions and invalidate derived caches explicitly.

### 6.5 Ordering and focus

- Ongoing timed occurrences satisfy start <= now < end when an actual end exists.
- The next timed occurrence is the earliest future start in the active filter; stable tie-breaking uses start, end if available, normalized title and ID.
- Multiple ongoing entries remain visible.
- Point events move to past after their start; no invented ongoing state.
- Date-only entries are shown separately and do not obscure the next timed item.
- If today is finished, the widget may show the next available day with an explicit date label.
- Cancellation exceptions do not appear as active upcoming entries.

### 6.6 Validation

- Trim accidental leading/trailing whitespace without rewriting the user's identifiers or content.
- Require a nonempty title and resolved date; require start time for timed entries.
- End must be later than start after zone resolution when present. Overnight events have an explicit end-day relationship.
- A recurring overnight event may cross into the following day; broad multi-day recurrence is not assumed supported.
- Invalid ranges, unknown zones, empty weekly-day sets and unsupported recurrence variants are rejected with editable errors.
- Overlap is a warning, not an automatic rejection.
- Past events can be saved, but enabling an alert whose trigger is already past requires a clear choice; do not ring immediately without consent.

## 7. Reminders, alarms and full-screen behavior

### 7.1 Separate concepts

| Concept | Desired behavior | Not a promise of |
|---|---|---|
| Reminder notification | Optional notification at a user-chosen offset | Guaranteed sound, exact delivery, or overriding Focus |
| App-owned alarm | Optional ringing/system alarm where permitted | Universal support on every version |
| Add to Clock | Explicit Android hand-off to a compatible Clock app | Two-way synchronization or arbitrary future-date support |
| Full-screen presentation | Prominent alarm presentation where permitted; in-app full-page reminder when app is open | Forced custom takeover over every app or lock screen |

Notification and alarm choices are independent. Each has its own offset. Zero means the schedule start; a positive value means minutes before. Date-only entries need an explicit reminder time rather than an invented midnight.

Snoozing does not move the actual schedule. Stopping an alarm does not delete or complete a schedule. Imported entries do not inherit active sender alarms.

### 7.2 Android

Android's Clock intent supports a time, message and repeating weekdays.[12] Treat it as a hand-off:

- Use a concise schedule label and supported extras.
- Do not claim that an arbitrary dated event, semester boundary or exception can be represented solely by a time/weekday Clock alarm.
- Do not claim successful alarm creation merely because the intent was launched.
- Record **Sent to Clock / external status unverified**, not **Alarm scheduled**, unless a verifiable platform response exists.
- A later schedule edit must clearly explain the external alarm may need separate updating.

App-owned alarms require a native feasibility pass for exact scheduling, permissions, background execution, sound playback, reboot reconciliation and full-screen behavior. Do not use overlays or a foreground-service workaround to evade OS restrictions.

Native repeating Android alarms are inexact. Where exact user-intentioned delivery is required and authorized, use re-armed one-shot requests with stable occurrence IDs, not a repeating alarm incorrectly advertised as exact. Rebuild authorized requests after supported reboot/time-zone events.[26]

Check exact-alarm access before scheduling and after relevant permission changes. Do not assume newly installed apps receive it automatically or declare a restricted permission solely to avoid user consent; select the permitted calendar/alarm use case and store policy at implementation freeze.[33]

For eligible, permitted full-screen intents, Android distinguishes locked and unlocked presentation; an unlocked device may receive an expanded notification rather than a screen takeover.[14] Google Play's declaration and permission rules must be met before enabling this feature in release builds.[15]

### 7.3 iOS

On iOS 26 and later, evaluate AlarmKit for app-owned alarms. It has user authorization and system-controlled presentation, with a custom alarm title and supported actions.[13]

- Do not describe AlarmKit alarms as entries synchronized into Apple Clock.
- Do not promise an arbitrary custom full-screen app page will launch over other apps or the lock screen.
- Full descriptions remain available in the app; system alarm surfaces may show only compact supported information.
- Older supported iOS versions retain notification reminders and a truthful explanation that the alarm capability is unavailable.
- Do not impersonate calls, misuse audio/background modes or depend on notifications to force the app into the foreground.

### 7.4 What is shown

Where the app controls a permitted alarm/detail screen: title, schedule time, available room/professor/subtitle and platform-appropriate actions. Where the OS or Clock app controls presentation: supply a concise supported label, with full details in the app.

Lock-screen disclosure is separately configurable. A user request to show details does not override OS privacy protection. Default privacy treatment is a proposed product decision, not a platform guarantee.

### 7.5 Desired state versus actual state

Persist the user's desired rule separately from scheduling status:

`off`, `needs_permission`, `pending_schedule`, `scheduled`, `blocked`, `failed`, `unscheduled_capacity`, `external_unverified`, `cancelled`.

Do not label an alert **scheduled** until the native API accepts the request. Acceptance still does not guarantee delivery under every device condition. Reconcile on app resume, event edits, permission changes and supported system events.

### 7.6 Atomic changes and rolling scheduling

1. Commit schedule/exception changes and an alert-reconciliation outbox entry in one local transaction.
2. Derive desired requests for a bounded horizon.
3. Cancel obsolete native request IDs and schedule current ones.
4. Persist results and display failures or permission requirements.
5. Retry idempotently on supported opportunities.

Do not schedule an infinite number of pending requests. Respect the verified adapter/OS capacity, prioritize nearest occurrences, and expose when future requests need replenishment. The app must not imply that unattended background execution will always refresh a rolling horizon. Capacity and terminated-app behavior require a real-device design decision before release.

The current local-notification maintainer documentation describes a 64-pending-request iOS notification limit; do not treat that as an AlarmKit capacity limit. Recheck the pinned adapter and OS behavior before release.[28]

Use repeating notification triggers only when they faithfully represent the entire rule. A trigger without a term-end/exception mechanism must not continue indefinitely past a semester or ignore a cancelled class merely to save pending slots. For bounded/exception-bearing rules, use a tested occurrence strategy and expose actual scheduled coverage when replenishment is required.

## 8. Image import and review

### 8.1 Input scope

Support broad **content types**: posters, publication materials, photographs, screenshots and school timetable images. This is not a claim to decode every file format or read every image accurately.

Proposed first-version input support: JPEG and PNG; WebP and HEIC/HEIF only after native decode/conversion is verified on supported devices. Animated formats, arbitrary SVGs and PDFs are not silently treated as supported images. Give a precise error or a separately approved conversion path.

Use a system photo picker where possible. Camera capture asks for permission only when invoked. Allow crop/rotation and show the exact region about to be scanned.

### 8.2 Recommended processing split

- **On device:** decoding, orientation, cropping, safe downscaling, metadata removal, OCR and simple candidate parsing.
- **Optional backend:** a vision API interprets difficult layout/relationships using the cropped image and optional OCR evidence.
- **On device again:** review, validation, category mapping and explicit import.

ML Kit provides on-device/offline processing and text structure such as blocks and lines; those are useful evidence, not a complete schedule interpreter.[8][9] A full bundled generative vision model is not a first-version dependency.

There must be no silent cloud fallback. **Scan on device** and **Use AI scan** are distinct, understandable actions. Cloud processing requires informed approval for the actual image region and provider/deployment arrangement.

### 8.3 Candidate contract

Each candidate carries:

- Candidate ID and source/image revision.
- Possible title, date/date range, time, zone, recurrence, room, professor, subtitle and notes.
- Field-level origin: directly observed, user-supplied, inferred suggestion or unresolved.
- Source evidence where available: OCR text span and validated image region.
- Warnings: missing year, ambiguous date order, missing AM/PM, uncertain table association, missing term dates, conflict, duplicate or unreadable field.

Unknown fields are null/unresolved. Never add a default professor, default room, guessed year or standard duration to make the entry look complete. Numerical confidence from a model is not a calibrated certainty score and must not be presented as one.

Strict schema validation checks format, allowed keys, ranges and payload limits; it does not prove the image was interpreted correctly. An internal consistency check and human review remain mandatory.

### 8.4 Important-date behavior

- A date-only poster may become a date-only candidate.
- A timetable showing weekdays but no semester dates requires user-supplied start/end context.
- A printed date without a year remains unresolved until the user chooses a year.
- An ambiguous date order requires an explicit choice, not a locale-based guess presented as fact.
- A row/column association that cannot be justified is marked for review.
- An unsupported or unreadable layout produces a partial result or actionable failure, not fabricated completeness.

### 8.5 Review and confirmation

1. Show candidates and their source.
2. User selects, edits or removes them.
3. Resolve required ambiguous values for selected entries.
4. Map categories and choose personal alerts; imported alerts start off by default unless explicitly chosen.
5. Show the actual selected count and any remaining warnings.
6. **Add selected schedules** commits validated entries together locally.
7. Only after commit does the alert outbox schedule authorized requests and the widget snapshot refresh.

Closing review or cancelling a scan creates no schedules, reminders or alarms. A native scheduling failure after a successful import leaves the schedules saved and visibly marks the affected alerts; do not pretend the entire import failed and invite duplicate retries.

### 8.6 Cloud failure states

Offline, upload failure, unsupported image, budget/quota exhausted, provider unavailable, timeout, invalid structured output, no schedules found, partial recognition and cancelled task all have distinct states. Preserve the source and user edits where safe. Retry must not create duplicate billed jobs through an accidental repeated request.

## 9. Categories, sharing and recipient import

### 9.1 Category behavior

Proposed built-ins: **School**, **Work**, **Personal**; custom names allowed. One category per schedule in the first version, with **Uncategorized** as a truthful fallback.

Multi-select category filters use OR semantics. **All** clears category restrictions and includes Uncategorized. Renaming a category updates its labels, not the schedules' identities. Deleting a category offers a destination or Uncategorized rather than deleting its schedules.

Filters control visibility, not notification/alarm activation. Sharing the current filter uses the selected categories, not secretly just the rows currently visible on today's screen; an optional date-range scope must be explicit.

### 9.2 Sender flow

**Filter → Share → Choose scope → Review included data → Create link**.

Scopes:

- Current filtered schedules.
- All saved schedules.
- An edited selection from either scope.

“All” means all selected saved series/one-time entries, including ended entries unless the sender explicitly narrows the selection. It does not mean infinite expanded occurrences, every local setting, source images or private alert rules. Show clearly whether ended/past entries are included.

A recurring snapshot contains bounded structured series rules and exceptions, not an unbounded list of future dates. If a configured payload limit is exceeded, explain how to reduce/split the share; never silently omit entries and still say **All**.

Before upload, show exact entries and optional shared fields. Room, professor, subtitle and notes can be excluded. Source images, notification IDs, device IDs and sender alarm preferences are excluded.

### 9.3 Link and browser behavior

Use an owned HTTPS domain with verified Android App Links and Apple Universal Links. These require domain association, not just a route inside Flutter.[18][19]

- App installed: cold or warm link handling opens a **preview**, never an automatic import.
- App unavailable: browser shows a read-only preview and an honest way to open/install the app.
- Do not promise automatic context restoration after app-store installation. Reopening the original link must work.
- Link scanners, browser prefetch and GET requests must not create schedules, identities, alarms or paid AI work.
- Social link previews use generic product metadata by default, not private schedule titles or rooms.
- Expired/revoked/invalid links have an understandable state with no fabricated preview.

### 9.4 Recipient flow

**Open link → Preview → Select → Edit before adding → Map category / choose alerts → Confirm**.

A short selection fits a modal/bottom sheet. A large timetable opens the full review screen with the same explicit confirmation boundary.

Proposed import semantics:

- Each recipient receives independent local copies.
- Sender changes do not silently change imported schedules.
- Recipient edits do not modify the sender's snapshot or another person's data.
- Source zone and recurrence are preserved and visibly explained.
- Recipient categories are mapped by choice, not by trusting sender category IDs.
- Notification/alarm settings remain the recipient's choice.
- Duplicate candidates and existing local entries are flagged; default is to skip known identical imports, with an explicit keep-copy option.

Track both exact source identity and a normalized content fingerprint. Identity detects a repeated import of the same snapshot item; fingerprints are warnings, not grounds to silently merge unrelated entries.

### 9.5 Snapshot ownership and revocation

A share link is a bearer secret: anyone who receives or forwards it may view it unless an additional access-control feature is introduced. Do not call an unrestricted link private.

Recommended first-version controls: expiry selection, revoke link, list the sender's active links and create a replacement snapshot. Revocation prevents subsequent authorization through that link; it cannot erase already downloaded previews or imported copies. A response authorized before revocation commits may still finish; do not promise remote recall.

Anonymous online identities reduce signup friction but complicate recovery. Losing the identity/session or reinstalling may lose management of old links unless an approved recovery/account option exists. Explain this before link creation; do not promise revocation after identity loss.

## 10. Local data model

All definitions below are a planned schema, not executed migrations. Use foreign keys, explicit constraints and versioned migrations. SQLite is the source of truth for local schedules; native caches and pending alerts are derived state.

### 10.1 Main records

| Record | Required fields and responsibility |
|---|---|
| `categories` | `id`, name, optional tested color key, built-in/custom marker, sort order, timestamps |
| `schedule_series` | `id`, revision, title, category ID, time kind, start date, optional start time, optional end relationship, IANA zone for timed entries, recurrence kind/weekdays/final date, optional location/professor/subtitle/notes, timestamps |
| `occurrence_exceptions` | `id`, series ID, original occurrence key, cancelled/override type, explicit changed fields, revision, timestamps; unique on series + original occurrence key |
| `alert_rules` | `id`, series or exception scope, notification/alarm kind, enabled flag, offset minutes or date-only clock-time rule, privacy preference, optional supported snooze preference |
| `scheduled_alerts` | Rule/occurrence identity, native request ID, platform, request revision, intended trigger instant, actual status, error code, last reconciliation |
| `reconciliation_outbox` | Unique operation key, reason, source revision, pending/running/retry status, retry metadata; no user-content logs |
| `widget_configurations` | Native widget instance ID, selected category IDs, layout, detail visibility, match-app flag, supported appearance values, revision |
| `appearance_preferences` | System/light/dark, tested accent key, density, accessibility overrides |
| `import_drafts` | Draft ID/type, local source reference, candidate data, user edits, warnings, review state, expiration; not active schedules |
| `import_provenance` | Local series ID, source type, share snapshot/item/version or image draft reference, fingerprint, imported timestamp |
| `owned_share_links` | Backend share ID, snapshot version, scope summary, expiry/revocation state; raw bearer URL only in an appropriate local protected store if retained |
| `backend_session` | Backend anonymous/account session handled by the auth SDK and platform-protected storage, not by copying tokens into schedule records |

### 10.2 Time fields

A timed seed stores a local calendar date, local clock time, IANA zone and an optional end/day relationship. Derived UTC instants are caches, not replacements for the recurrence definition.

A date-only seed stores calendar dates; a range uses an explicit end-exclusive date in the contract. The UI can display an inclusive end date but must convert deliberately. No date-only import gets a fabricated UTC midnight.

Store stable IDs and structured values separately from localized labels. Never parse user-visible time text back into the domain model.

### 10.3 Transactions and deletion

- Create/edit/import writes domain records and reconciliation work in one transaction.
- Category deletion reassigns records only after a user decision.
- Series deletion removes its local exceptions and desired alert rules and creates cancellation work for known native request IDs.
- Widget snapshots update after committed data changes, not from an unfinished editor.
- App deletion/uninstall and OS backup behavior are not a substitute for a deliberate backup policy. Local encryption, backup exclusion and recovery expectations are release decisions.

## 11. Flutter frontend architecture

### 11.1 Layering

Use feature-first organization with thin presentation, application, domain and data boundaries:

- **Presentation:** Flutter screens/components, accessibility and platform-adapted interaction.
- **Application:** Riverpod controllers/view models, commands and UI state machines.
- **Domain:** schedule validation, bounded recurrence, occurrence identity, filtering, ordering, import validation and duplicate rules. No widget/platform/network imports.
- **Data:** Drift repositories, schema migrations, API clients and storage adapters.
- **Platform services:** notifications, alarms, widgets, secure storage, photo picker, clock/time-zone signals and deep links.

Repositories are sources of truth. Widgets do not query the backend directly or implement recurrence. State management must not become a second competing database.[1][2]

### 11.2 Planned structure

```text
lib/
  app/                 # shell, routes, theme wiring, lifecycle coordination
  core/
    time/              # injected clock and time-zone abstraction
    recurrence/        # bounded pure occurrence expansion
    validation/        # typed domain and import validation
    platform/          # abstract contracts and capability model
  features/
    schedules/         # domain, data, application, presentation
    categories/
    reminders/
    widgets/
    image_import/
    sharing/
    appearance/
    privacy/
  data/local/          # Drift tables, repositories, migrations, outbox
  integrations/        # native bridge, HTTP, auth and OCR adapters
assets/icons/          # curated, licensed local SVGs
android/               # native widget/alarm implementations and manifests
ios/                   # WidgetKit extension, shared container, AlarmKit bridge
backend/               # proposed infrastructure/functions and migrations
web-preview/           # small link-preview client and association assets
test/                  # domain, controller, repository and migration tests
integration_test/      # supported app flows; native device checks also required
```

This is a proposed structure. These application folders are not created by this documentation task.

### 11.3 Core interfaces

| Interface | Contract |
|---|---|
| `ScheduleRepository` | Transactional local CRUD and bounded query streams; no implicit cloud sync |
| `OccurrenceEngine` | Expand a series plus exceptions for a bounded window using an injected clock/zone database |
| `ImportValidator` | Validate a draft and return field-level errors without side effects |
| `ImportCommitService` | Atomically commit selected validated entries and reconciliation work |
| `NotificationScheduler` | Permission/capacity checks, idempotent schedule/cancel, accepted-request status |
| `AlarmScheduler` | Capability discovery, consent, schedule/cancel supported app-owned alarms |
| `ExternalClockGateway` | Explicit hand-off; returns requested/unavailable/error, not an invented confirmed state |
| `WidgetSnapshotService` | Serialize committed occurrences/preferences into a versioned atomic native snapshot |
| `ImageScanService` | Local scan and explicitly opted-in cloud job; returns draft candidates only |
| `ShareService` | Create/revoke owned snapshots and resolve bearer links; does not mutate local schedules |
| `DeviceCapabilities` | OS/API/permission/host-supported capabilities for truthful settings |

All services expose typed errors. UI copy maps from error categories; provider stack traces and credentials never enter user-visible messages.

### 11.4 State and lifecycle

- Inject the current clock; tests must not depend on the machine's current date.
- Derive Today/Week/Next from committed data and an explicit filter/window.
- Retain review/editor state through ordinary navigation and safe app interruptions.
- On resume, reconcile time-zone and permission changes and refresh native snapshots as appropriate.
- Debounce redundant derived updates; never depend on a perpetual Dart timer when the app is terminated.
- Network-unavailable sharing/AI actions fail clearly without disabling local scheduling.
- Preserve a received deep link while the user reviews an existing unsaved form; do not discard edits or silently import.

### 11.5 Dependency and build policy

Use maintained packages behind adapters, with exact compatible versions selected at scaffold time. Assess native SDK baselines, licenses, release history, platform requirements and privacy disclosures. Keep the package lockfile under version control.

Native widget work is expected: home_widget provides a bridge, not a replacement for native widget layout and lifecycle.[5] Flutter SVG support does not imply SVG support in a native extension.[6]

iOS native build/testing requires access to a suitable Mac/Xcode environment. Its availability is unresolved; a successful Windows-only documentation check cannot certify iOS.[29]

## 12. Native integration contracts

### 12.1 Capability model

Expose separately:

- Notifications authorized and applicable channel enabled.
- Exact scheduling available/authorized where required.
- App-owned alarm API available and authorized.
- Full-screen alarm access available/authorized and policy-approved.
- Compatible external Clock handler available.
- Widget family/layout supported and current rendering mode.
- Supported photo decode/conversion formats.

A permission checkbox in the app is a desired preference, not proof of OS authorization.

### 12.2 Widget snapshot

A versioned snapshot contains only what native rendering needs:

- Schema version, data revision, generation time and time-zone context.
- Per-widget configuration identity and filter.
- A bounded set of resolved occurrences with actual IDs, times and selected visible details.
- Requested appearance tokens and privacy preference.
- Relevant validation/staleness state, not provider secrets or entire source images.

Write snapshots atomically. Native readers must detect unsupported versions and use a safe empty/open-app state rather than crash or partially parse data.

On iOS, use an App Group/shared container and native timeline entries. On Android, use the verified shared-storage bridge and native widget provider. The widget must render useful cached data without a running Flutter UI.[5]

### 12.3 Refresh contract

Trigger refresh after committed edits/imports, filter changes and supported lifecycle/system events. Supply future timeline states or supported scheduled updates for occurrence boundaries rather than a minute-by-minute Dart loop.

OS scheduling and reload budgets can delay updates. Do not display a continuously changing countdown unless the native API actually provides it. Prefer absolute dates/times and a truthful stale/open-app treatment when cached data no longer suffices.

Android's periodic `updatePeriodMillis` path does not support intervals under 30 minutes. Data/lifecycle-triggered updates and a verified native boundary strategy are therefore required; replacing it with unrestricted polling is not a supported guarantee.[32]

Apple describes budgeted WidgetKit reloads and precomputed timeline entries; its typical refresh-budget example is 40–70 per day, not an exact service-level promise. Precompute meaningful occurrence states and test coalescing/delayed updates rather than promising an exact repaint every minute.[31]

Multiple widget instances have independent filters and appearances. Deleting one widget must not remove events or another widget's configuration.

### 12.4 Deep links

Use verified HTTPS associations for the chosen bundle/application IDs and domain.[18][19] App routing must cover cold start, warm start, invalid token, expired/revoked link, schema mismatch, offline preview failure and safe cancellation.

A widget link opens an existing occurrence/detail or an honest **Schedule no longer available** state. It does not create an event.

### 12.5 Alarm and notification native proof

Before enabling release flags, prove on real devices:

- Lock-screen versus unlocked presentation.
- Granted, denied and later-revoked permissions.
- App foreground/background/terminated and supported reboot/time-zone cases.
- Stop/snooze behavior without mutating event dates.
- Cancellation after edits and single-occurrence changes.
- External Clock behavior without claiming unsupported feedback.
- Native visibility limits for title/description and user privacy settings.

If the proof fails, the UI must expose the reduced capability instead of preserving the original promise.

## 13. Backend architecture and database

### 13.1 Role and boundaries

The backend exists for **share snapshots**, **optional AI-image jobs**, ownership/quota controls and link preview. It is not the source of truth for the user's complete local schedule database in the first version.

```text
Flutter app
  |-- Local SQLite --> domain queries --> native widget snapshot
  |                                \--> notification/alarm reconciliation
  |
  |-- explicit selected snapshot --> authenticated backend --> Postgres
  |                                                       \--> bearer link preview
  |
  \-- explicit AI-scan consent --> private image upload --> bounded worker
                                                          \--> approved vision provider
                                                               \--> review candidates only
Browser preview --> read-only resolve endpoint --> selected shared snapshot
```

Proposed managed stack: Supabase Auth, Postgres with RLS, private Storage and Edge Functions plus a bounded background worker/queue if provider calls exceed synchronous request limits. Do not assume a long-running image job can live indefinitely inside one edge request.

The reviewed Supabase Edge limits include 256 MB memory and two seconds of CPU time per request. Image decoding must be benchmarked against the selected runtime; use an isolated bounded worker when decoding cannot safely fit, not an assumption that an edge endpoint can decode any accepted image.[25]

### 13.2 Identity and ownership

Core local use needs no backend identity. Create/authenticate the proposed anonymous online identity only when required for share creation or a cloud scan. An anonymous session is not a recovery account.

With the proposed Supabase option, an anonymous signed-in user uses the `authenticated` database role, not the unauthenticated `anon` role. Do not write a broad policy that accidentally grants every anonymous installation access to every owner's data.[21]

All management operations derive ownership from verified server-side authentication, never a client-supplied owner ID. RLS is defense in depth; public preview uses a narrow server function, not public SELECT access to all snapshots.

Keep internal records outside exposed API schemas or revoke all unintended table/function grants. Separate JWT-verified management functions from the narrow public capability resolver. A privileged service client bypasses RLS: every such query must explicitly enforce the verified owner or bearer capability, even when RLS is enabled.[22][23]

No privileged/service credential belongs in Flutter, browser JavaScript or a public repository. A public backend project key is not a substitute for authorization policies.

### 13.3 Planned server records

| Record | Fields and access |
|---|---|
| `share_links` | ID, owner identity, immutable payload/schema version, item count, payload hash, token hash, expiry, revoked timestamp, created timestamp; owner metadata access, public payload only through resolver |
| `scan_assets` | ID, owner, private storage key, declared and detected type, byte/pixel limits, expiry and deletion state; never public |
| `scan_jobs` | ID, owner, asset ID, status including uncertain outcome, approved provider/model configuration reference, reserved/settled usage, validated candidate result, error code, expiry, timestamps |
| `usage_buckets` | Subject/global rate window, reserved/consumed units, concurrency state; server-controlled |
| `idempotency_records` | Subject, route, key hash, request hash, resource ID, safe outcome metadata, expiry; no raw share secret |
| `security_events` | Minimal request/route/outcome identifiers and coarse abuse signals; no raw tokens, image text or schedule descriptions |
| `deletion_jobs` | Owner/object references, scope, progress and retry state for backend cleanup |

The snapshot payload includes only selected content fields, structured recurrence, permitted exceptions and category labels. It excludes sender native alarm IDs, auth identity, source images, device metadata and local file paths.

### 13.4 Bearer-token handling

- Generate at least 32 random bytes on device using a vetted cryptographically secure source. Persist the secret in an appropriate protected store before the create request so an uncertain response does not lose it.
- Send only its SHA-256 digest with the selected snapshot to create the backend record. The server validates the digest format and stores the digest, never the raw secret.
- The proposed URL shape is an owned HTTPS `/s/{shareId}` route with `#token={secret}`. The client composes it from server metadata and the retained local secret; the create response and idempotency cache contain no bearer URL.
- A URI fragment is handled separately from dereferencing, reducing disclosure to ordinary HTTP request paths; it still exists in browser history, application state, screenshots and any script reading the page. No third-party scripts or analytics belong on this landing page.[30]
- The app/browser extracts the secret and submits it only in a redacted resolver POST body with the share ID. Confirm cold/warm native and browser handling preserves fragments before freezing this URL scheme.
- The owner list/status endpoints return metadata, not recoverable secrets. If local secrets are lost, create a replacement link rather than pretending a hash can reconstruct one.
- Identical create retries use the same persisted secret/digest and idempotency key. Return the existing resource metadata, not a fresh link capability.
- Redact tokens, request bodies and sensitive URLs from application/error/analytics logs even when a fragment is used. Do not log the full incoming deep-link URI.
- Send a restrictive referrer policy and private/no-store response policy for personal payloads.
- Check revocation/expiry on every resolve, serialized with revocation authorization at the share record. A previously authorized response may finish, and downloaded data cannot be recalled.

The domain, fragment handling, protected local storage and log-redaction capability require verification before launch. If the proposed scheme fails its native proof, revise this contract explicitly; do not silently expose secrets in query/path parameters.

Do not use a long-lived Storage signed-download URL as the share capability. Supabase documents that those URLs remain valid until expiry despite Auth-key changes; application revocation must be enforced by the resolver, not assumed to revoke a storage URL.[24]

### 13.5 Payload and versioning

One versioned share contract and one versioned extraction-candidate contract must be shared across mobile/backend/web validation. Unknown major versions are rejected with a safe update/explanation path.

Whitelist fields, string lengths, valid dates/zones, allowed recurrence forms and exception counts. Reject malformed relationships and duplicate item IDs. Server-side validation does not trust the Flutter client or a model's output.

### 13.6 Local confirmation boundary

There is intentionally no backend endpoint that automatically adds a shared/AI-derived item to someone's device schedule. Resolution returns data. Local review and an explicit local transaction perform the import.

## 14. Backend API contracts

These are proposed endpoint contracts, not implemented endpoints or sample responses. All bodies are typed/versioned JSON unless an upload protocol says otherwise. Request/response values shown as field names are schema definitions, not fabricated live records.

### 14.1 Common behavior

- TLS only. Management endpoints require a valid owner session; public resolve is separately rate-limited.
- State-changing requests use an `Idempotency-Key` scoped to identity and route where a retry could create duplicate shares/jobs.
- Reusing a key with a different request hash returns a conflict, not a second operation.
- Create operations reserve quotas transactionally before expensive work.
- Errors contain a stable code, safe message, request ID, optional field errors and retryability. No provider stack trace or secret.
- Public errors do not expose internal owner IDs or object storage keys.

### 14.2 Endpoint inventory

| Endpoint | Authorization | Request / response contract |
|---|---|---|
| `POST /v1/share-links` | Owner session | Input: schema version, selected validated payload, token digest, expiry choice. Output: share ID, non-secret route metadata, expiry, actual item count and snapshot version; client composes URL from its retained secret. Idempotent create. |
| `GET /v1/share-links` | Owner session | Paginated owner metadata: IDs, creation/expiry/revocation state, scope summary and counts; no complete local database or raw tokens. |
| `GET /v1/share-links/{shareId}` | Owner session | Exact owner status/metadata for management and revoke read-back; no bearer secret. |
| `DELETE /v1/share-links/{shareId}` | Owner session | Idempotent revoke. Other owners cannot discover/manage the share. Does not delete recipient copies. |
| `POST /v1/share-previews/resolve` | Bearer token + rate controls | Input: share ID, fragment-derived token and supported schema versions. Output: permitted snapshot and display metadata only. Read-only; never imports or creates a scan. |
| `POST /v1/scan-assets` | Owner session | Input: declared type/size and consent context. Output: owner-scoped asset ID, short-lived upload instruction and limits. |
| `POST /v1/scan-jobs` | Owner session | Input: owned asset ID, schema version, explicitly chosen scan mode, optional bounded OCR evidence. Output: job ID/status. Idempotent; validates upload before provider use. |
| `GET /v1/scan-jobs/{jobId}` | Owner session | Output: queued/running/review-ready/failed/cancelled/unknown state; validated candidates only when ready; uncertain provider outcomes do not automatically retry. |
| `DELETE /v1/scan-jobs/{jobId}` | Owner session | Request cancellation and cleanup. An in-flight external request may already have incurred usage; do not promise a refund. |
| `DELETE /v1/scan-assets/{assetId}` | Owner session | Idempotent owner-scoped cleanup. Must not delete another owner's object. |
| `POST /v1/privacy/delete-backend-data` | Owner session + explicit confirmation | Queue deletion/revocation of this identity's server data, return progress reference. Local schedules remain unless separately deleted locally. |
| `GET /health` | Restricted minimal health response | Availability only; no secrets, internal addresses or personal payloads. |

Use the auth provider's documented anonymous-session API rather than inventing a custom password/account flow for local scheduling.

### 14.3 Status and errors

- `400`: malformed/invalid request or fields.
- `401`: missing/invalid management authentication.
- `403`: authorized identity lacks a capability or permission; public object existence must not leak through management errors.
- `404`: not found, unknown token, revoked/unavailable link or non-owned resource where indistinguishability is required.
- `409`: idempotency request mismatch, incompatible state, or an expired replay record that cannot safely reproduce the original resource outcome.
- `410`: a known expired/revoked link only after a matching capability proves that state may be disclosed; unknown/wrong capabilities remain `404`.
- `413`: payload/image too large.
- `415`: unsupported or mismatched media type.
- `422`: valid transport but unsupported schedule/schema/recurrence semantics.
- `429`: rate/quota/concurrency limit; safe retry guidance where applicable.
- `5xx`: internal/provider unavailable/timeout category; no personal content in errors.

A successful create is `201`; an existing idempotent create replay returns the documented same resource outcome without repeating work. Accepted asynchronous jobs/deletions may use `202`. Revoke/delete uses a documented idempotent response. Exact transport details are to be frozen with an OpenAPI contract before implementation.

### 14.4 Idempotency and local imports

A create replay contains resource/outcome metadata only. The bearer secret remains client-held. After replay retention expires, return a documented uncertainty/conflict path rather than silently create another resource under an old key; require an explicit fresh action after checking owner metadata. After revocation, read the exact owner status endpoint before claiming the management action succeeded.

Atomically reserve both owner and global usage/concurrency before dispatching provider work, using a consistent lock order. Do not hold database locks during a network call. If a provider may have accepted a request but the outcome is unknown, retain a conservative reservation and mark `unknown`; do not automatically repeat a potentially billable call without provider idempotency or verified reconciliation.

Local imports additionally track snapshot/item/version identity and candidate fingerprints. The app disables duplicate submission while a commit is active, uses a transaction, and checks existing provenance after uncertain completion before retrying. Network idempotency does not replace local atomicity.

## 15. Security, privacy and AI governance

### 15.1 Threat model

Protect against forwarded/leaked links, cross-owner access, anonymous quota abuse, untrusted file uploads, decompression bombs, malicious SVG/script input, prompt injection in images, model hallucinations, duplicate imports, unsafe recurrence expansion, credentials in client builds, XSS in preview text, sensitive data in logs and misleading scheduled-alert status.

### 15.2 Minimum controls

- Verify authentication server-side and enforce owner policies on every management path.
- Deny broad public database/storage reads; do not let a public token become a SQL selector.
- Treat all titles, notes, OCR text and model output as untrusted plain content. Render text safely; never inject it as HTML.
- Validate actual decoded file type, dimensions and size, not only filename or client MIME. Apply bounded decoding and isolate/patch the decoder.[34]
- Strip unnecessary image metadata; do not follow arbitrary URLs found inside an image.
- Isolate the vision worker's network access to approved provider/storage endpoints.
- Treat image text as data, never as instructions, tools or authorization to create schedules. The model receives no browsing/tool/database credentials; prompt wording alone is not the security boundary.[35]
- Keep credentials in a backend secret store. Never compile a billable provider secret into the app.[17]
- Rate-limit per identity and additional abuse signals. Reinstalling an anonymous app must not be treated as a robust quota boundary.
- Use explicit cloud consent, request budgets and a global provider kill switch.
- Do not silently activate permissions/alerts from imported or shared content.

### 15.3 AI-provider selection gate

The provider is **not selected**. Benchmark representative, permission-cleared images for field accuracy, row/column association, unresolved-field handling, latency and cost. Do not select solely because a free quota exists.

School users may be minors. Google's standard Gemini API terms currently restrict clients directed at or likely to be accessed by individuals under 18; its unpaid-service data use also differs from paid-service handling.[16] Therefore this document does not approve Gemini as a universal school-app backend. Confirm audience, jurisdiction, provider eligibility, contractual privacy, retention and consent before live personal images are sent anywhere.

A paid API or a no-training statement is not the same as zero retention. App-controlled cleanup cannot guarantee immediate deletion from a provider's operational/security logs. Consent and privacy copy must describe the actual selected arrangement.

### 15.4 Image and job lifecycle

- Source image stays on device unless the user chooses cloud scan.
- Upload only the chosen/cropped image region and necessary OCR evidence.
- Private object access is owner-scoped and short-lived.
- Delete transient app-controlled uploads/results according to the approved TTL and on cancellation where possible.
- Disclose when the external provider may still retain operational data.
- A failed or cancelled job must not become an active event or generate reminders.
- Any retained source image reference for local review is separately removable.

### 15.5 Share privacy

Before creating a link, show exactly what will be uploaded. The default share excludes source images, device/auth metadata and sender alert settings. Optional room/professor/notes sharing is visible and editable.

Provide expiry/revoke controls and a warning that anyone with the link may access it. Do not claim link revocation recalls imported copies. Work schedules may contain sensitive location information; product language must not encourage treating a bearer link as authenticated private sharing.

### 15.6 Data deletion and recovery

Separate **Delete local schedules**, **Delete scan source**, **Revoke share**, and **Delete my backend data**. Their scopes differ. A backend deletion request must return a verifiable state/progress indicator rather than a false instantaneous success claim.

Account linking, anonymous-session recovery, database encryption and OS backup policy are unresolved release decisions. Document the actual loss/recovery behavior before users rely on the app.

## 16. Limits, reliability and operations

### 16.1 Proposed product limits

These are engineering starting points for approval, not measured results or provider quotas.

| Area | Proposed bound / behavior |
|---|---|
| Title | 120 characters; no forced truncation of stored user data on import |
| Subtitle | 240 characters |
| Location | 240 characters |
| Professor/person | 160 characters |
| Notes | 4,000 characters |
| Shared snapshot | At most 250 selected series/entries and 500 exception records; reject oversize explicitly |
| Shared JSON | At most 512 KiB after canonical serialization; server enforces bytes |
| Local source admission | Proposed 10 MiB and 40 million decoded pixels, subject to reference-device memory tests; reject safely before an unbounded decode |
| Normalized cloud upload | Static JPEG/PNG, at most 5 MiB, 12 million decoded pixels and 4,096 pixels per dimension; server enforces actual decoded limits |
| AI candidate result | At most 100 candidates per image; report truncation/unsupported density and ask for smaller crops rather than silently omit |
| Cloud upload authorization | Short-lived; proposed 15-minute validity |
| Transient image/job retention | Proposed one-hour app-controlled cleanup target after completion/cancellation; orphan sweeper and maximum 24-hour transient-storage retention subject to approved backup/provider policy |
| Default share expiry | Proposed seven days, editable before creation; longer/no-expiry choices require explicit approval |
| Idempotency outcome retention | Proposed 24 hours; no raw bearer URL/secret in the outcome; clients never blindly replay beyond retention |
| Recurrence expansion | Always bounded by query window and explicit output cap; no unbounded enumeration |
| OS pending alerts | Respect verified platform/adapter capacity; never hardcode an unlimited assumption |
| Scan budgets | Per-identity, network-abuse and global spend limits configured before public rollout; no unlimited anonymous provider access |

A candidate or payload that exceeds a bound remains editable. Do not silently truncate a professor's name, discard the final rows of a timetable, or claim a partial share is the whole selection.

### 16.2 Proposed performance budgets

Define reference devices before measurement. Initial targets, not achieved benchmarks:

- Core Today/Week queries remain responsive with the configured maximum active series and bounded occurrence window.
- Local save/import confirmation must not wait for a network round trip or synchronous widget rendering.
- Expensive recurrence/image work runs off the UI hot path.
- Long previews use virtualized lists and preserve edits while scrolling.
- Report scan progress honestly; do not use a fake percentage to disguise an unknown-duration API request.
- Widget snapshots are small, versioned and atomically replaced.

Collect real measurements during implementation before publishing latency, reliability or battery claims.

### 16.3 Deployment and observability

Use separate development, staging and production projects, credentials, domains and storage. Database/function changes use reviewed migrations and rollback procedures. Keep a minimal read-only health check and content-free telemetry: request IDs, error categories, aggregate latency/usage, cleanup success and quota denial counts.

Do not log tokens, entire URLs containing secrets, raw image/OCR text, private descriptions or provider requests. Test log redaction and data cleanup rather than assuming platform defaults are safe.

### 16.4 Offline and degraded behavior

- Local CRUD, filtering and review of existing local data work offline.
- Share creation/resolution and cloud scans explain their network requirement.
- Previously saved schedules and widget caches do not disappear because the server is unavailable.
- Permission denial does not disable the entire app.
- A request accepted by an OS/provider is not an unconditional delivery guarantee.
- Force-stop, uninstall, vendor restrictions and unattended horizon exhaustion require truthful supported-behavior documentation, not hidden promises.

On Android 15 and later, force-stop cancels the app's pending intents and disables its widgets until a subsequent launch. Relaunch/reconciliation and truthful user guidance are required; the app must not claim it can bypass this system behavior.[27]

## 17. Testing and acceptance criteria

### 17.1 Development discipline

Use test-driven vertical slices: write one behavior test, run it and observe the expected failure, implement the smallest passing behavior, then refactor while keeping tests green. Do not write all tests or all production code in one horizontal batch.

Required layers:

- Pure domain tests: recurrence, time zones, validation, filtering, ordering and duplicate identity.
- Repository/transaction and migration tests using an actual test database.
- Controller/widget tests for forms, review state and truthful capability labels.
- Backend contract/RLS/storage tests with at least two owners and a public client.
- Mobile integration and real-device native widget/alarm/deep-link tests.
- Web preview accessibility, XSS and link lifecycle tests.

Mocks cannot substitute for proving OS presentation, server access control or database migration behavior.

### 17.2 Acceptance matrix

| ID | Given / when | Required result |
|---|---|---|
| AT01 | Offline, user creates/edits a manual schedule | Actual entered values persist locally; no account or cloud call required |
| AT02 | Optional details are absent or imported information is unknown | Missing fields stay absent/unresolved; no invented UI values |
| AT03 | Daily/weekly series with selected days and final date | Only valid bounded occurrences appear, including correct boundary behavior |
| AT04 | One occurrence is moved or cancelled | Original occurrence is replaced/cancelled once; other occurrences are unchanged |
| AT05 | Source/device zones differ or DST creates an ambiguous/nonexistent time | Source semantics are preserved; unresolved times require explicit review |
| AT06 | Poster yields a date but no time/end | Date-only or explicit no-end representation; no fabricated midnight/duration |
| AT07 | Ongoing, overlapping, next-day and point events are queried | Ordering and focus match section 6; no hidden concurrent events |
| AT08 | Category filters, rename/delete and Uncategorized are exercised | Deterministic OR/filter behavior; no accidental event deletion |
| AT09 | Two widgets use different categories/appearances | Configurations remain independent and render the correct saved data |
| AT10 | Clear widget is used over light/dark/busy wallpaper | Wallpaper is not changed/copied; native limitations and readable alternatives are truthful |
| AT11 | Transparent style is unreadable or accessibility settings change | Accessible preset/stronger treatment is available; no false universal contrast claim |
| AT12 | Light/dark, large text, SVG assets and layout are tested | Consistent visual system, no clipped essential content or unlabelled icon actions |
| AT13 | Reminder is off, enabled, denied or later revoked | Custom offset and actual authorization/status are correct; no false scheduled badge |
| AT14 | Alarm and notification use different settings | They remain independent; unsupported alarm capability is explained |
| AT15 | Android Clock hand-off is unavailable or launched | Correct fallback/external-unverified state; no invented creation/sync confirmation |
| AT16 | Prominent alert on locked/unlocked Android and supported/older iOS | Only permitted native behavior; truthful fallback, no unconditional takeover promise |
| AT17 | A scheduled entry is edited/deleted or one exception changes | Obsolete known requests are cancelled/reconciled without duplicate ringing |
| AT18 | Reboot, time-zone change, app termination and force-stop are tested | Documented supported behavior and visible limitations; no timer-based false guarantee |
| AT19 | Unsupported/mislabeled/corrupt/rotated/large image is selected | Safe normalization or precise rejection; source stays editable |
| AT20 | User declines cloud scan consent | No image/OCR evidence is uploaded or sent to a provider |
| AT21 | Year, date order, AM/PM, term dates or table association is unclear | Field-level review required; no guessed fact presented as certain |
| AT22 | Image text attempts to instruct the model/backend | Treated as data; no arbitrary tool/network/action execution |
| AT23 | Extraction result is partial or uncertain | Source evidence and actual candidates shown; no fake confidence percentage/completeness |
| AT24 | Image/link review is closed without confirmation | No schedules, notifications or alarms are created |
| AT25 | Selected validated entries are confirmed, then native scheduling fails | Entries commit once; alert failure is shown without inviting duplicate imports |
| AT26 | Exact repeated import or similar/overlapping entry is detected | Explicit skip/keep-copy choice and warning; no silent destructive merge |
| AT27 | Sender shares current filter, all, or edited selection | Serialized scope/count exactly matches preview; limits never silently omit entries |
| AT28 | Snapshot is inspected | Only approved fields; no source images, auth/device data or sender alert IDs/settings |
| AT29 | Link opens cold/warm, in browser, offline or after installation | Preview-first behavior; reopening link works; no automatic import |
| AT30 | Recipient edits/imports a shared schedule | Local independent copy changes; sender snapshot and other recipients do not |
| AT31 | Link expires/revokes, is invalid, or resolve races with revoke | Subsequent authorization fails; an already-authorized response may finish; downloaded previews/imported copies are not falsely recalled |
| AT32 | Duplicate create/retry, fragment handling, token leak surfaces and quotas are tested | Stable metadata/client-held secret, bounded work, redacted logs and no fresh capability under an old replay key |
| AT33 | Owner A, owner B and public client attempt cross-access | No cross-owner management/storage access; narrow public resolver only |
| AT34 | Decompression bomb, spoofed MIME, script/SVG or oversized payload is submitted | Enforced server decode/schema limits before expensive processing |
| AT35 | AI times out, has uncertain billing/outcome, exceeds budget or returns invalid output | Typed failure/unknown/partial review; conservative reservation and no unverified paid retry, fabricated success or active schedules |
| AT36 | New/unknown snapshot or candidate schema version arrives | Safe rejection/update path; no crash or partial activation |
| AT37 | Long timetable and configured upper-bound fixtures are used | Responsive scrolling and bounded expansion; measurements recorded on named devices |
| AT38 | Database schema migration or reconciliation crashes mid-operation | Tested migration/transaction behavior; recoverable outbox without duplicate requests |
| AT39 | Screen reader, large text, focus, keyboard and empty states are exercised | Accessible equivalent flows and truthful minimal copy; fixtures absent from release |
| AT40 | User deletes backend data but keeps local schedules | Server deletion/revocation progresses truthfully; local schedule database is preserved |
| AT41 | Anonymous session is lost | Recovery limitation is explicit; management rights are not granted to a new unrelated identity |
| AT42 | First launch and ordinary local use | No signup wall, unsolicited uploads or bulk permission prompts |
| AT43 | Backend is unavailable | Local schedule/widget data remains usable; online actions fail clearly |
| AT44 | Pending native-request capacity or horizon is exhausted | Nearest requests prioritized; unscheduled future coverage is visible and reconciled honestly |
| AT45 | Native snapshot write/version change is interrupted | Atomic reader behavior or safe fallback; no mixed/partially decoded state |
| AT46 | Audience/provider/privacy gates are not approved | Production personal-image scanning stays disabled |
| AT47 | Widget reaches an occurrence boundary without the Flutter UI open | Verified native timeline/update behavior; stale data never masquerades as guaranteed live state |
| AT48 | Widget points to a deleted/changed occurrence | Safe details/changed-state handling; no auto-create or crash |

### 17.3 Proof required before claims

The documentation tooling may validate Markdown, token references and opaque contrast pairs. That does **not** prove app correctness, screenshot fidelity, model accuracy, permission behavior, backend security, alarm reliability or store approval. Those claims require the corresponding implementation and actual test output.

## 18. Implementation sequence

All phases below are future work, not tasks already performed.

### Phase 0 — Approve the contract and prove native risks

- Resolve the blocking choices in section 19.
- Run disposable native proofs for Clear widget rendering, refresh boundaries, date-specific alarms, AlarmKit, full-screen access and Clock hand-off limitations.
- Test verified links on a real owned domain and cold/warm app starts.
- Decide the honest platform capability matrix before polishing unsupported screens.
- Use permission-cleared image samples to compare local OCR and candidate cloud providers, without assuming school/minor eligibility.

### Phase 1 — One complete offline schedule slice

Design tokens → manual editor → local transaction → Today row → details/edit → actual tests. Use test-first vertical slices. Establish migration tests, injected time and basic accessibility at the start.

### Phase 2 — Recurrence, exceptions, categories and Week

Implement bounded recurrence and time-zone rules before relying on the same logic for alerts or widgets. Add category filters and accessible agenda behavior. Prove duplicate/overlap handling with real domain tests.

### Phase 3 — Native widgets

Use committed snapshots and per-widget settings. Prove appearance, next/upcoming transitions, clipping, multiple instances, deep links and accessible fallback on actual supported devices.

### Phase 4 — Reminders and alarms

Add permission-aware notifications, reconciliation/outbox, supported app-owned alarms and optional external Clock hand-off. Test denial/revocation/edit/delete/capacity/reboot and locked/unlocked presentation. Expose truthful degraded modes.

### Phase 5 — Secure snapshot sharing

Provision the approved backend/domain, implement ownership/RLS/schema validation/idempotency/revocation, build the small web preview, and connect preview-first recipient import. Test with multiple owners and hostile payloads before opening public creation.

### Phase 6 — Image import

Ship safe local decoding/OCR and editable draft review first. Enable cloud interpretation only after privacy/audience/provider and budget gates pass. Test representative difficult images; publish no fabricated accuracy claims.

### Phase 7 — Release hardening

Complete accessibility, performance, privacy disclosures, cleanup, backup/recovery decisions, crash-safe reconciliation and store permission review. Keep experimental/unsupported native features gated. Review every advertised behavior against real device evidence.

## 19. Open decisions and risk register

### 19.1 Decisions requiring user approval

| ID | Decision | Recommended starting position | Blocks |
|---|---|---|---|
| D01 | Product name/logo | Leave unbranded until chosen | Branding, not domain work |
| D02 | Supported OS/device baseline | Propose Android API 26+ and iOS 17+, subject to dependency/device-audience audit; AlarmKit gated separately | Native setup and release support |
| D03 | Target audience: adults only or also minors | Do not assume; confirm before selecting AI/backend terms | Production cloud scanning |
| D04 | Deployment region, provider and privacy arrangement | Select based on audience/jurisdiction and verified terms | Production backend/AI |
| D05 | Cloud-assisted scanning consent | Separate opt-in action; local/manual path always available | Image UX and provider integration |
| D06 | Snapshot versus live shared updates | Independent snapshot copies in v1 | Sharing contract |
| D07 | Identity/recovery | Anonymous online creation with clear recovery warning; optional accounts later | Share ownership and deletion/revocation UX |
| D08 | Default widget look | Requested Clear with no requested blur, plus accessible solid option | Final native styling |
| D09 | Alert defaults and lock-screen disclosure | Off until chosen; conservative detail disclosure | Alert UX |
| D10 | Clock/full-screen compromises | Accept capability-gated app alarms and optional Android Clock hand-off, not universal Clock sync | Alarm acceptance |
| D11 | Accent presets and density defaults | Restrained blue, system theme, comfortable density | Final visual polish |
| D12 | Local encryption/OS backup/recovery | Decide explicitly; do not imply Drift/SQLite automatically encrypts or synchronizes | Release privacy and data-loss expectations |
| D13 | Proposed limits/expiry/retention | Validate against devices, backend policy and budget | Public rollout |
| D14 | Access to Mac/Xcode and real target devices | Confirm availability; no Windows-only iOS certification | iOS implementation and QA |

### 19.2 Risk treatment

- **Native transparency differs:** use capability-driven presets and accept system material/tint.
- **Clear widget unreadable:** strong/solid accessible preset; test wallpapers without accessing user wallpaper.
- **Full-screen or exact alarm denied:** truthful notification/reduced-capability fallback; no permission bypass.
- **Clock hand-off cannot express an event:** warn or use supported app-owned scheduling, not a wrong-day alarm.
- **Unattended horizon/capacity exhaustion:** verify native strategy and expose coverage limits before release.
- **AI invents/misassociates fields:** evidence, schema/range validation, explicit ambiguity and mandatory review.
- **School audience incompatible with a provider:** keep provider unselected and cloud feature disabled until approved.
- **Link is forwarded:** bearer-link disclosure, expiry/revoke, field minimization; private authenticated sharing is separate scope.
- **Anonymous identity lost:** explicit recovery limitation; do not transfer ownership by guessing.
- **State changes but scheduling fails:** local transaction/outbox and actual status, not a false success badge.

## 20. Approval and implementation handoff

Before production app work begins, confirm:

- [ ] This document captures the desired product and platform compromises.
- [ ] The proposed first-version scope and exclusions are accepted or edited.
- [ ] The visual direction in DESIGN.md is accepted or edited.
- [ ] Audience, backend identity/recovery, link semantics and cloud-scan privacy are decided sufficiently for the affected phase.
- [ ] Native proof tasks and real-device access are available.
- [ ] Dependency versions, schema/OpenAPI contracts and capability flags will be frozen at scaffold time, not guessed now.
- [ ] No feature will be advertised as working until its acceptance tests and native checks actually run.

A later implementation agent should read this file, DESIGN.md, CONTRACTS.md, SOURCES.md and VALIDATION.md before writing production code. Open decisions are intentional unresolved choices, not permission to invent missing product facts.

## 21. Sources

Primary references and their scope are recorded in [SOURCES.md](#appendix-c-primary-source-register). Bracketed numbers in this specification refer to that source register. Product requirements come from the conversation; proposed defaults are engineering recommendations, not research findings or confirmed user decisions.


---

## Appendix A: Visual system and design tokens

The following YAML is the supported token front matter from the modular DESIGN.md; native-specific material values remain explicit prose below.

```yaml
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
```

### Overview

**Status:** proposed design system for approval before app implementation. The product name is not a chosen brand. This document contains design instructions, not a claim that the app or native widgets have been built.

The primary surface is **Monitor**: people glance at a timeline to find the current or next schedule. A schedule editor is a secondary **Configure** surface. Composition follows the task: date and filter controls, an ordered timeline, then contextual actions. There is no marketing hero, decorative statistics, motivational slogan, or equal-weight feature-card grid.

The direction is minimal and Apple-inspired without cloning a branded screen. Hierarchy comes from type, spacing, alignment and restrained emphasis. Glass is limited to supported navigation/material treatments and widget holders. Important schedule text is not buried under blur.

Normative product behavior, security rules and platform limits live in [SCHEDULER_SPEC.md](#scheduling-app-pre-implementation-specification). External references are in [SOURCES.md](#appendix-c-primary-source-register).

#### Implementation-specific values

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

### Colors

#### Light appearance

- `primary`: primary text, titles and schedule names.
- `secondary`: room, professor, date labels and supporting text; not disabled text.
- `tertiary`: selected controls, links and the primary action. It is not used to color every surface.
- `neutral`: app canvas; `surface`: grouped content and sheets.
- `error`: invalid input or an actionable problem, accompanied by text.
- `input-boundary`: interactive field boundaries where a visible boundary is necessary.
- `divider`: decorative separation only; never the sole outline identifying an essential control.

#### Dark appearance

Use `dark-canvas`, `dark-surface`, `dark-ink`, `dark-secondary`, `dark-accent` and `dark-on-accent` as a coherent set. Do not simply invert each light color. The bright blue dark-mode action has dark text; do not replace that text with white without another contrast check.

Category colors are optional accents, never the only way to identify School, Work, Personal or a custom category. Every category has a visible name and accessible label. Additional accent choices must ship as tested foreground/background pairs, not as an unrestricted color picker that can silently make text unreadable.

#### Contrast policy

Opaque text/background pairings must meet the text-contrast targets in the product specification. Transparent widgets are an explicit exception in capability, not an accessibility claim: arbitrary wallpaper is unknown, so a fixed translucent fill cannot guarantee contrast.

Provide **Clear**, **Soft tint** and **Solid accessible** widget treatments where supported. Offer light/dark text and stronger next-entry emphasis only when the platform can honor them. Respect the operating system's accessibility and rendering settings. When Reduce Transparency or an equivalent accessible treatment is requested, prefer the solid preset instead of preserving decoration.

### Typography

Use the native system font deliberately. In Flutter, inherit the platform theme rather than shipping SF Pro font files. Use tabular figures for schedule times where the platform supports them. Avoid all-caps body copy and very light text weights.

- Main date/page title: `h1`; never a full-screen hero.
- Schedule title: `body-emphasis`, with `h2` reserved for a focused detail view.
- Room, professor and subtitle: body or caption depending on density, not illegibly small text.
- Time column: `time`, aligned consistently and not distinguished by color alone.
- User font scaling takes precedence over the nominal sizes above. At large sizes, wrap, expand or switch to an agenda layout instead of clipping essential content.

Do not reduce all upcoming-entry text opacity until it becomes unreadable. The next entry should be stronger; upcoming entries must still be legible.

### Layout

- Default page gutters: `md`; use `lg` when screen width permits.
- Group related fields using `sm` or `md`; separate sections with `lg`.
- Timeline rows are content-sized. A row can show time, title, selected details and status, but is not a fixed-height decorative card.
- Use a three-destination app shell: **Today**, **Week**, **Settings**. Keep Add, Import and Share contextual; do not add one tab per action.
- A compact preview uses a bottom sheet. A long import or shared timetable uses a full review page with a persistent confirmation action.
- Mobile actions have at least a 48-logical-unit target, with platform-specific validation. Small SVG artwork may sit inside that larger target.
- The week grid must have an equivalent chronological agenda view for narrow screens, screen readers and large text.
- Sheets respect safe areas, keyboard insets and dismissal behavior. Unsaved edits require a clear discard decision.

#### Widget composition

1. No app-painted outer background in the requested Clear layout, where the native host permits it.
2. The next timed entry receives a brighter holder, stronger type and a more visible outline.
3. Upcoming entries receive quieter individual holders. Space between holders leaves wallpaper visible.
4. No wallpaper screenshot is copied into the widget. The user's wallpaper remains independent.
5. No artificial glowing frame, thick stroke, shimmer or perpetual animation.
6. Date-only entries use an explicit date/all-day label rather than an invented time.
7. A widget tap opens existing schedule details; it never creates a schedule or enables an alert.

The alpha values in the implementation-specific table are a starting hypothesis for a dark-wallpaper preview, not an implemented result. Test light, dark and busy wallpaper fixtures before choosing release values. On iOS, the native Clear/tinted rendering mode controls the material and can replace the requested background. Do not expose a cross-platform opacity slider that the platform cannot actually honor.

### Elevation & Depth

The default app surface is flat. Prefer background separation and spacing over shadows. Navigation may use a native translucent material if supported; content remains on a readable surface.

Widget **Clear** means no requested blur. **Soft tint** adds a translucent fill, not a promise of live wallpaper blur. A real native material may be used when the operating system provides it, but a Flutter backdrop filter is not assumed to work inside a home-screen widget.

Use a thin outline or a subtle text shadow only when it improves separation. Do not add multiple heavy shadows to imitate expensive glass. The solid accessible treatment is a first-class option, not an error state.

### Shapes

- Controls: `rounded.control`.
- App cards: `rounded.card`, used only for meaningful grouping.
- Bottom sheets: `rounded.sheet`, with native presentation behavior where practical.
- Pills: filters and selected states, not every label.
- Native widget outer shape: obey the host's clipping and corner behavior rather than assuming an arbitrary app radius.
- Widget holder radius: proposed 16 logical units, subject to native sizing and clipping tests.

### Components

#### Timeline row

Time and title are primary. Room, professor and subtitle are optional and hidden when absent. An ongoing entry may say **Now**; the next future timed entry may say **Next**. These labels must derive from actual occurrence times, never a seeded demonstration schedule.

If multiple entries overlap, show the simultaneous entries and an overlap indicator. Never silently pick one and hide the others.

#### Schedule editor

Progressively disclose **Details**, **Repeats** and **Reminders and alarms**. The title and date/time status are clear. Optional fields remain genuinely optional. Notification and alarm controls have independent desired settings and visible actual permission/scheduling states.

#### Image import review

Keep the source image available. Each proposed entry can be selected, edited or removed. Unreadable or missing values say **Needs review** or remain blank. Do not use a fabricated confidence percentage. An explicit confirmation is required before events, notifications or alarms are created.

#### Shared-link preview

Use **Preview**, **Edit before adding** and **Add selected schedules**. A long selection moves into a full-page review. The preview is read-only until the recipient edits their own draft. Never automatically save after opening a link.

#### Appearance controls

Start with a small set of tested presets. App and each widget can share appearance settings or be configured independently. Hide or explain unavailable native options. Separate app colors from the system's control of native widget glass/tint.

#### SVG assets

Use one curated icon family. Proposed family: Lucide, rendered from bundled SVG assets in Flutter. Preserve its upstream notices. Do not mix unrelated outline and filled sets by default. Native widgets receive equivalent approved native vector assets or build-time conversions, not an assumption that WidgetKit or Glance can run Flutter's SVG renderer.

Allowed core meanings: Today/calendar, week, add, image import, share, filter, room/location, person/professor, repeat, notification, alarm, appearance, edit, remove, confirm and close. Pair unfamiliar actions with text. Decorative SVGs are hidden from accessibility; actionable icon buttons have unique spoken labels.

#### Content and empty states

Only user-entered data, source-supported extracted candidates and approved interface copy belong in the product. No invented names, rooms, professors, schedules, metrics, testimonials or slogans. Test fixtures stay out of release storage.

Approved concise state labels include **No schedules yet**, **No schedules in this filter**, **Nothing else today**, **Needs review**, **Notifications are off**, **Alarm permission needed**, **Shared link expired**, and **Shared link unavailable**. Show only the state that is actually true.

### Do's and Don'ts

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

---

## Appendix B: Typed integration contracts

**Status:** proposed version 1.0 contracts for approval before code. These tables define payloads and behavior; they are not live API responses, generated data, database migrations or claims that endpoints exist.

Read [SCHEDULER_SPEC.md](#scheduling-app-pre-implementation-specification) for scope, platform limits, privacy and acceptance tests, and [DESIGN.md](#appendix-a-visual-system-and-design-tokens) for visual rules. If a table here conflicts with the main specification, resolve the inconsistency before implementation rather than silently choosing one.

### 1. Common conventions

- Wire field names use `camelCase`; local SQL names may use `snake_case` with explicit mapping.
- Contract version is a required string, initially `1.0`. Unknown major versions are rejected; optional-field compatibility must be explicitly tested.
- UUIDs are opaque valid identifiers generated through a vetted implementation, not display labels or security credentials.
- Calendar dates are validated `YYYY-MM-DD` values. Clock values are validated 24-hour `HH:mm` values. Pattern matching alone does not validate a real date.
- Timed schedules carry a valid IANA time-zone identifier. A fixed offset is not a replacement for a zone.
- Transport timestamps are UTC RFC 3339 values. Device clock time is not trusted as server creation/expiry authority.
- Optional known fields use explicit nullability. Unknown keys in security-sensitive payloads are rejected rather than silently interpreted as new capabilities.
- Preserve original user/source content. Validation must not repair malformed identifiers, guess dates or rewrite names to make a request pass.
- Text-length limits use Unicode code-point counts consistently on client and server; UTF-8 payload byte limits are enforced separately. Rendering must remain safe for combining marks, emoji and bidirectional text.
- Descriptions are plain text. No untrusted HTML, executable theme data or arbitrary remote SVG is accepted.
- Every list has an enforced maximum. Every recurrence query has a finite window and expansion cap.

### 2. Canonical schedule item

This shape is shared conceptually across manual events, validated imports and share snapshots. A local record adds local IDs/timestamps/alert rules; it must not accidentally serialize those private fields into a share.

| Field | Type | Required | Validation / meaning |
|---|---|---|---|
| `sourceItemId` | UUID string | Yes for import/share | Stable within the source snapshot; remap to a new local series ID on import |
| `revision` | Positive integer | Yes | Source revision, not an authorization claim |
| `title` | String | Yes | Nonempty, at most 120 code points |
| `categoryLabel` | String or null | Yes, nullable | Shared label only; never a trusted foreign local category ID |
| `time` | `TimedSpec` or `DateOnlySpec` | Yes | Discriminated union; required fields depend on kind |
| `recurrence` | `RecurrenceSpec` or null | Yes, nullable | Null for one-time entry |
| `details` | `DetailsSpec` | Yes | Nullable detail values; no filler text |
| `exceptions` | Array of `ExceptionSpec` | Yes | Empty is allowed; enforce configured count and uniqueness |

#### 2.1 TimedSpec

| Field | Type | Validation |
|---|---|---|
| `kind` | Literal `timed` | Discriminator |
| `startDate` | Calendar date | Seed date / earliest allowed recurrence date |
| `startTime` | Clock time | Explicitly resolved; not inferred from an unspecified date |
| `timeZone` | IANA zone string | Supported by the pinned zone database |
| `endTime` | Clock time or null | Null means explicitly no end time; do not invent a duration |
| `endDayOffset` | Nonnegative integer or null | Required with end time; null without it; recurring v1 supports same-day or next-day ending only |
| `seedTimeResolution` | `earlier`, `later` or null | Explicit resolution for an ambiguous seed instant; normal unambiguous times use null |

For a one-time multi-day timed event, any broader end-day range must be explicitly approved and bounded in implementation. Do not pretend the recurring subset already supports arbitrary multi-day recurrence.

Each recurrence uses local clock semantics in the source zone. A future ambiguous/nonexistent instance is unresolved unless an explicit valid occurrence override resolves it. Never silently use the device zone or carry forward a fixed UTC offset.

#### 2.2 DateOnlySpec

| Field | Type | Validation |
|---|---|---|
| `kind` | Literal `dateOnly` | Discriminator |
| `startDate` | Calendar date | Required known date |
| `endDateExclusive` | Calendar date | Must be after start; a single-date item ends on the following calendar date by representation, not by inventing a time |

No start time, UTC midnight, fixed offset or duration is inserted into date-only data. A reminder anchor time/zone belongs to the recipient's local alert rule, not the shared date-only item.

#### 2.3 RecurrenceSpec

| Field | Type | Validation |
|---|---|---|
| `frequency` | `daily` or `weekly` | Only supported v1 values |
| `interval` | Literal integer `1` | Advanced intervals are future scope unless the product decision changes |
| `weekdays` | Array of ISO weekday integers | Weekly: nonempty unique values from 1 through 7; daily: empty |
| `untilDateInclusive` | Calendar date or null | Not before seed start; null is unbounded recurrence definition, not permission for unbounded expansion |

The seed date limits the first occurrence. Weekly selection can begin on a later selected day. Display-week start is a preference, not a reason to reinterpret stored weekday identities. Unsupported count/month/year/complex recurrence fields are rejected with an editable explanation rather than dropped.

#### 2.4 DetailsSpec

| Field | Type | Bound / behavior |
|---|---|---|
| `location` | String or null | 240 code points |
| `professor` | String or null | 160 code points; optional for non-school use |
| `subtitle` | String or null | 240 code points |
| `notes` | String or null | 4,000 code points; may be excluded from a share |

Absence removes the corresponding display line. Empty optional input may be stored as null by an explicit schema rule; do not replace it with an invented room, instructor or subtitle.

#### 2.5 ExceptionSpec

| Field | Type | Meaning |
|---|---|---|
| `originalOccurrenceKey` | Validated structured identity/string | Refers to the original recurrence instance, not its moved time |
| `action` | `cancel` or `override` | Explicit operation |
| `replacement` | Complete resolved one-time item or null | Required for override; null for cancel; has no nested recurrence/exceptions |

The original key is scoped to the source series. On recipient import, remap it to the new local series identity without changing the referenced original occurrence. Duplicate exception keys are invalid.

An override must remain within supported time-kind behavior. Do not silently convert an entire weekly series when the user edits one instance. A whole-series change that invalidates exception keys requires a review/reconciliation step.

### 3. Local alert rule and native status

Alert preferences are local-only. They are not inherited from a shared snapshot unless the recipient explicitly creates their own rule during import.

#### 3.1 Desired rule

| Field | Type | Meaning |
|---|---|---|
| `id` | Local UUID | Stable local alert identity |
| `scope` | Series or occurrence identity | One entire rule or explicit occurrence override |
| `kind` | `notification` or `alarm` | Independent rules may coexist |
| `enabled` | Boolean | User preference, not OS permission status |
| `offsetMinutes` | Nonnegative integer | Zero is at the anchor; upper bound configured before release |
| `dateOnlyAnchorTime` | Clock time or null | Required for an enabled alert on a date-only item |
| `dateOnlyAnchorZone` | IANA zone or null | Required with a date-only anchor time |
| `lockScreenDetails` | `titleOnly` or `detailsRequested` | Requested disclosure; OS privacy remains authoritative |
| `presentationPreference` | `standard` or `prominentIfSupported` | Does not force an unsupported full-screen takeover |
| `snoozePreference` | Supported duration or null | Only offered where the native implementation can honor it |

Alarm lead times are calculated from actual occurrence instants using the selected zone. If the resulting trigger is already past, ask or leave it unscheduled; do not automatically ring on import.

#### 3.2 Actual scheduled request

| Field | Type | Meaning |
|---|---|---|
| `requestKey` | Stable opaque local key | Deterministic identity for rule + occurrence + platform |
| `sourceRevision` | Integer | Detects stale requests after edits |
| `nativeRequestId` | Platform opaque string or null | Only stored when returned/assigned by the adapter |
| `triggerAt` | UTC timestamp | Intended trigger, not a delivery receipt |
| `status` | Explicit enum | See states below |
| `errorCode` | Safe enum/string or null | User-visible category, not raw native/provider stack trace |
| `lastReconciledAt` | UTC timestamp | Diagnostic state |

States: `off`, `needsPermission`, `pendingSchedule`, `scheduled`, `blocked`, `failed`, `unscheduledCapacity`, `externalUnverified`, `cancelled`.

Mapping between camelCase contract state and local enum/storage names must be explicit. A Clock hand-off stays `externalUnverified`; it is not automatically promoted to `scheduled`. Native acceptance does not prove eventual ringing or override device settings.

#### 3.3 Reconciliation invariants

- Domain save + outbox insertion is one transaction.
- A retry uses the same request identity; it does not append a duplicate alarm.
- A changed occurrence invalidates obsolete requests before claiming the new state is scheduled.
- Filter changes affect visibility only; they do not enable/disable unrelated alert rules.
- Snooze changes only the supported alert's next action, never the schedule's start date/time.
- Capacity/horizon exhaustion is visible and tested, not hidden behind an enabled toggle.

### 4. Import candidate contract

Import candidates deliberately allow unresolved fields that the canonical active-schedule contract does not.

| Field | Type | Meaning |
|---|---|---|
| `candidateId` | Opaque unique string | Stable across edits/review within a draft |
| `sourceRevision` | Integer | Identifies the image/snapshot revision analyzed |
| `proposedItem` | Partial canonical fields | Missing values stay null/unresolved |
| `fieldEvidence` | Array of `FieldEvidence` | Source-backed context per field |
| `warnings` | Bounded array of typed warnings | Missing year/time, ambiguity, association, duplicate, overlap, unsupported pattern |
| `selectionState` | Local boolean | Recipient/user decision; not model authority |
| `reviewState` | `needsReview`, `ready`, `excluded` | Local validation status |

`FieldEvidence` contains field path, origin (`observed`, `userSupplied`, `inferredSuggestion`, `unresolved`), optional exact OCR span and optional validated image region. A region includes normalized coordinates and image revision/dimensions; invalid or unsupported coordinates are not drawn as if verified.

An inferred suggestion must be labelled. The model cannot mark its own output as user-confirmed. Do not expose model self-confidence as a calibrated percentage.

#### 4.1 Required unknown-field behavior

| Source condition | Contract result |
|---|---|
| Printed date has no year | Year unresolved; confirmation required |
| Weekdays but no term start | Series start unresolved until user supplies context |
| Time lacks AM/PM and is ambiguous | Unresolved choice, not guessed locale certainty |
| End time absent | Null end; explicit no-end/date-only choice where appropriate |
| Room/professor absent | Null fields; no generated fallback |
| Table alignment unclear | Association warning; candidate cannot silently become ready |
| No relevant schedule found | Honest empty result; not a fabricated candidate |
| Candidate count beyond configured limit | Explicit density/truncation problem and smaller-crop action |

#### 4.2 Import transaction

Input is a draft ID, selected candidate IDs, final validated items, category mappings and explicit local alert choices. Confirmed data is written once with provenance and reconciliation work. The transaction must reject duplicate submission or recover by looking up provenance after uncertain completion.

A failed alert API call after commit does not roll back already saved schedules without telling the user. It changes alert status and offers a targeted retry.

### 5. Share snapshot contract

#### 5.1 Shareable payload

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | Literal supported version string | Validated before parsing items |
| `items` | Bounded canonical-item array | Exactly the sender-approved selection |
| `sharedFieldPolicy` | Whitelisted field policy | Describes included/excluded optional details |

Server envelope adds snapshot ID/version, actual serialized item count, server creation/expiry and applicable availability state. Server-computed values are not trusted from the client.

Excluded by contract: source images, local file paths, owner/auth IDs, device IDs, native request IDs, active sender alert settings, hidden local schedules and unpublished drafts.

#### 5.2 Scope semantics

- `Current filter` uses selected categories; it does not secretly mean only the rows currently visible on today's screen.
- If a date-range scope is offered, it is a separate explicit choice with a clear preview.
- `All schedules` includes saved series/one-time records in the selected scope, including past/ended records unless excluded visibly.
- A series is serialized as a rule plus exceptions, not expanded indefinitely.
- The preview's count is computed from the actual validated payload. Never reuse a client/model-declared total without checking.

#### 5.3 Import semantics

Recipients create new local series IDs. Retain source snapshot/item/version provenance for repeated-import detection. Map category labels by choice. Preserve the time kind, source zone, recurrence and exceptions. Sender and recipient do not share editable database rows.

Exact source-identity duplicates default to skip, with an explicit keep-copy choice. Similar content/overlaps are warnings, not destructive automatic merges.

#### 5.4 Availability and token semantics

- A valid bearer token grants only the intended read-only preview.
- It is not a session credential, owner ID or permission to mutate the source.
- Expired/revoked/invalid tokens do not return personal payloads.
- Revocation does not reach into recipient-local imported copies.
- Already downloaded previews cannot be recalled, and a response authorized before revocation commits may still finish. Subsequent authorization must fail.
- Creator link metadata does not reconstruct a token from its hash.
- The client creates and protects at least 32 random secret bytes before creation, sends only the digest, and composes an HTTPS `/s/{shareId}#token={secret}` link from returned non-secret metadata. Fragment preservation is a native/web proof gate.
- The backend, management responses and idempotency records contain no raw secret or complete bearer URL. Replay returns the existing metadata, not a new capability. Expired replays fail safely instead of creating another resource under the old key.

### 6. Native widget snapshot contract

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | Version string | Native reader compatibility gate |
| `dataRevision` | Monotonic local revision | Prevents mixed old/new snapshots |
| `generatedAt` | UTC timestamp | Actual generation time |
| `widgetInstanceId` | Native opaque ID | Per-widget isolation |
| `timeZoneContext` | Validated zone/display context | Needed for actual date/time labels |
| `configuration` | Supported configuration values | Layout/filter/detail/appearance/privacy choices |
| `occurrences` | Bounded resolved list | Actual IDs, start/end/date-only values, selected visible details and status |
| `futureStates` | Bounded native timeline/update description | Only strategies the platform can honor |
| `coverageEnd` | Timestamp/date bound or null | Known data coverage, not a promise of continuous execution |
| `warnings` | Bounded typed list | Unresolved time, stale coverage or safe open-app state |

A snapshot has no provider key, backend bearer URL, full image or active editor draft. Native writers/readers use an atomic/versioned hand-off. An unsupported version yields a safe open-app state.

Widget configuration is scoped per native widget ID. Rendering respects current native appearance; requested alpha, colors or glass style are not a platform guarantee. Never repaint wallpaper from an image into a widget.

### 7. Backend request and response envelopes

#### 7.1 Safe error envelope

| Field | Type | Meaning |
|---|---|---|
| `code` | Stable machine-readable string | Transport/domain error category |
| `message` | Safe interface text | No secrets, private source text or provider stack trace |
| `requestId` | Opaque string | Correlates content-free diagnostics |
| `fieldErrors` | Optional bounded array | Field path + safe validation code |
| `retryable` | Boolean | A retry is permitted, not guaranteed to succeed |
| `retryAfterSeconds` | Optional nonnegative integer | Provided only when meaningful and safe |

Do not include a fake response body or pretend the provider was called when a job was rejected before execution.

#### 7.2 Share creation

Input: supported payload, expiry choice, client-generated token digest and an idempotency key. The client has already persisted the cryptographically random secret in protected storage. Server verifies identity, digest format, schema, limits and quota; computes actual counts/payload hash; commits the snapshot/link/idempotency outcome atomically or with a recoverable documented equivalent. It never receives the raw secret during creation.

Proposed create body fields: `schemaVersion`, `payload`, `tokenDigest`, `expiresAt`; `Idempotency-Key` is a header. `expiresAt` is validated against server policy/time, not trusted device time. The response contains `shareId`, `snapshotVersion`, `routePath`, `createdAt`, `expiresAt` and server-computed `itemCount`, never the raw token.

Token encoding is canonical unpadded base64url of exactly 32 random bytes. `tokenDigest` is the lowercase hexadecimal SHA-256 digest of those raw bytes, not of an arbitrarily normalized text representation. At redemption, enforce a small encoded-length/character bound, decode exactly 32 bytes, verify canonical re-encoding, then hash/compare. Reject malformed tokens before lookup; never silently repair a received link or token.

Output: created resource ID/version, non-secret route metadata and server expiry/count. The client composes the bearer URL using the retained secret. A repeated identical request returns the same resource outcome while replay remains valid. A changed body with the same key conflicts. No raw secret/complete bearer URL is needed in the replay cache.

Owner list output contains paginated metadata and a cursor. Do not claim `total` or `hasMore` unless computed from the actual authorized query. Revoke is idempotent and never mutates recipient copies.

An exact owner status endpoint supports revoke read-back before the app claims the link is revoked. Losing the local secret does not make a hash recoverable; offer an explicit replacement-link action when ownership still exists.

#### 7.3 Public resolve

Input: share ID, fragment-derived bearer token and supported schema versions, submitted in a redacted POST body. Output: only the permitted versioned snapshot and safe availability metadata. The resolver is read-only and rate-limited. It does not create an anonymous user, an import, a notification or a scan job.

Resolve body fields: `shareId`, `token`, `supportedSchemaVersions`. Only a matching capability may receive the payload or a known expired/revoked `410` state. Wrong/unknown capabilities and cross-owner management access do not expose owner metadata.

The fragment keeps the secret out of the ordinary HTTP route but not browser history, page scripts or application state. Do not log full incoming deep-link URIs. Demonstrate fragment preservation, no third-party scripts, no-store behavior and redaction before launch. Do not use a storage signed-download URL as a supposedly immediately revocable share capability.

#### 7.4 Cloud scan job

Input: an owned validated asset ID, consent context, requested interpretation mode, supported candidate schema and optional bounded OCR evidence. No arbitrary provider URL, executable instruction, model credential or trusted owner ID is accepted from the client.

States:

`queued -> running -> reviewReady | failed | cancelled | unknown`

A result is a review draft, not active schedules. Polling or reopening a completed job cannot run another paid provider request. Atomically reserve owner/global usage and concurrency before dispatch, with a consistent lock order and no database lock held during network work. An uncertain provider outcome stays `unknown` with a conservative reservation; do not repeat a possibly billed call without provider idempotency or verified reconciliation. A cancelled job may already have incurred usage.

Cloud images must meet the main specification's normalized JPEG/PNG byte, pixel and dimension limits. Benchmark bounded decoding in the actual runtime; use an isolated worker rather than assuming hosted edge CPU/memory limits can accommodate it.

Asset cleanup is scoped to app-controlled storage. Privacy copy must not turn an app-side deletion into a promise that third-party operational logs instantly disappear.

#### 7.5 Backend deletion

Input: authenticated identity and explicit confirmation scope. Output: deletion job/progress state. Revoke owned links, cancel owned pending jobs and clean private objects/results according to policy. Preserve local schedules unless a separate local deletion action was selected.

### 8. Validation and contract tests

Before implementation contracts are frozen:

- Test strict field/type/enum/date/zone and size validation on client and server.
- Test null/unresolved versus known optional values distinctly.
- Test scope/count consistency on the exact serialized snapshot.
- Test category mapping and source-ID remapping without cross-user mutation.
- Test canonical source identity/fingerprints with Unicode and identical times.
- Test future schema versions and malformed recurrence/exception relationships.
- Test owner A/owner B/public reads, writes, signed uploads and deletion attempts.
- Test idempotency crash/retry/expired-cache behavior, including secret response handling.
- Test source-image instructions as untrusted data, not executable authorization.
- Test widget schema changes and interrupted writes on native readers.
- Test alert desired/actual state divergence and honest UI after API/permission failure.

Implementation should generate or share schema definitions from these approved contracts and run cross-language fixtures. No production API, payload or test result is fabricated by this document.

---

## Appendix C: Primary-source register

**Checked during specification preparation:** October 18, 2026. Numbers below are assigned by the citation ledger, not invented from memory. Sources document capabilities and limits; they do not prove this app works on a device. Product requirements come from the conversation.

### Sources

[1] https://docs.flutter.dev/app-architecture/guide — Flutter: Guide to app architecture
[2] https://riverpod.dev/docs/concepts2/providers — Riverpod: Providers
[3] https://drift.simonbinder.eu/migrations — Drift: Migrations
[4] https://pub.dev/packages/go_router — Flutter: go_router package
[5] https://pub.dev/packages/home_widget — home_widget: Package documentation
[6] https://pub.dev/packages/flutter_svg — Flutter: flutter_svg package
[7] https://github.com/lucide-icons/lucide — Lucide: Official repository and license
[8] https://developers.google.com/ml-kit — Google ML Kit: Overview
[9] https://developers.google.com/ml-kit/vision/text-recognition/v2 — Google ML Kit: Text recognition v2
[10] https://developer.apple.com/videos/play/wwdc2025/278 — Apple WWDC25: What’s new in widgets
[11] https://developer.android.com/about/versions/12/features/widgets — Android: Android 12 widget improvements
[12] https://developer.android.com/guide/components/intents-common — Android: Common intents—Alarm clock
[13] https://developer.apple.com/videos/play/wwdc2025/230 — Apple WWDC25: Wake up to the AlarmKit API
[14] https://developer.android.com/develop/ui/views/notifications/build-notification — Android: Create a notification
[15] https://support.google.com/googleplay/android-developer/answer/13392821?hl=en — Google Play: Foreground service and full-screen intent requirements
[16] https://ai.google.dev/gemini-api/terms — Google: Gemini API Additional Terms of Service
[17] https://ai.google.dev/gemini-api/docs/api-key — Google: Gemini API key security
[18] https://docs.flutter.dev/cookbook/navigation/set-up-universal-links — Flutter: Set up universal links for iOS
[19] https://docs.flutter.dev/cookbook/navigation/set-up-app-links — Flutter: Set up app links for Android
[20] https://www.w3.org/TR/WCAG22 — W3C: Web Content Accessibility Guidelines 2.2
[21] https://supabase.com/docs/guides/auth/auth-anonymous — Supabase: Anonymous sign-ins
[22] https://supabase.com/docs/guides/database/postgres/row-level-security — Supabase: Row Level Security and grants
[23] https://supabase.com/docs/guides/functions/auth — Supabase: Edge Function authentication
[24] https://supabase.com/docs/guides/storage/serving/downloads — Supabase: Storage downloads and signed URL revocation
[25] https://supabase.com/docs/guides/functions/limits — Supabase: Edge Function runtime limits
[26] https://developer.android.com/develop/background-work/services/alarms — Android: Schedule alarms
[27] https://developer.android.com/about/versions/15/behavior-changes-all — Android 15: Behavior changes for all apps
[28] https://pub.dev/packages/flutter_local_notifications — flutter_local_notifications: Maintainer documentation and limitations
[29] https://docs.flutter.dev/platform-integration/ios/setup — Flutter: Set up iOS development
[30] https://www.rfc-editor.org/rfc/rfc3986 — IETF RFC 3986: URI Generic Syntax, fragments
[31] https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date — Apple WidgetKit: Keeping a widget up to date
[32] https://developer.android.com/develop/ui/views/appwidgets/advanced — Android: Create an advanced widget
[33] https://developer.android.com/about/versions/14/changes/schedule-exact-alarms — Android 14: Exact alarm permission changes
[34] https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html — OWASP: File Upload Cheat Sheet
[35] https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html — OWASP: LLM Prompt Injection Prevention Cheat Sheet

### Interpretation boundaries

- [1] supplies architectural separation, not a mandate to use the proposed state-management package.
- [2]–[6] are primary maintainer/package references. Compatibility, versions, licenses and native requirements still need a dependency freeze before scaffold work.
- [7] establishes the icon source/license; it does not mean the final icon assets have been selected or shipped.
- [8]–[9] describe on-device OCR and its text structure. They do not guarantee poster/timetable-to-schedule accuracy.
- [10]–[11] support the native widget appearance caveats. Clear materials, tinting and host clipping must be tested on real target devices.
- [12] describes Android Clock hand-off. It does not establish two-way sync, default-Clock read access, arbitrary dated-event support or proof that another app created an alarm.
- [13] describes app-owned AlarmKit behavior and consent. It is not an approval to claim Apple Clock synchronization or an arbitrary custom full-screen takeover.
- [14]–[15] establish Android prominent-alert behavior and release-policy checks. They are not evidence that this scheduler already qualifies or has permissions.
- [16] is relevant to audience/minor eligibility and free/paid data handling. No AI provider is approved by this specification; contract and privacy decisions remain launch gates.
- [17] supports keeping privileged API credentials out of mobile/web client builds.
- [18]–[19] describe domain-associated mobile links. They do not provide automatic post-install deferred-link restoration.
- [20] supports contrast/accessibility targets for known backgrounds. A translucent widget over arbitrary wallpaper has no universal fixed contrast guarantee.

No forum-user bug report, marketing claim, archived snapshot or made-up benchmark is used as proof of platform behavior. All latency, limits, visual alpha values, retention settings and architecture choices labelled proposed remain proposed until validated/approved.

### Additional reviewed constraints

- [21]–[23] establish anonymous-role, ownership, RLS/grants and function-auth distinctions. A privileged server client needs explicit owner/capability checks; enabling RLS alone is not proof of safe service-role code.
- [24] distinguishes storage signed URLs from an application-revocable share capability. [25] establishes runtime limits that require image-decoder benchmarking or an isolated worker.
- [26]–[28] cover native alarm lifecycle, Android force-stop effects and the notification maintainer's iOS pending-request limit. The documented notification limit is not an AlarmKit quota or a promise of indefinite unattended coverage.
- [29] supports iOS build/tooling requirements; no iOS device or build was tested by this documentation task.
- [30] supports fragment separation from HTTP dereferencing. A fragment is still visible to the user agent/page/application; it is not end-to-end encryption or a substitute for safe scripts, local storage and log handling.
- [31]–[33] cover widget scheduling budgets and exact-alarm permissions. Documented budget examples are not an app delivery or repaint guarantee.
- [34]–[35] support bounded-upload and untrusted-model-input controls. They do not certify the security of an unbuilt decoder, backend or AI workflow.

Two independent planning reviews were integrated. The parent also retrieved the relevant primary documents. Their recommendations are design review, not deployed access-control, decoder, device or provider test results.

---

## Appendix D: Documentation validation

**Prepared:** October 18, 2026.  
**Scope:** specification files only. No app implementation, deployment or real-device test is implied.

### Current status

The specification, typed contracts and design system are written. Independent native-platform and backend/security planning reviews have been integrated, and the parent retrieved the relevant primary references. Design lint, structural checks and citation-register verification have passed. The product remains a draft for user approval, not an implemented or certified app.

### Checks actually run

#### Design-system linter

Executed the published `@google/design.md` CLI at pinned version `0.4.0` using its Windows-safe `designmd` alias.

The latest completed lint returned:

- Errors: **0**.
- Warnings: **0**.
- Informational token summary: **16 colors, 6 typography scales, 4 rounding levels, 6 spacing tokens, 13 components**.

An earlier pass identified unused decorative tokens and a custom extension map ignored by the exporter. The document was corrected: decorative tokens are referenced, and platform-specific widget/motion values are explicitly normative prose rather than falsely assumed to be exported.

#### Opaque contrast calculations

Calculated with the sRGB relative-luminance formula in Python, not estimated visually. These are known opaque foreground/background pairs only:

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

Transparent widgets over arbitrary wallpaper are **not contrast-certified** by these calculations or by the token linter. Their native material, readability and accessible fallback need device testing.

#### Structural and citation checks

A Python checker actually parsed the saved Markdown after the independent reviews were integrated. It found:

- **24** unique sequential requirement IDs.
- **48** unique sequential acceptance-test IDs.
- **35** registered/cited source IDs, with no undefined source or acceptance reference.
- Balanced code fences and valid main table-of-contents anchors.
- Existing relative document links and no unfinished implementation placeholders.

The citation-ledger verifier also completed with **citations OK** in strict mode. This checks reference mapping and citation structure; it does not prove every proposed engineering decision through research or run any acceptance scenario.

#### Independent review changes incorporated

- Explicit Android exact/repeating-alarm, force-stop and native widget refresh constraints.
- A distinction between the notification maintainer's pending-request limit and AlarmKit capacity.
- Client-held share secrets, fragment-based links, digest-only persistence and secret-free creation replay; native fragment handling remains a future proof gate.
- Anonymous-role/service-client authorization risks, runtime image-decoder limits, revoke/resolve races, and downloaded-preview revocation limits.
- Conservative usage reservation and an `unknown` scan state instead of automatically repeating a possibly billed provider request.

These are planning and source-review outcomes. No child-agent in-memory model or self-report is represented as a deployed security or native-device test.

### Not tested or claimed

- Flutter compilation or mobile screen rendering.
- Native Android/iOS widget transparency, refresh budgets, launcher clipping or multiple widget instances.
- Actual reminder/alarm delivery, exact scheduling, full-screen permission or Clock-app behavior.
- Backend deployment, RLS enforcement, signed-storage access, quota handling or data deletion.
- Live AI requests, image-recognition accuracy, latency or cost.
- App-store policy approval, privacy/legal approval, authentication recovery or production security certification.
- User approval of proposed defaults or unresolved product decisions.

### Verification boundary

The implementation plan and acceptance matrix describe future tests. They are not fabricated passing results. Files and lint/static checks are the only completed artifacts at this stage.
