import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';

import '../../support/harness.dart';
import 'schedule_screens_test.dart' show classDraft;

void main() {
  for (final populated in [false, true]) {
    appTest('Week keeps all 24 hours reachable, populated=$populated', (h) async {
      if (populated) {
        await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft()));
        await h.settle();
      }
      await h.tapText('Week');
      final labels = find.byKey(const ValueKey('week-hour-label'));
      expect(labels, findsNWidgets(24));
      expect(h.tester.widget<Text>(labels.first).data, matches(r'12:00\sAM'));
      expect(h.tester.widget<Text>(labels.last).data, matches(r'11:00\sPM'));
      await h.tester.drag(find.byKey(const ValueKey('week-timeline')), const Offset(0, -1800));
      await h.settle();
      expect(h.tester.getTopLeft(labels.last).dy, lessThan(800));
      expect(h.tester.takeException(), isNull);
    }, size: const Size(360, 800));
  }
}
