import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/schedule/validation.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/privacy/data/privacy_repository.dart';
import 'package:schediel/features/privacy/domain/backend_deletion.dart';
import 'package:schediel/features/reminders/domain/alert_rule.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';
import 'package:schediel/features/sharing/application/share_sender.dart';
import 'package:schediel/features/sharing/data/share_api.dart';
import 'package:schediel/features/sharing/data/share_secret_store.dart';
class FakeDeletionApi implements BackendDataApi {
  bool complete = false;
  ShareApiException? getError;
  final expiredKeys = <String>{};
  final calls = <String>[];
  String? ownerId = 'owner-a';
  @override Future<String?> currentOwnerId() async => ownerId;
  BackendDeletion job() => BackendDeletion(deletionJobId:'job-a',status:complete?'completed':'queued',
    requestedAt:DateTime.utc(2026,11,2),completedAt:complete?DateTime.utc(2026,11,2):null,revokedShareCount:1,deletedShareCount:complete?1:0);
  final owners = <String>[];
  @override Future<BackendDeletion> deleteBackendData(String key, {required String expectedOwnerId}) async {
    calls.add('delete:$key');
    owners.add(expectedOwnerId);
    if (expiredKeys.contains(key)) throw const ShareApiException(status:409,code:'idempotency_expired');
    return job();
  }
  @override Future<BackendDeletion> deletionJob(String id) async {
    calls.add('get:$id');
    if (getError != null) throw getError!;
    return job();
  }
}
/// The server commits the command, but the response never arrives.
class _LossyApi implements BackendDataApi {
  _LossyApi(this.inner, this.fail);
  final FakeDeletionApi inner;
  final bool Function() fail;
  @override Future<BackendDeletion> deleteBackendData(String key, {required String expectedOwnerId}) async {
    final result = await inner.deleteBackendData(key, expectedOwnerId: expectedOwnerId);
    if (fail()) throw const ShareApiException(status:0,code:'network');
    return result;
  }
  @override Future<BackendDeletion> deletionJob(String id) => inner.deletionJob(id);
  @override Future<String?> currentOwnerId() => inner.currentOwnerId();
}
void main() {
  late AppDatabase db;
  late ScheduleRepository schedules;
  late PrivacyRepository privacy;
  late FakeDeletionApi api;
  final secrets = MemoryShareSecretStore();
  var id = 0;
  final now = DateTime.utc(2026,11,2);
  setUp(() {
    final zones = ZoneResolver.initialized(); final engine = OccurrenceEngine(zones);
    db = AppDatabase(NativeDatabase.memory(),clock:()=>now);
    schedules = ScheduleRepository(db,validator:SeriesValidator(zones,engine),engine:engine,clock:()=>now,newId:()=> 'id-${++id}');
    api = FakeDeletionApi();
    privacy = PrivacyRepository(db,schedules,secrets,api,newId:()=> 'key-${++id}');
  });
  tearDown(()=>db.close());
  Future<void> seed() => schedules.create(ScheduleDraft(title:'Fixture',time:DateOnlySpec(
    startDate:LocalDate(2026,11,3),endDateExclusive:LocalDate(2026,11,4))), alerts:const[
      AlertPreference(kind:AlertKind.notification,enabled:false,offsetMinutes:0)]).then((_){});

  Future<void> seedShares(String suffix, {String? owner = 'owner-a'}) async {
    await db.into(db.ownedShareLinks).insert(OwnedShareLinksCompanion.insert(
      shareId:'share-$suffix',snapshotVersion:1,itemCount:1,categoryLabelsJson:'[]',routePath:'/s/share-$suffix',
      createdAt:now,expiresAt:now.add(const Duration(days:7))));
    if (owner != null) await db.writeValue(ShareSender.ownedOwnerKey('share-$suffix'), owner);
    await db.into(db.pendingShareCreations).insert(PendingShareCreationsCompanion.insert(
      idempotencyKey:'pending-$suffix',payloadJson:'{}',createdAt:now,expiresAt:now.add(const Duration(days:7))));
    await secrets.write(ShareSender.shareSecretKey('share-$suffix'),'fixture');
    await secrets.write(ShareSender.pendingSecretKey('pending-$suffix'),'fixture');
  }

  test('R1 first completed readback after failure cleans only original scope', () async {
    await seed();
    await seedShares('old');
    api.complete = true;
    api.getError = const ShareApiException(status:0,code:'network');
    await expectLater(privacy.requestBackendDeletion(),throwsA(isA<ShareApiException>()));
    expect(await privacy.lastJobId(),'job-a');
    await seedShares('new');
    // A repository restart must retain the exact scope captured before POST.
    privacy = PrivacyRepository(db,schedules,secrets,api,newId:()=> 'key-${++id}');
    api.getError = null;
    await privacy.refreshBackendDeletion('job-a');
    expect((await db.select(db.ownedShareLinks).get()).map((r)=>r.shareId),['share-new']);
    expect((await db.select(db.pendingShareCreations).get()).map((r)=>r.idempotencyKey),['pending-old','pending-new']);
    expect(await secrets.read(ShareSender.shareSecretKey('share-old')),isNull);
    // Pending creates may commit after backend deletion; they are not covered.
    expect(await secrets.read(ShareSender.pendingSecretKey('pending-old')),isNotNull);
    expect(await secrets.read(ShareSender.shareSecretKey('share-new')),isNotNull);
    expect(await secrets.read(ShareSender.pendingSecretKey('pending-new')),isNotNull);
    expect(await schedules.loadAll(),hasLength(1));
    await seedShares('later');
    await privacy.refreshBackendDeletion('job-a');
    expect(await db.select(db.ownedShareLinks).get(),hasLength(2));
    expect(await db.select(db.pendingShareCreations).get(),hasLength(3));
    expect(await secrets.read(ShareSender.shareSecretKey('share-later')),isNotNull);
    expect(await secrets.read(ShareSender.pendingSecretKey('pending-later')),isNotNull);
  });

  test('R3 lost deletion response retries the same key, then an expired key needs a fresh confirmed request', () async {
    await seedShares('old');
    var fail = true;
    final lossy = _LossyApi(api, () => fail);
    privacy = PrivacyRepository(db,schedules,secrets,lossy,newId:()=> 'key-${++id}');
    await expectLater(privacy.requestBackendDeletion(),throwsA(isA<ShareApiException>()));
    final firstKey = api.calls.single.substring('delete:'.length);
    expect(await privacy.lastJobId(),isNull);
    // A plain retry replays the same command (server idempotency) ...
    await expectLater(privacy.requestBackendDeletion(),throwsA(isA<ShareApiException>()));
    expect(api.calls.last,'delete:$firstKey');
    // ... until the server's replay window has expired.
    fail = false;
    api.expiredKeys.add(firstKey);
    await expectLater(privacy.requestBackendDeletion(),throwsA(isA<BackendDeletionExpired>()));
    expect(api.calls.last,'delete:$firstKey');
    await seedShares('new');
    api.complete = true;
    final job = await privacy.requestBackendDeletion(fresh:true);
    expect(job.status,'completed');
    expect(api.calls.where((c) => c.startsWith('delete:')).last,isNot('delete:$firstKey'));
    // The fresh command covers links owned at the time of the new request.
    expect(await db.select(db.ownedShareLinks).get(),isEmpty);
    expect(await db.select(db.pendingShareCreations).get(),hasLength(2));
  });

  test('cleanup covers only links recorded for the identity that sent the deletion', () async {
    await seedShares('mine');
    await seedShares('earlier', owner: 'owner-old');
    await seedShares('unknown', owner: null);
    api.complete = true;
    await privacy.requestBackendDeletion();
    expect((await db.select(db.ownedShareLinks).get()).map((r) => r.shareId), unorderedEquals(['share-earlier', 'share-unknown']));
    expect(await secrets.read(ShareSender.shareSecretKey('share-mine')), isNull);
    expect(await db.readValue(ShareSender.ownedOwnerKey('share-mine')), isNull);
    // Links of another identity are still live on the server: keep their secrets.
    expect(await secrets.read(ShareSender.shareSecretKey('share-earlier')), isNotNull);
    expect(await secrets.read(ShareSender.shareSecretKey('share-unknown')), isNotNull);
  });

  test('deletion never signs in and saves nothing without an online identity', () async {
    api.ownerId = null;
    await expectLater(privacy.requestBackendDeletion(), throwsA(isA<ShareApiException>()));
    expect(api.calls, isEmpty);
    api.ownerId = 'owner-a';
    await privacy.requestBackendDeletion();
    expect(api.calls.first, startsWith('delete:'));
    // The command is pinned to the identity its scope was computed for.
    expect(api.owners, ['owner-a']);
  });

  test('a saved command is not replayed under a different identity', () async {
    await seedShares('mine');
    var fail = true;
    privacy = PrivacyRepository(db,schedules,secrets,_LossyApi(api, () => fail),newId:()=> 'key-${++id}');
    await expectLater(privacy.requestBackendDeletion(), throwsA(isA<ShareApiException>()));
    expect(api.calls, hasLength(1));
    fail = false;
    api.ownerId = 'owner-b';
    await expectLater(privacy.requestBackendDeletion(), throwsA(isA<BackendDeletionExpired>()));
    expect(api.calls, hasLength(1), reason: 'nothing sent for the replaced identity');
  });

  test('delete local schedules is atomic and queues cancellation but keeps categories and online data', () async {
    await seed();
    await db.writeValue('backend-deletion-job','job-existing');
    await privacy.deleteLocalSchedules();
    expect(await schedules.loadAll(),isEmpty);
    expect(await db.select(db.alertRules).get(),isEmpty);
    expect(await db.select(db.categories).get(),hasLength(3));
    expect(await db.select(db.reconciliationOutbox).get(),hasLength(2));
    expect(await db.readValue('backend-deletion-job'),'job-existing');
    expect(api.calls,isEmpty);
  });
  test('reopening completed deletion status does not erase newer local share metadata', () async {
    await privacy.requestBackendDeletion();
    api.complete = true;
    await privacy.refreshBackendDeletion('job-a');
    await db.into(db.ownedShareLinks).insert(OwnedShareLinksCompanion.insert(
      shareId:'new-share',snapshotVersion:1,itemCount:1,categoryLabelsJson:'[]',routePath:'/s/new-share',
      createdAt:now,expiresAt:now.add(const Duration(days:7))));
    await privacy.refreshBackendDeletion('job-a');
    expect(await db.select(db.ownedShareLinks).get(),hasLength(1));
  });

  test('backend deletion reads job progress and never deletes local schedules', () async {
    await seed();
    final job = await privacy.requestBackendDeletion();
    expect(job.status,'queued');
    expect(api.calls,hasLength(2));
    expect(api.calls.last,'get:job-a');
    expect(await privacy.lastJobId(),'job-a');
    expect(await schedules.loadAll(),hasLength(1));
    api.complete = true;
    final done = await privacy.refreshBackendDeletion('job-a');
    expect(done.status,'completed');
    expect(done.deletedShareCount,1);
    expect(await schedules.loadAll(),hasLength(1));
  });
}
