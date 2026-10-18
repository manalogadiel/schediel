import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Client-held bearer secret for a share link (CONTRACTS.md 5.4, 7.2):
/// exactly 32 random bytes, canonical unpadded base64url, and the lowercase
/// hex SHA-256 digest of the raw bytes. Only the digest leaves the device
/// at creation.
@immutable
class ShareSecret {
  const ShareSecret._(this.token, this.digest);

  factory ShareSecret.fromBytes(Uint8List bytes) {
    if (bytes.length != byteLength) throw ArgumentError('A share secret has $byteLength bytes');
    return ShareSecret._(base64Url.encode(bytes).replaceAll('=', ''), sha256.convert(bytes).toString());
  }

  factory ShareSecret.generate([Random? random]) {
    final source = random ?? Random.secure();
    return ShareSecret.fromBytes(Uint8List.fromList([for (var i = 0; i < byteLength; i++) source.nextInt(256)]));
  }

  static const byteLength = 32;
  static final RegExp _pattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

  /// Accepts only a canonical encoding; a received token is never repaired.
  static ShareSecret? tryParse(String token) {
    if (!_pattern.hasMatch(token)) return null;
    final Uint8List bytes;
    try {
      bytes = base64Url.decode('$token=');
    } on FormatException {
      return null;
    }
    if (bytes.length != byteLength) return null;
    final secret = ShareSecret.fromBytes(bytes);
    return secret.token == token ? secret : null;
  }

  final String token;
  final String digest;
}

/// A share bearer link: https://{host}/s/{shareId}#token={token}.
@immutable
class ShareLink {
  const ShareLink({required this.host, required this.shareId, required this.token});

  final String host;
  final String shareId;
  final String token;

  static final RegExp _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

  static bool isShareId(String value) => _uuid.hasMatch(value);

  Uri toUri() => Uri(scheme: 'https', host: host, path: '/s/$shareId', fragment: 'token=$token');

  static ShareLink? tryParse(Uri uri, {required String host}) {
    if (uri.scheme != 'https' || uri.host.toLowerCase() != host.toLowerCase()) return null;
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasPort && uri.port != 443) return null;
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments[0] != 's' || !isShareId(segments[1])) return null;
    final fragment = uri.fragment;
    if (!fragment.startsWith('token=')) return null;
    final token = fragment.substring('token='.length);
    if (ShareSecret.tryParse(token) == null) return null;
    return ShareLink(host: host, shareId: segments[1], token: token);
  }

  static ShareLink? tryParseText(String text, {required String host}) {
    final uri = Uri.tryParse(text.trim());
    return uri == null ? null : tryParse(uri, host: host);
  }
}
