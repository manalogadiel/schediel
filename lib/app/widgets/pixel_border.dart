import 'package:flutter/widgets.dart';

/// Square shape with stepped (notched) corners, like a pixel-art box.
Path pixelPath(Rect rect, {double step = 3}) {
  final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom, s = step;
  return Path()
    ..moveTo(l + s, t)
    ..lineTo(r - s, t)
    ..lineTo(r - s, t + s)
    ..lineTo(r, t + s)
    ..lineTo(r, b - s)
    ..lineTo(r - s, b - s)
    ..lineTo(r - s, b)
    ..lineTo(l + s, b)
    ..lineTo(l + s, b - s)
    ..lineTo(l, b - s)
    ..lineTo(l, t + s)
    ..lineTo(l + s, t + s)
    ..close();
}

/// Paints a pixel card: optional hard drop shadow, fill and a notched outline.
class PixelBorderPainter extends CustomPainter {
  const PixelBorderPainter({required this.fill, required this.ink, this.shadow = 0, this.width = 2, this.step = 3});

  final Color fill;
  final Color ink;

  /// Hard shadow offset (0 = none).
  final double shadow;
  final double width;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & Size(size.width - shadow, size.height - shadow);
    if (shadow > 0) canvas.drawPath(pixelPath(box.shift(Offset(shadow, shadow)), step: step), Paint()..color = ink);
    canvas.drawPath(pixelPath(box, step: step), Paint()..color = ink);
    canvas.drawPath(pixelPath(box.deflate(width), step: step), Paint()..color = fill);
  }

  @override
  bool shouldRepaint(PixelBorderPainter old) =>
      old.fill != fill || old.ink != ink || old.shadow != shadow || old.width != width || old.step != step;
}

/// Clips children to the pixel shape so ink splashes stay inside.
class PixelClipper extends CustomClipper<Path> {
  const PixelClipper({this.inset = 0, this.step = 3});

  final double inset;
  final double step;

  @override
  Path getClip(Size size) => pixelPath(Offset.zero & size, step: step);

  @override
  bool shouldReclip(PixelClipper old) => old.inset != inset || old.step != step;
}
