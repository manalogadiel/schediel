import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/schedule/limits.dart';
import 'share_payload.dart';

/// Offline ("direct") schedule links: the whole [SharePayload] travels inside
/// the link, so sharing works without any server. Format:
///
///   `schediel://import?v=1#base64url(gzip(canonical JSON))`
///
/// The data sits in the fragment, which apps and servers do not forward in
/// requests. Opening a link only shows the import review; nothing is added
/// until the recipient confirms.
abstract final class DirectShare {
  static const scheme = 'schediel';
  static const host = 'import';
  static const version = '1';

  static final _inText = RegExp(r'schediel://import\?v=\d+#[A-Za-z0-9_\-]+');

  static Uri encode(SharePayload payload) {
    final packed = base64Url.encode(gzip.encode(payload.canonicalBytes())).replaceAll('=', '');
    return Uri(scheme: scheme, host: host, queryParameters: const {'v': version}, fragment: packed);
  }

  static bool isDirect(Uri uri) => uri.scheme == scheme && uri.host == host;

  /// The first direct link inside pasted text (for example a whole message).
  static Uri? findInText(String text) {
    final match = _inText.firstMatch(text);
    return match == null ? null : Uri.tryParse(match.group(0)!);
  }

  /// Decodes and validates a direct link; null for anything malformed,
  /// oversized, from a newer version or failing the payload contract.
  static SharePayload? decode(Uri uri, SharePayloadValidator validator) {
    if (!isDirect(uri) || uri.queryParameters['v'] != version || uri.fragment.isEmpty) return null;
    try {
      final padded = uri.fragment.padRight((uri.fragment.length + 3) ~/ 4 * 4, '=');
      final bytes = _inflate(base64Url.decode(padded), ScheduleLimits.shareMaxBytes);
      if (bytes == null) return null;
      final json = jsonDecode(utf8.decode(bytes));
      if (validator.validate(json).isNotEmpty) return null;
      return SharePayload.fromJson(json as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  /// Stable identity for duplicate detection: the same link imported twice is
  /// recognized as the same source.
  static String sourceId(SharePayload payload) => 'direct-${sha256.convert(payload.canonicalBytes()).toString().substring(0, 32)}';

  /// Gunzips at most [limit] bytes; null when the data would exceed it, so a
  /// crafted link cannot expand without bound.
  static Uint8List? _inflate(List<int> data, int limit) {
    final out = BytesBuilder(copy: false);
    var overflow = false;
    final sink = ByteConversionSink.withCallback((_) {});
    final counting = _CountingSink((chunk) {
      if (overflow) return;
      if (out.length + chunk.length > limit) {
        overflow = true;
      } else {
        out.add(chunk);
      }
    }, sink);
    final input = gzip.decoder.startChunkedConversion(counting);
    const step = 1024;
    for (var i = 0; i < data.length && !overflow; i += step) {
      input.add(data.sublist(i, i + step > data.length ? data.length : i + step));
    }
    if (overflow) return null;
    input.close();
    return overflow ? null : out.takeBytes();
  }
}

class _CountingSink implements Sink<List<int>> {
  _CountingSink(this._onChunk, this._done);
  final void Function(List<int>) _onChunk;
  final Sink<List<int>> _done;

  @override
  void add(List<int> data) => _onChunk(data);

  @override
  void close() => _done.close();
}
