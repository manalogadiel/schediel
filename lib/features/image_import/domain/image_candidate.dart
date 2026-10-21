import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import 'ocr_document.dart';

enum FieldOrigin { observed, userSupplied, unresolved }
enum CandidateTimeKind { timed, dateOnly }
enum CandidateWarning { missingTitle, missingDate, missingYear, dateOrder, invalidDate, missingAmPm, missingTime, missingZone, missingTermStart, missingTermEnd, association, endChoice, unsupportedPattern, fieldTooLong }

class CandidateField<T> {
  const CandidateField({this.value, this.origin = FieldOrigin.unresolved, this.span, this.region});
  final T? value;
  final FieldOrigin origin;
  final OcrSpan? span;
  final ImageEvidenceRegion? region;

  CandidateField<T> fromUser(T? value) => CandidateField(value: value, origin: FieldOrigin.userSupplied, span: span, region: region);
}

class ImageCandidate {
  const ImageCandidate({required this.candidateId, required this.sourceRevision, required this.sourceLine,
    this.title = const CandidateField(), this.date = const CandidateField(),
    this.startTime = const CandidateField(), this.endTime = const CandidateField(),
    this.timeZone = const CandidateField(), this.timeKind = const CandidateField(),
    this.weekdays = const CandidateField(), this.termEnd = const CandidateField(),
    this.location = const CandidateField(), this.professor = const CandidateField(),
    this.subtitle = const CandidateField(), this.universityTimetable = false,
    this.associationConfirmed = false, this.noEndConfirmed = false, this.endDayOffset,
    this.warnings = const [], this.selected = true});
  final String candidateId;
  final int sourceRevision;
  final OcrSpan sourceLine;
  final CandidateField<String> title, timeZone, location, professor, subtitle;
  final bool universityTimetable;
  final CandidateField<LocalDate> date, termEnd;
  final CandidateField<LocalTime> startTime, endTime;
  final CandidateField<CandidateTimeKind> timeKind;
  final CandidateField<List<int>> weekdays;
  final bool associationConfirmed, noEndConfirmed, selected;
  final int? endDayOffset;
  final List<CandidateWarning> warnings;
}

class CandidateParseResult {
  const CandidateParseResult(this.candidates);
  final List<ImageCandidate> candidates;
  bool get universityTimetable => candidates.any((c) => c.universityTimetable);
  String get layoutNotice => universityTimetable
    ? 'Check the classes, then choose dates and repeats.'
    : 'Partial interpretation only. Check every entry against the image; complex timetable rows and columns may not be associated correctly.';
}
