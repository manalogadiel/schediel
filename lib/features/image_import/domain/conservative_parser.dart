import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import '../../../core/time/zone_resolver.dart';
import 'image_candidate.dart';
import 'image_preparation.dart';
import 'ocr_document.dart';

/// A deliberately small line-oriented parser, not a timetable interpreter.
/// OCR remains untrusted plain data; this class has no network or tool API.
class ConservativeCandidateParser {
  static const _months = 'January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec';
  static final _date = RegExp(r'\b\d{4}-\d{2}-\d{2}\b|\b(?:' + _months + r')\.?\s+\d{1,2}(?:st|nd|rd|th)?(?:,?\s+\d{4})?\b|\b\d{1,2}\s+(?:' + _months + r')\.?(?:\s+\d{4})?\b|\b\d{1,2}[/.]\d{1,2}(?:[/.]\d{2,4})?\b', caseSensitive: false);
  static final _monthFirst = RegExp(r'^([A-Za-z]+)\.?\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s+(\d{4}))?$', caseSensitive: false);
  static final _dayFirst = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\.?(?:\s+(\d{4}))?$', caseSensitive: false);
  static final _weekday = RegExp(r'\b(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Mon|Tue|Tues|Wed|Thu|Thurs|Fri|Sat|Sun)\b', caseSensitive: false);
  static const _monthNumbers = {'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12};
  static const _weekdayNumbers = {'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7};
  static final _clock = RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(AM|PM)\b|\b(\d{1,2}):(\d{2})\b', caseSensitive: false);
  static final _zone = RegExp(r'\b(?:[A-Za-z_]+/[A-Za-z_]+(?:/[A-Za-z_]+)?|UTC)\b');

  CandidateParseResult parse(OcrDocument document) {
    if (document.text.length > 100000 || document.lines.length > 2000) {
      throw const ImageImportFailure(ImageFailureCode.tooManyCandidates);
    }
    final rows = <ImageCandidate>[];
    for (final line in document.lines) {
      if (line.start < 0 || line.start + line.text.length > document.text.length ||
          document.text.substring(line.start, line.start + line.text.length) != line.text) {
        continue;
      }
      final dates = _date.allMatches(line.text).toList();
      final dayMatches = _weekday.allMatches(line.text).toList();
      if (dates.isEmpty && dayMatches.isEmpty) continue;
      if (rows.length == 100) throw const ImageImportFailure(ImageFailureCode.tooManyCandidates);
      final warnings = <CandidateWarning>[];
      final dateMatch = dates.firstOrNull;
      final date = dates.length == 1 ? _parseDate(dateMatch!.group(0)!, warnings) : null;
      if (dates.length > 1) warnings.add(CandidateWarning.unsupportedPattern);
      final weekly = dayMatches.isNotEmpty && (date == null || RegExp(r'\b(every|weekly)\b', caseSensitive: false).hasMatch(line.text));
      final days = weekly ? (dayMatches.map((m) => _weekdayNumbers[m.group(0)!.substring(0, 3).toLowerCase()]!).toSet().toList()..sort()) : <int>[];
      final anchor = [...dates, if (weekly) ...dayMatches]..sort((a, b) => a.start.compareTo(b.start));
      var title = line.text.substring(0, anchor.first.start).replaceAll(RegExp(r'[\s|;:–—-]+$'), '').trim();
      title = title.replaceFirst(RegExp(r'^Title:\s*', caseSensitive: false), '');
      if (title.toLowerCase() == 'every' || title.toLowerCase() == 'weekly') title = '';
      final clocks = _clock.allMatches(line.text).toList();
      final explicit24 = RegExp(r'\b24\s*(?:h|hour)\b', caseSensitive: false).hasMatch(line.text);
      final start = clocks.isEmpty ? null : _time(clocks.first, explicit24: explicit24);
      final end = clocks.length < 2 ? null : _time(clocks[1], explicit24: explicit24);
      final zoneMatches = _zone.allMatches(line.text).toList();
      final zoneMatch = zoneMatches.length == 1 ? zoneMatches.single : null;
      final zone = zoneMatch?.group(0);
      final validZone = zone != null && ZoneResolver.initialized().isValidZone(zone);
      if (title.isEmpty) warnings.add(CandidateWarning.missingTitle);
      if (title.runes.length > 120) warnings.add(CandidateWarning.fieldTooLong);
      if (weekly) {
        warnings.addAll([CandidateWarning.missingTermStart, CandidateWarning.missingTermEnd]);
      } else if (date == null && dates.isEmpty) {
        warnings.add(CandidateWarning.missingDate);
      }
      if (clocks.isNotEmpty && (start == null || (clocks.length > 1 && end == null))) warnings.add(CandidateWarning.missingAmPm);
      if (weekly && clocks.isEmpty) warnings.add(CandidateWarning.missingTime);
      if ((weekly || clocks.isNotEmpty) && !validZone) warnings.add(CandidateWarning.missingZone);
      if (clocks.length > 2) warnings.add(CandidateWarning.unsupportedPattern);
      if (clocks.length == 1) warnings.add(CandidateWarning.endChoice);
      warnings.add(CandidateWarning.association);
      final span = OcrSpan(start: line.start, end: line.start + line.text.length, text: line.text);
      final region = line.region != null && line.region!.sourceRevision == document.sourceRevision &&
          line.region!.width == document.width && line.region!.height == document.height ? line.region : null;
      CandidateField<T> observed<T>(T? value, Match? m) => CandidateField(
        value: value, origin: value == null ? FieldOrigin.unresolved : FieldOrigin.observed,
        span: m == null ? null : OcrSpan(start: line.start + m.start, end: line.start + m.end, text: m.group(0)!), region: region);
      final titleStart = title.isEmpty ? 0 : line.text.indexOf(title);
      CandidateField<String> detail(String label) {
        final m = RegExp('(?:^|[|;])\\s*(?:$label):\\s*([^|;]+)', caseSensitive: false).firstMatch(line.text);
        if (m == null) return const CandidateField();
        final value = m.group(1)!.trim();
        final at = line.text.indexOf(value, m.start);
        return CandidateField(value: value, origin: FieldOrigin.observed, span: OcrSpan(start: line.start + at, end: line.start + at + value.length, text: value), region: region);
      }
      rows.add(ImageCandidate(
        candidateId: '${document.sourceRevision}:${line.start}', sourceRevision: document.sourceRevision, sourceLine: span,
        title: CandidateField(value: title.isEmpty ? null : title, origin: title.isEmpty ? FieldOrigin.unresolved : FieldOrigin.observed,
          span: title.isEmpty ? null : OcrSpan(start: line.start + titleStart, end: line.start + titleStart + title.length, text: title), region: region),
        date: observed(weekly ? null : date, dateMatch), startTime: observed(clocks.length > 2 ? null : start, clocks.firstOrNull),
        endTime: observed(clocks.length > 2 ? null : end, clocks.length < 2 ? null : clocks[1]),
        timeZone: observed(validZone ? zone : null, zoneMatch),
        weekdays: observed(days.isEmpty ? null : List<int>.unmodifiable(days), dayMatches.firstOrNull),
        timeKind: CandidateField(value: clocks.isEmpty ? (weekly ? null : CandidateTimeKind.dateOnly) : CandidateTimeKind.timed,
          origin: clocks.isEmpty && weekly ? FieldOrigin.unresolved : FieldOrigin.observed, span: span, region: region),
        location: detail('Room|Location'), professor: detail('Professor|Prof|Instructor'),
        warnings: List.unmodifiable(warnings.toSet()),
      ));
    }
    return CandidateParseResult(List.unmodifiable(rows));
  }

  LocalDate? _parseDate(String text, List<CandidateWarning> warnings) {
    if (RegExp(r'^\d{4}-').hasMatch(text)) {
      final date = LocalDate.tryParse(text);
      if (date == null) warnings.add(CandidateWarning.invalidDate);
      return date;
    }
    final monthFirst = _monthFirst.firstMatch(text);
    final dayFirst = _dayFirst.firstMatch(text);
    if (monthFirst == null && dayFirst == null) {
      warnings.add(CandidateWarning.dateOrder);
      if (!RegExp(r'\d{4}$').hasMatch(text)) warnings.add(CandidateWarning.missingYear);
      return null;
    }
    final m = monthFirst ?? dayFirst!;
    final yearText = m.group(3);
    if (yearText == null) { warnings.add(CandidateWarning.missingYear); return null; }
    final month = (monthFirst != null ? m.group(1)! : m.group(2)!).substring(0, 3).toLowerCase();
    final day = int.parse(monthFirst != null ? m.group(2)! : m.group(1)!);
    final date = LocalDate.tryParse('$yearText-${_monthNumbers[month]!.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
    if (date == null) warnings.add(CandidateWarning.invalidDate);
    return date;
  }

  LocalTime? _time(Match m, {required bool explicit24}) {
    var hour = int.tryParse(m.group(1) ?? m.group(4) ?? '');
    final minute = int.tryParse(m.group(2) ?? m.group(5) ?? '0');
    if (hour == null || minute == null || minute > 59) return null;
    final suffix = m.group(3)?.toUpperCase();
    if (suffix != null) {
      if (hour < 1 || hour > 12) return null;
      hour = hour % 12 + (suffix == 'PM' ? 12 : 0);
    } else {
      final digits = m.group(4)!;
      if (hour > 23 || (!explicit24 && hour >= 1 && hour <= 12 && !digits.startsWith('0'))) return null;
    }
    return LocalTime(hour, minute);
  }
}
