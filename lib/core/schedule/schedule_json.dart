import '../time/local_date.dart';
import '../time/local_time.dart';
import 'models.dart';

/// JSON codecs for schedule values, shared by local storage and the share
/// contract (CONTRACTS.md section 2). Field names follow the contract.

Map<String, Object?> timeToJson(TimeSpec time) => switch (time) {
      TimedSpec() => {
          'kind': 'timed',
          'startDate': time.startDate.toIso(),
          'startTime': time.startTime.toHhMm(),
          'timeZone': time.timeZone,
          'endTime': time.endTime?.toHhMm(),
          'endDayOffset': time.endDayOffset,
          'seedTimeResolution': time.seedTimeResolution?.name,
          'endTimeResolution': time.endTimeResolution?.name,
        },
      DateOnlySpec() => {
          'kind': 'dateOnly',
          'startDate': time.startDate.toIso(),
          'endDateExclusive': time.endDateExclusive.toIso(),
        },
    };

TimeSpec timeFromJson(Map<String, dynamic> json) {
  if (json['kind'] == 'dateOnly') {
    return DateOnlySpec(
      startDate: LocalDate.parse(json['startDate'] as String),
      endDateExclusive: LocalDate.parse(json['endDateExclusive'] as String),
    );
  }
  TimeResolution? resolution(Object? v) => v == null ? null : TimeResolution.values.byName(v as String);
  return TimedSpec(
    startDate: LocalDate.parse(json['startDate'] as String),
    startTime: LocalTime.parse(json['startTime'] as String),
    timeZone: json['timeZone'] as String,
    endTime: json['endTime'] == null ? null : LocalTime.parse(json['endTime'] as String),
    endDayOffset: (json['endDayOffset'] as num?)?.toInt(),
    seedTimeResolution: resolution(json['seedTimeResolution']),
    endTimeResolution: resolution(json['endTimeResolution']),
  );
}

Map<String, Object?> recurrenceToJson(RecurrenceSpec rule) => {
      'frequency': rule.frequency.name,
      'interval': RecurrenceSpec.interval,
      'weekdays': rule.weekdays,
      'untilDateInclusive': rule.untilDateInclusive?.toIso(),
    };

RecurrenceSpec recurrenceFromJson(Map<String, dynamic> json) => RecurrenceSpec(
      frequency: RecurrenceFrequency.values.byName(json['frequency'] as String),
      weekdays: [for (final d in json['weekdays'] as List) (d as num).toInt()],
      untilDateInclusive:
          json['untilDateInclusive'] == null ? null : LocalDate.parse(json['untilDateInclusive'] as String),
    );

Map<String, Object?> detailsToJson(ScheduleDetails d) =>
    {'location': d.location, 'professor': d.professor, 'subtitle': d.subtitle, 'notes': d.notes};

ScheduleDetails detailsFromJson(Map<String, dynamic> json) => ScheduleDetails(
      location: json['location'] as String?,
      professor: json['professor'] as String?,
      subtitle: json['subtitle'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, Object?> exceptionToJson(OccurrenceException e) => {
      'originalOccurrenceKey': e.originalKey.toIso(),
      'action': e.action.name,
      'replacement': e.replacement == null
          ? null
          : {
              'title': e.replacement!.title,
              'time': timeToJson(e.replacement!.time),
              'details': detailsToJson(e.replacement!.details),
            },
    };

OccurrenceException exceptionFromJson(Map<String, dynamic> json) {
  final replacement = json['replacement'] as Map<String, dynamic>?;
  return OccurrenceException(
    originalKey: LocalDate.parse(json['originalOccurrenceKey'] as String),
    action: ExceptionAction.values.byName(json['action'] as String),
    replacement: replacement == null
        ? null
        : OccurrenceReplacement(
            title: replacement['title'] as String,
            time: timeFromJson(replacement['time'] as Map<String, dynamic>),
            details: detailsFromJson(replacement['details'] as Map<String, dynamic>),
          ),
  );
}
