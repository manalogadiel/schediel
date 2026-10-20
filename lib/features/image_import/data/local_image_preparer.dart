import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../domain/image_preparation.dart';

class PixelCrop {
  const PixelCrop(this.left, this.top, this.right, this.bottom);
  final int left, top, right, bottom;
  int get width => right - left;
  int get height => bottom - top;
}

class PreparedImage {
  const PreparedImage({required this.bytes, required this.width, required this.height});
  final Uint8List bytes;
  final int width, height;
}

/// Orientation, crop (in oriented pixels), then clockwise quarter turns.
Future<PreparedImage> normalizeImage(Uint8List bytes, {PixelCrop? crop, int quarterTurns = 0}) =>
    Isolate.run(() => _normalize(bytes, crop, quarterTurns));

PreparedImage _normalize(Uint8List bytes, PixelCrop? crop, int quarterTurns) {
  try {
    final header = ImageAdmission.inspect(bytes);
    final img.Decoder decoder = switch (header.format) {
      AdmittedImageFormat.png => img.PngDecoder(maxPixels: ImageImportLimits.sourcePixels),
      AdmittedImageFormat.jpeg => img.JpegDecoder(maxPixels: ImageImportLimits.sourcePixels),
      AdmittedImageFormat.webp => img.WebPDecoder()..maxPixels = ImageImportLimits.sourcePixels,
      AdmittedImageFormat.gif => img.GifDecoder()..maxPixels = ImageImportLimits.sourcePixels,
      AdmittedImageFormat.bmp => img.BmpDecoder(maxPixels: ImageImportLimits.sourcePixels),
      AdmittedImageFormat.tiff => img.TiffDecoder(maxPixels: ImageImportLimits.sourcePixels),
    };
    final decoded = decoder.decode(bytes, frame: 0);
    if (decoded == null ||
        !((decoded.width == header.width && decoded.height == header.height) ||
          (header.format == AdmittedImageFormat.jpeg && decoded.width == header.height && decoded.height == header.width))) {
      throw const ImageImportFailure(ImageFailureCode.unreadable);
    }
    return _finish(img.bakeOrientation(decoded), crop, quarterTurns);
  } on ImageImportFailure {
    rethrow;
  } catch (_) {
    throw const ImageImportFailure(ImageFailureCode.unreadable);
  }
}

PreparedImage _finish(img.Image image, PixelCrop? crop, int quarterTurns) {
  try {
    if (crop != null) {
      if (crop.left < 0 || crop.top < 0 || crop.right > image.width || crop.bottom > image.height || crop.width < 1 || crop.height < 1) {
        throw const ImageImportFailure(ImageFailureCode.invalidCrop);
      }
      image = img.copyCrop(image, x: crop.left, y: crop.top, width: crop.width, height: crop.height);
    }
    final turns = quarterTurns % 4;
    if (turns != 0) image = img.copyRotate(image, angle: turns * 90);
    final scale = math.min(1.0, math.min(
      ImageImportLimits.normalizedDimension / math.max(image.width, image.height),
      math.sqrt(ImageImportLimits.normalizedPixels / (image.width * image.height)),
    ));
    if (scale < 1) {
      image = img.copyResize(image,
        width: math.max(1, (image.width * scale).floor()),
        height: math.max(1, (image.height * scale).floor()),
        interpolation: img.Interpolation.average);
    }
    // A fresh pixel-only container drops EXIF/GPS/ICC/text metadata, including
    // metadata that resize/crop helpers might otherwise copy to the output.
    final pixels = img.Image.fromBytes(width: image.width, height: image.height,
      bytes: image.getBytes(order: img.ChannelOrder.rgba).buffer, numChannels: 4);
    image = img.Image(width: pixels.width, height: pixels.height, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(image, pixels);
    while (true) {
      final output = img.encodePng(image);
      if (output.length <= ImageImportLimits.normalizedBytes) {
        return PreparedImage(bytes: output, width: image.width, height: image.height);
      }
      // Lossless PNG first; size is bounded by further downscaling rather than
      // leaking original metadata or returning an oversize encoded image.
      image = img.copyResize(image,
        width: math.max(1, (image.width * 0.8).floor()),
        height: math.max(1, (image.height * 0.8).floor()),
        interpolation: img.Interpolation.average);
    }
  } on ImageImportFailure {
    rethrow;
  } catch (_) {
    throw const ImageImportFailure(ImageFailureCode.unreadable);
  }
}
