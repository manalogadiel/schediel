import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/schedules/presentation/add_menu.dart';
import 'icons.dart';
import 'providers.dart';
import 'theme/app_theme.dart';
import 'theme/schediel_theme.dart';
import 'theme/tokens.dart';
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
          if (!again) HapticFeedback.selectionClick();
          // Tapping Today while on Today jumps back to today's date.
          if (again && i == 0) ref.read(selectedDateProvider.notifier).today();
          navigationShell.goBranch(i, initialLocation: again);
        },
        onAdd: () => showAddMenu(context),
      ),
    );
  }
}

/// Fade-through between shell branches: the old page fades out quickly, then
/// the new one fades in while settling from a hair smaller. Every branch keeps
/// the same wrapper structure so switching never rebuilds its state.
class BranchSwitcher extends StatefulWidget {
  const BranchSwitcher({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  static const duration = Duration(milliseconds: 260);

  @override
  State<BranchSwitcher> createState() => _BranchSwitcherState();
}

class _BranchSwitcherState extends State<BranchSwitcher> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: BranchSwitcher.duration, value: 1);
  int? _previous;

  static const _out = Interval(0, 0.35, curve: Curves.easeIn);
  static const _in = Interval(0.25, 1, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(BranchSwitcher old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _previous = old.index;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _branch(int i, Widget child, double t, bool animating) {
    final current = i == widget.index;
    final leaving = animating && i == _previous;
    final opacity = current ? _in.transform(t) : (leaving ? 1 - _out.transform(t) : 1.0);
    final scale = current ? lerpDouble(0.985, 1, _in.transform(t))! : 1.0;
    return Offstage(
      offstage: !current && !leaving,
      child: TickerMode(
        enabled: current || leaving,
        child: IgnorePointer(
          ignoring: !current,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => Stack(
      fit: StackFit.expand,
      children: [for (final (i, child) in widget.children.indexed) _branch(i, child, _c.value, _c.isAnimating)],
    ),
  );
}

class _Destination {
  const _Destination(this.key, this.icon, this.selectedIcon, this.label);
  final String key;
  final AppIcons icon;
  final AppIcons selectedIcon;
  final String label;
}

const _destinations = [
  _Destination('today', AppIcons.today, AppIcons.todayFill, 'Today'),
  _Destination('week', AppIcons.week, AppIcons.weekFill, 'Week'),
  _Destination('settings', AppIcons.settings, AppIcons.settingsFill, 'Settings'),
];

/// Pill bar floating above content. One highlight glides to the selected
/// destination while its label opens and the previous one closes.
class FloatingNavBar extends StatefulWidget {
  const FloatingNavBar({super.key, required this.selectedIndex, required this.onSelect, required this.onAdd});

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  static const duration = Duration(milliseconds: 300);

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

const _pad = 6.0;
const _slot = 56.0; // unselected width
const _height = 52.0;
const _iconSize = 22.0;
const _labelGap = 8.0;
const _edge = 18.0; // selected horizontal padding

class _FloatingNavBarState extends State<FloatingNavBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: FloatingNavBar.duration, value: 1);
  late int _from = widget.selectedIndex;

  static const _curve = Cubic(0.2, 0.9, 0.1, 1);

  @override
  void didUpdateWidget(FloatingNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex == widget.selectedIndex) return;
    _from = old.selectedIndex;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static TextStyle _labelStyle(Color color) => TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color);

  /// Extra width each destination needs when selected, capped so the bar
  /// never overflows; the label ellipsizes instead.
  List<double> _extras(double maxWidth, TextScaler scaler, TextStyle style) {
    final room = math.max(0.0, maxWidth - 2 * _pad - _slot * _destinations.length);
    return [
      for (final d in _destinations)
        () {
          final label = TextPainter(
            text: TextSpan(text: d.label, style: style),
            textScaler: scaler,
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();
          final needed = label.width.ceilToDouble() + 1 + 2 * _edge + _iconSize + _labelGap - _slot;
          label.dispose();
          return math.min(room, needed);
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final p = c.palette;
    final pixel = c.style == StyleFamily.pixel;
    final radius = BorderRadius.circular(pixel ? 0 : Tokens.radiusPill);
    final scaler = MediaQuery.textScalerOf(context);
    final shape = pixel ? const RoundedRectangleBorder() : const StadiumBorder();
    // Measure with the exact style the label renders in (theme font included).
    final labelStyle = DefaultTextStyle.of(context).style.merge(_labelStyle(p.navOnSelected));

    final bar = LayoutBuilder(
      builder: (context, constraints) {
        final extras = _extras(constraints.maxWidth, scaler, labelStyle);
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _curve.transform(_c.value);
            final to = widget.selectedIndex;
            final n = _destinations.length;
            final open = [for (var i = 0; i < n; i++) lerpDouble(i == _from ? 1 : 0, i == to ? 1 : 0, t)!];
            final widths = [for (var i = 0; i < n; i++) _slot + open[i] * extras[i]];
            double leftOf(int k) => widths.take(k).fold(0.0, (a, b) => a + b);
            final glass = c.style == StyleFamily.soft;
            final box = DecoratedBox(
              decoration: BoxDecoration(
                color: glass ? p.navBackground.withValues(alpha: .80) : p.navBackground,
                borderRadius: radius,
                border: c.outlined ? Border.all(color: p.outline, width: 2) : null,
                boxShadow: switch (c.style) {
                  StyleFamily.soft => null,
                  StyleFamily.pop || StyleFamily.pixel => [BoxShadow(color: p.outline, offset: const Offset(3, 3))],
                  StyleFamily.sketch => null,
                },
              ),
              child: Padding(
                padding: const EdgeInsets.all(_pad),
                child: SizedBox(
                  height: _height,
                  width: leftOf(n),
                  child: Stack(
                    children: [
                      Positioned(
                        left: lerpDouble(leftOf(_from), leftOf(to), t),
                        width: lerpDouble(widths[_from], widths[to], t),
                        top: 0,
                        bottom: 0,
                        child: DecoratedBox(decoration: ShapeDecoration(color: p.navSelected, shape: shape)),
                      ),
                      Row(
                        children: [
                          for (final (i, d) in _destinations.indexed)
                            _NavItem(
                              destination: d,
                              selected: i == to,
                              open: open[i],
                              width: widths[i],
                              labelWidth: math.max(0, extras[i] + _slot - 2 * _edge - _iconSize - _labelGap),
                              iconLeft: lerpDouble((_slot - _iconSize) / 2, _edge, open[i])!,
                              color: Color.lerp(p.navInk, p.navOnSelected, open[i])!,
                              labelStyle: labelStyle,
                              shape: shape,
                              onTap: () => widget.onSelect(i),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            if (!glass) return box;
            // Frosted glass: blur whatever scrolls beneath the bar.
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [BoxShadow(color: const Color(0xFF000000).withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: box),
              ),
            );
          },
        );
      },
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
            ThemedIconButton(icon: AppIcons.add, tooltip: 'Add', onPressed: widget.onAdd, filled: true, size: 56),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.open,
    required this.width,
    required this.labelWidth,
    required this.iconLeft,
    required this.color,
    required this.labelStyle,
    required this.shape,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final double open, width, labelWidth, iconLeft;
  final Color color;
  final TextStyle labelStyle;
  final ShapeBorder shape;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          child: SizedBox(
            width: width,
            height: _height,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: iconLeft),
                    _NavIcon(destination: destination, selected: selected, color: color),
                    if (open > 0) ...[
                      const SizedBox(width: _labelGap),
                      Opacity(
                        opacity: Curves.easeIn.transform(open),
                        child: Transform.translate(
                          offset: Offset(-6 * (1 - open), 0),
                          child: SizedBox(
                            width: labelWidth,
                            child: Text(
                              destination.label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: labelStyle.copyWith(color: color),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plays a short gesture when its destination becomes selected: Today's page
/// drops in, Week's columns rise, Settings' gear turns.
class _NavIcon extends StatefulWidget {
  const _NavIcon({required this.destination, required this.selected, required this.color});

  final _Destination destination;
  final bool selected;
  final Color color;

  @override
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420), value: 1);

  @override
  void didUpdateWidget(_NavIcon old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected && !MediaQuery.disableAnimationsOf(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    return AnimatedBuilder(
      animation: _c,
      child: AppIcon(widget.selected ? d.selectedIcon : d.icon, size: _iconSize, color: widget.color),
      builder: (context, child) {
        final t = _c.value;
        final back = Curves.easeOutBack.transform(t);
        final gesture = switch (d.key) {
          'today' => Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.004)
              ..rotateX(-(1 - back) * 1.1),
            child: child,
          ),
          'week' => Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(1, lerpDouble(0.55, 1, back)!, 1),
            child: child,
          ),
          _ => Transform.rotate(angle: -(1 - Curves.easeOutCubic.transform(t)) * math.pi / 3, child: child),
        };
        return Transform.scale(scale: lerpDouble(0.88, 1, back)!, child: gesture);
      },
    );
  }
}
