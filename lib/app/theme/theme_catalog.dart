import 'dart:math' as math;

import 'package:flutter/material.dart' show Brightness, Color, FontWeight;
import 'package:material_color_utilities/material_color_utilities.dart';

import 'schediel_theme.dart';

/// The eight themes (design spec §5.2). Light values come from the approved
/// mockup; dark variants and the fills it did not show keep each theme's
/// character and are checked by test/app/theme_catalog_test.dart.
SchedielTheme themeFor(ThemeId id, {int customHue = 250}) => switch (id) {
      ThemeId.lilac => _lilac,
      ThemeId.clay => _clay,
      ThemeId.pop => _pop,
      ThemeId.mint => _mint,
      ThemeId.midnight => _midnight,
      ThemeId.pixel => _pixel,
      ThemeId.sketch => _sketch,
      ThemeId.custom => _custom(customHue % 360),
    };

Map<CategoryColorKey, Color> _fills(int blue, int green, int orange, int red, int purple, int gray) => {
      CategoryColorKey.blue: Color(blue),
      CategoryColorKey.green: Color(green),
      CategoryColorKey.orange: Color(orange),
      CategoryColorKey.red: Color(red),
      CategoryColorKey.purple: Color(purple),
      CategoryColorKey.gray: Color(gray),
    };

ThemePalette _p({
  required Brightness b,
  required int canvas,
  required int surface,
  required int ink,
  required int secondary,
  required int divider,
  required int accent,
  required int onAccent,
  required int navBg,
  required int navInk,
  required int navSel,
  required int navOnSel,
  required int now,
  required int onNow,
  required int cardInk,
  required int outline,
  required Map<CategoryColorKey, Color> fills,
}) =>
    ThemePalette(
      brightness: b,
      canvas: Color(canvas),
      surface: Color(surface),
      ink: Color(ink),
      secondaryInk: Color(secondary),
      divider: Color(divider),
      accent: Color(accent),
      onAccent: Color(onAccent),
      navBackground: Color(navBg),
      navInk: Color(navInk),
      navSelected: Color(navSel),
      navOnSelected: Color(navOnSel),
      nowBadge: Color(now),
      onNowBadge: Color(onNow),
      cardInk: Color(cardInk),
      outline: Color(outline),
      neutralFill: fills[CategoryColorKey.gray]!,
      categoryFills: fills,
    );

final _lilac = SchedielTheme(
  id: ThemeId.lilac,
  style: StyleFamily.soft,
  radius: 22,
  light: _p(
    b: Brightness.light, canvas: 0xFFF4F2FC, surface: 0xFFFFFFFF, ink: 0xFF1E1B2E, secondary: 0xFF5E5A73,
    divider: 0xFFE3E0EE, accent: 0xFF6A5AE0, onAccent: 0xFFFFFFFF, navBg: 0xFF1E1B2E, navInk: 0xFFB9B4D6,
    navSel: 0xFFFFFFFF, navOnSel: 0xFF1E1B2E, now: 0xFF1E1B2E, onNow: 0xFFFFFFFF, cardInk: 0xFF1E1B2E, outline: 0xFF1E1B2E,
    fills: _fills(0xFFDDEBFF, 0xFFDDF3E6, 0xFFFFF1C7, 0xFFFFE1EC, 0xFFE7E1FF, 0xFFECEBF2),
  ),
  dark: _p(
    b: Brightness.dark, canvas: 0xFF15131F, surface: 0xFF211E2E, ink: 0xFFF2F0FA, secondary: 0xFFB5B0CC,
    divider: 0xFF34304A, accent: 0xFFA99CFF, onAccent: 0xFF15131F, navBg: 0xFF2A2640, navInk: 0xFFB5B0CC,
    navSel: 0xFFA99CFF, navOnSel: 0xFF15131F, now: 0xFFA99CFF, onNow: 0xFF15131F, cardInk: 0xFFF2F0FA, outline: 0xFFF2F0FA,
    fills: _fills(0xFF22314A, 0xFF213A2E, 0xFF3D3420, 0xFF432634, 0xFF30294D, 0xFF2B2938),
  ),
);

final _clay = SchedielTheme(
  id: ThemeId.clay,
  style: StyleFamily.soft,
  radius: 26,
  light: _p(
    b: Brightness.light, canvas: 0xFFF3ECE4, surface: 0xFFFBF7F2, ink: 0xFF2A1F1A, secondary: 0xFF66564C,
    divider: 0xFFE3D8CC, accent: 0xFFA9502C, onAccent: 0xFFFFFFFF, navBg: 0xFFFBF7F2, navInk: 0xFF66564C,
    navSel: 0xFF2A1F1A, navOnSel: 0xFFF3ECE4, now: 0xFF2A1F1A, onNow: 0xFFFFFFFF, cardInk: 0xFF2A1F1A, outline: 0xFF2A1F1A,
    fills: _fills(0xFFDCE3EA, 0xFFD9E2CC, 0xFFEBDDBF, 0xFFF0D3C2, 0xFFE6CFD0, 0xFFE7E0D8),
  ),
  dark: _p(
    b: Brightness.dark, canvas: 0xFF1C1714, surface: 0xFF27201C, ink: 0xFFF3ECE4, secondary: 0xFFC2B3A8,
    divider: 0xFF3D332D, accent: 0xFFE39A73, onAccent: 0xFF1C1714, navBg: 0xFF2F2723, navInk: 0xFFC2B3A8,
    navSel: 0xFFE39A73, navOnSel: 0xFF1C1714, now: 0xFFE39A73, onNow: 0xFF1C1714, cardInk: 0xFFF3ECE4, outline: 0xFFF3ECE4,
    fills: _fills(0xFF2A323B, 0xFF2E3627, 0xFF3E3424, 0xFF43302A, 0xFF3D2C30, 0xFF332B27),
  ),
);

final _pop = SchedielTheme(
  id: ThemeId.pop,
  style: StyleFamily.pop,
  radius: 18,
  displayWeight: FontWeight.w900,
  light: _p(
    b: Brightness.light, canvas: 0xFFFFF4D6, surface: 0xFFFFFFFF, ink: 0xFF111111, secondary: 0xFF3A3A3A,
    divider: 0xFF111111, accent: 0xFFFFD400, onAccent: 0xFF111111, navBg: 0xFF111111, navInk: 0xFFFFF4D6,
    navSel: 0xFFFF4B3E, navOnSel: 0xFF111111, now: 0xFF111111, onNow: 0xFFFFFFFF, cardInk: 0xFF111111, outline: 0xFF111111,
    fills: _fills(0xFF6FD3FF, 0xFFB6F36A, 0xFFFFB547, 0xFFFF9EC4, 0xFFC9B6FF, 0xFFE5E5E5),
  ),
  dark: _p(
    b: Brightness.dark, canvas: 0xFF141414, surface: 0xFF1F1F1F, ink: 0xFFFFF4D6, secondary: 0xFFD6CFB8,
    divider: 0xFFFFF4D6, accent: 0xFFFFD400, onAccent: 0xFF111111, navBg: 0xFFFFF4D6, navInk: 0xFF111111,
    navSel: 0xFFFF4B3E, navOnSel: 0xFF111111, now: 0xFFFFD400, onNow: 0xFF111111, cardInk: 0xFF111111, outline: 0xFFFFF4D6,
    fills: _fills(0xFF6FD3FF, 0xFFB6F36A, 0xFFFFB547, 0xFFFF9EC4, 0xFFC9B6FF, 0xFFE5E5E5),
  ),
);

final _mint = SchedielTheme(
  id: ThemeId.mint,
  style: StyleFamily.soft,
  radius: 20,
  light: _p(
    b: Brightness.light, canvas: 0xFFEDF5F0, surface: 0xFFFFFFFF, ink: 0xFF14231B, secondary: 0xFF485C50,
    divider: 0xFFD5E3DA, accent: 0xFF17805A, onAccent: 0xFFFFFFFF, navBg: 0xFFFFFFFF, navInk: 0xFF485C50,
    navSel: 0xFF17805A, navOnSel: 0xFFFFFFFF, now: 0xFF14231B, onNow: 0xFFFFFFFF, cardInk: 0xFF14231B, outline: 0xFF14231B,
    fills: _fills(0xFFD8E8F6, 0xFFD3EFDF, 0xFFF6E4D1, 0xFFF6D9D9, 0xFFE9E1F6, 0xFFE6ECE8),
  ),
  dark: _p(
    b: Brightness.dark, canvas: 0xFF0F1813, surface: 0xFF18241D, ink: 0xFFE8F3EC, secondary: 0xFFA9BDB1,
    divider: 0xFF2A3A31, accent: 0xFF5FD3A0, onAccent: 0xFF0F1813, navBg: 0xFF1E2C24, navInk: 0xFFA9BDB1,
    navSel: 0xFF5FD3A0, navOnSel: 0xFF0F1813, now: 0xFF5FD3A0, onNow: 0xFF0F1813, cardInk: 0xFFE8F3EC, outline: 0xFFE8F3EC,
    fills: _fills(0xFF1F3142, 0xFF1E3A2C, 0xFF3B3122, 0xFF3D2626, 0xFF2F2840, 0xFF26302A),
  ),
);

final _midnightDark = _p(
  b: Brightness.dark, canvas: 0xFF0F1117, surface: 0xFF1A1E28, ink: 0xFFEEF0F6, secondary: 0xFF9AA1B3,
  divider: 0xFF2A2F3B, accent: 0xFF9DB8FF, onAccent: 0xFF0F1117, navBg: 0xFF1A1E28, navInk: 0xFF9AA1B3,
  navSel: 0xFF9DB8FF, navOnSel: 0xFF0F1117, now: 0xFF9DB8FF, onNow: 0xFF0F1117, cardInk: 0xFFEEF0F6, outline: 0xFFEEF0F6,
  fills: _fills(0xFF23304A, 0xFF24382F, 0xFF3A3226, 0xFF3A2632, 0xFF2E2742, 0xFF262A33),
);

final _midnight = SchedielTheme(
  id: ThemeId.midnight,
  style: StyleFamily.soft,
  radius: 22,
  darkOnly: true,
  light: _midnightDark,
  dark: _midnightDark,
);

final _pixel = SchedielTheme(
  id: ThemeId.pixel,
  style: StyleFamily.pixel,
  radius: 0,
  displayFont: 'Silkscreen',
  light: _p(
    b: Brightness.light, canvas: 0xFFEDEBDD, surface: 0xFFFFFFFF, ink: 0xFF1B1B2F, secondary: 0xFF4A4A63,
    divider: 0xFF1B1B2F, accent: 0xFF3D5AFE, onAccent: 0xFFFFFFFF, navBg: 0xFF1B1B2F, navInk: 0xFFEDEBDD,
    navSel: 0xFFFFD166, navOnSel: 0xFF1B1B2F, now: 0xFF1B1B2F, onNow: 0xFFFFFFFF, cardInk: 0xFF1B1B2F, outline: 0xFF1B1B2F,
    fills: _fills(0xFFA0C4FF, 0xFF9BE7C4, 0xFFFFD166, 0xFFFF8FA3, 0xFFC3B1FF, 0xFFD8D6CB),
  ),
  dark: _p(
    b: Brightness.dark, canvas: 0xFF101226, surface: 0xFF1A1D38, ink: 0xFFEDEBDD, secondary: 0xFFB9B7CC,
    divider: 0xFFEDEBDD, accent: 0xFF8FA2FF, onAccent: 0xFF101226, navBg: 0xFFEDEBDD, navInk: 0xFF101226,
    navSel: 0xFFFFD166, navOnSel: 0xFF101226, now: 0xFFFFD166, onNow: 0xFF101226, cardInk: 0xFF1B1B2F, outline: 0xFFEDEBDD,
    fills: _fills(0xFFA0C4FF, 0xFF9BE7C4, 0xFFFFD166, 0xFFFF8FA3, 0xFFC3B1FF, 0xFFD8D6CB),
  ),
);

final _sketch = SchedielTheme(
  id: ThemeId.sketch,
  style: StyleFamily.sketch,
  radius: 18,
  displayFont: 'Caveat',
  light: _p(
    b: Brightness.light, canvas: 0xFFFBFAF5, surface: 0xFFFFFFFF, ink: 0xFF2B2B2B, secondary: 0xFF5C5C5C,
    divider: 0xFFE3E8F2, accent: 0xFFFFE066, onAccent: 0xFF2B2B2B, navBg: 0xFFFFFFFF, navInk: 0xFF2B2B2B,
    navSel: 0xFF2B2B2B, navOnSel: 0xFFFBFAF5, now: 0xFF2B2B2B, onNow: 0xFFFBFAF5, cardInk: 0xFF2B2B2B, outline: 0xFF2B2B2B,
    fills: _fills(0xFFB3E5FC, 0xFFC8E6C9, 0xFFFFE0B2, 0xFFF8BBD0, 0xFFE1BEE7, 0xFFE0E0E0),
  ),
  dark: _p(
    b: Brightness.dark, canvas: 0xFF1F2A27, surface: 0xFF26332F, ink: 0xFFF1F1EA, secondary: 0xFFC2C8C3,
    divider: 0xFF33423D, accent: 0xFFFFE066, onAccent: 0xFF2B2B2B, navBg: 0xFF26332F, navInk: 0xFFF1F1EA,
    navSel: 0xFFF1F1EA, navOnSel: 0xFF1F2A27, now: 0xFFFFE066, onNow: 0xFF2B2B2B, cardInk: 0xFF2B2B2B, outline: 0xFFF1F1EA,
    fills: _fills(0xFFB3E5FC, 0xFFC8E6C9, 0xFFFFE0B2, 0xFFF8BBD0, 0xFFE1BEE7, 0xFFE0E0E0),
  ),
);

// ---------------------------------------------------------------- Custom ---

Color _hct(double hue, double chroma, double tone) => Color(Hct.from(hue % 360, chroma, tone).toInt());

double _luminance(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Moves [tone] away from [against] in steps until text contrast passes.
Color _readable(double hue, double chroma, double tone, Color against, {double target = 4.6}) {
  final darker = _luminance(against) > 0.18;
  var t = tone;
  var c = _hct(hue, chroma, t);
  while (_contrast(c, against) < target && t > 0 && t < 100) {
    t += darker ? -2 : 2;
    c = _hct(hue, chroma, t.clamp(0, 100));
  }
  return c;
}

/// Shortest signed angle from [from] to [to], degrees.
double _towards(double from, double to, double maxShift) {
  var d = (to - from) % 360;
  if (d > 180) d -= 360;
  return from + d.clamp(-maxShift, maxShift);
}

/// Lilac's fills anchor each category's hue family; Custom nudges them
/// at most 8° toward the chosen hue (spec §5.4), so orange stays orange.
Map<CategoryColorKey, Color> _customFills(double hue, {required bool dark, required Color ink}) {
  final base = _lilac.light.categoryFills;
  return {
    for (final key in CategoryColorKey.values)
      key: () {
        if (key == CategoryColorKey.gray) {
          return _readable(hue, 6, dark ? 22 : 92, ink);
        }
        final h = Hct.fromInt(base[key]!.toARGB32());
        final shifted = _towards(h.hue, hue, 8);
        return _readable(shifted, dark ? 20 : math.max(h.chroma, 14), dark ? 24 : h.tone, ink);
      }(),
  };
}

SchedielTheme _custom(int hueInt) {
  final hue = hueInt.toDouble();
  // Light
  final lInk = _hct(hue, 10, 12);
  final lCanvas = _hct(hue, 6, 97.5);
  final lAccent = _readable(hue, 48, 40, const Color(0xFFFFFFFF));
  final lSecondary = _readable(hue, 12, 38, lCanvas);
  final light = ThemePalette(
    brightness: Brightness.light,
    canvas: lCanvas,
    surface: const Color(0xFFFFFFFF),
    ink: lInk,
    secondaryInk: lSecondary,
    divider: _hct(hue, 8, 88),
    accent: lAccent,
    onAccent: const Color(0xFFFFFFFF),
    navBackground: lInk,
    navInk: _readable(hue, 10, 80, lInk),
    navSelected: const Color(0xFFFFFFFF),
    navOnSelected: lInk,
    nowBadge: lInk,
    onNowBadge: const Color(0xFFFFFFFF),
    cardInk: lInk,
    outline: lInk,
    neutralFill: _readable(hue, 6, 92, lInk),
    categoryFills: _customFills(hue, dark: false, ink: lInk),
  );
  // Dark
  final dCanvas = _hct(hue, 8, 7);
  final dInk = _hct(hue, 6, 95);
  final dAccent = _readable(hue, 48, 80, dCanvas);
  final dark = ThemePalette(
    brightness: Brightness.dark,
    canvas: dCanvas,
    surface: _hct(hue, 10, 12),
    ink: dInk,
    secondaryInk: _readable(hue, 10, 75, _hct(hue, 10, 12)),
    divider: _hct(hue, 10, 22),
    accent: dAccent,
    onAccent: dCanvas,
    navBackground: _hct(hue, 10, 16),
    navInk: _readable(hue, 10, 75, _hct(hue, 10, 16)),
    navSelected: dAccent,
    navOnSelected: dCanvas,
    nowBadge: dAccent,
    onNowBadge: dCanvas,
    cardInk: dInk,
    outline: dInk,
    neutralFill: _readable(hue, 6, 22, dInk),
    categoryFills: _customFills(hue, dark: true, ink: dInk),
  );
  return SchedielTheme(id: ThemeId.custom, style: StyleFamily.soft, radius: 22, light: light, dark: dark, customHue: hueInt);
}
