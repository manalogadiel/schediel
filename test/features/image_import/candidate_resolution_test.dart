import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/features/image_import/domain/conservative_parser.dart';
import 'package:schediel/features/image_import/domain/image_candidate.dart';
import 'package:schediel/features/image_import/domain/candidate_resolution.dart';
import 'package:schediel/features/image_import/domain/ocr_document.dart';

void main() {
  test('explicit title/date/association resolve poster without fabricating time', () {
    final c = ConservativeCandidateParser().parse(OcrDocument.plain('March 5')).candidates.single;
    final edits = CandidateEdits.fromCandidate(c);
    expect(edits.date, isEmpty);
    expect(edits.title, isEmpty);
    expect(edits.timeZone, isEmpty);
    final missing = resolveImageCandidate(c, edits);
    expect(missing.resolved, isNull);
    expect(missing.errors.keys, containsAll(['title', 'date', 'association']));
    edits.title = 'Exam';
    edits.date = '2027-03-05';
    edits.associationConfirmed = true;
    final result = resolveImageCandidate(c, edits).resolved!;
    expect(result.draft.time, DateOnlySpec(startDate: LocalDate(2027, 3, 5), endDateExclusive: LocalDate(2027, 3, 6)));
    expect(result.draft.details.isEmpty, isTrue);
    expect(result.fieldEvidence['date']!.origin, FieldOrigin.userSupplied);
    expect(result.fieldEvidence['timeKind']!.origin, FieldOrigin.observed);
  });
  test('explicit one-time choice overrides observed weekly weekdays without term dates', () {
    final candidate = ConservativeCandidateParser().parse(OcrDocument.plain('Class | Thu | 8:30 AM-10:00 AM')).candidates.single;
    final edits = CandidateEdits.fromCandidate(candidate);
    expect(edits.repeat, CandidateRepeat.weekly);
    edits.repeat = CandidateRepeat.oneTime;
    edits.date = '2026-10-22'; edits.timeZone = 'Asia/Manila';
    edits.endChoice = CandidateEndChoice.sameDay; edits.associationConfirmed = true;
    final result = resolveImageCandidate(candidate, edits);
    expect(result.errors, isEmpty);
    expect(result.resolved!.draft.recurrence, isNull);
    expect(edits.weekdays, [4], reason: 'Retain OCR weekdays for later edits, without activating a repeat.');
    expect(result.resolved!.draft.details.notes, isNull);
  });

  test('switching from one-time to weekly requires weekdays and a real end date', () {
    final candidate = ConservativeCandidateParser().parse(OcrDocument.plain('Class | Thu | 8:30 AM-10:00 AM')).candidates.single;
    final edits = CandidateEdits.fromCandidate(candidate)
      ..date = '2026-10-22' ..timeZone = 'Asia/Manila' ..associationConfirmed = true
      ..endChoice = CandidateEndChoice.sameDay ..repeat = CandidateRepeat.oneTime;
    expect(resolveImageCandidate(candidate, edits).resolved!.draft.recurrence, isNull);
    edits.repeat = CandidateRepeat.weekly;
    expect(resolveImageCandidate(candidate, edits).errors, contains('termEnd'));
    edits.termEnd = '2026-12-18'; edits.weekdays = [];
    expect(resolveImageCandidate(candidate, edits).errors, contains('weekdays'));
    edits.weekdays = [4];
    expect(resolveImageCandidate(candidate, edits).resolved!.draft.recurrence!.frequency, RecurrenceFrequency.weekly);
  });

}
