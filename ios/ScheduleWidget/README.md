# iOS widget and alarms — setup (untested)

The iOS widget and AlarmKit code was written on Windows without Xcode, so it has not been built or run. Build and check it on a Mac before relying on it.

## Add the widget extension

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target → Widget Extension**. Name it `ScheduleWidget`. Leave **Include Live Activity** and **Include Configuration App Intent** unchecked. Embed it in `Runner`.
3. Set the extension's deployment target to iOS 17.0, the same as `Runner`.
4. Delete the Swift files Xcode generated for the extension. Add `ios/ScheduleWidget/ScheduleWidget.swift` to the `ScheduleWidget` target only.
5. In **Signing & Capabilities**, add **App Groups** to both `Runner` and `ScheduleWidget`. Use `group.com.manalogadiel.schediel` for both.

The widget reads the snapshot that Flutter writes with `home_widget` under `schediel_widget_snapshot` in that App Group. The widget kind `ScheduleWidget` must match `iOSWidgetKind` in `lib/features/widgets/application/widget_snapshot_service.dart`.

## Alarms

- App-owned alarms use AlarmKit. AlarmKit needs iOS 26 or later and the Xcode 26 SDK.
- With older SDKs, the AlarmKit code in `ios/Runner/AppDelegate.swift` is compiled out.
- Below iOS 26, the app reports alarms as unavailable and keeps notification reminders.
- `NSAlarmKitUsageDescription` is in `ios/Runner/Info.plist`.

## Check on a device

- Widget timeline: Now, Next and Upcoming change at start and end times, at midnight, and at coverage end.
- Taps on an entry open that occurrence; other taps open Today.
- Clear, soft tint and solid surfaces display correctly, including the system's tinted and clear home screen styles.
- Alarm permission: test allowed, denied and not yet asked.
- An alarm rings at its time. Stop does not change the schedule.
