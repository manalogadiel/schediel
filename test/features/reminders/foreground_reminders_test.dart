import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/app.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/reminders/application/alert_planner.dart';
import 'package:schediel/features/reminders/application/foreground_reminders.dart';
import 'package:schediel/features/reminders/data/notification_gateway.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/integrations/native/native_bridge.dart';

import '../../support/harness.dart';

class RecordingBridge extends NativeBridge {
  final stopped = <String>[];

  @override
  Future<bool> stopAlarm(String requestKey) async {
    stopped.add(requestKey);
    return true;
  }
}

ScheduledAlertRow row(
  String kind,
  DateTime trigger, {
  String series = 's1',
  String key = '2026-11-02',
  String status = 'scheduled',
}) =>
    ScheduledAlertRow(
      requestKey: 'r-$kind|$series/$key|android',
      ruleId: 'r-$kind',
      seriesId: series,
      occurrenceKey: key,
      kind: kind,
      platform: 'android',
      sourceRevision: 1,
      nativeRequestId: null,
      triggerAt: trigger,
      status: status,
      errorCode: null,
      lastReconciledAt: trigger,
    );

void main() {
  final t0 = DateTime.utc(2026, 11, 2, 0, 50);

  group('remindersDue', () {
    test('includes only scheduled reminders and alarms that came due in the window', () {
      final due = remindersDue([
        row('notification', t0),
        row('notification', t0.add(const Duration(minutes: 1)), series: 'later'),
        row('notification', t0.subtract(const Duration(minutes: 1)), series: 'earlier'),
        row('alarm', t0, series: 'blocked', status: 'needsPermission'),
        row('clock', t0, series: 'clock', status: 'externalUnverified'),
      ], since: t0.subtract(const Duration(minutes: 1)), now: t0);
      expect(due.map((d) => d.seriesId), ['s1']);
      expect(due.single.kind, 'notification');
    });

    test('shows one page per occurrence and prefers the alarm', () {
      final due = remindersDue([row('notification', t0), row('alarm', t0)],
          since: t0.subtract(const Duration(minutes: 1)), now: t0);
      expect(due, hasLength(1));
      expect(due.single.kind, 'alarm');
      expect(due.single.requestKey, 'r-alarm|s1/2026-11-02|android');
    });
  });

  group('ForegroundReminderTracker', () {
    test('reports nothing while the app is not in the foreground', () {
      final tracker = ForegroundReminderTracker();
      expect(tracker.tick(t0, [row('alarm', t0)]), isEmpty);
    });

    test('reports reminders due after resuming, once', () {
      final tracker = ForegroundReminderTracker()..resumed(t0.subtract(const Duration(minutes: 5)));
      final rows = [row('alarm', t0)];
      expect(tracker.tick(t0.subtract(const Duration(minutes: 1)), rows), isEmpty);
      expect(tracker.tick(t0, rows), hasLength(1));
      expect(tracker.tick(t0.add(const Duration(minutes: 1)), rows), isEmpty);
    });

    test('does not replay reminders that fired while in the background', () {
      final tracker = ForegroundReminderTracker()..resumed(t0.subtract(const Duration(minutes: 5)));
      tracker.paused();
      tracker.resumed(t0.add(const Duration(minutes: 1)));
      expect(tracker.tick(t0.add(const Duration(minutes: 2)), [row('alarm', t0)]), isEmpty);
    });
  });

  group('reminder page', () {
    Future<String> addClass(TestHarness h) => h.run(() => h.read(scheduleRepositoryProvider).create(ScheduleDraft(
          title: 'Fixture class',
          time: TimedSpec(
            startDate: LocalDate(2026, 11, 2),
            startTime: LocalTime(9, 0),
            timeZone: 'Asia/Manila',
            endTime: LocalTime(10, 30),
            endDayOffset: 0,
          ),
          details: const ScheduleDetails(location: 'Fixture room', professor: 'Fixture person'),
        )));

    final bridge = RecordingBridge();
    appTest('an alarm page shows the schedule and Stop stops only the alarm', (h) async {
      final id = await addClass(h);
      h.read(routerProvider).push('/reminder/$id/2026-11-02?kind=alarm&request=${Uri.encodeComponent('k1')}');
      await h.settle();
      expect(find.text('Fixture class'), findsOneWidget);
      expect(textContaining('9:00'), findsWidgets);
      expect(find.text('Fixture room'), findsOneWidget);
      expect(find.text('Fixture person'), findsOneWidget);
      await h.tapText('Stop');
      expect(bridge.stopped, ['k1']);
      expect(find.text('Stop'), findsNothing);
      expect(await h.run(() => h.read(scheduleRepositoryProvider).loadAll()), hasLength(1));
    }, bridge: bridge);

    final gateway = FakeNotificationGateway();
    appTest('a reminder page dismisses its notification', (h) async {
      final id = await addClass(h);
      gateway.scheduled[notificationIdFor('k2')] = NotificationRequest(
        id: notificationIdFor('k2'),
        requestKey: 'k2',
        triggerAt: DateTime.utc(2026, 11, 2, 0, 50),
        title: 'Fixture class',
        body: '',
        payload: 'schediel://occurrence/$id/2026-11-02',
      );
      h.read(routerProvider).push('/reminder/$id/2026-11-02?kind=notification&request=k2');
      await h.settle();
      await h.tapText('Done');
      expect(gateway.scheduled, isEmpty);
    }, gateway: gateway);

    appTest('a missing schedule shows an honest state', (h) async {
      h.read(routerProvider).push('/reminder/missing/2026-11-02?kind=alarm&request=k3');
      await h.settle();
      expect(find.text('Schedule no longer available'), findsOneWidget);
      await h.tapText('Close');
      expect(find.text('Schedule no longer available'), findsNothing);
    }, bridge: RecordingBridge());
  });
}
