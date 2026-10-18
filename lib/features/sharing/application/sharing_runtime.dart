import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/share_api.dart';
import '../../privacy/domain/backend_deletion.dart';
import '../data/share_secret_store.dart';
import 'sharing_config.dart';

/// The online identity uses the same platform-protected adapter as share
/// secrets, never preferences or the schedule database.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage(this._store);
  final ShareSecretStore _store;
  static const _key = 'schediel:backend-session';
  @override Future<void> initialize() async {}
  @override Future<bool> hasAccessToken() async => await _store.read(_key) != null;
  @override Future<String?> accessToken() => _store.read(_key);
  @override Future<void> persistSession(String persistSessionString) => _store.write(_key, persistSessionString);
  @override Future<void> removePersistedSession() => _store.delete(_key);
}

/// Constructing a screen/provider does not initialize auth or make a network
/// call. The first explicit online operation prepares the SDK. Only management
/// operations subsequently create an anonymous session; resolve is public.
class DeferredShareApi implements ShareApi, BackendDataApi {
  DeferredShareApi(this._createApi);
  final Future<ShareApi> Function() _createApi;
  Future<ShareApi>? _ready;
  Future<ShareApi> _api() async {
    try {
      return await (_ready ??= _createApi());
    } on Object {
      _ready = null;
      throw const ShareApiException(status: 0, code: 'network');
    }
  }
  @override Future<ResolvedShare> resolve({required String shareId, required String token}) async =>
      (await _api()).resolve(shareId: shareId, token: token);
  @override Future<String> prepareCreateOwner() async => (await _api()).prepareCreateOwner();
  @override Future<String?> currentOwnerId() async => (await _api()).currentOwnerId();
  @override Future<OwnedShare> create({required String expectedOwnerId, required Map<String, Object?> payload, required String tokenDigest,
    required DateTime expiresAt, required String idempotencyKey}) async => (await _api()).create(
      expectedOwnerId: expectedOwnerId, payload: payload, tokenDigest: tokenDigest, expiresAt: expiresAt, idempotencyKey: idempotencyKey);
  @override Future<OwnedShare> get(String shareId) async => (await _api()).get(shareId);
  @override Future<OwnedShare> revoke(String shareId) async => (await _api()).revoke(shareId);
  @override Future<SharePage> list({String? cursor}) async => (await _api()).list(cursor: cursor);
  @override Future<BackendDeletion> deleteBackendData(String key, {required String expectedOwnerId}) async =>
      ((await _api()) as BackendDataApi).deleteBackendData(key, expectedOwnerId: expectedOwnerId);
  @override Future<BackendDeletion> deletionJob(String id) async => ((await _api()) as BackendDataApi).deletionJob(id);
}

ShareApi configuredShareApi(SharingConfig config, ShareSecretStore store) => DeferredShareApi(() async {
  if (!config.isConfigured) throw const ShareApiException(status: 0, code: 'sharing_unconfigured');
  final instance = await Supabase.initialize(url: config.apiUrl, publishableKey: config.publishableKey,
    debug: false, authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(store), detectSessionInUri: false,
    ));
  return SupabaseShareApi(instance.client);
});
