import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/features/schedules/presentation/schedule_time_picker.dart';

import '../../support/harness.dart';

void main() {
  for (final use24h in [false, true]) {
    testWidgets('wheel and keyboard preserve the $use24h hour-format setting', (tester) async {
      TimeOfDay? result;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(alwaysUse24HourFormat: use24h),
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async =>
                      result = await showScheduleTimePicker(context, initialTime: const TimeOfDay(hour: 23, minute: 59)),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker)).use24hFormat, use24h);
      await tester.tap(find.text('Keyboard input'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(MediaQuery.alwaysUse24HourFormatOf(tester.element(find.byType(TimePickerDialog))), use24h);
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(result, isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, const TimeOfDay(hour: 23, minute: 59));
    });
  }
  appTest('wheel time picker cancels without changing the draft and applies Done', (h) async {
    await h.tapText('Create schedule');
    await h.tester.enterText(textField('Title'), 'Fixture time');
    await h.tapText('Next');
    String startText() => (h.tester.widget<ListTile>(find.widgetWithText(ListTile, 'Starts')).trailing as Text).data!;
    final original = startText();
    await h.tapText('Starts');
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    h.tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker)).onDateTimeChanged(DateTime(2000, 1, 1, 23, 59));
    await h.tapText('Cancel');
    expect(startText(), original);
    await h.tapText('Starts');
    h.tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker)).onDateTimeChanged(DateTime(2000, 1, 1, 23, 59));
    await h.tapText('Done');
    expect(startText(), matches(r'11:59\sPM'));
  });
}
