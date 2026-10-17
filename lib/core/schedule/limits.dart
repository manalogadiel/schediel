/// Proposed product bounds (SCHEDULER_SPEC.md section 16.1 and the frozen
/// share contract). Lengths count Unicode code points.
abstract final class ScheduleLimits {
  static const int titleMax = 120;
  static const int categoryNameMax = 60;
  static const int locationMax = 240;
  static const int professorMax = 160;
  static const int subtitleMax = 240;
  static const int notesMax = 4000;
  static const int dateOnlyMaxSpanDays = 366;
  static const int shareMaxItems = 250;
  static const int shareMaxExceptions = 500;
  static const int shareMaxBytes = 524288;
}

/// Number of Unicode code points (not UTF-16 code units).
int codePointLength(String value) => value.runes.length;

/// Trims accidental surrounding whitespace; empty input becomes null. The
/// user's inner text is never rewritten.
String? normalizeOptionalText(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool isTrimmed(String value) => value.trim() == value;
