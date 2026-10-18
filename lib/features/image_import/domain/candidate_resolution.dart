import '../../../core/schedule/models.dart';
import '../../../core/schedule/occurrence_engine.dart';
import '../../../core/schedule/validation.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import '../../../core/time/zone_resolver.dart';
import '../../schedules/data/schedule_repository.dart';
import 'image_candidate.dart';

enum CandidateEndChoice { noEnd, sameDay, nextDay }

/// Raw form data lives in memory even when validation or OCR retries fail.
class CandidateEdits {
  CandidateEdits({this.title = '', this.date = '', this.lastDate = '', this.startTime = '', this.endTime = '', this.timeZone = '', this.termEnd = '', this.location = '', this.professor = '', this.kind, this.endChoice, this.associationConfirmed = false, this.weekdays = const [], this.seedResolution, this.endResolution});
  String title, date, lastDate, startTime, endTime, timeZone, termEnd, location, professor;
  CandidateTimeKind? kind;
  CandidateEndChoice? endChoice;
  bool associationConfirmed;
  List<int> weekdays;
  TimeResolution? seedResolution, endResolution;

  factory CandidateEdits.fromCandidate(ImageCandidate c) => CandidateEdits(
    title: c.title.value ?? '', date: c.date.value?.toIso() ?? '',
    startTime: c.startTime.value?.toHhMm() ?? '', endTime: c.endTime.value?.toHhMm() ?? '',
    timeZone: c.timeZone.value ?? '', termEnd: c.termEnd.value?.toIso() ?? '',
    location: c.location.value ?? '', professor: c.professor.value ?? '',
    kind: c.timeKind.value, weekdays: [...?c.weekdays.value]);
}

class ResolvedImageCandidate {
  const ResolvedImageCandidate({required this.candidate, required this.draft, required this.fieldEvidence});
  final ImageCandidate candidate;
  final ScheduleDraft draft;
  final Map<String, CandidateField<Object?>> fieldEvidence;
}

class CandidateResolutionResult {
  const CandidateResolutionResult({this.resolved, this.errors = const {}});
  final ResolvedImageCandidate? resolved;
  final Map<String, String> errors;
}

CandidateResolutionResult resolveImageCandidate(ImageCandidate c, CandidateEdits e) {
  final errors = <String, String>{};
  final title = e.title.trim();
  final date = LocalDate.tryParse(e.date.trim());
  if (title.isEmpty) errors['title'] = 'Enter the title from the image or your own title.';
  if (title.runes.length > 120) errors['title'] = 'Title must be 120 characters or fewer. Edit it; it will not be truncated.';
  if (date == null) errors['date'] = 'Enter a full, valid date as YYYY-MM-DD. Choose the year and date order explicitly.';
  if (e.kind == null) errors['kind'] = 'Choose a timed or date-only entry.';
  if (!e.associationConfirmed) errors['association'] = 'Confirm which title, date and time belong together against the image.';
  if (errors.isNotEmpty) return CandidateResolutionResult(errors: errors);
  final actualDate = date!;
  TimeSpec time;
  final zones = ZoneResolver.initialized();
  if (e.kind == CandidateTimeKind.dateOnly) {
    final last = e.lastDate.trim().isEmpty ? actualDate : LocalDate.tryParse(e.lastDate.trim());
    if (last == null || last.isBefore(actualDate)) {
      return const CandidateResolutionResult(errors: {'lastDate': 'Choose a valid final date on or after the first date.'});
    }
    try {
      time = DateOnlySpec(startDate: actualDate, endDateExclusive: last.addDays(1));
    } on ArgumentError {
      return const CandidateResolutionResult(errors: {'lastDate': 'This date is outside the supported date range.'});
    }
  } else {
    final start = LocalTime.tryParse(e.startTime.trim());
    final end = e.endChoice == CandidateEndChoice.noEnd ? null : LocalTime.tryParse(e.endTime.trim());
    final zone = e.timeZone.trim();
    if (start == null) errors['startTime'] = 'Enter a resolved 24-hour HH:mm time. Do not guess AM or PM.';
    if (!zones.isValidZone(zone)) errors['timeZone'] = 'Enter the source IANA time zone; the device zone is not assumed.';
    if (e.endChoice == null) errors['endChoice'] = 'Choose no end time, same-day end or next-day end.';
    if (e.endChoice != null && e.endChoice != CandidateEndChoice.noEnd && end == null) errors['endTime'] = 'Enter a valid end time as HH:mm.';
    if (errors.isNotEmpty) return CandidateResolutionResult(errors: errors);
    final offset = end == null ? null : (e.endChoice == CandidateEndChoice.nextDay ? 1 : 0);
    if (end != null && offset == 0 && !end.isAfter(start!)) errors['endTime'] = 'End must follow the start. Choose next day explicitly for overnight events.';
    final startWall = zones.resolve(zone, actualDate, start!);
    if (startWall.kind == WallTimeKind.nonexistent) errors['startTime'] = 'This clock time does not exist in the selected zone. Choose a different time.';
    if (startWall.kind == WallTimeKind.ambiguous && e.seedResolution == null) errors['seedResolution'] = 'This clock time occurs twice. Choose the earlier or later occurrence.';
    WallTimeResolution? endWall;
    if (end != null) {
      try {
        endWall = zones.resolve(zone, actualDate.addDays(offset!), end);
        if (endWall.kind == WallTimeKind.nonexistent) errors['endTime'] = 'This end time does not exist in the selected zone.';
        if (endWall.kind == WallTimeKind.ambiguous && e.endResolution == null) errors['endResolution'] = 'Choose the earlier or later end-time occurrence.';
      } on ArgumentError { errors['endTime'] = 'End date is outside the supported range.'; }
    }
    if (errors.isNotEmpty) return CandidateResolutionResult(errors: errors);
    time = TimedSpec(startDate: actualDate, startTime: start, timeZone: zone,
      endTime: end, endDayOffset: offset,
      seedTimeResolution: startWall.kind == WallTimeKind.ambiguous ? e.seedResolution : null,
      endTimeResolution: endWall?.kind == WallTimeKind.ambiguous ? e.endResolution : null);
  }
  RecurrenceSpec? recurrence;
  if (e.weekdays.isNotEmpty || (c.weekdays.value?.isNotEmpty ?? false)) {
    final termEnd = LocalDate.tryParse(e.termEnd.trim());
    if (termEnd == null || termEnd.isBefore(actualDate)) errors['termEnd'] = 'Enter the actual term end as YYYY-MM-DD, on or after the start.';
    if (e.weekdays.isEmpty || e.weekdays.any((d) => d < 1 || d > 7)) errors['weekdays'] = 'Choose the actual recurring weekdays.';
    if (errors.isNotEmpty) return CandidateResolutionResult(errors: errors);
    recurrence = RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: e.weekdays, untilDateInclusive: termEnd);
  }
  String? optional(String value) => value.trim().isEmpty ? null : value.trim();
  final draft = ScheduleDraft(title: title, time: time, recurrence: recurrence,
    details: ScheduleDetails(location: optional(e.location), professor: optional(e.professor)));
  final issues = SeriesValidator(zones, OccurrenceEngine(zones)).validate(ScheduleSeries(id: 'image-draft', revision: 1,
    title: title, time: time, recurrence: recurrence, details: draft.details));
  for (final issue in issues) { errors[issue.path] = 'Check this value (${issue.code}); nothing was truncated.'; }
  if (errors.isNotEmpty) return CandidateResolutionResult(errors: errors);
  CandidateField<Object?> field<T>(CandidateField<T> original, T? value) =>
    original.value == value ? original : original.fromUser(value);
  final evidence = <String, CandidateField<Object?>>{
    'title': field(c.title, title), 'date': field(c.date, actualDate),
    'timeKind': field(c.timeKind, e.kind),
    'location': field(c.location, optional(e.location)), 'professor': field(c.professor, optional(e.professor)),
    'association': const CandidateField(value: true, origin: FieldOrigin.userSupplied),
    if (time is TimedSpec) ...{
      'startTime': field(c.startTime, time.startTime), 'endTime': field(c.endTime, time.endTime),
      'timeZone': field(c.timeZone, time.timeZone),
      'endChoice': CandidateField(value: e.endChoice, origin: FieldOrigin.userSupplied),
    },
    if (recurrence != null) ...{
      'weekdays': CandidateField(value: recurrence.weekdays, origin: c.weekdays.value.toString() == recurrence.weekdays.toString() ? c.weekdays.origin : FieldOrigin.userSupplied,
        span: c.weekdays.span, region: c.weekdays.region),
      'termEnd': field(c.termEnd, recurrence.untilDateInclusive),
    },
  };
  return CandidateResolutionResult(resolved: ResolvedImageCandidate(candidate: c, draft: draft, fieldEvidence: Map.unmodifiable(evidence)));
}
