import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../theme/app_theme.dart';
import '../theme/schediel_theme.dart';

/// A second accent for gradients: the same color nudged around the hue
/// wheel, so every theme gets a two-tone glow from its own accent.
Color accentPartner(Color accent) {
  final h = Hct.fromInt(accent.toARGB32());
  return Color(Hct.from((h.hue + 38) % 360, h.chroma + 8, (h.tone + 6).clamp(0, 100)).toInt());
}

/// Soft blurred color fields behind a page header (Soft style only), drawn
/// from the theme's own accent so every palette gets its own glow.
class AuraBackdrop extends StatelessWidget {
  const AuraBackdrop({super.key, this.height = 360});
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    if (c.style != StyleFamily.soft) return const SizedBox.shrink();
    final dark = c.palette.brightness == Brightness.dark;
    final a = c.palette.accent;
    final b = accentPartner(a);
    final pink = Color.lerp(a, const Color(0xFFFF5FA2), .55)!;
    final strength = dark ? .22 : .30;
    Widget blob(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: strength)),
    );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60, tileMode: TileMode.decal),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: -60, top: -40, child: blob(a, 240)),
                Positioned(right: -70, top: 40, child: blob(b, 260)),
                Positioned(left: 90, top: 170, child: blob(pink, 200)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Original empty-day illustration painted in the theme's colors: a tilted
/// back card, a front planner card with a checked slot, a glowing orb and a
/// few sparkles. No raster assets.
class DayArt extends StatelessWidget {
  const DayArt({super.key, this.width = 168, this.height = 128});
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final fills = c.palette.categoryFills.values.toList();
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, height),
        painter: _DayArtPainter(
          accent: c.palette.accent,
          partner: accentPartner(c.palette.accent),
          surface: c.surface,
          ink: c.ink,
          back: fills.length > 1 ? fills[1] : c.palette.neutralFill,
          pixel: c.style == StyleFamily.pixel,
          dark: c.palette.brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class _DayArtPainter extends CustomPainter {
  const _DayArtPainter({
    required this.accent,
    required this.partner,
    required this.surface,
    required this.ink,
    required this.back,
    required this.pixel,
    required this.dark,
  });
  final Color accent, partner, surface, ink, back;
  final bool pixel, dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 168);
    final r = pixel ? 0.0 : 14.0;

    // Halo.
    canvas.drawCircle(const Offset(84, 66), 58, Paint()..color = accent.withValues(alpha: dark ? .14 : .10));

    // Back card, tilted.
    canvas
      ..save()
      ..translate(70, 64)
      ..rotate(-0.16)
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-44, -36, 88, 72), Radius.circular(r)), Paint()..color = back)
      ..restore();

    // Front card with a soft shadow and a gradient header band.
    final front = RRect.fromRectAndRadius(const Rect.fromLTWH(54, 30, 86, 76), Radius.circular(r));
    canvas
      ..drawRRect(
        front.shift(const Offset(0, 5)),
        Paint()
          ..color = Colors.black.withValues(alpha: dark ? .35 : .10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawRRect(front, Paint()..color = surface)
      ..save()
      ..clipRRect(front);
    const band = Rect.fromLTWH(54, 30, 86, 18);
    canvas
      ..drawRect(band, Paint()..shader = LinearGradient(colors: [accent, partner]).createShader(band))
      ..restore();

    // Binder rings.
    final ring = Paint()
      ..color = ink.withValues(alpha: .55)
      ..strokeWidth = 3
      ..strokeCap = pixel ? StrokeCap.square : StrokeCap.round;
    canvas
      ..drawLine(const Offset(74, 24), const Offset(74, 35), ring)
      ..drawLine(const Offset(120, 24), const Offset(120, 35), ring);

    // Slots, one of them checked.
    final slot = Paint()..color = ink.withValues(alpha: .12);
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64, 58 + i * 14.0, i == 1 ? 40 : 58, 7), Radius.circular(pixel ? 0 : 3.5)), slot);
    }
    canvas.drawCircle(const Offset(124, 75), 8, Paint()..color = accent);
    canvas.drawPath(
      Path()
        ..moveTo(120.5, 75)
        ..lineTo(123.2, 77.6)
        ..lineTo(127.8, 72.4),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Glowing orb.
    const orb = Offset(138, 26);
    canvas
      ..drawCircle(
        orb,
        15,
        Paint()
          ..color = partner.withValues(alpha: .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawCircle(orb, 11, Paint()..shader = RadialGradient(colors: [partner, accent]).createShader(Rect.fromCircle(center: orb, radius: 11)));

    // Four-point sparkles.
    void sparkle(Offset o, double k) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2;
        path
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx + math.cos(a - .35) * k * .35, o.dy + math.sin(a - .35) * k * .35)
          ..lineTo(o.dx + math.cos(a) * k, o.dy + math.sin(a) * k)
          ..lineTo(o.dx + math.cos(a + .35) * k * .35, o.dy + math.sin(a + .35) * k * .35)
          ..close();
      }
      canvas.drawPath(path, Paint()..color = accent.withValues(alpha: .8));
    }

    sparkle(const Offset(30, 30), 7);
    sparkle(const Offset(150, 104), 5);
    sparkle(const Offset(40, 108), 4);
  }

  @override
  bool shouldRepaint(_DayArtPainter old) =>
      old.accent != accent || old.surface != surface || old.ink != ink || old.back != back || old.pixel != pixel || old.dark != dark;
}
