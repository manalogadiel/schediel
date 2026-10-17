import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/features/categories/domain/category.dart';
import 'package:schediel/features/schedules/application/day_view.dart';

void main() {
  late ZoneResolver zones;
  late DayViewBuilder builder;

  setUpAll(() {
    zones = ZoneResolver.initialized();
    builder = DayViewBuilder(zones, OccurrenceEngine(zones));
  });

  ScheduleSeries series(String id, {String? category, int hour = 9, List<int> weekdays = const [1, 3]}) => ScheduleSeries(
        id: id,
        revision: 1,
        title: 'Fixture $id',
        categoryId: category,
        time: TimedSpec(
          startDate: LocalDate(2026, 11, 2),
          startTime: LocalTime(hour, 0),
          timeZone: 'Asia/Manila',
          endTime: LocalTime(hour + 1, 0),
          endDayOffset: 0,
        ),
        recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: weekdays),
      );

  test('builds today with Now/Next from the injected time and the device zone', () {
    final view = builder.build(
      series: [series('a', hour: 9), series('b', hour: 11)],
      filter: const CategoryFilter.all(),
      date: LocalDate(2026, 11, 2),
      today: LocalDate(2026, 11, 2),
      now: DateTime.utc(2026, 11, 2, 1, 30),
      zone: 'Asia/Manila',
    );
    expect(view.agenda.ongoing.single.seriesId, 'a');
    expect(view.agenda.next!.seriesId, 'b');
    expect(view.hasAnySchedules, isTrue);
    expect(view.isEmpty, isFalse);
  });

  test('applies the category filter for visibility only', () {
    final view = builder.build(
      series: [series('a', category: 'school'), series('b', category: 'work', hour: 13), series('c', hour: 15)],
      filter: const CategoryFilter.only({'work'}, includeUncategorized: true),
      date: LocalDate(2026, 11, 4),
      today: LocalDate(2026, 11, 2),
      now: DateTime.utc(2026, 11, 2, 1),
      zone: 'Asia/Manila',
    );
    expect(view.agenda.timed.map((o) => o.seriesId), ['b', 'c']);
    expect(view.filterActive, isTrue);
  });

  test('flags overlapping occurrences', () {
    final view = builder.build(
      series: [series('a', hour: 9), series('b', hour: 9)],
      filter: const CategoryFilter.all(),
      date: LocalDate(2026, 11, 2),
      today: LocalDate(2026, 11, 1),
      now: DateTime.utc(2026, 11, 1),
      zone: 'Asia/Manila',
    );
    expect(view.overlapIds, hasLength(2));
  });

  test('reports an empty day and no schedules at all', () {
    final empty = builder.build(
      series: const [],
      filter: const CategoryFilter.all(),
      date: LocalDate(2026, 11, 2),
      today: LocalDate(2026, 11, 2),
      now: DateTime.utc(2026, 11, 2),
      zone: 'Asia/Manila',
    );
    expect(empty.hasAnySchedules, isFalse);
    expect(empty.isEmpty, isTrue);
  });

  test('shows the occurrence in the device zone when it differs from the source zone', () {
    final view = builder.build(
      series: [series('a', hour: 9)],
      filter: const CategoryFilter.all(),
      date: LocalDate(2026, 11, 1),
      today: LocalDate(2026, 11, 1),
      now: DateTime.utc(2026, 10, 31),
      zone: 'America/Los_Angeles',
    );
    expect(view.agenda.next!.originalKey, LocalDate(2026, 11, 2));
  });

  test('builds a week of day views from the week start', () {
    final week = builder.buildWeek(
      series: [series('a')],
      filter: const CategoryFilter.all(),
      weekStart: LocalDate(2026, 11, 2),
      today: LocalDate(2026, 11, 2),
      now: DateTime.utc(2026, 11, 2),
      zone: 'Asia/Manila',
    );
    expect(week.days, hasLength(7));
    expect([for (final d in week.days) d.agenda.timed.length + d.agenda.ongoing.length + (d.agenda.next == null ? 0 : 1) + d.agenda.upcoming.length + d.agenda.past.length],
        [1, 0, 1, 0, 0, 0, 0]);
  });
}
