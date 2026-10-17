import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../app/providers.dart';
import '../../appearance/appearance.dart';
import '../data/widget_config_repository.dart';
import '../domain/widget_config.dart';
import 'widget_snapshot_builder.dart';

const androidWidgetProvider = 'com.manalogadiel.schediel.widget.ScheduleWidgetProvider';
const iOSWidgetKind = 'ScheduleWidget';
const iOSAppGroup = 'group.com.manalogadiel.schediel';

/// Platform side of the widget hand-off. Replaced in tests.
abstract class WidgetSnapshotWriter {
  Future<void> write(String json);

  /// Native widget instance keys currently placed (Android appWidgetIds).
  Future<List<String>> installedWidgetKeys();

  Future<String?> readBack();
}

class HomeWidgetSnapshotWriter implements WidgetSnapshotWriter {
  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _ensureGroup() async {
    if (Platform.isIOS) await HomeWidget.setAppGroupId(iOSAppGroup);
  }

  @override
  Future<void> write(String json) async {
    if (!_supported) return;
    try {
      await _ensureGroup();
      await HomeWidget.saveWidgetData<String>(widgetSnapshotKey, json);
      await HomeWidget.updateWidget(qualifiedAndroidName: androidWidgetProvider, iOSName: iOSWidgetKind);
    } on PlatformException {
      // The widget keeps its previous snapshot; it shows a stale state when
      // that snapshot's coverage ends.
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<List<String>> installedWidgetKeys() async {
    if (!_supported || !Platform.isAndroid) return const [];
    try {
      final widgets = await HomeWidget.getInstalledWidgets();
      return [
        for (final w in widgets)
          if (w.androidWidgetId != null) '${w.androidWidgetId}',
      ];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  Future<String?> readBack() async {
    if (!_supported) return null;
    try {
      await _ensureGroup();
      return await HomeWidget.getWidgetData<String>(widgetSnapshotKey);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

/// Writes a fresh snapshot after committed changes (spec 12.2-12.3).
class WidgetSnapshotService {
  WidgetSnapshotService(this._ref);

  final Ref _ref;

  Future<String> refresh() async {
    final series = await _ref.read(scheduleRepositoryProvider).loadAll();
    final configs = await _ref.read(widgetConfigRepositoryProvider).loadAll();
    final revision = await _ref.read(databaseProvider).dataRevision();
    final appearance = _ref.read(appearanceProvider);
    final platformDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    final appIsDark = switch (appearance.themeMode.name) {
      'dark' => true,
      'light' => false,
      _ => platformDark,
    };
    final snapshot = _ref.read(widgetSnapshotBuilderProvider).build(
          series: series,
          configs: configs,
          now: _ref.read(clockProvider)(),
          zone: _ref.read(deviceZoneProvider),
          dataRevision: revision,
          use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
          appIsDark: appIsDark,
        );
    final json = jsonEncode(snapshot);
    await _ref.read(widgetSnapshotWriterProvider).write(json);
    _ref.read(lastWidgetSnapshotProvider.notifier).set(json);
    return json;
  }
}

final widgetSnapshotBuilderProvider = Provider<WidgetSnapshotBuilder>(
  (ref) => WidgetSnapshotBuilder(ref.watch(zoneResolverProvider), ref.watch(occurrenceEngineProvider)),
);

final widgetSnapshotWriterProvider = Provider<WidgetSnapshotWriter>((ref) => HomeWidgetSnapshotWriter());

final widgetConfigRepositoryProvider = Provider<WidgetConfigRepository>(
  (ref) => WidgetConfigRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final widgetConfigsProvider = StreamProvider<List<WidgetConfig>>((ref) => ref.watch(widgetConfigRepositoryProvider).watchAll());

final installedWidgetKeysProvider = FutureProvider<List<String>>((ref) => ref.watch(widgetSnapshotWriterProvider).installedWidgetKeys());

final widgetSnapshotServiceProvider = Provider<WidgetSnapshotService>((ref) => WidgetSnapshotService(ref));

/// The most recent snapshot written by this app session, for the preview.
final lastWidgetSnapshotProvider = NotifierProvider<LastSnapshotNotifier, String?>(LastSnapshotNotifier.new);

class LastSnapshotNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String json) => state = json;
}
