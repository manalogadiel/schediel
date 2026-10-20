import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/icons.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/app/theme/theme_customization.dart';
import 'package:schediel/app/theme/tokens.dart';

import '../../support/harness.dart';
import 'schedule_screens_test.dart' show classDraft;

void main() {
  test('soft filled buttons never draw an outline, even with a pale accent', () {
    final theme = buildTheme(
      theme: themeFor(ThemeId.lilac, customization: const ThemeCustomization(mainTone: 92)),
      brightness: Brightness.light,
      density: Density.comfortable,
      showCategoryColors: true,
    );
    final style = theme.filledButtonTheme.style!;
    final shape = style.shape!.resolve({})! as OutlinedBorder;
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
