import 'package:flutter/foundation.dart';

import '../../categories/domain/category.dart';

enum WidgetLayout { compact, expanded }

/// clear: no app-painted root, no blur, subtle holders; softTint: stronger
/// translucent holders; solid: opaque high-contrast holders.
enum WidgetSurface { clear, softTint, solid }

/// Text for dark wallpaper (light) or light wallpaper (dark).
enum WidgetTextTone { light, dark }

/// Per-widget settings (spec 4.7, 12.3). Each native widget instance has its
/// own; key 'default' covers widgets without an entry.
@immutable
class WidgetConfig {
  const WidgetConfig({
    required this.widgetKey,
    required this.filter,
    required this.layout,
    required this.surface,
    required this.textTone,
    required this.nextEmphasis,
    required this.showLocation,
    required this.showProfessor,
    required this.showSubtitle,
    required this.matchApp,
    required this.revision,
  });

  static const defaultKey = 'default';

  static const defaults = WidgetConfig(
    widgetKey: defaultKey,
    filter: CategoryFilter.all(),
    layout: WidgetLayout.expanded,
    surface: WidgetSurface.clear,
    textTone: WidgetTextTone.light,
    nextEmphasis: true,
    showLocation: true,
    showProfessor: true,
    showSubtitle: true,
    matchApp: false,
    revision: 0,
  );

  final String widgetKey;
  final CategoryFilter filter;
  final WidgetLayout layout;
  final WidgetSurface surface;
  final WidgetTextTone textTone;
  final bool nextEmphasis;
  final bool showLocation;
  final bool showProfessor;
  final bool showSubtitle;

  /// Text tone follows the app's light/dark appearance.
  final bool matchApp;
  final int revision;

  WidgetConfig copyWith({
    String? widgetKey,
    CategoryFilter? filter,
    WidgetLayout? layout,
    WidgetSurface? surface,
    WidgetTextTone? textTone,
    bool? nextEmphasis,
    bool? showLocation,
    bool? showProfessor,
    bool? showSubtitle,
    bool? matchApp,
    int? revision,
  }) =>
      WidgetConfig(
        widgetKey: widgetKey ?? this.widgetKey,
        filter: filter ?? this.filter,
        layout: layout ?? this.layout,
        surface: surface ?? this.surface,
        textTone: textTone ?? this.textTone,
        nextEmphasis: nextEmphasis ?? this.nextEmphasis,
        showLocation: showLocation ?? this.showLocation,
        showProfessor: showProfessor ?? this.showProfessor,
        showSubtitle: showSubtitle ?? this.showSubtitle,
        matchApp: matchApp ?? this.matchApp,
        revision: revision ?? this.revision,
      );

  @override
  bool operator ==(Object other) =>
      other is WidgetConfig &&
      other.widgetKey == widgetKey &&
      other.filter == filter &&
      other.layout == layout &&
      other.surface == surface &&
      other.textTone == textTone &&
      other.nextEmphasis == nextEmphasis &&
      other.showLocation == showLocation &&
      other.showProfessor == showProfessor &&
      other.showSubtitle == showSubtitle &&
      other.matchApp == matchApp &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(widgetKey, filter, layout, surface, textTone, nextEmphasis, showLocation,
      showProfessor, showSubtitle, matchApp, revision);
}
