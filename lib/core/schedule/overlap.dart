import 'occurrence.dart';

/// Whether two resolved timed occurrences overlap. Intervals are
/// start-inclusive and end-exclusive; an occurrence without an end is a point
/// at its start. Adjacent intervals do not overlap.
bool timedOverlap(TimedTiming a, TimedTiming b) {
  final aEnd = a.endUtc;
  final bEnd = b.endUtc;
  if (aEnd == null && bEnd == null) return a.startUtc == b.startUtc;
  if (aEnd == null) return _pointInside(a.startUtc, b.startUtc, bEnd!);
  if (bEnd == null) return _pointInside(b.startUtc, a.startUtc, aEnd);
  return a.startUtc.isBefore(bEnd) && b.startUtc.isBefore(aEnd);
}

bool _pointInside(DateTime point, DateTime start, DateTime end) =>
    !point.isBefore(start) && point.isBefore(end);

/// Ids of resolved timed occurrences that overlap at least one other.
/// Date-only and unresolved occurrences are not compared as timed overlaps.
Set<String> overlappingIds(List<Occurrence> occurrences) {
  final timed = [
    for (final o in occurrences)
      if (o.timing is TimedTiming) o,
  ];
  final result = <String>{};
  for (var i = 0; i < timed.length; i++) {
    for (var j = i + 1; j < timed.length; j++) {
      if (timedOverlap(timed[i].timing as TimedTiming, timed[j].timing as TimedTiming)) {
        result
          ..add(timed[i].id)
          ..add(timed[j].id);
      }
    }
  }
  return result;
}
