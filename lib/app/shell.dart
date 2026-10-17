import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'icons.dart';

/// Three destinations: Today, Week, Settings (spec 4.1).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    AppIcon icon(AppIcons i, bool selected) =>
        AppIcon(i, color: selected ? scheme.onSurface : scheme.onSurfaceVariant);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(icon: icon(AppIcons.calendar, false), selectedIcon: icon(AppIcons.calendar, true), label: 'Today'),
          NavigationDestination(icon: icon(AppIcons.week, false), selectedIcon: icon(AppIcons.week, true), label: 'Week'),
          NavigationDestination(icon: icon(AppIcons.settings, false), selectedIcon: icon(AppIcons.settings, true), label: 'Settings'),
        ],
      ),
    );
  }
}
