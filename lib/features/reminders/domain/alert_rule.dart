import 'package:flutter/foundation.dart';

import '../../../core/time/local_time.dart';

/// Notification reminders and app-owned alarms are independent (spec 7.1).
enum AlertKind { notification, alarm }

/// Requested lock-screen disclosure; OS privacy settings remain authoritative.
enum LockScreenDetails { titleOnly, detailsRequested }

/// Never forces an unsupported full-screen takeover.
enum PresentationPreference { standard, prominentIfSupported }

/// Proposed upper bound for "minutes before" (CONTRACTS.md 3.1 requires a
/// configured bound before release).
const int maxAlertOffsetMinutes = 7 * 24 * 60;

/// Snooze lengths the app-owned alarm implementation can honor.
const List<int> supportedSnoozeMinutes = [5, 10, 15];

/// The user's desired alert preference for one kind, independent of OS
/// permission or scheduling status.
@immutable
class AlertPreference {
  const AlertPreference({
    required this.kind,
    required this.enabled,
    required this.offsetMinutes,
    this.dateOnlyAnchorTime,
    this.dateOnlyAnchorZone,
    this.lockScreenDetails = LockScreenDetails.titleOnly,
    this.presentationPreference = PresentationPreference.standard,
    this.snoozeMinutes,
  });

  final AlertKind kind;
  final bool enabled;

  /// 0 = at the start (or anchor); positive = minutes before.
  final int offsetMinutes;

  /// Required for an enabled alert on a date-only schedule.
  final LocalTime? dateOnlyAnchorTime;
  final String? dateOnlyAnchorZone;
  final LockScreenDetails lockScreenDetails;
  final PresentationPreference presentationPreference;
  final int? snoozeMinutes;

  AlertPreference copyWith({
    bool? enabled,
    int? offsetMinutes,
    LocalTime? Function()? dateOnlyAnchorTime,
    String? Function()? dateOnlyAnchorZone,
    LockScreenDetails? lockScreenDetails,
    PresentationPreference? presentationPreference,
    int? Function()? snoozeMinutes,
  }) =>
      AlertPreference(
        kind: kind,
        enabled: enabled ?? this.enabled,
        offsetMinutes: offsetMinutes ?? this.offsetMinutes,
        dateOnlyAnchorTime: dateOnlyAnchorTime != null ? dateOnlyAnchorTime() : this.dateOnlyAnchorTime,
        dateOnlyAnchorZone: dateOnlyAnchorZone != null ? dateOnlyAnchorZone() : this.dateOnlyAnchorZone,
        lockScreenDetails: lockScreenDetails ?? this.lockScreenDetails,
        presentationPreference: presentationPreference ?? this.presentationPreference,
        snoozeMinutes: snoozeMinutes != null ? snoozeMinutes() : this.snoozeMinutes,
      );

  @override
  bool operator ==(Object other) =>
      other is AlertPreference &&
      other.kind == kind &&
      other.enabled == enabled &&
      other.offsetMinutes == offsetMinutes &&
      other.dateOnlyAnchorTime == dateOnlyAnchorTime &&
      other.dateOnlyAnchorZone == dateOnlyAnchorZone &&
      other.lockScreenDetails == lockScreenDetails &&
      other.presentationPreference == presentationPreference &&
      other.snoozeMinutes == snoozeMinutes;

  @override
  int get hashCode => Object.hash(kind, enabled, offsetMinutes, dateOnlyAnchorTime, dateOnlyAnchorZone,
      lockScreenDetails, presentationPreference, snoozeMinutes);
}

/// A stored desired rule for a whole series.
@immutable
class AlertRule {
  const AlertRule({required this.id, required this.seriesId, required this.preference});

  final String id;
  final String seriesId;
  final AlertPreference preference;

  AlertKind get kind => preference.kind;
}
