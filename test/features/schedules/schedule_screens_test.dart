import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/features/categories/domain/category.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';

import '../../support/harness.dart';

ScheduleDraft classDraft({
  String title = 'Fixture class',
  int hour = 9,
  int? endHour = 10,
  String? location = 'Fixture room',
  String? professor,
  String? category,
  List<int> weekdays = const [1, 3],
}) => ScheduleDraft(
  title: title,
  categoryId: category,
  time: TimedSpec(
    startDate: LocalDate(2026, 11, 2),
    startTime: LocalTime(hour, 0),
    timeZone: 'Asia/Manila',
    endTime: endHour == null ? null : LocalTime(endHour, 0),
    endDayOffset: endHour == null ? null : 0,
  ),
  recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: weekdays),
  details: ScheduleDetails(location: location, professor: professor),
);

void main() {
  appTest('first launch shows an honest empty Today with one clear action', (h) async {
    expect(find.text('No schedules yet'), findsOneWidget);
    expect(find.text('Create schedule'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Selected date Monday, November 2')), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Now'), findsNothing);
  });

  appTest('Today shows Now, Next and only the details that exist', now: DateTime.utc(2026, 11, 2, 1, 30), (h) async {
    final repo = h.read(scheduleRepositoryProvider);
    await h.run(() => repo.create(classDraft(title: 'Fixture first', hour: 9, endHour: 10)));
    await h.run(
      () => repo.create(classDraft(title: 'Fixture second', hour: 11, endHour: 12, location: null, professor: 'Fixture person')),
    );
    await h.settle();

    expect(find.text('Fixture first'), findsOneWidget);
    expect(find.text('Fixture second'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Fixture room'), findsOneWidget);
    expect(find.text('Fixture person'), findsOneWidget);
    expect(find.text('No schedules yet'), findsNothing);
  });

  appTest('an active filter with no matches says so and can be cleared', (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft(category: 'school')));
    await h.run(() => h.read(appFilterProvider.notifier).set(const CategoryFilter.only({'work'})));
    await h.settle();
    expect(find.text('No schedules in this filter'), findsOneWidget);
    await h.tapText('Show all');
    expect(find.text('Fixture class'), findsOneWidget);
  });

  appTest('creating a schedule in the editor saves it to Today', (h) async {
    final tester = h.tester;
    await h.tapText('Create schedule');
    expect(find.text('New schedule'), findsOneWidget);

    await h.tapText('Next');
    expect(find.text('Enter a title'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await h.settle();

    await tester.enterText(find.widgetWithText(TextField, 'Title'), '  Fixture lecture  ');
    final room = find.widgetWithText(TextField, 'Room or location');
    await tester.scrollUntilVisible(room, 120, scrollable: find.byType(Scrollable).last);
    await tester.enterText(room, 'Fixture hall');
    await h.tapText('Next');
    await h.tapText('Next');
    await h.tapText('Save');

    expect(find.text('New schedule'), findsNothing);
    expect(find.text('Fixture lecture'), findsOneWidget);
    expect(find.text('Fixture hall'), findsOneWidget);
  });

  appTest('leaving the editor with unsaved edits asks before discarding', (h) async {
    final tester = h.tester;
    await h.tapText('Create schedule');
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Fixture draft');
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await h.settle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await h.tapText('Cancel');
    expect(find.text('New schedule'), findsOneWidget);
    expect(find.text('Fixture draft'), findsOneWidget);
  });

  appTest('editing a repeating schedule asks for the scope first', (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft()));
    await h.settle();
    await h.tapText('Fixture class');
    expect(find.text('Every Mon, Wed'), findsOneWidget);
    await h.tapText('Edit');
    expect(find.text('This occurrence'), findsOneWidget);
    expect(find.text('Entire series'), findsOneWidget);
    await h.tapText('This occurrence');
    expect(find.text('Edit occurrence'), findsOneWidget);
    expect(textContaining('Changes apply only to the occurrence on'), findsOneWidget);
  });

  appTest('Week agenda lists the week with real entries', (h) async {
    await h.run(() => h.read(scheduleRepositoryProvider).create(classDraft()));
    await h.settle();
    await h.tapText('Week');
    await h.tester.tap(find.byTooltip('Show agenda'));
    await h.settle();
    expect(find.text('Fixture class'), findsNWidgets(2));
  });
}
