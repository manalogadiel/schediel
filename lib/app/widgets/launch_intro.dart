import 'package:flutter/material.dart';

/// Short brand intro that continues the native splash: the paper logo lifts
/// slightly, then the paper sheet fades away to reveal the app.
///
/// Holds Flutter's first frame until the logo is decoded so the hand-off from
/// the system splash has no blank flash. Never blocks input, hidden from
/// accessibility, and skipped entirely when Reduce Motion is on.
class LaunchIntro extends StatefulWidget {
  const LaunchIntro({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  static const overlayKey = ValueKey('launch-intro');
  static const paper = Color(0xFFFCF8F1); // android @color/brand_paper
  static const logoAsset = 'assets/branding/splash_logo.png';
  static const logoSize = 160.0; // matches the native splash logo (dp)
  static const duration = Duration(milliseconds: 900);

  @override
  State<LaunchIntro> createState() => _LaunchIntroState();
}

class _LaunchIntroState extends State<LaunchIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: LaunchIntro.duration);
  late bool _show = widget.enabled;
  bool _started = false;
  bool _deferred = false;

  @override
  void initState() {
    super.initState();
    if (_show) {
      WidgetsBinding.instance.deferFirstFrame();
      _deferred = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_show || _started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _show = false;
      _release();
      return;
    }
    // Never hold the first frame for long: a slow or failed decode still plays the intro.
    precacheImage(const AssetImage(LaunchIntro.logoAsset), context)
        .timeout(const Duration(milliseconds: 400), onTimeout: () {})
        .whenComplete(() {
      _release();
      if (!mounted) return;
      _c.forward().whenComplete(() {
        if (mounted) setState(() => _show = false);
      });
    });
  }

  void _release() {
    if (!_deferred) return;
    _deferred = false;
    WidgetsBinding.instance.allowFirstFrame();
  }

  @override
  void dispose() {
    _release();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return widget.child;
    final lift = CurvedAnimation(parent: _c, curve: const Interval(0, 0.5, curve: Curves.easeOutCubic));
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0.35, 1, curve: Curves.easeInCubic));
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          key: LaunchIntro.overlayKey,
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Opacity(
                opacity: 1 - fade.value,
                child: ColoredBox(
                  color: LaunchIntro.paper,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, -6 * lift.value),
                      child: Transform.scale(
                        scale: 1 + 0.04 * lift.value + 0.06 * fade.value,
                        child: const Image(
                          image: AssetImage(LaunchIntro.logoAsset),
                          width: LaunchIntro.logoSize,
                          height: LaunchIntro.logoSize,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
