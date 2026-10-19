import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/features/appearance/appearance.dart';

import '../../support/harness.dart';

void main() {
  for (final theme in [ThemeId.pixel, ThemeId.sketch]) {
    appTest('editor fields never use the ${theme.label} display font', (h) async {
      await h.run(() => h.read(appearanceProvider.notifier).update((a) => a.copyWith(theme: theme)));
      await h.settle();
      await h.tapText('Create schedule');
      final fields = find.byType(EditableText);
      expect(fields, findsWidgets);
      for (final e in h.tester.widgetList<EditableText>(fields)) {
        expect(e.style.fontFamily, isNot(anyOf('Silkscreen', 'Caveat')));
      }
      await h.tester.enterText(find.widgetWithText(TextField, 'Title'), 'Fixture title');
      await h.tester.pump();
      expect(find.text('Fixture title'), findsOneWidget);
    });
  }
}
