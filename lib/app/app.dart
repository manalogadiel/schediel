import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/appearance/appearance.dart';
import '../features/reminders/application/capabilities.dart';
import '../features/reminders/application/reconciliation_service.dart';
import '../features/widgets/application/widget_snapshot_service.dart';
import 'lifecycle.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

final routerProvider = Provider<GoRouter>((ref) => buildRouter());

class SchedielApp extends ConsumerStatefulWidget {
  const SchedielApp({super.key});

  @override
  ConsumerState<SchedielApp> createState() => _SchedielAppState();
}

class _SchedielAppState extends ConsumerState<SchedielApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(appLifecycleProvider).onStart());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
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
    ref.listen(appearanceProvider, (previous, next) {
      if (previous != null && previous.themeMode != next.themeMode) ref.read(widgetSnapshotServiceProvider).refresh();
    });
    ThemeData theme(Brightness b) => buildTheme(
          brightness: b,
          accent: appearance.accent,
          density: appearance.density,
          showCategoryColors: appearance.showCategoryColors,
        );
    return MaterialApp.router(
      title: 'Schediel',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: appearance.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 160),
      routerConfig: router,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en')],
    );
  }
}
