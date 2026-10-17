import 'package:flutter/foundation.dart';

import '../../../core/schedule/models.dart';
import '../../../core/schedule/occurrence.dart';
import '../../../core/schedule/occurrence_engine.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import '../../../core/time/zone_resolver.dart';
import '../domain/alert_rule.dart';

@immutable
class PlanInput {
  const PlanInput({
    required this.series,
    required this.rules,
    required this.now,
    required this.zone,
    required this.horizon,
    required this.capacity,
    required this.platform,
    required this.use24h,
  });

  final List<ScheduleSeries> series;
  final List<AlertRule> rules;
  final DateTime now;
  final String zone;
  final Duration horizon;
  final int capacity;
  final String platform;
  final bool use24h;
}

/// One desired native request derived from a rule and an occurrence.
@immutable
class PlannedAlert {
  const PlannedAlert({
    required this.requestKey,
    required this.ruleId,
    required this.seriesId,
    required this.occurrenceKey,
    required this.kind,
    required this.triggerAt,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.sourceRevision,
    required this.snoozeMinutes,
    required this.prominentRequested,
  });

  final String requestKey;
  final String ruleId;
  final String seriesId;
  final LocalDate occurrenceKey;
  final AlertKind kind;
  final DateTime triggerAt;
  final String title;
  final String body;
  final String deepLink;
  final int sourceRevision;
  final int? snoozeMinutes;
  final bool prominentRequested;
}

@immutable
class AlertPlan {
  const AlertPlan(this.requests, this.overflow);

  /// Nearest requests within capacity, ordered by trigger.
  final List<PlannedAlert> requests;

  /// Requests beyond capacity: visible as unscheduled, replenished later.
  final List<PlannedAlert> overflow;
}

/// Pure derivation of desired alert requests for a bounded horizon
/// (spec 7.6 steps 1-2). Past triggers are never scheduled.
class AlertPlanner {
  AlertPlanner(this.zones, this.engine);

  final ZoneResolver zones;
  final OccurrenceEngine engine;

  AlertPlan plan(PlanInput input, AlertKind kind) {
    final now = input.now.toUtc();
    final horizonEnd = now.add(input.horizon);
    final bySeries = <String, AlertRule>{};
    for (final r in input.rules) {
      if (r.kind == kind && r.preference.enabled) bySeries[r.seriesId] = r;
    }
    final planned = <PlannedAlert>[];
    for (final series in input.series) {
      final rule = bySeries[series.id];
      if (rule == null) continue;
      final p = rule.preference;
      final offset = Duration(minutes: p.offsetMinutes);
      final occurrences = engine
          .expand(
            series,
            windowStart: now.subtract(const Duration(days: 1)),
            windowEnd: horizonEnd.add(offset).add(const Duration(days: 1)),
            viewZone: input.zone,
            cap: 1000,
          )
          .occurrences;
      for (final o in occurrences) {
        final anchor = _anchor(o, p);
        if (anchor == null) continue;
        final trigger = anchor.subtract(offset);
        if (!trigger.isAfter(now) || trigger.isAfter(horizonEnd)) continue;
        planned.add(PlannedAlert(
          requestKey: '${rule.id}|${o.id}|${input.platform}',
          ruleId: rule.id,
          seriesId: series.id,
          occurrenceKey: o.originalKey,
          kind: kind,
          triggerAt: trigger,
          title: o.title,
          body: _body(o, p, input),
          deepLink: 'schediel://occurrence/${o.seriesId}/${o.originalKey.toIso()}',
          sourceRevision: series.revision,
          snoozeMinutes: p.snoozeMinutes,
          prominentRequested: p.presentationPreference == PresentationPreference.prominentIfSupported,
        ));
      }
    }
    planned.sort((a, b) {
      final byTrigger = a.triggerAt.compareTo(b.triggerAt);
      return byTrigger != 0 ? byTrigger : a.requestKey.compareTo(b.requestKey);
    });
    final cut = planned.length < input.capacity ? planned.length : input.capacity;
    return AlertPlan(List.unmodifiable(planned.sublist(0, cut)), List.unmodifiable(planned.sublist(cut)));
  }

  DateTime? _anchor(Occurrence o, AlertPreference p) {
    final t = o.timing;
    switch (t) {
      case TimedTiming():
        return t.startUtc;
      case UnresolvedTiming():
        return null;
      case DateOnlyTiming():
        final time = p.dateOnlyAnchorTime;
        final zone = p.dateOnlyAnchorZone;
        if (time == null || zone == null || !zones.isValidZone(zone)) return null;
        final resolved = zones.resolve(zone, t.startDate, time);
        return resolved.candidates.isEmpty ? null : resolved.candidates.first;
    }
  }

  String _body(Occurrence o, AlertPreference p, PlanInput input) {
    final t = o.timing;
    String time;
    if (t is TimedTiming) {
      final start = zones.toLocal(t.startUtc, input.zone).time;
      final end = t.endUtc == null ? null : zones.toLocal(t.endUtc!, input.zone).time;
      time = end == null ? _clock(start, input.use24h) : '${_clock(start, input.use24h)} – ${_clock(end, input.use24h)}';
    } else {
      time = 'All day';
    }
    if (p.lockScreenDetails == LockScreenDetails.titleOnly) return time;
    return [time, o.details.location, o.details.professor].whereType<String>().join(' · ');
  }

  String _clock(LocalTime t, bool use24h) {
    if (use24h) return t.toHhMm();
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$hour:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  }
}

/// Stable positive 31-bit notification id for a request key (FNV-1a).
int notificationIdFor(String requestKey) {
  var hash = 0x811c9dc5;
  for (final unit in requestKey.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final id = hash & 0x7fffffff;
  return id == 0 ? 1 : id;
}
