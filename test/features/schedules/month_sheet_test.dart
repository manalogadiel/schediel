import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/core/time/local_date.dart';

import '../../support/harness.dart';
import 'schedule_screens_test.dart' show classDraft;

Future<void> _open(TestHarness h) async {
  await h.tester.tap(find.bySemanticsLabel(RegExp('^Selected date')));
  await h.settle();
}

void main() {
  appTest('the month sheet opens on the selected month and returns the tapped day', (h) async {
    await _open(h);
    expect(find.text('November 2026'), findsOneWidget);
    await h.tester.tap(find.byKey(const ValueKey('month-day-2026-11-21')));
    await h.settle();
    await h.tester.tap(find.byKey(const ValueKey('month-done')));
    await h.settle();
    expect(h.read(effectiveDateProvider), LocalDate(2026, 11, 21));
  });

  appTest('chevrons page months and Today returns to the current month', (h) async {
    await _open(h);
    await h.tester.tap(find.byKey(const ValueKey('month-next')));
    await h.settle();
    expect(find.text('December 2026'), findsOneWidget);
    await h.tester.tap(find.byKey(const ValueKey('month-prev')));
    await h.settle();
    await h.tester.tap(find.byKey(const ValueKey('month-prev')));
    await h.settle();
    expect(find.text('October 2026'), findsOneWidget);
    await h.tester.tap(find.byKey(const ValueKey('month-today')));
    await h.settle();
    expect(find.text('November 2026'), findsOneWidget);
  });

  appTest('dismissing the sheet keeps the date', (h) async {
    await _open(h);
    await h.tester.tapAt(const Offset(20, 20));
    await h.settle();
    expect(find.byKey(const ValueKey('month-done')), findsNothing);
    expect(h.read(effectiveDateProvider), LocalDate(2026, 11, 2));
  });

  appTest('days with schedules carry a dot', (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft()));
    await h.settle();
    await _open(h);
    expect(find.byKey(const ValueKey('month-dot-2026-11-04')), findsOneWidget);
    expect(find.byKey(const ValueKey('month-dot-2026-11-05')), findsNothing);
  });

  appTest('the sheet fits a narrow screen at 200% text', size: const Size(320, 700), (h) async {
    h.tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(h.tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(h);
    expect(find.byKey(const ValueKey('month-done')), findsOneWidget);
    expect(h.tester.takeException(), isNull);
  });

  appTest('paging stops at the last month the calendar supports', (h) async {
    h.read(selectedDateProvider.notifier).select(LocalDate(2199, 11, 10));
    await h.settle();
    await _open(h);
    expect(find.text('November 2199'), findsOneWidget);
    await h.tester.tap(find.byKey(const ValueKey('month-next')));
    await h.settle();
    expect(h.tester.takeException(), isNull);
    expect(find.text('November 2199'), findsOneWidget);
  });
}
