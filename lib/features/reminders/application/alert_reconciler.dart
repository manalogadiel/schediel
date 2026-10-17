import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/schedule/models.dart';
import '../../../data/local/database.dart';
import '../../../integrations/native/native_bridge.dart';
import '../data/notification_gateway.dart';
import '../domain/alert_rule.dart';
import 'alert_planner.dart';
import 'capabilities.dart';

/// Status names stored for actual requests (CONTRACTS.md 3.2).
abstract final class AlertStatus {
  static const needsPermission = 'needsPermission';
  static const scheduled = 'scheduled';
  static const blocked = 'blocked';
  static const failed = 'failed';
  static const unscheduledCapacity = 'unscheduledCapacity';
  static const externalUnverified = 'externalUnverified';
}

@immutable
class ReconcileSummary {
  const ReconcileSummary({
    required this.scheduled,
    required this.needsPermission,
    required this.failed,
    required this.overflow,
    required this.blocked,
    required this.coverageEnd,
  });

  final Map<AlertKind, int> scheduled;
  final Map<AlertKind, int> needsPermission;
  final Map<AlertKind, int> failed;
  final Map<AlertKind, int> overflow;
  final Map<AlertKind, int> blocked;

  /// Last scheduled trigger per kind: coverage of the rolling horizon.
  final Map<AlertKind, DateTime?> coverageEnd;
}

/// Cancels obsolete requests, schedules current ones and persists the actual
/// result (spec 7.6 steps 3-5). Retries reuse the same request identity.
class AlertReconciler {
  AlertReconciler({
    required this.db,
    required this.planner,
    required this.gateway,
    required this.bridge,
    required this.loadSeries,
    required this.loadRules,
    required this.clock,
    required this.zone,
    required this.use24h,
  });

  static const horizon = Duration(days: 14);

  /// Leaves room under iOS's 64 pending-notification limit.
  static const notificationCapacity = 48;
  static const alarmCapacity = 32;

  final AppDatabase db;
  final AlertPlanner planner;
  final NotificationGateway gateway;
  final NativeBridge bridge;
  final Future<List<ScheduleSeries>> Function() loadSeries;
  final Future<List<AlertRule>> Function() loadRules;
  final DateTime Function() clock;
  final String Function() zone;
  final bool Function() use24h;

  Future<ReconcileSummary> reconcile(DeviceCapabilities caps) async {
    final now = clock().toUtc();
    final series = await loadSeries();
    final rules = await loadRules();
    final platform = caps.native.platform == 'unknown' ? defaultTargetPlatform.name : caps.native.platform;
    PlanInput input(int capacity) => PlanInput(
          series: series,
          rules: rules,
          now: now,
          zone: zone(),
          horizon: horizon,
          capacity: capacity,
          platform: platform,
          use24h: use24h(),
        );
    final existing = await db.select(db.scheduledAlerts).get();
    final rows = <ScheduledAlertsCompanion>[];
    final summary = (
      scheduled: <AlertKind, int>{},
      needsPermission: <AlertKind, int>{},
      failed: <AlertKind, int>{},
      overflow: <AlertKind, int>{},
      blocked: <AlertKind, int>{},
      coverage: <AlertKind, DateTime?>{},
    );
    void count(Map<AlertKind, int> map, AlertKind kind) => map[kind] = (map[kind] ?? 0) + 1;

    ScheduledAlertsCompanion row(PlannedAlert a, String status, {String? nativeId, String? error}) =>
        ScheduledAlertsCompanion.insert(
          requestKey: a.requestKey,
          ruleId: a.ruleId,
          seriesId: a.seriesId,
          occurrenceKey: a.occurrenceKey.toIso(),
          kind: a.kind.name,
          platform: platform,
          sourceRevision: a.sourceRevision,
          nativeRequestId: Value(nativeId),
          triggerAt: a.triggerAt,
          status: status,
          errorCode: Value(error),
          lastReconciledAt: now,
        );

    // Notifications.
    final notifications = planner.plan(input(notificationCapacity), AlertKind.notification);
    final oldNotifications = {for (final r in existing) if (r.kind == AlertKind.notification.name) r.requestKey: r};
    final desiredKeys = {for (final a in notifications.requests) a.requestKey};
    for (final old in oldNotifications.values) {
      final id = int.tryParse(old.nativeRequestId ?? '');
      if (id != null && !desiredKeys.contains(old.requestKey)) await gateway.cancel(id);
    }
    if (!caps.notificationsAuthorized) {
      for (final old in oldNotifications.values) {
        final id = int.tryParse(old.nativeRequestId ?? '');
        if (id != null) await gateway.cancel(id);
      }
      for (final a in notifications.requests) {
        rows.add(row(a, AlertStatus.needsPermission));
        count(summary.needsPermission, AlertKind.notification);
      }
    } else {
      final pending = await gateway.pendingIds();
      for (final a in notifications.requests) {
        final id = notificationIdFor(a.requestKey);
        final old = oldNotifications[a.requestKey];
        final unchanged = old != null &&
            old.status == AlertStatus.scheduled &&
            old.triggerAt.isAtSameMomentAs(a.triggerAt) &&
            old.sourceRevision == a.sourceRevision &&
            pending.contains(id);
        var ok = unchanged;
        if (!unchanged) {
          await gateway.cancel(id);
          ok = await gateway.schedule(
            NotificationRequest(
              id: id,
              requestKey: a.requestKey,
              triggerAt: a.triggerAt,
              title: a.title,
              body: a.body,
              payload: a.deepLink,
            ),
            exact: caps.exactAuthorized,
          );
        }
        rows.add(row(a, ok ? AlertStatus.scheduled : AlertStatus.failed, nativeId: ok ? '$id' : null, error: ok ? null : 'scheduleFailed'));
        count(ok ? summary.scheduled : summary.failed, AlertKind.notification);
        if (ok) summary.coverage[AlertKind.notification] = a.triggerAt;
      }
    }
    for (final a in notifications.overflow) {
      rows.add(row(a, AlertStatus.unscheduledCapacity));
      count(summary.overflow, AlertKind.notification);
    }

    // App-owned alarms (replace-all native semantics).
    final alarms = planner.plan(input(alarmCapacity), AlertKind.alarm);
    final native = caps.native;
    if (!native.alarmsAvailable) {
      for (final a in alarms.requests) {
        rows.add(row(a, AlertStatus.blocked, error: 'unavailable'));
        count(summary.blocked, AlertKind.alarm);
      }
    } else if (!caps.alarmsAuthorized) {
      await bridge.scheduleAlarms(const [], now.add(horizon));
      for (final a in alarms.requests) {
        rows.add(row(a, AlertStatus.needsPermission));
        count(summary.needsPermission, AlertKind.alarm);
      }
    } else {
      final prominentAllowed = native.fullScreen == CapabilityStatus.authorized;
      final results = await bridge.scheduleAlarms([
        for (final a in alarms.requests)
          AlarmRequest(
            requestKey: a.requestKey,
            triggerAt: a.triggerAt,
            title: a.title,
            body: a.body,
            deepLink: a.deepLink,
            snoozeMinutes: a.snoozeMinutes,
            prominent: a.prominentRequested && prominentAllowed,
          ),
      ], now.add(horizon));
      final byKey = {for (final r in results) r.requestKey: r};
      for (final a in alarms.requests) {
        final result = byKey[a.requestKey];
        switch (result?.status) {
          case AlarmResultStatus.scheduled:
            rows.add(row(a, AlertStatus.scheduled, nativeId: a.requestKey));
            count(summary.scheduled, AlertKind.alarm);
            summary.coverage[AlertKind.alarm] = a.triggerAt;
          case AlarmResultStatus.needsPermission:
            rows.add(row(a, AlertStatus.needsPermission));
            count(summary.needsPermission, AlertKind.alarm);
          case AlarmResultStatus.pastTrigger:
            break;
          case AlarmResultStatus.failed:
          case null:
            rows.add(row(a, AlertStatus.failed, error: result?.errorCode ?? 'failed'));
            count(summary.failed, AlertKind.alarm);
        }
      }
    }
    for (final a in alarms.overflow) {
      rows.add(row(a, AlertStatus.unscheduledCapacity));
      count(summary.overflow, AlertKind.alarm);
    }

    await db.transaction(() async {
      await (db.delete(db.scheduledAlerts)
            ..where((t) => t.kind.isIn([AlertKind.notification.name, AlertKind.alarm.name])))
          .go();
      for (final r in rows) {
        await db.into(db.scheduledAlerts).insertOnConflictUpdate(r);
      }
    });

    return ReconcileSummary(
      scheduled: summary.scheduled,
      needsPermission: summary.needsPermission,
      failed: summary.failed,
      overflow: summary.overflow,
      blocked: summary.blocked,
      coverageEnd: summary.coverage,
    );
  }
}
