import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/local/database.dart';
import '../../schedules/data/schedule_repository.dart';
import '../domain/import_entry.dart';

class ImportRepository {
  ImportRepository(this._db, this._schedules, {required this._clock, required this._newId});
  final AppDatabase _db;
  final ScheduleRepository _schedules;
  final DateTime Function() _clock;
  final String Function() _newId;
  Future<Map<String, ImportDuplicate>> inspect(List<ImportEntry> entries) async {
    final sources = await _db.select(_db.importProvenance).get();
    final fingerprints = {for (final s in await _schedules.loadAll()) scheduleFingerprint(s)};
    return {
      for (final e in entries)
        e.candidateId: ImportDuplicate(
          exact: sources.any((p) => _sameSource(e, p)),
          similar: fingerprints.contains(scheduleFingerprint(e.asSeries('', _clock()))),
        ),
    };
  }

  bool _sameSource(ImportEntry e, ProvenanceRow p) =>
      e.sourceType == p.sourceType && e.sourceItemId != null &&
      e.sourceItemId == p.sourceItemId && e.sourceRevision == p.sourceRevision &&
      (e.sourceType == 'share'
          ? e.shareId != null && e.shareId == p.shareId
          : e.imageDraftId != null && e.imageDraftId == p.imageDraftId);

  /// Only this explicit command turns candidates into active local rows.
  /// Receipt, schedules, provenance and reconciliation are one SQLite commit.
  Future<List<String>> commit(String commandId, List<ImportEntry> entries) => _db.transaction(() async {
    final body = jsonEncode(entries.map((e) => e.toCommandJson()).toList());
    final hash = sha256.convert(utf8.encode(body)).toString();
    final receipt = await (_db.select(_db.importCommits)..where((t) => t.commandId.equals(commandId))).getSingleOrNull();
    if (receipt != null) {
      if (receipt.payloadHash != hash) throw StateError('import_command_mismatch');
      return (jsonDecode(receipt.seriesIdsJson) as List).cast<String>();
    }
    if (entries.map((e) => e.candidateId).toSet().length != entries.length) throw StateError('duplicate_candidate_id');
    final now = _clock().toUtc();
    final ids = <String>[];
    final sources = await _db.select(_db.importProvenance).get();
    for (final e in entries) {
      if (!e.keepCopy && sources.any((p) => _sameSource(e, p))) continue;
      final id = _newId();
      final series = e.asSeries(id, now);
      await _schedules.insertValidatedSeries(series, alerts: e.alerts);
      final provenance = ImportProvenanceCompanion.insert(
        id: _newId(), seriesId: id, sourceType: e.sourceType,
        shareId: Value(e.shareId), sourceItemId: Value(e.sourceItemId),
        sourceRevision: Value(e.sourceRevision), imageDraftId: Value(e.imageDraftId),
        fingerprint: scheduleFingerprint(series), importedAt: now,
      );
      await _db.into(_db.importProvenance).insert(provenance);
      ids.add(id);
    }
    await _db.into(_db.importCommits).insert(ImportCommitsCompanion.insert(
      commandId: commandId, payloadHash: hash, seriesIdsJson: jsonEncode(ids), committedAt: now,
    ));
    if (ids.isNotEmpty) await _schedules.commitWork(OutboxReason.importCommitted);
    return ids;
  });
}
final importRepositoryProvider = Provider<ImportRepository>((ref) => ImportRepository(
  ref.watch(databaseProvider), ref.watch(scheduleRepositoryProvider),
  clock: ref.watch(clockProvider), newId: ref.watch(idGeneratorProvider),
));
