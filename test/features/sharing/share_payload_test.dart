import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/features/sharing/domain/share_payload.dart';

void main() {
  late SharePayloadValidator validator;
  late List<Map<String, dynamic>> cases;

  setUpAll(() {
    final zones = ZoneResolver.initialized();
    validator = SharePayloadValidator(zones, OccurrenceEngine(zones));
    final doc = jsonDecode(File('contracts/fixtures/share-payload-cases.json').readAsStringSync())
        as Map<String, dynamic>;
    cases = (doc['cases'] as List).cast<Map<String, dynamic>>();
  });

  test('loads the shared cross-language fixtures', () {
    expect(cases.length, greaterThanOrEqualTo(50));
  });

  test('matches every shared fixture case', () {
    final failures = <String>[];
    for (final c in cases) {
      final errors = validator.validate(c['payload']);
      if (c['valid'] == true) {
        if (errors.isNotEmpty) failures.add('${c['name']}: unexpected $errors');
      } else {
        final expected = c['expectError'] as Map<String, dynamic>;
        final hit = errors.any((e) => e.code == expected['code'] && e.path == expected['path']);
        if (!hit) failures.add('${c['name']}: expected ${expected['code']} at ${expected['path']}, got $errors');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('decodes a valid payload into models and encodes it back unchanged', () {
    final valid = cases.firstWhere((c) => c['name'] == 'valid-mixed-items')['payload'];
    final payload = SharePayload.fromJson(valid as Map<String, dynamic>);
    expect(payload.items, hasLength(3));
    expect(jsonEncode(payload.toJson()), jsonEncode(valid));
  });

  test('rejects payloads above the serialized byte limit', () {
    final valid = Map<String, dynamic>.from(
      cases.firstWhere((c) => c['name'] == 'valid-mixed-items')['payload'] as Map<String, dynamic>,
    );
    final policy = Map<String, dynamic>.from(valid['sharedFieldPolicy'] as Map)..['notes'] = true;
    final items = [
      for (var i = 0; i < 140; i++)
        {
          ...(valid['items'] as List)[1] as Map<String, dynamic>,
          'sourceItemId': '00000000-0000-4000-8000-${(1000 + i).toString().padLeft(12, '0')}',
          'details': {'location': null, 'professor': null, 'subtitle': null, 'notes': 'n' * 4000},
        },
    ];
    final errors = validator.validate({...valid, 'items': items, 'sharedFieldPolicy': policy});
    expect(errors.map((e) => e.code), contains('payload_too_large'));
  });
}
