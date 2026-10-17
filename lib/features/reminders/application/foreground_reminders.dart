import 'package:flutter/foundation.dart';

import '../../../data/local/database.dart';
import 'alert_reconciler.dart';

/// A reminder or alarm that came due while the app was open.
@immutable
class DueReminder {
  const DueReminder({
    required this.seriesId,
    required this.occurrenceKey,
    required this.kind,
    required this.requestKey,
    required this.triggerAt,
  });

  final String seriesId;
  final String occurrenceKey;

  /// 'notification' or 'alarm'.
  final String kind;
  final String requestKey;
  final DateTime triggerAt;

  String get location =>
      '/reminder/$seriesId/$occurrenceKey?kind=$kind&request=${Uri.encodeQueryComponent(requestKey)}';
}

/// Scheduled reminders and alarms whose trigger fell in (since, now], one per
/// occurrence (the alarm wins), in trigger order.
List<DueReminder> remindersDue(Iterable<ScheduledAlertRow> rows, {required DateTime since, required DateTime now}) {
  final due = rows
      .where((r) =>
          r.status == AlertStatus.scheduled &&
          (r.kind == 'notification' || r.kind == 'alarm') &&
          r.triggerAt.isAfter(since) &&
          !r.triggerAt.isAfter(now))
      .toList()
    ..sort((a, b) => a.triggerAt.compareTo(b.triggerAt));
  final byOccurrence = <String, DueReminder>{};
  for (final r in due) {
    final key = '${r.seriesId}/${r.occurrenceKey}';
    final existing = byOccurrence[key];
    if (existing == null || (existing.kind != 'alarm' && r.kind == 'alarm')) {
      byOccurrence[key] = DueReminder(
        seriesId: r.seriesId,
        occurrenceKey: r.occurrenceKey,
        kind: r.kind,
        requestKey: r.requestKey,
        triggerAt: r.triggerAt,
      );
    }
  }
  return byOccurrence.values.toList(growable: false);
}

/// Tracks foreground time for the in-app full-page reminder (spec 7.1).
/// Reminders that fired while the app was in the background are not
/// replayed; the system already presented them.
class ForegroundReminderTracker {
  DateTime? _since;

  bool get inForeground => _since != null;

  void resumed(DateTime now) => _since = now;

  void paused() => _since = null;

  List<DueReminder> tick(DateTime now, Iterable<ScheduledAlertRow> rows) {
    final since = _since;
    if (since == null || !now.isAfter(since)) return const [];
    _since = now;
    return remindersDue(rows, since: since, now: now);
  }
}
