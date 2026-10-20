import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:schediel/features/image_import/data/local_image_preparer.dart';
import 'package:schediel/features/image_import/data/platform_image_preparer.dart';
import 'package:schediel/features/image_import/domain/image_preparation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final formats = <String, Uint8List Function(img.Image)>{
    'WebP': (i) => img.encodeWebP(i), 'BMP': (i) => img.encodeBmp(i),
    'GIF': (i) => img.encodeGif(i), 'TIFF': (i) => img.encodeTiff(i),
  };
  for (final format in formats.entries) {
    test('${format.key} normalizes real pixels and strips metadata', () async {
      final input = img.Image(width: 4, height: 3, numChannels: 4);
      img.fill(input, color: img.ColorRgba8(20, 70, 120, 255));
      input.textData = {'private': 'remove this'};
      final output = await normalizeImage(format.value(input), crop: const PixelCrop(1, 0, 4, 2), quarterTurns: 1);
      expect((output.width, output.height), (2, 3));
      final decoded = img.decodePng(output.bytes)!;
      expect(decoded.getPixel(0, 0).r, closeTo(20, 3));
      expect(decoded.getPixel(0, 0).g, closeTo(70, 3));
      expect(decoded.textData ?? {}, isEmpty);
      expect(decoded.exif.isEmpty, isTrue);
    });
  }

  test('AVIF native-channel contract reuses pixel-only normalization', () async {
    const channel = MethodChannel('schediel/image_decode');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final bytes = await File('test/fixtures/image_import/solid.avif').readAsBytes();
    expect(ImageAdmission.needsPlatformDecoder(bytes), isTrue);
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'normalize');
      expect((call.arguments as Map)['bytes'], bytes);
      final image = img.Image(width: 8, height: 6);
      img.fill(image, color: img.ColorRgb8(20, 70, 120));
      image.textData = {'private': 'remove me'};
      return img.encodePng(image);
    });
    final result = await normalizePlatformImage(bytes, const PixelCrop(0, 0, 4, 6), 1);
    expect((result.width, result.height), (6, 4));
    final pixel = img.decodePng(result.bytes)!.getPixel(0, 0);
    expect(pixel.r, closeTo(20, 3));
    expect(pixel.g, closeTo(70, 3));
  });

  test('transparent screenshots are composited onto white for OCR', () async {
    final image = img.Image(width: 3, height: 1, numChannels: 4);
    image.setPixelRgba(0, 0, 0, 0, 0, 0);
    image.setPixelRgba(1, 0, 0, 0, 0, 255);
    image.setPixelRgba(2, 0, 0, 0, 0, 128);
    final result = img.decodePng((await normalizeImage(img.encodePng(image))).bytes)!;
    expect(result.getPixel(0, 0).r, 255);
    expect(result.getPixel(1, 0).r, 0);
    expect(result.getPixel(2, 0).r, closeTo(127, 1));
  });

  test('animated GIF and multi-page TIFF are never silently truncated', () async {
    final image = img.Image(width: 2, height: 2);
    image.addFrame(img.Image(width: 2, height: 2));
    for (final bytes in [img.encodeGif(image), await File('test/fixtures/image_import/two-pages.tiff').readAsBytes()]) {
      await expectLater(normalizeImage(bytes), throwsA(isA<ImageImportFailure>()
        .having((e) => e.code, 'code', ImageFailureCode.unsupported)));
    }
  });
  test('JPEG EXIF orientation is applied before crop', () async {
    final source = img.Image(width: 4, height: 2);
    source.exif.imageIfd.orientation = 6;
    final result = await normalizeImage(img.encodeJpg(source), crop: const PixelCrop(0, 0, 2, 4));
    expect((result.width, result.height), (2, 4));
    expect(img.decodePng(result.bytes)!.exif.isEmpty, isTrue);
  });

  test('normalization enforces dimension and pixel limits', () async {
    final source = img.Image(width: 4100, height: 3000);
    final result = await normalizeImage(img.encodePng(source));
    expect(result.width, lessThanOrEqualTo(4096));
    expect(result.height, lessThanOrEqualTo(4096));
    expect(result.width * result.height, lessThanOrEqualTo(12000000));
    expect(result.bytes.length, lessThanOrEqualTo(5 * 1024 * 1024));
  });

  test('invalid crop and corrupt PNG are explicit recoverable failures', () async {
    final bytes = img.encodePng(img.Image(width: 3, height: 2));
    await expectLater(normalizeImage(bytes, crop: const PixelCrop(-1, 0, 2, 2)),
      throwsA(isA<ImageImportFailure>().having((e) => e.code, 'code', ImageFailureCode.invalidCrop)));
    bytes[29] ^= 1;
    await expectLater(normalizeImage(bytes),
      throwsA(isA<ImageImportFailure>().having((e) => e.code, 'code', ImageFailureCode.unreadable)));
  });

  test('isolate normalization crops exact pixels, rotates and strips metadata', () async {
    final source = img.Image(width: 4, height: 3);
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 4; x++) { source.setPixelRgba(x, y, x * 40, y * 60, 10, 255); }
    }
    source.textData = {'private': 'do not retain'};
    final result = await normalizeImage(img.encodePng(source), crop: const PixelCrop(1, 0, 4, 2), quarterTurns: 1);
    expect(result.width, 2);
    expect(result.height, 3);
    final decoded = img.decodePng(result.bytes)!;
    expect(decoded.getPixel(0, 0).r, 40);
    expect(decoded.getPixel(0, 0).g, 60);
    expect(decoded.getPixel(1, 2).r, 120);
    expect(decoded.getPixel(1, 2).g, 0);
    expect(decoded.textData ?? {}, isEmpty);
    expect(decoded.exif.isEmpty, isTrue);
  });
}
