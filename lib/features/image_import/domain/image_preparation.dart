import 'dart:typed_data';

abstract final class ImageImportLimits {
  static const sourceBytes = 10 * 1024 * 1024;
  static const sourcePixels = 40000000;
  static const normalizedBytes = 5 * 1024 * 1024;
  static const normalizedPixels = 12000000;
  static const normalizedDimension = 4096;
}

enum ImageFailureCode {
  unsupported, unreadable, tooLarge, invalidCrop, noText, noCandidates,
  tooManyCandidates, ocrUnavailable, ocrFailed, permissionDenied,
}

class ImageImportFailure implements Exception {
  const ImageImportFailure(this.code);
  final ImageFailureCode code;

  String get message => switch (code) {
    ImageFailureCode.unsupported => 'Choose a static JPEG or PNG image. Other formats and animated images are not supported.',
    ImageFailureCode.unreadable => 'Unable to read this image. Choose another JPEG or PNG.',
    ImageFailureCode.tooLarge => 'Image exceeds the safe size limit (10 MiB or 40 million pixels). Export a smaller image or crop it first.',
    ImageFailureCode.invalidCrop => 'Choose a nonempty region inside the image.',
    ImageFailureCode.noText => 'No readable text found. Try a clearer image or a smaller crop.',
    ImageFailureCode.noCandidates => 'No schedule dates or weekdays found. Try a smaller crop or enter schedules manually.',
    ImageFailureCode.tooManyCandidates => 'This image is too dense to review safely. Scan smaller crops; no rows were silently omitted.',
    ImageFailureCode.ocrUnavailable => 'On-device text recognition is available on Android and iOS only.',
    ImageFailureCode.ocrFailed => 'Unable to scan this image on device. Your edits are kept. Try again or crop a clearer region.',
    ImageFailureCode.permissionDenied => 'Image access was not allowed. Choose a photo or allow camera access in system settings.',
  };

  @override
  String toString() => 'ImageImportFailure(${code.name})';
}

enum AdmittedImageFormat { jpeg, png }

class ImageHeader {
  const ImageHeader(this.format, this.width, this.height);
  final AdmittedImageFormat format;
  final int width;
  final int height;
}

/// Header admission occurs before decoding. Filename/MIME are not authority.
abstract final class ImageAdmission {
  static ImageHeader inspect(Uint8List bytes) {
    if (bytes.length > ImageImportLimits.sourceBytes) throw const ImageImportFailure(ImageFailureCode.tooLarge);
    if (bytes.length >= 8 && _same(bytes, 0, const [137, 80, 78, 71, 13, 10, 26, 10])) return _png(bytes);
    if (bytes.length >= 2 && bytes[0] == 255 && bytes[1] == 216) return _jpeg(bytes);
    throw const ImageImportFailure(ImageFailureCode.unsupported);
  }

  static ImageHeader _png(Uint8List bytes) {
    if (bytes.length < 33 || !_same(bytes, 12, 'IHDR'.codeUnits) || _u32(bytes, 8) != 13) {
      throw const ImageImportFailure(ImageFailureCode.unreadable);
    }
    final width = _u32(bytes, 16), height = _u32(bytes, 20);
    _dimensions(width, height);
    var offset = 8;
    var end = false;
    while (offset + 12 <= bytes.length) {
      final length = _u32(bytes, offset);
      if (offset + length + 12 > bytes.length) throw const ImageImportFailure(ImageFailureCode.unreadable);
      final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
      if (type == 'acTL' || type == 'fcTL' || type == 'fdAT') throw const ImageImportFailure(ImageFailureCode.unsupported);
      if (type == 'IEND') { end = true; break; }
      offset += length + 12;
    }
    if (!end) throw const ImageImportFailure(ImageFailureCode.unreadable);
    return ImageHeader(AdmittedImageFormat.png, width, height);
  }

  static ImageHeader _jpeg(Uint8List bytes) {
    var offset = 2;
    while (offset < bytes.length) {
      if (bytes[offset++] != 255) break;
      while (offset < bytes.length && bytes[offset] == 255) { offset++; }
      if (offset >= bytes.length) break;
      final marker = bytes[offset++];
      if (marker == 0xda || marker == 0xd9) break;
      if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
      if (offset + 2 > bytes.length) break;
      final length = (bytes[offset] << 8) | bytes[offset + 1];
      if (length < 2 || offset + length > bytes.length) break;
      if (const [0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf].contains(marker)) {
        if (length < 8) break;
        final height = (bytes[offset + 3] << 8) | bytes[offset + 4];
        final width = (bytes[offset + 5] << 8) | bytes[offset + 6];
        _dimensions(width, height);
        if (!const [0xc0, 0xc1, 0xc2].contains(marker) || bytes[offset + 2] != 8) {
          throw const ImageImportFailure(ImageFailureCode.unsupported);
        }
        return ImageHeader(AdmittedImageFormat.jpeg, width, height);
      }
      offset += length;
    }
    throw const ImageImportFailure(ImageFailureCode.unreadable);
  }

  static void _dimensions(int width, int height) {
    if (width < 1 || height < 1) throw const ImageImportFailure(ImageFailureCode.unreadable);
    if (width * height > ImageImportLimits.sourcePixels) throw const ImageImportFailure(ImageFailureCode.tooLarge);
  }

  static int _u32(Uint8List b, int at) => ByteData.sublistView(b).getUint32(at);
  static bool _same(Uint8List b, int at, List<int> signature) {
    if (b.length < at + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (b[at + i] != signature[i]) return false;
    }
    return true;
  }
}
