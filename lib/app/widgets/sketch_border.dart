import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A hand-drawn rounded-rectangle outline. The wobble is derived only from
/// [seed], so a card looks the same on every frame and every launch.
class SketchOutline {
  const SketchOutline(this.points);

  /// Closed polygon through the wobbly perimeter, in local coordinates.
  final List<Offset> points;

  Path toPath() {
    final path = Path();
    if (points.isEmpty) return path;
    // Smooth through midpoints so the line reads as pen, not polygon.
    Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final start = mid(points.last, points.first);
    path.moveTo(start.dx, start.dy);
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final next = mid(p, points[(i + 1) % points.length]);
      path.quadraticBezierTo(p.dx, p.dy, next.dx, next.dy);
    }
    return path..close();
  }
}

/// Stable 32-bit FNV-1a hash of the seed's string form (Object.hashCode is
/// not guaranteed stable between runs).
int stableSeed(Object? seed) {
  var h = 0x811c9dc5;
  for (final unit in (seed ?? '').toString().codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// Paints a sketch-style card: wobbly fill, a main pen line and a lighter
/// second pass slightly off the first.
class SketchBorderPainter extends CustomPainter {
  SketchBorderPainter({required this.seed, required this.fill, required this.ink, this.radius = 18, this.strokeWidth = 2});

  final Object? seed;
  final Color fill;
  final Color ink;
  final double radius;
  final double strokeWidth;

  static const _jitter = 1.4;

  static SketchOutline outline(Size size, {required Object? seed, required double radius, int pass = 0}) {
    final random = math.Random(stableSeed(seed) ^ (pass * 0x9e3779b9));
    final r = math.min(radius, math.min(size.width, size.height) / 2);
    final base = _roundedRectPoints(size, r);
    return SketchOutline([
      for (final p in base)
        Offset(p.dx + (random.nextDouble() * 2 - 1) * _jitter, p.dy + (random.nextDouble() * 2 - 1) * _jitter),
    ]);
  }

  /// Evenly spaced perimeter samples of a rounded rectangle.
  static List<Offset> _roundedRectPoints(Size size, double r) {
    final points = <Offset>[];
    const step = 14.0;
    void line(Offset a, Offset b) {
      final n = math.max(1, ((b - a).distance / step).round());
      for (var i = 0; i < n; i++) {
        points.add(Offset.lerp(a, b, i / n)!);
      }
    }

    void arc(Offset center, double start) {
      for (var i = 0; i < 3; i++) {
        final a = start + (math.pi / 2) * (i / 3);
        points.add(center + Offset(math.cos(a), math.sin(a)) * r);
      }
    }

    final w = size.width, h = size.height;
    line(Offset(r, 0), Offset(w - r, 0));
    arc(Offset(w - r, r), -math.pi / 2);
    line(Offset(w, r), Offset(w, h - r));
    arc(Offset(w - r, h - r), 0);
    line(Offset(w - r, h), Offset(r, h));
    arc(Offset(r, h - r), math.pi / 2);
    line(Offset(0, h - r), Offset(0, r));
    arc(Offset(r, r), math.pi);
    return points;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final main = outline(size, seed: seed, radius: radius).toPath();
    canvas.drawPath(main, Paint()..color = fill);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = ink;
    canvas.drawPath(main, pen);
    canvas.drawPath(
      outline(size, seed: seed, radius: radius, pass: 1).toPath(),
      pen
        ..strokeWidth = strokeWidth * 0.6
        ..color = ink.withValues(alpha: ink.a * 0.45),
    );
  }

  @override
  bool shouldRepaint(SketchBorderPainter old) =>
      old.seed != seed || old.fill != fill || old.ink != ink || old.radius != radius || old.strokeWidth != strokeWidth;
}
