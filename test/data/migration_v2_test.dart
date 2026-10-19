import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/appearance/appearance.dart';
import 'package:schediel/features/widgets/data/widget_config_repository.dart';
import 'package:schediel/features/widgets/domain/widget_config.dart';

/// Opens an in-memory database that starts as a real v1 file.
AppDatabase v1Database({required String accent, required String mode}) {
  final schema = File('test/data/fixtures/v1_schema.sql').readAsStringSync();
  return AppDatabase(NativeDatabase.memory(setup: (raw) {
    // Only seed once: drift opens the executor a single time per test.
    if (raw.select('PRAGMA user_version').first.values.first != 0) return;
    for (final statement in schema.split(';\n').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
      raw.execute(statement.endsWith(';') ? statement : '$statement;');
    }
    raw.execute("INSERT INTO categories VALUES ('school','School','blue',1,0,0,0)");
    raw.execute("INSERT INTO schedule_series (id, revision, title, category_id, time_kind, start_date, created_at, updated_at, end_date_exclusive) "
        "VALUES ('s1', 1, 'Calculus', 'school', 'dateOnly', '2026-11-03', 0, 0, '2026-11-04')");
    raw.execute("INSERT INTO appearance_preferences (id, theme_mode, accent_key, density, show_category_colors, updated_at) VALUES (1, '$mode', '$accent', 'comfortable', 1, 0)");
    raw.execute("INSERT INTO widget_configurations (widget_id, updated_at) VALUES ('42', 0)");
    raw.execute('PRAGMA user_version = 1');
  }));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  for (final (accent, mode, theme) in [
    ('blue', 'system', ThemeId.lilac),
    ('teal', 'light', ThemeId.mint),
    ('indigo', 'system', ThemeId.lilac),
    ('graphite', 'dark', ThemeId.midnight),
    ('graphite', 'light', ThemeId.clay),
  ]) {
    test('v1 with $accent accent in $mode mode upgrades to ${theme.name} and keeps data', () async {
      final db = v1Database(accent: accent, mode: mode);
      addTearDown(db.close);
      expect(await db.customSelect('PRAGMA user_version').getSingle().then((r) => r.data.values.first), 2);
      expect((await db.select(db.scheduleSeriesTable).get()).single.title, 'Calculus');
      expect((await db.select(db.categories).get()).single.colorKey, 'blue');
      final settings = await AppearanceRepository(db, clock: DateTime.now).load();
      expect(settings.theme, theme);
      expect(settings.themeMode.name, mode);
      expect(settings.customHue, 250);
      // Widgets that existed before themes keep their current look.
      final widgets = {for (final r in await db.select(db.widgetConfigurations).get()) r.widgetId: r};
      expect(widgets.keys.toSet(), {'42', 'default'});
      expect(widgets.values.every((r) => !r.useAppTheme), isTrue);
      // The added default row keeps every other setting at its default.
      final configs = {for (final c in await WidgetConfigRepository(db, clock: DateTime.now).loadAll()) c.widgetKey: c};
      expect(configs['default'], WidgetConfig.defaults.copyWith(useAppTheme: false, revision: configs['default']!.revision));
      expect(await db.select(db.profilePreferences).get(), isEmpty);
    });
  }

  test('a fresh database starts on Lilac with no profile', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = await AppearanceRepository(db, clock: DateTime.now).load();
    expect(settings.theme, ThemeId.lilac);
    expect(settings.themeMode, ThemeMode.system);
  });

  test('theme and custom hue persist', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = AppearanceRepository(db, clock: DateTime.now);
    await repo.save(const AppearanceSettings(theme: ThemeId.custom, customHue: 140));
    final loaded = await repo.load();
    expect(loaded.theme, ThemeId.custom);
    expect(loaded.customHue, 140);
  });
}
