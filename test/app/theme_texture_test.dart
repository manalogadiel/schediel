import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/app.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_customization.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:schediel/app/widgets/theme_texture.dart';
import 'package:schediel/features/appearance/appearance.dart';

import '../support/harness.dart';

void main() {
  appTest('selected texture is visible behind the actual app navigation', (h) async {
    const key = ValueKey('texture-screen-capture');
    await h.tester.pumpWidget(UncontrolledProviderScope(container: h.container,
      child: const RepaintBoundary(key: key, child: SchedielApp())));
    await h.settle();
    Future<List<int>> capture() async {
      final boundary = h.tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final image = await h.tester.runAsync(() => boundary.toImage(pixelRatio: 1));
      final bytes = await h.tester.runAsync(() => image!.toByteData(format: ui.ImageByteFormat.rawRgba));
      image!.dispose();
      return bytes!.buffer.asUint8List().toList();
    }
    final plain = await capture();
    await h.run(() => h.read(appearanceProvider.notifier).update((s) => s.copyWith(
      customizations: {s.theme: const ThemeCustomization(texture: ThemeTexture.grid)})));
    await h.settle();
    final textured = await capture();
    var marks = 0;
    // The empty margin has no labels/cards: changes here must be the canvas.
    for (var y = 300; y < 600; y++) {
      for (var x = 2; x < 12; x++) {
        final i = (y * 400 + x) * 4;
        if ((plain[i] - textured[i]).abs() > 3) marks++;
      }
    }
    expect(marks, greaterThan(80), reason: 'The router must not cover the texture.');
  });
  test('default palettes paint visible marks rather than white on near-white', () {
    for (final id in ThemeId.values) {
      for (final brightness in Brightness.values) {
        final theme = buildTheme(theme: themeFor(id), brightness: brightness,
          density: Density.comfortable, showCategoryColors: true, texture: ThemeTexture.grid);
        final c = theme.extension<ScheduleColors>()!;
        final painted = Color.alphaBlend(textureOverlay(c), c.canvas);
        final difference = [(painted.r - c.canvas.r).abs(),
          (painted.g - c.canvas.g).abs(), (painted.b - c.canvas.b).abs()]
          .reduce((a, b) => a > b ? a : b);
        expect(difference, greaterThan(6 / 255), reason: '$id $brightness');
      }
    }
  });
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
