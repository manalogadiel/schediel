import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/widgets/common.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../data/local/database.dart';
import '../application/alert_reconciler.dart';
import '../application/reconciliation_service.dart';
import '../domain/alert_rule.dart';

/// The desired alert and its actual scheduling status for one occurrence.
/// "Scheduled" appears only when the OS accepted the request.
class AlertStatusLine extends ConsumerWidget {
  const AlertStatusLine({super.key, required this.rule, required this.occurrence});

  final AlertRule rule;
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = Formats.of(context);
    final p = rule.preference;
    final kind = p.kind == AlertKind.notification ? 'Notification' : 'Alarm';
    final anchor = p.dateOnlyAnchorTime;
    final when = occurrence.timing is DateOnlyTiming && anchor != null
        ? '${p.offsetMinutes == 0 ? 'At' : '${f.offsetLabel(p.offsetMinutes)},'} ${f.clock(anchor)}'
        : f.offsetLabel(p.offsetMinutes);
    final rows = ref.watch(scheduledAlertsProvider).value ?? const <ScheduledAlertRow>[];
    ScheduledAlertRow? actual;
    for (final r in rows) {
      if (r.ruleId == rule.id && r.occurrenceKey == occurrence.originalKey.toIso()) actual = r;
    }
    final status = _statusText(actual, occurrence);
    return DetailLine(
      icon: p.kind == AlertKind.notification ? AppIcons.notification : AppIcons.alarm,
      text: status == null ? '$kind · $when' : '$kind · $when · $status',
    );
  }

  String? _statusText(ScheduledAlertRow? row, Occurrence occurrence) {
    if (occurrence.timing is UnresolvedTiming) return 'Not scheduled until the time is reviewed';
    if (row == null) return null;
    return switch (row.status) {
      AlertStatus.scheduled => 'Scheduled',
      AlertStatus.needsPermission => 'Permission needed',
      AlertStatus.blocked => 'Not available on this device',
      AlertStatus.failed => 'Could not be scheduled',
      AlertStatus.unscheduledCapacity => 'Will be scheduled closer to the date',
      _ => null,
    };
  }
}
