import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/themed.dart';
import '../../../core/schedule/occurrence.dart';
import 'occurrence_sheet.dart';

/// "in 40 min", "in 1 h 30 min"; whole minutes, rounded down.
String untilLabel(Duration d) {
  final minutes = d.inMinutes;
  if (minutes < 1) return 'in less than a minute';
  if (minutes < 60) return 'in $minutes min';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? 'in $h h' : 'in $h h $m min';
}

/// The next timed occurrence, large and accent-filled. Only shown when there
/// is a next item; the countdown follows the app's minute ticker.
class NextCard extends ConsumerWidget {
  const NextCard({super.key, required this.next});

  final Occurrence next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.scheduleColors;
    final p = c.palette;
    final text = Theme.of(context).textTheme;
    final f = Formats.of(context);
    final now = ref.watch(nowProvider);
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    final timing = next.timing;
    final range = timing is TimedTiming ? OccurrenceTimeText.of(timing, zones, zone, f).range : null;
    final until = timing is TimedTiming ? untilLabel(timing.startUtc.difference(now.toUtc())) : null;
    final details = next.details;
    final ink = p.onAccent;
    Widget line(AppIcons icon, String value) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 2, right: 8), child: AppIcon(icon, size: 16, color: ink)),
            Expanded(child: Text(value, style: text.bodyMedium?.copyWith(color: ink))),
          ]),
        );
    final semantics = [
      'Next',
      ?until,
      next.title,
      ?range,
      if (details.location != null) 'Room ${details.location}',
      if (details.professor != null) 'With ${details.professor}',
    ].join(', ');
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: ThemedCard(
        fill: p.accent,
        emphasized: true,
        seed: 'next-${next.id}',
        padding: const EdgeInsets.fromLTRB(Tokens.md + 2, Tokens.md, Tokens.md + 2, Tokens.md + 2),
        onTap: () => showOccurrenceSheet(context, next),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ThemedPill(label: 'Next', fill: ink),
                if (until != null) Text(until, style: text.labelLarge?.copyWith(color: ink, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            Text(next.title, style: text.titleLarge?.copyWith(color: ink)),
            if (range != null) line(AppIcons.time, range),
            if (details.location != null) line(AppIcons.location, details.location!),
            if (details.professor != null) line(AppIcons.person, details.professor!),
          ],
        ),
      ),
    );
  }
}
