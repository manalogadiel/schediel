import 'package:flutter/foundation.dart';

import '../time/local_date.dart';
import '../time/local_time.dart';
import 'models.dart';

/// Why an occurrence cannot be placed on the timeline without a user choice.
enum TimeReviewReason { startNonexistent, startAmbiguous, endNonexistent, endAmbiguous, invalidRange }

sealed class OccurrenceTiming {
  const OccurrenceTiming();
}

/// A timed occurrence with resolved instants. [endUtc] is null for a point
/// event; no duration is invented.
@immutable
final class TimedTiming extends OccurrenceTiming {
  const TimedTiming({
    required this.startUtc,
    required this.endUtc,
    required this.sourceZone,
    required this.localStartDate,
    required this.localStartTime,
  });

  final DateTime startUtc;
  final DateTime? endUtc;
  final String sourceZone;
  final LocalDate localStartDate;
  final LocalTime localStartTime;
}

@immutable
final class DateOnlyTiming extends OccurrenceTiming {
  const DateOnlyTiming({required this.startDate, required this.endDateExclusive});

  final LocalDate startDate;
  final LocalDate endDateExclusive;
}

/// A timed occurrence whose wall time is ambiguous, nonexistent or inverted
/// in its source zone. It is visibly unscheduled until explicitly resolved.
@immutable
final class UnresolvedTiming extends OccurrenceTiming {
  const UnresolvedTiming({
    required this.localDate,
    required this.localStartTime,
    required this.sourceZone,
    required this.reason,
  });

  final LocalDate localDate;
  final LocalTime localStartTime;
  final String sourceZone;
  final TimeReviewReason reason;
}

/// One concrete instance of a series, keyed by its original local date.
@immutable
class Occurrence {
  const Occurrence({
    required this.seriesId,
    required this.originalKey,
    required this.title,
    required this.categoryId,
    required this.details,
    required this.timing,
    required this.isOverride,
    required this.seriesRevision,
    required this.isRecurring,
  });

  final String seriesId;
  final LocalDate originalKey;
  final String title;
  final String? categoryId;
  final ScheduleDetails details;
  final OccurrenceTiming timing;
  final bool isOverride;
  final int seriesRevision;
  final bool isRecurring;

  /// Stable logical identity: series plus original occurrence date.
  String get id => '$seriesId/${originalKey.toIso()}';
}

@immutable
class ExpansionResult {
  const ExpansionResult(this.occurrences, {required this.truncated});

  final List<Occurrence> occurrences;

  /// True when the output cap stopped expansion before the window ended.
  final bool truncated;
}
