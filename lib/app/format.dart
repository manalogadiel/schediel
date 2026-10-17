import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/schedule/models.dart';
import '../core/schedule/occurrence.dart';
import '../core/time/local_date.dart';
import '../core/time/local_time.dart';
import '../core/time/zone_resolver.dart';

/// Locale-aware labels built only from actual values.
class Formats {
  Formats(this.locale, {required this.use24h});

  factory Formats.of(BuildContext context) => Formats(
        Localizations.localeOf(context).toLanguageTag(),
        use24h: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  final String locale;
  final bool use24h;

  DateTime _dt(LocalDate d) => DateTime.utc(d.year, d.month, d.day);

  String clock(LocalTime t) =>
      use24h ? t.toHhMm() : DateFormat.jm(locale).format(DateTime.utc(2000, 1, 1, t.hour, t.minute));

  /// "Monday, November 2"
  String dayTitle(LocalDate d) => DateFormat.MMMMEEEEd(locale).format(_dt(d));

  /// "Mon, Nov 2"
  String shortDate(LocalDate d) => DateFormat.MMMEd(locale).format(_dt(d));

  /// "Mon, Nov 2, 2026"
  String fullDate(LocalDate d) => DateFormat.yMMMEd(locale).format(_dt(d));

  /// "Nov 2"
  String monthDay(LocalDate d) => DateFormat.MMMd(locale).format(_dt(d));

  /// ISO weekday 1..7 -> "Mon". 2024-01-01 was a Monday.
  String weekdayShort(int isoWeekday) => DateFormat.E(locale).format(DateTime.utc(2024, 1, isoWeekday));

  String weekdayLong(int isoWeekday) => DateFormat.EEEE(locale).format(DateTime.utc(2024, 1, isoWeekday));

  /// "Nov 2 – Nov 8, 2026"
  String range(LocalDate first, LocalDate last) {
    if (first == last) return fullDate(first);
    final sameYear = first.year == last.year;
    final left = sameYear ? monthDay(first) : DateFormat.yMMMd(locale).format(_dt(first));
    return '$left – ${DateFormat.yMMMd(locale).format(_dt(last))}';
  }

  String repeatSummary(RecurrenceSpec? rule) {
    if (rule == null) return 'Does not repeat';
    final base = switch (rule.frequency) {
      RecurrenceFrequency.daily => 'Every day',
      RecurrenceFrequency.weekly =>
        rule.weekdays.length == 7 ? 'Every day' : 'Every ${rule.weekdays.map(weekdayShort).join(', ')}',
    };
    final until = rule.untilDateInclusive;
    return until == null ? base : '$base until ${fullDate(until)}';
  }

  /// "All day" for one date, otherwise the inclusive date range.
  String dateOnlyLabel(LocalDate start, LocalDate endExclusive) {
    final last = endExclusive.addDays(-1);
    return last == start ? 'All day' : range(start, last);
  }

  /// Relative day word, only for adjacent days.
  String? relativeDay(LocalDate date, LocalDate today) {
    final diff = today.daysUntil(date);
    return switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => null,
    };
  }

  String offsetLabel(int minutes) {
    if (minutes == 0) return 'At start time';
    if (minutes % (24 * 60) == 0) {
      final days = minutes ~/ (24 * 60);
      return days == 1 ? '1 day before' : '$days days before';
    }
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hour before' : '$hours hours before';
    }
    return minutes == 1 ? '1 minute before' : '$minutes minutes before';
  }
}

/// The readable city part of an IANA zone id ("America/New_York" -> "New York").
String zoneCity(String zoneId) => zoneId.split('/').last.replaceAll('_', ' ');

/// Display times of a resolved occurrence in the viewing zone.
class OccurrenceTimeText {
  OccurrenceTimeText._(this.start, this.end, this.endsNextDay, this.sourceNote);

  factory OccurrenceTimeText.of(TimedTiming t, ZoneResolver zones, String viewZone, Formats f) {
    final start = zones.toLocal(t.startUtc, viewZone);
    final endUtc = t.endUtc;
    final end = endUtc == null ? null : zones.toLocal(endUtc, viewZone);
    final nextDay = end != null && end.date.isAfter(start.date);
    final note = t.sourceZone == viewZone
        ? null
        : '${f.clock(t.localStartTime)} ${zoneCity(t.sourceZone)} time';
    return OccurrenceTimeText._(f.clock(start.time), end == null ? null : f.clock(end.time), nextDay, note);
  }

  final String start;
  final String? end;
  final bool endsNextDay;

  /// Source wall time when the schedule's zone differs from the device zone.
  final String? sourceNote;

  String get range {
    if (end == null) return start;
    return endsNextDay ? '$start – $end next day' : '$start – $end';
  }
}

/// Short explanation for an occurrence that needs a time decision.
String reviewReasonLabel(TimeReviewReason reason) => switch (reason) {
      TimeReviewReason.startNonexistent => 'The start time is skipped by a clock change on this date.',
      TimeReviewReason.startAmbiguous => 'The start time happens twice on this date because of a clock change.',
      TimeReviewReason.endNonexistent => 'The end time is skipped by a clock change on this date.',
      TimeReviewReason.endAmbiguous => 'The end time happens twice on this date because of a clock change.',
      TimeReviewReason.invalidRange => 'After a clock change the end is not after the start on this date.',
    };
