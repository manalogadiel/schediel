import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Extra semantic colors the timeline needs beyond ColorScheme.
@immutable
class ScheduleColors extends ThemeExtension<ScheduleColors> {
  const ScheduleColors({
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.secondaryInk,
    required this.divider,
    required this.inputBoundary,
    required this.nextHolder,
    required this.density,
    required this.showCategoryColors,
  });

  final Color canvas;
  final Color surface;
  final Color ink;
  final Color secondaryInk;
  final Color divider;
  final Color inputBoundary;

  /// Subtle accent wash marking the next schedule.
  final Color nextHolder;
  final Density density;
  final bool showCategoryColors;

  @override
  ScheduleColors copyWith({Density? density, bool? showCategoryColors}) => ScheduleColors(
        canvas: canvas,
        surface: surface,
        ink: ink,
        secondaryInk: secondaryInk,
        divider: divider,
        inputBoundary: inputBoundary,
        nextHolder: nextHolder,
        density: density ?? this.density,
        showCategoryColors: showCategoryColors ?? this.showCategoryColors,
      );

  @override
  ScheduleColors lerp(ThemeExtension<ScheduleColors>? other, double t) {
    if (other is! ScheduleColors) return this;
    return ScheduleColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      secondaryInk: Color.lerp(secondaryInk, other.secondaryInk, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputBoundary: Color.lerp(inputBoundary, other.inputBoundary, t)!,
      nextHolder: Color.lerp(nextHolder, other.nextHolder, t)!,
      density: t < 0.5 ? density : other.density,
      showCategoryColors: t < 0.5 ? showCategoryColors : other.showCategoryColors,
    );
  }
}

extension ScheduleThemeContext on BuildContext {
  ScheduleColors get scheduleColors => Theme.of(this).extension<ScheduleColors>()!;
}

/// Text styles from the DESIGN.md typography tokens. The platform system
/// font is inherited; no font files are bundled.
TextTheme _textTheme(Color ink, Color secondaryInk) {
  return TextTheme(
    headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -0.6, color: ink),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.25, letterSpacing: -0.22, color: ink),
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

ThemeData buildTheme({
  required Brightness brightness,
  required AccentPreset accent,
  required Density density,
  required bool showCategoryColors,
}) {
  final dark = brightness == Brightness.dark;
  final pair = dark ? accent.dark : accent.light;
  final canvas = dark ? Tokens.darkCanvas : Tokens.neutral;
  final surface = dark ? Tokens.darkSurface : Tokens.surface;
  final ink = dark ? Tokens.darkInk : Tokens.primary;
  final secondaryInk = dark ? Tokens.darkSecondary : Tokens.secondary;
  final divider = dark ? Tokens.darkDivider : Tokens.divider;
  final boundary = dark ? Tokens.darkInputBoundary : Tokens.inputBoundary;
  final error = dark ? Tokens.darkError : Tokens.error;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: pair.accent,
    onPrimary: pair.onAccent,
    secondary: pair.accent,
    onSecondary: pair.onAccent,
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
  final text = _textTheme(ink, secondaryInk);
  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusControl));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
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
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: pair.accent.withValues(alpha: dark ? 0.22 : 0.12),
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? ink : secondaryInk,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(Tokens.minTarget, Tokens.minTarget),
        shape: controlShape,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: Tokens.md, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(Tokens.minTarget, Tokens.minTarget),
        shape: controlShape,
        side: BorderSide(color: boundary),
        foregroundColor: ink,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(Tokens.minTarget, Tokens.minTarget),
        shape: controlShape,
        foregroundColor: pair.accent,
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        borderSide: BorderSide(color: boundary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        borderSide: BorderSide(color: boundary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        borderSide: BorderSide(color: pair.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        borderSide: BorderSide(color: error),
      ),
      labelStyle: TextStyle(color: secondaryInk),
      hintStyle: TextStyle(color: secondaryInk),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: boundary),
      backgroundColor: surface,
      selectedColor: pair.accent.withValues(alpha: dark ? 0.26 : 0.14),
      labelStyle: TextStyle(fontSize: 15, color: ink),
      showCheckmark: true,
      checkmarkColor: ink,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: divider,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radiusSheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusCard)),
      titleTextStyle: text.titleMedium,
      contentTextStyle: text.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusControl)),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.transparent : boundary,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(Tokens.minTarget, 40),
        side: BorderSide(color: boundary),
        selectedBackgroundColor: pair.accent.withValues(alpha: dark ? 0.26 : 0.14),
        selectedForegroundColor: ink,
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
        canvas: canvas,
        surface: surface,
        ink: ink,
        secondaryInk: secondaryInk,
        divider: divider,
        inputBoundary: boundary,
        nextHolder: pair.accent.withValues(alpha: dark ? 0.20 : 0.09),
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
