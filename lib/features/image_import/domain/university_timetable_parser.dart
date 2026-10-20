import '../../../core/time/local_time.dart';
import 'image_candidate.dart';
import 'ocr_document.dart';

class UniversityTableResult {
  const UniversityTableResult(this.candidates, this.consumedLines);
  final List<ImageCandidate> candidates;
  final Set<int> consumedLines;
}

/// Associates only a recognized, spatially ordered university table. Units and
/// section are deliberately excluded; neither becomes notes or a room. Missing
/// semester dates/zone remain unresolved, and every row still needs review.
class UniversityTimetableParser {
  static final _code = RegExp(r'^[A-Za-z]{2,8}\s*\d{2,4}[A-Za-z]?$', caseSensitive: false);
  static final _codeAndTitle = RegExp(r'^([A-Za-z]{2,8}\s*\d{2,4}[A-Za-z]?)\s+(.+)$');
  static final _day = RegExp(r'\b(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Mon|Tue|Tues|Wed|Thu|Thurs|Fri|Sat|Sun)\b', caseSensitive: false);
  static final _clock = RegExp(r'\b(\d{1,2}):([0-5]\d)\s*(AM|PM)\b', caseSensitive: false);
  static const _days = {'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7};

  UniversityTableResult? parse(OcrDocument doc) {
    final lines = doc.lines.where((line) => line.region != null &&
      line.region!.sourceRevision == doc.sourceRevision && line.region!.width == doc.width &&
      line.region!.height == doc.height && line.start >= 0 && line.start + line.text.length <= doc.text.length &&
      doc.text.substring(line.start, line.start + line.text.length) == line.text).toList();
    const names = ['code', 'description', 'units', 'section', 'instructor', 'schedules'];
    final headers = <OcrLine>[];
    for (final name in names) {
      final matches = lines.where((l) => l.text.trim().toLowerCase() == name).toList();
      if (matches.length != 1) return null;
      headers.add(matches.single);
    }
    final centers = headers.map((h) => (h.region!.left + h.region!.right) / 2).toList();
    final headerY = headers.map((h) => (h.region!.top + h.region!.bottom) / 2).toList()..sort();
    if (headerY.last - headerY.first > .035) return null;
    for (var i = 1; i < centers.length; i++) {
      if (centers[i] - centers[i - 1] < .025) return null;
    }
    final headerBottom = headers.map((h) => h.region!.bottom).reduce((a, b) => a > b ? a : b);
    final forcedColumns = <OcrLine, int>{};
    int column(OcrLine line) {
      if (forcedColumns.containsKey(line)) return forcedColumns[line]!;
      if (line.region!.left <= centers.first + .025) return 0;
      final x = (line.region!.left + line.region!.right) / 2;
      for (var i = 1; i < centers.length - 1; i++) {
        if (x < (centers[i] + centers[i + 1]) / 2) return i;
      }
      return centers.length - 1;
    }
    final body = <OcrLine>[];
    for (final line in lines.where((l) => l.region!.top > headerBottom)) {
      final merged = line.region!.left <= centers.first + .025 ? _codeAndTitle.firstMatch(line.text) : null;
      if (merged == null) { body.add(line); continue; }
      // ML Kit sometimes emits Code + Description as one line. Their text
      // remains exact source substrings, with the original bounding region.
      final code = OcrLine(text: merged.group(1)!, start: line.start,
        blockId: line.blockId, region: line.region);
      final titleText = merged.group(2)!;
      final title = OcrLine(text: titleText, start: line.start + line.text.indexOf(titleText, merged.group(1)!.length),
        blockId: line.blockId, region: line.region);
      forcedColumns[code] = 0; forcedColumns[title] = 1;
      body.addAll([code, title]);
    }
    final codes = body.where((l) => column(l) == 0).toList()..sort(_byPosition);
    final anchors = <List<OcrLine>>[];
    for (var i = 0; i < codes.length; i++) {
      if (_code.hasMatch(codes[i].text.trim())) {
        anchors.add([codes[i]]);
      } else if (RegExp(r'^[A-Za-z]{2,8}$').hasMatch(codes[i].text.trim()) && i + 1 < codes.length &&
          RegExp(r'^\d{2,4}[A-Za-z]?$').hasMatch(codes[i + 1].text.trim()) &&
          codes[i + 1].region!.top - codes[i].region!.bottom <
              (codes[i].region!.bottom - codes[i].region!.top) * 1.5) {
        anchors.add([codes[i], codes[++i]]);
      }
    }
    if (anchors.isEmpty) return null;
    // A dropped code must not cause a neighboring course to absorb its title,
    // instructor or meetings. Wrapped description lines form one cell; a
    // separate cell without a corresponding code makes this layout unresolved.
    final descriptions = body.where((l) => column(l) == 1).toList()..sort(_byPosition);
    if (descriptions.isNotEmpty) {
      final heights = descriptions.map((l) => l.region!.bottom - l.region!.top).toList()..sort();
      final gap = heights[heights.length ~/ 2] * 1.6;
      var groups = 1;
      for (var i = 1; i < descriptions.length; i++) {
        if (descriptions[i].region!.top - descriptions[i - 1].region!.bottom > gap) groups++;
      }
      if (groups != anchors.length) return null;
    }
    double middle(List<OcrLine> group) => (group.first.region!.top + group.last.region!.bottom) / 2;
    final consumed = <int>{};
    final candidates = <ImageCandidate>[];
    for (var row = 0; row < anchors.length; row++) {
      final top = row == 0 ? headerBottom : (middle(anchors[row - 1]) + middle(anchors[row])) / 2;
      final bottom = row + 1 == anchors.length ? 1.0 : (middle(anchors[row]) + middle(anchors[row + 1])) / 2;
      final cells = <int, List<OcrLine>>{};
      for (final line in body) {
        final y = (line.region!.top + line.region!.bottom) / 2;
        if (y >= top && y < bottom) (cells[column(line)] ??= []).add(line);
      }
      for (final cell in cells.values) { cell.sort(_byPosition); }
      final schedule = cells[5] ?? const <OcrLine>[];
      final joined = _JoinedLines(schedule);
      final days = _day.allMatches(joined.text).toList();
      if (days.isEmpty) continue;
      final title = _textField(doc, cells[1] ?? const []);
      final professor = _textField(doc, cells[4] ?? const []);
      final code = _textField(doc, anchors[row]);
      for (var meeting = 0; meeting < days.length; meeting++) {
        final from = days[meeting].start;
        final to = meeting + 1 < days.length ? days[meeting + 1].start : joined.text.length;
        final value = joined.text.substring(from, to);
        final clockMatches = _clock.allMatches(value).toList();
        final start = clockMatches.isEmpty ? null : _time(clockMatches.first);
        final end = clockMatches.length == 2 ? _time(clockMatches[1]) : null;
        final meetingLines = joined.between(from, to);
        final source = _span(doc, [...anchors[row], ...?cells[1], ...?cells[4], ...meetingLines]);
        if (source == null) continue;
        final room = value.lastIndexOf('/');
        // OCR can drop the slash on its own short wrapped room line. Accept
        // only the bounded remainder after two explicit clocks, never a
        // neighboring title/instructor/section column.
        final roomStart = room >= 0 ? room + 1 : clockMatches.length == 2 ? clockMatches.last.end : value.length;
        final rawRoom = value.substring(roomStart).replaceAll(RegExp(r'^[\s/|–—-]+'), '')
          .replaceFirst(RegExp(r'^I\s+(?=\S)'), '').trim();
        final roomLines = joined.between(from + roomStart, to);
        final roomValue = _roomText(doc, rawRoom, roomLines);
        CandidateField<T> field<T>(T? observed, List<OcrLine> evidence) => CandidateField(
          value: observed, origin: observed == null ? FieldOrigin.unresolved : FieldOrigin.observed,
          span: _span(doc, evidence), region: _region(doc, evidence));
        final warnings = <CandidateWarning>[
          CandidateWarning.missingTermStart, CandidateWarning.missingTermEnd,
          CandidateWarning.missingZone, CandidateWarning.association,
          if (title.value == null) CandidateWarning.missingTitle,
          if (start == null || end == null) CandidateWarning.missingAmPm,
          if (clockMatches.length != 2) CandidateWarning.unsupportedPattern,
        ];
        candidates.add(ImageCandidate(
          candidateId: '${doc.sourceRevision}:table:${anchors[row].first.start}:$meeting',
          sourceRevision: doc.sourceRevision, sourceLine: source, universityTimetable: true,
          title: title, professor: professor, subtitle: code,
          weekdays: field([_days[days[meeting].group(0)!.substring(0, 3).toLowerCase()]!], joined.between(from, from + days[meeting].group(0)!.length)),
          startTime: field(start, clockMatches.isEmpty ? meetingLines : joined.between(from + clockMatches.first.start, from + clockMatches.first.end)),
          endTime: field(end, clockMatches.length != 2 ? meetingLines : joined.between(from + clockMatches[1].start, from + clockMatches[1].end)),
          timeKind: field(CandidateTimeKind.timed, meetingLines),
          location: field(roomValue.isEmpty || clockMatches.length != 2 ? null : roomValue, roomLines),
          endDayOffset: start != null && end != null && end.isAfter(start) ? 0 : null,
          warnings: List.unmodifiable(warnings),
        ));
      }
      consumed.addAll(schedule.map((l) => l.start));
    }
    return candidates.isEmpty ? null : UniversityTableResult(candidates, consumed);
  }

  static int _byPosition(OcrLine a, OcrLine b) {
    final y = a.region!.top.compareTo(b.region!.top);
    return y == 0 ? a.region!.left.compareTo(b.region!.left) : y;
  }

  static CandidateField<String> _textField(OcrDocument doc, List<OcrLine> lines) {
    final value = lines.map((l) => l.text.trim()).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return CandidateField(value: value.isEmpty ? null : value,
      origin: value.isEmpty ? FieldOrigin.unresolved : FieldOrigin.observed,
      span: _span(doc, lines), region: _region(doc, lines));
  }

  static OcrSpan? _span(OcrDocument doc, List<OcrLine> lines) {
    if (lines.isEmpty) return null;
    final from = lines.map((l) => l.start).reduce((a, b) => a < b ? a : b);
    final to = lines.map((l) => l.start + l.text.length).reduce((a, b) => a > b ? a : b);
    return OcrSpan(start: from, end: to, text: doc.text.substring(from, to));
  }

  static ImageEvidenceRegion? _region(OcrDocument doc, List<OcrLine> lines) {
    if (lines.isEmpty) return null;
    return ImageEvidenceRegion.validated(
      left: lines.map((l) => l.region!.left).reduce((a, b) => a < b ? a : b),
      top: lines.map((l) => l.region!.top).reduce((a, b) => a < b ? a : b),
      right: lines.map((l) => l.region!.right).reduce((a, b) => a > b ? a : b),
      bottom: lines.map((l) => l.region!.bottom).reduce((a, b) => a > b ? a : b),
      sourceRevision: doc.sourceRevision, width: doc.width, height: doc.height);
  }

  static LocalTime? _time(Match m) {
    final hour = int.parse(m.group(1)!);
    if (hour < 1 || hour > 12) return null;
    return LocalTime(hour % 12 + (m.group(3)!.toUpperCase() == 'PM' ? 12 : 0), int.parse(m.group(2)!));
  }

  static String _roomText(OcrDocument doc, String value, List<OcrLine> evidence) {
    if (evidence.length != 1 || evidence.single.text.trim() != value) return value;
    final glyphs = evidence.single.glyphs.where((g) => g.region.sourceRevision == doc.sourceRevision &&
      g.region.width == doc.width && g.region.height == doc.height).toList()
      ..sort((a, b) => a.region.left.compareTo(b.region.left));
    if (glyphs.length < 2 || !RegExp(r'^[I1Tl|/]$').hasMatch(glyphs.first.text) ||
        !value.startsWith(glyphs[0].text + glyphs[1].text)) {
      return value;
    }
    final first = glyphs[0].region, second = glyphs[1].region;
    final height = (first.bottom - first.top) * doc.height;
    final width = (first.right - first.left) * doc.width;
    final gap = (second.left - first.right) * doc.width;
    // In this format a separated slash can be recognized as T, I or 1. Use
    // its narrow glyph and word-sized gap; never remove a normal tightly
    // spaced leading letter/digit (T104, 1104 and ITL remain valid rooms).
    return width <= height * .5 && gap >= height * .45 ? value.substring(glyphs.first.text.length).trimLeft() : value;
  }
}

class _JoinedLines {
  _JoinedLines(this.lines) {
    final buffer = StringBuffer();
    for (final line in lines) {
      if (buffer.isNotEmpty) buffer.write(' ');
      starts.add(buffer.length);
      buffer.write(line.text.trim());
    }
    text = buffer.toString();
  }
  final List<OcrLine> lines;
  final starts = <int>[];
  late final String text;
  List<OcrLine> between(int from, int to) => [for (var i = 0; i < lines.length; i++)
    if (starts[i] < to && starts[i] + lines[i].text.trim().length > from) lines[i]];
}
