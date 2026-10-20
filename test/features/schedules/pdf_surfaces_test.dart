import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/theme/app_theme.dart';

import '../../support/harness.dart';

void main() {
  appTest('empty state keeps real copy and schedule illustration', (h) async {
    expect(find.text('No schedules yet'), findsOneWidget);
    expect(find.text('Create schedule'), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-empty-art')), findsOneWidget);
  });

  appTest('theme canvas covers system areas without changing old navigation', (h) async {
    final nav = find.byKey(const ValueKey('nav-today'));
    final context = h.tester.element(nav);
    final region = find.ancestor(of: nav, matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)).first;
    final style = h.tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(region).value;
    expect(style.systemNavigationBarColor, context.scheduleColors.canvas);
    expect(style.statusBarColor, Colors.transparent);
    expect(find.byKey(const ValueKey('nav-week')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-settings')), findsOneWidget);
    expect(find.byTooltip('Add'), findsOneWidget);
  });
}
