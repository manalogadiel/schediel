import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/features/appearance/appearance.dart';

import '../../support/harness.dart';

void main() {
  for (final theme in [ThemeId.lilac, ThemeId.pop]) {
    appTest('category color swatches show the ${theme.label} fills with their names', (h) async {
      await h.run(() => h.read(appearanceProvider.notifier).update((a) => a.copyWith(theme: theme)));
      await h.settle();
      await h.tapText('Settings');
      await h.tapText('Categories');
      await h.tapText('School');
      for (final key in ['Blue', 'Green', 'Orange', 'Red', 'Purple', 'Gray']) {
        expect(find.text(key), findsOneWidget);
      }
      final dot = find.byKey(const ValueKey('color-dot-red'));
      final fill = (h.tester.widget<Container>(dot).decoration! as BoxDecoration).color;
      expect(fill, h.tester.element(dot).scheduleColors.palette.fillFor('red'));
    });
  }
}
