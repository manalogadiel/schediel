import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/appearance/appearance.dart';
import '../features/reminders/application/capabilities.dart';
import '../features/reminders/application/foreground_reminders.dart';
import '../features/reminders/application/reconciliation_service.dart';
import '../features/widgets/application/widget_snapshot_service.dart';
import 'lifecycle.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

final routerProvider = Provider<GoRouter>((ref) => buildRouter());

class SchedielApp extends ConsumerStatefulWidget {
  const SchedielApp({super.key});

  @override
  ConsumerState<SchedielApp> createState() => _SchedielAppState();
}

class _SchedielAppState extends ConsumerState<SchedielApp> with WidgetsBindingObserver {
  final _reminders = ForegroundReminderTracker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reminders.resumed(ref.read(clockProvider)());
      ref.read(appLifecycleProvider).onStart();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAccessibilityFeatures() {
    // Reduce Motion changed: rebuild so theme switches become instant.
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.detached) {
      _reminders.paused();
    }
    if (state == AppLifecycleState.resumed) {
      _reminders.resumed(ref.read(clockProvider)());
      ref.read(nowProvider.notifier).refresh();
      ref.invalidate(deviceCapabilitiesProvider);
      ref.read(appLifecycleProvider).onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider);
    final router = ref.watch(routerProvider);
    ref.listen(deviceZoneProvider, (previous, next) {
      if (previous != null && previous != next) ref.read(reconciliationServiceProvider).run(force: true);
    });
    // In-app full-page reminder when one comes due while the app is open.
    ref.listen(scheduledAlertsProvider, (_, _) {});
    ref.listen(nowProvider, (previous, next) {
      final rows = ref.read(scheduledAlertsProvider).value ?? const [];
      for (final due in _reminders.tick(next, rows)) {
        router.push(due.location);
      }
    });
    ref.listen(appearanceProvider, (previous, next) {
      if (previous != null &&
          (previous.themeMode != next.themeMode ||
              previous.theme != next.theme ||
              previous.customHue != next.customHue ||
              previous.showCategoryColors != next.showCategoryColors)) {
        ref.read(widgetSnapshotServiceProvider).refresh();
      }
    });
    final selected = appearance.schedielTheme;
    ThemeData theme(Brightness b) => buildTheme(
          theme: selected,
          brightness: b,
          density: appearance.density,
          showCategoryColors: appearance.showCategoryColors,
        );
    return MaterialApp.router(
      title: 'Schediel',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: effectiveThemeMode(selected, appearance.themeMode),
      // Theme switches cross-fade (screen motion); reduced motion is instant.
      // MaterialApp creates the MediaQuery, so read the platform setting.
      themeAnimationDuration: WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations
          ? Duration.zero
          : Tokens.screenMotion,
      routerConfig: router,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en')],
    );
  }
}
