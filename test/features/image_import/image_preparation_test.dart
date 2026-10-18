import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:schediel/features/image_import/domain/image_preparation.dart';

void main() {
  test('admission accepts actual PNG and JPEG signatures', () {
    final source = img.Image(width: 3, height: 2);
    ImageAdmission.inspect(img.encodePng(source));
    ImageAdmission.inspect(img.encodeJpg(source));
  });

  test('header admission rejects 40Mpx bomb before pixel decoding', () {
    final bytes = img.encodePng(img.Image(width: 1, height: 1));
    ByteData.sublistView(bytes).setUint32(16, 40000001);
    expect(() => ImageAdmission.inspect(bytes),
      throwsA(isA<ImageImportFailure>().having((e) => e.code, 'code', ImageFailureCode.tooLarge)));
  });

  test('byte admission rejects more than 10 MiB', () {
    expect(() => ImageAdmission.inspect(Uint8List(10 * 1024 * 1024 + 1)),
      throwsA(isA<ImageImportFailure>().having((e) => e.code, 'code', ImageFailureCode.tooLarge)));
  });

  test('truncated supported signatures are unreadable, not accepted', () {
    expect(() => ImageAdmission.inspect(Uint8List.fromList([255, 216, 255])),
      throwsA(isA<ImageImportFailure>().having((e) => e.code, 'code', ImageFailureCode.unreadable)));
  });
  test('admission rejects GIF bytes even when caller calls them PNG', () {
    expect(
      () => ImageAdmission.inspect(Uint8List.fromList('GIF89a'.codeUnits)),
      throwsA(isA<ImageImportFailure>().having((e) => e.code, 'code', ImageFailureCode.unsupported)),
    );
  });
}
