import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Protected storage for share bearer secrets (spec 13.4). Secrets never go
/// to the database, logs or the backend.
abstract class ShareSecretStore {
  Future<void> write(String key, String token);

  Future<String?> read(String key);

  Future<void> delete(String key);
}

class SecureShareSecretStore implements ShareSecretStore {
  SecureShareSecretStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String token) => _storage.write(key: key, value: token);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory store for tests and hosts without secure storage.
class MemoryShareSecretStore implements ShareSecretStore {
  final values = <String, String>{};

  @override
  Future<void> write(String key, String token) async => values[key] = token;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> delete(String key) async => values.remove(key);
}
