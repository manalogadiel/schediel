import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';

void main() {
  late ZoneResolver zones;
  late OccurrenceEngine engine;

  setUpAll(() {
    zones = ZoneResolver.initialized();
    engine = OccurrenceEngine(zones);
  });

  ScheduleSeries series({
    TimeSpec? time,
    RecurrenceSpec? recurrence,
    List<OccurrenceException> exceptions = const [],
  }) =>
      ScheduleSeries(
        id: 's1',
        revision: 1,
        title: 'Fixture class',
        time: time ??
            TimedSpec(
              startDate: LocalDate(2026, 11, 2),
              startTime: LocalTime(9, 0),
              timeZone: 'Asia/Manila',
              endTime: LocalTime(10, 30),
              endDayOffset: 0,
            ),
        recurrence: recurrence,
        exceptions: exceptions,
      );

  List<String> keys(List<Occurrence> list) => [for (final o in list) o.originalKey.toIso()];

  test('expands a one-time timed schedule to one resolved occurrence', () {
    final result = engine.expand(
      series(),
      windowStart: DateTime.utc(2026, 11, 1),
      windowEnd: DateTime.utc(2026, 11, 3),
      viewZone: 'Asia/Manila',
    );
    expect(result.occurrences, hasLength(1));
    final timing = result.occurrences.single.timing as TimedTiming;
    expect(timing.startUtc, DateTime.utc(2026, 11, 2, 1));
    expect(timing.endUtc, DateTime.utc(2026, 11, 2, 2, 30));
    expect(result.occurrences.single.id, 's1/2026-11-02');
  });

  test('expands weekly weekdays inside the window and stops at the until date', () {
    final result = engine.expand(
      series(
        recurrence: RecurrenceSpec(
          frequency: RecurrenceFrequency.weekly,
          weekdays: [1, 3],
          untilDateInclusive: LocalDate(2026, 11, 18),
        ),
      ),
      windowStart: DateTime.utc(2026, 10, 31),
      windowEnd: DateTime.utc(2026, 12, 1),
      viewZone: 'Asia/Manila',
    );
    expect(keys(result.occurrences), [
      '2026-11-02',
      '2026-11-04',
      '2026-11-09',
      '2026-11-11',
      '2026-11-16',
      '2026-11-18',
    ]);
    expect(result.truncated, isFalse);
  });

  test('starts a weekly rule on the first selected weekday after an unselected seed date', () {
    final s = series(
      time: TimedSpec(
        startDate: LocalDate(2026, 11, 3),
        startTime: LocalTime(9, 0),
        timeZone: 'Asia/Manila',
      ),
      recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [1, 3]),
    );
    final result = engine.expand(
      s,
      windowStart: DateTime.utc(2026, 11, 1),
      windowEnd: DateTime.utc(2026, 11, 10),
      viewZone: 'Asia/Manila',
    );
    expect(keys(result.occurrences), ['2026-11-04', '2026-11-09']);
    expect(engine.isOriginalDate(s, LocalDate(2026, 11, 3)), isFalse);
    expect(engine.isOriginalDate(s, LocalDate(2026, 11, 4)), isTrue);
  });

  test('caps an unbounded daily rule and reports truncation', () {
    final result = engine.expand(
      series(recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.daily)),
      windowStart: DateTime.utc(2026, 11, 1),
      windowEnd: DateTime.utc(2027, 11, 1),
      viewZone: 'Asia/Manila',
      cap: 10,
    );
    expect(result.occurrences, hasLength(10));
    expect(result.truncated, isTrue);
  });

  test('cancels and overrides individual occurrences by original key', () {
    final moved = OccurrenceReplacement(
      title: 'Fixture class (moved)',
      time: TimedSpec(
        startDate: LocalDate(2026, 11, 10),
        startTime: LocalTime(13, 0),
        timeZone: 'Asia/Manila',
        endTime: LocalTime(14, 30),
        endDayOffset: 0,
      ),
      details: const ScheduleDetails(location: 'Fixture room'),
    );
    final result = engine.expand(
      series(
        recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [1, 3]),
        exceptions: [
          OccurrenceException(originalKey: LocalDate(2026, 11, 4), action: ExceptionAction.cancel),
          OccurrenceException(
            originalKey: LocalDate(2026, 11, 9),
            action: ExceptionAction.override,
            replacement: moved,
          ),
        ],
      ),
      windowStart: DateTime.utc(2026, 11, 1),
      windowEnd: DateTime.utc(2026, 11, 12),
      viewZone: 'Asia/Manila',
    );
    expect(keys(result.occurrences), ['2026-11-02', '2026-11-09', '2026-11-11']);
    final override = result.occurrences[1];
    expect(override.isOverride, isTrue);
    expect(override.title, 'Fixture class (moved)');
    expect((override.timing as TimedTiming).startUtc, DateTime.utc(2026, 11, 10, 5));
    expect(override.details.location, 'Fixture room');
  });

  test('includes an overnight occurrence that started the previous local day', () {
    final s = series(
      time: TimedSpec(
        startDate: LocalDate(2026, 11, 4),
        startTime: LocalTime(22, 0),
        timeZone: 'America/New_York',
        endTime: LocalTime(6, 0),
        endDayOffset: 1,
      ),
      recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.daily),
    );
    final result = engine.expand(
      s,
      windowStart: DateTime.utc(2026, 11, 5, 10),
      windowEnd: DateTime.utc(2026, 11, 5, 11),
      viewZone: 'America/New_York',
    );
    expect(keys(result.occurrences), ['2026-11-04']);
    final timing = result.occurrences.single.timing as TimedTiming;
    expect(timing.startUtc, DateTime.utc(2026, 11, 5, 3));
    expect(timing.endUtc, DateTime.utc(2026, 11, 5, 11));
  });

  test('marks a future occurrence in a DST fold for review instead of guessing', () {
    final s = series(
      time: TimedSpec(
        startDate: LocalDate(2026, 10, 30),
        startTime: LocalTime(1, 30),
        timeZone: 'America/New_York',
      ),
      recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.daily),
    );
    final result = engine.expand(
      s,
      windowStart: DateTime.utc(2026, 10, 31),
      windowEnd: DateTime.utc(2026, 11, 3),
      viewZone: 'America/New_York',
    );
    final fold = result.occurrences.firstWhere((o) => o.originalKey == LocalDate(2026, 11, 1));
    expect(fold.timing, isA<UnresolvedTiming>());
    expect((fold.timing as UnresolvedTiming).reason, TimeReviewReason.startAmbiguous);
    final others = result.occurrences.where((o) => o.originalKey != LocalDate(2026, 11, 1));
    expect(others.every((o) => o.timing is TimedTiming), isTrue);
  });

  test('applies the explicit seed resolution to an ambiguous seed occurrence only', () {
    final s = series(
      time: TimedSpec(
        startDate: LocalDate(2026, 11, 1),
        startTime: LocalTime(1, 30),
        timeZone: 'America/New_York',
        seedTimeResolution: TimeResolution.later,
      ),
    );
    final result = engine.expand(
      s,
      windowStart: DateTime.utc(2026, 11, 1),
      windowEnd: DateTime.utc(2026, 11, 2),
      viewZone: 'America/New_York',
    );
    expect((result.occurrences.single.timing as TimedTiming).startUtc, DateTime.utc(2026, 11, 1, 6, 30));
  });

  test('marks a wall time inside a spring-forward gap as needing review', () {
    final s = series(
      time: TimedSpec(
        startDate: LocalDate(2026, 3, 7),
        startTime: LocalTime(2, 30),
        timeZone: 'America/New_York',
      ),
      recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.daily),
    );
    final result = engine.expand(
      s,
      windowStart: DateTime.utc(2026, 3, 7),
      windowEnd: DateTime.utc(2026, 3, 10),
      viewZone: 'America/New_York',
    );
    final gap = result.occurrences.firstWhere((o) => o.originalKey == LocalDate(2026, 3, 8));
    expect((gap.timing as UnresolvedTiming).reason, TimeReviewReason.startNonexistent);
  });

  test('keeps a point event without an invented end', () {
    final s = series(
      time: TimedSpec(startDate: LocalDate(2026, 11, 2), startTime: LocalTime(11, 0), timeZone: 'Asia/Manila'),
    );
    final result = engine.expand(
      s,
      windowStart: DateTime.utc(2026, 11, 2),
      windowEnd: DateTime.utc(2026, 11, 3),
      viewZone: 'Asia/Manila',
    );
    expect((result.occurrences.single.timing as TimedTiming).endUtc, isNull);
  });

  test('maps date-only ranges into the window through the view zone without inventing times', () {
    final s = series(
      time: DateOnlySpec(startDate: LocalDate(2026, 12, 1), endDateExclusive: LocalDate(2026, 12, 4)),
    );
    final inside = engine.expand(
      s,
      windowStart: zones.startOfDay(LocalDate(2026, 12, 3), 'Asia/Manila'),
      windowEnd: zones.startOfDay(LocalDate(2026, 12, 4), 'Asia/Manila'),
      viewZone: 'Asia/Manila',
    );
    expect(inside.occurrences, hasLength(1));
    expect(inside.occurrences.single.timing, isA<DateOnlyTiming>());
    final after = engine.expand(
      s,
      windowStart: zones.startOfDay(LocalDate(2026, 12, 4), 'Asia/Manila'),
      windowEnd: zones.startOfDay(LocalDate(2026, 12, 5), 'Asia/Manila'),
      viewZone: 'Asia/Manila',
    );
    expect(after.occurrences, isEmpty);
  });

  test('lists original dates of a rule within a bounded range', () {
    final s = series(
      recurrence: RecurrenceSpec(
        frequency: RecurrenceFrequency.weekly,
        weekdays: [3],
        untilDateInclusive: LocalDate(2026, 11, 25),
      ),
    );
    expect(
      engine.originalDates(s, LocalDate(2026, 11, 1), LocalDate(2026, 12, 31)).map((d) => d.toIso()),
      ['2026-11-04', '2026-11-11', '2026-11-18', '2026-11-25'],
    );
    expect(engine.isOriginalDate(s, LocalDate(2026, 12, 2)), isFalse);
  });
}
