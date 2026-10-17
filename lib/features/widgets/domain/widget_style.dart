import 'package:flutter/material.dart';

import '../domain/widget_config.dart';

/// Holder and text colors for the native widget, mirrored in
/// android/.../widget/WidgetStyle.kt and ios/ScheduleWidget. Starting values
/// for device readability tests (DESIGN.md implementation table).
@immutable
class WidgetStyle {
  const WidgetStyle({
    required this.nextHolder,
    required this.upcomingHolder,
    required this.nextOutline,
    required this.primaryText,
    required this.secondaryText,
  });

  final Color nextHolder;
  final Color upcomingHolder;
  final Color nextOutline;
  final Color primaryText;
  final Color secondaryText;

  static WidgetStyle of(WidgetSurface surface, WidgetTextTone tone) {
    final light = tone == WidgetTextTone.light;
    final (next, upcoming) = switch ((surface, light)) {
      (WidgetSurface.clear, true) => (const Color(0x2EFFFFFF), const Color(0x0FFFFFFF)),
      (WidgetSurface.clear, false) => (const Color(0x99FFFFFF), const Color(0x52FFFFFF)),
      (WidgetSurface.softTint, true) => (const Color(0x8C3A3A3C), const Color(0x661C1C1E)),
      (WidgetSurface.softTint, false) => (const Color(0xD9FFFFFF), const Color(0xA6F2F2F7)),
      (WidgetSurface.solid, true) => (const Color(0xFF3A3A3C), const Color(0xFF1C1C1E)),
      (WidgetSurface.solid, false) => (const Color(0xFFFFFFFF), const Color(0xFFE5E5EA)),
    };
    return WidgetStyle(
      nextHolder: next,
      upcomingHolder: upcoming,
      nextOutline: light ? const Color(0x59FFFFFF) : const Color(0x1F000000),
      primaryText: light ? const Color(0xFFFFFFFF) : const Color(0xFF1D1D1F),
      secondaryText: light ? const Color(0xC7FFFFFF) : const Color(0xFF3A3A3C),
    );
  }

  /// Holder corner radius in logical units.
  static const holderRadius = 16.0;
}
