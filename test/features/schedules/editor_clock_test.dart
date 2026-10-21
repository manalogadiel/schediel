import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/features/reminders/domain/alert_rule.dart';
import 'package:schediel/integrations/native/native_bridge.dart';

import '../../support/harness.dart';

class EditorClockBridge extends NativeBridge {
  final calls = <({int hour, int minute, String title, List<int>? days})>[];
  ClockLaunchResult result = ClockLaunchResult.launched;

  @override
  Future<NativeCapabilities> getCapabilities() async => const NativeCapabilities(
    platform: 'android',
    osVersion: '13',
    apiLevel: 33,
    exactAlarms: CapabilityStatus.authorized,
    appAlarms: CapabilityStatus.authorized,
    fullScreen: CapabilityStatus.authorized,
    externalClock: true,
  );

  @override
  Future<List<AlarmResult>> scheduleAlarms(List<AlarmRequest> alarms, DateTime horizonEnd) async => [
    for (final a in alarms) AlarmResult(a.requestKey, AlarmResultStatus.scheduled, null),
  ];

  @override
  Future<ClockLaunchResult> launchClockAlarm({
    required int hour,
    required int minute,
    required String message,
    List<int>? weekdays,
  }) async {
    calls.add((hour: hour, minute: minute, title: message, days: weekdays));
    return result;
  }
}

void main() {
  final bridge = EditorClockBridge();
  setUp(() {
    bridge.calls.clear();
    bridge.result = ClockLaunchResult.launched;
  });

  Future<void> enableAlarm(TestHarness h) async {
    await h.tapText('Create schedule');
    await h.tester.enterText(textField('Title'), 'Fixture Clock save');
    await h.tapText('Next');
    await h.tapText('Next');
    await h.tapText('Alarm');
  }

  appTest('saving an enabled alarm opens Clock with the chosen lead time after persistence', (h) async {
    await enableAlarm(h);
    await h.tapText('Alarm timing');
    await h.tester.tap(find.byKey(const ValueKey('alert-offset-10')));
    await h.settle();
    expect(bridge.calls, isEmpty);
    final button = find.widgetWithText(FilledButton, 'Save & open Clock');
    expect(h.tester.getBottomRight(button).dx, closeTo(384, 1));
    await h.tapText('Save & open Clock');
    expect(bridge.calls, [(hour: 8, minute: 50, title: 'Fixture Clock save', days: null)]);
    final saved = (await h.run(h.read(scheduleRepositoryProvider).loadAll)).single;
    expect(saved.title, 'Fixture Clock save');
    final rows = await h.run(() => h.db.select(h.db.scheduledAlerts).get());
    expect(rows.where((r) => r.kind == 'clock').single.seriesId, saved.id);
  }, bridge: bridge);

  appTest('opting out of Clock saves the Schediel alarm without a handoff', (h) async {
    await enableAlarm(h);
    final toggle = find.widgetWithText(SwitchListTile, 'Open Android Clock after saving');
    await h.tester.ensureVisible(toggle);
    await h.tester.tap(toggle);
    await h.settle();
    await h.tapText('Save');
    expect(bridge.calls, isEmpty);
    final saved = (await h.run(h.read(scheduleRepositoryProvider).loadAll)).single;
    final rules = await h.run(() => h.read(scheduleRepositoryProvider).alertRules(saved.id));
    expect(rules.singleWhere((r) => r.kind == AlertKind.alarm).preference.enabled, isTrue);
  }, bridge: bridge);

  appTest('Clock launch failure keeps the saved schedule and reports a separate error', (h) async {
    bridge.result = ClockLaunchResult.failed;
    await enableAlarm(h);
    await h.tapText('Save & open Clock');
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), hasLength(1));
    expect(find.text('Schedule saved. Could not open Clock; your Schediel alarm is still enabled.'), findsOneWidget);
    final rows = await h.run(() => h.db.select(h.db.scheduledAlerts).get());
    expect(rows.where((r) => r.kind == 'clock'), isEmpty);
  }, bridge: bridge);
}
