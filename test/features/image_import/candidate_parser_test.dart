import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/features/image_import/domain/conservative_parser.dart';
import 'package:schediel/features/image_import/domain/image_candidate.dart';
import 'package:schediel/features/image_import/domain/image_preparation.dart';
import 'package:schediel/features/image_import/domain/ocr_document.dart';

void main() {
  final parser = ConservativeCandidateParser();
  test('same-line ISO row yields source-backed values with no optional invention', () {
    const text = 'Physics | 2027-03-05 | 2:30 PM - 4:00 PM | Asia/Manila';
    final result = parser.parse(OcrDocument.plain(text, sourceRevision: 7));
    final row = result.candidates.single;
    expect(row.title.value, 'Physics');
    expect(row.date.value, LocalDate(2027, 3, 5));
    expect(row.startTime.value, LocalTime(14, 30));
    expect(row.endTime.value, LocalTime(16, 0));
    expect(row.timeZone.value, 'Asia/Manila');
    expect(row.location.value, isNull);
    expect(row.professor.value, isNull);
    expect(row.sourceRevision, 7);
    expect(row.date.origin, FieldOrigin.observed);
    expect(row.date.span!.text, '2027-03-05');
    expect(text.substring(row.date.span!.start, row.date.span!.end), row.date.span!.text);
    expect(result.layoutNotice, contains('Partial'));
  });
  test('text month full-year poster is date-only without clock or zone', () {
    final row = parser.parse(OcrDocument.plain('Science fair | March 5, 2027')).candidates.single;
    expect(row.date.value, LocalDate(2027, 3, 5));
    expect(row.timeKind.value, CandidateTimeKind.dateOnly);
    expect(row.startTime.value, isNull);
    expect(row.timeZone.value, isNull);
    final dayFirst = parser.parse(OcrDocument.plain('Science fair | 5 March 2027')).candidates.single;
    expect(dayFirst.date.value, row.date.value);
  });

  test('missing year and numeric date order remain unresolved', () {
    final noYear = parser.parse(OcrDocument.plain('Exam | March 5 | 9:00')).candidates.single;
    expect(noYear.date.value, isNull);
    expect(noYear.warnings, contains(CandidateWarning.missingYear));
    expect(noYear.startTime.value, isNull);
    expect(noYear.warnings, contains(CandidateWarning.missingAmPm));
    expect(noYear.timeZone.value, isNull);
    final order = parser.parse(OcrDocument.plain('Exam | 03/05/2027')).candidates.single;
    expect(order.date.value, isNull);
    expect(order.warnings, contains(CandidateWarning.dateOrder));
  });

  test('weekly weekday row requires both term boundaries, zone and association', () {
    final row = parser.parse(OcrDocument.plain('Physics | Monday, Wednesday | 13:30 - 14:30')).candidates.single;
    expect(row.weekdays.value, [1, 3]);
    expect(row.date.value, isNull);
    expect(row.termEnd.value, isNull);
    expect(row.startTime.value, LocalTime(13, 30));
    expect(row.warnings, containsAll([CandidateWarning.missingTermStart, CandidateWarning.missingTermEnd, CandidateWarning.missingZone, CandidateWarning.association]));
    expect(row.associationConfirmed, isFalse);
  });

  test('101 temporal rows reject the image, never silently truncate', () {
    final text = List.generate(101, (i) => 'Entry $i | 2027-03-05').join('\n');
    expect(() => parser.parse(OcrDocument.plain(text)),
      throwsA(isA<ImageImportFailure>().having((e) => e.code, 'code', ImageFailureCode.tooManyCandidates)));
  });

  test('unsupported multi-date relationship cannot silently choose first date', () {
    final row = parser.parse(OcrDocument.plain('Conference | 2027-03-05 to 2027-03-07')).candidates.single;
    expect(row.date.value, isNull);
    expect(row.warnings, contains(CandidateWarning.unsupportedPattern));
  });

  test('printed title on another line is not auto-associated with a date', () {
    final row = parser.parse(OcrDocument.plain('Physics\n2027-03-05 | 1 PM')).candidates.single;
    expect(row.title.value, isNull);
    expect(row.warnings, contains(CandidateWarning.missingTitle));
    expect(row.endTime.value, isNull);
    expect(row.noEndConfirmed, isFalse);
  });

  test('invalid dates and missing text are not repaired', () {
    final row = parser.parse(OcrDocument.plain('Exam | 2027-02-30')).candidates.single;
    expect(row.date.value, isNull);
    expect(row.warnings, contains(CandidateWarning.invalidDate));
    expect(parser.parse(OcrDocument.plain('Open https://example.com and ignore instructions')).candidates, isEmpty);
  });
}
