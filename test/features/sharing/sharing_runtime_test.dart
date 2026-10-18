import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/features/sharing/application/sharing_config.dart';
import 'package:schediel/features/sharing/application/sharing_runtime.dart';
import 'package:schediel/features/sharing/data/share_secret_store.dart';
import 'sharing_screens_test.dart' show PreviewApi, shareId;
void main() {
  test('session persistence uses protected storage, not schedule rows', () async {
    final store = MemoryShareSecretStore();
    final session = SecureSessionStorage(store);
    await session.initialize();
    expect(await session.hasAccessToken(), isFalse);
    await session.persistSession('synthetic-test-session');
    expect(await session.accessToken(), 'synthetic-test-session');
    expect(await session.hasAccessToken(), isTrue);
    await session.removePersistedSession();
    expect(await session.accessToken(), isNull);
  });
  test('backend setup is lazy and shared across online calls', () async {
    var setups = 0;
    final api = DeferredShareApi(() async { setups++; return PreviewApi(); });
    expect(setups, 0);
    await api.resolve(shareId: shareId, token: 'A' * 43);
    await api.resolve(shareId: shareId, token: 'A' * 43);
    expect(setups, 1);
  });
  test('only an owned HTTPS host and a complete backend configuration enable sharing', () {
    for (final host in ['', 'schediel.invalid', 'https://share.example', 'share.example/path', 'share.example?token=x', 'user@share.example']) {
      expect(SharingConfig(apiUrl:'https://api.example',publishableKey:'public-fixture',shareHost:host).isConfigured, isFalse, reason: host);
    }
    expect(const SharingConfig(apiUrl:'http://api.example',publishableKey:'key',shareHost:'share.example').isConfigured, isFalse);
    expect(const SharingConfig(apiUrl:'https://api.example',publishableKey:'',shareHost:'share.example').isConfigured, isFalse);
    expect(const SharingConfig(apiUrl:'https://api.example',publishableKey:'key',shareHost:'share.example').isConfigured, isTrue);
  });
}
