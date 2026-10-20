import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/router.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';
import 'package:schediel/features/sharing/application/share_sender.dart';
import 'package:schediel/features/sharing/application/sharing_config.dart';
import 'package:schediel/features/sharing/data/share_api.dart';
import 'package:schediel/features/sharing/data/share_secret_store.dart';
import 'package:schediel/features/sharing/domain/share_link.dart';
import 'package:schediel/features/sharing/presentation/sharing_screens.dart';
import '../../support/harness.dart';

const config = SharingConfig(apiUrl: 'https://api.example', publishableKey: 'public-fixture', shareHost: 'share.example');
const shareId = '6f1c2b1e-9d3a-4c55-8e21-0a7b3c4d5e6f';
class PreviewApi implements ShareApi {
  int resolves = 0;
  Object? error;
  Object? payloadOverride;
  @override
  Future<ResolvedShare> resolve({required String shareId, required String token}) async {
    resolves++;
    if (error != null) throw error!;
    return ResolvedShare(shareId: shareId, schemaVersion: '1.0', snapshotVersion: 1,
      createdAt: DateTime.utc(2026, 11, 1), expiresAt: DateTime.utc(2026, 11, 8), itemCount: 1,
      payload: payloadOverride ?? {'schemaVersion':'1.0', 'sharedFieldPolicy':{'location':false,'professor':false,'subtitle':false,'notes':false},
        'items':[{'sourceItemId':'00000000-0000-4000-8000-000000000001','revision':1,'title':'Shared fixture',
          'categoryLabel':'School', 'time':{'kind':'dateOnly','startDate':'2026-11-03','endDateExclusive':'2026-11-04'},
          'recurrence':null,'details':{'location':null,'professor':null,'subtitle':null,'notes':null},'exceptions':[]} ]});
  }
  @override Future<String> prepareCreateOwner() async => 'owner-a';
  @override Future<String?> currentOwnerId() async => 'owner-a';
  @override Future<OwnedShare> create({required String expectedOwnerId, required Map<String,Object?> payload, required String tokenDigest, required DateTime expiresAt, required String idempotencyKey}) => throw UnimplementedError();
  @override Future<OwnedShare> get(String shareId) => throw UnimplementedError();
  @override Future<SharePage> list({String? cursor}) => throw UnimplementedError();
  @override Future<OwnedShare> revoke(String shareId) => throw UnimplementedError();
}

class UncertainCreateApi extends PreviewApi {
  int creates = 0;
  @override Future<OwnedShare> create({required String expectedOwnerId, required Map<String,Object?> payload, required String tokenDigest,
    required DateTime expiresAt, required String idempotencyKey}) async {
    creates++;
    throw const ShareApiException(status:0,code:'network');
  }
}

void main() {
  final uncertain = UncertainCreateApi();
  appTest('uncertain link creation cannot be repeated as a fresh second link', (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(ScheduleDraft(title:'Fixture',time:DateOnlySpec(
      startDate:LocalDate(2026,11,3),endDateExclusive:LocalDate(2026,11,4)))));
    rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const CreateShareScreen()));
    await h.settle(); await h.tapText('Create link');
    expect(uncertain.creates,1);
    expect(h.tester.widget<FilledButton>(find.widgetWithText(FilledButton,'Create link')).onPressed,isNull);
    expect(find.text('Check saved attempts'),findsOneWidget);
  },overrides:[sharingConfigProvider.overrideWithValue(config),shareApiProvider.overrideWithValue(uncertain),
    shareSecretStoreProvider.overrideWithValue(MemoryShareSecretStore())]);

  appTest('online links stay off until a backend is configured; offline links can still be pasted', (h) async {
    rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const ShareOpenScreen()));
    await h.settle();
    expect(find.textContaining('Online links are not set up'), findsNothing);
    expect(find.textContaining('Paste a link or the whole message'), findsOneWidget);
    expect(find.text('Open preview'), findsOneWidget);
    expect(find.text('Add selected schedules'), findsNothing);
  });

  final api = PreviewApi();
  appTest('a shared link resolves to editable review but creates nothing before confirmation', (h) async {
    rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => ShareOpenScreen(
      initialLink: ShareLink(host: 'share.example', shareId: shareId, token: 'A' * 43))));
    await h.settle();
    expect(find.text('Shared fixture'), findsOneWidget);
    expect(find.text('Shared category: School'), findsOneWidget);
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    await h.tapText('Add selected schedules');
    final all = await h.run(h.read(scheduleRepositoryProvider).loadAll);
    expect(all.single.title, 'Shared fixture');
    expect(all.single.categoryId, isNull);
    expect(api.resolves, 1);
  }, overrides: [sharingConfigProvider.overrideWithValue(config), shareApiProvider.overrideWithValue(api)]);

  for (final (code, label) in [('link_expired','Shared link expired'),('link_revoked','Shared link revoked'),('not_found','Shared link unavailable'),('unsupported_schema_version','This link needs a newer version'),('rate_limited','Too many requests')]) {
    final failing = PreviewApi()..error = ShareApiException(status: code == 'not_found' ? 404 : 410, code: code);
    appTest('resolver $code is an honest state, never a fabricated preview', (h) async {
      rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => ShareOpenScreen(
        initialLink: ShareLink(host:'share.example',shareId:shareId,token:'A'*43))));
      await h.settle();
      expect(find.text(label), findsOneWidget);
      expect(find.text('Shared fixture'), findsNothing);
      expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    }, overrides: [sharingConfigProvider.overrideWithValue(config), shareApiProvider.overrideWithValue(failing)]);
  }

  final invalid = PreviewApi()..payloadOverride = {'schemaVersion':'1.0','items':[]};
  appTest('invalid server payload is rejected before review', (h) async {
    rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => ShareOpenScreen(
      initialLink: ShareLink(host:'share.example',shareId:shareId,token:'A'*43))));
    await h.settle();
    expect(find.text('Shared link unavailable'), findsOneWidget);
    expect(find.text('Add selected schedules'), findsNothing);
  }, overrides: [sharingConfigProvider.overrideWithValue(config), shareApiProvider.overrideWithValue(invalid)]);

  appTest('sender current-filter selection includes saved past entries, not only Today rows', (h) async {
    await h.run(() async {
      final repo = h.read(scheduleRepositoryProvider);
      await repo.create(ScheduleDraft(title:'Past school fixture',categoryId:'school',time:DateOnlySpec(
        startDate:LocalDate(2026,1,1),endDateExclusive:LocalDate(2026,1,2))));
      await repo.create(ScheduleDraft(title:'Work fixture',categoryId:'work',time:DateOnlySpec(
        startDate:LocalDate(2026,11,3),endDateExclusive:LocalDate(2026,11,4))));
    });
    rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const CreateShareScreen()));
    await h.settle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Past school fixture'), findsOneWidget);
    expect(find.textContaining('Past and ended'), findsOneWidget);
  }, overrides: [sharingConfigProvider.overrideWithValue(config)]);
}
