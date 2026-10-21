import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/schedule/models.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/time/local_time.dart';
import '../../../data/local/database.dart';
import '../../../integrations/native/native_bridge.dart';
import '../domain/alert_rule.dart';
import 'alert_reconciler.dart';
import 'capabilities.dart';

/// What a Clock alarm can express for this schedule, if anything.
@immutable
class ClockHandoffPlan {
  const ClockHandoffPlan({required this.time, required this.weekdays});

  /// Device-local alarm time.
  final LocalTime time;

  /// ISO weekdays for repeating alarms; null rings once at the next [time].
  final List<int>? weekdays;
}

/// Explicit Android hand-off to a Clock app (spec 7.2). The app records
/// "sent, unverified" and never claims the Clock alarm exists.
class ClockHandoffService {
  ClockHandoffService(this._ref);

  final Ref _ref;

  /// Resolve the next future alarm for the editor, rather than handing a
  /// past occurrence (or an arbitrary selected day) to Android Clock.
  ({Occurrence occurrence, ClockHandoffPlan plan})? nextFor(ScheduleSeries series, int offsetMinutes) {
    final now = _ref.read(clockProvider)().toUtc();
    final zone = _ref.read(deviceZoneProvider);
    final occurrences = _ref
        .read(occurrenceEngineProvider)
        .expand(series, windowStart: now, windowEnd: now.add(const Duration(days: 8)), viewZone: zone)
        .occurrences;
    for (final occurrence in occurrences) {
      final timing = occurrence.timing;
      if (timing is! TimedTiming || !timing.startUtc.subtract(Duration(minutes: offsetMinutes)).isAfter(now)) continue;
      final plan = planFor(series, occurrence, offsetMinutes);
      if (plan == null) return null;
      // Clock cannot express a future start date, skipped dates or an until
      // date. Do not let an editor hand-off ring before the next occurrence.
      if (plan.weekdays != null) {
        final localNow = _ref.read(zoneResolverProvider).toLocal(now, zone);
        for (var day = 0; day <= 7; day++) {
          final date = localNow.date.addDays(day);
          if (!plan.weekdays!.contains(date.weekday)) continue;
          if (day == 0 && plan.time.minutesOfDay <= localNow.time.minutesOfDay) continue;
          final trigger = _ref
              .read(zoneResolverProvider)
              .toLocal(timing.startUtc.subtract(Duration(minutes: offsetMinutes)), zone);
          if (date != trigger.date) return null;
          break;
        }
      }
      return (occurrence: occurrence, plan: plan);
    }
    return null;
  }

  /// Only schedules a time/weekday Clock alarm can represent exactly: a
  /// daily or weekly series in the device zone, or a one-time schedule
  /// within the next 24 hours. Anything else returns null.
  ClockHandoffPlan? planFor(ScheduleSeries series, Occurrence occurrence, int offsetMinutes) {
    final timing = occurrence.timing;
    final time = series.time;
    if (timing is! TimedTiming || time is! TimedSpec) return null;
    final zone = _ref.read(deviceZoneProvider);
    if (time.timeZone != zone) return null;
    final zones = _ref.read(zoneResolverProvider);
    final trigger = timing.startUtc.subtract(Duration(minutes: offsetMinutes));
    final local = zones.toLocal(trigger, zone);
    final rule = series.recurrence;
    if (rule != null) {
      // A lead time that crosses midnight would shift the weekdays.
      if (local.date != timing.localStartDate) return null;
      return ClockHandoffPlan(
        time: local.time,
        weekdays: rule.frequency == RecurrenceFrequency.daily ? const [1, 2, 3, 4, 5, 6, 7] : rule.weekdays,
      );
    }
    final now = _ref.read(clockProvider)().toUtc();
    if (!trigger.isAfter(now) || trigger.difference(now) > const Duration(hours: 24)) return null;
    return ClockHandoffPlan(time: local.time, weekdays: null);
  }

  Future<ClockLaunchResult> send(ScheduleSeries series, Occurrence occurrence, ClockHandoffPlan plan) async {
    final result = await _ref.read(nativeBridgeProvider).launchClockAlarm(
          hour: plan.time.hour,
          minute: plan.time.minute,
          message: series.title.length > 60 ? series.title.substring(0, 60) : series.title,
          weekdays: plan.weekdays,
        );
    if (result == ClockLaunchResult.launched) {
      final db = _ref.read(databaseProvider);
      final now = _ref.read(clockProvider)().toUtc();
      await db
          .into(db.scheduledAlerts)
          .insertOnConflictUpdate(
            ScheduledAlertsCompanion.insert(
              requestKey: 'clock|${series.id}',
              ruleId: 'clock',
              seriesId: series.id,
              occurrenceKey: occurrence.originalKey.toIso(),
              kind: 'clock',
              platform: 'android',
              sourceRevision: series.revision,
              nativeRequestId: const Value(null),
              triggerAt: now,
              status: AlertStatus.externalUnverified,
              errorCode: const Value(null),
              lastReconciledAt: now,
            ),
          );
    }
    return result;
  }
}

final clockHandoffProvider = Provider<ClockHandoffService>((ref) => ClockHandoffService(ref));

/// Whether the Clock hand-off is offered at all on this device.
final clockHandoffAvailableProvider = Provider<bool>(
  (ref) => ref.watch(deviceCapabilitiesProvider).value?.native.externalClock ?? false,
);

/// The recorded hand-off for a series, if any.
ScheduledAlertRow? clockRecordFor(List<ScheduledAlertRow> rows, String seriesId) {
  for (final r in rows) {
    if (r.kind == 'clock' && r.seriesId == seriesId) return r;
  }
  return null;
}

/// Alarm offset to apply to a Clock hand-off: the series alarm rule when
/// enabled, otherwise the start time.
int clockOffsetFor(List<AlertRule> rules, String seriesId) {
  for (final r in rules) {
    if (r.seriesId == seriesId && r.kind == AlertKind.alarm && r.preference.enabled) return r.preference.offsetMinutes;
  }
  return 0;
}
