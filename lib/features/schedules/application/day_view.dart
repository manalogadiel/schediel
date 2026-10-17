import 'package:flutter/foundation.dart';

import '../../../core/schedule/agenda.dart';
import '../../../core/schedule/models.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/schedule/occurrence_engine.dart';
import '../../../core/schedule/overlap.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/zone_resolver.dart';
import '../../categories/domain/category.dart';

/// One day of the timeline, derived from committed data, the active filter,
/// the device zone and an injected time.
@immutable
class DayView {
  const DayView({
    required this.date,
    required this.isToday,
    required this.agenda,
    required this.overlapIds,
    required this.hasAnySchedules,
    required this.filterActive,
    required this.truncated,
  });

  final LocalDate date;
  final bool isToday;
  final DayAgenda agenda;
  final Set<String> overlapIds;

  /// Whether any schedule exists at all, regardless of filter and day.
  final bool hasAnySchedules;
  final bool filterActive;
  final bool truncated;

  bool get isEmpty => agenda.isEmpty;

  /// Every occurrence of the day, for counts and accessibility summaries.
  List<Occurrence> get all => [
        ...agenda.dateOnly,
        ...agenda.needsReview,
        ...agenda.ongoing,
        if (agenda.next != null) agenda.next!,
        ...agenda.upcoming,
        ...agenda.timed,
        ...agenda.past,
      ];
}

@immutable
class WeekView {
  const WeekView({required this.weekStart, required this.days});
  final LocalDate weekStart;
  final List<DayView> days;
}

class DayViewBuilder {
  DayViewBuilder(this.zones, this.engine);

  final ZoneResolver zones;
  final OccurrenceEngine engine;

  DayView build({
    required List<ScheduleSeries> series,
    required CategoryFilter filter,
    required LocalDate date,
    required LocalDate today,
    required DateTime now,
    required String zone,
  }) {
    final visible = [for (final s in series) if (filter.matches(s.categoryId)) s];
    final (start, end) = dayWindow(zones, date, zone);
    final occurrences = <Occurrence>[];
    var truncated = false;
    for (final s in visible) {
      final result = engine.expand(s, windowStart: start, windowEnd: end, viewZone: zone);
      occurrences.addAll(result.occurrences);
      truncated = truncated || result.truncated;
    }
    final isToday = date == today;
    return DayView(
      date: date,
      isToday: isToday,
      agenda: buildDayAgenda(occurrences, now: now, mode: isToday ? AgendaMode.today : AgendaMode.otherDay),
      overlapIds: overlappingIds(occurrences),
      hasAnySchedules: series.isNotEmpty,
      filterActive: !filter.isAll,
      truncated: truncated,
    );
  }

  WeekView buildWeek({
    required List<ScheduleSeries> series,
    required CategoryFilter filter,
    required LocalDate weekStart,
    required LocalDate today,
    required DateTime now,
    required String zone,
  }) =>
      WeekView(
        weekStart: weekStart,
        days: [
          for (var i = 0; i < 7; i++)
            build(series: series, filter: filter, date: weekStart.addDays(i), today: today, now: now, zone: zone),
        ],
      );
}
