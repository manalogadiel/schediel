import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/widgets/common.dart';
import '../../../core/schedule/occurrence.dart';
import '../domain/alert_rule.dart';

/// The desired alert preference for an occurrence. Scheduling status is
/// shown separately and never inferred from the toggle.
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
    return DetailLine(
      icon: p.kind == AlertKind.notification ? AppIcons.notification : AppIcons.alarm,
      text: '$kind · $when',
    );
  }
}
