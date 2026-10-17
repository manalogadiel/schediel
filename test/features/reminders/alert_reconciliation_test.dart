import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/reminders/application/alert_planner.dart';
import 'package:schediel/features/reminders/application/alert_reconciler.dart';
import 'package:schediel/features/reminders/application/capabilities.dart';
import 'package:schediel/features/reminders/domain/alert_rule.dart';
import 'package:schediel/integrations/native/native_bridge.dart';

import '../../support/harness.dart' show FakeNotificationGateway;

class FakeBridge extends NativeBridge {
  NativeCapabilities caps = const NativeCapabilities(
    platform: 'android',
    osVersion: '15',
    apiLevel: 35,
    exactAlarms: CapabilityStatus.authorized,
    appAlarms: CapabilityStatus.authorized,
    fullScreen: CapabilityStatus.authorized,
    externalClock: true,
  );
  List<AlarmRequest> held = [];

  @override
  Future<NativeCapabilities> getCapabilities() async => caps;

  @override
  Future<List<AlarmResult>> scheduleAlarms(List<AlarmRequest> alarms, DateTime horizonEnd) async {
    held = alarms;
    return [for (final a in alarms) AlarmResult(a.requestKey, AlarmResultStatus.scheduled, null)];
  }
}

void main() {
  late ZoneResolver zones;
  late AlertPlanner planner;
  final now = DateTime.utc(2026, 11, 2, 0, 0); // 08:00 in Manila

  setUpAll(() {
    zones = ZoneResolver.initialized();
    planner = AlertPlanner(zones, OccurrenceEngine(zones));
  });

  ScheduleSeries weekly({List<OccurrenceException> exceptions = const []}) => ScheduleSeries(
        id: 's1',
        revision: 3,
        title: 'Fixture class',
        time: TimedSpec(
          startDate: LocalDate(2026, 11, 2),
          startTime: LocalTime(9, 0),
          timeZone: 'Asia/Manila',
          endTime: LocalTime(10, 0),
          endDayOffset: 0,
        ),
        recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [1, 3]),
        details: const ScheduleDetails(location: 'Fixture room', professor: 'Fixture person'),
        exceptions: exceptions,
      );

  AlertRule rule(AlertKind kind, {int offset = 10, bool enabled = true, LockScreenDetails lock = LockScreenDetails.titleOnly}) =>
      AlertRule(
        id: 'r-${kind.name}',
        seriesId: 's1',
        preference: AlertPreference(kind: kind, enabled: enabled, offsetMinutes: offset, lockScreenDetails: lock),
      );

  PlanInput input(List<ScheduleSeries> series, List<AlertRule> rules, {int capacity = 48}) => PlanInput(
        series: series,
        rules: rules,
        now: now,
        zone: 'Asia/Manila',
        horizon: const Duration(days: 14),
        capacity: capacity,
        platform: 'android',
        use24h: true,
      );

  test('derives future triggers from actual occurrence instants and offsets', () {
    final plan = planner.plan(input([weekly()], [rule(AlertKind.notification)]), AlertKind.notification);
    expect(plan.requests.first.triggerAt, DateTime.utc(2026, 11, 2, 0, 50));
    expect(plan.requests.first.requestKey, 'r-notification|s1/2026-11-02|android');
    expect(plan.requests.first.deepLink, 'schediel://occurrence/s1/2026-11-02');
    expect(plan.requests.map((r) => r.occurrenceKey.toIso()),
        ['2026-11-02', '2026-11-04', '2026-11-09', '2026-11-11']);
    expect(plan.overflow, isEmpty);
  });

  test('never schedules a trigger that is already past', () {
    final plan = planner.plan(input([weekly()], [rule(AlertKind.notification, offset: 120)]), AlertKind.notification);
    expect(plan.requests.first.occurrenceKey, LocalDate(2026, 11, 4));
  });

  test('skips cancelled occurrences and disabled rules', () {
    final s = weekly(exceptions: [OccurrenceException(originalKey: LocalDate(2026, 11, 4), action: ExceptionAction.cancel)]);
    final plan = planner.plan(input([s], [rule(AlertKind.notification)]), AlertKind.notification);
    expect(plan.requests.map((r) => r.occurrenceKey.toIso()), isNot(contains('2026-11-04')));
    expect(planner.plan(input([s], [rule(AlertKind.notification, enabled: false)]), AlertKind.notification).requests, isEmpty);
  });

  test('keeps the nearest requests within capacity and reports the rest', () {
    final plan = planner.plan(input([weekly()], [rule(AlertKind.notification)], capacity: 2), AlertKind.notification);
    expect(plan.requests, hasLength(2));
    expect(plan.overflow, hasLength(2));
    expect(plan.requests.last.triggerAt.isBefore(plan.overflow.first.triggerAt), isTrue);
  });

  test('uses the chosen clock time for all-day schedules', () {
    final allDay = ScheduleSeries(
      id: 's1',
      revision: 1,
      title: 'Fixture deadline',
      time: DateOnlySpec(startDate: LocalDate(2026, 11, 5), endDateExclusive: LocalDate(2026, 11, 6)),
    );
    final r = AlertRule(
      id: 'r1',
      seriesId: 's1',
      preference: AlertPreference(
        kind: AlertKind.notification,
        enabled: true,
        offsetMinutes: 30,
        dateOnlyAnchorTime: LocalTime(9, 0),
        dateOnlyAnchorZone: 'Asia/Manila',
      ),
    );
    final plan = planner.plan(input([allDay], [r]), AlertKind.notification);
    expect(plan.requests.single.triggerAt, DateTime.utc(2026, 11, 5, 0, 30));
  });

  test('lock-screen preference controls which details enter the body', () {
    final titleOnly = planner.plan(input([weekly()], [rule(AlertKind.notification)]), AlertKind.notification);
    expect(titleOnly.requests.first.body, '09:00 – 10:00');
    final details = planner.plan(
        input([weekly()], [rule(AlertKind.notification, lock: LockScreenDetails.detailsRequested)]), AlertKind.notification);
    expect(details.requests.first.body, '09:00 – 10:00 · Fixture room · Fixture person');
  });

  group('reconciler', () {
    late AppDatabase db;
    late FakeNotificationGateway gateway;
    late FakeBridge bridge;
    late AlertReconciler reconciler;
    var series = <ScheduleSeries>[];
    var rules = <AlertRule>[];

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory(), clock: () => now);
      gateway = FakeNotificationGateway();
      bridge = FakeBridge();
      series = [weekly()];
      rules = [rule(AlertKind.notification), rule(AlertKind.alarm, offset: 0)];
      reconciler = AlertReconciler(
        db: db,
        planner: planner,
        gateway: gateway,
        bridge: bridge,
        loadSeries: () async => series,
        loadRules: () async => rules,
        clock: () => now,
        zone: () => 'Asia/Manila',
        use24h: () => true,
      );
    });

    tearDown(() => db.close());

    test('schedules accepted requests and records their status', () async {
      final summary = await reconciler.reconcile(DeviceCapabilities(notifications: CapabilityStatus.authorized, native: bridge.caps));
      expect(gateway.scheduled, hasLength(4));
      expect(bridge.held, hasLength(4));
      expect(summary.scheduled[AlertKind.notification], 4);
      final rows = await db.select(db.scheduledAlerts).get();
      expect(rows.where((r) => r.status == 'scheduled'), hasLength(8));
    });

    test('is idempotent and cancels requests that are no longer desired', () async {
      final caps = DeviceCapabilities(notifications: CapabilityStatus.authorized, native: bridge.caps);
      await reconciler.reconcile(caps);
      final firstIds = gateway.scheduled.keys.toSet();
      await reconciler.reconcile(caps);
      expect(gateway.scheduled.keys.toSet(), firstIds);

      series = [weekly(exceptions: [OccurrenceException(originalKey: LocalDate(2026, 11, 4), action: ExceptionAction.cancel)])];
      await reconciler.reconcile(caps);
      expect(gateway.scheduled, hasLength(3));
      expect(bridge.held.map((a) => a.requestKey), isNot(contains('r-alarm|s1/2026-11-04|android')));

      rules = [];
      await reconciler.reconcile(caps);
      expect(gateway.scheduled, isEmpty);
      expect(bridge.held, isEmpty);
      expect(await db.select(db.scheduledAlerts).get(), isEmpty);
    });

    test('records needsPermission instead of claiming success', () async {
      gateway.status = CapabilityStatus.denied;
      final summary = await reconciler.reconcile(DeviceCapabilities(
        notifications: CapabilityStatus.denied,
        native: const NativeCapabilities(
          platform: 'android',
          osVersion: '15',
          apiLevel: 35,
          exactAlarms: CapabilityStatus.denied,
          appAlarms: CapabilityStatus.denied,
          fullScreen: CapabilityStatus.denied,
          externalClock: false,
        ),
      ));
      expect(gateway.scheduled, isEmpty);
      expect(summary.needsPermission[AlertKind.notification], 4);
      expect(summary.needsPermission[AlertKind.alarm], 4);
      final rows = await db.select(db.scheduledAlerts).get();
      expect(rows.every((r) => r.status == 'needsPermission'), isTrue);
    });
  });
}
