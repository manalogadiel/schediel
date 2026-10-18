import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/local/database.dart';
import '../../schedules/data/schedule_repository.dart';
import '../../sharing/application/share_sender.dart';
import '../../sharing/data/share_api.dart';
import '../../sharing/data/share_secret_store.dart';
import '../domain/backend_deletion.dart';

/// Durable local scope of one command; never contains bearer secrets.
class _DeletionRequest {
  const _DeletionRequest(this.key, this.ownedShareIds, {this.ownerId});

  final String key;
  final List<String> ownedShareIds;

  /// Identity the command was created for; null for a legacy saved key.
  final String? ownerId;

  String encode() => jsonEncode({
    'version': 2,
    'key': key,
    'ownerId': ownerId,
    'ownedShareIds': ownedShareIds,
  });

  static _DeletionRequest? decode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      if (json['version'] != 2) return null;
      return _DeletionRequest(json['key'] as String,
        (json['ownedShareIds'] as List).cast<String>().toList(), ownerId: json['ownerId'] as String?);
    } on Object {
      return null;
    }
  }
}

class PrivacyRepository {
  PrivacyRepository(this.db,this.schedules,this.secrets,this.api,{required this.newId});
  final AppDatabase db; final ScheduleRepository schedules; final ShareSecretStore secrets;
  final BackendDataApi api; final String Function() newId;
  static const _jobKey = 'backend-deletion-job';
  static const _requestKey = 'backend-deletion-request';
  static const _requestContextKey = 'backend-deletion-request-context';
  static String _jobContextKey(String id) => 'backend-deletion-context:$id';

  Future<void> deleteLocalSchedules() => db.transaction(() async {
    await db.delete(db.scheduleSeriesTable).go();
    // Known native requests intentionally survive until cancellation is
    // reconciled. Categories, preferences and online records are separate.
    await schedules.commitWork(OutboxReason.seriesDeleted);
  });

  /// Sends the saved deletion command, or a new one. The server deletes only
  /// the calling identity's links, so a command's scope is the local links
  /// recorded for that identity when the command was first created; replays
  /// keep the same key, identity and scope. Pending creations are never in
  /// scope: they may commit on the server after the deletion and still be live.
  ///
  /// Throws [BackendDeletionExpired] when the saved command can no longer be
  /// replayed (expired, or the online identity changed); the caller must ask
  /// the user before passing [fresh].
  /// [onSaved] runs once a new command is durably saved, before it is sent.
  Future<BackendDeletion> requestBackendDeletion({bool fresh = false, void Function()? onSaved}) async {
    final ownerId = await api.currentOwnerId();
    // Deletion never signs in: without the identity there is nothing to delete.
    if (ownerId == null) throw const ShareApiException(status: 401, code: 'unauthenticated');
    var request = fresh ? null : await _savedRequest();
    if (request?.ownerId != null && request!.ownerId != ownerId) throw const BackendDeletionExpired();
    if (request == null) {
      final owned = await db.select(db.ownedShareLinks).get();
      final scope = <String>[
        for (final l in owned)
          if (await db.readValue(ShareSender.ownedOwnerKey(l.shareId)) == ownerId) l.shareId,
      ];
      request = _DeletionRequest(newId(), scope, ownerId: ownerId);
      await db.writeValue(_requestContextKey, request.encode());
      await db.writeValue(_requestKey, '');
      onSaved?.call();
    }
    final BackendDeletion accepted;
    try {
      accepted = await api.deleteBackendData(request.key, expectedOwnerId: ownerId);
    } on ShareApiException catch (e) {
      if (e.code == 'idempotency_expired') throw const BackendDeletionExpired();
      rethrow;
    }
    await db.transaction(() async {
      await db.writeValue(_jobContextKey(accepted.deletionJobId), request!.encode());
      await db.writeValue(_jobKey, accepted.deletionJobId);
      await db.writeValue(_requestContextKey, '');
    });
    // 202 is acceptance, not proof of deletion. Read the exact job.
    return refreshBackendDeletion(accepted.deletionJobId);
  }

  Future<_DeletionRequest?> _savedRequest() async {
    final saved = _DeletionRequest.decode(await db.readValue(_requestContextKey));
    if (saved != null) return saved;
    // A key saved by an earlier version has no recorded scope: replay it,
    // but clean nothing locally when it completes.
    final legacy = await db.readValue(_requestKey);
    return legacy == null || legacy.isEmpty ? null : _DeletionRequest(legacy, const []);
  }

  Future<BackendDeletion> refreshBackendDeletion(String jobId) async {
    final status = await api.deletionJob(jobId);
    if (status.deletionJobId != jobId) throw StateError('deletion_job_mismatch');
    final cleanupKey = 'backend-deletion-cleaned:$jobId';
    if (status.status == 'completed' && await db.readValue(cleanupKey) != 'true') {
      // Only links that existed when this command was created; an unknown
      // job (no saved scope) cleans nothing.
      final scope = _DeletionRequest.decode(await db.readValue(_jobContextKey(jobId)))?.ownedShareIds ?? const <String>[];
      for (final shareId in scope) {
        await secrets.delete(ShareSender.shareSecretKey(shareId));
      }
      await db.transaction(() async {
        if (scope.isNotEmpty) {
          await (db.delete(db.ownedShareLinks)..where((t) => t.shareId.isIn(scope))).go();
          await (db.delete(db.keyValues)..where((t) => t.key.isIn([for (final id in scope) ShareSender.ownedOwnerKey(id)]))).go();
        }
        await db.writeValue(cleanupKey, 'true');
      });
    }
    return status;
  }
  Future<String?> lastJobId() => db.readValue(_jobKey);
}

final backendDataApiProvider = Provider<BackendDataApi>((ref) => ref.watch(shareApiProvider) as BackendDataApi);
final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) => PrivacyRepository(
  ref.watch(databaseProvider), ref.watch(scheduleRepositoryProvider), ref.watch(shareSecretStoreProvider),
  ref.watch(backendDataApiProvider), newId: ref.watch(idGeneratorProvider),
));
