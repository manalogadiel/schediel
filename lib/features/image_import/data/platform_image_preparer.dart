
import 'package:flutter/services.dart';

import '../domain/image_preparation.dart';
import 'local_image_preparer.dart';

/// Android checks header dimensions and requests bounded decode before pixels
/// are allocated. HEIC/AVIF availability depends on installed device codecs.
Future<PreparedImage> normalizePlatformImage(Uint8List bytes, PixelCrop? crop, int quarterTurns) async {
  if (!ImageAdmission.needsPlatformDecoder(bytes)) throw const ImageImportFailure(ImageFailureCode.unsupported);
  try {
    final result = await const MethodChannel('schediel/image_decode').invokeMethod<Object?>('normalize', {'bytes': bytes});
    if (result is! Uint8List || result.length > ImageImportLimits.normalizedBytes) throw const ImageImportFailure(ImageFailureCode.unreadable);
    // Reuse the exact metadata removal, white background, crop and rotation path.
    return await normalizeImage(result, crop: crop, quarterTurns: quarterTurns);
  } on ImageImportFailure {
    rethrow;
  } on PlatformException catch (e) {
    throw ImageImportFailure(switch (e.code) {
      'tooLarge' => ImageFailureCode.tooLarge,
      'unreadable' => ImageFailureCode.unreadable,
      _ => ImageFailureCode.unsupported,
    });
  } on MissingPluginException {
    throw const ImageImportFailure(ImageFailureCode.unsupported);
  }
}
