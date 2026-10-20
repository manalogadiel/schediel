import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/core/time/local_date.dart';

import '../../support/harness.dart';

void main() {
  appTest('Week month picker selects an actual date and retains the Week tab', (h) async {
    await h.tapText('Week');
    expect(find.byTooltip('Choose date'), findsOneWidget);
    await h.tester.tap(find.byTooltip('Choose date'));
    await h.settle();
    expect(find.byKey(const ValueKey('month-done')), findsOneWidget);
    await h.tester.tap(find.byKey(const ValueKey('month-day-2026-11-15')));
    await h.settle();
    await h.tester.tap(find.byKey(const ValueKey('month-done')));
    await h.settle();
    expect(h.read(effectiveDateProvider), LocalDate(2026, 11, 15));
    expect(find.byKey(const ValueKey('day-2026-11-15')), findsOneWidget);
    expect(find.byTooltip('Choose date'), findsOneWidget);
  });
}
