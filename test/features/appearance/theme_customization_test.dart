import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_customization.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/appearance/appearance.dart';

void main() {
  test('saved customization changes the resolved palette but keeps family identity', () {
    const settings = AppearanceSettings(
      theme: ThemeId.pixel,
      customizations: {ThemeId.pixel: ThemeCustomization(mainHue: 120, mainTone: 60, backgroundHue: 200, backgroundTone: 10)},
    );
    final resolved = settings.schedielTheme;
    expect(resolved.light.accent, isNot(const AppearanceSettings(theme: ThemeId.pixel).schedielTheme.light.accent));
    expect(resolved.light.canvas, isNot(const AppearanceSettings(theme: ThemeId.pixel).schedielTheme.light.canvas));
    expect(resolved.displayFont, 'Silkscreen');
    expect(resolved.style, StyleFamily.pixel);
  });
  test('per-theme choices round trip independently and participate in equality', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = AppearanceRepository(db, clock: DateTime.now);
    const choices = {
      ThemeId.pop: ThemeCustomization(mainHue: 12, mainTone: 60, texture: ThemeTexture.paper),
      ThemeId.pixel: ThemeCustomization(backgroundHue: 180, backgroundTone: 20),
    };
    const settings = AppearanceSettings(theme: ThemeId.pop, customizations: choices);
    expect(settings, isNot(const AppearanceSettings(theme: ThemeId.pop)));
    await repo.save(settings);
    final loaded = await repo.load();
    expect(loaded, settings);
    expect(loaded.hashCode, settings.hashCode);
    final switched = loaded.copyWith(theme: ThemeId.pixel);
    await repo.save(switched);
    expect((await repo.load()).customizations, choices);
    expect(switched.customizations[ThemeId.pop]!.texture, ThemeTexture.paper);
  });
}
