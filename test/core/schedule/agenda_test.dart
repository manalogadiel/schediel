import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/agenda.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence.dart';
import 'package:schediel/core/schedule/overlap.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';

Occurrence timed(String id, DateTime start, DateTime? end, {String title = 'Fixture'}) => Occurrence(
      seriesId: id,
      originalKey: LocalDate(2026, 11, 2),
      title: title,
      categoryId: null,
      details: ScheduleDetails.empty,
      timing: TimedTiming(
        startUtc: start,
        endUtc: end,
        sourceZone: 'Asia/Manila',
        localStartDate: LocalDate(2026, 11, 2),
        localStartTime: LocalTime(0, 0),
      ),
      isOverride: false,
      seriesRevision: 1,
      isRecurring: false,
    );

Occurrence dateOnly(String id) => Occurrence(
      seriesId: id,
      originalKey: LocalDate(2026, 11, 2),
      title: 'Fixture all day',
      categoryId: null,
      details: ScheduleDetails.empty,
      timing: DateOnlyTiming(startDate: LocalDate(2026, 11, 2), endDateExclusive: LocalDate(2026, 11, 3)),
      isOverride: false,
      seriesRevision: 1,
      isRecurring: false,
    );

Occurrence unresolved(String id) => Occurrence(
      seriesId: id,
      originalKey: LocalDate(2026, 11, 2),
      title: 'Fixture unresolved',
      categoryId: null,
      details: ScheduleDetails.empty,
      timing: UnresolvedTiming(
        localDate: LocalDate(2026, 11, 2),
        localStartTime: LocalTime(1, 30),
        sourceZone: 'America/New_York',
        reason: TimeReviewReason.startAmbiguous,
      ),
      isOverride: false,
      seriesRevision: 1,
      isRecurring: false,
    );

DateTime at(int hour, [int minute = 0]) => DateTime.utc(2026, 11, 2, hour, minute);

void main() {
  final a = timed('a', at(1), at(2, 30));
  final b = timed('b', at(3), at(4));
  final c = timed('c', at(3), null);
  final d = dateOnly('d');
  final e = unresolved('e');
  final all = [d, e, a, b, c];

  group('today agenda', () {
    test('before the first class: next is the earliest future start', () {
      final agenda = buildDayAgenda(all, now: at(0), mode: AgendaMode.today);
      expect(agenda.dateOnly, [d]);
      expect(agenda.needsReview, [e]);
      expect(agenda.ongoing, isEmpty);
      expect(agenda.next, a);
      expect(agenda.upcoming, [c, b]);
      expect(agenda.past, isEmpty);
    });

    test('during a class: it is ongoing and the next start follows', () {
      final agenda = buildDayAgenda(all, now: at(1, 30), mode: AgendaMode.today);
      expect(agenda.ongoing, [a]);
      expect(agenda.next, c);
      expect(agenda.upcoming, [b]);
    });

    test('a point event becomes past at its start; simultaneous ongoing entries all stay visible', () {
      final overlapping = timed('f', at(3), at(5));
      final agenda = buildDayAgenda([...all, overlapping], now: at(3), mode: AgendaMode.today);
      expect(agenda.ongoing, [b, overlapping]);
      expect(agenda.past, [a, c]);
      expect(agenda.next, isNull);
      expect(agenda.isFinished, isFalse);
    });

    test('when everything has ended the day is finished', () {
      final agenda = buildDayAgenda([a, b], now: at(6), mode: AgendaMode.today);
      expect(agenda.past, [a, b]);
      expect(agenda.isFinished, isTrue);
    });

    test('ties are broken by end, then normalized title, then id', () {
      final x = timed('x', at(8), at(10), title: 'beta');
      final y = timed('y', at(8), at(9), title: 'alpha');
      final z = timed('z', at(8), at(10), title: ' Alpha');
      final agenda = buildDayAgenda([x, y, z], now: at(7), mode: AgendaMode.today);
      expect([agenda.next, ...agenda.upcoming], [y, z, x]);
    });
  });

  test('other days list actual times without Now or Next', () {
    final agenda = buildDayAgenda(all, now: at(1, 30), mode: AgendaMode.otherDay);
    expect(agenda.ongoing, isEmpty);
    expect(agenda.next, isNull);
    expect(agenda.timed, [a, c, b]);
    expect(agenda.dateOnly, [d]);
  });

  group('overlaps', () {
    test('flags intersecting intervals and points inside intervals but not adjacent ones', () {
      final p = timed('p', at(9), at(10));
      final q = timed('q', at(10), at(11));
      final r = timed('r', at(9, 30), at(9, 45));
      final s = timed('s', at(10), null);
      final t = timed('t', at(12), null);
      final u = timed('u', at(12), null);
      final ids = overlappingIds([p, q, r, s, t, u]);
      expect(ids, {'p/2026-11-02', 'r/2026-11-02', 'q/2026-11-02', 's/2026-11-02', 't/2026-11-02', 'u/2026-11-02'});
      expect(overlappingIds([p, q]), isEmpty);
    });

    test('ignores date-only and unresolved occurrences for timed overlap', () {
      expect(overlappingIds([a, d, e]), isEmpty);
    });
  });
}
