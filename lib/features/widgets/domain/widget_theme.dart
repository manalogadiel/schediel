import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart' show contrastRatio;
import '../../../app/theme/schediel_theme.dart';

/// Lowest holder opacities tried for translucent surfaces (design §8.1).
const widgetClearStart = 0.70;
const widgetSoftTintStart = 0.88;

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// The lowest opacity from [start] (2% steps) at which every holder's text
/// stays at 4.5:1 when the holder is composited over pure black and pure
/// white wallpaper. 1.0 when nothing lower passes.
double holderOpacity(ThemePalette p, double start) {
  final pairs = [
    (p.accent, p.onAccent),
    (p.neutralFill, p.cardInk),
    for (final fill in p.categoryFills.values) (fill, p.cardInk),
  ];
  bool readable(double alpha) {
    for (final (fill, ink) in pairs) {
      for (final wallpaper in const [Color(0xFF000000), Color(0xFFFFFFFF)]) {
        if (contrastRatio(ink, Color.alphaBlend(fill.withValues(alpha: alpha), wallpaper)) < 4.5) return false;
      }
    }
    return true;
  }

  for (var step = (start * 100).round(); step < 100; step += 2) {
    if (readable(step / 100)) return step / 100;
  }
  return 1.0;
}

Map<String, Object?> _palette(ThemePalette p) => {
      'accent': _hex(p.accent),
      'onAccent': _hex(p.onAccent),
      'neutralFill': _hex(p.neutralFill),
      'cardInk': _hex(p.cardInk),
      'outline': _hex(p.outline),
      'categoryFills': {for (final e in p.categoryFills.entries) e.key.name: _hex(e.value)},
      'opacity': {
        'clear': holderOpacity(p, widgetClearStart),
        'softTint': holderOpacity(p, widgetSoftTintStart),
      },
    };

/// The snapshot `theme` object (contract 1.1). Both palettes are always
/// written so the widget can follow the phone's night mode while the app is
/// closed; a fixed app mode (or Midnight) writes the same palette twice.
Map<String, Object?> widgetThemeJson(SchedielTheme theme, ThemeMode mode) {
  final light = theme.darkOnly || mode == ThemeMode.dark ? theme.dark : theme.light;
  final dark = !theme.darkOnly && mode == ThemeMode.light ? theme.light : theme.dark;
  return {
    'id': theme.id.name,
    'style': theme.style.name,
    'light': _palette(light),
    'dark': _palette(dark),
  };
}

/// Colors for one themed holder (mirrors android/.../widget/ThemeStyle.kt).
@immutable
class HolderColors {
  const HolderColors({required this.fill, required this.ink, required this.outline});

  /// Fill including the surface opacity.
  final Color fill;
  final Color ink;
  final Color outline;
}

Color _parse(Object? hex) => Color(int.parse((hex! as String).substring(1), radix: 16) | 0xFF000000);

/// Next holders use the accent; others their category fill (neutral when
/// absent). Clear and soft tint use the palette's tested opacity.
HolderColors holderColors(Map<String, Object?> palette, {required bool next, String? categoryColor, required String surface}) {
  final fills = palette['categoryFills']! as Map<String, Object?>;
  final base = next ? _parse(palette['accent']) : _parse(fills[categoryColor] ?? palette['neutralFill']);
  final ink = next ? _parse(palette['onAccent']) : _parse(palette['cardInk']);
  final opacity = palette['opacity']! as Map<String, Object?>;
  final alpha = switch (surface) {
    'clear' => (opacity['clear']! as num).toDouble(),
    'softTint' => (opacity['softTint']! as num).toDouble(),
    _ => 1.0,
  };
  return HolderColors(fill: base.withValues(alpha: alpha), ink: ink, outline: _parse(palette['outline']));
}
