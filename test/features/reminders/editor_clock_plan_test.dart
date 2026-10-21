import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/features/reminders/application/clock_handoff.dart';

void main() {
  late ProviderContainer container;
  late ClockHandoffService service;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 2, 0, 30)),
        initialDeviceZoneProvider.overrideWithValue('Asia/Manila'),
        zoneResolverProvider.overrideWithValue(ZoneResolver.initialized()),
      ],
    );
    service = container.read(clockHandoffProvider);
  });
  tearDown(() => container.dispose());

  ScheduleSeries fixture({
    int day = 2,
    RecurrenceSpec? recurrence,
    String zone = 'Asia/Manila',
    List<OccurrenceException> exceptions = const [],
  }) => ScheduleSeries(
    id: 'fixture',
    revision: 1,
    title: 'Fixture class',
    time: TimedSpec(startDate: LocalDate(2026, 11, day), startTime: LocalTime(9, 0), timeZone: zone),
    recurrence: recurrence,
    exceptions: exceptions,
  );

  test('one-time Clock alarm uses the future trigger including its lead time', () {
    expect(service.nextFor(fixture(), 10)!.plan.time, LocalTime(8, 50));
    expect(service.nextFor(fixture(), 60), isNull);
    expect(service.nextFor(fixture(day: 4), 0), isNull);
    expect(service.nextFor(fixture(zone: 'UTC'), 0), isNull);
  });
  test('weekly alarm preserves selected weekdays and does not start before its schedule', () {
    final rule = RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [1, 3]);
    final target = service.nextFor(fixture(recurrence: rule), 10)!;
    expect(target.occurrence.originalKey, LocalDate(2026, 11, 2));
    expect(target.plan.weekdays, [1, 3]);
    expect(target.plan.time, LocalTime(8, 50));
    expect(service.nextFor(fixture(day: 4, recurrence: rule), 10), isNull);
  });
  test('a cancelled next occurrence is not handed to Clock as an earlier alarm', () {
    final series = fixture(
      recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [1, 3]),
      exceptions: [OccurrenceException(originalKey: LocalDate(2026, 11, 2), action: ExceptionAction.cancel)],
    );
    expect(service.nextFor(series, 10), isNull);
  });
}
