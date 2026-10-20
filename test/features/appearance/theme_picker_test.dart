import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/features/appearance/appearance.dart';
import 'package:schediel/features/appearance/appearance_screen.dart';

import '../../support/harness.dart';

void main() {
  appTest('mode buttons and their contents are centered at both text sizes', (h) async {
    await h.tapText('Settings');
    await h.tapText('Appearance');
    for (final scale in [1.0, 2.0]) {
      h.tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(h.tester.platformDispatcher.clearTextScaleFactorTestValue);
      await h.settle();
      final center = h.tester.getCenter(find.byType(ModeToggle)).dy;
      for (final (mode, label) in [(ThemeMode.light, 'Light'), (ThemeMode.dark, 'Dark'), (ThemeMode.system, 'Auto')]) {
        final button = find.byKey(ValueKey('mode-${mode.name}'));
        expect(h.tester.getCenter(button).dy, closeTo(center, .5));
        expect(h.tester.getCenter(find.descendant(of: button, matching: find.text(label))).dy,
          closeTo(center, .5));
        expect(h.tester.getSize(button).height, greaterThanOrEqualTo(40));
      }
      expect(h.tester.takeException(), isNull);
    }
  });
  appTest('appearance remains usable at 200 percent text and stores a texture for its family', (h) async {
    h.tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(h.tester.platformDispatcher.clearTextScaleFactorTestValue);
    await h.tapText('Settings');
    await h.tapText('Appearance');
    expect(h.tester.takeException(), isNull);
    await h.tester.ensureVisible(find.byKey(const ValueKey('theme-sketch')));
    await h.tester.tap(find.byKey(const ValueKey('theme-sketch')));
    await h.settle();
    await h.tester.scrollUntilVisible(
      find.byKey(const ValueKey('texture-selector')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await h.settle();

    await h.tapText('None');
    await h.tapText('Paper');
    final saved = await h.run(() => AppearanceRepository(h.db, clock: DateTime.now).load());
    expect(saved.customizations[ThemeId.sketch]!.texture.name, 'paper');
    expect(h.tester.takeException(), isNull);
  }, size: const Size(360, 800));
  appTest('appearance uses one live preview and a horizontal selector for every family', (h) async {
    await h.tapText('Settings');
    await h.tapText('Appearance');
    expect(find.byKey(const ValueKey('theme-preview')), findsOneWidget);
    final selector = h.tester.widget<SingleChildScrollView>(find.byKey(const ValueKey('theme-selector')));
    expect(selector.scrollDirection, Axis.horizontal);
    expect(find.byType(Slider), findsNWidgets(2));
  });
  Future<void> openThemes(TestHarness h) async {
    await h.tapText('Settings');
    await h.tapText('Appearance');
  }

  appTest('choosing a theme applies at once and is saved', (h) async {
    final handle = h.tester.ensureSemantics();
    await openThemes(h);
    for (final id in ThemeId.values) {
      expect(find.byKey(ValueKey('theme-${id.name}')), findsOneWidget, reason: id.name);
    }
    await h.tester.ensureVisible(find.byKey(const ValueKey('theme-pop')));
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
    await h.tester.ensureVisible(find.byKey(const ValueKey('theme-midnight')));
    await h.tester.tap(find.bySemanticsLabel('Midnight theme'));
    await h.settle();
    expect(find.text('Midnight is always dark.'), findsOneWidget);
    final toggle = h.tester.widget<ModeToggle>(find.byType(ModeToggle));
    expect(toggle.onChanged, isNull);
    expect(Theme.of(h.tester.element(find.text('Mode'))).brightness, Brightness.dark);
  });

  appTest('Custom color shows a hue control that saves when released', (h) async {
    await openThemes(h);
    expect(find.byType(Slider), findsNWidgets(2));
    await h.tester.ensureVisible(find.byKey(const ValueKey('theme-custom')));
    await h.tester.tap(find.bySemanticsLabel('Custom color theme'));
    await h.settle();
    final slider = find.descendant(of: find.byKey(const ValueKey('main-hue')), matching: find.byType(Slider));
    await h.tester.ensureVisible(slider);
    await h.settle();
    await h.tester.drag(slider, const Offset(-120, 0));
    await h.settle();
    final saved = await h.run(() => AppearanceRepository(h.db, clock: DateTime.now).load());
    expect(saved.theme, ThemeId.custom);
    expect(saved.customizations[ThemeId.custom]!.mainHue, isNot(250));
  });

  appTest('mode toggle switches to dark and saves', (h) async {
    await openThemes(h);
    await h.tester.tap(find.byKey(const ValueKey('mode-dark')));
    await h.settle();
    final saved = await h.run(() => AppearanceRepository(h.db, clock: DateTime.now).load());
    expect(saved.themeMode, ThemeMode.dark);
  });

  appTest('background target edits the background and a preset saves at once', (h) async {
    await openThemes(h);
    await h.tester.ensureVisible(find.byKey(const ValueKey('target-background')));
    await h.tester.tap(find.byKey(const ValueKey('target-background')));
    await h.settle();
    expect(find.byKey(const ValueKey('background-hue')), findsOneWidget);
    await h.tester.tap(find.bySemanticsLabel('Preset 1'));
    await h.settle();
    final saved = await h.run(() => AppearanceRepository(h.db, clock: DateTime.now).load());
    expect(saved.customizations[saved.theme]!.backgroundTone, 96);
  });

  appTest('density cards save the chosen density', (h) async {
    await openThemes(h);
    final card = find.byKey(const ValueKey('density-compact'));
    await h.tester.scrollUntilVisible(card, 160, scrollable: find.byType(Scrollable).first);
    await h.tester.ensureVisible(card);
    await h.settle();
    await h.tester.tap(find.byKey(const ValueKey('density-compact')));
    await h.settle();
    final saved = await h.run(() => AppearanceRepository(h.db, clock: DateTime.now).load());
    expect(saved.density.name, 'compact');
  });
}
