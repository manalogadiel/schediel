import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../core/schedule/occurrence.dart';
import 'occurrence_sheet.dart';

enum RowEmphasis { now, next, normal, past }

/// One timeline entry: time, title, then only the details that exist.
class TimelineRow extends ConsumerWidget {
  const TimelineRow({
    super.key,
    required this.occurrence,
    this.emphasis = RowEmphasis.normal,
    this.overlaps = false,
  });

  final Occurrence occurrence;
  final RowEmphasis emphasis;
  final bool overlaps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.scheduleColors;
    final text = Theme.of(context).textTheme;
    final f = Formats.of(context);
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    final category = ref.watch(categoryByIdProvider(occurrence.categoryId));
    final compact = colors.density == Density.compact;
    final past = emphasis == RowEmphasis.past;
    final ink = past ? colors.secondaryInk : colors.ink;

    String primaryTime;
    String? secondaryTime;
    String? sourceNote;
    final timing = occurrence.timing;
    switch (timing) {
      case TimedTiming():
        final t = OccurrenceTimeText.of(timing, zones, zone, f);
        primaryTime = t.start;
        secondaryTime = t.end == null ? null : (t.endsNextDay ? '${t.end} +1' : t.end);
        sourceNote = t.sourceNote;
      case DateOnlyTiming():
        primaryTime = 'All day';
        final last = timing.endDateExclusive.addDays(-1);
        secondaryTime = last == timing.startDate ? null : 'to ${f.monthDay(last)}';
      case UnresolvedTiming():
        primaryTime = f.clock(timing.localStartTime);
        secondaryTime = null;
    }

    final details = occurrence.details;
    final label = switch (emphasis) {
      RowEmphasis.now => 'Now',
      RowEmphasis.next => 'Next',
      _ => null,
    };

    final semantics = [
      ?label,
      occurrence.title,
      if (timing is TimedTiming) OccurrenceTimeText.of(timing, zones, zone, f).range else primaryTime,
      if (timing is UnresolvedTiming) 'Needs time review',
      if (details.location != null) 'Room ${details.location}',
      if (details.professor != null) 'With ${details.professor}',
      if (details.subtitle != null) details.subtitle!,
      if (category != null) 'Category ${category.name}',
      if (overlaps) 'Overlaps another schedule',
      if (past) 'Ended',
    ].join(', ');

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.md, vertical: compact ? 10 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(primaryTime, style: timeStyle(context).copyWith(color: ink)),
                if (secondaryTime != null)
                  Text(secondaryTime, style: timeStyle(context).copyWith(color: colors.secondaryInk, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          const SizedBox(width: Tokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Padding(padding: const EdgeInsets.only(bottom: 4), child: StatusLabel(label, strong: emphasis == RowEmphasis.now || emphasis == RowEmphasis.next)),
                Text(
                  occurrence.title,
                  style: text.titleMedium?.copyWith(
                    color: ink,
                    fontWeight: emphasis == RowEmphasis.next || emphasis == RowEmphasis.now ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (details.location != null) DetailLine(icon: AppIcons.location, text: details.location!),
                if (details.professor != null) DetailLine(icon: AppIcons.person, text: details.professor!),
                if (details.subtitle != null) DetailLine(icon: AppIcons.text, text: details.subtitle!),
                if (category != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      CategoryDot(colorKey: category.colorKey),
                      Flexible(child: Text(category.name, style: text.labelSmall)),
                    ]),
                  ),
                if (sourceNote != null) DetailLine(icon: AppIcons.time, text: sourceNote),
                if (timing is UnresolvedTiming) DetailLine(icon: AppIcons.warning, text: 'Needs time review'),
                if (overlaps) DetailLine(icon: AppIcons.warning, text: 'Overlaps another schedule'),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: emphasis == RowEmphasis.next ? colors.nextHolder : Colors.transparent,
        child: InkWell(
          onTap: () => showOccurrenceSheet(context, occurrence),
          child: content,
        ),
      ),
    );
  }
}
