import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/app/theme/theme_catalog.dart';
import 'package:schediel/app/theme/tokens.dart';
import 'package:schediel/app/widgets/labeled_field.dart';

void main() {
  for (final theme in [ThemeId.lilac, ThemeId.pop, ThemeId.pixel, ThemeId.sketch]) {
    testWidgets('labels remain above empty, focused and filled inputs (${theme.name})', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(theme: themeFor(theme), brightness: Brightness.light,
          density: Density.comfortable, showCategoryColors: true),
        home: Scaffold(body: Center(child: SizedBox(width: 280, child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: LabeledField(label: 'Room or location', controller: controller),
        )))),
      ));
      void checkLabel() {
        final field = find.byType(TextField);
        expect(tester.widget<TextField>(field).decoration!.labelText, isNull);
        expect(tester.getBottomLeft(find.text('Room or location')).dy, lessThan(tester.getTopLeft(field).dy));
        expect(find.bySemanticsLabel('Room or location'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      checkLabel();
      await tester.tap(find.byType(TextField)); await tester.pump(); checkLabel();
      await tester.enterText(find.byType(TextField), '105'); await tester.pump(); checkLabel();
      expect(controller.text, '105');
      semantics.dispose();
    });
  }
}
