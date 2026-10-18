import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/schedule/validation.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/data/local/database.dart';
import 'package:schediel/features/imports/data/import_repository.dart';
import 'package:schediel/features/imports/domain/import_entry.dart';
import 'package:schediel/features/schedules/data/schedule_repository.dart';

void main() {
  final now = DateTime.utc(2026, 11, 2);
  late AppDatabase db;
  late ScheduleRepository schedules;
  late ImportRepository imports;
  var id = 0;
  setUp(() {
    final zones = ZoneResolver.initialized();
    final engine = OccurrenceEngine(zones);
    db = AppDatabase(NativeDatabase.memory(), clock: () => now);
    String newId() => 'local-${++id}';
    schedules = ScheduleRepository(db, validator: SeriesValidator(zones, engine), engine: engine,
        clock: () => now, newId: newId);
    imports = ImportRepository(db, schedules, clock: () => now, newId: newId);
  });
  tearDown(() => db.close());

  ImportEntry entry({String sourceId = 'item-a', String title = 'Fixture class'}) => ImportEntry(
    candidateId: sourceId,
    sourceType: 'share',
    shareId: 'share-a',
    sourceItemId: sourceId,
    sourceRevision: 2,
    draft: ScheduleDraft(title: title, categoryId: 'school',
      time: TimedSpec(startDate: LocalDate(2026, 11, 2), startTime: LocalTime(9, 0), timeZone: 'Asia/Manila'),
      recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.weekly, weekdays: [1, 3])),
    exceptions: [OccurrenceException(originalKey: LocalDate(2026, 11, 4), action: ExceptionAction.cancel)],
  );

  test('confirmation commits independent copies, exceptions, provenance and one outbox atomically', () async {
    final result = await imports.commit('command-a', [entry()]);
    expect(result, hasLength(1));
    final saved = (await schedules.loadAll()).single;
    expect(saved.id, isNot('item-a'));
    expect(saved.revision, 1);
    expect(saved.recurrence!.weekdays, [1, 3]);
    expect(saved.exceptions.single.action, ExceptionAction.cancel);
    expect(await schedules.alertRules(saved.id), isEmpty);
    final source = (await db.select(db.importProvenance).get()).single;
    expect(source.shareId, 'share-a');
    expect(source.sourceItemId, 'item-a');
    expect(source.sourceRevision, 2);
    expect(await db.select(db.reconciliationOutbox).get(), hasLength(1));
    expect(await db.select(db.importCommits).get(), hasLength(1));
    expect(await db.dataRevision(), 1);
  });

  test('repeating the same command returns its receipt without duplicating schedules', () async {
    final a = await imports.commit('command-a', [entry()]);
    final b = await imports.commit('command-a', [entry()]);
    expect(b, a);
    expect(await schedules.loadAll(), hasLength(1));
    expect(await db.dataRevision(), 1);
    await expectLater(imports.commit('command-a', [entry(title: 'Changed')]), throwsStateError);
  });

  test('an invalid selected item rolls back the entire batch', () async {
    await expectLater(imports.commit('command-a', [entry(), entry(sourceId: 'b', title: '')]),
        throwsA(isA<ScheduleValidationException>()));
    expect(await schedules.loadAll(), isEmpty);
    expect(await db.select(db.importProvenance).get(), isEmpty);
    expect(await db.select(db.importCommits).get(), isEmpty);
    expect(await db.dataRevision(), 0);
  });

  test('known exact imports default to skip, but keep-copy is explicit', () async {
    await imports.commit('a', [entry()]);
    final check = await imports.inspect([entry(), entry(sourceId: 'other')]);
    expect(check['item-a']!.exact, isTrue);
    expect(check['other']!.exact, isFalse);
    expect(check['other']!.similar, isTrue);
    expect(await imports.commit('b', [entry()]), isEmpty);
    expect(await schedules.loadAll(), hasLength(1));
    expect(await imports.commit('c', [entry().copyWith(keepCopy: true)]), hasLength(1));
    expect(await schedules.loadAll(), hasLength(2));
  });

  test('similar fingerprints warn, never silently merge unrelated identities', () async {
    await imports.commit('a', [entry(title: '  École class  ')]);
    final other = entry(sourceId: 'different', title: 'école   class');
    expect((await imports.inspect([other]))['different']!.similar, isTrue);
    expect(await imports.commit('b', [other]), hasLength(1));
    expect(await schedules.loadAll(), hasLength(2));
  });

  test('image provenance does not collide with share identities', () async {
    await imports.commit('a', [entry()]);
    final image = ImportEntry(candidateId: 'row-1', sourceType: 'image', imageDraftId: 'draft-1',
        sourceItemId: 'row-1', sourceRevision: 1, draft: entry().draft);
    expect((await imports.inspect([image]))['row-1']!.exact, isFalse);
    await imports.commit('b', [image]);
    expect((await imports.inspect([image]))['row-1']!.exact, isTrue);
  });
}
