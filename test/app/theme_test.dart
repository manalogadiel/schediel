import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/app/theme/tokens.dart';

ThemeData build(ThemeId id, Brightness b, {int hue = 250}) =>
    buildTheme(theme: themeFor(id, customHue: hue), brightness: b, density: Density.comfortable, showCategoryColors: true);

void main() {
  test('contrast ratio matches known WCAG values', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.001));
  });

  test('error text stays readable on every theme surface', () {
    for (final id in ThemeId.values) {
      for (final b in Brightness.values) {
        final t = build(id, b);
        expect(contrastRatio(t.colorScheme.error, t.colorScheme.surface), greaterThanOrEqualTo(4.5), reason: '${id.name} $b');
        expect(contrastRatio(t.colorScheme.error, t.scaffoldBackgroundColor), greaterThanOrEqualTo(4.5), reason: '${id.name} $b canvas');
      }
    }
  });

  test('the theme palette drives the color scheme', () {
    final light = build(ThemeId.lilac, Brightness.light);
    expect(light.colorScheme.primary, const Color(0xFF6A5AE0));
    expect(light.scaffoldBackgroundColor, const Color(0xFFF4F2FC));
    final colors = light.extension<ScheduleColors>()!;
    expect(colors.style, StyleFamily.soft);
    expect(colors.categoryFill('blue'), const Color(0xFFDDEBFF));
    expect(colors.categoryFill(null), colors.palette.neutralFill);
    final dark = buildTheme(theme: themeFor(ThemeId.lilac), brightness: Brightness.dark, density: Density.compact, showCategoryColors: false);
    expect(dark.brightness, Brightness.dark);
    expect(dark.extension<ScheduleColors>()!.density, Density.compact);
    // Category colors off: every category uses the neutral fill.
    final off = dark.extension<ScheduleColors>()!;
    expect(off.categoryFill('red'), off.palette.neutralFill);
  });

  test('Midnight is always dark', () {
    expect(build(ThemeId.midnight, Brightness.light).brightness, Brightness.dark);
    expect(effectiveThemeMode(themeFor(ThemeId.midnight), ThemeMode.light), ThemeMode.dark);
    expect(effectiveThemeMode(themeFor(ThemeId.lilac), ThemeMode.light), ThemeMode.light);
  });

  test('display text styles use the theme display font and body styles never do', () {
    final pixel = build(ThemeId.pixel, Brightness.light).textTheme;
    expect(pixel.headlineMedium!.fontFamily, 'Silkscreen');
    expect(pixel.titleLarge!.fontFamily, 'Silkscreen');
    for (final style in [pixel.bodyLarge, pixel.bodyMedium, pixel.bodySmall, pixel.labelLarge, pixel.labelMedium, pixel.labelSmall, pixel.titleMedium]) {
      // ThemeData fills in the platform font; never a display font.
      expect(style!.fontFamily, isNot(anyOf('Silkscreen', 'Caveat')));
    }
    final sketch = build(ThemeId.sketch, Brightness.light).textTheme;
    expect(sketch.headlineMedium!.fontFamily, 'Caveat');
    expect(build(ThemeId.lilac, Brightness.light).textTheme.headlineMedium!.fontFamily, isNot(anyOf('Silkscreen', 'Caveat')));
  });

  test('segmented and text-button labels stay readable in every theme (yellow accents included)', () {
    for (final id in ThemeId.values) {
      for (final b in Brightness.values) {
        final t = build(id, b);
        final c = t.extension<ScheduleColors>()!;
        final seg = t.segmentedButtonTheme.style!;
        final unselected = seg.foregroundColor!.resolve(const {})!;
        final selected = seg.foregroundColor!.resolve(const {WidgetState.selected})!;
        final selectedBg = seg.backgroundColor!.resolve(const {WidgetState.selected})!;
        for (final bg in [c.surface, c.palette.canvas]) {
          expect(contrastRatio(unselected, bg), greaterThanOrEqualTo(4.5), reason: '${id.name} $b unselected segment');
        }
        expect(contrastRatio(selected, Color.alphaBlend(selectedBg, c.surface)), greaterThanOrEqualTo(4.5),
            reason: '${id.name} $b selected segment');
        final textButton = t.textButtonTheme.style!.foregroundColor!.resolve(const {})!;
        expect(contrastRatio(textButton, c.palette.canvas), greaterThanOrEqualTo(4.5), reason: '${id.name} $b text button');
      }
    }
  });
}
