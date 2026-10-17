import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/local/database.dart';
import '../../widgets/application/widget_snapshot_service.dart';
import 'alert_planner.dart';
import 'alert_reconciler.dart';
import 'capabilities.dart';

final alertPlannerProvider = Provider<AlertPlanner>(
  (ref) => AlertPlanner(ref.watch(zoneResolverProvider), ref.watch(occurrenceEngineProvider)),
);

final alertReconcilerProvider = Provider<AlertReconciler>((ref) {
  final repo = ref.watch(scheduleRepositoryProvider);
  final db = ref.watch(databaseProvider);
  return AlertReconciler(
    db: db,
    planner: ref.watch(alertPlannerProvider),
    gateway: ref.watch(notificationGatewayProvider),
    bridge: ref.watch(nativeBridgeProvider),
    loadSeries: repo.loadAll,
    loadRules: repo.loadAllAlertRules,
    clock: ref.watch(clockProvider),
    zone: () => ref.read(deviceZoneProvider),
    use24h: () => PlatformDispatcher.instance.alwaysUse24HourFormat,
  );
});

/// Latest reconciliation result for the status surfaces.
final lastReconcileProvider = NotifierProvider<LastReconcileNotifier, ReconcileSummary?>(LastReconcileNotifier.new);

class LastReconcileNotifier extends Notifier<ReconcileSummary?> {
  @override
  ReconcileSummary? build() => null;

  void set(ReconcileSummary summary) => state = summary;
}

/// Actual scheduling rows, for per-occurrence status lines.
final scheduledAlertsProvider = StreamProvider<List<ScheduledAlertRow>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.scheduledAlerts).watch();
});

/// Processes the transactional outbox: after committed changes it refreshes
/// the widget snapshot and reconciles alerts (spec 7.6, 10.3).
class ReconciliationService {
  ReconciliationService(this._ref);

  final Ref _ref;
  StreamSubscription<List<OutboxRow>>? _subscription;
  Timer? _debounce;
  bool _running = false;
  bool _again = false;
  bool _forceNext = false;

  AppDatabase get _db => _ref.read(databaseProvider);

  void start() {
    _subscription ??= (_db.select(_db.reconciliationOutbox)..where((t) => t.status.isIn(['pending', 'retry'])))
        .watch()
        .listen((rows) {
      if (rows.isEmpty) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () => run());
    });
  }

  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
  }

  /// Runs pending work; [force] also runs with an empty outbox (start,
  /// resume, zone or permission changes) to replenish the rolling horizon.
  Future<void> run({bool force = false}) async {
    _forceNext = _forceNext || force;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        final pending = await (_db.select(_db.reconciliationOutbox)..where((t) => t.status.isIn(['pending', 'retry']))).get();
        final forced = _forceNext;
        _forceNext = false;
        if (pending.isEmpty && !forced) break;
        final ids = [for (final p in pending) p.id];
        try {
          await _ref.read(widgetSnapshotServiceProvider).refresh();
          _ref.invalidate(deviceCapabilitiesProvider);
          final caps = await _ref.read(deviceCapabilitiesProvider.future);
          final summary = await _ref.read(alertReconcilerProvider).reconcile(caps);
          _ref.read(lastReconcileProvider.notifier).set(summary);
          if (ids.isNotEmpty) {
            await (_db.delete(_db.reconciliationOutbox)..where((t) => t.id.isIn(ids))).go();
          }
        } on Object {
          if (ids.isNotEmpty) {
            await (_db.update(_db.reconciliationOutbox)..where((t) => t.id.isIn(ids))).write(
              ReconciliationOutboxCompanion(
                status: const Value('retry'),
                attempts: const Value.absent(),
                nextAttemptAt: Value(_ref.read(clockProvider)().toUtc().add(const Duration(minutes: 1))),
              ),
            );
            await _db.customStatement(
              'UPDATE reconciliation_outbox SET attempts = attempts + 1 WHERE id IN (${ids.join(',')})',
            );
          }
          break;
        }
      } while (_again);
    } finally {
      _running = false;
    }
  }
}

final reconciliationServiceProvider = Provider<ReconciliationService>((ref) {
  final service = ReconciliationService(ref);
  ref.onDispose(service.dispose);
  return service;
});
