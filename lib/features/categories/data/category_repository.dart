import 'package:drift/drift.dart';

import '../../../core/schedule/limits.dart';
import '../../../data/local/database.dart';
import '../../schedules/data/schedule_repository.dart' show OutboxReason;
import '../domain/category.dart';

enum CategoryNameProblem { empty, tooLong, duplicate }

class CategoryNameException implements Exception {
  CategoryNameException(this.problem);
  final CategoryNameProblem problem;
}

class CategoryRepository {
  CategoryRepository(this._db, {required this._clock, required this._newId});

  final AppDatabase _db;
  final DateTime Function() _clock;
  final String Function() _newId;

  Stream<List<Category>> watchAll() => (_db.select(_db.categories)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]))
      .watch()
      .map((rows) => [for (final r in rows) _toCategory(r)]);

  Future<List<Category>> loadAll() => watchAll().first;

  Future<Category> create(String name, {String? colorKey}) {
    return _db.transaction(() async {
      final trimmed = await _validName(name);
      final rows = await _db.select(_db.categories).get();
      final order = rows.isEmpty ? 0 : rows.map((r) => r.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
      final now = _clock().toUtc();
      final id = _newId();
      await _db.into(_db.categories).insert(CategoriesCompanion.insert(
            id: id,
            name: trimmed,
            colorKey: Value(colorKey),
            sortOrder: order,
            createdAt: now,
            updatedAt: now,
          ));
      await _commit(now);
      return Category(id: id, name: trimmed, colorKey: colorKey, builtIn: false, sortOrder: order);
    });
  }

  Future<void> rename(String id, String name) {
    return _db.transaction(() async {
      final trimmed = await _validName(name, excludeId: id);
      final now = _clock().toUtc();
      await (_db.update(_db.categories)..where((t) => t.id.equals(id)))
          .write(CategoriesCompanion(name: Value(trimmed), updatedAt: Value(now)));
      await _commit(now);
    });
  }

  Future<void> setColor(String id, String? colorKey) {
    return _db.transaction(() async {
      final now = _clock().toUtc();
      await (_db.update(_db.categories)..where((t) => t.id.equals(id)))
          .write(CategoriesCompanion(colorKey: Value(colorKey), updatedAt: Value(now)));
      await _commit(now);
    });
  }

  Future<void> reorder(List<String> orderedIds) {
    return _db.transaction(() async {
      final now = _clock().toUtc();
      for (var i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.categories)..where((t) => t.id.equals(orderedIds[i])))
            .write(CategoriesCompanion(sortOrder: Value(i), updatedAt: Value(now)));
      }
      await _commit(now);
    });
  }

  /// Deletes a category after the user chose where its schedules go:
  /// another category, or Uncategorized when [reassignTo] is null.
  Future<void> delete(String id, {String? reassignTo}) {
    if (reassignTo == id) throw ArgumentError('A category cannot be reassigned to itself');
    return _db.transaction(() async {
      final now = _clock().toUtc();
      await (_db.update(_db.scheduleSeriesTable)..where((t) => t.categoryId.equals(id))).write(
        ScheduleSeriesTableCompanion(categoryId: Value(reassignTo), updatedAt: Value(now)),
      );
      await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
      await _commit(now);
    });
  }

  Future<String> _validName(String name, {String? excludeId}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw CategoryNameException(CategoryNameProblem.empty);
    if (codePointLength(trimmed) > ScheduleLimits.categoryNameMax) {
      throw CategoryNameException(CategoryNameProblem.tooLong);
    }
    final rows = await _db.select(_db.categories).get();
    final lower = trimmed.toLowerCase();
    if (rows.any((r) => r.id != excludeId && r.name.toLowerCase() == lower)) {
      throw CategoryNameException(CategoryNameProblem.duplicate);
    }
    return trimmed;
  }

  Future<void> _commit(DateTime now) async {
    final revision = await _db.bumpDataRevision();
    await _db.into(_db.reconciliationOutbox).insert(ReconciliationOutboxCompanion.insert(
          operationKey: 'reconcile:$revision',
          reason: OutboxReason.categoryChanged,
          sourceRevision: revision,
          status: 'pending',
          createdAt: now,
        ));
  }

  Category _toCategory(CategoryRow r) =>
      Category(id: r.id, name: r.name, colorKey: r.colorKey, builtIn: r.builtIn, sortOrder: r.sortOrder);
}
