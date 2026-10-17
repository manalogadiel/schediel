import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/icons.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../integrations/native/native_bridge.dart';
import '../application/capabilities.dart';
import '../domain/alert_rule.dart';

/// Shows the actual permission state for an enabled alert kind, with the one
/// action that can fix it. Shows nothing when everything is allowed.
class CapabilityNote extends ConsumerWidget {
  const CapabilityNote({super.key, required this.kind});

  final AlertKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(deviceCapabilitiesProvider).value;
    if (caps == null) return const SizedBox.shrink();
    final bridge = ref.read(nativeBridgeProvider);

    Future<void> refresh() async => ref.invalidate(deviceCapabilitiesProvider);

    Widget note(String text, {String? action, Future<void> Function()? onAction}) => Padding(
          padding: const EdgeInsets.fromLTRB(Tokens.md, 0, Tokens.md, Tokens.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: DetailLine(icon: AppIcons.warning, text: text)),
              if (action != null)
                TextButton(
                  onPressed: () async {
                    await onAction!();
                    await refresh();
                  },
                  child: Text(action),
                ),
            ],
          ),
        );

    if (kind == AlertKind.notification) {
      return switch (caps.notifications) {
        CapabilityStatus.authorized || CapabilityStatus.notRequired => const SizedBox.shrink(),
        CapabilityStatus.notDetermined => note(
            'Notifications need permission',
            action: 'Allow',
            onAction: () => ref.read(notificationGatewayProvider).requestPermission(),
          ),
        CapabilityStatus.denied => note(
            'Notifications are off',
            action: 'Settings',
            onAction: () => bridge.openSystemSettings(SettingsTarget.notifications),
          ),
        CapabilityStatus.unavailable => note('Notifications are not available on this device'),
      };
    }

    final native = caps.native;
    if (native.appAlarms == CapabilityStatus.unavailable) {
      return note('Alarms are not available on this device. Notification reminders still work.');
    }
    if (native.appAlarms == CapabilityStatus.notDetermined) {
      return note('Alarm permission needed', action: 'Allow', onAction: bridge.requestAppAlarmAuthorization);
    }
    if (native.appAlarms == CapabilityStatus.denied) {
      return note(
        'Alarm permission needed',
        action: 'Settings',
        onAction: () => bridge.openSystemSettings(
          native.platform == 'android' ? SettingsTarget.exactAlarms : SettingsTarget.app,
        ),
      );
    }
    if (native.platform == 'android' && caps.notifications == CapabilityStatus.denied) {
      return note(
        'Notifications are off, so alarms cannot show',
        action: 'Settings',
        onAction: () => bridge.openSystemSettings(SettingsTarget.notifications),
      );
    }
    return const SizedBox.shrink();
  }
}
