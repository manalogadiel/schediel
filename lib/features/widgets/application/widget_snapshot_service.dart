import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../app/providers.dart';
import '../../appearance/appearance.dart';
import '../data/widget_config_repository.dart';
import '../../../app/theme/schediel_theme.dart';
import '../domain/widget_config.dart';
import '../domain/widget_theme.dart';
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
    // Capture everything from the container before awaiting: the provider
    // may be disposed (app shutdown, tests) while loads are in flight.
    final appearance = _ref.read(appearanceProvider);
    final scheduleRepository = _ref.read(scheduleRepositoryProvider);
    final configRepository = _ref.read(widgetConfigRepositoryProvider);
    final categoryRepository = _ref.read(categoryRepositoryProvider);
    final database = _ref.read(databaseProvider);
    final builder = _ref.read(widgetSnapshotBuilderProvider);
    final writer = _ref.read(widgetSnapshotWriterProvider);
    final now = _ref.read(clockProvider)();
    final zone = _ref.read(deviceZoneProvider);
    final last = _ref.read(lastWidgetSnapshotProvider.notifier);

    final series = await scheduleRepository.loadAll();
    final configs = await configRepository.loadAll();
    final revision = await database.dataRevision();
    final categories = await categoryRepository.loadAll();
    final platformDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    final appIsDark = switch (appearance.themeMode.name) {
      'dark' => true,
      'light' => false,
      _ => platformDark,
    } || appearance.schedielTheme.darkOnly;
    final snapshot = builder.build(
      series: series,
      configs: configs,
      now: now,
      zone: zone,
      dataRevision: revision,
      use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
      appIsDark: appIsDark,
      theme: widgetThemeJson(appearance.schedielTheme, appearance.themeMode),
      // With category colors off, holders use the neutral fill.
      categoryColors: {
        for (final c in categories)
          if (appearance.showCategoryColors && CategoryColorKey.fromKey(c.colorKey) != null) c.id: c.colorKey,
      },
    );
    final json = jsonEncode(snapshot);
    await writer.write(json);
    if (_ref.mounted) last.set(json);
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
