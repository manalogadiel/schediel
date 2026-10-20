import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'brand_mark.dart';

/// Short brand intro that continues the native splash: the vector mark sits
/// exactly where the system left it, its "today" cell pops and the glasses
/// catch the light, then it lifts while the wordmark types in letter by
/// letter with the tagline, and the paper sheet slides away to the app.
///
/// Paints synchronously (no image decode), never blocks input, is hidden from
/// accessibility and is skipped entirely when Reduce Motion is on.
class LaunchIntro extends StatefulWidget {
  const LaunchIntro({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  static const overlayKey = ValueKey('launch-intro');
  static const markKey = ValueKey('launch-intro-mark');
  static const paper = Color(0xFFFCF8F1); // android @color/brand_paper
  static const ink = Color(0xFF233548);
  static const logoSize = 154.0; // matches the Android 12+ system splash icon (dp)
  static const duration = Duration(milliseconds: 1150);
  static const wordmark = 'Schediel';
  static const tagline = 'Your week, in order.';

  @override
  State<LaunchIntro> createState() => _LaunchIntroState();
}

class _LaunchIntroState extends State<LaunchIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: LaunchIntro.duration);
  late bool _show = widget.enabled;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_show || _started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _show = false;
      return;
    }
    _c.forward().whenComplete(() {
      if (mounted) setState(() => _show = false);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _seg(double t, double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  Widget _letter(double t, int i) {
    final k = _seg(t, .28 + i * .035, .48 + i * .035);
    return Opacity(
      opacity: k,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - k)),
        child: Text(
          LaunchIntro.wordmark[i],
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -.6,
            color: LaunchIntro.ink,
            height: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          key: LaunchIntro.overlayKey,
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                final lift = _seg(t, .18, .5);
                final exit = _seg(t, .8, 1, Curves.easeInCubic);
                final tag = _seg(t, .52, .7);
                return Opacity(
                  opacity: 1 - exit,
                  child: Transform.translate(
                    offset: Offset(0, -28 * exit),
                    child: ColoredBox(
                      color: LaunchIntro.paper,
                      // The system splash centres its icon below the status bar;
                      // match it so the hand-off doesn't jump.
                      child: Padding(
                        padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.translate(
                              offset: Offset(0, -54 * lift),
                              child: Transform.scale(
                                scale: lerpDouble(1, .74, lift)!,
                                child: BrandMark(
                                  key: LaunchIntro.markKey,
                                  size: LaunchIntro.logoSize,
                                  cellPop: _seg(t, 0, .26, Curves.linear),
                                  glint: t < .04 || t > .34 ? -1 : _seg(t, .04, .34, Curves.easeInOut),
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, 50),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [for (var i = 0; i < LaunchIntro.wordmark.length; i++) _letter(t, i)],
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(0, 86 + 6 * (1 - tag)),
                              child: Opacity(
                                opacity: tag,
                                child: const Text(
                                  LaunchIntro.tagline,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: .2,
                                    color: Color(0xFF6B6457),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
