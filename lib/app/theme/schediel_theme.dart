import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/material.dart' show Brightness, Color, FontWeight;

/// User-selectable themes (design spec §5).
enum ThemeId {
  lilac('Lilac'),
  clay('Clay'),
  pop('Pop'),
  mint('Mint'),
  midnight('Midnight'),
  pixel('Pixel'),
  sketch('Sketch'),
  custom('Custom color');

  const ThemeId(this.label);
  final String label;

  static ThemeId fromKey(String? key) =>
      ThemeId.values.firstWhere((t) => t.name == key, orElse: () => ThemeId.lilac);
}

/// How cards, pills and buttons are drawn.
/// soft: rounded with a faint shadow; pop: black outline and hard offset
/// shadow; pixel: square with notched pixel corners; sketch: hand-drawn
/// outlines on lined paper.
enum StyleFamily { soft, pop, pixel, sketch }

/// The six stored category color keys. The theme decides how each looks.
enum CategoryColorKey {
  blue,
  green,
  orange,
  red,
  purple,
  gray;

  static CategoryColorKey? fromKey(String? key) {
    for (final k in values) {
      if (k.name == key) return k;
    }
    return null;
  }
}

/// Every color one brightness of a theme draws.
@immutable
class ThemePalette {
  const ThemePalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.secondaryInk,
    required this.divider,
    required this.accent,
    required this.onAccent,
    required this.navBackground,
    required this.navInk,
    required this.navSelected,
    required this.navOnSelected,
    required this.nowBadge,
    required this.onNowBadge,
    required this.cardInk,
    required this.outline,
    required this.neutralFill,
    required this.categoryFills,
  });

  final Brightness brightness;
  final Color canvas;
  final Color surface;
  final Color ink;
  final Color secondaryInk;
  final Color divider;
  final Color accent;
  final Color onAccent;
  final Color navBackground;
  final Color navInk;
  final Color navSelected;
  final Color navOnSelected;
  final Color nowBadge;
  final Color onNowBadge;

  /// Text on category and neutral card fills.
  final Color cardInk;

  /// Outline for pop, pixel and sketch shapes.
  final Color outline;

  /// Card fill when a schedule has no category color or colors are off.
  final Color neutralFill;
  final Map<CategoryColorKey, Color> categoryFills;

  Color fillFor(String? colorKey) => categoryFills[CategoryColorKey.fromKey(colorKey)] ?? neutralFill;
}

/// A complete theme: palette for each brightness plus shape and type.
@immutable
class SchedielTheme {
  const SchedielTheme({
    required this.id,
    required this.style,
    required this.radius,
    required this.light,
    required this.dark,
    this.displayFont,
    this.displayWeight = FontWeight.w700,
    this.darkOnly = false,
    this.customHue,
  });

  final ThemeId id;
  final StyleFamily style;

  /// Card corner radius in logical pixels (0 for pixel).
  final double radius;

  /// Bundled display family for headings, or null for the system font.
  final String? displayFont;
  final FontWeight displayWeight;
  final ThemePalette light;
  final ThemePalette dark;

  /// The theme has no light variant (Midnight); app mode is ignored.
  final bool darkOnly;

  /// Hue for [ThemeId.custom]; null otherwise.
  final int? customHue;

  ThemePalette palette(Brightness b) => darkOnly || b == Brightness.dark ? dark : light;
}
