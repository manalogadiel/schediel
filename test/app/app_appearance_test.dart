import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:schediel/features/appearance/appearance.dart';
import 'package:schediel/features/widgets/application/widget_snapshot_service.dart';

import '../support/harness.dart';
import '../features/widgets/widget_settings_theme_test.dart' show RecordingWriter;

void main() {
  final writer = RecordingWriter();

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
