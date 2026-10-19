import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/widgets/themed.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/schedules/presentation/day_strip.dart';
import 'package:schediel/features/schedules/presentation/next_card.dart';
import 'package:schediel/features/schedules/presentation/today_header.dart';

import '../../support/harness.dart';
import 'schedule_screens_test.dart' show classDraft;

void main() {
  test('greeting follows local time boundaries', () {
    String g(int h, int m) => greetingFor(DateTime(2026, 11, 2, h, m));
    expect(g(4, 59), 'Good evening');
    expect(g(5, 0), 'Good morning');
    expect(g(11, 59), 'Good morning');
    expect(g(12, 0), 'Good afternoon');
    expect(g(17, 59), 'Good afternoon');
    expect(g(18, 0), 'Good evening');
  });

  test('time until the next item reads naturally', () {
    expect(untilLabel(const Duration(seconds: 20)), 'in less than a minute');
    expect(untilLabel(const Duration(minutes: 40)), 'in 40 min');
    expect(untilLabel(const Duration(minutes: 60)), 'in 1 h');
    expect(untilLabel(const Duration(minutes: 90)), 'in 1 h 30 min');
    expect(untilLabel(const Duration(hours: 26)), 'in 26 h');
  });

  appTest('without a profile the greeting stands alone; with a name an initial shows', (h) async {
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.byType(ThemedAvatar), findsNothing);
    await h.run(() => h.db.into(h.db.profilePreferences).insert(ProfilePreferencesCompanion.insert(
          id: const Value(1),
          displayName: const Value('Diel'),
          updatedAt: DateTime.utc(2026, 11, 2),
        )));
    await h.settle();
    expect(find.byType(ThemedAvatar), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(find.text('Diel'), findsOneWidget);
  });

  appTest('day strip dots come from real occurrences', (h) async {
    final handle = h.tester.ensureSemantics();
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(weekdays: const [1, 3])));
    await h.settle();
    expect(find.bySemanticsLabel(RegExp(r'^Monday, November 2.*has schedules')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Wednesday, November 4.*has schedules')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Tuesday, November 3.*has schedules')), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'^Tuesday, November 3')), findsOneWidget);
    handle.dispose();
  });

  appTest('choosing a day shows a Today pill that returns to today', (h) async {
    expect(find.byKey(const ValueKey('today-pill')), findsNothing);
    await h.tester.tap(find.byKey(const ValueKey('day-2026-11-04')));
    await h.settle();
    expect(find.text('Wednesday, November 4'), findsOneWidget);
    await h.tester.tap(find.byKey(const ValueKey('today-pill')));
    await h.settle();
    expect(find.text('Monday, November 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-pill')), findsNothing);
  });

  appTest('swiping the day strip moves by a week', (h) async {
    await h.tester.fling(find.byType(DayStripView), const Offset(-300, 0), 1000);
    await h.settle();
    expect(find.text('Monday, November 9'), findsOneWidget);
    await h.tester.fling(find.byType(DayStripView), const Offset(300, 0), 1000);
    await h.settle();
    expect(find.text('Monday, November 2'), findsOneWidget);
  });

  appTest('the Next card shows the next item with a live countdown', now: DateTime.utc(2026, 11, 2, 1, 30), (h) async {
    final repo = h.read(scheduleRepositoryProvider);
    await h.run(() => repo.create(classDraft(title: 'Fixture first', hour: 9, endHour: 10)));
    await h.run(() => repo.create(classDraft(title: 'Fixture second', hour: 11, endHour: 12)));
    await h.settle();
    expect(find.byType(NextCard), findsOneWidget);
    expect(find.descendant(of: find.byType(NextCard), matching: find.text('Fixture second')), findsOneWidget);
    expect(find.text('in 1 h 30 min'), findsOneWidget);
    // Ongoing: Now badge and an elapsed bar in the timeline.
    expect(find.text('Now'), findsOneWidget);
    expect(find.byKey(const ValueKey('elapsed-bar')), findsOneWidget);
  });

  appTest('no Next card when nothing is next', now: DateTime.utc(2026, 11, 2, 1, 30), (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(title: 'Fixture only', hour: 9, endHour: 10)));
    await h.settle();
    expect(find.byType(NextCard), findsNothing);
    expect(find.text('Next'), findsNothing);
  });

  appTest('Today fits a narrow screen at 200% text', size: const Size(320, 700), now: DateTime.utc(2026, 11, 2, 1, 30), (h) async {
    h.tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(h.tester.platformDispatcher.clearTextScaleFactorTestValue);
    await h.run(() => h.db.into(h.db.profilePreferences).insert(ProfilePreferencesCompanion.insert(
          id: const Value(1),
          displayName: const Value('Fixture Longname Person'),
          updatedAt: DateTime.utc(2026, 11, 2),
        )));
    final repo = h.read(scheduleRepositoryProvider);
    await h.run(() => repo.create(classDraft(title: 'Fixture first', hour: 9, endHour: 10, professor: 'Fixture person')));
    await h.run(() => repo.create(classDraft(title: 'Fixture second', hour: 11, endHour: 12)));
    await h.settle();
    expect(h.tester.takeException(), isNull);
    await h.tester.scrollUntilVisible(find.byType(NextCard), 200, scrollable: find.byType(Scrollable).first);
    await h.tester.scrollUntilVisible(find.text('Fixture first'), 200, scrollable: find.byType(Scrollable).first);
    expect(h.tester.takeException(), isNull);
  });
}
