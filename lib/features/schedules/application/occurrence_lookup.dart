import '../../../core/schedule/models.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/schedule/occurrence_engine.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/zone_resolver.dart';

/// Resolves one occurrence from its stable key (series + original date),
/// for widget deep links and detail pages.
class OccurrenceLookup {
  OccurrenceLookup(this.zones, this.engine);

  final ZoneResolver zones;
  final OccurrenceEngine engine;

  Occurrence? find(ScheduleSeries series, LocalDate key, String viewZone) {
    if (!engine.isOriginalDate(series, key)) return null;
    final exception = series.exceptionFor(key);
    if (exception?.action == ExceptionAction.cancel) return null;
    final anchor = exception?.replacement?.time ?? series.time;
    final anchorDate = exception?.replacement != null ? anchor.startDate : key;
    final zone = anchor is TimedSpec ? anchor.timeZone : viewZone;
    final span = anchor is DateOnlySpec ? anchor.spanDays : 1;
    final result = engine.expand(
      series,
      windowStart: zones.startOfDay(anchorDate.addDays(-1), zone),
      windowEnd: zones.startOfDay(anchorDate.addDays(span + 2), zone),
      viewZone: viewZone,
    );
    for (final o in result.occurrences) {
      if (o.originalKey == key) return o;
    }
    return null;
  }
}
