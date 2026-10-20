import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/features/image_import/application/image_import_controller.dart';
import 'package:schediel/features/image_import/domain/candidate_resolution.dart';
import 'package:schediel/features/image_import/domain/conservative_parser.dart';
import 'package:schediel/features/image_import/domain/image_candidate.dart';
import 'package:schediel/features/image_import/domain/ocr_document.dart';
import 'image_import_controller_test.dart' show FakePicker, FakePreparer, FakeOcr;

/// Synthetic names; geometry mirrors the supplied university table, including
/// split lines, mixed-case course codes and per-meeting rooms.
OcrDocument universityFixture({bool shuffled = false, bool merged = false, int width = 1000, int height = 1000,
  String firstRoom = '105', List<OcrGlyph> roomGlyphs = const []}) {
  final cells = <(String, double, double, double, double)>[
    ('Code', .02, .01, .07, .03), ('Description', .18, .01, .31, .03),
    ('Units', .38, .01, .43, .03), ('Section', .49, .01, .56, .03),
    ('Instructor', .64, .01, .74, .03), ('Schedules', .85, .01, .95, .03),
    ('CS 311', .025, .10, .078, .12),
    ('Automata Theory and Formal', .10, .09, .31, .11), ('Languages', .10, .115, .19, .135),
    ('SANTOS, ALEX M.', .60, .10, .77, .12),
    ('THU - 08:30 AM-10:00 AM', .80, .05, .98, .07), (firstRoom, .87, .075, .92, .095),
    ('FRI - 04:00 PM-05:30 PM /', .80, .12, .98, .14), ('402', .87, .145, .91, .165),
    ('CS 312', .025, .235, .078, .255), ('Mobile Computing', .10, .235, .28, .255),
    ('CRUZ, JAMIE R.', .60, .235, .77, .255),
    ('MON - 07:00 AM-10:00', .80, .185, .98, .205), ('AM / LAB 5', .85, .21, .95, .23),
    ('FRI - 10:00 AM-12:00 PM /', .80, .26, .98, .28), ('SMART', .87, .285, .94, .305),
    ('MATH', .025, .365, .078, .385), ('408', .04, .39, .07, .41),
    ('Data Analysis', .10, .38, .26, .40), ('REYES, MORGAN T.', .60, .38, .77, .40),
    ('WED - 08:30 AM-10:00', .80, .33, .98, .35), ('AM / OL', .85, .355, .95, .375),
    ('FRI - 08:30 AM-10:00 AM /', .80, .405, .98, .425), ('SMART', .87, .43, .94, .45),
  ];
  if (merged) {
    cells.removeWhere((c) => c.$1 == 'CS 312' || c.$1 == 'Mobile Computing');
    cells.add(('CS 312 Mobile Computing', .025, .235, .28, .255));
  }
  if (shuffled) cells.sort((a, b) => b.$2.compareTo(a.$2));
  final text = StringBuffer();
  final lines = <OcrLine>[];
  for (final (value, left, top, right, bottom) in cells) {
    lines.add(OcrLine(text: value, start: text.length, blockId: lines.length,
      glyphs: value == firstRoom ? roomGlyphs : const [],
      region: ImageEvidenceRegion.validated(left: left, top: top, right: right, bottom: bottom,
        sourceRevision: 1, width: width, height: height)));
    text.writeln(value);
  }
  return OcrDocument(text: text.toString(), lines: lines, sourceRevision: 1, width: width, height: height);
}

void main() {
  for (final shuffled in [false, true]) {
    test('university table joins cells and splits weekly meetings (shuffled=$shuffled)', () {
      final document = universityFixture(shuffled: shuffled);
      final result = ConservativeCandidateParser().parse(document);
      expect(result.candidates, hasLength(6));
      final thursday = result.candidates[0], friday = result.candidates[1];
      for (final c in [thursday, friday]) {
        expect(c.title.value, 'Automata Theory and Formal Languages');
        expect(c.professor.value, 'SANTOS, ALEX M.');
        expect(c.subtitle.value, 'CS 311');
        expect(c.universityTimetable, isTrue);
        expect(c.date.value, isNull);
        expect(c.termEnd.value, isNull);
        expect(c.timeZone.value, isNull);
        expect(c.associationConfirmed, isFalse);
        expect(c.warnings, containsAll([CandidateWarning.missingTermStart, CandidateWarning.missingTermEnd]));
        for (final f in [c.title, c.professor, c.subtitle, c.location]) {
          expect(f.origin, FieldOrigin.observed);
          expect(document.text.substring(f.span!.start, f.span!.end), f.span!.text);
          expect(f.region, isNotNull);
        }
      }
      expect(thursday.weekdays.value, [4]);
      expect(thursday.startTime.value, LocalTime(8, 30));
      expect(thursday.endTime.value, LocalTime(10, 0));
      expect(thursday.location.value, '105');
      expect(friday.weekdays.value, [5]);
      expect(friday.startTime.value, LocalTime(16, 0));
      expect(friday.endTime.value, LocalTime(17, 30));
      expect(friday.location.value, '402');
      expect(result.candidates[2].location.value, 'LAB 5');
      expect(result.candidates[3].endTime.value, LocalTime(12, 0));
      expect(result.candidates[4].subtitle.value, 'MATH 408');
      expect(result.candidates[4].location.value, 'OL');
      expect(result.candidates[5].location.value, 'SMART');
      expect(result.candidates.map((c) => c.candidateId).toSet(), hasLength(6));
    });
  }
  test('native OCR can merge code and description without losing either field', () {
    final result = ConservativeCandidateParser().parse(universityFixture(merged: true));
    expect(result.candidates, hasLength(6));
    expect(result.candidates[2].title.value, 'Mobile Computing');
    expect(result.candidates[2].subtitle.value, 'CS 312');
    expect(result.candidates[2].location.value, 'LAB 5');
  });
  test('room delimiter cleanup uses glyph spacing, preserving real T104, 1104 and ITL', () {
    OcrGlyph glyph(String text, double left, double width) => OcrGlyph(text,
      ImageEvidenceRegion.validated(left: left, top: .078, right: left + width, bottom: .088,
        sourceRevision: 1, width: 1000, height: 1000)!);
    for (final (raw, expected, firstWidth, gap) in [
      ('T104', '104', .004, .006), ('IITL', 'ITL', .004, .005),
      ('T104', 'T104', .008, .002), ('1104', '1104', .004, .002),
      ('ITL', 'ITL', .002, .001), ('105', '105', .004, .003),
    ]) {
      final doc = universityFixture(firstRoom: raw, roomGlyphs: [
        glyph(raw[0], .87, firstWidth), glyph(raw[1], .87 + firstWidth + gap, .006)]);
      expect(ConservativeCandidateParser().parse(doc).candidates.first.location.value, expected);
    }
    expect(ConservativeCandidateParser().parse(universityFixture(firstRoom: 'T104')).candidates.first.location.value,
      'T104', reason: 'Without source geometry, a leading letter must not be guessed away.');
  });
  test('a dropped course code cannot reassign its cells to a neighboring course', () {
    final doc = universityFixture();
    final missing = OcrDocument(text: doc.text, sourceRevision: 1, width: doc.width, height: doc.height,
      lines: doc.lines.where((l) => l.text != 'CS 312').toList());
    final result = ConservativeCandidateParser().parse(missing);
    expect(result.candidates, isNotEmpty);
    expect(result.candidates.every((c) => !c.universityTimetable && c.title.value == null), isTrue);
  });
  test('one explicit term produces independent weekly School drafts, never notes or alerts', () {
    final c = ImageImportController(picker: FakePicker(), preparer: FakePreparer(), ocr: FakeOcr(), newId: () => 'probe');
    addTearDown(c.dispose);
    c.candidates = ConservativeCandidateParser().parse(universityFixture()).candidates;
    for (final row in c.candidates) {
      c.edits[row.candidateId] = CandidateEdits.fromCandidate(row);
      c.selected.add(row.candidateId);
    }
    final start = LocalDate(2026, 10, 19), end = LocalDate(2026, 12, 18);
    expect(c.applyUniversityTerm(start: start, end: end, zone: 'Asia/Manila', checked: false), isNotNull);
    expect(c.edits.values.every((e) => e.date.isEmpty), isTrue);
    expect(c.applyUniversityTerm(start: start, end: end, zone: 'Asia/Manila', checked: true), isNull);
    final entries = c.reviewEntries(universityCategoryId: 'school')!;
    expect(entries, hasLength(6));
    for (final e in entries) {
      expect(e.draft.categoryId, 'school');
      expect(e.draft.details.notes, isNull);
      expect(e.alerts, isEmpty);
      final time = e.draft.time as TimedSpec;
      expect(time.startDate.weekday, e.draft.recurrence!.weekdays.single);
      expect(e.draft.recurrence!.untilDateInclusive, end);
      expect(e.draft.recurrence!.frequency, RecurrenceFrequency.weekly);
    }
    expect(entries[0].draft.details.subtitle, 'CS 311');
    expect(entries[0].draft.details.professor, 'SANTOS, ALEX M.');
    expect((entries[0].draft.time as TimedSpec).startDate, LocalDate(2026, 10, 22));
    expect((entries[1].draft.time as TimedSpec).startDate, LocalDate(2026, 10, 23));
    expect(entries[0].draft.details.location, '105');
    expect(entries[1].draft.details.location, '402');
  });
}
