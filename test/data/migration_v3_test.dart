import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/appearance/appearance.dart';
import 'package:schediel/app/theme/schediel_theme.dart';

AppDatabase v2Database({bool savedPreferences = true}) => AppDatabase(
  NativeDatabase.memory(
    setup: (raw) {
      final schema = File('test/data/fixtures/v1_schema.sql').readAsStringSync();
      for (final statement in schema.split(';\n').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
        raw.execute(statement.endsWith(';') ? statement : '$statement;');
      }
      raw.execute("ALTER TABLE appearance_preferences ADD COLUMN theme_key TEXT NOT NULL DEFAULT 'lilac'");
      raw.execute('ALTER TABLE appearance_preferences ADD COLUMN custom_hue INTEGER NOT NULL DEFAULT 250');
      raw.execute('ALTER TABLE widget_configurations ADD COLUMN use_app_theme INTEGER NOT NULL DEFAULT 1');
      raw.execute(
        'CREATE TABLE profile_preferences (id INTEGER NOT NULL PRIMARY KEY, display_name TEXT, photo_path TEXT, updated_at INTEGER NOT NULL)',
      );
      if (savedPreferences) {
        raw.execute(
          "INSERT INTO appearance_preferences (id, theme_mode, theme_key, custom_hue, updated_at) VALUES (1, 'system', 'pixel', 145, 0)",
        );
      }
      raw.execute('PRAGMA user_version = 2');
    },
  ),
);

void main() {
  test('fresh install defaults to light mode', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect((await AppearanceRepository(db, clock: DateTime.now).load()).themeMode, ThemeMode.light);
  });
  test('v2 upgrades additively and preserves the saved mode and theme', () async {
    final db = v2Database();
    addTearDown(db.close);
    final saved = await AppearanceRepository(db, clock: DateTime.now).load();
    expect(saved.themeMode, ThemeMode.system);
    expect(saved.theme, ThemeId.pixel);
    expect(saved.customHue, 145);
    expect((await db.customSelect('PRAGMA user_version').getSingle()).data.values.first, 3);
    final columns = await db.customSelect('PRAGMA table_info(appearance_preferences)').get();
    expect(columns.map((r) => r.data['name']), contains('theme_customizations_json'));
  });
  test('v2 with no saved row preserves its implicit system-mode preference', () async {
    final db = v2Database(savedPreferences: false);
    addTearDown(db.close);
    expect((await AppearanceRepository(db, clock: DateTime.now).load()).themeMode, ThemeMode.system);
  });
}
