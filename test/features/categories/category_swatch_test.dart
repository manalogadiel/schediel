import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/widgets/common.dart';
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
      final swatch = find.descendant(of: find.widgetWithText(ChoiceChip, 'Red'), matching: find.byType(CategorySwatch));
      final box = h.tester.widget<Container>(find.descendant(of: swatch, matching: find.byType(Container)));
      final fill = (box.decoration! as BoxDecoration).color;
      expect(fill, h.tester.element(swatch).scheduleColors.palette.fillFor('red'));
    });
  }
}
