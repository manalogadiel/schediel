import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/schedules/presentation/add_menu.dart';
import 'icons.dart';
import 'providers.dart';
import 'theme/app_theme.dart';
import 'theme/schediel_theme.dart';
import 'theme/tokens.dart';
import 'widgets/common.dart';
import 'widgets/themed.dart';

/// Three destinations (Today, Week, Settings) in a floating bar, plus a
/// separate add button (spec 4.1; revamp §4).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Bottom padding a scrolling page needs so its last item clears the bar.
  /// The shell extends the body behind the bar, so Scaffold already reports
  /// the bar's height as bottom padding.
  static double bottomInset(BuildContext context) => MediaQuery.paddingOf(context).bottom + Tokens.md;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: navigationShell.currentIndex,
        onSelect: (i) {
          final again = i == navigationShell.currentIndex;
          // Tapping Today while on Today jumps back to today's date.
          if (again && i == 0) ref.read(selectedDateProvider.notifier).today();
          navigationShell.goBranch(i, initialLocation: again);
        },
        onAdd: () => showAddMenu(context),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.key, this.icon, this.label);
  final String key;
  final AppIcons icon;
  final String label;
}

const _destinations = [
  _Destination('today', AppIcons.calendar, 'Today'),
  _Destination('week', AppIcons.week, 'Week'),
  _Destination('settings', AppIcons.settings, 'Settings'),
];

/// Pill bar floating above content; the selected destination shows its label.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.selectedIndex, required this.onSelect, required this.onAdd});

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final p = c.palette;
    final pixel = c.style == StyleFamily.pixel;
    final radius = BorderRadius.circular(pixel ? 0 : Tokens.radiusPill);
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: p.navBackground,
        borderRadius: radius,
        border: c.outlined ? Border.all(color: p.outline, width: 2) : null,
        boxShadow: switch (c.style) {
          StyleFamily.soft => [BoxShadow(color: const Color(0xFF000000).withValues(alpha: 0.14), blurRadius: 20, offset: const Offset(0, 6))],
          StyleFamily.pop || StyleFamily.pixel => [BoxShadow(color: p.outline, offset: const Offset(3, 3))],
          StyleFamily.sketch => null,
        },
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, d) in _destinations.indexed)
              if (i == selectedIndex)
                // The label gives way (ellipsis) before the bar overflows.
                Flexible(child: _NavItem(destination: d, selected: true, onTap: () => onSelect(i), pixel: pixel))
              else
                _NavItem(destination: d, selected: false, onTap: () => onSelect(i), pixel: pixel),
          ],
        ),
      ),
    );
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: Tokens.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.xs, Tokens.md, Tokens.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: bar),
            const SizedBox(width: Tokens.sm),
            ThemedIconButton(icon: AppIcons.add, tooltip: 'Add', onPressed: onAdd, filled: true, size: 56),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected, required this.onTap, required this.pixel});

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool pixel;

  @override
  Widget build(BuildContext context) {
    final p = context.scheduleColors.palette;
    final fg = selected ? p.navOnSelected : p.navInk;
    final shape = pixel ? const RoundedRectangleBorder() : const StadiumBorder();
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Material(
        key: ValueKey('nav-${destination.key}'),
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.control(context),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 52, minWidth: 56),
            padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 14),
            decoration: ShapeDecoration(color: selected ? p.navSelected : Colors.transparent, shape: shape),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(destination.icon, size: 22, color: fg),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
