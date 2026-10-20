import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/schediel_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../app/widgets/themed.dart';
import '../../../core/schedule/occurrence.dart';
import 'occurrence_sheet.dart';

enum RowEmphasis { now, next, normal, past }

/// One timeline entry: a node on the day's rail and a card with the title
/// and details on the left and the time range centered on the right.
/// Ongoing entries fill with the accent.
class TimelineRow extends ConsumerWidget {
  const TimelineRow({super.key, required this.occurrence, this.emphasis = RowEmphasis.normal, this.overlaps = false});

  final Occurrence occurrence;
  final RowEmphasis emphasis;
  final bool overlaps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.scheduleColors;
    final p = colors.palette;
    final text = Theme.of(context).textTheme;
    final f = Formats.of(context);
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    final category = ref.watch(categoryByIdProvider(occurrence.categoryId));
    final compact = colors.density == Density.compact;
    final past = emphasis == RowEmphasis.past;
    final live = emphasis == RowEmphasis.now;

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

    // Ongoing fills with the accent; past steps back to the neutral fill.
    final fill = live ? p.accent : (past ? p.neutralFill : colors.categoryFill(category?.colorKey));
    final ink = live ? p.onAccent : p.cardInk;
    final soft = ink.withValues(alpha: .72);
    final detailStyle = text.bodySmall?.copyWith(color: soft);

    double? elapsed;
    if (live && timing is TimedTiming && timing.endUtc != null) {
      final total = timing.endUtc!.difference(timing.startUtc).inSeconds;
      final done = ref.watch(nowProvider).toUtc().difference(timing.startUtc).inSeconds;
      if (total > 0) elapsed = (done / total).clamp(0.0, 1.0);
    }

    final times = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(primaryTime, style: timeStyle(context).copyWith(color: ink, fontWeight: FontWeight.w700, fontSize: 14)),
        if (secondaryTime != null)
          Text(secondaryTime, style: timeStyle(context).copyWith(color: soft, fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ThemedPill(label: label, emphasized: !live, fill: live ? ink : null),
          ),
        Text(
          occurrence.title,
          style: text.titleMedium?.copyWith(color: ink, fontWeight: live ? FontWeight.w700 : FontWeight.w600, height: 1.25),
        ),
        if (details.location != null) DetailLine(icon: AppIcons.location, text: details.location!, style: detailStyle),
        if (details.professor != null) DetailLine(icon: AppIcons.person, text: details.professor!, style: detailStyle),
        if (details.subtitle != null) DetailLine(icon: AppIcons.text, text: details.subtitle!, style: detailStyle),
        if (sourceNote != null) DetailLine(icon: AppIcons.time, text: sourceNote, style: detailStyle),
        if (timing is UnresolvedTiming) DetailLine(icon: AppIcons.warning, text: 'Needs time review', style: detailStyle),
        if (overlaps) DetailLine(icon: AppIcons.warning, text: 'Overlaps another schedule', style: detailStyle),
        if (category != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _CategoryTag(name: category.name, ink: ink, colorKey: category.colorKey),
          ),
      ],
    );

    // Large text stacks the time above the details instead of squeezing both.
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final card = ThemedCard(
      fill: fill,
      seed: occurrence.id,
      emphasized: emphasis == RowEmphasis.next,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 11 : 15),
      onTap: () => showOccurrenceSheet(context, occurrence),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stacked)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(alignment: Alignment.centerLeft, child: times),
                const SizedBox(height: 6),
                info,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: info),
                const SizedBox(width: 12),
                times,
              ],
            ),
          if (elapsed != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(colors.style == StyleFamily.pixel ? 0 : 3),
                child: LinearProgressIndicator(
                  key: const ValueKey('elapsed-bar'),
                  value: elapsed,
                  minHeight: 5,
                  color: ink,
                  backgroundColor: ink.withValues(alpha: 0.2),
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      onTap: () => showOccurrenceSheet(context, occurrence),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RailNode(emphasis: emphasis, compactGap: compact),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: compact ? 8 : 12),
                child: card,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The day's rail: a continuous line with a node per entry. The ongoing
/// node is a filled ring with a halo; past nodes are small solid dots.
class _RailNode extends StatelessWidget {
  const _RailNode({required this.emphasis, required this.compactGap});
  final RowEmphasis emphasis;
  final bool compactGap;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final accent = c.accentText;
    final shape = c.style == StyleFamily.pixel ? BoxShape.rectangle : BoxShape.circle;
    final node = switch (emphasis) {
      RowEmphasis.now => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: shape,
          color: c.canvas,
          border: Border.all(color: accent, width: 5),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: .35), blurRadius: 10)],
        ),
      ),
      RowEmphasis.past => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: shape, color: c.secondaryInk.withValues(alpha: .5)),
      ),
      _ => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(shape: shape, color: c.canvas, border: Border.all(color: accent, width: 2)),
      ),
    };
    return SizedBox(
      width: 18,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(top: 0, bottom: 0, child: Container(width: 2, color: c.ink.withValues(alpha: .14))),
          // The node sits level with the card's first line.
          Padding(padding: EdgeInsets.only(top: compactGap ? 16 : 20), child: node),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.name, required this.ink, required this.colorKey});

  final String name;
  final Color ink;
  final String? colorKey;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final pixel = c.style == StyleFamily.pixel;
    final strong = c.showCategoryColors ? CategoryColor.fromKey(colorKey)?.resolve(c.palette.brightness) : null;
    // A borderless pill tinted with the category's own color.
    return Container(
      key: const ValueKey('category-tag'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(pixel ? 0 : Tokens.radiusPill),
        color: strong?.withValues(alpha: .18) ?? ink.withValues(alpha: .08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: strong ?? ink.withValues(alpha: .5), shape: pixel ? BoxShape.rectangle : BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              name,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3, color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
