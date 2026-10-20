import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_customization.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:schediel/app/widgets/theme_texture.dart';

void main() {
  testWidgets('textures do not take focus, add labels or replace input state', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();
    for (final texture in ThemeTexture.values) {
      final theme = buildTheme(
        theme: themeFor(ThemeId.lilac),
        brightness: Brightness.light,
        density: Density.comfortable,
        showCategoryColors: true,
        texture: texture,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: ThemeTextureSurface(
            texture: texture,
            child: Scaffold(
              body: TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Value'),
              ),
            ),
          ),
        ),
      );
      if (texture == ThemeTexture.none) await tester.enterText(find.byType(TextField), '12:30');
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(controller.text, '12:30');
      expect(find.bySemanticsLabel('Value'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });
  test('texture extremes preserve canvas text contrast', () {
    for (final id in ThemeId.values) {
      for (final tone in [0.0, 45.0, 50.0, 100.0]) {
        for (final brightness in Brightness.values) {
          final theme = buildTheme(
            theme: themeFor(id, customization: ThemeCustomization(backgroundTone: tone)),
            brightness: brightness,
            density: Density.comfortable,
            showCategoryColors: true,
          );
          final c = theme.extension<ScheduleColors>()!;
          final painted = Color.alphaBlend(textureOverlay(c), c.canvas);
          for (final ink in [c.ink, c.secondaryInk, c.accentText]) {
            expect(contrastRatio(ink, painted), greaterThanOrEqualTo(4.5), reason: '$id $brightness $tone');
          }
        }
      }
    }
  });
}
