import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/sharing/application/share_sender.dart';
import 'package:schediel/features/sharing/application/sharing_config.dart';
import 'package:schediel/features/sharing/data/share_api.dart';
import 'package:schediel/features/sharing/data/share_secret_store.dart';
import 'package:schediel/features/sharing/domain/share_link.dart';
import 'package:schediel/features/sharing/domain/share_payload.dart';

const shareId = '6f1c2b1e-9d3a-4c55-8e21-0a7b3c4d5e6f';

class FakeShareApi implements ShareApi {
  FakeShareApi(this.onCreate);

  final Future<void> Function(String key, String digest) onCreate;
  final creates = <(String, String, DateTime)>[];
  Object? failNext;
  String? ownerId = 'owner-a';
  int preparations = 0;
  int signIns = 0;

  @override
  Future<String?> currentOwnerId() async => ownerId;

  @override
  Future<String> prepareCreateOwner() async {
    preparations++;
    if (ownerId == null) {
      signIns++;
      ownerId = 'owner-b';
    }
    return ownerId!;
  }

  @override
  Future<OwnedShare> create({
    required Map<String, Object?> payload,
    required String tokenDigest,
    required DateTime expiresAt,
    required String idempotencyKey,
    required String expectedOwnerId,
  }) async {
    if (ownerId != expectedOwnerId) {
      throw const ShareApiException(status: 401, code: 'share_owner_unavailable');
    }
    creates.add((idempotencyKey, tokenDigest, expiresAt));
    await onCreate(idempotencyKey, tokenDigest);
    final fail = failNext;
    if (fail != null) {
      failNext = null;
      throw fail;
    }
    return OwnedShare(
      shareId: shareId,
      snapshotVersion: 1,
      routePath: '/s/$shareId',
      createdAt: DateTime.utc(2026, 11, 2),
      expiresAt: expiresAt,
      revokedAt: null,
      itemCount: (payload['items'] as List).length,
      categoryLabels: const ['Fixture school'],
    );
  }

  List<OwnedShare> listed = const [];

  @override
  Future<SharePage> list({String? cursor}) async => SharePage(items: listed, nextCursor: null);

  @override
  Future<OwnedShare> get(String shareId) => throw UnimplementedError();

  @override
  Future<OwnedShare> revoke(String shareId) => throw UnimplementedError();

  @override
  Future<ResolvedShare> resolve({required String? shareId, required String token}) => throw UnimplementedError();
}

void main() {
  final now = DateTime.utc(2026, 11, 2, 0, 0);
  late ZoneResolver zones;
  late AppDatabase db;
  late MemoryShareSecretStore secrets;
  late SharePayloadValidator validator;
  var ids = 0;

  setUpAll(() => zones = ZoneResolver.initialized());

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory(), clock: () => now);
    secrets = MemoryShareSecretStore();
    validator = SharePayloadValidator(zones, OccurrenceEngine(zones));
  });

  tearDown(() => db.close());

  ShareSender sender(ShareApi api) => ShareSender(
        db: db,
        api: api,
        secrets: secrets,
        config: const SharingConfig(apiUrl: 'https://api.example', publishableKey: 'key', shareHost: 'share.example'),
        validator: validator,
        clock: () => now,
        newId: () => '00000000-0000-4000-8000-${(++ids).toString().padLeft(12, '0')}',
      );

  ScheduleSeries weekly({String id = '00000000-0000-4000-8000-0000000000aa'}) => ScheduleSeries(
        id: id,
        revision: 2,
        title: 'Fixture class',
        categoryId: 'school',
        time: TimedSpec(
          startDate: LocalDate(2026, 11, 2),
          startTime: LocalTime(9, 0),
          timeZone: 'Asia/Manila',
          endTime: LocalTime(10, 30),
          endDayOffset: 0,
        ),
        recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [1, 3]),
        details: const ScheduleDetails(location: 'Fixture room', professor: 'Fixture person', notes: 'Private note'),
        exceptions: [
          OccurrenceException(
            originalKey: LocalDate(2026, 11, 4),
            action: ExceptionAction.override,
            replacement: OccurrenceReplacement(
              title: 'Fixture class (moved)',
              time: TimedSpec(
                startDate: LocalDate(2026, 11, 5),
                startTime: LocalTime(13, 0),
                timeZone: 'Asia/Manila',
                endTime: LocalTime(14, 0),
                endDayOffset: 0,
              ),
              details: const ScheduleDetails(location: 'Fixture hall', professor: 'Fixture person'),
            ),
          ),
        ],
      );

  const policy = SharedFieldPolicy(location: true, professor: false, subtitle: true, notes: false);

  test('builds a valid payload with only the selected fields and category labels', () {
    final build = sender(FakeShareApi((_, _) async {})).build([weekly()], const {'school': 'Fixture school'}, policy);
    expect(build.problem, isNull);
    final json = build.payload!.toJson();
    expect(validator.validate(json), isEmpty);
    final item = (json['items'] as List).single as Map;
    expect(item['categoryLabel'], 'Fixture school');
    expect(item['details'], {'location': 'Fixture room', 'professor': null, 'subtitle': null, 'notes': null});
    final replacement = ((item['exceptions'] as List).single as Map)['replacement'] as Map;
    expect((replacement['details'] as Map)['professor'], isNull);
    expect((replacement['details'] as Map)['location'], 'Fixture hall');
  });

  test('explains instead of silently dropping schedules when the payload is too large', () {
    final many = [
      for (var i = 0; i < 251; i++)
        weekly(id: '00000000-0000-4000-8000-${(1000 + i).toString().padLeft(12, '0')}'),
    ];
    final build = sender(FakeShareApi((_, _) async {})).build(many, const {}, policy);
    expect(build.payload, isNull);
    expect(build.problem, ShareBuildProblem.tooMany);
  });

  test('stores the secret and the pending request before calling the server', () async {
    late FakeShareApi api;
    api = FakeShareApi((key, digest) async {
      final pending = await db.select(db.pendingShareCreations).get();
      expect(pending.single.idempotencyKey, key);
      expect(await db.readValue(ShareSender.pendingOwnerKey(key)), 'owner-a');
      final token = await secrets.read(ShareSender.pendingSecretKey(key));
      expect(ShareSecret.tryParse(token!)!.digest, digest);
    });
    final s = sender(api);
    final created = await s.create(s.build([weekly()], const {}, policy).payload!, validity: const Duration(days: 7));

    expect(created.link.toString(), startsWith('https://share.example/s/#'));
    final token = created.link.fragment;
    expect(ShareSecret.tryParse(token)!.digest, api.creates.single.$2);
    expect(api.creates.single.$3, now.add(const Duration(days: 7)));
    expect(await db.select(db.pendingShareCreations).get(), isEmpty);
    expect((await db.select(db.ownedShareLinks).get()).single.shareId, shareId);
    expect(await secrets.read(ShareSender.shareSecretKey(shareId)), token);
    expect(await s.linkFor(shareId), created.link);
    // Backend deletion is per identity, so the creating identity is recorded.
    expect(await db.readValue(ShareSender.ownedOwnerKey(shareId)), 'owner-a');
  });

  test('refresh records the listing identity as the owner of each listed link', () async {
    final api = FakeShareApi((_, _) async {})
      ..ownerId = 'owner-b'
      ..listed = [
        OwnedShare(shareId: 'listed-1', snapshotVersion: 1, routePath: '/s/listed-1', createdAt: now,
            expiresAt: now.add(const Duration(days: 1)), revokedAt: null, itemCount: 1, categoryLabels: const []),
      ];
    await sender(api).refresh();
    expect(await db.readValue(ShareSender.ownedOwnerKey('listed-1')), 'owner-b');
  });

  test('a retry after an uncertain failure reuses the same key and secret', () async {
    final api = FakeShareApi((_, _) async {})..failNext = const ShareApiException(status: 0, code: 'network');
    final s = sender(api);
    final payload = s.build([weekly()], const {}, policy).payload!;
    await expectLater(s.create(payload, validity: const Duration(days: 1)), throwsA(isA<ShareApiException>()));
    final pending = await s.pending();
    expect(pending, hasLength(1));

    final created = await s.retry(pending.single.idempotencyKey);
    expect(api.creates, hasLength(2));
    expect(api.creates[1].$1, api.creates[0].$1);
    expect(api.creates[1].$2, api.creates[0].$2);
    expect(created.share.shareId, shareId);
    expect(await s.pending(), isEmpty);
    expect(await db.readValue(ShareSender.pendingOwnerKey(pending.single.idempotencyKey)), isNull);
  });

  for (final replacement in <String?>[null, 'owner-b']) {
    test('uncertain retry refuses ${replacement == null ? 'lost' : 'changed'} owner without creating a link', () async {
      final api = FakeShareApi((_, _) async {})
        ..failNext = const ShareApiException(status: 0, code: 'network');
      final firstSender = sender(api);
      final payload = firstSender.build([weekly()], const {}, policy).payload!;
      await expectLater(firstSender.create(payload, validity: const Duration(days: 1)),
          throwsA(isA<ShareApiException>()));
      final pending = (await firstSender.pending()).single;
      final token = await secrets.read(ShareSender.pendingSecretKey(pending.idempotencyKey));
      api.ownerId = replacement;

      // A new sender must use durable ownership, not in-memory state.
      await expectLater(sender(api).retry(pending.idempotencyKey),
          throwsA(isA<ShareApiException>().having((e) => e.code, 'code', 'share_owner_unavailable')));
      expect(api.creates, hasLength(1));
      expect(api.preparations, 1);
      expect(api.signIns, 0);
      expect((await firstSender.pending()).single.idempotencyKey, pending.idempotencyKey);
      expect(await secrets.read(ShareSender.pendingSecretKey(pending.idempotencyKey)), token);
    });
  }

  test('explicit discard removes the pending owner binding', () async {
    final api = FakeShareApi((_, _) async {})..failNext = const ShareApiException(status: 0, code: 'network');
    final s = sender(api);
    await expectLater(s.create(s.build([weekly()], const {}, policy).payload!, validity: const Duration(days: 1)),
        throwsA(isA<ShareApiException>()));
    final key = (await s.pending()).single.idempotencyKey;
    expect(await db.readValue(ShareSender.pendingOwnerKey(key)), 'owner-a');
    await s.discard(key);
    expect(await db.readValue(ShareSender.pendingOwnerKey(key)), isNull);
    expect(await s.pending(), isEmpty);
    expect(await secrets.read(ShareSender.pendingSecretKey(key)), isNull);
  });

  test('a rejected request discards the pending creation and its secret', () async {
    final api = FakeShareApi((_, _) async {})
      ..failNext = const ShareApiException(status: 422, code: 'validation_failed');
    final s = sender(api);
    final payload = s.build([weekly()], const {}, policy).payload!;
    await expectLater(s.create(payload, validity: const Duration(days: 1)), throwsA(isA<ShareApiException>()));
    expect(await s.pending(), isEmpty);
    expect(secrets.values, isEmpty);
  });
}
