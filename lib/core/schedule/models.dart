import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../time/local_date.dart';
import '../time/local_time.dart';

/// Explicit choice for a wall time that occurs twice (a DST fold).
enum TimeResolution { earlier, later }

/// When a schedule happens: a resolved wall-clock time in an IANA zone, or a
/// calendar date (range) without any time.
sealed class TimeSpec {
  const TimeSpec();
  LocalDate get startDate;
}

@immutable
final class TimedSpec extends TimeSpec {
  const TimedSpec({
    required this.startDate,
    required this.startTime,
    required this.timeZone,
    this.endTime,
    this.endDayOffset,
    this.seedTimeResolution,
    this.endTimeResolution,
  });

  @override
  final LocalDate startDate;
  final LocalTime startTime;
  final String timeZone;

  /// Null means the schedule explicitly has no end time (a point event).
  final LocalTime? endTime;

  /// 0 = same day, 1 = next day. Null exactly when [endTime] is null.
  final int? endDayOffset;
  final TimeResolution? seedTimeResolution;
  final TimeResolution? endTimeResolution;

  bool get hasEnd => endTime != null;

  TimedSpec copyWith({
    LocalDate? startDate,
    LocalTime? startTime,
    String? timeZone,
    LocalTime? Function()? endTime,
    int? Function()? endDayOffset,
    TimeResolution? Function()? seedTimeResolution,
    TimeResolution? Function()? endTimeResolution,
  }) =>
      TimedSpec(
        startDate: startDate ?? this.startDate,
        startTime: startTime ?? this.startTime,
        timeZone: timeZone ?? this.timeZone,
        endTime: endTime != null ? endTime() : this.endTime,
        endDayOffset: endDayOffset != null ? endDayOffset() : this.endDayOffset,
        seedTimeResolution: seedTimeResolution != null ? seedTimeResolution() : this.seedTimeResolution,
        endTimeResolution: endTimeResolution != null ? endTimeResolution() : this.endTimeResolution,
      );

  @override
  bool operator ==(Object other) =>
      other is TimedSpec &&
      other.startDate == startDate &&
      other.startTime == startTime &&
      other.timeZone == timeZone &&
      other.endTime == endTime &&
      other.endDayOffset == endDayOffset &&
      other.seedTimeResolution == seedTimeResolution &&
      other.endTimeResolution == endTimeResolution;

  @override
  int get hashCode => Object.hash(
        startDate,
        startTime,
        timeZone,
        endTime,
        endDayOffset,
        seedTimeResolution,
        endTimeResolution,
      );
}

@immutable
final class DateOnlySpec extends TimeSpec {
  const DateOnlySpec({required this.startDate, required this.endDateExclusive});

  @override
  final LocalDate startDate;
  final LocalDate endDateExclusive;

  int get spanDays => startDate.daysUntil(endDateExclusive);

  /// Inclusive last date, for display only.
  LocalDate get lastDate => endDateExclusive.addDays(-1);

  @override
  bool operator ==(Object other) =>
      other is DateOnlySpec && other.startDate == startDate && other.endDateExclusive == endDateExclusive;

  @override
  int get hashCode => Object.hash(startDate, endDateExclusive);
}

enum RecurrenceFrequency { daily, weekly }

@immutable
class RecurrenceSpec {
  RecurrenceSpec({
    required this.frequency,
    Iterable<int> weekdays = const [],
    this.untilDateInclusive,
  }) : weekdays = List.unmodifiable(weekdays.toSet().toList()..sort());

  final RecurrenceFrequency frequency;

  /// ISO weekdays (1 = Monday ... 7 = Sunday), sorted and unique.
  final List<int> weekdays;
  final LocalDate? untilDateInclusive;

  static const int interval = 1;

  RecurrenceSpec copyWith({
    RecurrenceFrequency? frequency,
    Iterable<int>? weekdays,
    LocalDate? Function()? untilDateInclusive,
  }) =>
      RecurrenceSpec(
        frequency: frequency ?? this.frequency,
        weekdays: weekdays ?? this.weekdays,
        untilDateInclusive: untilDateInclusive != null ? untilDateInclusive() : this.untilDateInclusive,
      );

  @override
  bool operator ==(Object other) =>
      other is RecurrenceSpec &&
      other.frequency == frequency &&
      const ListEquality<int>().equals(other.weekdays, weekdays) &&
      other.untilDateInclusive == untilDateInclusive;

  @override
  int get hashCode => Object.hash(frequency, Object.hashAll(weekdays), untilDateInclusive);
}

/// Optional schedule details. Absent values are null and are never replaced
/// with invented text.
@immutable
class ScheduleDetails {
  const ScheduleDetails({this.location, this.professor, this.subtitle, this.notes});

  static const empty = ScheduleDetails();

  final String? location;
  final String? professor;
  final String? subtitle;
  final String? notes;

  bool get isEmpty => location == null && professor == null && subtitle == null && notes == null;

  ScheduleDetails copyWith({
    String? Function()? location,
    String? Function()? professor,
    String? Function()? subtitle,
    String? Function()? notes,
  }) =>
      ScheduleDetails(
        location: location != null ? location() : this.location,
        professor: professor != null ? professor() : this.professor,
        subtitle: subtitle != null ? subtitle() : this.subtitle,
        notes: notes != null ? notes() : this.notes,
      );

  @override
  bool operator ==(Object other) =>
      other is ScheduleDetails &&
      other.location == location &&
      other.professor == professor &&
      other.subtitle == subtitle &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(location, professor, subtitle, notes);
}

enum ExceptionAction { cancel, override }

/// A complete one-time replacement for one original occurrence.
@immutable
class OccurrenceReplacement {
  const OccurrenceReplacement({required this.title, required this.time, required this.details});

  final String title;
  final TimeSpec time;
  final ScheduleDetails details;

  @override
  bool operator ==(Object other) =>
      other is OccurrenceReplacement && other.title == title && other.time == time && other.details == details;

  @override
  int get hashCode => Object.hash(title, time, details);
}

/// Cancels or overrides one original occurrence, identified by its original
/// local date (the occurrence key), never by its moved display time.
@immutable
class OccurrenceException {
  const OccurrenceException({required this.originalKey, required this.action, this.replacement});

  final LocalDate originalKey;
  final ExceptionAction action;
  final OccurrenceReplacement? replacement;

  @override
  bool operator ==(Object other) =>
      other is OccurrenceException &&
      other.originalKey == originalKey &&
      other.action == action &&
      other.replacement == replacement;

  @override
  int get hashCode => Object.hash(originalKey, action, replacement);
}

@immutable
class ScheduleSeries {
  ScheduleSeries({
    required this.id,
    required this.revision,
    required this.title,
    required this.time,
    this.categoryId,
    this.recurrence,
    this.details = ScheduleDetails.empty,
    Iterable<OccurrenceException> exceptions = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : exceptions = List.unmodifiable(exceptions),
        createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        updatedAt = updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  final String id;
  final int revision;
  final String title;
  final String? categoryId;
  final TimeSpec time;
  final RecurrenceSpec? recurrence;
  final ScheduleDetails details;
  final List<OccurrenceException> exceptions;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRecurring => recurrence != null;

  OccurrenceException? exceptionFor(LocalDate key) =>
      exceptions.firstWhereOrNull((e) => e.originalKey == key);

  ScheduleSeries copyWith({
    int? revision,
    String? title,
    String? Function()? categoryId,
    TimeSpec? time,
    RecurrenceSpec? Function()? recurrence,
    ScheduleDetails? details,
    Iterable<OccurrenceException>? exceptions,
    DateTime? updatedAt,
  }) =>
      ScheduleSeries(
        id: id,
        revision: revision ?? this.revision,
        title: title ?? this.title,
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        time: time ?? this.time,
        recurrence: recurrence != null ? recurrence() : this.recurrence,
        details: details ?? this.details,
        exceptions: exceptions ?? this.exceptions,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
