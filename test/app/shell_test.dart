import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/icons.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/shell.dart';
import 'package:schediel/core/time/local_date.dart';

import '../features/schedules/schedule_screens_test.dart' show classDraft;
import '../support/harness.dart';

void main() {
  appTest('the add button opens the add menu', (h) async {
    await h.tester.tap(find.byTooltip('Add'));
    await h.settle();
    expect(find.text('Import image'), findsOneWidget);
    expect(find.text('Open shared link'), findsOneWidget);
  });

  appTest('navigation destinations and the add button are labelled', (h) async {
    final handle = h.tester.ensureSemantics();
    for (final label in ['Today', 'Week', 'Settings']) {
      expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
    }
    expect(find.bySemanticsLabel('Add'), findsOneWidget);
    handle.dispose();
  });

  appTest('tapping Today while on Today returns to today', (h) async {
    await h.run(() async => h.read(selectedDateProvider.notifier).select(LocalDate(2026, 11, 5)));
    await h.settle();
    expect(find.bySemanticsLabel(RegExp('^Selected date Thursday, November 5')), findsOneWidget);
    await h.tester.tap(find.byKey(const ValueKey('nav-today')));
    await h.settle();
    expect(find.bySemanticsLabel(RegExp('^Selected date Monday, November 2')), findsOneWidget);
  });

  test('Today and Week use distinct icons', () {
    expect(AppIcons.today.asset, isNot(AppIcons.week.asset));
    expect(AppIcons.todayFill.asset, isNot(AppIcons.weekFill.asset));
  });

  appTest('switching tabs fades through and settles on the new page', (h) async {
    await h.tester.tap(find.byKey(const ValueKey('nav-settings')));
    await h.tester.pump();
    await h.tester.pump(BranchSwitcher.duration ~/ 2);
    expect(find.byType(FloatingNavBar), findsOneWidget);
    await h.settle();
    expect(find.text('Appearance'), findsOneWidget);
  });

  appTest('switching tabs keeps the floating bar', (h) async {
    await h.tester.tap(find.byKey(const ValueKey('nav-week')));
    await h.settle();
    expect(find.byType(FloatingNavBar), findsOneWidget);
    await h.tester.tap(find.byKey(const ValueKey('nav-settings')));
    await h.settle();
    expect(find.text('Appearance'), findsOneWidget);
  });

  appTest('the last Today row scrolls clear of the floating bar at 200% text', size: const Size(320, 700), (h) async {
    h.tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(h.tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repo = h.read(scheduleRepositoryProvider);
    for (var i = 0; i < 6; i++) {
      await h.run(() => repo.create(classDraft(title: 'Fixture row $i', hour: 10 + i, endHour: 11 + i, weekdays: const [1])));
    }
    await h.settle();
    final last = find.text('Fixture row 5');
    await h.tester.scrollUntilVisible(last, 200, scrollable: find.byType(Scrollable).first);
    await h.tester.fling(find.byType(Scrollable).first, const Offset(0, -2000), 3000);
    await h.settle();
    final bar = h.tester.getRect(find.byType(FloatingNavBar));
    final row = h.tester.getRect(last);
    expect(row.bottom, lessThanOrEqualTo(bar.top), reason: 'row $row bar $bar');
  });
}
