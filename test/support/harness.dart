import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/app/app.dart';
import 'package:schediel/app/lifecycle.dart';
import 'package:schediel/app/providers.dart';
import 'package:schediel/app/router.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/appearance/appearance.dart';
import 'package:schediel/features/reminders/application/capabilities.dart';
import 'package:schediel/features/reminders/data/notification_gateway.dart';
import 'package:schediel/integrations/native/native_bridge.dart';

/// Records requests instead of talking to the OS.
class FakeNotificationGateway implements NotificationGateway {
  CapabilityStatus status = CapabilityStatus.authorized;
  final Map<int, NotificationRequest> scheduled = {};

  @override
  Future<void> initialize({void Function(String payload)? onOpen}) async {}

  @override
  Future<CapabilityStatus> permissionStatus() async => status;

  @override
  Future<CapabilityStatus> requestPermission() async => status = CapabilityStatus.authorized;

  @override
  Future<bool> schedule(NotificationRequest request, {bool exact = false}) async {
    if (status != CapabilityStatus.authorized) return false;
    scheduled[request.id] = request;
    return true;
  }

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<Set<int>> pendingIds() async => scheduled.keys.toSet();

  @override
  Future<String?> launchPayload() async => null;
}

/// A clock that never schedules timers, so tests stay deterministic.
class FixedNow extends NowNotifier {
  FixedNow(this.value);
  final DateTime value;

  @override
  DateTime build() => value;

  @override
  void refresh() {}
}

class TestHarness {
  TestHarness(this.tester, this.db, this.container);

  final WidgetTester tester;
  final AppDatabase db;
  final ProviderContainer container;

  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  /// Runs an async operation inside the fake-async test zone by pumping
  /// until it completes.
  Future<T> run<T>(Future<T> Function() op) async {
    var done = false;
    T? result;
    Object? error;
    StackTrace? stack;
    op().then((v) {
      result = v;
      done = true;
    }, onError: (Object e, StackTrace s) {
      error = e;
      stack = s;
      done = true;
    });
    for (var i = 0; i < 400 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    if (!done) throw StateError('Operation did not complete');
    if (error != null) Error.throwWithStackTrace(error!, stack!);
    return result as T;
  }

  Future<void> settle() async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();
  }

  /// Taps visible text. Unselected navigation destinations show only an
  /// icon, so their names fall back to the destination's key.
  Future<void> tapText(String text) async {
    final visible = find.text(text);
    final nav = find.byKey(ValueKey('nav-${text.toLowerCase()}'));
    await tester.tap(visible.evaluate().isEmpty && nav.evaluate().isNotEmpty ? nav : visible.last);
    await settle();
  }
}

/// A widget test of the whole app on an in-memory database with an injected
/// clock and zone. Cleans up the tree, providers and database afterwards.
void appTest(
  String description,
  Future<void> Function(TestHarness h) body, {
  DateTime? now,
  String zone = 'Asia/Manila',
  List<Override> overrides = const [],
  NativeBridge? bridge,
  NotificationGateway? gateway,
  Size size = const Size(400, 860),
}) {
  testWidgets(description, (tester) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    final fixed = now ?? DateTime.utc(2026, 11, 2, 0, 30);
    final db = AppDatabase(NativeDatabase.memory(), clock: () => fixed);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => fixed),
      nowProvider.overrideWith(() => FixedNow(fixed)),
      zoneResolverProvider.overrideWithValue(ZoneResolver.initialized()),
      initialDeviceZoneProvider.overrideWithValue(zone),
      deviceZoneSourceProvider.overrideWithValue(() async => zone),
      appearanceRepositoryProvider.overrideWithValue(AppearanceRepository(db, clock: () => fixed)),
      notificationGatewayProvider.overrideWithValue(gateway ?? FakeNotificationGateway()),
      nativeBridgeProvider.overrideWithValue(bridge ?? NativeBridge()),
      routerProvider.overrideWith((ref) => buildRouter()),
      ...overrides,
    ]);
    final h = TestHarness(tester, db, container);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SchedielApp()));
    await h.settle();
    try {
      await body(h);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await h.run(db.close);
      await tester.pump(const Duration(seconds: 5));
      tester.view.resetPhysicalSize();
    }
  });
}

Finder textContaining(String s) => find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains(s));
