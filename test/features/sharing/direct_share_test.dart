import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/deep_links.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/router.dart';
import 'package:schediel/features/sharing/application/share_sender.dart';
import 'package:schediel/features/sharing/domain/direct_share.dart';
import 'package:schediel/features/sharing/domain/share_payload.dart';
import 'package:schediel/features/sharing/presentation/direct_import_screen.dart';

import '../../support/harness.dart';

final _json = {
  'schemaVersion': '1.0',
  'sharedFieldPolicy': {'location': false, 'professor': false, 'subtitle': false, 'notes': false},
  'items': [
    {
      'sourceItemId': '00000000-0000-4000-8000-000000000001',
      'revision': 1,
      'title': 'Direct fixture',
      'categoryLabel': 'School',
      'time': {'kind': 'dateOnly', 'startDate': '2026-11-03', 'endDateExclusive': '2026-11-04'},
      'recurrence': null,
      'details': {'location': null, 'professor': null, 'subtitle': null, 'notes': null},
      'exceptions': <Object>[],
    },
  ],
};

SharePayload _payload() => SharePayload.fromJson(_json);

void main() {
  late SharePayloadValidator validator;
  setUpAll(() {
    final container = ProviderContainer();
    validator = container.read(sharePayloadValidatorProvider);
  });

  test('a direct link round-trips the payload and stays in the fragment', () {
    final link = DirectShare.encode(_payload());
    expect(link.scheme, 'schediel');
    expect(link.host, 'import');
    expect(link.queryParameters['v'], '1');
    final back = DirectShare.decode(link, validator);
    expect(back, isNotNull);
    expect(back!.items.single.title, 'Direct fixture');
    expect(DirectShare.sourceId(back), DirectShare.sourceId(_payload()));
  });

  test('tampered, foreign, newer or oversized links are rejected', () {
    final link = DirectShare.encode(_payload());
    expect(DirectShare.decode(link.replace(fragment: '${link.fragment.substring(0, 10)}xx'), validator), isNull);
    expect(DirectShare.decode(link.replace(queryParameters: {'v': '2'}), validator), isNull);
    expect(DirectShare.decode(Uri.parse('schediel://today'), validator), isNull);
    final invalid = base64Url.encode(gzip.encode(utf8.encode(jsonEncode({'schemaVersion': '1.0', 'items': 'nope'})))).replaceAll('=', '');
    expect(DirectShare.decode(link.replace(fragment: invalid), validator), isNull);
    final bomb = base64Url.encode(gzip.encode(List.filled(2 * 1024 * 1024, 32))).replaceAll('=', '');
    expect(DirectShare.decode(link.replace(fragment: bomb), validator), isNull);
  });

  test('a link is found inside a pasted message', () {
    final link = DirectShare.encode(_payload());
    final found = DirectShare.findInText('Schedules from Schediel: Direct fixture\n\nTo add them…\n\n$link');
    expect(found.toString(), link.toString());
    expect(DirectShare.findInText('no link here'), isNull);
  });

  test('direct links route to the import review', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(deepLinkCoordinatorProvider).routeFor(DirectShare.encode(_payload())), '/share/import');
  });

  appTest('opening a direct link shows an editable review and adds nothing', (h) async {
    rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => DirectImportScreen(link: DirectShare.encode(_payload()))));
    await h.settle();
    expect(find.text('Direct fixture'), findsOneWidget);
    expect(await h.run(() => h.read(scheduleRepositoryProvider).loadAll()), isEmpty);
  });

  appTest('a broken direct link explains itself', (h) async {
    rootNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => DirectImportScreen(link: Uri.parse('schediel://import?v=1#broken'))),
    );
    await h.settle();
    expect(find.text('This link can’t be opened'), findsOneWidget);
  });
}
