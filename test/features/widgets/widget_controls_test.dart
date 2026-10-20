import 'package:flutter/material.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/features/widgets/domain/widget_config.dart';

import '../schedules/schedule_screens_test.dart' show classDraft;

import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/features/widgets/data/widget_config_repository.dart';

import '../../support/harness.dart';

void main() {
  appTest('expanded preview keeps every shown row intact and respects hidden details', (h) async {
    h.tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(h.tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (var i = 0; i < 4; i++) {
      await h.run(
        () => h.read(scheduleRepositoryProvider).create(classDraft(title: 'Fixture $i', hour: 9 + i * 2, endHour: 10 + i * 2)),
      );
    }
    await h.run(
      () => WidgetConfigRepository(
        h.db,
        clock: DateTime.now,
      ).save(WidgetConfig.defaults.copyWith(layout: WidgetLayout.expanded, showLocation: true)),
    );
    await h.tapText('Settings');
    await h.tester.scrollUntilVisible(find.text('Home screen widgets'), 160, scrollable: find.byType(Scrollable).first);
    await h.settle();
    await h.tapText('Home screen widgets');
    await h.tester.scrollUntilVisible(find.text('Default widget settings'), 160, scrollable: find.byType(Scrollable).first);
    await h.settle();
    await h.tapText('Default widget settings');
    final preview = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Widget preview');
    expect(preview, findsOneWidget);
    expect(find.descendant(of: preview, matching: find.textContaining('Fixture room')), findsNothing);
    expect(h.tester.takeException(), isNull);
  });
  appTest('widget categories use one grouped selector and apply only the chosen filter', (h) async {
    await h.tapText('Settings');
    await h.tester.scrollUntilVisible(find.text('Home screen widgets'), 160, scrollable: find.byType(Scrollable).first);
    await h.settle();
    await h.tapText('Home screen widgets');
    await h.tester.scrollUntilVisible(find.text('Default widget settings'), 160, scrollable: find.byType(Scrollable).first);
    await h.settle();
    await h.tapText('Default widget settings');
    expect(find.byType(FilterChip), findsNothing);
    await h.tester.scrollUntilVisible(
      find.byKey(const ValueKey('widget-filter-selector')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await h.settle();
    await h.tester.tap(find.byKey(const ValueKey('widget-filter-selector')));
    await h.settle();
    await h.tester.tap(find.widgetWithText(CheckboxListTile, 'School'));
    await h.settle();
    await h.tapText('Apply');
    final configs = await h.run(() => WidgetConfigRepository(h.db, clock: DateTime.now).loadAll());
    expect(configs.single.filter.categoryIds, {'school'});
    expect(configs.single.filter.isAll, isFalse);
    await h.tester.tap(find.byKey(const ValueKey('widget-filter-selector')));
    await h.settle();
    await h.tester.tap(find.widgetWithText(CheckboxListTile, 'Work'));
    await h.settle();
    await h.tapText('Cancel');
    final unchanged = await h.run(() => WidgetConfigRepository(h.db, clock: DateTime.now).loadAll());
    expect(unchanged.single.filter.categoryIds, {'school'});
  });
}
