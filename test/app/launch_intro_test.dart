import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/widgets/launch_intro.dart';

Widget _host({required bool enabled, bool reduceMotion = false, VoidCallback? onTap}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: LaunchIntro(
          enabled: enabled,
          child: Scaffold(body: Center(child: TextButton(onPressed: onTap, child: const Text('Below')))),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('intro covers the app with the brand logo, then removes itself', (tester) async {
    await tester.pumpWidget(_host(enabled: true));
    expect(find.byKey(LaunchIntro.overlayKey), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500)); // capped decode wait, then start
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(LaunchIntro.overlayKey), findsOneWidget, reason: 'still animating');

    await tester.pumpAndSettle();
    expect(find.byKey(LaunchIntro.overlayKey), findsNothing);
    expect(find.text('Below'), findsOneWidget);
  });

  testWidgets('intro never blocks taps on the app underneath', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(enabled: true, onTap: () => taps++));
    expect(find.byKey(LaunchIntro.overlayKey), findsOneWidget);
    await tester.tap(find.text('Below'), warnIfMissed: false);
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('reduce motion and disabled intro show the app immediately', (tester) async {
    await tester.pumpWidget(_host(enabled: true, reduceMotion: true));
    expect(find.byKey(LaunchIntro.overlayKey), findsNothing);
    await tester.pumpWidget(_host(enabled: false));
    expect(find.byKey(LaunchIntro.overlayKey), findsNothing);
  });
}
