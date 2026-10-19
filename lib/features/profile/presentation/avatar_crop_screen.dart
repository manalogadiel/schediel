import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/schediel_theme.dart';
import '../../../app/theme/tokens.dart';
import '../data/profile_repository.dart';

/// Square pan/zoom crop with a round (square for Pixel) mask. Returns the
/// chosen region in upright image pixels, or null on cancel. Nothing is
/// saved here.
class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({super.key, required this.image, required this.imageSize});

  final ImageProvider image;

  /// Upright image size in pixels.
  final Size imageSize;

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _controller = TransformationController();
  double _viewport = 0;
  bool _centered = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Visible square in image pixels for the current pan and zoom.
  SquareCrop crop() {
    final m = _controller.value;
    final scale = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    final shortest = math.min(widget.imageSize.width, widget.imageSize.height);
    final perPoint = shortest / _viewport; // image pixels per child point
    final side = (_viewport / scale * perPoint).round();
    final left = (-t.x / scale * perPoint).round();
    final top = (-t.y / scale * perPoint).round();
    return SquareCrop(
      left.clamp(0, (widget.imageSize.width - side).round().clamp(0, 1 << 30)),
      top.clamp(0, (widget.imageSize.height - side).round().clamp(0, 1 << 30)),
      side.clamp(1, shortest.round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.scheduleColors;
    final square = c.style == StyleFamily.pixel;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop photo'),
        leading: IconButton(tooltip: 'Cancel', icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.md),
          child: Column(
            children: [
              Text('Drag and pinch to frame your photo.', style: TextStyle(color: c.secondaryInk)),
              const SizedBox(height: Tokens.md),
              Expanded(
                child: LayoutBuilder(builder: (context, box) {
                  _viewport = math.min(box.maxWidth, box.maxHeight);
                  final shortest = math.min(widget.imageSize.width, widget.imageSize.height);
                  final childW = _viewport * widget.imageSize.width / shortest;
                  final childH = _viewport * widget.imageSize.height / shortest;
                  if (!_centered && _viewport > 0) {
                    // Start on the middle of the photo.
                    _centered = true;
                    _controller.value = Matrix4.translationValues(-(childW - _viewport) / 2, -(childH - _viewport) / 2, 0);
                  }
                  return Center(
                    child: SizedBox.square(
                      dimension: _viewport,
                      child: Stack(children: [
                        ClipRect(
                          child: InteractiveViewer(
                            transformationController: _controller,
                            constrained: false,
                            minScale: 1,
                            maxScale: 6,
                            child: Image(
                              image: widget.image,
                              width: childW,
                              height: childH,
                              fit: BoxFit.fill,
                              semanticLabel: 'Photo to crop',
                            ),
                          ),
                        ),
                        IgnorePointer(child: CustomPaint(size: Size.square(_viewport), painter: _MaskPainter(square: square, color: c.canvas))),
                      ]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: Tokens.md),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
                const SizedBox(width: Tokens.md),
                Expanded(child: FilledButton(onPressed: () => Navigator.of(context).pop(crop()), child: const Text('Save'))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  const _MaskPainter({required this.square, required this.color});

  final bool square;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hole = Path();
    if (square) {
      hole.addRect(rect.deflate(2));
    } else {
      hole.addOval(rect.deflate(2));
    }
    final mask = Path.combine(PathOperation.difference, Path()..addRect(rect), hole);
    canvas.drawPath(mask, Paint()..color = color.withValues(alpha: 0.72));
    canvas.drawPath(hole, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(_MaskPainter old) => old.square != square || old.color != color;
}
