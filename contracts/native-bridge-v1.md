# Native bridge contract, version 1

Implementation contract between the Flutter app and its Android (Kotlin) and iOS (Swift) code. It realizes SCHEDULER_SPEC.md sections 7 and 12 and CONTRACTS.md sections 3 and 6. Any change is a contract change: update this file, the Dart adapter (`lib/integrations/native/native_bridge.dart`) and both platforms together.

## Channel

- `MethodChannel('com.manalogadiel.schediel/native')`, standard method codec.
- All methods are idempotent and never throw for expected states; they return typed status strings. Unexpected native failures map to `PlatformException(code: 'native_error')` without user content in the message.
- Native code never logs schedule titles, details, notes or deep links.

## Capability model

`getCapabilities()` returns a map:

| Key | Type | Android | iOS |
|---|---|---|---|
| `platform` | String | `android` | `ios` |
| `osVersion` | String | `Build.VERSION.RELEASE` | `UIDevice.current.systemVersion` |
| `apiLevel` | int or null | `Build.VERSION.SDK_INT` | null |
| `exactAlarms` | String | `authorized` / `denied` (API 31+ `canScheduleExactAlarms()`), `notRequired` below API 31 | `unavailable` |
| `appAlarms` | String | `authorized` when exact alarms are authorized or not required and the alarm can be presented (notifications enabled, alarm channel not blocked), else `denied` | AlarmKit on iOS 26+: `authorized` / `denied` / `notDetermined`; below iOS 26: `unavailable` |
| `fullScreen` | String | API 34+: `authorized` / `denied` (`canUseFullScreenIntent()`); below 34: `authorized` | `unavailable` (presentation is system-controlled) |
| `externalClock` | bool | an activity resolves `AlarmClock.ACTION_SET_ALARM` | false |

Notification authorization is read and requested on the Dart side through `flutter_local_notifications`, not through this channel.

## Methods

| Method | Arguments | Result |
|---|---|---|
| `getCapabilities` | none | capability map above |
| `requestAppAlarmAuthorization` | none | iOS 26+: AlarmKit authorization result (`authorized` / `denied` / `notDetermined`); otherwise the current `appAlarms` value without UI |
| `openSystemSettings` | `{target: 'exactAlarms' \| 'fullScreen' \| 'notifications' \| 'app'}` | bool: a settings screen was opened |
| `scheduleAlarms` | `{alarms: [AlarmRequest], horizonEndEpochMs: int}` | `[AlarmResult]` in request order |
| `cancelAllAlarms` | none | int: number cancelled |
| `stopAlarm` | `{requestKey: String}` | bool: an alarm with that key was stopped, or cancelled before ringing. Used by the in-app reminder page; never changes schedule data |
| `getScheduledAlarms` | none | `[String]` request keys native currently holds |
| `launchClockAlarm` | `{hour: int, minute: int, message: String, weekdays: [int] or null}` | `launched` / `unavailable` / `failed` |

### AlarmRequest

| Field | Type | Rule |
|---|---|---|
| `requestKey` | String | Deterministic `rule/occurrence/platform` identity from Dart, at most 160 characters |
| `triggerAtEpochMs` | int | Absolute trigger instant |
| `title` | String | Schedule title, at most 120 code points |
| `body` | String | Time and permitted details, already filtered by the rule's lock-screen preference |
| `deepLink` | String | `schediel://occurrence/{seriesId}/{originalKey}` |
| `snoozeMinutes` | int or null | 1 to 30 when snooze is offered; null hides snooze |
| `prominent` | bool | Request full-screen presentation where permitted |

`scheduleAlarms` has replace-all semantics: after the call, native holds exactly the given set. Requests whose trigger is not in the future return `pastTrigger` and are not scheduled. Native persists the accepted set so it can re-arm after reboot (Android) without starting Flutter.

### AlarmResult

`{requestKey: String, status: 'scheduled' | 'needsPermission' | 'pastTrigger' | 'failed', errorCode: String or null}`. `scheduled` means the OS accepted the request; it does not prove later ringing.

### Clock hand-off (Android only)

`launchClockAlarm` starts `AlarmClock.ACTION_SET_ALARM` with `EXTRA_HOUR`, `EXTRA_MINUTES`, `EXTRA_MESSAGE` and, when weekdays are given, `EXTRA_DAYS` mapped from ISO weekdays (1 = Monday) to `java.util.Calendar` constants. `launched` only means the intent started; the app records `externalUnverified` and never claims the Clock alarm exists.

## Alarm presentation

- Android: `AlarmManager.setAlarmClock` one-shot requests with stable request codes derived from `requestKey`. The receiver posts a notification on the `schediel_alarms` channel (alarm audio usage, high importance) with a full-screen intent to the native alarm activity when `prominent` is true and full-screen access is authorized; otherwise a heads-up notification. The activity shows the title, time and the permitted body with Stop and, when allowed, Snooze. Stop and Snooze never modify schedule data. Snooze re-arms one native request `snoozeMinutes` later under the same request key. Open launches `MainActivity` with `ACTION_VIEW` and the deep link.
- iOS 26+: AlarmKit alarms with the title as the system alarm label; system UI is authoritative. Below iOS 26 the method results are `failed` with `errorCode: 'unavailable'` and the Dart side keeps notification reminders.

## Widget data hand-off

- Dart writes the snapshot JSON (`contracts/schemas/widget-snapshot-v1.schema.json`) with `HomeWidget.saveWidgetData<String>('schediel_widget_snapshot', json)` and then calls `HomeWidget.updateWidget(qualifiedAndroidName: 'com.manalogadiel.schediel.widget.ScheduleWidgetProvider', iOSName: 'ScheduleWidget')`.
- iOS uses the App Group `group.com.manalogadiel.schediel` (`HomeWidget.setAppGroupId`).
- Widget entry taps open `schediel://occurrence/{seriesId}/{originalKey}`; other taps open the app. The Dart side receives widget launches through `home_widget`.
- Readers follow `x-readerRules` in the schema and the fixtures in `contracts/fixtures/widget-snapshot-cases.json`.

## Internal deep links

- `schediel://occurrence/{seriesId}/{originalKey}` opens existing occurrence details or the honest "Schedule no longer available" state.
- `schediel://today` opens Today.
- These links never create schedules, enable alerts or import data.
