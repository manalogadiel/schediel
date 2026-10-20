import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/features/sharing/domain/share_link.dart';

void main() {
  const id = '6f1c2b1e-9d3a-4c55-8e21-0a7b3c4d5e6f';
  final zeros = ShareSecret.fromBytes(Uint8List(32));

  group('ShareSecret', () {
    test('encodes 32 bytes as canonical unpadded base64url and a hex SHA-256 digest', () {
      expect(zeros.token, 'A' * 43);
      expect(zeros.digest, '66687aadf862bd776c8fc18b8e9f8e20089714856ee233b3902a591d0d5f2925');
    });

    test('generates fresh random secrets', () {
      final a = ShareSecret.generate();
      final b = ShareSecret.generate();
      expect(a.token, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(a.digest, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(a.token, isNot(b.token));
      expect(ShareSecret.tryParse(a.token)!.digest, a.digest);
    });

    test('rejects malformed or non-canonical tokens without repairing them', () {
      for (final token in ['A' * 42, 'A' * 44, '${'A' * 42}=', '${'A' * 42}+', '${'A' * 42}B', '']) {
        expect(ShareSecret.tryParse(token), isNull, reason: token);
      }
      expect(ShareSecret.tryParse('${'A' * 42}E'), isNotNull);
    });
  });

  group('ShareLink', () {
    test('compact links round-trip and extract from a chat message without a schedule ID', () {
      final uri = ShareLink(host: 'share.example', token: zeros.token).toUri();
      expect(uri.path, '/s/');
      expect(uri.fragment, zeros.token);
      expect(uri.toString().length, lessThan(70));
      final parsed = ShareLink.tryParseText('Schedules from Schediel\n($uri).', host: 'share.example');
      expect(parsed?.token, zeros.token);
      expect(parsed?.shareId, isNull);
      for (final bad in ['https://other.example/s/#${zeros.token}',
        'https://share.example/s/?x=1#${zeros.token}', 'https://share.example/s/#${zeros.token}=',
        'https://share.example/s/#${'A' * 42}B', 'https://share.example/s/#token=${zeros.token}']) {
        expect(ShareLink.tryParse(Uri.parse(bad), host: 'share.example'), isNull);
      }
    });
    test('composes the bearer link from server metadata and the local secret', () {
      final link = ShareLink(host: 'share.example', shareId: id, token: zeros.token);
      expect(link.toUri().toString(), 'https://share.example/s/#${'A' * 43}');
    });

    test('parses only well-formed links for the configured host', () {
      final ok = ShareLink.tryParse(Uri.parse('https://Share.Example/s/$id#token=${'A' * 43}'), host: 'share.example');
      expect(ok?.shareId, id);
      expect(ok?.token, 'A' * 43);

      for (final text in [
        'http://share.example/s/$id#token=${'A' * 43}',
        'https://other.example/s/$id#token=${'A' * 43}',
        'https://share.example/s/$id',
        'https://share.example/s/$id#token=short',
        'https://share.example/s/not-a-uuid#token=${'A' * 43}',
        'https://share.example/s/$id/extra#token=${'A' * 43}',
        'https://share.example/s/$id?token=${'A' * 43}',
        'https://share.example/x/$id#token=${'A' * 43}',
        'https://share.example/s/${id.toUpperCase()}#token=${'A' * 43}',
      ]) {
        expect(ShareLink.tryParse(Uri.parse(text), host: 'share.example'), isNull, reason: text);
      }
    });

    test('parses pasted text with surrounding whitespace', () {
      expect(ShareLink.tryParseText('  https://share.example/s/$id#token=${'A' * 43}\n', host: 'share.example'), isNotNull);
      expect(ShareLink.tryParseText('not a link', host: 'share.example'), isNull);
    });
  });
}
