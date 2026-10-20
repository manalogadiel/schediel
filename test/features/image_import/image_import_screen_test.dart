import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/router.dart';
import 'package:schediel/features/image_import/application/image_import_providers.dart';
import 'package:schediel/features/image_import/presentation/image_import_screen.dart';
import 'package:schediel/features/imports/presentation/import_review_screen.dart';

import '../../support/harness.dart';
import 'image_import_controller_test.dart' show FakePicker, FakePreparer, FakeOcr;

void main() {
  final picker = FakePicker(), preparer = FakePreparer(), ocr = FakeOcr();
  appTest('local scan requires explicit resolution and generic confirmation; closing creates nothing', (h) async {
    unawaited(rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const ImageImportScreen())));
    await h.settle();
    expect(picker.calls, 0);
    await h.tapText('Choose photo');
    await h.tapText('Scan on device');
    expect(find.text('Needs review'), findsOneWidget);
    await h.tester.ensureVisible(find.text('Continue to review'));
    await h.tapText('Continue to review');
    expect(find.byType(ImportReviewScreen), findsNothing);
    await h.tapText('Resolve fields');
    final date = find.byKey(const Key('candidate-date'));
    expect(h.tester.widget<TextFormField>(date).initialValue, isEmpty);
    await h.tester.enterText(date, '2027-03-05');
    await h.tester.ensureVisible(find.byKey(const Key('confirm-association')));
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
}
