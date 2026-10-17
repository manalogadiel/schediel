import 'package:flutter/material.dart';

/// Design tokens from DESIGN.md. Values are logical pixels.
abstract final class Tokens {
  // Light appearance.
  static const primary = Color(0xFF1D1D1F);
  static const secondary = Color(0xFF5A5A60);
  static const tertiary = Color(0xFF0066CC);
  static const neutral = Color(0xFFF5F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const onAccent = Color(0xFFFFFFFF);
  static const error = Color(0xFFB3261E);
  static const inputBoundary = Color(0xFF8A8A92);
  static const divider = Color(0xFFD6D6DC);

  // Dark appearance.
  static const darkCanvas = Color(0xFF0C0C0E);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkInk = Color(0xFFF5F5F7);
  static const darkSecondary = Color(0xFFB2B2BA);
  static const darkAccent = Color(0xFF64A7FF);
  static const darkOnAccent = Color(0xFF081322);
  static const darkError = Color(0xFFFFB4AB);
  static const darkInputBoundary = Color(0xFF8E8E96);
  static const darkDivider = Color(0xFF3A3A3E);

  // Radii.
  static const radiusControl = 12.0;
  static const radiusCard = 18.0;
  static const radiusSheet = 28.0;
  static const radiusPill = 9999.0;

  // Spacing.
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Minimum interactive target.
  static const minTarget = 48.0;

  /// Nominal SVG display size.
  static const iconSize = 22.0;

  // Motion.
  static const controlMotion = Duration(milliseconds: 160);
  static const screenMotion = Duration(milliseconds: 220);
}

/// A tested accent pair for one appearance.
@immutable
class AccentPair {
  const AccentPair(this.accent, this.onAccent);
  final Color accent;
  final Color onAccent;
}

/// Tested accent presets (contrast-checked in test/app/theme_test.dart).
enum AccentPreset {
  blue('Blue', AccentPair(Tokens.tertiary, Tokens.onAccent), AccentPair(Tokens.darkAccent, Tokens.darkOnAccent)),
  teal('Teal', AccentPair(Color(0xFF00756A), Color(0xFFFFFFFF)), AccentPair(Color(0xFF4FD1C5), Color(0xFF04201D))),
  indigo('Indigo', AccentPair(Color(0xFF4F46E5), Color(0xFFFFFFFF)), AccentPair(Color(0xFFA5B4FC), Color(0xFF10123A))),
  graphite('Graphite', AccentPair(Color(0xFF48484A), Color(0xFFFFFFFF)), AccentPair(Color(0xFFD1D1D6), Color(0xFF1C1C1E)));

  const AccentPreset(this.label, this.light, this.dark);

  final String label;
  final AccentPair light;
  final AccentPair dark;

  static AccentPreset fromKey(String? key) =>
      AccentPreset.values.firstWhere((p) => p.name == key, orElse: () => AccentPreset.blue);
}

/// Optional category accents. Always paired with a visible name; never text
/// color (contrast-checked as non-text marks).
enum CategoryColor {
  blue('Blue', Color(0xFF0A6ED1), Color(0xFF5EADFF)),
  green('Green', Color(0xFF248A3D), Color(0xFF30D158)),
  orange('Orange', Color(0xFFC94F00), Color(0xFFFF9F0A)),
  red('Red', Color(0xFFD70015), Color(0xFFFF6961)),
  purple('Purple', Color(0xFF8944AB), Color(0xFFCF8CF2)),
  gray('Gray', Color(0xFF6C6C70), Color(0xFFAEAEB2));

  const CategoryColor(this.label, this.light, this.dark);

  final String label;
  final Color light;
  final Color dark;

  Color resolve(Brightness brightness) => brightness == Brightness.dark ? dark : light;

  static CategoryColor? fromKey(String? key) {
    for (final c in CategoryColor.values) {
      if (c.name == key) return c;
    }
    return null;
  }
}

enum Density { comfortable, compact }
