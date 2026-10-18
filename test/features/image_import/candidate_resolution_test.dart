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
}
