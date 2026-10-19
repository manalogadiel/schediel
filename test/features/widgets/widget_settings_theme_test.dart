import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/features/widgets/application/widget_snapshot_service.dart';
import 'package:schediel/features/widgets/data/widget_config_repository.dart';

import '../../support/harness.dart';

class RecordingWriter implements WidgetSnapshotWriter {
  final List<String> written = [];

  @override
  Future<void> write(String json) async => written.add(json);

  @override
  Future<List<String>> installedWidgetKeys() async => const [];

  @override
  Future<String?> readBack() async => written.isEmpty ? null : written.last;
}

void main() {
  final writer = RecordingWriter();

  Future<void> openDefaultWidget(TestHarness h) async {
    await h.tapText('Settings');
    final entry = find.text('Home screen widgets');
    await h.tester.scrollUntilVisible(entry, 200, scrollable: find.byType(Scrollable).first);
    await h.tapText('Home screen widgets');
    await h.tapText('Default widget settings');
  }

  appTest('Use app theme is on for a new widget, persists when turned off and rewrites the snapshot', (h) async {
    writer.written.clear();
    await openDefaultWidget(h);
    final toggle = find.widgetWithText(SwitchListTile, 'Use app theme');
    await h.tester.scrollUntilVisible(toggle, 200, scrollable: find.byType(Scrollable).first);
    expect(h.tester.widget<SwitchListTile>(toggle).value, isTrue);

    final before = writer.written.length;
    await h.tester.tap(toggle);
    await h.settle();
    expect(h.tester.widget<SwitchListTile>(toggle).value, isFalse);
    final saved = await h.run(() => WidgetConfigRepository(h.db, clock: DateTime.now).loadAll());
    expect(saved.single.useAppTheme, isFalse);
    // The snapshot write follows the save; give the database work time to finish.
    for (var i = 0; i < 100 && writer.written.length == before; i++) {
      await h.tester.pump(const Duration(milliseconds: 20));
    }
    expect(writer.written.length, greaterThan(before));
    final snapshot = jsonDecode(writer.written.last) as Map<String, dynamic>;
    expect(snapshot['schemaVersion'], '1.1');
    expect(snapshot['theme'], isA<Map<String, dynamic>>());
    final configuration = ((snapshot['widgets'] as Map)['default'] as Map)['configuration'] as Map;
    expect(configuration['useAppTheme'], isFalse);
  }, overrides: [widgetSnapshotWriterProvider.overrideWithValue(writer)]);
}
