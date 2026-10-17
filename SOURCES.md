# Primary-source register

**Checked during specification preparation:** October 18, 2026. Numbers below are assigned by the citation ledger, not invented from memory. Sources document capabilities and limits; they do not prove this app works on a device. Product requirements come from the conversation.

## Sources

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

## Interpretation boundaries

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

## Additional reviewed constraints

- [21]–[23] establish anonymous-role, ownership, RLS/grants and function-auth distinctions. A privileged server client needs explicit owner/capability checks; enabling RLS alone is not proof of safe service-role code.
- [24] distinguishes storage signed URLs from an application-revocable share capability. [25] establishes runtime limits that require image-decoder benchmarking or an isolated worker.
- [26]–[28] cover native alarm lifecycle, Android force-stop effects and the notification maintainer's iOS pending-request limit. The documented notification limit is not an AlarmKit quota or a promise of indefinite unattended coverage.
- [29] supports iOS build/tooling requirements; no iOS device or build was tested by this documentation task.
- [30] supports fragment separation from HTTP dereferencing. A fragment is still visible to the user agent/page/application; it is not end-to-end encryption or a substitute for safe scripts, local storage and log handling.
- [31]–[33] cover widget scheduling budgets and exact-alarm permissions. Documented budget examples are not an app delivery or repaint guarantee.
- [34]–[35] support bounded-upload and untrusted-model-input controls. They do not certify the security of an unbuilt decoder, backend or AI workflow.

Two independent planning reviews were integrated. The parent also retrieved the relevant primary documents. Their recommendations are design review, not deployed access-control, decoder, device or provider test results.
