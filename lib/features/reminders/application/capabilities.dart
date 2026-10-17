import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../integrations/native/native_bridge.dart';
import '../data/notification_gateway.dart';

/// What the device actually allows right now (spec 12.1). A toggle in the
/// app is a preference; this is the authorization state.
@immutable
class DeviceCapabilities {
  const DeviceCapabilities({required this.notifications, required this.native});

  static const unknown = DeviceCapabilities(
    notifications: CapabilityStatus.unavailable,
    native: NativeCapabilities.unavailable,
  );

  final CapabilityStatus notifications;
  final NativeCapabilities native;

  bool get notificationsAuthorized => notifications == CapabilityStatus.authorized;

  bool get exactAuthorized =>
      native.exactAlarms == CapabilityStatus.authorized || native.exactAlarms == CapabilityStatus.notRequired;

  bool get alarmsAuthorized => native.appAlarms == CapabilityStatus.authorized;
}

final nativeBridgeProvider = Provider<NativeBridge>((ref) => NativeBridge());

final notificationGatewayProvider = Provider<NotificationGateway>((ref) => LocalNotificationGateway());

/// Re-read on resume and after permission prompts.
final deviceCapabilitiesProvider = FutureProvider<DeviceCapabilities>((ref) async {
  final gateway = ref.watch(notificationGatewayProvider);
  final bridge = ref.watch(nativeBridgeProvider);
  final results = await Future.wait([gateway.permissionStatus(), bridge.getCapabilities()]);
  return DeviceCapabilities(
    notifications: results[0] as CapabilityStatus,
    native: results[1] as NativeCapabilities,
  );
});
