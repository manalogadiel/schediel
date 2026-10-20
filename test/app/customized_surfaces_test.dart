import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/theme/theme_customization.dart';
import 'package:schediel/app/theme/schediel_theme.dart';
import 'package:schediel/features/appearance/appearance.dart';

import '../support/harness.dart';

void main() {
  Future<void> customize(TestHarness h) async {
    await h.run(
      () => h
          .read(appearanceProvider.notifier)
          .update(
            (s) => s.copyWith(
              themeMode: ThemeMode.dark,
              customizations: {ThemeId.lilac: const ThemeCustomization(mainTone: 100, backgroundTone: 100)},
            ),
          ),
    );
    await h.settle();
  }

  appTest('system icons follow the actual customized canvas rather than the mode name', (h) async {
    await customize(h);
    final region = h.tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(find.byType(AnnotatedRegion<SystemUiOverlayStyle>))
        .firstWhere((r) => r.value.systemNavigationBarColor != null);
    expect(region.value.systemNavigationBarIconBrightness, Brightness.dark);
    expect(region.value.statusBarIconBrightness, Brightness.dark);
  });
  appTest('a low-contrast selected date gets a visible boundary in soft themes', (h) async {
    await customize(h);
    final date = h.read(effectiveDateProvider);
    final material = h.tester.widget<Material>(find.byKey(ValueKey('day-${date.toIso()}')));
    expect((material.shape! as OutlinedBorder).side.style, BorderStyle.solid);
  });
}
