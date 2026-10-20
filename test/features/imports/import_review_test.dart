import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/router.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/features/schedules/presentation/schedule_editor_screen.dart';
import 'package:schediel/features/imports/data/import_repository.dart';
import 'package:schediel/features/imports/domain/import_entry.dart';
import 'package:schediel/features/imports/presentation/import_review_screen.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';

import '../../support/harness.dart';

ImportEntry fixture() => ImportEntry(
  candidateId: 'a',
  sourceType: 'share',
  shareId: 'share-a',
  sourceItemId: 'source-a',
  sourceRevision: 1,
  draft: ScheduleDraft(
    title: 'Fixture poster',
    details: const ScheduleDetails(location: 'Fixture hall'),
    time: DateOnlySpec(startDate: LocalDate(2026, 11, 3), endDateExclusive: LocalDate(2026, 11, 4)),
  ),
);

void openReview() => unawaited(
  rootNavigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => ImportReviewScreen(entries: [fixture()]))),
);

void main() {
  appTest('cancelling the typed review editor returns to inactive review safely', (h) async {
    openReview();
    await h.settle();
    await h.tapText('Edit');
    await h.tester.tap(find.byTooltip('Close').last);
    await h.settle();
    expect(h.tester.takeException(), isNull);
    expect(find.text('Fixture poster'), findsOneWidget);
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
  });

  appTest('opening and closing review creates no schedules or alert rules', (h) async {
    openReview();
    await h.settle();
    expect(find.text('Fixture poster'), findsOneWidget);
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    await h.tester.tap(find.byTooltip('Close'));
    await h.settle();
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    expect(await h.run(() => h.db.select(h.db.alertRules).get()), isEmpty);
  });

  appTest('edited candidates remain inactive until Add selected schedules', (h) async {
    openReview();
    await h.settle();
    await h.tapText('Edit');
    await h.tester.enterText(find.widgetWithText(TextField, 'Title'), 'Edited poster');
    await h.tapText('Next');
    await h.tapText('Next');
    await h.tapText('Use changes');
    expect(find.text('Edited poster'), findsOneWidget);
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
    await h.tapText('Add selected schedules');
    final saved = await h.run(h.read(scheduleRepositoryProvider).loadAll);
    expect(saved.single.title, 'Edited poster');
    expect(saved.single.details.location, 'Fixture hall');
    expect(saved.single.categoryId, isNull);
    expect(await h.run(() => h.db.select(h.db.alertRules).get()), isEmpty);
  });

  appTest('review title edits preserve an explicit next-day end relationship', (h) async {
    ReviewEdit? result;
    rootNavigatorKey.currentState!
        .push<ReviewEdit>(
          MaterialPageRoute(
            builder: (_) => ScheduleEditorScreen(
              scope: EditorScope.review,
              initialDraft: ScheduleDraft(
                title: 'Long fixture',
                time: TimedSpec(
                  startDate: LocalDate(2026, 11, 3),
                  startTime: LocalTime(9, 0),
                  timeZone: 'Asia/Manila',
                  endTime: LocalTime(10, 0),
                  endDayOffset: 1,
                ),
              ),
            ),
          ),
        )
        .then((v) => result = v);
    await h.settle();
    await h.tester.enterText(find.widgetWithText(TextField, 'Title'), 'Renamed fixture');
    await h.tapText('Next');
    await h.tapText('Next');
    await h.tapText('Use changes');
    expect((result!.draft.time as TimedSpec).endDayOffset, 1);
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
  });

  appTest('closing an edited review asks before discarding inactive changes', (h) async {
    openReview();
    await h.settle();
    await h.tapText('Edit');
    await h.tester.enterText(find.widgetWithText(TextField, 'Title'), 'Changed draft');
    await h.tapText('Next');
    await h.tapText('Next');
    await h.tapText('Use changes');
    await h.tester.tap(find.byTooltip('Close'));
    await h.settle();
    expect(find.text('Discard review changes?'), findsOneWidget);
    await h.tapText('Keep reviewing');
    expect(find.text('Changed draft'), findsOneWidget);
    await h.tester.tap(find.byTooltip('Close'));
    await h.settle();
    await h.tapText('Discard review');
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
  });

  appTest('known exact imports start unselected with an explicit keep copy choice', (h) async {
    await h.run(() => h.read(importRepositoryProvider).commit('first', [fixture()]));
    openReview();
    await h.settle();
    expect(find.text('Already imported'), findsOneWidget);
    expect(find.text('0 selected'), findsOneWidget);
    await h.tapText('Keep a copy');
    expect(find.text('1 selected'), findsOneWidget);
    await h.tapText('Add selected schedules');
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), hasLength(2));
  });
}
