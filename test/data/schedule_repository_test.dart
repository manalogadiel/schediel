import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/schedule/validation.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/categories/data/category_repository.dart';
import 'package:schediel/features/categories/domain/category.dart';
import 'package:schediel/features/reminders/domain/alert_rule.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';

void main() {
  late AppDatabase db;
  late ScheduleRepository schedules;
  late CategoryRepository categories;
  var idCounter = 0;
  final now = DateTime.utc(2026, 10, 30, 2);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    final zones = ZoneResolver.initialized();
    final engine = OccurrenceEngine(zones);
    db = AppDatabase(NativeDatabase.memory(), clock: () => now);
    String newId() => '00000000-0000-4000-8000-${(++idCounter).toString().padLeft(12, '0')}';
    schedules = ScheduleRepository(db, validator: SeriesValidator(zones, engine), engine: engine, clock: () => now, newId: newId);
    categories = CategoryRepository(db, clock: () => now, newId: newId);
  });

  tearDown(() => db.close());

  ScheduleDraft weeklyDraft({String title = 'Fixture class', String? categoryId = 'school'}) => ScheduleDraft(
        title: title,
        categoryId: categoryId,
        time: TimedSpec(
          startDate: LocalDate(2026, 11, 2),
          startTime: LocalTime(9, 0),
          timeZone: 'Asia/Manila',
          endTime: LocalTime(10, 30),
          endDayOffset: 0,
        ),
        recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [1, 3]),
        details: const ScheduleDetails(location: 'Fixture room', professor: 'Fixture person'),
      );

  test('a fresh database has the built-in categories and no schedules', () async {
    final all = await categories.watchAll().first;
    expect(all.map((c) => c.name), ['School', 'Work', 'Personal']);
    expect(all.every((c) => c.builtIn), isTrue);
    expect(await schedules.loadAll(), isEmpty);
  });

  test('creates a series with its alert rules and reconciliation work in one transaction', () async {
    final id = await schedules.create(
      weeklyDraft(),
      alerts: const [AlertPreference(kind: AlertKind.notification, enabled: true, offsetMinutes: 10)],
    );
    final saved = await schedules.load(id);
    expect(saved!.title, 'Fixture class');
    expect(saved.revision, 1);
    expect(saved.details.location, 'Fixture room');
    expect(saved.recurrence!.weekdays, [1, 3]);
    expect((saved.time as TimedSpec).endTime, LocalTime(10, 30));
    final rules = await schedules.alertRules(id);
    expect(rules.single.preference.offsetMinutes, 10);
    expect(await db.dataRevision(), 1);
    final outbox = await db.select(db.reconciliationOutbox).get();
    expect(outbox.single.status, 'pending');
    expect(outbox.single.sourceRevision, 1);
  });

  test('rejects an invalid draft without writing anything', () async {
    await expectLater(
      schedules.create(weeklyDraft(title: '')),
      throwsA(isA<ScheduleValidationException>()),
    );
    expect(await schedules.loadAll(), isEmpty);
    expect(await db.dataRevision(), 0);
  });

  test('editing the entire series increments its revision and keeps valid exceptions', () async {
    final id = await schedules.create(weeklyDraft());
    await schedules.cancelOccurrence(id, LocalDate(2026, 11, 4));
    await schedules.updateSeries(id, weeklyDraft(title: 'Fixture class renamed'));
    final saved = await schedules.load(id);
    expect(saved!.title, 'Fixture class renamed');
    expect(saved.revision, 3);
    expect(saved.exceptions.single.originalKey, LocalDate(2026, 11, 4));
  });

  test('a rule change that invalidates exceptions requires an explicit choice', () async {
    final id = await schedules.create(weeklyDraft());
    final moved = OccurrenceReplacement(
      title: 'Fixture class moved',
      time: TimedSpec(
        startDate: LocalDate(2026, 11, 5),
        startTime: LocalTime(13, 0),
        timeZone: 'Asia/Manila',
        endTime: LocalTime(14, 0),
        endDayOffset: 0,
      ),
      details: ScheduleDetails.empty,
    );
    await schedules.overrideOccurrence(id, LocalDate(2026, 11, 4), moved);
    await schedules.cancelOccurrence(id, LocalDate(2026, 11, 9));
    final tuesdays = weeklyDraft().copyWith(
      recurrence: () => RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [2]),
    );

    final current = await schedules.load(id);
    expect(schedules.invalidatedExceptions(current!, tuesdays).map((e) => e.originalKey.toIso()), ['2026-11-04', '2026-11-09']);
    await expectLater(schedules.updateSeries(id, tuesdays), throwsA(isA<ExceptionsNeedDecision>()));

    await schedules.updateSeries(id, tuesdays, onInvalidExceptions: InvalidExceptionChoice.keepChangesAsOneTime);
    final all = await schedules.loadAll();
    expect(all, hasLength(2));
    final series = all.firstWhere((s) => s.id == id);
    expect(series.exceptions, isEmpty);
    final oneTime = all.firstWhere((s) => s.id != id);
    expect(oneTime.title, 'Fixture class moved');
    expect(oneTime.recurrence, isNull);
    expect(oneTime.categoryId, 'school');
    expect(oneTime.time.startDate, LocalDate(2026, 11, 5));
  });

  test('discarding invalidated exceptions is possible only when chosen', () async {
    final id = await schedules.create(weeklyDraft());
    await schedules.cancelOccurrence(id, LocalDate(2026, 11, 9));
    final daily = weeklyDraft().copyWith(
      recurrence: () => RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [5]),
    );
    await schedules.updateSeries(id, daily, onInvalidExceptions: InvalidExceptionChoice.discard);
    expect((await schedules.load(id))!.exceptions, isEmpty);
    expect(await schedules.loadAll(), hasLength(1));
  });

  test('restoring an occurrence removes its exception', () async {
    final id = await schedules.create(weeklyDraft());
    await schedules.cancelOccurrence(id, LocalDate(2026, 11, 4));
    await schedules.restoreOccurrence(id, LocalDate(2026, 11, 4));
    expect((await schedules.load(id))!.exceptions, isEmpty);
  });

  test('cancelling a date that is not an original occurrence is rejected', () async {
    final id = await schedules.create(weeklyDraft());
    await expectLater(schedules.cancelOccurrence(id, LocalDate(2026, 11, 5)), throwsA(isA<ScheduleValidationException>()));
  });

  test('deleting a series removes its exceptions and alert rules', () async {
    final id = await schedules.create(
      weeklyDraft(),
      alerts: const [AlertPreference(kind: AlertKind.alarm, enabled: true, offsetMinutes: 0)],
    );
    await schedules.cancelOccurrence(id, LocalDate(2026, 11, 4));
    await schedules.deleteSeries(id);
    expect(await schedules.load(id), isNull);
    expect(await db.select(db.occurrenceExceptions).get(), isEmpty);
    expect(await db.select(db.alertRules).get(), isEmpty);
  });

  test('replacing alert preferences keeps one rule per kind', () async {
    final id = await schedules.create(weeklyDraft());
    await schedules.updateSeries(
      id,
      weeklyDraft(),
      alerts: const [
        AlertPreference(kind: AlertKind.notification, enabled: true, offsetMinutes: 15),
        AlertPreference(kind: AlertKind.alarm, enabled: false, offsetMinutes: 5),
      ],
    );
    await schedules.updateSeries(
      id,
      weeklyDraft(),
      alerts: const [AlertPreference(kind: AlertKind.notification, enabled: true, offsetMinutes: 30)],
    );
    final rules = await schedules.alertRules(id);
    expect(rules, hasLength(1));
    expect(rules.single.preference.offsetMinutes, 30);
  });

  group('categories', () {
    test('creates, renames and reorders custom categories with unique names', () async {
      final lab = await categories.create('Lab');
      await expectLater(categories.create(' lab '), throwsA(isA<CategoryNameException>()));
      await expectLater(categories.create(''), throwsA(isA<CategoryNameException>()));
      await categories.rename(lab.id, 'Lab work');
      final names = (await categories.watchAll().first).map((c) => c.name);
      expect(names, ['School', 'Work', 'Personal', 'Lab work']);
    });

    test('deleting a category moves its schedules to the chosen destination', () async {
      final id = await schedules.create(weeklyDraft(categoryId: 'work'));
      await categories.delete('work', reassignTo: 'personal');
      expect((await schedules.load(id))!.categoryId, 'personal');
      final other = await schedules.create(weeklyDraft(categoryId: 'personal'));
      await categories.delete('personal');
      expect((await schedules.load(other))!.categoryId, isNull);
      expect((await categories.watchAll().first).map((c) => c.id), ['school']);
    });

    test('filters use OR semantics and All includes Uncategorized', () {
      const all = CategoryFilter.all();
      expect(all.matches(null), isTrue);
      const schoolOrWork = CategoryFilter.only({'school', 'work'});
      expect(schoolOrWork.matches('school'), isTrue);
      expect(schoolOrWork.matches('personal'), isFalse);
      expect(schoolOrWork.matches(null), isFalse);
      expect(CategoryFilter.fromJson(schoolOrWork.toJson()), schoolOrWork);
      expect(CategoryFilter.fromJson(null), all);
      expect(const CategoryFilter.only({'gone'}).retainExisting(['school']), all);
    });
  });
}
