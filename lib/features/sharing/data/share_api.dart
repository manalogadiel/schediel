import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../privacy/domain/backend_deletion.dart';

/// Owner metadata for a share link (openapi.yaml ShareLink). No secret.
@immutable
class OwnedShare {
  const OwnedShare({
    required this.shareId,
    required this.snapshotVersion,
    required this.routePath,
    required this.createdAt,
    required this.expiresAt,
    required this.revokedAt,
    required this.itemCount,
    required this.categoryLabels,
  });

  factory OwnedShare.fromJson(Map<String, dynamic> json) => OwnedShare(
        shareId: json['shareId'] as String,
        snapshotVersion: (json['snapshotVersion'] as num).toInt(),
        routePath: json['routePath'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        revokedAt: json['revokedAt'] == null ? null : DateTime.parse(json['revokedAt'] as String),
        itemCount: (json['itemCount'] as num).toInt(),
        categoryLabels: [for (final l in json['categoryLabels'] as List) l as String],
      );

  final String shareId;
  final int snapshotVersion;
  final String routePath;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  final int itemCount;
  final List<String> categoryLabels;
}

@immutable
class SharePage {
  const SharePage({required this.items, required this.nextCursor});

  final List<OwnedShare> items;
  final String? nextCursor;
}

/// A resolved bearer link (openapi.yaml ResolvedShare). The payload is
/// validated again locally before it is shown.
@immutable
class ResolvedShare {
  const ResolvedShare({
    required this.shareId,
    required this.schemaVersion,
    required this.snapshotVersion,
    required this.createdAt,
    required this.expiresAt,
    required this.itemCount,
    required this.payload,
  });

  factory ResolvedShare.fromJson(Map<String, dynamic> json) => ResolvedShare(
        shareId: json['shareId'] as String,
        schemaVersion: json['schemaVersion'] as String,
        snapshotVersion: (json['snapshotVersion'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        itemCount: (json['itemCount'] as num).toInt(),
        payload: json['payload'],
      );

  final String shareId;
  final String schemaVersion;
  final int snapshotVersion;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int itemCount;
  final Object? payload;
}

/// A safe error from the sharing backend (openapi.yaml ErrorEnvelope), or a
/// network failure with [status] 0.
@immutable
class ShareApiException implements Exception {
  const ShareApiException({required this.status, required this.code, this.retryable = false, this.retryAfterSeconds});

  final int status;
  final String code;
  final bool retryable;
  final int? retryAfterSeconds;

  /// The outcome is unknown: the request may or may not have taken effect.
  bool get uncertain => status == 0 || status >= 500;

  @override
  String toString() => 'ShareApiException($status, $code)';
}

abstract class ShareApi {
  /// Explicit preparation for a NEW creation only. Retrying must never call
  /// this method: an absent session may belong to an already submitted owner.
  Future<String> prepareCreateOwner();

  /// The current online identity without signing in; null when absent.
  Future<String?> currentOwnerId();

  Future<OwnedShare> create({
    required String expectedOwnerId,
    required Map<String, Object?> payload,
    required String tokenDigest,
    required DateTime expiresAt,
    required String idempotencyKey,
  });

  Future<SharePage> list({String? cursor});

  Future<OwnedShare> get(String shareId);

  Future<OwnedShare> revoke(String shareId);

  Future<ResolvedShare> resolve({required String? shareId, required String token});
}

/// Calls the Supabase Edge Functions. Management requests use an anonymous
/// session created only when sharing is used (spec 13.2).
class SupabaseShareApi implements ShareApi, BackendDataApi {
  SupabaseShareApi(this._client);

  final SupabaseClient _client;

  @override
  Future<BackendDeletion> deleteBackendData(String idempotencyKey, {required String expectedOwnerId}) async {
    // Never sign in, and pin the checked identity: the saved local scope
    // belongs to it, so the command must not run as anyone else.
    final session = await _currentSession();
    if (session == null || expectedOwnerId.isEmpty || session.user.id != expectedOwnerId) {
      throw const ShareApiException(status: 401, code: 'share_owner_unavailable');
    }
    return BackendDeletion.fromJson(await _invoke('privacy/delete-backend-data',
      body: const {'confirm': 'delete-backend-data'},
      headers: {'Idempotency-Key': idempotencyKey, 'Authorization': 'Bearer ${session.accessToken}'}) as Map<String, dynamic>);
  }

  @override
  Future<BackendDeletion> deletionJob(String jobId) async {
    await _ensureSession();
    return BackendDeletion.fromJson(await _invoke('privacy/deletion-jobs/$jobId', method: HttpMethod.get) as Map<String, dynamic>);
  }

  /// The current session, refreshed (same user) when expired. Never signs in.
  Future<Session?> _currentSession() async {
    final session = _client.auth.currentSession;
    if (session == null || !session.isExpired) return session;
    try {
      return (await _client.auth.refreshSession()).session;
    } on AuthRetryableFetchException {
      throw const ShareApiException(status: 0, code: 'network', retryable: true);
    } on AuthException {
      throw const ShareApiException(status: 401, code: 'unauthenticated');
    } on Object {
      throw const ShareApiException(status: 0, code: 'network', retryable: true);
    }
  }

  Future<void> _ensureSession({bool create = false}) async {
    if (_client.auth.currentSession != null) return;
    if (!create) throw const ShareApiException(status: 401, code: 'unauthenticated');
    try {
      await _client.auth.signInAnonymously();
    } on AuthException {
      throw const ShareApiException(status: 401, code: 'unauthenticated');
    } on Object {
      throw const ShareApiException(status: 0, code: 'network');
    }
  }

  Future<Object?> _invoke(
    String path, {
    HttpMethod method = HttpMethod.post,
    Object? body,
    Map<String, String>? headers,
    Map<String, String>? query,
  }) async {
    try {
      final response = await _client.functions.invoke(
        path,
        method: method,
        body: body,
        headers: headers,
        queryParameters: query,
      );
      return response.data;
    } on FunctionException catch (e) {
      final details = e.details;
      final envelope = details is Map ? details : const {};
      throw ShareApiException(
        status: e.status,
        code: envelope['code'] as String? ?? 'internal_error',
        retryable: envelope['retryable'] == true,
        retryAfterSeconds: (envelope['retryAfterSeconds'] as num?)?.toInt(),
      );
    } on ShareApiException {
      rethrow;
    } on Object {
      throw const ShareApiException(status: 0, code: 'network', retryable: true);
    }
  }

  @override
  Future<String?> currentOwnerId() async {
    final id = _client.auth.currentSession?.user.id;
    return id == null || id.isEmpty ? null : id;
  }

  @override
  Future<String> prepareCreateOwner() async {
    await _ensureSession(create: true);
    final session = _client.auth.currentSession;
    if (session == null || session.user.id.isEmpty) {
      throw const ShareApiException(status: 401, code: 'share_owner_unavailable');
    }
    return session.user.id;
  }

  @override
  Future<OwnedShare> create({
    required String expectedOwnerId,
    required Map<String, Object?> payload,
    required String tokenDigest,
    required DateTime expiresAt,
    required String idempotencyKey,
  }) async {
    // Never sign in here. This command may already exist for another owner.
    final session = await _currentSession();
    if (session == null || expectedOwnerId.isEmpty || session.user.id != expectedOwnerId) {
      throw const ShareApiException(status: 401, code: 'share_owner_unavailable');
    }
    final data = await _invoke(
      'share-links',
      body: {
        'schemaVersion': payload['schemaVersion'],
        'payload': payload,
        'tokenDigest': tokenDigest,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
      },
      // Pin the checked identity even if auth changes while dispatching.
      headers: {'Idempotency-Key': idempotencyKey, 'Authorization': 'Bearer ${session.accessToken}'},
    );
    return OwnedShare.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<SharePage> list({String? cursor}) async {
    await _ensureSession();
    final data = await _invoke(
      'share-links',
      method: HttpMethod.get,
      query: cursor == null ? null : {'cursor': cursor},
    ) as Map<String, dynamic>;
    return SharePage(
      items: [for (final i in data['items'] as List) OwnedShare.fromJson(i as Map<String, dynamic>)],
      nextCursor: data['nextCursor'] as String?,
    );
  }

  @override
  Future<OwnedShare> get(String shareId) async {
    await _ensureSession();
    return OwnedShare.fromJson(await _invoke('share-links/$shareId', method: HttpMethod.get) as Map<String, dynamic>);
  }

  @override
  Future<OwnedShare> revoke(String shareId) async {
    await _ensureSession();
    return OwnedShare.fromJson(await _invoke('share-links/$shareId', method: HttpMethod.delete) as Map<String, dynamic>);
  }

  @override
  Future<ResolvedShare> resolve({required String? shareId, required String token}) async {
    // The token travels only in this POST body (CONTRACTS.md 7.3).
    final data = await _invoke('share-resolve', body: {
      'shareId': ?shareId,
      'token': token,
      'supportedSchemaVersions': const ['1.0'],
    });
    return ResolvedShare.fromJson(data as Map<String, dynamic>);
  }
}
