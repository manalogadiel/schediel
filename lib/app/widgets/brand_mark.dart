import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Schediel mark painted from the same geometry as
/// assets/branding/logo.svg and the Android splash vector
/// (tools/gen_splash_vector.py), so the hand-off from the system splash is
/// pixel-identical. Paints synchronously: no image decode, no blank frame.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 154, this.cellPop = 0, this.glint = -1});

  final double size;

  /// 0..1 bump that enlarges the teal "today" cell.
  final double cellPop;

  /// 0..1 position of a light sweep across the glasses; outside that range
  /// there is no glint.
  final double glint;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _BrandMarkPainter(cellPop: cellPop, glint: glint),
  );
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.cellPop, required this.glint});
  final double cellPop, glint;

  static const body = Color(0xFFF4EADB);
  static const lip = Color(0xFFE3D3B8);
  static const edge = Color(0xFFD6C3A1);
  static const ink = Color(0xFF233548);
  static const cell = Color(0xFFCFC2AC);
  static const teal = Color(0xFF4F9D97);

  static RRect _r(double x, double y, double w, double h, double r) => RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 58);
    canvas
      ..drawRRect(_r(6, 17.5, 46, 39, 9), Paint()..color = lip)
      ..drawRRect(_r(6, 15, 46, 39, 9), Paint()..color = body)
      ..drawRRect(
        _r(6.4, 15.4, 45.2, 38.2, 8.6),
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );

    final hair = Path()
      ..moveTo(6, 25)
      ..lineTo(6, 17)
      ..cubicTo(6, 10, 12, 6, 19, 6)
      ..lineTo(36, 6)
      ..cubicTo(42, 6, 46, 4, 50, 1)
      ..cubicTo(50, 5, 49, 8, 47, 9)
      ..cubicTo(50, 10, 52, 13, 52, 17)
      ..lineTo(52, 25)
      ..cubicTo(46, 21, 38, 19, 29, 19)
      ..cubicTo(20, 19, 12, 21, 6, 25)
      ..close();
    canvas.drawPath(hair, Paint()..color = ink);

    final frame = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final lensFill = Paint()..color = Colors.white.withValues(alpha: .45);
    for (final x in [10.0, 32.0]) {
      final lens = _r(x, 21.5, 16, 11, 3.5);
      canvas.drawRRect(lens, lensFill);
      if (glint >= 0 && glint <= 1) {
        canvas
          ..save()
          ..clipRRect(lens);
        final gx = 4 + glint * 50;
        canvas.drawPath(
          Path()
            ..moveTo(gx, 18)
            ..lineTo(gx + 4, 18)
            ..lineTo(gx - 2, 36)
            ..lineTo(gx - 6, 36)
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: .85),
        );
        canvas.restore();
      }
      canvas.drawRRect(lens, frame);
    }
    canvas.drawLine(const Offset(26, 26.5), const Offset(32, 26.5), frame);

    final cellPaint = Paint()..color = cell;
    for (final (x, y) in const [(12.0, 38.0), (24.0, 38.0), (36.0, 38.0), (12.0, 46.5), (24.0, 46.5)]) {
      canvas.drawRRect(_r(x, y, 10, 6, 1.8), cellPaint);
    }
    final grow = 1 + .28 * math.sin(cellPop.clamp(0, 1) * math.pi);
    canvas
      ..save()
      ..translate(41, 49.5)
      ..scale(grow)
      ..drawRRect(_r(-5, -3, 10, 6, 1.8), Paint()..color = teal)
      ..restore();
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) => old.cellPop != cellPop || old.glint != glint;
}
