import 'package:schediel/features/appearance/appearance.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/icons.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:schediel/data/local/database.dart';

import '../../support/harness.dart';
import 'schedule_screens_test.dart' show classDraft;

void main() {
  appTest('the category tag is a borderless pill in the category color', (h) async {
    await h.run(
      () => (h.db.update(h.db.categories)..where((t) => t.id.equals('school'))).write(const CategoriesCompanion(colorKey: Value('red'))),
    );
    // The earliest upcoming item becomes the hero card; the second stays a timeline row.
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(title: 'Fixture hero', hour: 21, endHour: null)));
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(category: 'school', hour: 23, endHour: null)));
    await h.settle();
    final tag = find.byKey(const ValueKey('category-tag')).first;
    final box = h.tester.widget<Container>(tag).decoration! as BoxDecoration;
    final brightness = Theme.of(h.tester.element(tag)).brightness;
    expect(box.border, isNull);
    expect(box.color, CategoryColor.red.resolve(brightness).withValues(alpha: .18));
  });

  appTest('category cards have a folder tab and no folder icon', (h) async {
    await h.tapText('Settings');
    await h.tapText('Categories');
    for (final id in ['school', 'work', 'personal']) {
      final card = find.byKey(ValueKey(id));
      expect(find.descendant(of: card, matching: find.byWidgetPredicate((w) => w is AppIcon && w.icon == AppIcons.folder)), findsNothing);
      expect(find.descendant(of: card, matching: find.byKey(ValueKey('category-icon-$id'))), findsOneWidget);
    }
  });

  appTest('tags go neutral when category colors are off', (h) async {
    await h.run(
      () => (h.db.update(h.db.categories)..where((t) => t.id.equals('school'))).write(const CategoriesCompanion(colorKey: Value('red'))),
    );
    await h.run(() => h.read(appearanceProvider.notifier).update((a) => a.copyWith(showCategoryColors: false)));
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(title: 'Fixture hero', hour: 21, endHour: null)));
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(category: 'school', hour: 23, endHour: null)));
    await h.settle();
    final tag = find.byKey(const ValueKey('category-tag')).first;
    final box = h.tester.widget<Container>(tag).decoration! as BoxDecoration;
    final brightness = Theme.of(h.tester.element(tag)).brightness;
    expect(box.color, isNot(CategoryColor.red.resolve(brightness).withValues(alpha: .18)));
  });
}
