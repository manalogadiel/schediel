import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_customization.dart';

/// Decoration may only move canvas colors within the text's contrast budget.
Color textureOverlay(ScheduleColors c) {
  double minimum(Color shade) {
    final background = Color.alphaBlend(shade, c.canvas);
    return [c.ink, c.secondaryInk, c.accentText].map((ink) => contrastRatio(ink, background)).reduce((a, b) => a < b ? a : b);
  }

  for (var alpha = .04; alpha >= .0025; alpha /= 2) {
    final black = Colors.black.withValues(alpha: alpha), white = Colors.white.withValues(alpha: alpha);
    final best = minimum(black) >= minimum(white) ? black : white;
    if (minimum(best) >= 4.5) return best;
  }
  return Colors.transparent;
}

class ThemeTextureSurface extends StatelessWidget {
  const ThemeTextureSurface({super.key, required this.texture, required this.child});
  final ThemeTexture texture;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  isComplex: texture == ThemeTexture.paper,
                  painter: _TexturePainter(texture, c.canvas, textureOverlay(c)),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _TexturePainter extends CustomPainter {
  const _TexturePainter(this.texture, this.background, this.shade);
  final ThemeTexture texture;
  final Color background, shade;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = background);
    final paint = Paint()
      ..color = shade
      ..strokeWidth = 1;
    switch (texture) {
      case ThemeTexture.none:
        return;
      case ThemeTexture.stripes:
        for (var x = 0.0; x < size.width + size.height; x += 28) {
          canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), paint);
        }
      case ThemeTexture.paper:
        for (var y = 6.0; y < size.height; y += 12) {
          for (var x = 6.0; x < size.width; x += 12) {
            canvas.drawCircle(Offset(x + ((y.toInt() ~/ 12) % 2) * 3, y), .65, paint);
          }
        }
      case ThemeTexture.gradient:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [shade.withValues(alpha: 0), shade],
            ).createShader(rect),
        );
    }
  }

  @override
  bool shouldRepaint(_TexturePainter oldDelegate) =>
      oldDelegate.texture != texture || oldDelegate.background != background || oldDelegate.shade != shade;
}
