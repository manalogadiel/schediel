import 'package:collection/collection.dart';

import '../../../core/schedule/agenda.dart';
import '../../../core/schedule/models.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/schedule/occurrence_engine.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import '../../../core/time/zone_resolver.dart';
import '../domain/widget_config.dart';

const widgetSnapshotKey = 'schediel_widget_snapshot';
const widgetSnapshotVersion = '1.0';
const widgetMaxOccurrences = 24;
const widgetCoverageDays = 7;

/// Serializes committed occurrences and per-widget settings into the native
/// widget snapshot (contracts/schemas/widget-snapshot-v1.schema.json).
class WidgetSnapshotBuilder {
  WidgetSnapshotBuilder(this.zones, this.engine);

  final ZoneResolver zones;
  final OccurrenceEngine engine;

  Map<String, Object?> build({
    required List<ScheduleSeries> series,
    required List<WidgetConfig> configs,
    required DateTime now,
    required String zone,
    required int dataRevision,
    required bool use24h,
    bool appIsDark = false,
  }) {
    final utcNow = now.toUtc();
    final today = zones.localDateOf(utcNow, zone);
    final windowStart = zones.startOfDay(today, zone);
    var coverageEnd = zones.startOfDay(today.addDays(widgetCoverageDays), zone);

    final allConfigs = [
      if (!configs.any((c) => c.widgetKey == WidgetConfig.defaultKey)) WidgetConfig.defaults,
      ...configs,
    ];
    final widgets = <String, Object?>{};
    for (final config in allConfigs) {
      final visible = [for (final s in series) if (config.filter.matches(s.categoryId)) s];
      final occurrences = <Occurrence>[];
      for (final s in visible) {
        occurrences.addAll(engine
            .expand(s, windowStart: windowStart, windowEnd: coverageEnd, viewZone: zone, cap: widgetMaxOccurrences * 4)
            .occurrences);
      }
      final upcoming = occurrences.where((o) => !_endedBefore(o, utcNow)).toList();
      mergeSort(upcoming, compare: (a, b) => _compare(a, b, zone));
      if (upcoming.length > widgetMaxOccurrences) {
        final firstOmitted = _sortInstant(upcoming[widgetMaxOccurrences], zone);
        if (firstOmitted.isBefore(coverageEnd)) coverageEnd = firstOmitted;
        upcoming.removeRange(widgetMaxOccurrences, upcoming.length);
      }
      widgets[config.widgetKey] = {
        'configuration': {
          'configRevision': config.revision,
          'layout': config.layout.name,
          'surface': config.surface.name,
          'textTone': (config.matchApp ? (appIsDark ? WidgetTextTone.light : WidgetTextTone.dark) : config.textTone).name,
          'nextEmphasis': config.nextEmphasis,
          'visibleDetails': {
            'location': config.showLocation,
            'professor': config.showProfessor,
            'subtitle': config.showSubtitle,
          },
        },
        'occurrences': [for (final o in upcoming) _occurrence(o, config, zone, use24h)],
        'emptyReason': series.isEmpty
            ? 'noSchedules'
            : visible.isEmpty
                ? 'noneInFilter'
                : null,
      };
    }

    // A truncated widget pulled coverage in; drop entries beyond it so every
    // projection is complete up to coverageEnd.
    for (final entry in widgets.values) {
      final projection = entry as Map<String, Object?>;
      final list = projection['occurrences'] as List<Map<String, Object?>>;
      list.removeWhere((o) => !_startsBefore(o, coverageEnd, zone));
    }

    return {
      'schemaVersion': widgetSnapshotVersion,
      'dataRevision': dataRevision,
      'generatedAt': utcNow.toIso8601String(),
      'deviceTimeZone': zone,
      'coverageEnd': coverageEnd.toIso8601String(),
      'widgets': widgets,
    };
  }

  bool _endedBefore(Occurrence o, DateTime now) {
    final t = o.timing;
    if (t is! TimedTiming) return false;
    final end = t.endUtc;
    return end == null ? !now.isBefore(t.startUtc) : !now.isBefore(end);
  }

  DateTime _sortInstant(Occurrence o, String zone) => switch (o.timing) {
        TimedTiming(:final startUtc) => startUtc,
        DateOnlyTiming(:final startDate) => zones.startOfDay(startDate, zone),
        UnresolvedTiming(:final localDate, :final sourceZone, :final localStartTime) =>
          zones.startOfDay(localDate, sourceZone).add(Duration(minutes: localStartTime.minutesOfDay)),
      };

  int _compare(Occurrence a, Occurrence b, String zone) {
    final byStart = _sortInstant(a, zone).compareTo(_sortInstant(b, zone));
    if (byStart != 0) return byStart;
    if (a.timing is TimedTiming && b.timing is TimedTiming) return compareTimed(a, b);
    return a.id.compareTo(b.id);
  }

  bool _startsBefore(Map<String, Object?> o, DateTime coverageEnd, String zone) {
    final start = o['startEpochMs'] as int?;
    if (start != null) return start < coverageEnd.millisecondsSinceEpoch;
    final date = LocalDate.parse(o['startDate'] as String);
    return zones.startOfDay(date, zone).isBefore(coverageEnd);
  }

  Map<String, Object?> _occurrence(Occurrence o, WidgetConfig config, String zone, bool use24h) {
    final t = o.timing;
    final details = o.details;
    String? zoneLabel;
    int? start;
    int? end;
    String startDate;
    String? endDateExclusive;
    var status = 'resolved';
    switch (t) {
      case TimedTiming():
        start = t.startUtc.millisecondsSinceEpoch;
        end = t.endUtc?.millisecondsSinceEpoch;
        startDate = t.localStartDate.toIso();
        if (t.sourceZone != zone) zoneLabel = _zoneLabel(t.localStartTime, t.sourceZone, t.startUtc, use24h);
      case DateOnlyTiming():
        startDate = t.startDate.toIso();
        endDateExclusive = t.endDateExclusive.toIso();
      case UnresolvedTiming():
        startDate = t.localDate.toIso();
        status = 'needsTimeReview';
        if (t.sourceZone != zone) {
          zoneLabel = _zoneLabel(t.localStartTime, t.sourceZone, zones.startOfDay(t.localDate, t.sourceZone), use24h);
        }
    }
    return {
      'occurrenceId': o.id,
      'seriesId': o.seriesId,
      'originalKey': o.originalKey.toIso(),
      'kind': t is DateOnlyTiming ? 'dateOnly' : 'timed',
      'title': o.title,
      'startEpochMs': start,
      'endEpochMs': end,
      'startDate': startDate,
      'endDateExclusive': endDateExclusive,
      'timeStatus': status,
      'zoneLabel': zoneLabel,
      'location': config.showLocation ? details.location : null,
      'professor': config.showProfessor ? details.professor : null,
      'subtitle': config.showSubtitle ? details.subtitle : null,
      'deepLink': 'schediel://occurrence/${o.seriesId}/${o.originalKey.toIso()}',
    };
  }

  String _zoneLabel(LocalTime time, String sourceZone, DateTime instant, bool use24h) {
    final clock = use24h ? time.toHhMm() : _twelveHour(time);
    final city = sourceZone.split('/').last.replaceAll('_', ' ');
    final full = '$clock $city';
    if (full.length <= 16) return full;
    final abbreviated = '$clock ${zones.abbreviation(instant, sourceZone)}';
    return abbreviated.length <= 16 ? abbreviated : clock;
  }

  String _twelveHour(LocalTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$hour:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  }
}
