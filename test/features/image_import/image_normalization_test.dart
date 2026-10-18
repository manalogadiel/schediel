import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:schediel/features/image_import/data/local_image_preparer.dart';
import 'package:schediel/features/image_import/domain/image_preparation.dart';

void main() {
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
