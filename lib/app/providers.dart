import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/schedule/models.dart';
import '../core/schedule/occurrence_engine.dart';
import '../core/schedule/validation.dart';
import '../core/time/local_date.dart';
import '../core/time/zone_resolver.dart';
import '../data/local/database.dart';
import '../features/categories/data/category_repository.dart';
import '../features/categories/domain/category.dart';
import '../features/reminders/domain/alert_rule.dart';
import '../features/schedules/application/day_view.dart';
import '../features/schedules/application/occurrence_lookup.dart';
import '../features/schedules/data/schedule_repository.dart';

/// Opened in main.dart; tests provide an in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Provided in main.dart'));

/// Injected clock. Tests replace it; nothing reads DateTime.now directly.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final zoneResolverProvider = Provider<ZoneResolver>((ref) => ZoneResolver.initialized());

final occurrenceEngineProvider = Provider<OccurrenceEngine>((ref) => OccurrenceEngine(ref.watch(zoneResolverProvider)));

final seriesValidatorProvider = Provider<SeriesValidator>(
  (ref) => SeriesValidator(ref.watch(zoneResolverProvider), ref.watch(occurrenceEngineProvider)),
);

final idGeneratorProvider = Provider<String Function()>((ref) {
  const uuid = Uuid();
  return uuid.v4;
});

final dayViewBuilderProvider = Provider<DayViewBuilder>(
  (ref) => DayViewBuilder(ref.watch(zoneResolverProvider), ref.watch(occurrenceEngineProvider)),
);

final occurrenceLookupProvider = Provider<OccurrenceLookup>(
  (ref) => OccurrenceLookup(ref.watch(zoneResolverProvider), ref.watch(occurrenceEngineProvider)),
);

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(
    ref.watch(databaseProvider),
    validator: ref.watch(seriesValidatorProvider),
    engine: ref.watch(occurrenceEngineProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final allSeriesProvider = StreamProvider<List<ScheduleSeries>>((ref) => ref.watch(scheduleRepositoryProvider).watchAll());

final categoriesProvider = StreamProvider<List<Category>>((ref) => ref.watch(categoryRepositoryProvider).watchAll());

final alertRulesProvider = StreamProvider<List<AlertRule>>(
  (ref) => ref.watch(scheduleRepositoryProvider).watchAllAlertRules(),
);

/// Device IANA zone read at startup (main.dart) and refreshed on resume.
final initialDeviceZoneProvider = Provider<String>((ref) => 'UTC');

final deviceZoneProvider = NotifierProvider<DeviceZoneNotifier, String>(DeviceZoneNotifier.new);

class DeviceZoneNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(initialDeviceZoneProvider);

  void set(String zone) {
    if (zone != state && ref.read(zoneResolverProvider).isValidZone(zone)) state = zone;
  }
}

/// The current time, advanced at each minute boundary while the app runs and
/// on resume. Never used for background work.
final nowProvider = NotifierProvider<NowNotifier, DateTime>(NowNotifier.new);

class NowNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    final now = ref.watch(clockProvider)();
    _schedule(now);
    return now;
  }

  void refresh() {
    final now = ref.read(clockProvider)();
    state = now;
    _schedule(now);
  }

  /// Zone-independent: minute boundaries are the same instant everywhere.
  void _schedule(DateTime now) {
    _timer?.cancel();
    final ms = now.millisecondsSinceEpoch;
    final nextMinute = (ms ~/ Duration.millisecondsPerMinute + 1) * Duration.millisecondsPerMinute;
    _timer = Timer(Duration(milliseconds: nextMinute - ms + 50), refresh);
  }
}

final todayProvider = Provider<LocalDate>((ref) {
  final zones = ref.watch(zoneResolverProvider);
  return zones.localDateOf(ref.watch(nowProvider), ref.watch(deviceZoneProvider));
});

/// The date shown on Today; null follows the current day.
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, LocalDate?>(SelectedDateNotifier.new);

class SelectedDateNotifier extends Notifier<LocalDate?> {
  @override
  LocalDate? build() => null;

  void select(LocalDate date) => state = date == ref.read(todayProvider) ? null : date;

  void today() => state = null;
}

final effectiveDateProvider = Provider<LocalDate>((ref) => ref.watch(selectedDateProvider) ?? ref.watch(todayProvider));

/// The schedule-view category filter, shared by Today and Week and persisted.
final initialAppFilterProvider = Provider<CategoryFilter>((ref) => const CategoryFilter.all());

final appFilterProvider = NotifierProvider<AppFilterNotifier, CategoryFilter>(AppFilterNotifier.new);

class AppFilterNotifier extends Notifier<CategoryFilter> {
  static const storageKey = 'appFilter';

  @override
  CategoryFilter build() => ref.watch(initialAppFilterProvider);

  Future<void> set(CategoryFilter filter) async {
    state = filter;
    await ref.read(databaseProvider).writeValue(storageKey, jsonEncode(filter.toJson()));
  }
}

/// The filter actually applied: ids of deleted categories are ignored.
final effectiveFilterProvider = Provider<CategoryFilter>((ref) {
  final filter = ref.watch(appFilterProvider);
  final categories = ref.watch(categoriesProvider).value;
  if (categories == null) return filter;
  return filter.retainExisting(categories.map((c) => c.id));
});

final dayViewProvider = Provider.family<AsyncValue<DayView>, LocalDate>((ref, date) {
  final seriesAsync = ref.watch(allSeriesProvider);
  final filter = ref.watch(effectiveFilterProvider);
  final now = ref.watch(nowProvider);
  final zone = ref.watch(deviceZoneProvider);
  final today = ref.watch(todayProvider);
  final builder = ref.watch(dayViewBuilderProvider);
  return seriesAsync.whenData(
    (series) => builder.build(series: series, filter: filter, date: date, today: today, now: now, zone: zone),
  );
});

final weekViewProvider = Provider.family<AsyncValue<WeekView>, LocalDate>((ref, weekStart) {
  final seriesAsync = ref.watch(allSeriesProvider);
  final filter = ref.watch(effectiveFilterProvider);
  final now = ref.watch(nowProvider);
  final zone = ref.watch(deviceZoneProvider);
  final today = ref.watch(todayProvider);
  final builder = ref.watch(dayViewBuilderProvider);
  return seriesAsync.whenData(
    (series) => builder.buildWeek(series: series, filter: filter, weekStart: weekStart, today: today, now: now, zone: zone),
  );
});

final seriesByIdProvider = Provider.family<AsyncValue<ScheduleSeries?>, String>((ref, id) {
  return ref.watch(allSeriesProvider).whenData((all) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  });
});

final categoryByIdProvider = Provider.family<Category?, String?>((ref, id) {
  if (id == null) return null;
  final all = ref.watch(categoriesProvider).value ?? const [];
  for (final c in all) {
    if (c.id == id) return c;
  }
  return null;
});
