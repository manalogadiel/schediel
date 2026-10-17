import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import '../../../core/time/zone_resolver.dart';
import '../../categories/domain/category.dart';
import '../application/day_view.dart';
import 'occurrence_sheet.dart';
import 'timeline_row.dart';

/// Week: a time grid with an equivalent agenda (spec 4.4).
class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  int _weekOffset = 0;
  bool? _agenda;

  LocalDate _weekStart(BuildContext context, LocalDate today) {
    final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final isoStart = first == 0 ? 7 : first;
    final back = (today.weekday - isoStart + 7) % 7;
    return today.addDays(-back + 7 * _weekOffset);
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final start = _weekStart(context, today);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Week', style: text.labelMedium?.copyWith(color: context.scheduleColors.secondaryInk)),
                  Semantics(header: true, child: Text(f.range(start, start.addDays(6)), style: text.headlineMedium)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.sm, Tokens.xs, Tokens.md, Tokens.sm),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous week',
                    onPressed: () => setState(() => _weekOffset--),
                    icon: const AppIcon(AppIcons.previous),
                  ),
                  IconButton(
                    tooltip: 'Next week',
                    onPressed: () => setState(() => _weekOffset++),
                    icon: const AppIcon(AppIcons.next),
                  ),
                  if (_weekOffset != 0)
                    TextButton(onPressed: () => setState(() => _weekOffset = 0), child: const Text('This week')),
                  const Spacer(),
                  IconButton(
                    tooltip: agenda ? 'Show time grid' : 'Show agenda',
                    onPressed: () => setState(() => _agenda = !agenda),
                    icon: AppIcon(agenda ? AppIcons.grid : AppIcons.agenda),
                  ),
                  const SizedBox(width: Tokens.xs),
                  const FilterPill(),
                ],
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
                  if (empty) {
                    final any = w.days.first.hasAnySchedules;
                    final filtered = w.days.first.filterActive;
                    return ListView(children: [
                      EmptyState(
                        title: !any
                            ? 'No schedules yet'
                            : filtered
                                ? 'No schedules in this filter'
                                : 'No schedules this week',
                        action: !any
                            ? FilledButton(onPressed: () => context.push('/schedule/new'), child: const Text('Create schedule'))
                            : filtered
                                ? TextButton(
                                    onPressed: () => ref.read(appFilterProvider.notifier).set(const CategoryFilter.all()),
                                    child: const Text('Show all'),
                                  )
                                : null,
                      ),
                    ]);
                  }
                  return agenda ? _WeekAgenda(week: w) : _WeekGrid(week: w);
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.xxl),
      children: [
        for (final day in week.days)
          if (!day.isEmpty)
            SectionGroup(
              header: '${f.dayTitle(day.date)}${day.isToday ? ' · Today' : ''}',
              children: [
                for (final o in [...day.agenda.dateOnly, ...day.agenda.needsReview, ...day.all.where((o) => o.timing is TimedTiming)])
                  TimelineRow(occurrence: o, overlaps: day.overlapIds.contains(o.id)),
              ],
            ),
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

class _WeekGrid extends ConsumerWidget {
  const _WeekGrid({required this.week});

  final WeekView week;

  static const _gutter = 44.0;

  List<_Segment> _segments(DayView day, ZoneResolver zones, String zone) {
    final (dayStart, dayEnd) = (zones.startOfDay(day.date, zone), zones.startOfDay(day.date.addDays(1), zone));
    final dayMinutes = dayEnd.difference(dayStart).inMinutes;
    final result = <_Segment>[];
    for (final o in day.all) {
      final t = o.timing;
      if (t is! TimedTiming) continue;
      final start = math.max(0, t.startUtc.difference(dayStart).inMinutes);
      final end = t.endUtc == null ? start + 30 : math.min(dayMinutes, t.endUtc!.difference(dayStart).inMinutes);
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
      final used = {for (final c in cluster) if (c.endMin > s.startMin) c.column};
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
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    final now = ref.watch(nowProvider);
    final f = Formats.of(context);
    final colors = context.scheduleColors;
    final scheme = Theme.of(context).colorScheme;
    final hourHeight = colors.density == Density.compact ? 40.0 : 48.0;

    final perDay = [for (final d in week.days) _segments(d, zones, zone)];
    var firstHour = 8;
    var lastHour = 18;
    for (final segs in perDay) {
      for (final s in segs) {
        firstHour = math.min(firstHour, s.startMin ~/ 60);
        lastHour = math.max(lastHour, ((s.endMin + 59) ~/ 60).clamp(0, 24));
      }
    }
    final hours = lastHour - firstHour;
    final hasStrip = week.days.any((d) => d.agenda.dateOnly.isNotEmpty || d.agenda.needsReview.isNotEmpty);

    return LayoutBuilder(builder: (context, constraints) {
      final colWidth = (constraints.maxWidth - _gutter - Tokens.md) / 7;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: _gutter, right: Tokens.md),
            child: Row(
              children: [
                for (final d in week.days)
                  SizedBox(
                    width: colWidth,
                    child: Semantics(
                      label: '${f.dayTitle(d.date)}${d.isToday ? ', today' : ''}',
                      excludeSemantics: true,
                      child: Column(children: [
                        Text(f.weekdayShort(d.date.weekday), style: TextStyle(fontSize: 12, color: colors.secondaryInk)),
                        const SizedBox(height: 2),
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: d.isToday ? BoxDecoration(color: scheme.primary, shape: BoxShape.circle) : null,
                          child: Text(
                            '${d.date.day}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: d.isToday ? scheme.onPrimary : colors.ink,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
              ],
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
                      child: Column(children: [
                        for (final o in [...d.agenda.dateOnly, ...d.agenda.needsReview])
                          _Block(occurrence: o, compact: true, warn: o.timing is UnresolvedTiming),
                      ]),
                    ),
                ],
              ),
            ),
          const SizedBox(height: Tokens.xs),
          Divider(color: colors.divider),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: Tokens.xxl),
              child: SizedBox(
                height: hours * hourHeight + Tokens.sm,
                child: Stack(
                  children: [
                    for (var h = 0; h <= hours; h++)
                      Positioned(
                        top: h * hourHeight,
                        left: 0,
                        right: Tokens.md,
                        child: Row(children: [
                          SizedBox(
                            width: _gutter,
                            child: ExcludeSemantics(
                              child: Text(
                                f.clock(LocalTime((firstHour + h) % 24, 0)),
                                style: TextStyle(fontSize: 11, color: colors.secondaryInk),
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: colors.divider.withValues(alpha: 0.6))),
                        ]),
                      ),
                    for (var i = 0; i < 7; i++)
                      for (final s in perDay[i])
                        Positioned(
                          left: _gutter + i * colWidth + s.column * (colWidth / s.columns) + 1,
                          width: colWidth / s.columns - 2,
                          top: (s.startMin - firstHour * 60) * hourHeight / 60 + 6,
                          height: math.max(20, (s.endMin - s.startMin) * hourHeight / 60 - 2),
                          child: _Block(occurrence: s.occurrence, point: s.isPoint, overlaps: week.days[i].overlapIds.contains(s.occurrence.id)),
                        ),
                    for (var i = 0; i < 7; i++)
                      if (week.days[i].isToday)
                        Builder(builder: (context) {
                          final minutes = now.toUtc().difference(zones.startOfDay(week.days[i].date, zone)).inMinutes;
                          if (minutes < firstHour * 60 || minutes > lastHour * 60) return const SizedBox.shrink();
                          return Positioned(
                            left: _gutter + i * colWidth,
                            width: colWidth,
                            top: (minutes - firstHour * 60) * hourHeight / 60 + 6,
                            child: ExcludeSemantics(child: Container(height: 2, color: scheme.error)),
                          );
                        }),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
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
    final scheme = Theme.of(context).colorScheme;
    final category = ref.watch(categoryByIdProvider(occurrence.categoryId));
    final categoryColor = colors.showCategoryColors ? CategoryColor.fromKey(category?.colorKey) : null;
    final accent = categoryColor?.resolve(Theme.of(context).brightness) ?? scheme.primary;
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    final f = Formats.of(context);
    final t = occurrence.timing;
    final time = t is TimedTiming ? OccurrenceTimeText.of(t, zones, zone, f).range : (t is DateOnlyTiming ? 'All day' : 'Needs time review');
    return Semantics(
      button: true,
      label: '${occurrence.title}, $time${overlaps ? ', overlaps another schedule' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: compact ? 2 : 0),
        child: Material(
          color: accent.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: warn || overlaps ? BorderSide(color: colors.inputBoundary) : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showOccurrenceSheet(context, occurrence),
            child: Container(
              decoration: BoxDecoration(border: Border(left: BorderSide(color: accent, width: 3))),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              alignment: Alignment.topLeft,
              child: Text(
                occurrence.title,
                maxLines: compact ? 1 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w600, color: colors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
