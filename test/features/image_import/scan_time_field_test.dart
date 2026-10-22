import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/features/image_import/presentation/scan_time_field.dart';

void main() {
  for (final use24h in [false, true]) {
    testWidgets(
      'scan time selector confirms only Done and respects 24h=$use24h',
      (tester) async {
        LocalTime? value;
        var changes = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(alwaysUse24HourFormat: use24h),
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) => ScanTimeField(
                    label: 'Start time',
                    value: value,
                    onChanged: (next) => setState(() {
                      value = next;
                      changes++;
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.byType(TextField), findsNothing);
        expect(
          tester.getBottomLeft(find.text('Start time')).dy,
          lessThan(tester.getTopLeft(find.byType(InputDecorator)).dy),
        );
        await tester.tap(find.text('Choose time'));
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        expect(find.text('Keyboard input'), findsNothing);
        final wheel = tester.widget<CupertinoDatePicker>(
          find.byType(CupertinoDatePicker),
        );
        expect(wheel.use24hFormat, use24h);
        wheel.onDateTimeChanged(DateTime(2000, 1, 1, 16, 30));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(value, isNull);
        expect(changes, 0);
        for (final time in [
          LocalTime(0, 0),
          LocalTime(12, 0),
          LocalTime(23, 59),
        ]) {
          await tester.tap(find.byType(ScanTimeField));
          await tester.pumpAndSettle();
          tester
              .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
              .onDateTimeChanged(DateTime(2000, 1, 1, time.hour, time.minute));
          expect(value, isNot(time));
          await tester.tap(find.text('Done'));
          await tester.pumpAndSettle();
          expect(value, time);
        }
        expect(changes, 3);
        await tester.tap(find.byType(ScanTimeField));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(
          changes,
          3,
          reason: 'Accepting the same time must preserve resolved draft state.',
        );
      },
    );
  }

  testWidgets(
    'scan time selector fits large text and keeps cancellation unchanged',
    (tester) async {
      tester.view.physicalSize =
          const Size(360, 800) * tester.view.devicePixelRatio;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanTimeField(
              label: 'End time',
              value: LocalTime(17, 30),
              onChanged: (_) => changes++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ScanTimeField));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Done').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(changes, 0);
    },
  );
}
