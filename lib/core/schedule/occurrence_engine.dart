import '../time/local_date.dart';
import '../time/local_time.dart';
import '../time/zone_resolver.dart';
import 'models.dart';
import 'occurrence.dart';

/// Bounded, pure expansion of a series into occurrences. Never enumerates an
/// infinite rule: every call has a finite window and an output cap.
class OccurrenceEngine {
  OccurrenceEngine(this.zones);

  final ZoneResolver zones;

  static const int defaultCap = 500;

  /// Whether [date] is an original occurrence date of the series rule.
  bool isOriginalDate(ScheduleSeries series, LocalDate date) {
    final start = series.time.startDate;
    if (date.isBefore(start)) return false;
    final rule = series.recurrence;
    if (rule == null) return date == start;
    final until = rule.untilDateInclusive;
    if (until != null && date.isAfter(until)) return false;
    return switch (rule.frequency) {
      RecurrenceFrequency.daily => true,
      RecurrenceFrequency.weekly => rule.weekdays.contains(date.weekday),
    };
  }

  /// Original occurrence dates from [from] (inclusive) to [toExclusive],
  /// at most [cap] values.
  List<LocalDate> originalDates(
    ScheduleSeries series,
    LocalDate from,
    LocalDate toExclusive, {
    int cap = 1000,
  }) {
    final result = <LocalDate>[];
    var cursor = from.isBefore(series.time.startDate) ? series.time.startDate : from;
    final rule = series.recurrence;
    var end = toExclusive;
    if (rule == null) {
      final seed = series.time.startDate;
      return (!seed.isBefore(from) && seed.isBefore(toExclusive)) ? [seed] : const [];
    }
    final until = rule.untilDateInclusive;
    if (until != null && until.addDays(1).isBefore(end)) end = until.addDays(1);
    while (cursor.isBefore(end) && result.length < cap) {
      if (isOriginalDate(series, cursor)) result.add(cursor);
      cursor = cursor.addDays(1);
    }
    return result;
  }

  ExpansionResult expand(
    ScheduleSeries series, {
    required DateTime windowStart,
    required DateTime windowEnd,
    required String viewZone,
    int cap = defaultCap,
  }) {
    final ws = windowStart.toUtc();
    final we = windowEnd.toUtc();
    if (!ws.isBefore(we)) return const ExpansionResult([], truncated: false);

    final exceptionKeys = {for (final e in series.exceptions) e.originalKey};
    final candidates = <Occurrence>[];

    final range = _originalDateRange(series, ws, we, viewZone);
    final dates = originalDates(series, range.$1, range.$2, cap: cap + exceptionKeys.length + 1);
    for (final date in dates) {
      if (exceptionKeys.contains(date)) continue;
      final occurrence = _build(
        series: series,
        key: date,
        title: series.title,
        details: series.details,
        time: series.time,
        occurrenceDate: date,
        isSeed: date == series.time.startDate,
        isOverride: false,
      );
      if (_overlaps(occurrence.timing, ws, we, viewZone)) candidates.add(occurrence);
    }

    for (final exception in series.exceptions) {
      final replacement = exception.replacement;
      if (exception.action != ExceptionAction.override || replacement == null) continue;
      if (!isOriginalDate(series, exception.originalKey)) continue;
      final occurrence = _build(
        series: series,
        key: exception.originalKey,
        title: replacement.title,
        details: replacement.details,
        time: replacement.time,
        occurrenceDate: replacement.time.startDate,
        isSeed: true,
        isOverride: true,
      );
      if (_overlaps(occurrence.timing, ws, we, viewZone)) candidates.add(occurrence);
    }

    candidates.sort((a, b) {
      final byTime = _sortInstant(a.timing, viewZone).compareTo(_sortInstant(b.timing, viewZone));
      if (byTime != 0) return byTime;
      return a.originalKey.compareTo(b.originalKey);
    });
    final truncated = candidates.length > cap;
    return ExpansionResult(
      List.unmodifiable(truncated ? candidates.sublist(0, cap) : candidates),
      truncated: truncated,
    );
  }

  /// Local original dates that could produce an occurrence overlapping the
  /// window, widened by one day for overnight entries and zone differences.
  (LocalDate, LocalDate) _originalDateRange(
    ScheduleSeries series,
    DateTime ws,
    DateTime we,
    String viewZone,
  ) {
    final time = series.time;
    switch (time) {
      case TimedSpec():
        final from = zones.localDateOf(ws, time.timeZone).addDays(-1);
        final to = zones.localDateOf(we, time.timeZone).addDays(2);
        return (from, to);
      case DateOnlySpec():
        final from = zones.localDateOf(ws, viewZone).addDays(-time.spanDays);
        final to = zones.localDateOf(we, viewZone).addDays(2);
        return (from, to);
    }
  }

  Occurrence _build({
    required ScheduleSeries series,
    required LocalDate key,
    required String title,
    required ScheduleDetails details,
    required TimeSpec time,
    required LocalDate occurrenceDate,
    required bool isSeed,
    required bool isOverride,
  }) {
    final OccurrenceTiming timing = switch (time) {
      TimedSpec() => _resolveTimed(time, occurrenceDate, isSeed),
      DateOnlySpec() => DateOnlyTiming(
          startDate: occurrenceDate,
          endDateExclusive: occurrenceDate.addDays(time.spanDays),
        ),
    };
    return Occurrence(
      seriesId: series.id,
      originalKey: key,
      title: title,
      categoryId: series.categoryId,
      details: details,
      timing: timing,
      isOverride: isOverride,
      seriesRevision: series.revision,
      isRecurring: series.isRecurring,
    );
  }

  OccurrenceTiming _resolveTimed(TimedSpec spec, LocalDate date, bool isSeed) {
    UnresolvedTiming unresolved(TimeReviewReason reason) => UnresolvedTiming(
          localDate: date,
          localStartTime: spec.startTime,
          sourceZone: spec.timeZone,
          reason: reason,
        );

    final start = _pick(
      zones.resolve(spec.timeZone, date, spec.startTime),
      isSeed ? spec.seedTimeResolution : null,
    );
    if (start.instant == null) {
      return unresolved(start.ambiguous ? TimeReviewReason.startAmbiguous : TimeReviewReason.startNonexistent);
    }

    DateTime? endUtc;
    final endTime = spec.endTime;
    if (endTime != null) {
      final endDate = date.addDays(spec.endDayOffset ?? 0);
      final end = _pick(
        zones.resolve(spec.timeZone, endDate, endTime),
        isSeed ? spec.endTimeResolution : null,
      );
      if (end.instant == null) {
        return unresolved(end.ambiguous ? TimeReviewReason.endAmbiguous : TimeReviewReason.endNonexistent);
      }
      if (!end.instant!.isAfter(start.instant!)) return unresolved(TimeReviewReason.invalidRange);
      endUtc = end.instant;
    }

    return TimedTiming(
      startUtc: start.instant!,
      endUtc: endUtc,
      sourceZone: spec.timeZone,
      localStartDate: date,
      localStartTime: spec.startTime,
    );
  }

  ({DateTime? instant, bool ambiguous}) _pick(WallTimeResolution r, TimeResolution? choice) {
    switch (r.kind) {
      case WallTimeKind.normal:
        return (instant: r.candidates.single, ambiguous: false);
      case WallTimeKind.nonexistent:
        return (instant: null, ambiguous: false);
      case WallTimeKind.ambiguous:
        if (choice == null) return (instant: null, ambiguous: true);
        return (
          instant: choice == TimeResolution.earlier ? r.candidates.first : r.candidates.last,
          ambiguous: true,
        );
    }
  }

  bool _overlaps(OccurrenceTiming timing, DateTime ws, DateTime we, String viewZone) {
    switch (timing) {
      case TimedTiming(:final startUtc, :final endUtc):
        if (endUtc == null) return !startUtc.isBefore(ws) && startUtc.isBefore(we);
        return startUtc.isBefore(we) && endUtc.isAfter(ws);
      case DateOnlyTiming(:final startDate, :final endDateExclusive):
        final start = zones.startOfDay(startDate, viewZone);
        final end = zones.startOfDay(endDateExclusive, viewZone);
        return start.isBefore(we) && end.isAfter(ws);
      case UnresolvedTiming(:final localDate, :final sourceZone):
        final start = zones.startOfDay(localDate, sourceZone);
        final end = zones.startOfDay(localDate.addDays(1), sourceZone);
        return start.isBefore(we) && end.isAfter(ws);
    }
  }

  DateTime _sortInstant(OccurrenceTiming timing, String viewZone) => switch (timing) {
        TimedTiming(:final startUtc) => startUtc,
        DateOnlyTiming(:final startDate) => zones.startOfDay(startDate, viewZone),
        UnresolvedTiming(:final localDate, :final sourceZone, :final localStartTime) =>
          zones.startOfDay(localDate, sourceZone).add(Duration(minutes: localStartTime.minutesOfDay)),
      };
}

/// Minutes in a day, used by callers that need a local day window.
const int minutesPerDay = 24 * 60;

/// The local day [date] as a UTC window in [zone].
(DateTime, DateTime) dayWindow(ZoneResolver zones, LocalDate date, String zone) =>
    (zones.startOfDay(date, zone), zones.startOfDay(date.addDays(1), zone));

/// Converts a local wall time to minutes for display ordering.
int wallMinutes(LocalTime time) => time.minutesOfDay;
