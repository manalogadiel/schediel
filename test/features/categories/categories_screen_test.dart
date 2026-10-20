import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/harness.dart';

void main() {
  appTest('settings and categories use soft colored icons with separated rows', (h) async {
    await h.tapText('Settings');
    final appearance = find.byKey(const ValueKey('settings-icon-appearance'));
    expect(appearance, findsOneWidget);
    expect(h.tester.getSize(appearance), const Size(40, 40));
    await h.tapText('Categories');
    for (final id in ['school', 'work', 'personal']) {
      expect(find.byKey(ValueKey('category-icon-$id')), findsOneWidget);
    }
    final gap =
        h.tester.getTopLeft(find.byKey(const ValueKey('work'))).dy -
        h.tester.getBottomLeft(find.byKey(const ValueKey('school'))).dy;
    expect(gap, greaterThanOrEqualTo(8));
    await h.tapText('School');
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Delete category'), findsOneWidget);
  });
}
