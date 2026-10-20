import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/data/local/database.dart';

import '../../support/harness.dart';
import 'schedule_screens_test.dart' show classDraft;

void main() {
  appTest('week blocks use the category fill from the theme', (h) async {
    await h.run(() => (h.db.update(h.db.categories)..where((t) => t.id.equals('school')))
        .write(const CategoriesCompanion(colorKey: Value('green'))));
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(category: 'school')));
    await h.settle();
    await h.tapText('Week');
    final blocks = find.byKey(const ValueKey('week-block'));
    expect(blocks, findsNWidgets(2));
    final colors = h.tester.element(blocks.first).scheduleColors;
    final box = h.tester.widget<Material>(blocks.first);
    expect(box.color, colors.categoryFill('green'));
  });

  appTest('week navigation keeps its labelled controls', (h) async {
    await h.tapText('Week');
    expect(find.byTooltip('Previous week'), findsOneWidget);
    expect(find.byTooltip('Next week'), findsOneWidget);
    await h.tester.tap(find.byTooltip('Next week'));
    await h.settle();
    expect(find.text('This week'), findsOneWidget);
    await h.tapText('This week');
    expect(find.text('This week'), findsNothing);
  });

  appTest('hour labels stay on one line in the narrow time column', (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(category: 'school')));
    await h.settle();
    await h.tapText('Week');
    final labels = find.byKey(const ValueKey('week-hour-label'));
    expect(labels, findsWidgets);
    for (var i = 0; i < labels.evaluate().length; i++) {
      final label = labels.at(i);
      final text = (h.tester.widget(label) as Text).data;
      // One 11sp line, not "10:00 A" over "M", and inside the 44dp column as painted.
      expect(h.tester.getSize(label).height, lessThan(18), reason: text);
      expect(h.tester.getBottomRight(label).dx - h.tester.getTopLeft(label).dx, lessThanOrEqualTo(44.5), reason: text);
    }
  }, size: const Size(360, 800));

  appTest('week header days line up with their grid columns', (h) async {
    await h.tapText('Week');
    for (var i = 0; i < 7; i++) {
      final header = h.tester.getCenter(find.byKey(ValueKey('day-2026-11-0${i + 1}')));
      final column = h.tester.getCenter(find.byKey(ValueKey('week-column-$i')));
      expect((header.dx - column.dx).abs(), lessThan(1), reason: 'day ${i + 1}');
    }
    final headTint = h.tester.getRect(find.byKey(const ValueKey('week-selected-header')));
    final columnTint = h.tester.getRect(find.byKey(const ValueKey('week-selected-column')));
    expect((headTint.left - columnTint.left).abs(), lessThan(1));
    expect((headTint.right - columnTint.right).abs(), lessThan(1));
  });

  appTest('week block titles never split a word', (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(title: 'Automata Theory')));
    await h.settle();
    await h.tapText('Week');
    final block = find.byKey(const ValueKey('week-block')).first;
    final lines = h.tester.widgetList<Text>(find.descendant(of: block, matching: find.byType(Text))).toList();
    expect(lines, isNotEmpty);
    for (final line in lines) {
      expect(line.softWrap, isFalse, reason: line.data);
      expect(line.maxLines, 1, reason: line.data);
    }
    expect(lines.first.data, 'Automata');
  });

  appTest('an all-day item lays out in the week grid strip', (h) async {
    await h.run(
      () => h.read(scheduleRepositoryProvider).create(
        ScheduleDraft(title: 'Fixture all day', time: DateOnlySpec(startDate: LocalDate(2026, 11, 3), endDateExclusive: LocalDate(2026, 11, 4))),
      ),
    );
    await h.settle();
    await h.tapText('Week');
    expect(h.tester.takeException(), isNull);
    expect(find.text('Fixture all day'), findsOneWidget);
  });

  appTest('week blocks do not overflow at 200% text', (h) async {
    h.tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(h.tester.platformDispatcher.clearTextScaleFactorTestValue);
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(title: 'Automata Theory')));
    await h.settle();
    await h.tapText('Week');
    // Large text prefers the agenda; force the grid.
    await h.tester.tap(find.byTooltip('Show time grid'));
    await h.settle();
    expect(h.tester.takeException(), isNull);
  });

  appTest('the week number comes from the Thursday inside the visible week', (h) async {
    await h.tapText('Week');
    expect(find.text('W45'), findsOneWidget);
  });

  appTest('swiping the week header moves a week', (h) async {
    await h.tapText('Week');
    await h.tester.fling(find.byKey(const ValueKey('day-2026-11-04')), const Offset(-300, 0), 1000);
    await h.settle();
    expect(h.read(effectiveDateProvider), LocalDate(2026, 11, 9));
  });

  appTest('three overlapping blocks still show a title initial', (h) async {
    for (final title in ['Alpha', 'Beta', 'Gamma']) {
      await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(title: title, weekdays: const [1])));
    }
    await h.settle();
    await h.tapText('Week');
    expect(h.tester.takeException(), isNull);
    for (final initial in ['A', 'B', 'G']) {
      expect(find.descendant(of: find.byKey(const ValueKey('week-block')), matching: find.text(initial)), findsOneWidget, reason: initial);
    }
  }, size: const Size(360, 800));
}
