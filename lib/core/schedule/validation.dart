import 'package:flutter/foundation.dart';

import '../time/zone_resolver.dart';
import 'limits.dart';
import 'models.dart';
import 'occurrence_engine.dart';

/// A validation problem. [path] is relative to the series ('title',
/// 'time/endTime', 'exceptions/0/replacement'); [code] uses the shared
/// contract error codes.
@immutable
class ValidationIssue {
  const ValidationIssue(this.path, this.code);

  final String path;
  final String code;

  @override
  bool operator ==(Object other) => other is ValidationIssue && other.path == path && other.code == code;

  @override
  int get hashCode => Object.hash(path, code);

  @override
  String toString() => '$path:$code';
}

/// Semantic rules for an active schedule (spec section 6.6). Overlap is a
/// warning elsewhere, never a validation failure.
class SeriesValidator {
  SeriesValidator(this.zones, this.engine);

  final ZoneResolver zones;
  final OccurrenceEngine engine;

  List<ValidationIssue> validate(ScheduleSeries series) {
    final issues = <ValidationIssue>[];
    _text(issues, 'title', series.title, ScheduleLimits.titleMax, required: true);
    _time(issues, 'time', series.time, recurring: series.isRecurring);
    final rule = series.recurrence;
    if (rule != null) _recurrence(issues, rule, series.time);
    _details(issues, 'details', series.details);
    _exceptions(issues, series);
    return issues;
  }

  void _text(List<ValidationIssue> issues, String path, String? value, int max, {bool required = false}) {
    if (value == null) {
      if (required) issues.add(ValidationIssue(path, 'invalid_text'));
      return;
    }
    if (value.isEmpty || !isTrimmed(value)) {
      issues.add(ValidationIssue(path, 'invalid_text'));
    } else if (codePointLength(value) > max) {
      issues.add(ValidationIssue(path, 'too_long'));
    }
  }

  void _details(List<ValidationIssue> issues, String path, ScheduleDetails details) {
    _text(issues, '$path/location', details.location, ScheduleLimits.locationMax);
    _text(issues, '$path/professor', details.professor, ScheduleLimits.professorMax);
    _text(issues, '$path/subtitle', details.subtitle, ScheduleLimits.subtitleMax);
    _text(issues, '$path/notes', details.notes, ScheduleLimits.notesMax);
  }

  void _time(List<ValidationIssue> issues, String path, TimeSpec time, {required bool recurring}) {
    switch (time) {
      case TimedSpec():
        if (!zones.isValidZone(time.timeZone)) {
          issues.add(ValidationIssue('$path/timeZone', 'invalid_time_zone'));
        }
        final hasEnd = time.endTime != null;
        final hasOffset = time.endDayOffset != null;
        if (hasEnd != hasOffset) {
          issues.add(ValidationIssue('$path/endDayOffset', 'invalid_value'));
        } else if (hasEnd) {
          final offset = time.endDayOffset!;
          if (offset != 0 && offset != 1) {
            issues.add(ValidationIssue('$path/endDayOffset', 'invalid_value'));
          } else if (offset == 0 && !time.endTime!.isAfter(time.startTime)) {
            issues.add(ValidationIssue('$path/endTime', 'invalid_range'));
          }
        }
      case DateOnlySpec():
        final span = time.spanDays;
        if (span < 1 || (recurring && span != 1) || span > ScheduleLimits.dateOnlyMaxSpanDays) {
          issues.add(ValidationIssue('$path/endDateExclusive', 'invalid_range'));
        }
    }
  }

  void _recurrence(List<ValidationIssue> issues, RecurrenceSpec rule, TimeSpec time) {
    final weekdays = rule.weekdays;
    final validDays = weekdays.every((d) => d >= 1 && d <= 7);
    switch (rule.frequency) {
      case RecurrenceFrequency.weekly:
        if (weekdays.isEmpty || !validDays) {
          issues.add(const ValidationIssue('recurrence/weekdays', 'invalid_recurrence'));
        }
      case RecurrenceFrequency.daily:
        if (weekdays.isNotEmpty) {
          issues.add(const ValidationIssue('recurrence/weekdays', 'invalid_recurrence'));
        }
    }
    final until = rule.untilDateInclusive;
    if (until != null && until.isBefore(time.startDate)) {
      issues.add(const ValidationIssue('recurrence/untilDateInclusive', 'invalid_range'));
    }
  }

  void _exceptions(List<ValidationIssue> issues, ScheduleSeries series) {
    final seen = <String>{};
    for (var i = 0; i < series.exceptions.length; i++) {
      final exception = series.exceptions[i];
      final path = 'exceptions/$i';
      if (!series.isRecurring) {
        issues.add(ValidationIssue(path, 'invalid_exception'));
        continue;
      }
      final key = exception.originalKey.toIso();
      if (!seen.add(key)) {
        issues.add(ValidationIssue('$path/originalOccurrenceKey', 'duplicate'));
        continue;
      }
      if (!engine.isOriginalDate(series, exception.originalKey)) {
        issues.add(ValidationIssue('$path/originalOccurrenceKey', 'invalid_exception'));
      }
      final replacement = exception.replacement;
      switch (exception.action) {
        case ExceptionAction.cancel:
          if (replacement != null) issues.add(ValidationIssue('$path/replacement', 'invalid_exception'));
        case ExceptionAction.override:
          if (replacement == null) {
            issues.add(ValidationIssue('$path/replacement', 'invalid_exception'));
          } else if (replacement.time.runtimeType != series.time.runtimeType) {
            issues.add(ValidationIssue('$path/replacement/time', 'invalid_exception'));
          } else {
            _text(issues, '$path/replacement/title', replacement.title, ScheduleLimits.titleMax, required: true);
            _time(issues, '$path/replacement/time', replacement.time, recurring: false);
            _details(issues, '$path/replacement/details', replacement.details);
          }
      }
    }
  }
}
