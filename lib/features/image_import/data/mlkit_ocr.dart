import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' as ml;

import '../domain/image_preparation.dart';
import '../domain/image_services.dart';
import '../domain/ocr_document.dart';

/// Latin-script ML Kit on device only; no cloud fallback exists.
class MlKitOnDeviceOcr implements OnDeviceOcr {
  MlKitOnDeviceOcr({bool Function()? isSupported}) : _isSupported = isSupported ?? (() => Platform.isAndroid || Platform.isIOS);
  final bool Function() _isSupported;

  @override
  Future<OcrDocument> recognize(PreparedImageFile image) async {
    if (!_isSupported()) throw const ImageImportFailure(ImageFailureCode.ocrUnavailable);
    if (image.width < 1 || image.height < 1 || image.width > 4096 || image.height > 4096 || image.width * image.height > 12000000) {
      throw const ImageImportFailure(ImageFailureCode.tooLarge);
    }
    final recognizer = ml.TextRecognizer(script: ml.TextRecognitionScript.latin);
    try {
      try {
        final result = await recognizer.processImage(ml.InputImage.fromFilePath(image.path));
        if (result.text.length > 100000) throw const ImageImportFailure(ImageFailureCode.tooManyCandidates);
        if (result.text.trim().isEmpty) throw const ImageImportFailure(ImageFailureCode.noText);
        final lines = <OcrLine>[];
        final buffer = StringBuffer();
        var glyphCount = 0;
        for (var b = 0; b < result.blocks.length; b++) {
          for (final line in result.blocks[b].lines) {
            if (lines.length >= 2000 || buffer.length + line.text.length > 100000) throw const ImageImportFailure(ImageFailureCode.tooManyCandidates);
            final box = line.boundingBox;
            final region = ImageEvidenceRegion.validated(left: box.left / image.width, top: box.top / image.height,
              right: box.right / image.width, bottom: box.bottom / image.height,
              sourceRevision: image.sourceRevision, width: image.width, height: image.height);
            final glyphs = <OcrGlyph>[];
            for (final element in line.elements) {
              for (final symbol in element.symbols) {
                if (++glyphCount > 100000) throw const ImageImportFailure(ImageFailureCode.tooManyCandidates);
                final box = symbol.boundingBox;
                final symbolRegion = ImageEvidenceRegion.validated(left: box.left / image.width, top: box.top / image.height,
                  right: box.right / image.width, bottom: box.bottom / image.height,
                  sourceRevision: image.sourceRevision, width: image.width, height: image.height);
                if (symbolRegion != null && symbol.text.isNotEmpty) glyphs.add(OcrGlyph(symbol.text, symbolRegion));
              }
            }
            lines.add(OcrLine(text: line.text, start: buffer.length, blockId: b, region: region, glyphs: List.unmodifiable(glyphs)));
            buffer.writeln(line.text);
          }
        }
        if (lines.isEmpty) return OcrDocument.plain(result.text, sourceRevision: image.sourceRevision, width: image.width, height: image.height);
        return OcrDocument(text: buffer.toString(), lines: List.unmodifiable(lines),
          sourceRevision: image.sourceRevision, width: image.width, height: image.height);
      } finally {
        await recognizer.close();
      }
    } on ImageImportFailure {
      rethrow;
    } on MissingPluginException {
      throw const ImageImportFailure(ImageFailureCode.ocrUnavailable);
    } on PlatformException {
      throw const ImageImportFailure(ImageFailureCode.ocrFailed);
    } catch (_) {
      throw const ImageImportFailure(ImageFailureCode.ocrFailed);
    }
  }
}
