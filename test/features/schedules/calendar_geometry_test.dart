import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/widgets/themed.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/features/schedules/presentation/timeline_row.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';

import '../../support/harness.dart';
import 'schedule_screens_test.dart' show classDraft;

void main() {
  appTest('Today time range is centered against its whole card', (h) async {
    await h.run(
      () => h
          .read(scheduleRepositoryProvider)
          .create(classDraft(professor: 'Fixture person', location: 'Fixture room', category: 'school')),
    );
    await h.settle();
    final row = find.byType(TimelineRow);
    final card = find.descendant(of: row, matching: find.byType(ThemedCard));
    final start = find.descendant(of: row, matching: find.textContaining(RegExp(r'^9:00\sAM$')));
    final end = find.descendant(of: row, matching: find.textContaining(RegExp(r'^10:00\sAM$')));
    final midpoint = (h.tester.getTopLeft(start).dy + h.tester.getBottomLeft(end).dy) / 2;
    expect((midpoint - h.tester.getCenter(card).dy).abs(), lessThan(1));
  }, now: DateTime.utc(2026, 11, 2, 2, 30));

  appTest('DST fall-back displays events at their local wall-clock hour', (h) async {
    await h.run(
      () => h
          .read(scheduleRepositoryProvider)
          .create(
            ScheduleDraft(
              title: 'Fixture DST',
              time: TimedSpec(
                startDate: LocalDate(2026, 11, 1),
                startTime: LocalTime(9, 0),
                endTime: LocalTime(10, 0),
                endDayOffset: 0,
                timeZone: 'America/New_York',
              ),
            ),
          ),
    );
    await h.settle();
    await h.tapText('Week');
    final block = find.byKey(const ValueKey('week-block'));
    final zero = find.byKey(const ValueKey('week-hour-label')).first;
    expect(h.tester.getTopLeft(block).dy - h.tester.getTopLeft(zero).dy, closeTo(9 * 48 + 6, 1));
  }, zone: 'America/New_York');
}
