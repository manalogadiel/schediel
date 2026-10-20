import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  appTest(
    'licenses open as short credits and retain every complete bundled notice',
    (h) async {
      await h.tapText('Settings');
      await h.tester.scrollUntilVisible(
        find.text('Open source licenses'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await h.tapText('Open source licenses');
      expect(find.text('Credits and licenses'), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing);
      for (final (name, asset) in const [
        ('Inter', 'assets/fonts/LICENSE-Inter.txt'),
        ('Caveat', 'assets/fonts/LICENSE-Caveat.txt'),
        ('Silkscreen', 'assets/fonts/LICENSE-Silkscreen.txt'),
        ('Lucide icons', 'assets/icons/LICENSE-lucide.txt'),
      ]) {
        await h.tapText(name);
        final original = await h.run(() => rootBundle.loadString(asset));
        expect(
          h.tester.widget<SelectableText>(find.byType(SelectableText)).data,
          original,
        );
        await h.tester.pageBack();
        await h.settle();
      }
      await h.tapText('All library licenses');
      expect(find.byType(LicensePage), findsOneWidget);
    },
  );
}
