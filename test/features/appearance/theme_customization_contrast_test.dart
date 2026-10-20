import 'package:flutter/material.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/app/theme/theme_customization.dart';

void main() {
  test('sliders and selected controls stay visible with customized backgrounds', () {
    final issues = <String>[];
    for (final id in ThemeId.values) {
      for (final brightness in Brightness.values) {
        for (final tone in [0.0, 100.0]) {
          for (final bgTone in [0.0, 45.0, 50.0, 100.0]) {
            final t = themeFor(
              id,
              customization: ThemeCustomization(mainTone: tone, backgroundTone: bgTone),
            );
            final data = buildTheme(theme: t, brightness: brightness, density: Density.comfortable, showCategoryColors: true);
            final p = t.palette(brightness);
            final thumb = data.sliderTheme.thumbColor ?? data.colorScheme.primary;
            if (contrastRatio(thumb, p.surface) < 3 || contrastRatio(thumb, p.canvas) < 3) {
              issues.add('$id $brightness $tone/$bgTone slider');
            }
            final style = data.segmentedButtonTheme.style!;
            final background = Color.alphaBlend(style.backgroundColor!.resolve({WidgetState.selected})!, p.surface);
            if (contrastRatio(style.foregroundColor!.resolve({WidgetState.selected})!, background) < 4.5) {
              issues.add('$id $brightness $tone/$bgTone selected text');
            }
          }
        }
      }
    }
    expect(issues.take(8), isEmpty);
  });
  test('extreme hue and tone settings retain readable text and control boundaries', () {
    for (final id in ThemeId.values) {
      for (final hue in [0.0, 359.0]) {
        for (final tone in [0.0, 45.0, 50.0, 100.0]) {
          for (final bgTone in [0.0, 45.0, 50.0, 100.0]) {
            final base = themeFor(id);
            final t = themeFor(
              id,
              customization: ThemeCustomization(mainHue: hue, mainTone: tone, backgroundHue: hue, backgroundTone: bgTone),
            );
            expect(t.displayFont, base.displayFont);
            expect(t.style, base.style);
            for (final brightness in Brightness.values) {
              final p = t.palette(brightness);
              final data = buildTheme(theme: t, brightness: brightness, density: Density.comfortable, showCategoryColors: true);
              final colors = data.extension<ScheduleColors>()!;
              for (final (name, fg, bg) in [
                ('body/canvas', p.ink, p.canvas),
                ('body/surface', p.ink, p.surface),
                ('secondary/canvas', p.secondaryInk, p.canvas),
                ('secondary/surface', p.secondaryInk, p.surface),
                ('accent', p.onAccent, p.accent),
                ('navigation', p.navInk, p.navBackground),
                ('selected navigation', p.navOnSelected, p.navSelected),
                ('badge', p.onNowBadge, p.nowBadge),
                ('error/canvas', data.colorScheme.error, p.canvas),
                ('error/surface', data.colorScheme.error, p.surface),
                for (final fill in p.categoryFills.values) ('category', p.cardInk, fill),
              ]) {
                expect(
                  contrastRatio(fg, bg),
                  greaterThanOrEqualTo(4.5),
                  reason: '$id $brightness hue=$hue main=$tone background=$bgTone $name',
                );
              }
              expect(contrastRatio(colors.inputBoundary, p.surface), greaterThanOrEqualTo(3));
              final style = data.filledButtonTheme.style!;
              final border = style.side?.resolve({}) ?? style.shape!.resolve({})!.side;
              final outlineContrast = border.style == BorderStyle.none ? 0.0 : contrastRatio(border.color, p.surface);
              final fillContrast = contrastRatio(p.accent, p.surface);
              expect(
                fillContrast > outlineContrast ? fillContrast : outlineContrast,
                greaterThanOrEqualTo(3),
                reason: '$id $brightness main=$tone background=$bgTone filled control',
              );
              expect(p.categoryFills, base.palette(brightness).categoryFills);
            }
          }
        }
      }
    }
  });
  test('empty and texture-only overrides preserve default colors', () {
    for (final id in ThemeId.values) {
      final base = themeFor(id);
      for (final value in [const ThemeCustomization(), const ThemeCustomization(texture: ThemeTexture.paper)]) {
        final resolved = themeFor(id, customization: value);
        expect(resolved.light.canvas, base.light.canvas);
        expect(resolved.dark.accent, base.dark.accent);
      }
    }
  });
  test('malformed and unknown JSON is ignored while numbers are clamped safely', () {
    for (final value in ['broken', 'null', '[]', '42', '{"unknown":{"mainHue":100}}']) {
      expect(decodeThemeCustomizations(value), isEmpty);
    }
    final parsed = decodeThemeCustomizations(
      '{"pop":{"mainHue":999,"mainTone":-20,"backgroundHue":"12","backgroundTone":120,"texture":"unknown","ignored":true},"pixel":[]}',
    );
    expect(parsed.keys, [ThemeId.pop]);
    expect(parsed[ThemeId.pop], const ThemeCustomization(mainHue: 359, mainTone: 0, backgroundTone: 100));
    expect(ThemeCustomization.number(double.infinity, 100), isNull);
    expect(const ThemeCustomization(mainHue: double.nan).toJson(), isNot(contains('mainHue')));
  });
}
