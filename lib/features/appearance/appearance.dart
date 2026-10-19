import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/schediel_theme.dart';
import '../../app/theme/theme_catalog.dart';
import '../../app/theme/tokens.dart';
import '../../data/local/database.dart';

@immutable
class AppearanceSettings {
  const AppearanceSettings({
    this.themeMode = ThemeMode.system,
    this.theme = ThemeId.lilac,
    this.customHue = 250,
    this.density = Density.comfortable,
    this.showCategoryColors = true,
  });

  final ThemeMode themeMode;
  final ThemeId theme;

  /// Hue (0–359) used by [ThemeId.custom].
  final int customHue;
  final Density density;
  final bool showCategoryColors;

  /// The resolved theme definition.
  SchedielTheme get schedielTheme => themeFor(theme, customHue: customHue);

  AppearanceSettings copyWith({
    ThemeMode? themeMode,
    ThemeId? theme,
    int? customHue,
    Density? density,
    bool? showCategoryColors,
  }) =>
      AppearanceSettings(
        themeMode: themeMode ?? this.themeMode,
        theme: theme ?? this.theme,
        customHue: (customHue ?? this.customHue) % 360,
        density: density ?? this.density,
        showCategoryColors: showCategoryColors ?? this.showCategoryColors,
      );

  @override
  bool operator ==(Object other) =>
      other is AppearanceSettings &&
      other.themeMode == themeMode &&
      other.theme == theme &&
      other.customHue == customHue &&
      other.density == density &&
      other.showCategoryColors == showCategoryColors;

  @override
  int get hashCode => Object.hash(themeMode, theme, customHue, density, showCategoryColors);
}

class AppearanceRepository {
  AppearanceRepository(this._db, {required this._clock});

  final AppDatabase _db;
  final DateTime Function() _clock;

  Future<AppearanceSettings> load() async {
    final row = await (_db.select(_db.appearancePreferences)..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) return const AppearanceSettings();
    return AppearanceSettings(
      themeMode: ThemeMode.values.firstWhere((m) => m.name == row.themeMode, orElse: () => ThemeMode.system),
      theme: ThemeId.fromKey(row.themeKey),
      customHue: row.customHue % 360,
      density: Density.values.firstWhere((d) => d.name == row.density, orElse: () => Density.comfortable),
      showCategoryColors: row.showCategoryColors,
    );
  }

  Future<void> save(AppearanceSettings s) => _db.into(_db.appearancePreferences).insertOnConflictUpdate(
        AppearancePreferencesCompanion.insert(
          id: const Value(1),
          themeMode: Value(s.themeMode.name),
          themeKey: Value(s.theme.name),
          customHue: Value(s.customHue),
          density: Value(s.density.name),
          showCategoryColors: Value(s.showCategoryColors),
          updatedAt: _clock().toUtc(),
        ),
      );
}

/// Loaded before the first frame (main.dart) to avoid a theme flash.
final initialAppearanceProvider = Provider<AppearanceSettings>((ref) => const AppearanceSettings());

final appearanceRepositoryProvider = Provider<AppearanceRepository>(
  (ref) => throw UnimplementedError('Provided in main.dart'),
);

final appearanceProvider = NotifierProvider<AppearanceNotifier, AppearanceSettings>(AppearanceNotifier.new);

class AppearanceNotifier extends Notifier<AppearanceSettings> {
  @override
  AppearanceSettings build() => ref.watch(initialAppearanceProvider);

  Future<void> update(AppearanceSettings Function(AppearanceSettings) change) async {
    final next = change(state);
    if (next == state) return;
    state = next;
    await ref.read(appearanceRepositoryProvider).save(next);
  }
}
