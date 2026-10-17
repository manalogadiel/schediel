import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/features/schedules/application/occurrence_lookup.dart';

void main() {
  late OccurrenceLookup lookup;

  setUpAll(() {
    final zones = ZoneResolver.initialized();
    lookup = OccurrenceLookup(zones, OccurrenceEngine(zones));
  });

  final series = ScheduleSeries(
    id: 's1',
    revision: 2,
    title: 'Fixture class',
    time: TimedSpec(
      startDate: LocalDate(2026, 11, 2),
      startTime: LocalTime(9, 0),
      timeZone: 'Asia/Manila',
      endTime: LocalTime(10, 0),
      endDayOffset: 0,
    ),
    recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [1]),
    exceptions: [
      OccurrenceException(originalKey: LocalDate(2026, 11, 9), action: ExceptionAction.cancel),
      OccurrenceException(
        originalKey: LocalDate(2026, 11, 16),
        action: ExceptionAction.override,
        replacement: OccurrenceReplacement(
          title: 'Fixture class moved',
          time: TimedSpec(
            startDate: LocalDate(2026, 12, 1),
            startTime: LocalTime(15, 0),
            timeZone: 'Asia/Manila',
          ),
          details: ScheduleDetails.empty,
        ),
      ),
    ],
  );

  test('finds a regular occurrence by its original key', () {
    final o = lookup.find(series, LocalDate(2026, 11, 2), 'Asia/Manila');
    expect((o!.timing as TimedTiming).startUtc, DateTime.utc(2026, 11, 2, 1));
  });

  test('finds an override even when it moved to another week', () {
    final o = lookup.find(series, LocalDate(2026, 11, 16), 'Asia/Manila');
    expect(o!.isOverride, isTrue);
    expect((o.timing as TimedTiming).startUtc, DateTime.utc(2026, 12, 1, 7));
  });

  test('returns null for cancelled occurrences and dates outside the rule', () {
    expect(lookup.find(series, LocalDate(2026, 11, 9), 'Asia/Manila'), isNull);
    expect(lookup.find(series, LocalDate(2026, 11, 3), 'Asia/Manila'), isNull);
  });
}
