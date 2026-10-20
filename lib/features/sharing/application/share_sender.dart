import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../app/providers.dart';
import '../../../core/schedule/models.dart';
import '../../../data/local/database.dart';
import '../data/share_api.dart';
import '../data/share_secret_store.dart';
import '../domain/share_link.dart';
import '../domain/share_payload.dart';
import 'sharing_config.dart';
import 'sharing_runtime.dart';

enum ShareBuildProblem { nothingSelected, tooMany, tooLarge, invalid }

@immutable
class ShareBuild {
  const ShareBuild.ok(SharePayload this.payload) : problem = null;

  const ShareBuild.failed(ShareBuildProblem this.problem) : payload = null;

  final SharePayload? payload;
  final ShareBuildProblem? problem;
}

@immutable
class CreatedShare {
  const CreatedShare(this.share, this.link);

  final OwnedShare share;
  final Uri link;
}

/// Link validity choices offered to the sender (openapi.yaml expiresAt).
const shareValidityChoices = [Duration(days: 1), Duration(days: 7)];

/// Sender side of link sharing (spec 9.2, 13.4): builds the exact snapshot,
/// keeps the bearer secret on the device and creates the link idempotently.
class ShareSender {
  ShareSender({
    required this._db,
    required this._api,
    required this._secrets,
    required this._config,
    required this._validator,
    required this._clock,
    required this._newId,
  });

  final AppDatabase _db;
  final ShareApi _api;
  final ShareSecretStore _secrets;
  final SharingConfig _config;
  final SharePayloadValidator _validator;
  final DateTime Function() _clock;
  final String Function() _newId;

  static String pendingSecretKey(String idempotencyKey) => 'share-pending:$idempotencyKey';

  static String shareSecretKey(String shareId) => 'share-secret:$shareId';

  // Owner identity is metadata, not a credential. Keep it beside the pending
  // command without a schema migration; missing legacy bindings fail closed.
  static String pendingOwnerKey(String idempotencyKey) => 'share-pending-owner:$idempotencyKey';

  /// Online identity that owns a created link. Backend deletion only covers
  /// the sending identity's links, so its local cleanup is scoped by this.
  static String ownedOwnerKey(String shareId) => 'share-owner:$shareId';

  /// The exact payload for the selected series. Excluded details are removed
  /// from items and from changed occurrences.
  ShareBuild build(List<ScheduleSeries> series, Map<String, String> categoryNames, SharedFieldPolicy policy) {
    if (series.isEmpty) return const ShareBuild.failed(ShareBuildProblem.nothingSelected);
    if (series.length > 250) return const ShareBuild.failed(ShareBuildProblem.tooMany);
    final payload = SharePayload(
      sharedFieldPolicy: policy,
      items: [
        for (final s in series)
          ShareItem(
            sourceItemId: s.id,
            revision: s.revision,
            title: s.title,
            categoryLabel: s.categoryId == null ? null : categoryNames[s.categoryId],
            time: s.time,
            recurrence: s.recurrence,
            details: policy.apply(s.details),
            exceptions: [
              for (final e in s.exceptions)
                e.replacement == null
                    ? e
                    : OccurrenceException(
                        originalKey: e.originalKey,
                        action: e.action,
                        replacement: OccurrenceReplacement(
                          title: e.replacement!.title,
                          time: e.replacement!.time,
                          details: policy.apply(e.replacement!.details),
                        ),
                      ),
            ],
          ),
      ],
    );
    final errors = _validator.validate(payload.toJson());
    if (errors.any((e) => e.code == 'payload_too_large')) return const ShareBuild.failed(ShareBuildProblem.tooLarge);
    if (errors.any((e) => e.code == 'too_many')) return const ShareBuild.failed(ShareBuildProblem.tooMany);
    if (errors.isNotEmpty) return const ShareBuild.failed(ShareBuildProblem.invalid);
    return ShareBuild.ok(payload);
  }

  /// Persists the secret and the request first, so an uncertain response can
  /// be retried with the same key and secret instead of creating a second link.
  Future<CreatedShare> create(SharePayload payload, {required Duration validity}) async {
    // Only this explicit fresh-create path may establish an online identity.
    final ownerId = await _api.prepareCreateOwner();
    if (ownerId.isEmpty) throw const ShareApiException(status: 401, code: 'share_owner_unavailable');
    final key = _newId();
    final secret = ShareSecret.generate();
    final now = _clock().toUtc();
    await _secrets.write(pendingSecretKey(key), secret.token);
    await _db.transaction(() async {
      await _db.into(_db.pendingShareCreations).insert(PendingShareCreationsCompanion.insert(
            idempotencyKey: key,
            payloadJson: jsonEncode(payload.toJson()),
            expiresAt: now.add(validity),
            createdAt: now,
          ));
      await _db.writeValue(pendingOwnerKey(key), ownerId);
    });
    return retry(key);
  }

  Future<CreatedShare> retry(String idempotencyKey) async {
    final pending = await (_db.select(_db.pendingShareCreations)
          ..where((t) => t.idempotencyKey.equals(idempotencyKey)))
        .getSingle();
    final ownerId = await _db.readValue(pendingOwnerKey(idempotencyKey));
    if (ownerId == null || ownerId.isEmpty) {
      // Never infer ownership for legacy/partially recovered attempts: they
      // may already have been accepted under an identity we no longer hold.
      throw const ShareApiException(status: 401, code: 'share_owner_unavailable');
    }
    final token = await _secrets.read(pendingSecretKey(idempotencyKey));
    final secret = token == null ? null : ShareSecret.tryParse(token);
    if (secret == null) {
      await discard(idempotencyKey);
      throw const ShareApiException(status: 0, code: 'secret_unavailable');
    }
    final OwnedShare share;
    try {
      share = await _api.create(
        expectedOwnerId: ownerId,
        payload: jsonDecode(pending.payloadJson) as Map<String, Object?>,
        tokenDigest: secret.digest,
        expiresAt: pending.expiresAt.toUtc(),
        idempotencyKey: idempotencyKey,
      );
    } on ShareApiException catch (e) {
      // Definite rejections free the attempt; uncertain outcomes and expired
      // replays stay pending for an explicit retry or discard.
      if (!e.uncertain && e.status != 401 && e.status != 403 && e.status != 429 && e.code != 'idempotency_expired') {
        await discard(idempotencyKey);
      }
      rethrow;
    }
    await _secrets.write(shareSecretKey(share.shareId), secret.token);
    await _db.transaction(() async {
      await _saveOwned(share);
      await _db.writeValue(ownedOwnerKey(share.shareId), ownerId);
      await (_db.delete(_db.pendingShareCreations)..where((t) => t.idempotencyKey.equals(idempotencyKey))).go();
      await (_db.delete(_db.keyValues)..where((t) => t.key.equals(pendingOwnerKey(idempotencyKey)))).go();
    });
    await _secrets.delete(pendingSecretKey(idempotencyKey));
    return CreatedShare(share, _link(share.shareId, secret.token));
  }

  Future<List<PendingShareRow>> pending() => _db.select(_db.pendingShareCreations).get();

  Future<void> discard(String idempotencyKey) async {
    await _db.transaction(() async {
      await (_db.delete(_db.pendingShareCreations)..where((t) => t.idempotencyKey.equals(idempotencyKey))).go();
      await (_db.delete(_db.keyValues)..where((t) => t.key.equals(pendingOwnerKey(idempotencyKey)))).go();
    });
    await _secrets.delete(pendingSecretKey(idempotencyKey));
  }

  /// The bearer link composed from the locally kept secret, if still here.
  Future<Uri?> linkFor(String shareId) async {
    final token = await _secrets.read(shareSecretKey(shareId));
    return token == null ? null : _link(shareId, token);
  }

  /// Revokes, then reads the exact status back before reporting success.
  Future<OwnedShare> revoke(String shareId) async {
    await _api.revoke(shareId);
    final status = await _api.get(shareId);
    await _saveOwned(status);
    if (status.revokedAt != null) await _secrets.delete(shareSecretKey(shareId));
    return status;
  }

  /// Refreshes local owner metadata from the server (newest first).
  Future<void> refresh() async {
    // The list only returns the calling identity's links.
    final ownerId = await _api.currentOwnerId();
    // First visits have no online identity yet. Only Send link may create
    // one; an empty local list is not an authentication failure.
    if (ownerId == null || ownerId.isEmpty) return;
    String? cursor;
    var pages = 0;
    do {
      final page = await _api.list(cursor: cursor);
      await _db.transaction(() async {
        for (final share in page.items) {
          await _saveOwned(share);
          await _db.writeValue(ownedOwnerKey(share.shareId), ownerId);
        }
      });
      cursor = page.nextCursor;
    } while (cursor != null && ++pages < 10);
  }

  Uri _link(String shareId, String token) => ShareLink(host: _config.shareHost, shareId: shareId, token: token).toUri();

  Future<void> _saveOwned(OwnedShare s) => _db.into(_db.ownedShareLinks).insertOnConflictUpdate(OwnedShareLinksCompanion.insert(
        shareId: s.shareId,
        snapshotVersion: s.snapshotVersion,
        itemCount: s.itemCount,
        categoryLabelsJson: jsonEncode(s.categoryLabels),
        routePath: s.routePath,
        createdAt: s.createdAt,
        expiresAt: s.expiresAt,
        revokedAt: Value(s.revokedAt),
      ));
}

final shareSecretStoreProvider = Provider<ShareSecretStore>((ref) => SecureShareSecretStore());

final sharePayloadValidatorProvider = Provider<SharePayloadValidator>(
  (ref) => SharePayloadValidator(ref.watch(zoneResolverProvider), ref.watch(occurrenceEngineProvider)),
);

/// Lazy: ordinary offline use never initializes a backend session.
final shareApiProvider = Provider<ShareApi>((ref) => configuredShareApi(
  ref.watch(sharingConfigProvider), ref.watch(shareSecretStoreProvider)));

final shareSenderProvider = Provider<ShareSender>((ref) => ShareSender(
      db: ref.watch(databaseProvider),
      api: ref.watch(shareApiProvider),
      secrets: ref.watch(shareSecretStoreProvider),
      config: ref.watch(sharingConfigProvider),
      validator: ref.watch(sharePayloadValidatorProvider),
      clock: ref.watch(clockProvider),
      newId: ref.watch(idGeneratorProvider),
    ));

final ownedSharesProvider = StreamProvider<List<OwnedShareLinkRow>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.ownedShareLinks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
});
