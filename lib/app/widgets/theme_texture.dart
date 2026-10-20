import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_customization.dart';
import 'art.dart';

/// Decoration may only move canvas colors within the text's contrast budget.
/// Searches down from a visible strength until every text color keeps 4.5:1.
Color textureOverlay(ScheduleColors c) {
  double minimum(Color shade) {
    final background = Color.alphaBlend(shade, c.canvas);
    return [c.ink, c.secondaryInk, c.accentText].map((ink) => contrastRatio(ink, background)).reduce((a, b) => a < b ? a : b);
  }

  // Prefer marks that contrast with the canvas. Maximizing text contrast
  // first picked white on near-white canvases, making the texture invisible.
  final shades = c.canvas.computeLuminance() > .5
      ? [Colors.black, Colors.white]
      : [Colors.white, Colors.black];
  for (final color in shades) {
    for (var alpha = .12; alpha >= .0025; alpha *= .7) {
      final shade = color.withValues(alpha: alpha);
      if (minimum(shade) >= 4.5) return shade;
    }
  }
  return Colors.transparent;
}

/// Paints the app's chosen texture behind everything; never interactive.
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
              child: TextureLayer(texture, shade: textureOverlay(c), background: c.canvas, accent: c.palette.accent),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Rasterize static decoration once instead of submitting thousands of grain
/// marks to the GPU on every scroll/blur frame. Flutter's bounded image cache
/// shares equal surfaces and owns their lifetime, including memory pressure.
class TextureLayer extends StatelessWidget {
  const TextureLayer(this.texture, {super.key, required this.shade, this.background, this.accent});
  final ThemeTexture texture;
  final Color shade;
  final Color? background, accent;

  @override
  Widget build(BuildContext context) {
    if (texture == ThemeTexture.none) return ColoredBox(color: background ?? Colors.transparent);
    return RepaintBoundary(child: LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      if (!size.isFinite || size.isEmpty) return const SizedBox.shrink();
      return Image(
        image: TextureImage(texture, size: size, shade: shade, background: background,
          accent: accent, pixelRatio: math.min(MediaQuery.devicePixelRatioOf(context), 2048 / size.longestSide)),
        width: size.width,
        height: size.height,
        fit: BoxFit.fill,
        excludeFromSemantics: true,
        // Retain the canvas while a new size/color is rasterized; never show
        // a previous theme's cached image after an appearance change.
        frameBuilder: (_, child, frame, _) => frame == null
            ? ColoredBox(color: background ?? Colors.transparent)
            : child,
        errorBuilder: (_, _, _) => ColoredBox(color: background ?? Colors.transparent),
      );
    }));
  }
}

@visibleForTesting
class TextureImage extends ImageProvider<TextureImage> {
  const TextureImage(this.texture, {required this.size, required this.shade,
    required this.pixelRatio, this.background, this.accent});
  final ThemeTexture texture;
  final Size size;
  final Color shade;
  final double pixelRatio;
  final Color? background, accent;

  @override
  Future<TextureImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(TextureImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(key._rasterize());

  Future<ImageInfo> _rasterize() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    TexturePainter(texture, shade: shade, background: background, accent: accent).paint(canvas, size);
    final picture = recorder.endRecording();
    try {
      return ImageInfo(image: await picture.toImage(
        math.max(1, (size.width * pixelRatio).ceil()),
        math.max(1, (size.height * pixelRatio).ceil())), scale: pixelRatio);
    } finally {
      picture.dispose();
    }
  }

  @override
  bool operator ==(Object other) => other is TextureImage && texture == other.texture &&
      size == other.size && shade == other.shade && pixelRatio == other.pixelRatio &&
      background == other.background && accent == other.accent;
  @override
  int get hashCode => Object.hash(texture, size, shade, pixelRatio, background, accent);
}

/// Draws one texture pattern in [shade] (a translucent black or white),
/// optionally over a solid [background]. Deterministic, so it never shimmers
/// between frames.
class TexturePainter extends CustomPainter {
  const TexturePainter(this.texture, {required this.shade, this.background, this.accent});
  final ThemeTexture texture;
  final Color shade;
  final Color? background, accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (background != null) canvas.drawRect(rect, Paint()..color = background!);
    if (shade.a == 0 && texture != ThemeTexture.mesh) return;
    final stroke = Paint()
      ..color = shade
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = shade;
    switch (texture) {
      case ThemeTexture.none:
        return;
      case ThemeTexture.stripes:
        stroke.strokeWidth = 1.4;
        for (var x = 0.0; x < size.width + size.height; x += 22) {
          canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), stroke);
        }
      case ThemeTexture.paper:
        // Fibrous grain: short random dashes plus specks.
        final r = math.Random(7);
        final count = (size.width * size.height / 70).clamp(0, 9000).toInt();
        stroke.strokeWidth = .7;
        for (var i = 0; i < count; i++) {
          final p = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
          if (i % 3 == 0) {
            final a = r.nextDouble() * math.pi;
            final l = 2 + r.nextDouble() * 4;
            canvas.drawLine(p, p + Offset(math.cos(a) * l, math.sin(a) * l), stroke);
          } else {
            canvas.drawRect(Rect.fromLTWH(p.dx, p.dy, .9, .9), fill);
          }
        }
      case ThemeTexture.dots:
        for (var y = 8.0; y < size.height; y += 16) {
          for (var x = 8.0 + ((y ~/ 16) % 2) * 8; x < size.width; x += 16) {
            canvas.drawCircle(Offset(x, y), 1.3, fill);
          }
        }
      case ThemeTexture.grid:
        stroke.strokeWidth = .8;
        for (var x = 0.0; x < size.width; x += 24) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), stroke);
        }
        for (var y = 0.0; y < size.height; y += 24) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), stroke);
        }
      case ThemeTexture.carbon:
        // Woven twill: alternating half cells read as interlaced fibres.
        const cell = 8.0;
        final light = Paint()..color = shade.withValues(alpha: shade.a * .45);
        var row = 0;
        for (var y = 0.0; y < size.height; y += cell, row++) {
          var col = 0;
          for (var x = 0.0; x < size.width; x += cell, col++) {
            final horizontal = (row + col).isEven;
            final a = horizontal ? Rect.fromLTWH(x, y, cell, cell / 2) : Rect.fromLTWH(x, y, cell / 2, cell);
            final b = horizontal ? Rect.fromLTWH(x, y + cell / 2, cell, cell / 2) : Rect.fromLTWH(x + cell / 2, y, cell / 2, cell);
            canvas
              ..drawRect(a.deflate(.4), fill)
              ..drawRect(b.deflate(.4), light);
          }
        }
      case ThemeTexture.graphite:
        // Brushed metal: long faint horizontal strokes of varying weight.
        final r = math.Random(11);
        for (var y = 0.0; y < size.height; y += 1.6) {
          final start = r.nextDouble() * size.width * .3;
          final length = size.width * (.4 + r.nextDouble() * .7);
          final p = Paint()
            ..color = shade.withValues(alpha: shade.a * (.25 + r.nextDouble() * .75))
            ..strokeWidth = .6 + r.nextDouble() * .6;
          canvas.drawLine(Offset(start, y), Offset(start + length, y), p);
        }
      case ThemeTexture.flow:
        // Flowing contour lines drifting across the page.
        stroke.strokeWidth = 1.1;
        for (var i = -4; i < size.height / 18 + 4; i++) {
          final path = Path();
          final base = i * 18.0;
          for (var x = 0.0; x <= size.width + 8; x += 8) {
            final y = base + math.sin(x / 70 + i * .35) * 22 + math.sin(x / 23 + i * .9) * 4;
            x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
          }
          canvas.drawPath(path, stroke);
        }
      case ThemeTexture.topo:
        // Topographic rings around two summits.
        for (final (center, phase) in [
          (Offset(size.width * .78, size.height * .16), 0.0),
          (Offset(size.width * .18, size.height * .72), 1.7),
        ]) {
          for (var ring = 1; ring < 26; ring++) {
            final path = Path();
            for (var k = 0; k <= 72; k++) {
              final a = k / 72 * 2 * math.pi;
              final radius = ring * 16 + math.sin(a * 3 + phase + ring * .3) * (4 + ring * .5) + math.sin(a * 5 - phase) * 3;
              final o = center + Offset(math.cos(a) * radius, math.sin(a) * radius * .82);
              k == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
            }
            canvas.drawPath(path..close(), stroke);
          }
        }
      case ThemeTexture.mesh:
        // Soft mesh gradient from the accent and its partner hue.
        final a = accent ?? shade;
        final b = accentPartner(a);
        for (final (center, color, radius) in [
          (Offset(size.width * .1, size.height * .05), a, size.longestSide * .55),
          (Offset(size.width * .95, size.height * .35), b, size.longestSide * .5),
          (Offset(size.width * .3, size.height * .95), Color.lerp(a, b, .5)!, size.longestSide * .5),
        ]) {
          canvas.drawRect(
            rect,
            Paint()
              ..shader = RadialGradient(
                colors: [color.withValues(alpha: .10), color.withValues(alpha: 0)],
              ).createShader(Rect.fromCircle(center: center, radius: radius)),
          );
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
  bool shouldRepaint(TexturePainter old) =>
      old.texture != texture || old.background != background || old.shade != shade || old.accent != accent;
}
