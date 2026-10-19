import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart' show contrastRatio;
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/features/widgets/domain/widget_theme.dart';

Color hex(Object? v) => Color(int.parse((v as String).substring(1), radix: 16) | 0xFF000000);

void main() {
  test('holder opacity keeps card text readable over black and white wallpaper', () {
    final themes = [
      for (final id in ThemeId.values.where((i) => i != ThemeId.custom)) themeFor(id),
      for (var h = 0; h < 360; h += 15) themeFor(ThemeId.custom, customHue: h),
    ];
    for (final t in themes) {
      final json = widgetThemeJson(t, ThemeMode.system);
      for (final name in ['light', 'dark']) {
        final p = json[name]! as Map<String, Object?>;
        final opacity = p['opacity']! as Map<String, Object?>;
        final pairs = [
          (hex(p['accent']), hex(p['onAccent'])),
          (hex(p['neutralFill']), hex(p['cardInk'])),
          for (final v in (p['categoryFills']! as Map<String, Object?>).values) (hex(v), hex(p['cardInk'])),
        ];
        for (final surface in ['clear', 'softTint']) {
          final alpha = (opacity[surface]! as num).toDouble();
          expect(alpha, inInclusiveRange(surface == 'clear' ? 0.70 : 0.88, 1.0));
          for (final (fill, ink) in pairs) {
            for (final wallpaper in [const Color(0xFF000000), const Color(0xFFFFFFFF)]) {
              final shown = Color.alphaBlend(fill.withValues(alpha: alpha), wallpaper);
              expect(contrastRatio(ink, shown), greaterThanOrEqualTo(4.5),
                  reason: '${t.id.name}/${t.customHue} $name $surface ${fill.toARGB32().toRadixString(16)} on $wallpaper');
            }
          }
        }
        expect(opacity['softTint']! as num, greaterThanOrEqualTo(opacity['clear']! as num));
      }
    }
  });

  test('both palettes follow the app mode; Midnight is always dark', () {
    final lilac = themeFor(ThemeId.lilac);
    final system = widgetThemeJson(lilac, ThemeMode.system);
    expect(system['light'], isNot(system['dark']));
    expect(hex((system['light']! as Map)['accent']), lilac.light.accent);
    expect(hex((system['dark']! as Map)['accent']), lilac.dark.accent);
    final light = widgetThemeJson(lilac, ThemeMode.light);
    expect(light['dark'], light['light']);
    final dark = widgetThemeJson(lilac, ThemeMode.dark);
    expect(dark['light'], dark['dark']);
    final midnight = widgetThemeJson(themeFor(ThemeId.midnight), ThemeMode.light);
    expect(hex((midnight['light']! as Map)['accent']), themeFor(ThemeId.midnight).dark.accent);
    expect(midnight['style'], 'soft');
    expect(widgetThemeJson(themeFor(ThemeId.pixel), ThemeMode.system)['style'], 'pixel');
  });

  test('colors are written as #RRGGBB and every category key is present', () {
    final p = widgetThemeJson(themeFor(ThemeId.pop), ThemeMode.system)['light']! as Map<String, Object?>;
    expect(p['accent'], '#FFD400');
    expect((p['categoryFills']! as Map).keys, unorderedEquals(['blue', 'green', 'orange', 'red', 'purple', 'gray']));
    for (final v in [p['accent'], p['onAccent'], p['neutralFill'], p['cardInk'], p['outline']]) {
      expect(v, matches(RegExp(r'^#[0-9A-F]{6}$')));
    }
  });
}
