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
}
