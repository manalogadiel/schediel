import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';

void main() {
  group('LocalDate', () {
    test('parses a real ISO date and reports its ISO weekday', () {
      final date = LocalDate.parse('2026-11-02');
      expect(date.year, 2026);
      expect(date.month, 11);
      expect(date.day, 2);
      expect(date.weekday, DateTime.monday);
      expect(date.toIso(), '2026-11-02');
    });

    test('rejects impossible, malformed and out-of-range dates', () {
      for (final value in [
        '2026-02-30',
        '2026-2-3',
        '2026-13-01',
        '2026-00-10',
        '20261102',
        '2200-01-01',
        '1899-12-31',
        ' 2026-11-02',
        '',
      ]) {
        expect(LocalDate.tryParse(value), isNull, reason: value);
      }
      expect(LocalDate.tryParse('2028-02-29'), LocalDate(2028, 2, 29));
      expect(() => LocalDate(2026, 2, 29), throwsArgumentError);
    });

    test('adds days across month, year and leap boundaries', () {
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
      expect(LocalDate(2028, 2, 28).addDays(1), LocalDate(2028, 2, 29));
      expect(LocalDate(2026, 3, 1).addDays(-1), LocalDate(2026, 2, 28));
      expect(LocalDate(2026, 11, 2).addDays(14), LocalDate(2026, 11, 16));
    });

    test('measures whole days between dates', () {
      expect(LocalDate(2026, 11, 2).daysUntil(LocalDate(2026, 11, 9)), 7);
      expect(LocalDate(2026, 11, 9).daysUntil(LocalDate(2026, 11, 2)), -7);
      expect(LocalDate(2026, 12, 1).daysUntil(LocalDate(2027, 12, 1)), 365);
    });

    test('orders and compares by calendar position', () {
      final a = LocalDate(2026, 11, 2);
      final b = LocalDate(2026, 11, 3);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.compareTo(b), lessThan(0));
      expect(a, LocalDate.parse('2026-11-02'));
      expect({a, LocalDate(2026, 11, 2)}.length, 1);
    });

    test('round-trips through epoch days', () {
      final date = LocalDate(2026, 11, 2);
      expect(LocalDate.fromEpochDay(date.epochDay), date);
      expect(LocalDate(1970, 1, 1).epochDay, 0);
    });
  });

  group('LocalTime', () {
    test('parses strict 24-hour HH:mm values', () {
      final time = LocalTime.parse('09:05');
      expect(time.hour, 9);
      expect(time.minute, 5);
      expect(time.minutesOfDay, 545);
      expect(time.toHhMm(), '09:05');
    });

    test('rejects malformed clock values', () {
      for (final value in ['24:00', '9:00', '12:60', '1200', '', '12:5', 'ab:cd']) {
        expect(LocalTime.tryParse(value), isNull, reason: value);
      }
    });

    test('compares by minutes of day', () {
      expect(LocalTime(9, 0).compareTo(LocalTime(10, 30)), lessThan(0));
      expect(LocalTime(22, 0).isAfter(LocalTime(6, 0)), isTrue);
      expect(LocalTime(9, 0), LocalTime.parse('09:00'));
    });
  });
}
