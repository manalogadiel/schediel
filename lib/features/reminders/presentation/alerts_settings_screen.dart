import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/icons.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/common.dart';
import '../../../core/time/local_date.dart';
import '../../../integrations/native/native_bridge.dart';
import '../application/alert_reconciler.dart';
import '../application/capabilities.dart';
import '../application/reconciliation_service.dart';
import '../domain/alert_rule.dart';

/// Truthful alert status (spec 7.5, 12.1): device permissions, what is
/// actually scheduled, and what needs attention.
class AlertsSettingsScreen extends ConsumerWidget {
  const AlertsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(deviceCapabilitiesProvider);
    final rows = ref.watch(scheduledAlertsProvider).value ?? const [];
    final bridge = ref.read(nativeBridgeProvider);
    final f = Formats.of(context);
    final text = Theme.of(context).textTheme;
    final zones = ref.watch(zoneResolverProviderForAlerts);

    int countOf(AlertKind kind, String status) => rows.where((r) => r.kind == kind.name && r.status == status).length;
    DateTime? coverage(AlertKind kind) {
      DateTime? last;
      for (final r in rows) {
        if (r.kind == kind.name && r.status == AlertStatus.scheduled && (last == null || r.triggerAt.isAfter(last))) {
          last = r.triggerAt;
        }
      }
      return last;
    }

    String statusLabel(CapabilityStatus s) => switch (s) {
          CapabilityStatus.authorized => 'Allowed',
          CapabilityStatus.notRequired => 'Not required',
          CapabilityStatus.denied => 'Not allowed',
          CapabilityStatus.notDetermined => 'Not asked yet',
          CapabilityStatus.unavailable => 'Not available',
        };

    Widget kindSection(AlertKind kind, String title) {
      final scheduled = countOf(kind, AlertStatus.scheduled);
      final permission = countOf(kind, AlertStatus.needsPermission);
      final failed = countOf(kind, AlertStatus.failed);
      final capacity = countOf(kind, AlertStatus.unscheduledCapacity);
      final blocked = countOf(kind, AlertStatus.blocked);
      final end = coverage(kind);
      final lines = <Widget>[
        ListTile(title: Text('Scheduled'), trailing: Text('$scheduled')),
        if (end != null)
          ListTile(
            title: const Text('Scheduled through'),
            trailing: Text(f.fullDate(zones(end))),
          ),
        if (permission > 0) ListTile(title: const Text('Waiting for permission'), trailing: Text('$permission')),
        if (failed > 0) ListTile(title: const Text('Could not be scheduled'), trailing: Text('$failed')),
        if (blocked > 0) ListTile(title: const Text('Not available on this device'), trailing: Text('$blocked')),
        if (capacity > 0)
          ListTile(
            title: const Text('Scheduled later'),
            subtitle: const Text('Added automatically as their dates get closer while you use the app'),
            trailing: Text('$capacity'),
          ),
      ];
      return SectionGroup(header: title, children: lines);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders and alarms')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Tokens.md, Tokens.sm, Tokens.md, Tokens.xxl),
        children: [
          caps.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Tokens.lg),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (_, _) => const EmptyState(title: 'Unable to read device permissions'),
            data: (c) => SectionGroup(
              header: 'This device',
              children: [
                ListTile(
                  leading: const AppIcon(AppIcons.notification),
                  title: const Text('Notifications'),
                  subtitle: Text(statusLabel(c.notifications)),
                  trailing: c.notifications == CapabilityStatus.notDetermined
                      ? TextButton(
                          onPressed: () async {
                            await ref.read(notificationGatewayProvider).requestPermission();
                            ref.invalidate(deviceCapabilitiesProvider);
                            await ref.read(reconciliationServiceProvider).run(force: true);
                          },
                          child: const Text('Allow'),
                        )
                      : c.notifications == CapabilityStatus.denied
                          ? TextButton(
                              onPressed: () => bridge.openSystemSettings(SettingsTarget.notifications),
                              child: const Text('Settings'),
                            )
                          : null,
                ),
                if (c.native.platform == 'android')
                  ListTile(
                    leading: const AppIcon(AppIcons.time),
                    title: const Text('Exact timing'),
                    subtitle: Text(c.native.exactAlarms == CapabilityStatus.denied
                        ? 'Not allowed. Reminders may arrive late and alarms cannot be set.'
                        : statusLabel(c.native.exactAlarms)),
                    trailing: c.native.exactAlarms == CapabilityStatus.denied
                        ? TextButton(
                            onPressed: () => bridge.openSystemSettings(SettingsTarget.exactAlarms),
                            child: const Text('Settings'),
                          )
                        : null,
                  ),
                ListTile(
                  leading: const AppIcon(AppIcons.alarm),
                  title: const Text('Alarms'),
                  subtitle: Text(switch (c.native.appAlarms) {
                    CapabilityStatus.unavailable => 'Not available on this device. Notification reminders still work.',
                    CapabilityStatus.denied when c.native.platform == 'android' =>
                      'Alarms need notifications and exact timing to be allowed.',
                    final status => statusLabel(status),
                  }),
                  trailing: c.native.appAlarms == CapabilityStatus.notDetermined
                      ? TextButton(
                          onPressed: () async {
                            await bridge.requestAppAlarmAuthorization();
                            ref.invalidate(deviceCapabilitiesProvider);
                            await ref.read(reconciliationServiceProvider).run(force: true);
                          },
                          child: const Text('Allow'),
                        )
                      : null,
                ),
                if (c.native.platform == 'android')
                  ListTile(
                    leading: const AppIcon(AppIcons.widget),
                    title: const Text('Full-screen alarms'),
                    subtitle: Text(c.native.fullScreen == CapabilityStatus.denied
                        ? 'Not allowed. Alarms show as notifications.'
                        : statusLabel(c.native.fullScreen)),
                    trailing: c.native.fullScreen == CapabilityStatus.denied
                        ? TextButton(
                            onPressed: () => bridge.openSystemSettings(SettingsTarget.fullScreen),
                            child: const Text('Settings'),
                          )
                        : null,
                  ),
              ],
            ),
          ),
          kindSection(AlertKind.notification, 'Notifications'),
          kindSection(AlertKind.alarm, 'Alarms'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.xs),
            child: Text(
              'Scheduled means the system accepted the request. Focus modes, battery settings and the device '
              'can still delay or silence it. Filters never turn reminders or alarms off.',
              style: text.bodySmall?.copyWith(color: context.scheduleColors.secondaryInk),
            ),
          ),
          const SizedBox(height: Tokens.md),
          OutlinedButton(
            onPressed: () async {
              await ref.read(reconciliationServiceProvider).run(force: true);
              if (context.mounted) showMessage(context, 'Reminders and alarms updated');
            },
            child: const Text('Update now'),
          ),
        ],
      ),
    );
  }
}

/// Converts an instant to the device-local date for labels.
final zoneResolverProviderForAlerts = Provider<LocalDate Function(DateTime)>((ref) {
  final zones = ref.watch(zoneResolverProvider);
  final zone = ref.watch(deviceZoneProvider);
  return (instant) => zones.localDateOf(instant, zone);
});
