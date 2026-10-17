import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../features/reminders/application/capabilities.dart';
import '../features/reminders/application/reconciliation_service.dart';
import 'deep_links.dart';
import 'providers.dart';

/// Reads the device's IANA zone. Replaced in tests.
final deviceZoneSourceProvider = Provider<Future<String?> Function()>((ref) => () async {
      try {
        return (await FlutterTimezone.getLocalTimezone()).identifier;
      } on PlatformException {
        return null;
      } on MissingPluginException {
        return null;
      }
    });

/// Startup and resume work: derived state (alerts, widget snapshot) is
/// refreshed from committed data (spec 11.4). Steps are independent; one
/// failure does not block the others.
class AppLifecycleCoordinator {
  AppLifecycleCoordinator(this._ref);

  final Ref _ref;
  bool _started = false;

  Future<void> onStart() async {
    if (_started) return;
    _started = true;
    await _refreshZone();
    final links = _ref.read(deepLinkCoordinatorProvider);
    await _guard(() async {
      final gateway = _ref.read(notificationGatewayProvider);
      await gateway.initialize(onOpen: (payload) => links.handle(Uri.parse(payload)));
      final launch = await gateway.launchPayload();
      if (launch != null) links.handle(Uri.parse(launch));
    });
    await _guard(links.start);
    final reconciliation = _ref.read(reconciliationServiceProvider);
    reconciliation.start();
    await _guard(() => reconciliation.run(force: true));
  }

  Future<void> onResume() async {
    await _refreshZone();
    _ref.invalidate(deviceCapabilitiesProvider);
    await _guard(() => _ref.read(reconciliationServiceProvider).run(force: true));
  }

  Future<void> _refreshZone() async {
    final zone = await _ref.read(deviceZoneSourceProvider)();
    if (zone != null) _ref.read(deviceZoneProvider.notifier).set(zone);
  }

  Future<void> _guard(Future<void> Function() task) async {
    try {
      await task();
    } on Object {
      // Derived-state failures surface through their own status screens.
    }
  }
}

final appLifecycleProvider = Provider<AppLifecycleCoordinator>((ref) => AppLifecycleCoordinator(ref));
