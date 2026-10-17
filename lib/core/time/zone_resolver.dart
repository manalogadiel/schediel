import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'local_date.dart';
import 'local_time.dart';

/// How a wall-clock time maps onto instants in a zone.
enum WallTimeKind { normal, ambiguous, nonexistent }

@immutable
class WallTimeResolution {
  const WallTimeResolution(this.kind, this.candidates);

  final WallTimeKind kind;

  /// UTC instants that display as the wall time, ascending. Empty in a gap,
  /// two entries in a fold.
  final List<DateTime> candidates;

  /// The instant when exactly one exists.
  DateTime? get single => kind == WallTimeKind.normal ? candidates.single : null;
}

@immutable
class LocalDateTimeParts {
  const LocalDateTimeParts(this.date, this.time);
  final LocalDate date;
  final LocalTime time;
}

/// IANA time-zone arithmetic on the bundled, pinned tz database
/// (package:timezone). The database updates with the package version.
class ZoneResolver {
  ZoneResolver._();

  static bool _loaded = false;

  /// Loads the bundled database once and returns a resolver.
  factory ZoneResolver.initialized() {
    if (!_loaded) {
      tzdata.initializeTimeZones();
      _loaded = true;
    }
    return ZoneResolver._();
  }

  static const Duration _probe = Duration(hours: 30);

  bool isValidZone(String id) {
    if (id.isEmpty) return false;
    return tz.timeZoneDatabase.locations.containsKey(id);
  }

  tz.Location location(String id) => tz.getLocation(id);

  /// All canonical zone ids in the bundled database, sorted.
  List<String> get zoneIds => tz.timeZoneDatabase.locations.keys.toList()..sort();

  WallTimeResolution resolve(String zoneId, LocalDate date, LocalTime time) {
    final loc = tz.getLocation(zoneId);
    final wall = DateTime.utc(date.year, date.month, date.day, time.hour, time.minute)
        .millisecondsSinceEpoch;
    final offsets = <int>{
      loc.timeZone(wall - _probe.inMilliseconds).offset.inMilliseconds,
      loc.timeZone(wall).offset.inMilliseconds,
      loc.timeZone(wall + _probe.inMilliseconds).offset.inMilliseconds,
    };
    final instants = <int>{};
    for (final offset in offsets) {
      final candidate = wall - offset;
      if (loc.timeZone(candidate).offset.inMilliseconds == offset) {
        instants.add(candidate);
      }
    }
    final sorted = instants.toList()..sort();
    final candidates = [
      for (final ms in sorted) DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
    ];
    final kind = switch (candidates.length) {
      0 => WallTimeKind.nonexistent,
      1 => WallTimeKind.normal,
      _ => WallTimeKind.ambiguous,
    };
    return WallTimeResolution(kind, List.unmodifiable(candidates));
  }

  LocalDateTimeParts toLocal(DateTime instant, String zoneId) {
    final loc = tz.getLocation(zoneId);
    final ms = instant.toUtc().millisecondsSinceEpoch;
    final shifted = DateTime.fromMillisecondsSinceEpoch(
      ms + loc.timeZone(ms).offset.inMilliseconds,
      isUtc: true,
    );
    return LocalDateTimeParts(
      LocalDate(shifted.year, shifted.month, shifted.day),
      LocalTime(shifted.hour, shifted.minute),
    );
  }

  LocalDate localDateOf(DateTime instant, String zoneId) => toLocal(instant, zoneId).date;

  String abbreviation(DateTime instant, String zoneId) =>
      tz.getLocation(zoneId).timeZone(instant.toUtc().millisecondsSinceEpoch).abbreviation;

  /// The first instant of [date] in [zoneId]. Days that begin inside a gap
  /// start at the first existing minute.
  DateTime startOfDay(LocalDate date, String zoneId) {
    for (var minute = 0; minute < 24 * 60; minute += 15) {
      final resolution = resolve(zoneId, date, LocalTime.fromMinutes(minute));
      if (resolution.candidates.isNotEmpty) {
        final first = resolution.candidates.first;
        return first.subtract(Duration(minutes: minute));
      }
    }
    throw StateError('No instant found for $date in $zoneId');
  }
}
