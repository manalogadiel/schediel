import 'package:drift/drift.dart';

part 'database.g.dart';

/// Local SQLite schema (SCHEDULER_SPEC.md section 10). SQLite is the source of
/// truth; native alerts and widget snapshots are derived state.

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorKey => text().nullable()();
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SeriesRow')
class ScheduleSeriesTable extends Table {
  @override
  String get tableName => 'schedule_series';

  TextColumn get id => text()();
  IntColumn get revision => integer()();
  TextColumn get title => text()();
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get timeKind => text()();
  TextColumn get startDate => text()();
  TextColumn get startTime => text().nullable()();
  TextColumn get timeZone => text().nullable()();
  TextColumn get endTime => text().nullable()();
  IntColumn get endDayOffset => integer().nullable()();
  TextColumn get seedTimeResolution => text().nullable()();
  TextColumn get endTimeResolution => text().nullable()();
  TextColumn get endDateExclusive => text().nullable()();
  TextColumn get recurrenceFrequency => text().nullable()();
  TextColumn get recurrenceWeekdays => text().nullable()();
  TextColumn get recurrenceUntil => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get professor => text().nullable()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExceptionRow')
class OccurrenceExceptions extends Table {
  TextColumn get id => text()();
  TextColumn get seriesId =>
      text().references(ScheduleSeriesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get originalKey => text()();
  TextColumn get action => text()();
  TextColumn get replacementJson => text().nullable()();
  IntColumn get revision => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {seriesId, originalKey},
      ];
}

/// Desired alert preferences. [scopeKey] is '*' for the whole series or an
/// original occurrence key for a single-occurrence override.
@DataClassName('AlertRuleRow')
class AlertRules extends Table {
  TextColumn get id => text()();
  TextColumn get seriesId =>
      text().references(ScheduleSeriesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get scopeKey => text().withDefault(const Constant('*'))();
  TextColumn get kind => text()();
  BoolColumn get enabled => boolean()();
  IntColumn get offsetMinutes => integer()();
  TextColumn get dateOnlyAnchorTime => text().nullable()();
  TextColumn get dateOnlyAnchorZone => text().nullable()();
  TextColumn get lockScreenDetails => text()();
  TextColumn get presentationPreference => text()();
  IntColumn get snoozeMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {seriesId, scopeKey, kind},
      ];
}

/// Actual native scheduling state, separate from the desired rule.
@DataClassName('ScheduledAlertRow')
class ScheduledAlerts extends Table {
  TextColumn get requestKey => text()();
  /// Not a foreign key: rows outlive a deleted rule until reconciliation
  /// cancels the native request they describe.
  TextColumn get ruleId => text()();
  TextColumn get seriesId => text()();
  TextColumn get occurrenceKey => text()();
  TextColumn get kind => text()();
  TextColumn get platform => text()();
  IntColumn get sourceRevision => integer()();
  TextColumn get nativeRequestId => text().nullable()();
  DateTimeColumn get triggerAt => dateTime()();
  TextColumn get status => text()();
  TextColumn get errorCode => text().nullable()();
  DateTimeColumn get lastReconciledAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {requestKey};
}

/// Work committed in the same transaction as domain changes. Holds no user
/// content.
@DataClassName('OutboxRow')
class ReconciliationOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationKey => text().unique()();
  TextColumn get reason => text()();
  IntColumn get sourceRevision => integer()();
  TextColumn get status => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('WidgetConfigRow')
class WidgetConfigurations extends Table {
  TextColumn get widgetId => text()();

  /// JSON {"categoryIds": [...], "includeUncategorized": bool}; null = all.
  TextColumn get categoryFilter => text().nullable()();
  TextColumn get layout => text().withDefault(const Constant('expanded'))();
  TextColumn get surface => text().withDefault(const Constant('clear'))();
  TextColumn get textTone => text().withDefault(const Constant('light'))();
  BoolColumn get nextEmphasis => boolean().withDefault(const Constant(true))();
  BoolColumn get showLocation => boolean().withDefault(const Constant(true))();
  BoolColumn get showProfessor => boolean().withDefault(const Constant(true))();
  BoolColumn get showSubtitle => boolean().withDefault(const Constant(true))();
  BoolColumn get matchApp => boolean().withDefault(const Constant(false))();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {widgetId};
}

@DataClassName('PreferencesRow')
class AppearancePreferences extends Table {
  IntColumn get id => integer()();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  TextColumn get accentKey => text().withDefault(const Constant('blue'))();
  TextColumn get density => text().withDefault(const Constant('comfortable'))();
  BoolColumn get showCategoryColors => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Unconfirmed image or share review drafts. Never active schedules.
@DataClassName('ImportDraftRow')
class ImportDrafts extends Table {
  TextColumn get id => text()();
  TextColumn get sourceType => text()();
  TextColumn get sourceRef => text().nullable()();
  IntColumn get sourceRevision => integer()();
  IntColumn get draftRevision => integer()();
  TextColumn get payloadJson => text()();
  TextColumn get reviewState => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProvenanceRow')
class ImportProvenance extends Table {
  TextColumn get id => text()();
  TextColumn get seriesId =>
      text().references(ScheduleSeriesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get sourceType => text()();
  TextColumn get shareId => text().nullable()();
  TextColumn get sourceItemId => text().nullable()();
  IntColumn get sourceRevision => integer().nullable()();
  TextColumn get imageDraftId => text().nullable()();
  TextColumn get fingerprint => text()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Once-only import receipts keyed by command identity.
@DataClassName('ImportCommitRow')
class ImportCommits extends Table {
  TextColumn get commandId => text()();
  TextColumn get payloadHash => text()();
  TextColumn get seriesIdsJson => text()();
  DateTimeColumn get committedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {commandId};
}

@DataClassName('OwnedShareLinkRow')
class OwnedShareLinks extends Table {
  TextColumn get shareId => text()();
  IntColumn get snapshotVersion => integer()();
  IntColumn get itemCount => integer()();
  TextColumn get categoryLabelsJson => text()();
  TextColumn get routePath => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get revokedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {shareId};
}

/// A share creation whose secret is already stored, awaiting a certain
/// response. Retries reuse the same key and secret.
@DataClassName('PendingShareRow')
class PendingShareCreations extends Table {
  TextColumn get idempotencyKey => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {idempotencyKey};
}

@DataClassName('KeyValueRow')
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Categories,
    ScheduleSeriesTable,
    OccurrenceExceptions,
    AlertRules,
    ScheduledAlerts,
    ReconciliationOutbox,
    WidgetConfigurations,
    AppearancePreferences,
    ImportDrafts,
    ImportProvenance,
    ImportCommits,
    OwnedShareLinks,
    PendingShareCreations,
    KeyValues,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  int get schemaVersion => 1;

  static const builtInCategories = [
    ('school', 'School'),
    ('work', 'Work'),
    ('personal', 'Personal'),
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          final now = _clock().toUtc();
          for (var i = 0; i < builtInCategories.length; i++) {
            final (id, name) = builtInCategories[i];
            await into(categories).insert(CategoriesCompanion.insert(
              id: id,
              name: name,
              builtIn: const Value(true),
              sortOrder: i,
              createdAt: now,
              updatedAt: now,
            ));
          }
          await into(appearancePreferences).insert(AppearancePreferencesCompanion.insert(id: const Value(1), updatedAt: now));
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Increments and returns the local data revision inside the current
  /// transaction. Widget snapshots carry it to prevent mixed revisions.
  Future<int> bumpDataRevision() async {
    final current = await (select(keyValues)..where((t) => t.key.equals('dataRevision'))).getSingleOrNull();
    final next = (int.tryParse(current?.value ?? '') ?? 0) + 1;
    await into(keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: 'dataRevision', value: '$next'));
    return next;
  }

  Future<int> dataRevision() async {
    final current = await (select(keyValues)..where((t) => t.key.equals('dataRevision'))).getSingleOrNull();
    return int.tryParse(current?.value ?? '') ?? 0;
  }

  Future<String?> readValue(String key) async =>
      (await (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> writeValue(String key, String value) =>
      into(keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: value));
}
