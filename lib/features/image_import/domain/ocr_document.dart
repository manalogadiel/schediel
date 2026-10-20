/// Plain OCR content only. Never a command, URL action or tool request.
class OcrDocument {
  OcrDocument({required this.text, required this.lines, required this.sourceRevision, required this.width, required this.height});
  final String text;
  final List<OcrLine> lines;
  final int sourceRevision, width, height;

  factory OcrDocument.plain(String text, {int sourceRevision = 1, int width = 100, int height = 100}) {
    var offset = 0;
    final lines = <OcrLine>[];
    for (final value in text.split('\n')) {
      lines.add(OcrLine(text: value, start: offset, blockId: 0));
      offset += value.length + 1;
    }
    return OcrDocument(text: text, lines: lines, sourceRevision: sourceRevision, width: width, height: height);
  }
}

class OcrLine {
  const OcrLine({required this.text, required this.start, required this.blockId, this.region, this.glyphs = const []});
  final String text;
  final int start, blockId;
  final ImageEvidenceRegion? region;
  final List<OcrGlyph> glyphs;
}

/// Android character geometry helps distinguish a narrow, separated table
/// delimiter from the first character of a room. iOS may omit this evidence.
class OcrGlyph {
  const OcrGlyph(this.text, this.region);
  final String text;
  final ImageEvidenceRegion region;
}

class OcrSpan {
  const OcrSpan({required this.start, required this.end, required this.text});
  final int start, end;
  final String text;
}

class ImageEvidenceRegion {
  const ImageEvidenceRegion._(this.left, this.top, this.right, this.bottom, this.sourceRevision, this.width, this.height);
  final double left, top, right, bottom;
  final int sourceRevision, width, height;

  static ImageEvidenceRegion? validated({required double left, required double top, required double right, required double bottom, required int sourceRevision, required int width, required int height}) {
    if (width < 1 || height < 1 || sourceRevision < 1 ||
      ![left, top, right, bottom].every((v) => v.isFinite) ||
      left < 0 || top < 0 || right > 1 || bottom > 1 || right <= left || bottom <= top) {
      return null;
    }
    return ImageEvidenceRegion._(left, top, right, bottom, sourceRevision, width, height);
  }
}
