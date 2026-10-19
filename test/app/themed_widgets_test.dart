import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:schediel/app/widgets/sketch_border.dart';
import 'package:schediel/app/widgets/themed.dart';
import 'package:schediel/features/profile/domain/profile.dart';

Widget host(ThemeId id, Widget child, {Brightness brightness = Brightness.light, bool reduceMotion = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(theme: themeFor(id), brightness: brightness, density: Density.comfortable, showCategoryColors: true),
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  test('sketch outline is deterministic for a seed and differs between seeds', () {
    const size = Size(200, 80);
    List<Offset> points(Object seed) => SketchBorderPainter.outline(size, seed: seed, radius: 18).points;
    expect(points('a'), points('a'));
    expect(points('a'), isNot(points('b')));
    // The wobble stays close to the box.
    for (final p in points('a')) {
      expect(p.dx, inInclusiveRange(-3, size.width + 3));
      expect(p.dy, inInclusiveRange(-3, size.height + 3));
    }
  });

  testWidgets('sketch cards tilt slightly, but not with reduced motion', (tester) async {
    double angle() {
      final t = tester.widget<Transform>(find.descendant(of: find.byType(ThemedCard), matching: find.byType(Transform)).first);
      return t.transform.getRotation().entry(1, 0);
    }

    await tester.pumpWidget(host(ThemeId.sketch, const ThemedCard(seed: 'tilt-seed', child: SizedBox(width: 120, height: 40))));
    expect(angle().abs(), greaterThan(0));
    expect(angle().abs(), lessThanOrEqualTo(0.0175)); // ≤ 1°
    await tester.pumpWidget(host(ThemeId.sketch, const ThemedCard(seed: 'tilt-seed', child: SizedBox(width: 120, height: 40)), reduceMotion: true));
    expect(find.descendant(of: find.byType(ThemedCard), matching: find.byType(Transform)), findsNothing);
  });

  testWidgets('a tappable card is at least 48dp tall and reports taps', (tester) async {
    var taps = 0;
    for (final id in ThemeId.values) {
      await tester.pumpWidget(host(id, ThemedCard(onTap: () => taps++, child: const Text('x'))));
      expect(tester.getSize(find.byType(ThemedCard)).height, greaterThanOrEqualTo(Tokens.minTarget), reason: id.name);
      await tester.tap(find.byType(ThemedCard));
    }
    expect(taps, ThemeId.values.length);
  });

  testWidgets('a label pill hugs its label instead of stretching across a wide row', (tester) async {
    for (final id in [ThemeId.lilac, ThemeId.pixel]) {
      await tester.pumpWidget(host(
          id,
          const SizedBox(
            width: 320,
            child: Wrap(children: [ThemedPill(key: ValueKey('pill'), label: 'Next'), Text('in 5 min', key: ValueKey('after'))]),
          )));
      final pill = tester.getSize(find.byKey(const ValueKey('pill')));
      expect(pill.width, lessThan(100), reason: id.name);
      // The text after the pill stays on the same line.
      expect(tester.getTopLeft(find.byKey(const ValueKey('after'))).dy, lessThan(tester.getBottomLeft(find.byKey(const ValueKey('pill'))).dy),
          reason: id.name);
    }
  });

  testWidgets('pill text uses readable ink on its fill in every theme', (tester) async {
    for (final id in ThemeId.values) {
      for (final b in Brightness.values) {
        await tester.pumpWidget(host(id, const ThemedPill(label: 'Now', emphasized: true), brightness: b));
        final text = tester.widget<Text>(find.text('Now'));
        final pill = tester.widget<ThemedPill>(find.byType(ThemedPill));
        final ctx = tester.element(find.byType(ThemedPill));
        final fill = pill.resolveFill(ctx);
        expect(contrastRatio(text.style!.color!, fill), greaterThanOrEqualTo(4.5), reason: '${id.name} $b');
      }
    }
  });

  testWidgets('avatar shows the photo, otherwise initials, otherwise a person icon', (tester) async {
    await tester.pumpWidget(host(ThemeId.lilac, const ThemedAvatar(profile: Profile(name: 'Diel Manalo'))));
    expect(find.text('DM'), findsOneWidget);
    await tester.pumpWidget(host(ThemeId.lilac, const ThemedAvatar(profile: Profile())));
    expect(find.byType(Text), findsNothing);
    expect(find.bySemanticsLabel('Profile'), findsOneWidget);
    // Real file IO must run outside the fake-async test zone.
    final dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('avatar')))!;
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/p.png')..writeAsBytesSync(const [
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0x0D, 0x49, 0x48, 0x44, 0x52, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 0x1F,
          0x15, 0xC4, 0x89, 0, 0, 0, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0, 1, 0, 0, 5, 0, 1, 0x0D, 0x0A, 0x2D, 0xB4, 0, 0, 0,
          0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
        ]);
    await tester.pumpWidget(host(ThemeId.pixel, ThemedAvatar(profile: Profile(name: 'Diel', photoPath: file.path))));
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('D'), findsNothing);
  });

  for (final b in Brightness.values) {
    testWidgets('primitives golden ($b)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(720, 1040));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final themes = ThemeId.values.where((id) => b == Brightness.light || !themeFor(id).darkOnly).toList();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: const ValueKey('golden'),
          child: Column(children: [
            for (final id in themes)
              Expanded(
                child: Theme(
                  data: buildTheme(theme: themeFor(id), brightness: b, density: Density.comfortable, showCategoryColors: true),
                  child: Builder(builder: (context) {
                    final c = context.scheduleColors;
                    return ColoredBox(
                      color: c.canvas,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          for (final (i, key) in ['blue', 'green', 'orange', null].indexed) ...[
                            Expanded(
                              child: ThemedCard(
                                seed: '${id.name}-$i',
                                fill: c.categoryFill(key),
                                emphasized: i == 0,
                                child: const SizedBox(height: 70),
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          const ThemedPill(width: 56, height: 32, emphasized: true),
                        ]),
                      ),
                    );
                  }),
                ),
              ),
          ]),
        ),
      ));
      await expectLater(find.byKey(const ValueKey('golden')), matchesGoldenFile('goldens/primitives_${b.name}.png'));
    });
  }

  test('outlined styles are the non-soft families', () {
    for (final id in ThemeId.values) {
      final t = buildTheme(theme: themeFor(id), brightness: Brightness.light, density: Density.comfortable, showCategoryColors: true);
      expect(t.extension<ScheduleColors>()!.outlined, themeFor(id).style != StyleFamily.soft);
    }
  });
}
