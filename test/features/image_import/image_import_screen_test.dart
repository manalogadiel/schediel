import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/router.dart';
import 'package:schediel/features/image_import/application/image_import_providers.dart';
import 'package:schediel/features/image_import/presentation/image_import_screen.dart';
import 'package:schediel/features/image_import/domain/image_services.dart';
import 'package:schediel/features/image_import/domain/ocr_document.dart';
import 'package:schediel/features/image_import/domain/candidate_resolution.dart';
import 'package:schediel/features/image_import/domain/conservative_parser.dart';
import 'package:schediel/features/image_import/application/image_import_controller.dart';
import 'package:schediel/features/image_import/presentation/candidate_resolution_screen.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/features/imports/presentation/import_review_screen.dart';

import '../../support/harness.dart';
import 'image_import_controller_test.dart' show FakePicker, FakePreparer, FakeOcr;
import 'university_timetable_test.dart' show universityFixture;

void main() {
  final picker = FakePicker(), preparer = FakePreparer(), ocr = FakeOcr();
  appTest('local scan requires explicit resolution and generic confirmation; closing creates nothing', (h) async {
    unawaited(rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const ImageImportScreen())));
    await h.settle();
    expect(picker.calls, 0);
    await h.tapText('Choose photo');
    await h.tapText('Scan on device');
    expect(find.text('Needs review'), findsOneWidget);
    await Scrollable.ensureVisible(h.tester.element(find.text('Continue to review')), alignment: .5);
    await h.settle();
    await h.tapText('Continue to review');
    expect(find.byType(ImportReviewScreen), findsNothing);
    expect(find.textContaining('Resolve the missing fields'), findsOneWidget);
    await h.tester.ensureVisible(find.text('Resolve fields'));
    await h.tapText('Resolve fields');
    final date = find.byKey(const Key('candidate-date'));
    expect(h.tester.widget<TextFormField>(date).initialValue, isEmpty);
    await h.tester.enterText(date, '2027-03-05');
    await h.tester.scrollUntilVisible(find.byKey(const Key('confirm-association')), 300,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last);
    await h.tester.tap(find.byKey(const Key('confirm-association'))); await h.settle();
    await h.tapText('Use draft values');
    await h.tester.ensureVisible(find.text('Continue to review'));
    await h.tapText('Continue to review');
    expect(find.byType(ImportReviewScreen), findsOneWidget);
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    expect(await h.run(() => h.db.select(h.db.alertRules).get()), isEmpty);
    await h.tester.tap(find.byTooltip('Close').last); await h.settle();
    await h.tester.tap(find.byTooltip('Close').last); await h.settle();
    await h.tapText('Discard draft');
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    expect(await h.run(() => h.db.select(h.db.alertRules).get()), isEmpty);
  }, overrides: [imageSourcePickerProvider.overrideWithValue(picker), imagePreparerProvider.overrideWithValue(preparer), onDeviceOcrProvider.overrideWithValue(ocr)]);

  appTest('university classes preselect School and stay inactive until Add', (h) async {
    unawaited(rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const ImageImportScreen())));
    await h.settle();
    await h.tapText('Choose photo');
    await h.tapText('Scan on device');
    final scrollable = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last;
    Future<void> reach(Finder finder) => h.tester.scrollUntilVisible(finder, 300, scrollable: scrollable);
    await reach(find.byKey(const Key('university-term-start')));
    await h.tester.enterText(find.byKey(const Key('university-term-start')), '2026-10-19');
    await reach(find.byKey(const Key('university-term-end')));
    await h.tester.enterText(find.byKey(const Key('university-term-end')), '2026-12-18');
    await reach(find.byKey(const Key('university-check')));
    await h.tester.tap(find.byKey(const Key('university-check')));
    await reach(find.text('Apply to selected classes'));
    await h.tapText('Apply to selected classes');
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    await reach(find.text('Continue to review'));
    await h.tapText('Continue to review');
    expect(find.byType(ImportReviewScreen), findsOneWidget);
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    final review = h.tester.widget<ImportReviewScreen>(find.byType(ImportReviewScreen));
    expect(review.entries, hasLength(6));
    expect(review.entries.every((e) => e.draft.categoryId == 'school' && e.draft.details.notes == null && e.alerts.isEmpty), isTrue);
    await h.tapText('Add selected schedules');
    final saved = await h.run(h.read(scheduleRepositoryProvider).loadAll);
    expect(saved, hasLength(6));
    expect(saved.every((s) => s.categoryId == 'school' && s.details.notes == null), isTrue);
    expect(await h.run(() => h.db.select(h.db.alertRules).get()), isEmpty);
  }, overrides: [imageSourcePickerProvider.overrideWithValue(FakePicker()), imagePreparerProvider.overrideWithValue(FakePreparer()),
    onDeviceOcrProvider.overrideWithValue(_UniversityOcr())]);
  appTest('one-time class choice stays in School and adds nothing until confirmation', (h) async {
    unawaited(rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const ImageImportScreen())));
    await h.settle();
    await h.tapText('Choose photo');
    await h.tapText('Scan on device');
    final scrollable = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last;
    Future<void> reach(Finder finder) => h.tester.scrollUntilVisible(finder, 280, scrollable: scrollable);
    await reach(find.text('One time'));
    await h.tapText('One time');
    expect(find.byKey(const Key('university-term-end')), findsNothing);
    await reach(find.byKey(const Key('university-term-start')));
    await h.tester.enterText(find.byKey(const Key('university-term-start')), '2026-10-19');
    await reach(find.byKey(const Key('university-check')));
    await h.tester.tap(find.byKey(const Key('university-check')));
    await reach(find.text('Apply to selected classes'));
    await h.tapText('Apply to selected classes');
    await reach(find.text('Continue to review'));
    await h.tapText('Continue to review');
    final entries = h.tester.widget<ImportReviewScreen>(find.byType(ImportReviewScreen)).entries;
    expect(entries, hasLength(6));
    expect(entries.every((e) => e.draft.recurrence == null && e.draft.categoryId == 'school' && e.draft.details.notes == null), isTrue);
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    await h.tapText('Add selected schedules');
    final saved = await h.run(h.read(scheduleRepositoryProvider).loadAll);
    expect(saved, hasLength(6));
    expect(saved.every((s) => s.recurrence == null && s.categoryId == 'school'), isTrue);
    expect(await h.run(() => h.db.select(h.db.alertRules).get()), isEmpty);
  }, overrides: [imageSourcePickerProvider.overrideWithValue(FakePicker()), imagePreparerProvider.overrideWithValue(FakePreparer()),
    onDeviceOcrProvider.overrideWithValue(_UniversityOcr())]);

  appTest('individual class can change to one-time without changing the other classes', (h) async {
    final controller = ImageImportController(picker: FakePicker(), preparer: FakePreparer(), ocr: FakeOcr(), newId: () => 'fixture');
    addTearDown(controller.dispose);
    controller.candidates = ConservativeCandidateParser().parse(universityFixture()).candidates;
    for (final row in controller.candidates) {
      controller.edits[row.candidateId] = CandidateEdits.fromCandidate(row);
      controller.selected.add(row.candidateId);
    }
    controller.applyUniversityTerm(start: LocalDate(2026,10,19), end: LocalDate(2026,12,18), zone: 'Asia/Manila', checked: true);
    final candidate = controller.candidates.first;
    unawaited(rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => CandidateResolutionScreen(
      controller: controller, candidate: candidate))));
    await h.settle();
    await h.tester.ensureVisible(find.text('One time'));
    await h.tapText('One time');
    expect(controller.edits[candidate.candidateId]!.repeat, CandidateRepeat.oneTime);
    expect(controller.resolved, isNot(contains(candidate.candidateId)));
    await h.tester.tap(find.widgetWithText(TextButton, 'Use draft values'));
    await h.settle();
    expect(controller.resolved[candidate.candidateId]!.draft.recurrence, isNull);
    expect(controller.edits.values.skip(1).every((e) => e.repeat == CandidateRepeat.weekly), isTrue);
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
  });

}

class _UniversityOcr implements OnDeviceOcr {
  @override
  Future<OcrDocument> recognize(PreparedImageFile image) async => universityFixture(width: image.width, height: image.height);
}
