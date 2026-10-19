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
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await h.tapText('15');
    await h.tapText('OK');
    expect(h.read(effectiveDateProvider), LocalDate(2026, 11, 15));
    expect(find.byKey(const ValueKey('day-2026-11-15')), findsOneWidget);
    expect(find.byTooltip('Choose date'), findsOneWidget);
  });
}
