import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/sharing/application/share_sender.dart';
import 'package:schediel/features/sharing/application/sharing_config.dart';
import 'package:schediel/features/sharing/data/share_api.dart';
import 'package:schediel/features/sharing/data/share_secret_store.dart';
import '../../support/harness.dart';
import 'sharing_screens_test.dart' show PreviewApi, config, shareId;

class ManagementApi extends PreviewApi {
  final actions = <String>[];
  bool revoked = false;
  OwnedShare metadata() => OwnedShare(shareId:shareId, snapshotVersion:1, routePath:'/s/$shareId',
    createdAt:DateTime.utc(2026,11,1),expiresAt:DateTime.utc(2026,11,8),
    revokedAt:revoked ? DateTime.utc(2026,11,2) : null,itemCount:1,categoryLabels:const ['School']);
  @override Future<SharePage> list({String? cursor}) async { actions.add('list'); return SharePage(items:[metadata()],nextCursor:null); }
  @override Future<OwnedShare> get(String id) async { actions.add('get:$id'); return metadata(); }
  @override Future<OwnedShare> revoke(String id) async { actions.add('revoke:$id'); revoked = true; return metadata(); }
}
void main() {
  final fresh = _NoSessionApi();
  appTest('first visit to Shared links stays empty without signing in or listing', (h) async {
    await h.tapText('Settings'); await h.tapText('Shared links');
    expect(find.text('No shared links in the local list.'), findsOneWidget);
    expect(find.text('Could not verify this sharing session'), findsNothing);
    expect(fresh.actions, isEmpty); expect(fresh.preparations, 0);
  }, overrides: [sharingConfigProvider.overrideWithValue(config), shareApiProvider.overrideWithValue(fresh)]);

  final api = ManagementApi();
  appTest('shared-link revocation confirms, reads exact owner status and removes local secret', (h) async {
    await h.run(() => h.read(shareSecretStoreProvider).write(ShareSender.shareSecretKey(shareId), 'A'*43));
    await h.tapText('Settings');
    await h.tapText('Shared links');
    expect(find.text('Active at last check'), findsOneWidget);
    await h.tapText('Revoke');
    expect(api.revoked, isFalse);
    await h.tapText('Revoke link');
    expect(find.text('Revoked'), findsOneWidget);
    expect(api.actions, containsAllInOrder(['list','revoke:$shareId','get:$shareId']));
    expect(await h.run(() => h.read(shareSecretStoreProvider).read(ShareSender.shareSecretKey(shareId))), isNull);
  }, overrides:[sharingConfigProvider.overrideWithValue(config),shareApiProvider.overrideWithValue(api),
    shareSecretStoreProvider.overrideWithValue(MemoryShareSecretStore())]);

  final owned = _OwnerChangedApi();
  final store = MemoryShareSecretStore();
  appTest('a saved attempt from an earlier identity is kept, explained and only discarded on confirmation', (h) async {
    const key = 'pending-fixture';
    await h.run(() async {
      await h.db.into(h.db.pendingShareCreations).insert(PendingShareCreationsCompanion.insert(
        idempotencyKey: key, payloadJson: '{}', createdAt: DateTime.utc(2026, 11, 2), expiresAt: DateTime.utc(2026, 11, 3)));
      await h.db.writeValue(ShareSender.pendingOwnerKey(key), 'owner-a');
      await store.write(ShareSender.pendingSecretKey(key), 'A' * 43);
    });
    await h.tapText('Settings');
    await h.tapText('Shared links');
    await h.tapText('Retry saved creation');
    expect(owned.creates, 0);
    expect(find.textContaining('belongs to an earlier online identity'), findsOneWidget);
    expect(await h.run(() => h.db.select(h.db.pendingShareCreations).get()), hasLength(1));
    await h.tapText('Discard attempt');
    await h.tapText('Cancel');
    expect(await h.run(() => h.db.select(h.db.pendingShareCreations).get()), hasLength(1));
  }, overrides:[sharingConfigProvider.overrideWithValue(config), shareApiProvider.overrideWithValue(owned),
    shareSecretStoreProvider.overrideWithValue(store)]);
}

class _NoSessionApi extends ManagementApi {
  int preparations = 0;
  @override Future<String?> currentOwnerId() async => null;
  @override Future<String> prepareCreateOwner() async { preparations++; throw StateError('Unexpected sign-in'); }
  @override Future<SharePage> list({String? cursor}) async {
    actions.add('list'); throw const ShareApiException(status: 401, code: 'unauthenticated');
  }
}

/// The current session belongs to another identity than the saved attempt.
class _OwnerChangedApi extends ManagementApi {
  int creates = 0;
  @override Future<OwnedShare> create({required String expectedOwnerId, required Map<String,Object?> payload, required String tokenDigest,
    required DateTime expiresAt, required String idempotencyKey}) async {
    if (expectedOwnerId != 'owner-b') throw const ShareApiException(status: 401, code: 'share_owner_unavailable');
    creates++;
    throw StateError('unexpected create');
  }
  @override Future<SharePage> list({String? cursor}) async => const SharePage(items: [], nextCursor: null);
}
