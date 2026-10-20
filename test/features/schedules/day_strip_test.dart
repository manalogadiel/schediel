import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/features/schedules/presentation/day_strip.dart';

import '../../support/harness.dart';
import 'schedule_screens_test.dart' show classDraft;

void main() {
  for (final populated in [false, true]) {
    appTest('Week has seven clickable full-width dates, populated=$populated', (h) async {
      if (populated) {
        await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft()));
        await h.settle();
      }
      await h.tapText('Week');
      final cells = [for (var d = 1; d <= 7; d++) find.byKey(ValueKey('day-2026-11-0$d'))];
      for (final cell in cells) {
        expect(cell, findsOneWidget);
      }
      expect(h.tester.getTopLeft(cells.first).dx, inInclusiveRange(16.0, 20.0));
      final widths = cells.map((c) => h.tester.getSize(c).width).toList();
      expect(widths.every((w) => (w - widths.first).abs() <= 1), isTrue);
      await h.tester.tap(cells[2]);
      await h.settle();
      expect(h.read(effectiveDateProvider), LocalDate(2026, 11, 3));
      expect(find.byKey(const ValueKey('nav-week')), findsOneWidget);
      expect(h.tester.takeException(), isNull);
    }, size: const Size(360, 800));
  }

  appTest('arched band sits behind the numbers, not the weekday labels', (h) async {
    final strip = find.byType(DayStripView);
    expect(h.tester.widget<DayStripView>(strip).arched, isTrue);
    final box = h.tester.getRect(strip);
    for (var d = 1; d <= 7; d++) {
      final cell = find.byKey(ValueKey('day-2026-11-0$d'));
      final label = h.tester.getRect(find.descendant(of: cell, matching: find.byType(Text)).first);
      final number = h.tester.getRect(find.descendant(of: cell, matching: find.text('$d')));
      final top = box.top + DayStripView.bandTop(label.center.dx - box.left, box.width, DayStripView.labelHeightFor(1));
      expect(label.bottom, lessThanOrEqualTo(top + .5), reason: 'label of day $d overlaps the band');
      expect(number.top, greaterThan(top), reason: 'number of day $d sits above the band');
    }
  });
}
