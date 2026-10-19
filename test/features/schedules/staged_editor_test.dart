import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/router.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';
import 'package:schediel/features/schedules/presentation/schedule_editor_screen.dart';

import '../../support/harness.dart';

void main() {
  appTest('occurrence actions use filled controls without removing confirmation', (h) async {
    await h.run(
      () => h
          .read(scheduleRepositoryProvider)
          .create(
            ScheduleDraft(
              title: 'Fixture actions',
              time: TimedSpec(
                startDate: LocalDate(2026, 11, 2),
                startTime: LocalTime(9, 0),
                endTime: LocalTime(10, 0),
                endDayOffset: 0,
                timeZone: 'Asia/Manila',
              ),
            ),
          ),
    );
    await h.settle();
    await h.tapText('Fixture actions');
    expect(find.byWidgetPredicate((w) => w is OutlinedButton), findsNothing);
    await h.tapText('Delete');
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), hasLength(1));
    await h.tapText('Cancel');
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), hasLength(1));
  });
  appTest('new late-night defaults keep an explicit next-day end', (h) async {
    await h.tapText('Create schedule');
    await h.tester.enterText(find.widgetWithText(TextField, 'Title'), 'Fixture overnight');
    await h.tapText('Next');
    await h.tapText('Next');
    await h.tapText('Save');
    final time = (await h.run(h.read(scheduleRepositoryProvider).loadAll)).single.time as TimedSpec;
    expect(time.startTime, LocalTime(23, 0));
    expect(time.endTime, LocalTime(0, 0));
    expect(time.endDayOffset, 1);
  }, now: DateTime.utc(2026, 11, 2, 14, 30));

  appTest('reviewing a point event never invents an end time', (h) async {
    rootNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ScheduleEditorScreen(
          scope: EditorScope.review,
          initialDraft: ScheduleDraft(
            title: 'Fixture point',
            time: TimedSpec(startDate: LocalDate(2026, 11, 2), startTime: LocalTime(9, 0), timeZone: 'Asia/Manila'),
          ),
        ),
      ),
    );
    await h.settle();
    await h.tapText('Next');
    expect(h.tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'End time')).value, isFalse);
    expect(await h.run(h.read(scheduleRepositoryProvider).loadAll), isEmpty);
  });
  appTest('alert timing uses a single grouped selector and keeps the chosen offset', (h) async {
    await h.tapText('Create schedule');
    await h.tester.enterText(find.widgetWithText(TextField, 'Title'), 'Fixture alert');
    await h.tapText('Next');
    await h.tapText('Next');
    await h.tapText('Notification');
    expect(find.byType(ChoiceChip), findsNothing);
    await h.tapText('Notification timing');
    await h.tester.tap(find.byKey(const ValueKey('alert-offset-30')));
    await h.settle();
    await h.tapText('Back');
    await h.tapText('Next');
    await h.tapText('Notification timing');
    final selected = h.tester.widget<Semantics>(
      find.ancestor(of: find.byKey(const ValueKey('alert-offset-30')), matching: find.byType(Semantics)).first,
    );
    expect(selected.properties.selected, isTrue);
  });
  appTest('editor opens as a guarded bottom sheet above the existing shell', (h) async {
    await h.tapText('Create schedule');
    final context = h.tester.element(find.byType(ScheduleEditorScreen));
    expect(ModalRoute.of(context), isA<ModalBottomSheetRoute<dynamic>>());
    await h.tester.enterText(find.widgetWithText(TextField, 'Title'), 'Fixture draft');
    await h.tester.tapAt(const Offset(2, 2));
    await h.settle();
    expect(find.text('New schedule'), findsOneWidget);
    await h.tester.tap(find.byTooltip('Close'));
    await h.settle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await h.tapText('Cancel');
    expect(find.text('Fixture draft'), findsOneWidget);
  });
  appTest('editor labels stay inside the filled field above its value', (h) async {
    await h.tapText('Create schedule');
    final field = h.tester.widget<TextField>(find.widgetWithText(TextField, 'Title'));
    expect(field.decoration!.floatingLabelBehavior, FloatingLabelBehavior.always);
    expect(field.decoration!.border, InputBorder.none);
    expect(field.decoration!.filled, isTrue);
  });
  appTest('staged editor keeps a draft and saves only from its final step', (h) async {
    await h.tapText('Create schedule');
    expect(find.text('1 / 3 · Details'), findsOneWidget);
    await h.tester.enterText(find.widgetWithText(TextField, 'Title'), 'Fixture staged');
    await h.tapText('Next');
    expect(find.text('2 / 3 · Time'), findsOneWidget);
    expect(h.tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'End time')).value, isTrue);
    expect(h.read(allSeriesProvider).value, isEmpty);
    await h.tapText('Back');
    expect(h.tester.widget<TextField>(find.widgetWithText(TextField, 'Title')).controller!.text, 'Fixture staged');
    await h.tapText('Next');
    await h.tapText('Next');
    expect(find.text('3 / 3 · Alerts'), findsOneWidget);
    expect(h.read(allSeriesProvider).value, isEmpty);
    await h.tapText('Save');
    expect(find.text('Fixture staged'), findsOneWidget);
    expect(find.text('New schedule'), findsNothing);
  });
}
