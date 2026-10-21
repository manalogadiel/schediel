import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/features/image_import/presentation/scan_date_field.dart';

void main() {
  Future<void> mount(WidgetTester tester, Widget child, {double scale = 1}) => tester.pumpWidget(
    ProviderScope(overrides: [todayProvider.overrideWithValue(LocalDate(2026,10,22))],
      child: MaterialApp(home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20), child: child)))))));

  testWidgets('calendar selection needs Done; cancellation leaves the date unchanged', (tester) async {
    LocalDate? value;
    var changes = 0;
    await mount(tester, StatefulBuilder(builder: (context, setState) => ScanDateField(
      label: 'Term starts', value: value, onChanged: (next) => setState(() { value = next; changes++; }))));
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Choose date'), findsOneWidget);
    expect(tester.getBottomLeft(find.text('Term starts')).dy,
      lessThan(tester.getTopLeft(find.byType(InputDecorator)).dy));
    await tester.tap(find.text('Choose date'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.byType(InputDatePickerFormField), findsNothing);
    await tester.tap(find.text('23'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(value, isNull);
    expect(changes, 0);
    await tester.tap(find.text('Choose date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(value, LocalDate(2026,10,24));
    expect(find.text('Sat, Oct 24, 2026'), findsOneWidget);
    expect(changes, 1);
    // Reopening and accepting the same day must not invalidate an applied draft.
    await tester.tap(find.text('Sat, Oct 24, 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(changes, 1);
  });

  testWidgets('end date disallows days before the start and supports choosing a year', (tester) async {
    final semantics = tester.ensureSemantics();
    LocalDate? value;
    await mount(tester, ScanDateField(label: 'Term ends', value: null,
      firstDate: LocalDate(2026,10,22), focusDate: LocalDate(2026,10,22), onChanged: (next) => value = next));
    await tester.tap(find.text('Choose date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('21')); // Disabled: before the selected start.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(value, LocalDate(2026,10,22));
    await tester.tap(find.text('Choose date'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Select year')));
    await tester.pumpAndSettle();
    expect(find.byType(YearPicker), findsOneWidget);
    await tester.tap(find.text('2027'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(value, LocalDate(2027,10,24));
    semantics.dispose();
  });

  testWidgets('optional date can be cleared and controls fit 200 percent text', (tester) async {
    tester.view.physicalSize = const Size(360, 800) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    LocalDate? value = LocalDate(2026,10,22);
    await mount(tester, StatefulBuilder(builder: (context, setState) => ScanDateField(
      label: 'Last date (optional)', value: value, allowClear: true,
      onChanged: (next) => setState(() => value = next))), scale: 2);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Clear Last date (optional)'));
    await tester.pumpAndSettle();
    expect(value, isNull);
    expect(find.text('Choose date'), findsOneWidget);
    await tester.tap(find.text('Choose date'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(value, isNull);
  });
}
