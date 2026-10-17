import 'package:flutter/foundation.dart';

/// A calendar date without a time or zone. Years are limited to 1900-2199,
/// matching the share contract (rule S01).
@immutable
class LocalDate implements Comparable<LocalDate> {
  const LocalDate._(this.year, this.month, this.day);

  factory LocalDate(int year, int month, int day) {
    final date = _validated(year, month, day);
    if (date == null) {
      throw ArgumentError('Invalid calendar date $year-$month-$day');
    }
    return date;
  }

  /// Date of [value]'s own calendar fields (no zone conversion).
  factory LocalDate.fromDateTime(DateTime value) =>
      LocalDate(value.year, value.month, value.day);

  factory LocalDate.fromEpochDay(int epochDay) {
    final utc = DateTime.utc(1970, 1, 1).add(Duration(days: epochDay));
    return LocalDate(utc.year, utc.month, utc.day);
  }

  static const int minYear = 1900;
  static const int maxYear = 2199;
  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  static LocalDate? tryParse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) return null;
    return _validated(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static LocalDate parse(String value) {
    final date = tryParse(value);
    if (date == null) throw FormatException('Invalid date', value);
    return date;
  }

  static LocalDate? _validated(int year, int month, int day) {
    if (year < minYear || year > maxYear || month < 1 || month > 12 || day < 1) {
      return null;
    }
    final probe = DateTime.utc(year, month, day);
    if (probe.year != year || probe.month != month || probe.day != day) {
      return null;
    }
    return LocalDate._(year, month, day);
  }

  DateTime get _utcMidnight => DateTime.utc(year, month, day);

  /// ISO weekday: 1 = Monday ... 7 = Sunday.
  int get weekday => _utcMidnight.weekday;

  int get epochDay => _utcMidnight.difference(DateTime.utc(1970, 1, 1)).inDays;

  LocalDate addDays(int days) => LocalDate.fromEpochDay(epochDay + days);

  int daysUntil(LocalDate other) => other.epochDay - epochDay;

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) => epochDay.compareTo(other.epochDay);

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
