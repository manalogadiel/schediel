import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/icons.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/router.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/app/theme/theme_customization.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:schediel/features/schedules/presentation/occurrence_sheet.dart';

import '../../support/harness.dart';
import 'schedule_screens_test.dart' show classDraft;

void main() {
  for (final tab in ['Today', 'Week']) {
    appTest('$tab details open higher on the root navigator above the floating bar', (h) async {
      await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(title: 'Fixture visible actions', professor: 'Fixture person')));
      await h.settle();
      if (tab == 'Week') {
        await h.tapText('Week');
        final block = find.byKey(const ValueKey('week-block')).first;
        await h.tester.ensureVisible(block);
        await h.tester.tap(block);
        await h.settle();
      } else {
        await h.tapText('Fixture visible actions');
      }
      final details = find.byType(OccurrenceDetails);
      final route = ModalRoute.of(h.tester.element(details))!;
      expect(route.navigator, same(rootNavigatorKey.currentState));
      expect(h.tester.widget<DraggableScrollableSheet>(find.byType(DraggableScrollableSheet)).initialChildSize, .75);
      expect(h.tester.getSize(details).height, greaterThan(h.tester.view.physicalSize.height / h.tester.view.devicePixelRatio * .65));
      expect(find.text('Edit').hitTestable(), findsOneWidget);
      expect(find.text('Remove').hitTestable(), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-week')).hitTestable(), findsNothing);
      expect(h.tester.takeException(), isNull);
    });
  }
  test('soft filled buttons never draw an outline, even with a pale accent', () {
    final theme = buildTheme(
      theme: themeFor(ThemeId.lilac, customization: const ThemeCustomization(mainTone: 92)),
      brightness: Brightness.light,
      density: Density.comfortable,
      showCategoryColors: true,
    );
    final style = theme.filledButtonTheme.style!;
    final shape = style.shape!.resolve({})!;
    expect(shape.side, BorderSide.none);
    final bg = style.backgroundColor!.resolve({})!;
    final fg = style.foregroundColor!.resolve({})!;
    expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(bg, theme.colorScheme.surface), greaterThanOrEqualTo(3));
  });

  appTest('the remove action shows its trash icon in the error color on a soft red fill', (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(title: 'Fixture sheet')));
    await h.settle();
    await h.tapText('Fixture sheet');
    final remove = find.ancestor(of: find.text('Remove'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(remove, findsOneWidget);
    final error = Theme.of(h.tester.element(remove)).colorScheme.error;
    final style = h.tester.widget<ButtonStyleButton>(remove).style!;
    expect(style.foregroundColor!.resolve({}), error);
    expect(style.backgroundColor!.resolve({}), error.withValues(alpha: .12));
    final icon = h.tester.widget<AppIcon>(find.descendant(of: remove, matching: find.byType(AppIcon)));
    expect(icon.color, error);
  });

  appTest('the edit icon follows the button foreground', (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(title: 'Fixture edit')));
    await h.settle();
    await h.tapText('Fixture edit');
    final edit = find.ancestor(of: find.text('Edit'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    final icon = h.tester.widget<AppIcon>(find.descendant(of: edit, matching: find.byType(AppIcon)));
    expect(icon.color, isNull, reason: 'inherits the deepened fill foreground via IconTheme');
  });
}
