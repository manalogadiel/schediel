import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Capability values from the native bridge (contracts/native-bridge-v1.md).
enum CapabilityStatus { authorized, denied, notDetermined, notRequired, unavailable }

CapabilityStatus _status(Object? value) => switch (value) {
      'authorized' => CapabilityStatus.authorized,
      'denied' => CapabilityStatus.denied,
      'notDetermined' => CapabilityStatus.notDetermined,
      'notRequired' => CapabilityStatus.notRequired,
      _ => CapabilityStatus.unavailable,
    };

@immutable
class NativeCapabilities {
  const NativeCapabilities({
    required this.platform,
    required this.osVersion,
    required this.apiLevel,
    required this.exactAlarms,
    required this.appAlarms,
    required this.fullScreen,
    required this.externalClock,
  });

  factory NativeCapabilities.fromMap(Map<Object?, Object?> map) => NativeCapabilities(
        platform: map['platform'] as String? ?? 'unknown',
        osVersion: map['osVersion'] as String? ?? '',
        apiLevel: (map['apiLevel'] as num?)?.toInt(),
        exactAlarms: _status(map['exactAlarms']),
        appAlarms: _status(map['appAlarms']),
        fullScreen: _status(map['fullScreen']),
        externalClock: map['externalClock'] == true,
      );

  /// Used when the native side is absent (tests, unsupported hosts).
  static const unavailable = NativeCapabilities(
    platform: 'unknown',
    osVersion: '',
    apiLevel: null,
    exactAlarms: CapabilityStatus.unavailable,
    appAlarms: CapabilityStatus.unavailable,
    fullScreen: CapabilityStatus.unavailable,
    externalClock: false,
  );

  final String platform;
  final String osVersion;
  final int? apiLevel;
  final CapabilityStatus exactAlarms;
  final CapabilityStatus appAlarms;
  final CapabilityStatus fullScreen;
  final bool externalClock;

  bool get alarmsAvailable => appAlarms != CapabilityStatus.unavailable;
}

@immutable
class AlarmRequest {
  const AlarmRequest({
    required this.requestKey,
    required this.triggerAt,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.snoozeMinutes,
    required this.prominent,
  });

  final String requestKey;
  final DateTime triggerAt;
  final String title;
  final String body;
  final String deepLink;
  final int? snoozeMinutes;
  final bool prominent;

  Map<String, Object?> toMap() => {
        'requestKey': requestKey,
        'triggerAtEpochMs': triggerAt.toUtc().millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'deepLink': deepLink,
        'snoozeMinutes': snoozeMinutes,
        'prominent': prominent,
      };
}

enum AlarmResultStatus { scheduled, needsPermission, pastTrigger, failed }

@immutable
class AlarmResult {
  const AlarmResult(this.requestKey, this.status, this.errorCode);

  final String requestKey;
  final AlarmResultStatus status;
  final String? errorCode;

  factory AlarmResult.fromMap(Map<Object?, Object?> map) => AlarmResult(
        map['requestKey'] as String,
        AlarmResultStatus.values.firstWhere((s) => s.name == map['status'], orElse: () => AlarmResultStatus.failed),
        map['errorCode'] as String?,
      );
}

enum ClockLaunchResult { launched, unavailable, failed }

enum SettingsTarget { exactAlarms, fullScreen, notifications, app }

/// Dart side of the native bridge. Expected states never throw; a missing
/// native implementation reports capabilities as unavailable.
class NativeBridge {
  NativeBridge([MethodChannel? channel]) : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.manalogadiel.schediel/native';

  final MethodChannel _channel;

  Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    }
  }

  Future<NativeCapabilities> getCapabilities() async {
    final map = await _call<Map<Object?, Object?>>('getCapabilities');
    return map == null ? NativeCapabilities.unavailable : NativeCapabilities.fromMap(map);
  }

  Future<CapabilityStatus> requestAppAlarmAuthorization() async =>
      _status(await _call<String>('requestAppAlarmAuthorization'));

  Future<bool> openSystemSettings(SettingsTarget target) async =>
      await _call<bool>('openSystemSettings', {'target': target.name}) ?? false;

  /// Replace-all: afterwards native holds exactly [alarms].
  Future<List<AlarmResult>> scheduleAlarms(List<AlarmRequest> alarms, DateTime horizonEnd) async {
    final result = await _call<List<Object?>>('scheduleAlarms', {
      'alarms': [for (final a in alarms) a.toMap()],
      'horizonEndEpochMs': horizonEnd.toUtc().millisecondsSinceEpoch,
    });
    if (result == null) {
      return [for (final a in alarms) AlarmResult(a.requestKey, AlarmResultStatus.failed, 'unavailable')];
    }
    return [for (final r in result) AlarmResult.fromMap(r as Map<Object?, Object?>)];
  }

  Future<int> cancelAllAlarms() async => await _call<int>('cancelAllAlarms') ?? 0;

  Future<List<String>> getScheduledAlarms() async =>
      (await _call<List<Object?>>('getScheduledAlarms'))?.cast<String>() ?? const [];

  Future<ClockLaunchResult> launchClockAlarm({
    required int hour,
    required int minute,
    required String message,
    List<int>? weekdays,
  }) async {
    final result = await _call<String>('launchClockAlarm', {
      'hour': hour,
      'minute': minute,
      'message': message,
      'weekdays': weekdays,
    });
    return switch (result) {
      'launched' => ClockLaunchResult.launched,
      'failed' => ClockLaunchResult.failed,
      _ => ClockLaunchResult.unavailable,
    };
  }
}
