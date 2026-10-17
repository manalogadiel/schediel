import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../integrations/native/native_bridge.dart';

/// One reminder notification request derived from a desired rule.
@immutable
class NotificationRequest {
  const NotificationRequest({
    required this.id,
    required this.requestKey,
    required this.triggerAt,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String requestKey;
  final DateTime triggerAt;
  final String title;
  final String body;

  /// The occurrence deep link opened from the notification.
  final String payload;
}

/// Adapter over flutter_local_notifications (spec 11.3 NotificationScheduler).
/// Only accepted requests are reported as scheduled.
abstract class NotificationGateway {
  Future<void> initialize({void Function(String payload)? onOpen});
  Future<CapabilityStatus> permissionStatus();
  Future<CapabilityStatus> requestPermission();
  /// [exact] only when exact scheduling is authorized; otherwise the OS may
  /// deliver late.
  Future<bool> schedule(NotificationRequest request, {bool exact = false});
  Future<void> cancel(int id);
  Future<Set<int>> pendingIds();
  Future<String?> launchPayload();
}

class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'schediel_reminders';
  static const channelName = 'Schedule reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<void> initialize({void Function(String payload)? onOpen}) async {
    if (!_supported || _ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) onOpen?.call(payload);
        },
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            channelId,
            channelName,
            description: 'Reminders you turned on for schedules',
            importance: Importance.high,
          ));
      _ready = true;
    } on PlatformException {
      _ready = false;
    } on MissingPluginException {
      _ready = false;
    }
  }

  @override
  Future<CapabilityStatus> permissionStatus() async {
    if (!_supported) return CapabilityStatus.unavailable;
    try {
      if (Platform.isAndroid) {
        final enabled = await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
        return enabled == true ? CapabilityStatus.authorized : CapabilityStatus.denied;
      }
      final options = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      if (options == null) return CapabilityStatus.notDetermined;
      return options.isEnabled ? CapabilityStatus.authorized : CapabilityStatus.notDetermined;
    } on MissingPluginException {
      return CapabilityStatus.unavailable;
    }
  }

  @override
  Future<CapabilityStatus> requestPermission() async {
    if (!_supported) return CapabilityStatus.unavailable;
    try {
      bool? granted;
      if (Platform.isAndroid) {
        granted = await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else {
        granted = await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: false, sound: true);
      }
      return granted == true ? CapabilityStatus.authorized : CapabilityStatus.denied;
    } on MissingPluginException {
      return CapabilityStatus.unavailable;
    }
  }

  @override
  Future<bool> schedule(NotificationRequest request, {bool exact = false}) async {
    if (!_ready) return false;
    try {
      await _plugin.zonedSchedule(
        id: request.id,
        scheduledDate: tz.TZDateTime.from(request.triggerAt.toUtc(), tz.UTC),
        title: request.title,
        body: request.body.isEmpty ? null : request.body,
        payload: request.payload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.private,
          ),
          iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
        ),
        androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } on PlatformException {
      return false;
    } on ArgumentError {
      return false;
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id: id);
  }

  @override
  Future<Set<int>> pendingIds() async {
    if (!_ready) return {};
    final pending = await _plugin.pendingNotificationRequests();
    return {for (final p in pending) p.id};
  }

  @override
  Future<String?> launchPayload() async {
    if (!_ready) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }
}
