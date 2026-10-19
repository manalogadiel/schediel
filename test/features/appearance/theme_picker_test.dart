import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/features/appearance/appearance.dart';

import '../../support/harness.dart';

void main() {
  Future<void> openThemes(TestHarness h) async {
    await h.tapText('Settings');
    await h.tapText('Appearance');
  }

  appTest('choosing a theme applies at once and is saved', (h) async {
    final handle = h.tester.ensureSemantics();
    await openThemes(h);
    for (final id in ThemeId.values) {
      expect(find.bySemanticsLabel('${id.label} theme'), findsOneWidget, reason: id.name);
    }
    await h.tester.tap(find.bySemanticsLabel('Pop theme'));
    await h.settle();
    final colors = h.tester.element(find.text('Mode')).scheduleColors;
    expect(colors.style, StyleFamily.pop);
    final saved = await h.run(() => AppearanceRepository(h.db, clock: DateTime.now).load());
    expect(saved.theme, ThemeId.pop);
    handle.dispose();
  });

  appTest('Midnight disables the mode choice and says why', (h) async {
    await openThemes(h);
    await h.tester.tap(find.bySemanticsLabel('Midnight theme'));
    await h.settle();
    expect(find.text('Midnight is always dark.'), findsOneWidget);
    final buttons = h.tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>));
    expect(buttons.onSelectionChanged, isNull);
    expect(Theme.of(h.tester.element(find.text('Mode'))).brightness, Brightness.dark);
  });

  appTest('Custom color shows a hue control that saves when released', (h) async {
    await openThemes(h);
    expect(find.byType(Slider), findsNothing);
    await h.tester.tap(find.bySemanticsLabel('Custom color theme'));
    await h.settle();
    final slider = find.byType(Slider);
    await h.tester.ensureVisible(slider);
    await h.settle();
    await h.tester.drag(slider, const Offset(-120, 0));
    await h.settle();
    final saved = await h.run(() => AppearanceRepository(h.db, clock: DateTime.now).load());
    expect(saved.theme, ThemeId.custom);
    expect(saved.customHue, isNot(250));
  });
}
