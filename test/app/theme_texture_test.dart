import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' hide TextureLayer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/app.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_customization.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:schediel/app/widgets/theme_texture.dart';
import 'package:schediel/app/widgets/themed.dart';
import 'package:schediel/features/appearance/appearance.dart';

import '../support/harness.dart';

void main() {
  testWidgets('animated card contents do not repaint a static texture', (tester) async {
    final offset = ValueNotifier<double>(0);
    addTearDown(offset.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(theme: themeFor(ThemeId.lilac), brightness: Brightness.light,
        density: Density.comfortable, showCategoryColors: true, texture: ThemeTexture.paper),
      home: Scaffold(body: Center(child: SizedBox(width: 300, height: 160,
        child: ThemedCard(child: ValueListenableBuilder<double>(
          valueListenable: offset,
          builder: (_, value, child) => Transform.translate(offset: Offset(value, 0), child: child),
          child: const Text('Sample schedule'),
        )),
      ))),
    ));
    await _loadTextures(tester);
    await tester.pump();
    final texture = find.descendant(of: find.byType(TextureLayer), matching: find.byType(RawImage));
    final image = tester.widget<RawImage>(texture).image!;
    final retained = image.clone();
    addTearDown(retained.dispose);
    for (var i = 1; i <= 10; i++) {
      offset.value = i.toDouble();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.widget<RawImage>(texture).image!.isCloneOf(retained), isTrue,
        reason: 'Foreground animation must reuse the pre-rendered texture.');
    }
    expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is TexturePainter), findsNothing);
  });
  testWidgets('cached textures update after size, pattern and palette changes', (tester) async {
    ui.Image? previous;
    for (final (size, texture, background, shade) in [
      (const Size(120, 80), ThemeTexture.paper, Colors.white, Colors.black12),
      (const Size(160, 90), ThemeTexture.paper, Colors.white, Colors.black12),
      (const Size(160, 90), ThemeTexture.carbon, Colors.white, Colors.black12),
      (const Size(160, 90), ThemeTexture.carbon, Colors.black, Colors.white24),
    ]) {
      await tester.pumpWidget(MaterialApp(home: Center(child: SizedBox.fromSize(
        size: size, child: TextureLayer(texture, background: background, shade: shade)))));
      await _loadTextures(tester);
      await tester.pump();
      final image = tester.widget<RawImage>(find.byType(RawImage)).image!;
      expect(image.width, (size.width * tester.view.devicePixelRatio).ceil());
      expect(image.height, (size.height * tester.view.devicePixelRatio).ceil());
      if (previous != null) {
        expect(image.isCloneOf(previous), isFalse, reason: 'A changed surface must not reuse stale pixels.');
        previous.dispose();
      }
      previous = image.clone();
      final bytes = await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba));
      expect(bytes!.getUint8(0), background == Colors.black ? lessThan(100) : greaterThan(200));
    }
    previous?.dispose();
  });
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
    await _loadTextures(h.tester);
    await h.tester.pump();
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

Future<void> _loadTextures(WidgetTester tester) async {
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    if (image.image is! TextureImage) continue;
    await tester.runAsync(() async {
      final stream = image.image.resolve(createLocalImageConfiguration(element));
      final ready = Completer<void>();
      final listener = ImageStreamListener((info, _) {
        info.dispose();
        ready.complete();
      }, onError: (Object error, StackTrace? stack) => ready.completeError(error, stack));
      stream.addListener(listener);
      try {
        await ready.future;
      } finally {
        stream.removeListener(listener);
      }
    });
  }
}
