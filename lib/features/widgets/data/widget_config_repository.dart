import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../data/local/database.dart';
import '../../categories/domain/category.dart';
import '../domain/widget_config.dart';

class WidgetConfigRepository {
  WidgetConfigRepository(this._db, {required this._clock});

  final AppDatabase _db;
  final DateTime Function() _clock;

  Stream<List<WidgetConfig>> watchAll() =>
      _db.select(_db.widgetConfigurations).watch().map((rows) => [for (final r in rows) _toConfig(r)]);

  Future<List<WidgetConfig>> loadAll() async => [for (final r in await _db.select(_db.widgetConfigurations).get()) _toConfig(r)];

  /// Saves a configuration and bumps its revision.
  Future<WidgetConfig> save(WidgetConfig config) async {
    final next = config.copyWith(revision: config.revision + 1);
    final filter = next.filter.toJson();
    await _db.into(_db.widgetConfigurations).insertOnConflictUpdate(WidgetConfigurationsCompanion.insert(
          widgetId: next.widgetKey,
          categoryFilter: Value(filter == null ? null : jsonEncode(filter)),
          layout: Value(next.layout.name),
          surface: Value(next.surface.name),
          textTone: Value(next.textTone.name),
          nextEmphasis: Value(next.nextEmphasis),
          showLocation: Value(next.showLocation),
          showProfessor: Value(next.showProfessor),
          showSubtitle: Value(next.showSubtitle),
          matchApp: Value(next.matchApp),
          revision: Value(next.revision),
          updatedAt: _clock().toUtc(),
        ));
    return next;
  }

  /// Removing one widget's settings never touches schedules or other widgets.
  Future<void> delete(String widgetKey) =>
      (_db.delete(_db.widgetConfigurations)..where((t) => t.widgetId.equals(widgetKey))).go();

  WidgetConfig _toConfig(WidgetConfigRow r) => WidgetConfig(
        widgetKey: r.widgetId,
        filter: CategoryFilter.fromJson(r.categoryFilter == null ? null : jsonDecode(r.categoryFilter!)),
        layout: WidgetLayout.values.firstWhere((v) => v.name == r.layout, orElse: () => WidgetLayout.expanded),
        surface: WidgetSurface.values.firstWhere((v) => v.name == r.surface, orElse: () => WidgetSurface.clear),
        textTone: WidgetTextTone.values.firstWhere((v) => v.name == r.textTone, orElse: () => WidgetTextTone.light),
        nextEmphasis: r.nextEmphasis,
        showLocation: r.showLocation,
        showProfessor: r.showProfessor,
        showSubtitle: r.showSubtitle,
        matchApp: r.matchApp,
        revision: r.revision,
      );
}
