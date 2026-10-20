import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/features/profile/data/profile_repository.dart';

import '../support/harness.dart';

void main() {
  appTest('privacy summaries expand without hiding deletion controls', (h) async {
    await h.tapText('Settings');
    await h.tapText('Privacy and data');
    expect(find.byType(ExpansionTile), findsNWidgets(3));
    expect(find.textContaining('not encrypted by Schediel'), findsNothing);
    expect(find.text('Delete local schedules'), findsOneWidget);
    await h.tapText('Storage and profile');
    expect(find.textContaining('not encrypted by Schediel'), findsOneWidget);
    await h.tapText('Storage and profile');
    await h.tapText('Image scanning details');
    expect(find.textContaining('Cloud AI scanning is disabled'), findsOneWidget);
  });
  appTest('profile places its label above the input and still saves a local name', (h) async {
    await h.tapText('Settings');
    await h.tapText('Profile');
    final name = textField('Name');
    final field = h.tester.widget<TextField>(name);
    expect(field.decoration!.labelText, isNull);
    expect(h.tester.getBottomLeft(find.text('Name').last).dy, lessThan(h.tester.getTopLeft(name).dy));
    expect(field.decoration!.border, InputBorder.none);
    await h.tester.enterText(name, 'Fixture name');
    await h.settle();
    await h.tapText('Save name');
    expect((await h.run(h.read(profileRepositoryProvider).load)).name, 'Fixture name');
  });
}
