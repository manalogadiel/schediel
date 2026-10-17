import 'package:flutter/foundation.dart';

import 'occurrence.dart';

enum AgendaMode { today, otherDay }

/// A day's occurrences grouped for the timeline (spec section 6.5).
@immutable
class DayAgenda {
  const DayAgenda({
    required this.dateOnly,
    required this.needsReview,
    required this.ongoing,
    required this.next,
    required this.upcoming,
    required this.past,
    required this.timed,
  });

  /// Date-only entries; never assigned a time and never "next".
  final List<Occurrence> dateOnly;

  /// Timed entries whose wall time needs an explicit choice.
  final List<Occurrence> needsReview;

  /// Today only: start <= now < end.
  final List<Occurrence> ongoing;

  /// Today only: the earliest future start.
  final Occurrence? next;

  /// Today only: future starts after [next].
  final List<Occurrence> upcoming;

  /// Today only: ended intervals and started point events.
  final List<Occurrence> past;

  /// Other days: every resolved timed entry in chronological order.
  final List<Occurrence> timed;

  bool get isEmpty =>
      dateOnly.isEmpty &&
      needsReview.isEmpty &&
      ongoing.isEmpty &&
      next == null &&
      upcoming.isEmpty &&
      past.isEmpty &&
      timed.isEmpty;

  /// Today with entries but nothing ongoing or still to start.
  bool get isFinished => ongoing.isEmpty && next == null && upcoming.isEmpty && past.isNotEmpty;
}

/// Stable chronological order: start, end (a point event ends at its start),
/// normalized title, then id.
int compareTimed(Occurrence a, Occurrence b) {
  final ta = a.timing as TimedTiming;
  final tb = b.timing as TimedTiming;
  var result = ta.startUtc.compareTo(tb.startUtc);
  if (result != 0) return result;
  result = (ta.endUtc ?? ta.startUtc).compareTo(tb.endUtc ?? tb.startUtc);
  if (result != 0) return result;
  result = _normalized(a.title).compareTo(_normalized(b.title));
  if (result != 0) return result;
  return a.id.compareTo(b.id);
}

String _normalized(String title) => title.trim().toLowerCase();

bool hasEnded(TimedTiming timing, DateTime now) {
  final end = timing.endUtc;
  if (end == null) return !now.isBefore(timing.startUtc);
  return !now.isBefore(end);
}

bool isOngoing(TimedTiming timing, DateTime now) {
  final end = timing.endUtc;
  return end != null && !now.isBefore(timing.startUtc) && now.isBefore(end);
}

DayAgenda buildDayAgenda(List<Occurrence> occurrences, {required DateTime now, required AgendaMode mode}) {
  final dateOnly = <Occurrence>[];
  final needsReview = <Occurrence>[];
  final timed = <Occurrence>[];
  for (final occurrence in occurrences) {
    switch (occurrence.timing) {
      case DateOnlyTiming():
        dateOnly.add(occurrence);
      case UnresolvedTiming():
        needsReview.add(occurrence);
      case TimedTiming():
        timed.add(occurrence);
    }
  }
  timed.sort(compareTimed);
  if (mode == AgendaMode.otherDay) {
    return DayAgenda(
      dateOnly: List.unmodifiable(dateOnly),
      needsReview: List.unmodifiable(needsReview),
      ongoing: const [],
      next: null,
      upcoming: const [],
      past: const [],
      timed: List.unmodifiable(timed),
    );
  }

  final utcNow = now.toUtc();
  final ongoing = <Occurrence>[];
  final future = <Occurrence>[];
  final past = <Occurrence>[];
  for (final occurrence in timed) {
    final timing = occurrence.timing as TimedTiming;
    if (isOngoing(timing, utcNow)) {
      ongoing.add(occurrence);
    } else if (hasEnded(timing, utcNow)) {
      past.add(occurrence);
    } else {
      future.add(occurrence);
    }
  }
  ongoing.sort((a, b) {
    final ea = (a.timing as TimedTiming).endUtc!;
    final eb = (b.timing as TimedTiming).endUtc!;
    final byEnd = ea.compareTo(eb);
    return byEnd != 0 ? byEnd : compareTimed(a, b);
  });
  return DayAgenda(
    dateOnly: List.unmodifiable(dateOnly),
    needsReview: List.unmodifiable(needsReview),
    ongoing: List.unmodifiable(ongoing),
    next: future.isEmpty ? null : future.first,
    upcoming: List.unmodifiable(future.skip(1)),
    past: List.unmodifiable(past),
    timed: const [],
  );
}
