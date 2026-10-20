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
  static const _channel = MethodChannel('google_mlkit_text_recognizer');
  static var _nextId = 0;

  @override
  Future<OcrDocument> recognize(PreparedImageFile image) async {
    if (!_isSupported()) throw const ImageImportFailure(ImageFailureCode.ocrUnavailable);
    if (image.width < 1 || image.height < 1 || image.width > 4096 || image.height > 4096 || image.width * image.height > 12000000) {
      throw const ImageImportFailure(ImageFailureCode.tooLarge);
    }
    final id = 'schediel-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';
    try {
      // The plugin's native contract explicitly permits null bounding boxes.
      // Its Dart factory requires every block/element/symbol box to be a Map,
      // so use the same channel and preserve text even without that geometry.
      final result = await _channel.invokeMethod<Object?>('vision#startTextRecognizer', {
        'id': id, 'script': ml.TextRecognitionScript.latin.index,
        'imageData': ml.InputImage.fromFilePath(image.path).toJson(),
      });
      if (result is! Map || result['text'] is! String || result['blocks'] is! List) {
        throw const ImageImportFailure(ImageFailureCode.ocrFailed);
      }
      final text = result['text'] as String;
      if (text.length > 100000) throw const ImageImportFailure(ImageFailureCode.tooManyCandidates);
      if (text.trim().isEmpty) throw const ImageImportFailure(ImageFailureCode.noText);
      final lines = <OcrLine>[];
      final buffer = StringBuffer();
      var glyphCount = 0;
      final blocks = result['blocks'] as List;
      for (var b = 0; b < blocks.length; b++) {
        final block = blocks[b];
        if (block is! Map || block['lines'] is! List) continue;
        for (final line in block['lines'] as List) {
          if (line is! Map || line['text'] is! String) continue;
          final value = line['text'] as String;
          if (lines.length >= 2000 || buffer.length + value.length > 100000) throw const ImageImportFailure(ImageFailureCode.tooManyCandidates);
          final glyphs = <OcrGlyph>[];
          final elements = line['elements'];
          if (elements is List) {
            for (final element in elements) {
              if (element is! Map || element['symbols'] is! List) continue;
              for (final symbol in element['symbols'] as List) {
                if (++glyphCount > 100000) throw const ImageImportFailure(ImageFailureCode.tooManyCandidates);
                if (symbol is! Map || symbol['text'] is! String) continue;
                final region = _region(symbol['rect'], image);
                if (region != null && (symbol['text'] as String).isNotEmpty) glyphs.add(OcrGlyph(symbol['text'] as String, region));
              }
            }
          }
          lines.add(OcrLine(text: value, start: buffer.length, blockId: b,
            region: _region(line['rect'], image), glyphs: List.unmodifiable(glyphs)));
          buffer.writeln(value);
        }
      }
      if (lines.isEmpty) return OcrDocument.plain(text, sourceRevision: image.sourceRevision, width: image.width, height: image.height);
      return OcrDocument(text: buffer.toString(), lines: List.unmodifiable(lines),
        sourceRevision: image.sourceRevision, width: image.width, height: image.height);
    } on ImageImportFailure {
      rethrow;
    } on MissingPluginException {
      throw const ImageImportFailure(ImageFailureCode.ocrUnavailable);
    } catch (_) {
      throw const ImageImportFailure(ImageFailureCode.ocrFailed);
    } finally {
      try {
        await _channel.invokeMethod<void>('vision#closeTextRecognizer', {'id': id});
      } on PlatformException {
        // Cleanup failure must not replace recognized text or the original error.
      } on MissingPluginException {
        // The unavailable-recognizer error above remains the useful failure.
      }
    }
  }

  static ImageEvidenceRegion? _region(Object? raw, PreparedImageFile image) {
    if (raw is! Map) return null;
    final values = [raw['left'], raw['top'], raw['right'], raw['bottom']];
    if (!values.every((v) => v is num && v.isFinite)) return null;
    return ImageEvidenceRegion.validated(left: (values[0] as num).toDouble() / image.width,
      top: (values[1] as num).toDouble() / image.height, right: (values[2] as num).toDouble() / image.width,
      bottom: (values[3] as num).toDouble() / image.height, sourceRevision: image.sourceRevision, width: image.width, height: image.height);
  }
}
