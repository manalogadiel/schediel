import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' show Scrollable;
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/features/privacy/data/privacy_repository.dart';
import 'package:schediel/features/privacy/domain/backend_deletion.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';
import 'package:schediel/features/sharing/application/sharing_config.dart';
import 'package:schediel/features/sharing/data/share_api.dart';
import '../../support/harness.dart';

const _config = SharingConfig(apiUrl: 'https://api.example', publishableKey: 'public-fixture', shareHost: 'share.example');

/// Every saved key is past the server's replay window; fresh keys succeed.
class _ExpiringApi implements BackendDataApi {
  final keys = <String>[];
  @override
  Future<String?> currentOwnerId() async => 'owner-a';
  @override
  Future<BackendDeletion> deleteBackendData(String key, {required String expectedOwnerId}) async {
    keys.add(key);
    if (keys.length == 1) throw const ShareApiException(status: 409, code: 'idempotency_expired');
    return _job;
  }

  @override
  Future<BackendDeletion> deletionJob(String id) async => _job;
  static final _job = BackendDeletion(deletionJobId: 'job-a', status: 'completed', requestedAt: DateTime.utc(2026, 11, 2),
      completedAt: DateTime.utc(2026, 11, 2), revokedShareCount: 0, deletedShareCount: 0);
}

/// The first key is expired; the fresh command's response is lost once.
class _ExpireThenLoseApi extends _ExpiringApi {
  @override
  Future<BackendDeletion> deleteBackendData(String key, {required String expectedOwnerId}) async {
    keys.add(key);
    if (keys.length == 1) throw const ShareApiException(status: 409, code: 'idempotency_expired');
    if (keys.length == 2) throw const ShareApiException(status: 0, code: 'network');
    return _ExpiringApi._job;
  }
}

void main() {
  appTest('privacy explains local storage and separates destructive local deletion', (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(ScheduleDraft(title:'Fixture',time:DateOnlySpec(
      startDate:LocalDate(2026,11,3),endDateExclusive:LocalDate(2026,11,4)))));
    await h.tapText('Settings'); await h.tapText('Privacy and data');
    expect(find.textContaining('not encrypted by Schediel'), findsOneWidget);
    expect(find.textContaining('Cloud AI scanning is disabled'), findsOneWidget);
    await h.tapText('Delete local schedules');
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll),hasLength(1));
    await h.tapText('Cancel');
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll),hasLength(1));
    await h.tapText('Delete local schedules'); await h.tapText('Delete schedules');
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll),isEmpty);
    expect(await h.run(() => h.db.select(h.db.categories).get()),hasLength(3));
  });

  appTest('deleting local schedules also removes the profile unless unticked', (h) async {
    Future<void> seedProfile() => h.run(() => h.db.into(h.db.profilePreferences).insertOnConflictUpdate(
          ProfilePreferencesCompanion.insert(id: const Value(1), displayName: const Value('Diel'), updatedAt: DateTime.utc(2026, 11, 2))));
    await seedProfile();
    await h.tapText('Settings'); await h.tapText('Privacy and data');
    await h.tapText('Delete local schedules');
    expect(find.text('Also remove profile name and photo'), findsOneWidget);
    await h.tapText('Delete schedules');
    expect(await h.run(() => h.db.select(h.db.profilePreferences).get()), isEmpty);
    await seedProfile();
    await h.tapText('Delete local schedules');
    await h.tapText('Also remove profile name and photo');
    await h.tapText('Delete schedules');
    expect(await h.run(() => h.db.select(h.db.profilePreferences).get()), hasLength(1));
  });

  final expiring = _ExpiringApi();
  appTest('an expired deletion request is only repeated after a new confirmation', (h) async {
    Finder list() => find.byType(Scrollable).first;
    Future<void> tapScrolled(String text) async {
      await h.tester.scrollUntilVisible(find.text(text), 150, scrollable: list());
      await h.tester.ensureVisible(find.text(text));
      await h.settle();
      await h.tapText(text);
    }
    await h.tapText('Settings'); await h.tapText('Privacy and data');
    await tapScrolled('Delete my backend data'); await h.tapText('Delete backend data');
    expect(expiring.keys, hasLength(1));
    await h.tester.scrollUntilVisible(find.textContaining("can't be confirmed"), 150, scrollable: list());
    expect(find.textContaining("can't be confirmed"), findsOneWidget);
    await tapScrolled('Request deletion again');
    expect(expiring.keys, hasLength(1), reason: 'nothing is sent before confirmation');
    await h.tapText('Cancel');
    expect(expiring.keys, hasLength(1));
    await tapScrolled('Request deletion again'); await h.tapText('Delete backend data');
    expect(expiring.keys, hasLength(2));
    expect(expiring.keys.last, isNot(expiring.keys.first));
    await h.tester.scrollUntilVisible(find.textContaining('Backend deletion: completed'), 150, scrollable: list());
    expect(find.textContaining('Backend deletion: completed'), findsOneWidget);
  }, overrides: [sharingConfigProvider.overrideWithValue(_config), backendDataApiProvider.overrideWithValue(expiring)]);

  final lossy = _ExpireThenLoseApi();
  appTest('after a lost response the fresh deletion request is replayed, not replaced', (h) async {
    Finder list() => find.byType(Scrollable).first;
    Future<void> tapScrolled(String text) async {
      await h.tester.scrollUntilVisible(find.text(text), 150, scrollable: list());
      await h.tester.ensureVisible(find.text(text));
      await h.settle();
      await h.tapText(text);
    }
    await h.tapText('Settings'); await h.tapText('Privacy and data');
    await tapScrolled('Delete my backend data'); await h.tapText('Delete backend data');
    await tapScrolled('Request deletion again'); await h.tapText('Delete backend data');
    expect(lossy.keys, hasLength(2));
    await tapScrolled('Delete my backend data'); await h.tapText('Delete backend data');
    expect(lossy.keys, hasLength(3));
    expect(lossy.keys[2], lossy.keys[1]);
  }, overrides: [sharingConfigProvider.overrideWithValue(_config), backendDataApiProvider.overrideWithValue(lossy)]);
}
