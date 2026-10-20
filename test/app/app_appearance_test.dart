import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:schediel/app/theme/theme_customization.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/features/widgets/domain/widget_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:schediel/features/appearance/appearance.dart';
import 'package:schediel/features/widgets/application/widget_snapshot_service.dart';

import '../support/harness.dart';
import '../features/widgets/widget_settings_theme_test.dart' show RecordingWriter;

void main() {
  final writer = RecordingWriter();
  appTest('custom family colors trigger a widget refresh without a schema change', (h) async {
    writer.written.clear();
    await h.run(
      () => h
          .read(appearanceProvider.notifier)
          .update((s) => s.copyWith(customizations: {ThemeId.lilac: const ThemeCustomization(mainHue: 130, mainTone: 70)})),
    );
    for (var i = 0; i < 100 && writer.written.isEmpty; i++) {
      await h.tester.pump(const Duration(milliseconds: 20));
    }
    expect(writer.written, isNotEmpty);
    final snapshot = jsonDecode(writer.written.last) as Map;
    final settings = h.read(appearanceProvider);
    expect(snapshot['schemaVersion'], '1.1');
    expect(snapshot['theme'], widgetThemeJson(settings.schedielTheme, settings.themeMode));
    expect((snapshot['theme'] as Map).containsKey('texture'), isFalse);
  }, overrides: [widgetSnapshotWriterProvider.overrideWithValue(writer)]);

  appTest('turning category colors off rewrites the widget snapshot', (h) async {
    writer.written.clear();
    await h.run(() => h.read(appearanceProvider.notifier).update((s) => s.copyWith(showCategoryColors: !s.showCategoryColors)));
    for (var i = 0; i < 100 && writer.written.isEmpty; i++) {
      await h.tester.pump(const Duration(milliseconds: 20));
    }
    expect(writer.written, isNotEmpty);
    expect((jsonDecode(writer.written.last) as Map)['schemaVersion'], '1.1');
  }, overrides: [widgetSnapshotWriterProvider.overrideWithValue(writer)]);

  appTest('theme switches follow the platform Reduce Motion setting', (h) async {
    MaterialApp app() => h.tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeAnimationDuration, Tokens.screenMotion);
    h.tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(h.tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await h.settle();
    expect(app().themeAnimationDuration, Duration.zero);
  });
}
