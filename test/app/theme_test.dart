import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/tokens.dart';

void main() {
  test('contrast ratio matches known WCAG values', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.001));
  });

  test('opaque design-token text pairs meet 4.5:1', () {
    final pairs = {
      'primary/surface': (Tokens.primary, Tokens.surface),
      'primary/neutral': (Tokens.primary, Tokens.neutral),
      'secondary/surface': (Tokens.secondary, Tokens.surface),
      'secondary/neutral': (Tokens.secondary, Tokens.neutral),
      'error/surface': (Tokens.error, Tokens.surface),
      'darkInk/darkSurface': (Tokens.darkInk, Tokens.darkSurface),
      'darkSecondary/darkSurface': (Tokens.darkSecondary, Tokens.darkSurface),
      'darkSecondary/darkCanvas': (Tokens.darkSecondary, Tokens.darkCanvas),
      'darkError/darkSurface': (Tokens.darkError, Tokens.darkSurface),
    };
    pairs.forEach((name, pair) {
      expect(contrastRatio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5), reason: name);
    });
  });

  test('every accent preset is a tested pair in both appearances', () {
    for (final preset in AccentPreset.values) {
      expect(contrastRatio(preset.light.accent, preset.light.onAccent), greaterThanOrEqualTo(4.5), reason: '${preset.name} light button');
      expect(contrastRatio(preset.light.accent, Tokens.surface), greaterThanOrEqualTo(4.5), reason: '${preset.name} light link');
      expect(contrastRatio(preset.light.accent, Tokens.neutral), greaterThanOrEqualTo(4.5), reason: '${preset.name} light link on canvas');
      expect(contrastRatio(preset.dark.accent, preset.dark.onAccent), greaterThanOrEqualTo(4.5), reason: '${preset.name} dark button');
      expect(contrastRatio(preset.dark.accent, Tokens.darkSurface), greaterThanOrEqualTo(4.5), reason: '${preset.name} dark link');
      expect(contrastRatio(preset.dark.accent, Tokens.darkCanvas), greaterThanOrEqualTo(4.5), reason: '${preset.name} dark link on canvas');
    }
  });

  test('category colors are visible non-text marks (3:1) in both appearances', () {
    for (final color in CategoryColor.values) {
      expect(contrastRatio(color.light, Tokens.surface), greaterThanOrEqualTo(3), reason: '${color.name} light');
      expect(contrastRatio(color.light, Tokens.neutral), greaterThanOrEqualTo(3), reason: '${color.name} light canvas');
      expect(contrastRatio(color.dark, Tokens.darkSurface), greaterThanOrEqualTo(3), reason: '${color.name} dark');
      expect(contrastRatio(color.dark, Tokens.darkCanvas), greaterThanOrEqualTo(3), reason: '${color.name} dark canvas');
    }
  });

  test('builds light and dark themes from the tokens', () {
    final light = buildTheme(brightness: Brightness.light, accent: AccentPreset.blue, density: Density.comfortable, showCategoryColors: true);
    expect(light.colorScheme.primary, Tokens.tertiary);
    expect(light.scaffoldBackgroundColor, Tokens.neutral);
    final dark = buildTheme(brightness: Brightness.dark, accent: AccentPreset.blue, density: Density.compact, showCategoryColors: false);
    expect(dark.colorScheme.primary, Tokens.darkAccent);
    expect(dark.colorScheme.onPrimary, Tokens.darkOnAccent);
    expect(dark.extension<ScheduleColors>()!.density, Density.compact);
  });
}
