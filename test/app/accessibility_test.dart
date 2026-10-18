import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/harness.dart';
void main() {
  appTest('Today has one labelled share action and supports large text on a narrow screen', (h) async {
    expect(find.byTooltip('Share schedules'), findsOneWidget);
    h.tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(h.tester.platformDispatcher.clearTextScaleFactorTestValue);
    await h.settle();
    expect(h.tester.takeException(),isNull);
    final semantics = h.tester.ensureSemantics();
    await expectLater(h.tester,meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  },size:const Size(320,860));
}
