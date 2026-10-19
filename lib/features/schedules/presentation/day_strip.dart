import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/schediel_theme.dart';
import '../../../app/widgets/common.dart';
import '../../../core/time/local_date.dart';

/// First day of the locale's week containing [date].
LocalDate weekStartOf(BuildContext context, LocalDate date) {
  final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  final isoStart = first == 0 ? 7 : first;
  return date.addDays(-((date.weekday - isoStart + 7) % 7));
}

/// Seven days of the selected week. Tap a day to select it; swipe sideways
/// to move a week. Dots mark days that have schedules (real data, current
/// filter).
class DayStrip extends ConsumerWidget {
  const DayStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(effectiveDateProvider);
    final today = ref.watch(todayProvider);
    final start = weekStartOf(context, selected);
    final week = ref.watch(weekViewProvider(start)).value;
    final withSchedules = {
      if (week != null)
        for (final d in week.days)
          if (!d.isEmpty) d.date,
    };
    final notifier = ref.read(selectedDateProvider.notifier);
    return DayStripView(
      start: start,
      selected: selected,
      today: today,
      daysWithSchedules: withSchedules,
      onSelect: notifier.select,
    );
  }
}

class DayStripView extends StatelessWidget {
  const DayStripView({
    super.key,
    required this.start,
    required this.selected,
    required this.today,
    required this.daysWithSchedules,
    required this.onSelect,
  });

  final LocalDate start;
  final LocalDate selected;
  final LocalDate today;
  final Set<LocalDate> daysWithSchedules;
  final ValueChanged<LocalDate> onSelect;

  @override
  Widget build(BuildContext context) {
    final f = Formats.of(context);
    void week(int delta) => onSelect(selected.addDays(7 * delta));
    return Semantics(
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Previous week'): () => week(-1),
        const CustomSemanticsAction(label: 'Next week'): () => week(1),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 200) return;
          week(v < 0 ? 1 : -1);
        },
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: _DayCell(
                  date: start.addDays(i),
                  weekday: f.weekdayShort(start.addDays(i).weekday),
                  title: f.dayTitle(start.addDays(i)),
                  selected: start.addDays(i) == selected,
                  isToday: start.addDays(i) == today,
                  hasSchedules: daysWithSchedules.contains(start.addDays(i)),
                  onTap: () => onSelect(start.addDays(i)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.weekday,
    required this.title,
    required this.selected,
    required this.isToday,
    required this.hasSchedules,
    required this.onTap,
  });

  final LocalDate date;
  final String weekday;
  final String title;
  final bool selected;
  final bool isToday;
  final bool hasSchedules;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final p = c.palette;
    final pixel = c.style == StyleFamily.pixel;
    final fg = selected ? p.onAccent : c.ink;
    final shape = pixel
        ? RoundedRectangleBorder(side: selected || isToday ? BorderSide(color: p.outline, width: 2) : BorderSide.none)
        : StadiumBorder(
            side: selected && c.outlined
                ? BorderSide(color: p.outline, width: 2)
                : isToday && !selected
                    ? BorderSide(color: c.accentText, width: 1.5)
                    : BorderSide.none,
          );
    final label = [title, if (isToday) 'today', if (hasSchedules) 'has schedules'].join(', ');
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          key: ValueKey('day-${date.toIso()}'),
          color: Colors.transparent,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppMotion.control(context),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: ShapeDecoration(color: selected ? p.accent : Colors.transparent, shape: shape),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(weekday, maxLines: 1, overflow: TextOverflow.clip, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? fg : c.secondaryInk)),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: c.displayFont,
                      fontSize: c.displayFont == 'Caveat' ? 22 : (c.displayFont == 'Silkscreen' ? 14 : 17),
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasSchedules ? fg : Colors.transparent,
                      shape: pixel ? BoxShape.rectangle : BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
