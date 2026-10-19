import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'schediel_theme.dart';
import 'tokens.dart';

/// Theme-driven colors, shapes and type the screens need beyond ColorScheme.
@immutable
class ScheduleColors extends ThemeExtension<ScheduleColors> {
  const ScheduleColors({
    required this.palette,
    required this.style,
    required this.radius,
    required this.displayFont,
    required this.displayWeight,
    required this.inputBoundary,
    required this.accentText,
    required this.nextHolder,
    required this.density,
    required this.showCategoryColors,
  });

  final ThemePalette palette;
  final StyleFamily style;

  /// Card corner radius (0 for pixel).
  final double radius;
  final String? displayFont;
  final FontWeight displayWeight;
  final Color inputBoundary;

  /// The accent when it is readable as text on surfaces, otherwise ink
  /// (Pop and Sketch use a light highlighter accent).
  final Color accentText;

  /// Accent wash marking the next schedule.
  final Color nextHolder;
  final Density density;
  final bool showCategoryColors;

  Color get canvas => palette.canvas;
  Color get surface => palette.surface;
  Color get ink => palette.ink;
  Color get secondaryInk => palette.secondaryInk;
  Color get divider => palette.divider;

  /// Card fill for a category color key; neutral when colors are off or the
  /// key is unknown.
  Color categoryFill(String? colorKey) => showCategoryColors ? palette.fillFor(colorKey) : palette.neutralFill;

  /// Styles with drawn outlines (pop, pixel, sketch).
  bool get outlined => style != StyleFamily.soft;

  @override
  ScheduleColors copyWith({Density? density, bool? showCategoryColors}) => ScheduleColors(
        palette: palette,
        style: style,
        radius: radius,
        displayFont: displayFont,
        displayWeight: displayWeight,
        inputBoundary: inputBoundary,
        accentText: accentText,
        nextHolder: nextHolder,
        density: density ?? this.density,
        showCategoryColors: showCategoryColors ?? this.showCategoryColors,
      );

  @override
  ScheduleColors lerp(ThemeExtension<ScheduleColors>? other, double t) {
    if (other is! ScheduleColors) return this;
    // Palettes, shapes and fonts switch at the midpoint; ThemeData itself
    // cross-fades the scheme colors.
    return t < 0.5 ? this : other;
  }
}

extension ScheduleThemeContext on BuildContext {
  ScheduleColors get scheduleColors => Theme.of(this).extension<ScheduleColors>()!;

  /// Preferred short name for new code.
  ScheduleColors get schediel => scheduleColors;
}

/// The app's theme mode: Midnight has no light variant.
ThemeMode effectiveThemeMode(SchedielTheme theme, ThemeMode mode) => theme.darkOnly ? ThemeMode.dark : mode;

/// Text styles from the DESIGN.md typography tokens. Body text always uses the
/// platform font; only display styles take the theme's bundled display font.
TextTheme _textTheme(SchedielTheme theme, Color ink, Color secondaryInk) {
  final font = theme.displayFont;
  // Caveat runs small and Silkscreen wide; scale so headings keep their size.
  final scale = switch (font) { 'Caveat' => 1.25, 'Silkscreen' => 0.82, _ => 1.0 };
  final weight = switch (font) { null => theme.displayWeight, 'Caveat' => FontWeight.w700, _ => FontWeight.w400 };
  TextStyle display(double size, double height, double tracking) => TextStyle(
        fontFamily: font,
        fontSize: size * scale,
        fontWeight: weight,
        height: height,
        letterSpacing: font == null ? tracking : 0,
        color: ink,
      );
  return TextTheme(
    headlineLarge: display(34, 1.1, -0.8),
    headlineMedium: display(30, 1.15, -0.6),
    titleLarge: display(22, 1.25, -0.22),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4, color: ink),
    bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.45, color: ink),
    bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.4, color: ink),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: secondaryInk),
    labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4, color: ink),
    labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4, color: ink),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3, color: secondaryInk),
  );
}

/// The schedule time style: 15/500 with tabular figures.
TextStyle timeStyle(BuildContext context) => TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.35,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: context.scheduleColors.ink,
    );

/// Whichever of [a] or [b] reads better on [background].
Color _readableOn(Color background, Color a, Color b) =>
    contrastRatio(a, background) >= contrastRatio(b, background) ? a : b;

ThemeData buildTheme({
  required SchedielTheme theme,
  required Brightness brightness,
  required Density density,
  required bool showCategoryColors,
}) {
  final p = theme.palette(brightness);
  final dark = p.brightness == Brightness.dark;
  final canvas = p.canvas;
  final surface = p.surface;
  final ink = p.ink;
  final secondaryInk = p.secondaryInk;
  final divider = p.divider;
  // Non-text boundaries need 3:1; accent-colored text needs 4.5:1.
  final softBoundary = Color.lerp(secondaryInk, surface, 0.3)!;
  final boundary = contrastRatio(softBoundary, surface) >= 3 ? softBoundary : secondaryInk;
  final accentText = contrastRatio(p.accent, surface) >= 4.5 && contrastRatio(p.accent, canvas) >= 4.5 ? p.accent : ink;
  final accentMark = contrastRatio(p.accent, surface) >= 3 ? p.accent : ink;
  final error = dark ? Tokens.darkError : Tokens.error;
  final pixel = theme.style == StyleFamily.pixel;
  final controlRadius = pixel ? 0.0 : Tokens.radiusControl;
  final outlined = theme.style != StyleFamily.soft;
  final outline = BorderSide(color: p.outline, width: 2);
  final side = outlined ? outline : BorderSide(color: boundary);

  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    error: error,
    onError: dark ? const Color(0xFF410002) : Colors.white,
    surface: surface,
    onSurface: ink,
    onSurfaceVariant: secondaryInk,
    outline: boundary,
    outlineVariant: divider,
    surfaceContainerLowest: canvas,
    surfaceContainerLow: canvas,
    surfaceContainer: surface,
    surfaceContainerHigh: surface,
    surfaceContainerHighest: surface,
  );
  final text = _textTheme(theme, ink, secondaryInk);
  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius));
  final selectedWash = outlined ? p.accent : p.accent.withValues(alpha: dark ? 0.26 : 0.14);
  final onSelectedWash = outlined ? p.onAccent : ink;

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: canvas,
    canvasColor: canvas,
    textTheme: text,
    dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
    visualDensity: density == Density.compact ? VisualDensity.compact : VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleMedium,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.navBackground,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.navSelected,
      elevation: 0,
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? p.navOnSelected : p.navInk),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: p.navInk,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: p.onAccent,
      elevation: outlined ? 0 : 2,
      shape: pixel ? RoundedRectangleBorder(side: outline) : CircleBorder(side: outlined ? outline : BorderSide.none),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(Tokens.minTarget, Tokens.minTarget),
        shape: controlShape.copyWith(side: outlined ? outline : BorderSide.none),
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: Tokens.md, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(Tokens.minTarget, Tokens.minTarget),
        shape: controlShape,
        side: side,
        foregroundColor: ink,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(Tokens.minTarget, Tokens.minTarget),
        shape: controlShape,
        foregroundColor: accentText,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(Tokens.minTarget, Tokens.minTarget),
        foregroundColor: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: Tokens.md, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(controlRadius), borderSide: side),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(controlRadius), borderSide: side),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: BorderSide(color: accentMark, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: BorderSide(color: error),
      ),
      labelStyle: TextStyle(color: secondaryInk),
      hintStyle: TextStyle(color: secondaryInk),
    ),
    chipTheme: ChipThemeData(
      shape: pixel ? const RoundedRectangleBorder() : const StadiumBorder(),
      side: side,
      backgroundColor: surface,
      selectedColor: selectedWash,
      labelStyle: TextStyle(fontSize: 15, color: ink),
      secondaryLabelStyle: TextStyle(fontSize: 15, color: onSelectedWash),
      showCheckmark: true,
      checkmarkColor: onSelectedWash,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: divider,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(pixel ? 0 : Tokens.radiusSheet)),
        side: outlined ? outline : BorderSide.none,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radius),
        side: outlined ? outline : BorderSide.none,
      ),
      titleTextStyle: text.titleMedium,
      contentTextStyle: text.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.navBackground,
      contentTextStyle: TextStyle(fontSize: 15, color: _readableOn(p.navBackground, p.navInk, surface)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.transparent : boundary,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(Tokens.minTarget, 40),
        side: side,
        shape: controlShape,
        // Unselected labels use ink: some accents (Pop, Sketch yellow) are
        // fills, not text colors.
        foregroundColor: ink,
        backgroundColor: Colors.transparent,
        selectedBackgroundColor: selectedWash,
        selectedForegroundColor: onSelectedWash,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: secondaryInk,
      textColor: ink,
      minVerticalPadding: density == Density.compact ? 6 : 10,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _CalmPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    extensions: [
      ScheduleColors(
        palette: p,
        style: theme.style,
        radius: theme.radius,
        displayFont: theme.displayFont,
        displayWeight: theme.displayWeight,
        inputBoundary: boundary,
        accentText: accentText,
        nextHolder: outlined ? p.accent : p.accent.withValues(alpha: dark ? 0.20 : 0.10),
        density: density,
        showCategoryColors: showCategoryColors,
      ),
    ],
  );
}

/// Android page transition: a short fade with a slight rise (screen motion,
/// 220 ms). Reduced motion removes the movement.
class _CalmPageTransitionsBuilder extends PageTransitionsBuilder {
  const _CalmPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Tokens.screenMotion;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

/// WCAG relative luminance contrast ratio between two opaque colors.
double contrastRatio(Color a, Color b) {
  double channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) => 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
