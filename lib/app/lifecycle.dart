import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

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

/// Startup and resume work: derived state is refreshed from committed data
/// (spec 11.4). Each step is independent; one failure does not block others.
class AppLifecycleCoordinator {
  AppLifecycleCoordinator(this._ref);

  final Ref _ref;
  final List<Future<void> Function()> _startTasks = [];
  final List<Future<void> Function()> _resumeTasks = [];

  void addStartTask(Future<void> Function() task) => _startTasks.add(task);

  void addResumeTask(Future<void> Function() task) => _resumeTasks.add(task);

  Future<void> onStart() async {
    await _refreshZone();
    for (final task in _startTasks) {
      await _guard(task);
    }
  }

  Future<void> onResume() async {
    await _refreshZone();
    for (final task in _resumeTasks) {
      await _guard(task);
    }
  }

  Future<void> _refreshZone() async {
    final zone = await _ref.read(deviceZoneSourceProvider)();
    if (zone != null) _ref.read(deviceZoneProvider.notifier).set(zone);
  }

  Future<void> _guard(Future<void> Function() task) async {
    try {
      await task();
    } on Object {
      // Derived-state refresh failures surface through their own status UI.
    }
  }
}

final appLifecycleProvider = Provider<AppLifecycleCoordinator>((ref) => AppLifecycleCoordinator(ref));
