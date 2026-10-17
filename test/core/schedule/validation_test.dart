import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/schedule/validation.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';

void main() {
  late SeriesValidator validator;

  setUpAll(() {
    final zones = ZoneResolver.initialized();
    validator = SeriesValidator(zones, OccurrenceEngine(zones));
  });

  ScheduleSeries base({
    String title = 'Fixture class',
    TimeSpec? time,
    RecurrenceSpec? recurrence,
    ScheduleDetails details = ScheduleDetails.empty,
    List<OccurrenceException> exceptions = const [],
  }) =>
      ScheduleSeries(
        id: 's1',
        revision: 1,
        title: title,
        time: time ??
            TimedSpec(
              startDate: LocalDate(2026, 11, 2),
              startTime: LocalTime(9, 0),
              timeZone: 'Asia/Manila',
              endTime: LocalTime(10, 30),
              endDayOffset: 0,
            ),
        recurrence: recurrence,
        details: details,
        exceptions: exceptions,
      );

  List<String> codes(ScheduleSeries s) => [for (final i in validator.validate(s)) '${i.path}:${i.code}'];

  test('accepts a complete timed schedule', () {
    expect(validator.validate(base()), isEmpty);
  });

  test('requires a trimmed, non-empty title within 120 code points', () {
    expect(codes(base(title: '')), ['title:invalid_text']);
    expect(codes(base(title: ' Fixture')), ['title:invalid_text']);
    expect(codes(base(title: 'a' * 121)), ['title:too_long']);
    expect(validator.validate(base(title: '\u{1F642}' * 120)), isEmpty);
  });

  test('rejects an end that is not after the start on the same day', () {
    final s = base(
      time: TimedSpec(
        startDate: LocalDate(2026, 11, 2),
        startTime: LocalTime(9, 0),
        timeZone: 'Asia/Manila',
        endTime: LocalTime(9, 0),
        endDayOffset: 0,
      ),
    );
    expect(codes(s), ['time/endTime:invalid_range']);
  });

  test('accepts an explicit no-end point event and a next-day end', () {
    expect(
      validator.validate(base(
        time: TimedSpec(startDate: LocalDate(2026, 11, 2), startTime: LocalTime(9, 0), timeZone: 'Asia/Manila'),
      )),
      isEmpty,
    );
    expect(
      validator.validate(base(
        time: TimedSpec(
          startDate: LocalDate(2026, 11, 2),
          startTime: LocalTime(22, 0),
          timeZone: 'Asia/Manila',
          endTime: LocalTime(6, 0),
          endDayOffset: 1,
        ),
        recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.daily),
      )),
      isEmpty,
    );
  });

  test('rejects unknown zones and inconsistent end pairing', () {
    expect(
      codes(base(time: TimedSpec(startDate: LocalDate(2026, 11, 2), startTime: LocalTime(9, 0), timeZone: '+08:00'))),
      ['time/timeZone:invalid_time_zone'],
    );
    expect(
      codes(base(
        time: TimedSpec(
          startDate: LocalDate(2026, 11, 2),
          startTime: LocalTime(9, 0),
          timeZone: 'Asia/Manila',
          endTime: LocalTime(10, 0),
        ),
      )),
      ['time/endDayOffset:invalid_value'],
    );
  });

  test('requires weekdays for weekly rules and an until date on or after the start', () {
    expect(
      codes(base(recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly))),
      ['recurrence/weekdays:invalid_recurrence'],
    );
    expect(
      codes(base(
        recurrence: RecurrenceSpec(
          frequency: RecurrenceFrequency.weekly,
          weekdays: [1],
          untilDateInclusive: LocalDate(2026, 11, 1),
        ),
      )),
      ['recurrence/untilDateInclusive:invalid_range'],
    );
  });

  test('limits date-only spans and requires single-day recurring date-only items', () {
    final range = DateOnlySpec(startDate: LocalDate(2026, 12, 1), endDateExclusive: LocalDate(2026, 12, 4));
    expect(validator.validate(base(time: range)), isEmpty);
    expect(
      codes(base(time: range, recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.daily))),
      ['time/endDateExclusive:invalid_range'],
    );
    expect(
      codes(base(time: DateOnlySpec(startDate: LocalDate(2026, 12, 1), endDateExclusive: LocalDate(2027, 12, 3)))),
      ['time/endDateExclusive:invalid_range'],
    );
  });

  test('bounds optional details by code points and rejects blank values', () {
    expect(
      codes(base(details: ScheduleDetails(location: 'r' * 241, professor: 'p' * 161, notes: ''))),
      ['details/location:too_long', 'details/professor:too_long', 'details/notes:invalid_text'],
    );
  });

  test('validates exceptions against the original rule', () {
    final weekly = RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [1, 3]);
    expect(
      codes(base(recurrence: weekly, exceptions: [
        OccurrenceException(originalKey: LocalDate(2026, 11, 5), action: ExceptionAction.cancel),
      ])),
      ['exceptions/0/originalOccurrenceKey:invalid_exception'],
    );
    expect(
      codes(base(exceptions: [
        OccurrenceException(originalKey: LocalDate(2026, 11, 2), action: ExceptionAction.cancel),
      ])),
      ['exceptions/0:invalid_exception'],
    );
    expect(
      codes(base(recurrence: weekly, exceptions: [
        OccurrenceException(originalKey: LocalDate(2026, 11, 4), action: ExceptionAction.override),
      ])),
      ['exceptions/0/replacement:invalid_exception'],
    );
  });
}
