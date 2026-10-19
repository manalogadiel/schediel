import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:schediel/app/theme/app_theme.dart' show contrastRatio;
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';

/// Every text/background pair a theme draws (spec §5.5).
List<(String, Color, Color)> textPairs(ThemePalette p) => [
      ('ink/canvas', p.ink, p.canvas),
      ('ink/surface', p.ink, p.surface),
      ('secondary/canvas', p.secondaryInk, p.canvas),
      ('secondary/surface', p.secondaryInk, p.surface),
      ('onAccent/accent', p.onAccent, p.accent),
      ('navInk/nav', p.navInk, p.navBackground),
      ('navOnSelected/navSelected', p.navOnSelected, p.navSelected),
      ('onNow/now', p.onNowBadge, p.nowBadge),
      for (final e in p.categoryFills.entries) ('cardInk/${e.key.name}', p.cardInk, e.value),
      ('cardInk/neutral', p.cardInk, p.neutralFill),
    ];

void expectReadable(String label, SchedielTheme t, ThemePalette p) {
  for (final (name, fg, bg) in textPairs(p)) {
    expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5), reason: '$label $name ${fg.toARGB32().toRadixString(16)} on ${bg.toARGB32().toRadixString(16)}');
  }
  // Non-text boundary of the selected day pill (WCAG 1.4.11): its fill, or
  // the outline that outlined styles draw around it.
  final boundary = [contrastRatio(p.accent, p.canvas), if (t.style != StyleFamily.soft) contrastRatio(p.outline, p.canvas)];
  expect(boundary.reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(3.0), reason: '$label accent boundary');
}

void main() {
  test('every built-in theme meets text contrast in both brightnesses', () {
    for (final id in ThemeId.values.where((i) => i != ThemeId.custom)) {
      final t = themeFor(id);
      expectReadable('${id.name} light', t, t.light);
      expectReadable('${id.name} dark', t, t.dark);
    }
  });

  test('custom palettes pass contrast for every 15 degree hue', () {
    for (var hue = 0; hue < 360; hue += 15) {
      final t = themeFor(ThemeId.custom, customHue: hue);
      expectReadable('custom $hue light', t, t.light);
      expectReadable('custom $hue dark', t, t.dark);
    }
  });

  test('light values match the approved mockup', () {
    final lilac = themeFor(ThemeId.lilac).light;
    expect(lilac.canvas, const Color(0xFFF4F2FC));
    expect(lilac.accent, const Color(0xFF6A5AE0));
    expect(lilac.categoryFills[CategoryColorKey.blue], const Color(0xFFDDEBFF));
    expect(themeFor(ThemeId.clay).light.canvas, const Color(0xFFF3ECE4));
    final pop = themeFor(ThemeId.pop);
    expect(pop.light.accent, const Color(0xFFFFD400));
    expect(pop.light.onAccent, const Color(0xFF111111));
    expect(pop.style, StyleFamily.pop);
    expect(themeFor(ThemeId.mint).light.accent, const Color(0xFF17805A));
    final pixel = themeFor(ThemeId.pixel);
    expect(pixel.radius, 0);
    expect(pixel.displayFont, 'Silkscreen');
    expect(pixel.style, StyleFamily.pixel);
    final sketch = themeFor(ThemeId.sketch);
    expect(sketch.displayFont, 'Caveat');
    expect(sketch.style, StyleFamily.sketch);
    expect(sketch.light.accent, const Color(0xFFFFE066));
    final midnight = themeFor(ThemeId.midnight);
    expect(midnight.darkOnly, isTrue);
    expect(midnight.dark.canvas, const Color(0xFF0F1117));
    expect(midnight.light, same(midnight.dark));
    expect(themeFor(ThemeId.lilac).displayFont, isNull);
  });

  test('category fills keep their hue family in Custom', () {
    final base = themeFor(ThemeId.lilac).light.categoryFills;
    for (var hue = 0; hue < 360; hue += 15) {
      final custom = themeFor(ThemeId.custom, customHue: hue).light.categoryFills;
      for (final key in CategoryColorKey.values.where((k) => k != CategoryColorKey.gray)) {
        final a = Hct.fromInt(base[key]!.toARGB32()).hue;
        final b = Hct.fromInt(custom[key]!.toARGB32()).hue;
        final diff = ((a - b).abs() % 360).clamp(0, 360);
        expect(diff > 180 ? 360 - diff : diff, lessThanOrEqualTo(25), reason: 'hue $hue ${key.name}');
      }
    }
  });

  test('custom accent follows the chosen hue', () {
    final accent = themeFor(ThemeId.custom, customHue: 140).light.accent;
    final hue = Hct.fromInt(accent.toARGB32()).hue;
    expect((hue - 140).abs(), lessThan(15));
  });

  test('theme ids round-trip through storage keys', () {
    for (final id in ThemeId.values) {
      expect(ThemeId.fromKey(id.name), id);
    }
    expect(ThemeId.fromKey('unknown'), ThemeId.lilac);
    expect(ThemeId.fromKey(null), ThemeId.lilac);
  });
}
