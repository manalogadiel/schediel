import 'package:flutter/foundation.dart';

/// A wall-clock time with minute precision, written as 24-hour HH:mm.
@immutable
class LocalTime implements Comparable<LocalTime> {
  const LocalTime._(this.hour, this.minute);

  factory LocalTime(int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Invalid clock time $hour:$minute');
    }
    return LocalTime._(hour, minute);
  }

  factory LocalTime.fromMinutes(int minutesOfDay) =>
      LocalTime(minutesOfDay ~/ 60, minutesOfDay % 60);

  static final RegExp _pattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  final int hour;
  final int minute;

  static LocalTime? tryParse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) return null;
    return LocalTime._(int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  static LocalTime parse(String value) {
    final time = tryParse(value);
    if (time == null) throw FormatException('Invalid clock time', value);
    return time;
  }

  int get minutesOfDay => hour * 60 + minute;

  bool isBefore(LocalTime other) => compareTo(other) < 0;

  bool isAfter(LocalTime other) => compareTo(other) > 0;

  String toHhMm() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => toHhMm();
}
