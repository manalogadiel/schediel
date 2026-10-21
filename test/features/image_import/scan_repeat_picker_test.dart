import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/widgets/labeled_field.dart';
import 'package:schediel/features/image_import/domain/candidate_resolution.dart';
import 'package:schediel/features/image_import/presentation/scan_repeat_picker.dart';

void main() {
  testWidgets('repeat choices fit large text and keep the label above the control', (tester) async {
    tester.view.physicalSize = const Size(360, 800) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    var value = CandidateRepeat.weekly;
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Scaffold(body: Padding(padding: const EdgeInsets.all(24), child: StatefulBuilder(
        builder: (context, setState) => ScanRepeatPicker(value: value,
          onChanged: (next) => setState(() => value = next)),
      ))),
    )));
    expect(tester.getBottomLeft(find.text('Repeats')).dy,
      lessThan(tester.getTopLeft(find.byType(SegmentedButton<CandidateRepeat>)).dy));
    expect(find.byType(FieldLabel), findsOneWidget);
    await tester.tap(find.text('One time'));
    await tester.pumpAndSettle();
    expect(value, CandidateRepeat.oneTime);
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    expect(value, CandidateRepeat.weekly);
    expect(tester.takeException(), isNull);
  });
}
