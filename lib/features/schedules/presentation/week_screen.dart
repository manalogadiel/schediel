import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/shell.dart';
import '../../../app/theme/schediel_theme.dart';
import '../../../app/widgets/common.dart';
import '../../../app/widgets/themed.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import '../../../core/time/zone_resolver.dart';
import '../../categories/domain/category.dart';
import '../application/day_view.dart';
import 'occurrence_sheet.dart';
import 'timeline_row.dart';
import 'day_strip.dart';
import 'today_header.dart' show pickDate;

/// Week: a time grid with an equivalent agenda (spec 4.4).
class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  bool? _agenda;

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final selected = ref.watch(effectiveDateProvider);
    final start = weekStartOf(context, selected);
    final week = ref.watch(weekViewProvider(start));
    final f = Formats.of(context);
    final text = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final preferAgenda = media.textScaler.scale(1) > 1.3 || media.accessibleNavigation;
    final agenda = _agenda ?? preferAgenda;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Week', style: text.labelMedium?.copyWith(color: context.scheduleColors.secondaryInk)),
                        Tooltip(
                          message: 'Choose date',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(Tokens.radiusControl),
                            onTap: () async {
                              final picked = await pickDate(context, selected);
                              if (picked != null && mounted) ref.read(selectedDateProvider.notifier).select(picked);
                            },
                            child: Semantics(
                              button: true,
                              header: true,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(child: Text(f.range(start, start.addDays(6)), style: text.headlineMedium)),
                                  const SizedBox(width: Tokens.xs),
                                  const AppIcon(AppIcons.expand, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (start != weekStartOf(context, today))
                    Semantics(
                      button: true,
                      label: 'This week',
                      excludeSemantics: true,
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () => ref.read(selectedDateProvider.notifier).today(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: ThemedPill(label: 'This week', emphasized: true),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.sm, Tokens.xs, Tokens.md, Tokens.sm),
              child: Row(
                children: [
                  ThemedIconButton(
                    icon: AppIcons.previous,
                    tooltip: 'Previous week',
                    size: 40,
                    onPressed: () => ref.read(selectedDateProvider.notifier).select(selected.addDays(-7)),
                  ),
                  ThemedIconButton(
                    icon: AppIcons.next,
                    tooltip: 'Next week',
                    size: 40,
                    onPressed: () => ref.read(selectedDateProvider.notifier).select(selected.addDays(7)),
                  ),
                  const Spacer(),
                  ThemedIconButton(
                    icon: agenda ? AppIcons.grid : AppIcons.agenda,
                    tooltip: agenda ? 'Show time grid' : 'Show agenda',
                    size: 40,
                    onPressed: () => setState(() => _agenda = !agenda),
                  ),
                  const SizedBox(width: Tokens.xs),
                  const FilterPill(),
                ],
              ),
            ),
            if (agenda)
              Padding(
                padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.sm),
                child: DayStripView(
                  start: start,
                  selected: selected,
                  today: today,
                  daysWithSchedules: {
                    if (week.value != null)
                      for (final d in week.value!.days)
                        if (!d.isEmpty) d.date,
                  },
                  onSelect: ref.read(selectedDateProvider.notifier).select,
                ),
              ),
            Expanded(
              child: week.when(
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (_, _) => EmptyState(
                  title: 'Unable to load schedules',
                  action: OutlinedButton(onPressed: () => ref.invalidate(allSeriesProvider), child: const Text('Try again')),
                ),
                data: (w) {
                  final empty = w.days.every((d) => d.isEmpty);
                  final content = agenda ? _WeekAgenda(week: w) : _WeekGrid(week: w);
                  if (!empty) return content;
                  final any = w.days.first.hasAnySchedules;
                  final filtered = w.days.first.filterActive;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                !any
                                    ? 'No schedules yet'
                                    : filtered
                                    ? 'No schedules in this filter'
                                    : 'No schedules this week',
                              ),
                            ),
                            if (!any) TextButton(onPressed: () => context.push('/schedule/new'), child: const Text('Create schedule')),
                            if (any && filtered)
                              TextButton(
                                onPressed: () => ref.read(appFilterProvider.notifier).set(const CategoryFilter.all()),
                                child: const Text('Show all'),
                              ),
                          ],
                        ),
                      ),
                      Expanded(child: content),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekAgenda extends StatelessWidget {
  const _WeekAgenda({required this.week});

  final WeekView week;

  @override
  Widget build(BuildContext context) {
    final f = Formats.of(context);
    final text = Theme.of(context).textTheme;
    final c = context.scheduleColors;
    return ListView(
      padding: EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, AppShell.bottomInset(context)),
      children: [
        for (final day in week.days)
          if (!day.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: Tokens.sm, bottom: Tokens.sm),
              child: Semantics(
                header: true,
                child: Text(
                  '${f.dayTitle(day.date)}${day.isToday ? ' · Today' : ''}',
                  style: text.labelLarge?.copyWith(color: day.isToday ? c.ink : c.secondaryInk),
                ),
              ),
            ),
            for (final o in [...day.agenda.dateOnly, ...day.agenda.needsReview, ...day.all.where((o) => o.timing is TimedTiming)])
              TimelineRow(occurrence: o, overlaps: day.overlapIds.contains(o.id)),
          ],
      ],
    );
  }
}

/// A positioned segment of an occurrence within one local day.
class _Segment {
  _Segment(this.occurrence, this.startMin, this.endMin, this.isPoint);
  final Occurrence occurrence;
  final int startMin;
  final int endMin;
  final bool isPoint;
  int column = 0;
  int columns = 1;
}

class _WeekGrid extends ConsumerStatefulWidget {
  const _WeekGrid({required this.week});

  final WeekView week;

  @override
  ConsumerState<_WeekGrid> createState() => _WeekGridState();
}

class _WeekGridState extends ConsumerState<_WeekGrid> {
  WeekView get week => widget.week;
  final _scroll = ScrollController();
  LocalDate? _scrolledWeek;
  static const _gutter = 44.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<_Segment> _segments(DayView day, ZoneResolver zones, String zone) {
    final (dayStart, dayEnd) = (zones.startOfDay(day.date, zone), zones.startOfDay(day.date.addDays(1), zone));

    final result = <_Segment>[];
    for (final o in day.all) {
      final t = o.timing;
      if (t is! TimedTiming) continue;
      // The ruler is local wall time, not elapsed UTC minutes on DST days.
      final start = t.startUtc.isBefore(dayStart) ? 0 : zones.toLocal(t.startUtc, zone).time.minutesOfDay;
      final end = t.endUtc == null
          ? math.min(1440, start + 30)
          : !t.endUtc!.isBefore(dayEnd)
          ? 1440
          : zones.toLocal(t.endUtc!, zone).time.minutesOfDay;
      result.add(_Segment(o, start, math.max(end, start + 20), t.endUtc == null));
    }
    result.sort((a, b) => a.startMin.compareTo(b.startMin));
    // Greedy column assignment within clusters of overlapping segments.
    var cluster = <_Segment>[];
    var clusterEnd = -1;
    void close() {
      final cols = cluster.fold<int>(0, (m, s) => math.max(m, s.column + 1));
      for (final s in cluster) {
        s.columns = cols;
      }
      cluster = [];
    }

    for (final s in result) {
      if (s.startMin >= clusterEnd && cluster.isNotEmpty) close();
      final used = {
        for (final c in cluster)
          if (c.endMin > s.startMin) c.column,
      };
      var col = 0;
      while (used.contains(col)) {
        col++;
      }
      s.column = col;
      cluster.add(s);
      clusterEnd = math.max(clusterEnd, s.endMin);
    }
    if (cluster.isNotEmpty) close();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    final now = ref.watch(nowProvider);
    final f = Formats.of(context);
    final colors = context.scheduleColors;
    final scheme = Theme.of(context).colorScheme;
    final hourHeight = colors.density == Density.compact ? 40.0 : 48.0;

    final perDay = [for (final d in week.days) _segments(d, zones, zone)];
    const firstHour = 0;
    const lastHour = 24;
    const hours = lastHour - firstHour;
    if (_scrolledWeek != week.days.first.date) {
      _scrolledWeek = week.days.first.date;
      final local = zones.toLocal(now, zone);
      final isCurrentWeek = week.days.any((d) => d.date == local.date);
      final starts = perDay.expand((s) => s).map((s) => s.startMin).toList()..sort();
      final minute = isCurrentWeek ? local.time.minutesOfDay : (starts.firstOrNull ?? 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(((minute / 60 - 1) * hourHeight).clamp(0, _scroll.position.maxScrollExtent));
        }
      });
    }
    final hasStrip = week.days.any((d) => d.agenda.dateOnly.isNotEmpty || d.agenda.needsReview.isNotEmpty);

    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = (constraints.maxWidth - _gutter - Tokens.md) / 7;
        final selected = ref.watch(effectiveDateProvider);
        return Column(
          children: [
            // Swipe the header sideways to move a week, like the day strip.
            Semantics(
              customSemanticsActions: {
                const CustomSemanticsAction(label: 'Previous week'): () =>
                    ref.read(selectedDateProvider.notifier).select(selected.addDays(-7)),
                const CustomSemanticsAction(label: 'Next week'): () => ref.read(selectedDateProvider.notifier).select(selected.addDays(7)),
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() < 200) return;
                  ref.read(selectedDateProvider.notifier).select(selected.addDays(v < 0 ? 7 : -7));
                },
                child: _WeekHeader(
                  days: week.days,
                  gutter: _gutter,
                  colWidth: colWidth,
                  selected: selected,
                  onSelect: ref.read(selectedDateProvider.notifier).select,
                ),
              ),
            ),
            if (hasStrip)
              Padding(
                padding: const EdgeInsets.only(left: _gutter, right: Tokens.md, top: Tokens.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final d in week.days)
                      SizedBox(
                        width: colWidth,
                        child: Column(
                          children: [
                            for (final o in [...d.agenda.dateOnly, ...d.agenda.needsReview])
                              _Block(occurrence: o, compact: true, warn: o.timing is UnresolvedTiming),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: Tokens.xs),
            Divider(color: colors.divider),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('week-timeline'),
                controller: _scroll,
                padding: EdgeInsets.only(bottom: AppShell.bottomInset(context)),
                child: SizedBox(
                  height: hours * hourHeight + Tokens.sm,
                  child: Stack(
                    children: [
                      for (var i = 0; i < 7; i++) ...[
                        Positioned(
                          left: _gutter + i * colWidth,
                          top: 0,
                          width: colWidth,
                          height: 1,
                          child: SizedBox(key: ValueKey('week-column-$i')),
                        ),
                        if (week.days[i].date == selected)
                          Positioned(
                            left: _gutter + i * colWidth,
                            top: 0,
                            bottom: 0,
                            width: colWidth,
                            child: IgnorePointer(
                              child: ColoredBox(key: const ValueKey('week-selected-column'), color: _WeekHeader.tint(colors)),
                            ),
                          ),
                      ],
                      for (var h = 0; h <= hours; h++)
                        Positioned(
                          top: h * hourHeight,
                          left: 0,
                          right: Tokens.md,
                          child: Row(
                            children: [
                              SizedBox(
                                width: _gutter,
                                child: ExcludeSemantics(
                                  // "10:00 AM" can be wider than the column: shrink
                                  // slightly rather than wrap the AM/PM marker.
                                  child: h == hours
                                      ? const SizedBox.shrink()
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            f.clock(LocalTime((firstHour + h) % 24, 0)),
                                            key: const ValueKey('week-hour-label'),
                                            maxLines: 1,
                                            softWrap: false,
                                            style: TextStyle(fontSize: 11, color: colors.secondaryInk),
                                          ),
                                        ),
                                ),
                              ),
                              Expanded(child: Divider(color: colors.divider.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      for (var i = 0; i < 7; i++)
                        for (final s in perDay[i])
                          Positioned(
                            left: _gutter + i * colWidth + s.column * (colWidth / s.columns) + 1,
                            width: colWidth / s.columns - 2,
                            top: (s.startMin - firstHour * 60) * hourHeight / 60 + 6,
                            height: math.max(20, (s.endMin - s.startMin) * hourHeight / 60 - 2),
                            child: _Block(
                              occurrence: s.occurrence,
                              point: s.isPoint,
                              overlaps: week.days[i].overlapIds.contains(s.occurrence.id),
                            ),
                          ),
                      for (var i = 0; i < 7; i++)
                        if (week.days[i].isToday)
                          Builder(
                            builder: (context) {
                              final minutes = zones.toLocal(now, zone).time.minutesOfDay;
                              if (minutes < firstHour * 60 || minutes > lastHour * 60) return const SizedBox.shrink();
                              return Positioned(
                                left: _gutter + i * colWidth,
                                width: colWidth,
                                top: (minutes - firstHour * 60) * hourHeight / 60 + 6,
                                child: ExcludeSemantics(child: Container(height: 2, color: scheme.error)),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Block extends ConsumerWidget {
  const _Block({required this.occurrence, this.compact = false, this.point = false, this.overlaps = false, this.warn = false});

  final Occurrence occurrence;
  final bool compact;
  final bool point;
  final bool overlaps;
  final bool warn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.scheduleColors;
    final category = ref.watch(categoryByIdProvider(occurrence.categoryId));
    final fill = colors.categoryFill(category?.colorKey);
    final ink = colors.palette.cardInk;
    final strong =
        (colors.showCategoryColors ? CategoryColor.fromKey(category?.colorKey)?.resolve(colors.palette.brightness) : null) ??
        colors.accentText;
    final pixel = colors.style == StyleFamily.pixel;
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    final f = Formats.of(context);
    final t = occurrence.timing;
    final time = t is TimedTiming
        ? OccurrenceTimeText.of(t, zones, zone, f).range
        : (t is DateOnlyTiming ? 'All day' : 'Needs time review');
    final scaler = MediaQuery.textScalerOf(context);
    final titleLine = scaler.scale(11.5) * 1.17;
    final timeLine = scaler.scale(10.5) * 1.2;
    final titleStyle = TextStyle(fontSize: 11.5, height: 1.17, fontWeight: FontWeight.w600, color: ink);
    Text line(String value, TextStyle style) => Text(value, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: style);
    // The all-day strip gives compact blocks unbounded height, so they size to
    // one title line instead of stretching.
    final Widget body = compact
        ? Row(
            children: [
              if (!colors.outlined) Container(width: 3, height: titleLine, color: strong),
              Expanded(
                child: Padding(padding: const EdgeInsets.fromLTRB(4, 3, 3, 2), child: line(occurrence.title, titleStyle)),
              ),
            ],
          )
        : LayoutBuilder(
            builder: (context, outer) {
              // Three or more overlaps leave too little room for a bar and an
              // ellipsized title, so the block shows the title's first letter.
              final narrow = outer.maxWidth < 24;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!colors.outlined && !narrow) Container(width: 3, color: strong),
                  Expanded(
                    child: Padding(
                      padding: narrow ? const EdgeInsets.fromLTRB(2, 3, 2, 2) : const EdgeInsets.fromLTRB(4, 3, 3, 2),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final showTime = !narrow && t is TimedTiming && box.maxHeight >= titleLine + timeLine;
                          final room = box.maxHeight - (showTime ? timeLine : 0);
                          final lines = (room / titleLine).floor().clamp(1, 3);
                          final title = occurrence.title.trim();
                          final words = title.split(RegExp(r'\s+'));
                          final shown = narrow
                              ? [if (title.isNotEmpty) title.characters.first]
                              : [
                                  for (var k = 0; k < lines && k < words.length; k++)
                                    k == lines - 1 ? words.sublist(k).join(' ') : words[k],
                                ];
                          return ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topLeft,
                              maxHeight: double.infinity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                                children: [
                                  for (final w in shown)
                                    narrow
                                        ? Text(w, maxLines: 1, softWrap: false, overflow: TextOverflow.clip, style: titleStyle)
                                        : line(w, titleStyle),
                                  if (showTime)
                                    line(
                                      OccurrenceTimeText.of(t, zones, zone, f).start,
                                      TextStyle(fontSize: 10.5, height: 1.2, color: ink.withValues(alpha: .72)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
    return Semantics(
      button: true,
      label: '${occurrence.title}, $time${overlaps ? ', overlaps another schedule' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: compact ? 2 : 0),
        child: Material(
          key: const ValueKey('week-block'),
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pixel ? 0 : 8),
            side: colors.outlined
                ? BorderSide(color: colors.palette.outline, width: 1.5)
                : (warn || overlaps ? BorderSide(color: colors.inputBoundary) : BorderSide.none),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: () => showOccurrenceSheet(context, occurrence), child: body),
        ),
      ),
    );
  }
}

/// The grid's header: an ISO week number over the hour gutter, then one cell
/// per day built on the grid's own column width, so dates sit exactly above
/// their columns. The selected day's tint continues down the grid.
class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.days, required this.gutter, required this.colWidth, required this.selected, required this.onSelect});

  final List<DayView> days;
  final double gutter, colWidth;
  final LocalDate selected;
  final ValueChanged<LocalDate> onSelect;

  static Color tint(ScheduleColors c) => c.palette.accent.withValues(alpha: c.palette.brightness == Brightness.dark ? .14 : .08);

  static int isoWeek(LocalDate d) {
    final thursday = d.addDays(4 - d.weekday);
    return LocalDate(thursday.year, 1, 1).daysUntil(thursday) ~/ 7 + 1;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final p = c.palette;
    final f = Formats.of(context);
    final pixel = c.style == StyleFamily.pixel;
    final soft = c.style == StyleFamily.soft;
    return Row(
      children: [
        SizedBox(
          width: gutter,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'W${isoWeek(days.firstWhere((d) => d.date.weekday == 4, orElse: () => days.first).date)}',
                maxLines: 1,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .4, color: c.secondaryInk),
              ),
            ),
          ),
        ),
        for (final day in days)
          SizedBox(
            width: colWidth,
            child: Semantics(
              button: true,
              selected: day.date == selected,
              label: [f.dayTitle(day.date), if (day.isToday) 'today', if (!day.isEmpty) 'has schedules'].join(', '),
              excludeSemantics: true,
              child: Material(
                key: ValueKey('day-${day.date.toIso()}'),
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(pixel ? 0 : 14))),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelect(day.date),
                  child: Container(
                    key: day.date == selected ? const ValueKey('week-selected-header') : null,
                    color: day.date == selected ? tint(c) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          f.weekdayShort(day.date.weekday),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: day.date == selected ? FontWeight.w700 : FontWeight.w500,
                            color: day.date == selected ? c.accentText : c.secondaryInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: pixel ? BoxShape.rectangle : BoxShape.circle,
                            color: day.date == selected && !soft ? p.accent : null,
                            gradient: day.date == selected && soft
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [p.accent, Color.lerp(p.accent, const Color(0xFFFF7A59), .45)!],
                                  )
                                : null,
                            border: day.isToday && day.date != selected ? Border.all(color: c.accentText, width: 1.5) : null,
                          ),
                          child: FittedBox(
                            child: Text(
                              '${day.date.day}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: day.date == selected ? p.onAccent : c.ink,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: pixel ? BoxShape.rectangle : BoxShape.circle,
                            color: day.isEmpty ? Colors.transparent : c.accentText.withValues(alpha: .7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
