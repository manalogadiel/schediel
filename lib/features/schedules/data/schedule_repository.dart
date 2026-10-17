import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/schedule/limits.dart';
import '../../../core/schedule/models.dart';
import '../../../core/schedule/occurrence_engine.dart';
import '../../../core/schedule/schedule_json.dart';
import '../../../core/schedule/validation.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import '../../../data/local/database.dart';
import '../../reminders/domain/alert_rule.dart';

/// Editable schedule fields, before identity and revision are assigned.
@immutable
class ScheduleDraft {
  const ScheduleDraft({
    required this.title,
    required this.time,
    this.categoryId,
    this.recurrence,
    this.details = ScheduleDetails.empty,
  });

  final String title;
  final String? categoryId;
  final TimeSpec time;
  final RecurrenceSpec? recurrence;
  final ScheduleDetails details;

  factory ScheduleDraft.fromSeries(ScheduleSeries s) => ScheduleDraft(
        title: s.title,
        categoryId: s.categoryId,
        time: s.time,
        recurrence: s.recurrence,
        details: s.details,
      );

  ScheduleDraft copyWith({
    String? title,
    String? Function()? categoryId,
    TimeSpec? time,
    RecurrenceSpec? Function()? recurrence,
    ScheduleDetails? details,
  }) =>
      ScheduleDraft(
        title: title ?? this.title,
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        time: time ?? this.time,
        recurrence: recurrence != null ? recurrence() : this.recurrence,
        details: details ?? this.details,
      );

  /// Trims accidental surrounding whitespace; blank optional details become
  /// absent. Inner text is never rewritten.
  ScheduleDraft normalized() => ScheduleDraft(
        title: title.trim(),
        categoryId: categoryId,
        time: time,
        recurrence: recurrence,
        details: ScheduleDetails(
          location: normalizeOptionalText(details.location),
          professor: normalizeOptionalText(details.professor),
          subtitle: normalizeOptionalText(details.subtitle),
          notes: normalizeOptionalText(details.notes),
        ),
      );
}

class ScheduleValidationException implements Exception {
  ScheduleValidationException(this.issues);
  final List<ValidationIssue> issues;

  @override
  String toString() => 'ScheduleValidationException($issues)';
}

class ScheduleNotFoundException implements Exception {
  ScheduleNotFoundException(this.id);
  final String id;
}

/// A series rule change would leave these exceptions pointing at dates that
/// are no longer occurrences. The user must choose what happens to them.
class ExceptionsNeedDecision implements Exception {
  ExceptionsNeedDecision(this.exceptions);
  final List<OccurrenceException> exceptions;
}

enum InvalidExceptionChoice {
  /// Moved or edited occurrences become separate one-time schedules;
  /// cancellations of dates that no longer occur are dropped.
  keepChangesAsOneTime,

  /// Remove the affected exceptions.
  discard,
}

/// Outbox reasons. They contain no user content.
abstract final class OutboxReason {
  static const seriesSaved = 'series_saved';
  static const seriesDeleted = 'series_deleted';
  static const occurrenceChanged = 'occurrence_changed';
  static const categoryChanged = 'category_changed';
  static const importCommitted = 'import_committed';
}

/// Transactional local schedule storage (spec 10 and 11.3). Every mutation
/// writes domain rows, bumps the data revision and enqueues reconciliation
/// work in one transaction.
class ScheduleRepository {
  ScheduleRepository(
    this._db, {
    required this._validator,
    required this._engine,
    required this._clock,
    required this._newId,
  });

  final AppDatabase _db;
  final SeriesValidator _validator;
  final OccurrenceEngine _engine;
  final DateTime Function() _clock;
  final String Function() _newId;

  DateTime get _now => _clock().toUtc();

  Stream<List<ScheduleSeries>> watchAll() => _db
      .customSelect('SELECT 1', readsFrom: {_db.scheduleSeriesTable, _db.occurrenceExceptions})
      .watch()
      .asyncMap((_) => loadAll());

  Stream<ScheduleSeries?> watch(String id) => watchAll().map((all) {
        for (final s in all) {
          if (s.id == id) return s;
        }
        return null;
      });

  Future<List<ScheduleSeries>> loadAll() async {
    final rows = await (_db.select(_db.scheduleSeriesTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt), (t) => OrderingTerm.asc(t.id)]))
        .get();
    final exceptionRows = await _db.select(_db.occurrenceExceptions).get();
    final bySeries = <String, List<ExceptionRow>>{};
    for (final e in exceptionRows) {
      bySeries.putIfAbsent(e.seriesId, () => []).add(e);
    }
    return [for (final row in rows) _toSeries(row, bySeries[row.id] ?? const [])];
  }

  Future<ScheduleSeries?> load(String id) async {
    final row = await (_db.select(_db.scheduleSeriesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final exceptions = await (_db.select(_db.occurrenceExceptions)..where((t) => t.seriesId.equals(id))).get();
    return _toSeries(row, exceptions);
  }

  Stream<List<AlertRule>> watchAllAlertRules() => _db.select(_db.alertRules).watch().map(
        (rows) => [for (final r in rows) _toRule(r)],
      );

  Future<List<AlertRule>> alertRules(String seriesId) async {
    final rows = await (_db.select(_db.alertRules)
          ..where((t) => t.seriesId.equals(seriesId) & t.scopeKey.equals('*'))
          ..orderBy([(t) => OrderingTerm.asc(t.kind)]))
        .get();
    return [for (final r in rows) _toRule(r)];
  }

  Future<String> create(ScheduleDraft draft, {List<AlertPreference> alerts = const []}) {
    final id = _newId();
    return _db.transaction(() async {
      final now = _now;
      final series = _seriesFromDraft(id, 1, draft.normalized(), const [], now, now);
      _ensureValid(series);
      await _db.into(_db.scheduleSeriesTable).insert(_toRow(series));
      await _replaceAlerts(id, alerts, now);
      await _commit(OutboxReason.seriesSaved, now);
      return id;
    });
  }

  /// Exceptions that a new rule would orphan.
  List<OccurrenceException> invalidatedExceptions(ScheduleSeries current, ScheduleDraft draft) {
    final shape = _seriesFromDraft(current.id, current.revision, draft.normalized(), const [], _now, _now);
    return [
      for (final e in current.exceptions)
        if (!shape.isRecurring ||
            !_engine.isOriginalDate(shape, e.originalKey) ||
            (e.replacement != null && e.replacement!.time.runtimeType != shape.time.runtimeType))
          e,
    ];
  }

  Future<void> updateSeries(
    String id,
    ScheduleDraft draft, {
    InvalidExceptionChoice? onInvalidExceptions,
    List<AlertPreference>? alerts,
  }) {
    return _db.transaction(() async {
      final current = await load(id);
      if (current == null) throw ScheduleNotFoundException(id);
      final normalized = draft.normalized();
      final invalid = invalidatedExceptions(current, normalized);
      if (invalid.isNotEmpty && onInvalidExceptions == null) throw ExceptionsNeedDecision(invalid);
      final now = _now;
      final kept = [for (final e in current.exceptions) if (!invalid.contains(e)) e];
      final next = _seriesFromDraft(id, current.revision + 1, normalized, kept, current.createdAt, now);
      _ensureValid(next);
      await (_db.update(_db.scheduleSeriesTable)..where((t) => t.id.equals(id))).write(_toRow(next));
      for (final e in invalid) {
        await (_db.delete(_db.occurrenceExceptions)
              ..where((t) => t.seriesId.equals(id) & t.originalKey.equals(e.originalKey.toIso())))
            .go();
      }
      if (onInvalidExceptions == InvalidExceptionChoice.keepChangesAsOneTime) {
        final rules = await alertRules(id);
        for (final e in invalid) {
          final replacement = e.replacement;
          if (e.action != ExceptionAction.override || replacement == null) continue;
          final oneTimeId = _newId();
          final oneTime = ScheduleSeries(
            id: oneTimeId,
            revision: 1,
            title: replacement.title,
            categoryId: current.categoryId,
            time: replacement.time,
            details: replacement.details,
            createdAt: now,
            updatedAt: now,
          );
          _ensureValid(oneTime);
          await _db.into(_db.scheduleSeriesTable).insert(_toRow(oneTime));
          await _replaceAlerts(oneTimeId, [for (final r in rules) r.preference], now);
        }
      }
      if (alerts != null) await _replaceAlerts(id, alerts, now);
      await _commit(OutboxReason.seriesSaved, now);
    });
  }

  Future<void> overrideOccurrence(String seriesId, LocalDate originalKey, OccurrenceReplacement replacement) =>
      _setException(seriesId, OccurrenceException(
        originalKey: originalKey,
        action: ExceptionAction.override,
        replacement: replacement,
      ));

  Future<void> cancelOccurrence(String seriesId, LocalDate originalKey) => _setException(
        seriesId,
        OccurrenceException(originalKey: originalKey, action: ExceptionAction.cancel),
      );

  Future<void> restoreOccurrence(String seriesId, LocalDate originalKey) {
    return _db.transaction(() async {
      final current = await load(seriesId);
      if (current == null) throw ScheduleNotFoundException(seriesId);
      final now = _now;
      await (_db.delete(_db.occurrenceExceptions)
            ..where((t) => t.seriesId.equals(seriesId) & t.originalKey.equals(originalKey.toIso())))
          .go();
      await _bumpSeries(current, now);
      await _commit(OutboxReason.occurrenceChanged, now);
    });
  }

  Future<void> deleteSeries(String id) {
    return _db.transaction(() async {
      final now = _now;
      await (_db.delete(_db.scheduleSeriesTable)..where((t) => t.id.equals(id))).go();
      await _commit(OutboxReason.seriesDeleted, now);
    });
  }

  /// Inserts already-validated series (import commit). Callers run inside
  /// their own transaction and commit reconciliation work themselves.
  Future<void> insertValidatedSeries(ScheduleSeries series, {List<AlertPreference> alerts = const []}) async {
    _ensureValid(series);
    final now = _now;
    await _db.into(_db.scheduleSeriesTable).insert(_toRow(series));
    for (final e in series.exceptions) {
      await _db.into(_db.occurrenceExceptions).insert(_toExceptionRow(series.id, e, series.revision, now));
    }
    await _replaceAlerts(series.id, alerts, now);
  }

  Future<void> commitWork(String reason) => _commit(reason, _now);

  Future<void> _setException(String seriesId, OccurrenceException exception) {
    return _db.transaction(() async {
      final current = await load(seriesId);
      if (current == null) throw ScheduleNotFoundException(seriesId);
      final now = _now;
      final exceptions = [
        for (final e in current.exceptions)
          if (e.originalKey != exception.originalKey) e,
        exception,
      ];
      final next = current.copyWith(revision: current.revision + 1, exceptions: exceptions, updatedAt: now);
      _ensureValid(next);
      await (_db.delete(_db.occurrenceExceptions)
            ..where((t) => t.seriesId.equals(seriesId) & t.originalKey.equals(exception.originalKey.toIso())))
          .go();
      await _db.into(_db.occurrenceExceptions).insert(_toExceptionRow(seriesId, exception, next.revision, now));
      await (_db.update(_db.scheduleSeriesTable)..where((t) => t.id.equals(seriesId))).write(
        ScheduleSeriesTableCompanion(revision: Value(next.revision), updatedAt: Value(now)),
      );
      await _commit(OutboxReason.occurrenceChanged, now);
    });
  }

  Future<void> _bumpSeries(ScheduleSeries current, DateTime now) =>
      (_db.update(_db.scheduleSeriesTable)..where((t) => t.id.equals(current.id))).write(
        ScheduleSeriesTableCompanion(revision: Value(current.revision + 1), updatedAt: Value(now)),
      );

  void _ensureValid(ScheduleSeries series) {
    final issues = _validator.validate(series);
    if (issues.isNotEmpty) throw ScheduleValidationException(issues);
  }

  Future<void> _replaceAlerts(String seriesId, List<AlertPreference> alerts, DateTime now) async {
    await (_db.delete(_db.alertRules)..where((t) => t.seriesId.equals(seriesId) & t.scopeKey.equals('*'))).go();
    final seen = <AlertKind>{};
    for (final a in alerts) {
      if (!seen.add(a.kind)) continue;
      if (a.offsetMinutes < 0 || a.offsetMinutes > maxAlertOffsetMinutes) {
        throw ScheduleValidationException([ValidationIssue('alerts/${a.kind.name}/offsetMinutes', 'invalid_value')]);
      }
      await _db.into(_db.alertRules).insert(AlertRulesCompanion.insert(
            id: _newId(),
            seriesId: seriesId,
            kind: a.kind.name,
            enabled: a.enabled,
            offsetMinutes: a.offsetMinutes,
            dateOnlyAnchorTime: Value(a.dateOnlyAnchorTime?.toHhMm()),
            dateOnlyAnchorZone: Value(a.dateOnlyAnchorZone),
            lockScreenDetails: a.lockScreenDetails.name,
            presentationPreference: a.presentationPreference.name,
            snoozeMinutes: Value(a.snoozeMinutes),
            createdAt: now,
            updatedAt: now,
          ));
    }
  }

  Future<void> _commit(String reason, DateTime now) async {
    final revision = await _db.bumpDataRevision();
    await _db.into(_db.reconciliationOutbox).insert(ReconciliationOutboxCompanion.insert(
          operationKey: 'reconcile:$revision',
          reason: reason,
          sourceRevision: revision,
          status: 'pending',
          createdAt: now,
        ));
  }

  ScheduleSeries _seriesFromDraft(
    String id,
    int revision,
    ScheduleDraft d,
    List<OccurrenceException> exceptions,
    DateTime createdAt,
    DateTime updatedAt,
  ) =>
      ScheduleSeries(
        id: id,
        revision: revision,
        title: d.title,
        categoryId: d.categoryId,
        time: d.time,
        recurrence: d.recurrence,
        details: d.details,
        exceptions: exceptions,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  ScheduleSeriesTableCompanion _toRow(ScheduleSeries s) {
    final time = s.time;
    final rule = s.recurrence;
    return ScheduleSeriesTableCompanion(
      id: Value(s.id),
      revision: Value(s.revision),
      title: Value(s.title),
      categoryId: Value(s.categoryId),
      timeKind: Value(time is TimedSpec ? 'timed' : 'dateOnly'),
      startDate: Value(time.startDate.toIso()),
      startTime: Value(time is TimedSpec ? time.startTime.toHhMm() : null),
      timeZone: Value(time is TimedSpec ? time.timeZone : null),
      endTime: Value(time is TimedSpec ? time.endTime?.toHhMm() : null),
      endDayOffset: Value(time is TimedSpec ? time.endDayOffset : null),
      seedTimeResolution: Value(time is TimedSpec ? time.seedTimeResolution?.name : null),
      endTimeResolution: Value(time is TimedSpec ? time.endTimeResolution?.name : null),
      endDateExclusive: Value(time is DateOnlySpec ? time.endDateExclusive.toIso() : null),
      recurrenceFrequency: Value(rule?.frequency.name),
      recurrenceWeekdays: Value(rule?.weekdays.join(',')),
      recurrenceUntil: Value(rule?.untilDateInclusive?.toIso()),
      location: Value(s.details.location),
      professor: Value(s.details.professor),
      subtitle: Value(s.details.subtitle),
      notes: Value(s.details.notes),
      createdAt: Value(s.createdAt),
      updatedAt: Value(s.updatedAt),
    );
  }

  OccurrenceExceptionsCompanion _toExceptionRow(String seriesId, OccurrenceException e, int revision, DateTime now) {
    final r = e.replacement;
    return OccurrenceExceptionsCompanion.insert(
      id: _newId(),
      seriesId: seriesId,
      originalKey: e.originalKey.toIso(),
      action: e.action.name,
      replacementJson: Value(r == null
          ? null
          : jsonEncode({'title': r.title, 'time': timeToJson(r.time), 'details': detailsToJson(r.details)})),
      revision: revision,
      createdAt: now,
      updatedAt: now,
    );
  }

  ScheduleSeries _toSeries(SeriesRow row, List<ExceptionRow> exceptionRows) {
    TimeResolution? resolution(String? v) => v == null ? null : TimeResolution.values.byName(v);
    final TimeSpec time = row.timeKind == 'timed'
        ? TimedSpec(
            startDate: LocalDate.parse(row.startDate),
            startTime: LocalTime.parse(row.startTime!),
            timeZone: row.timeZone!,
            endTime: row.endTime == null ? null : LocalTime.parse(row.endTime!),
            endDayOffset: row.endDayOffset,
            seedTimeResolution: resolution(row.seedTimeResolution),
            endTimeResolution: resolution(row.endTimeResolution),
          )
        : DateOnlySpec(
            startDate: LocalDate.parse(row.startDate),
            endDateExclusive: LocalDate.parse(row.endDateExclusive!),
          );
    final frequency = row.recurrenceFrequency;
    final weekdays = row.recurrenceWeekdays;
    final sortedExceptions = [...exceptionRows]..sort((a, b) => a.originalKey.compareTo(b.originalKey));
    return ScheduleSeries(
      id: row.id,
      revision: row.revision,
      title: row.title,
      categoryId: row.categoryId,
      time: time,
      recurrence: frequency == null
          ? null
          : RecurrenceSpec(
              frequency: RecurrenceFrequency.values.byName(frequency),
              weekdays: weekdays == null || weekdays.isEmpty ? const [] : weekdays.split(',').map(int.parse),
              untilDateInclusive: row.recurrenceUntil == null ? null : LocalDate.parse(row.recurrenceUntil!),
            ),
      details: ScheduleDetails(
        location: row.location,
        professor: row.professor,
        subtitle: row.subtitle,
        notes: row.notes,
      ),
      exceptions: [for (final e in sortedExceptions) _toException(e)],
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  OccurrenceException _toException(ExceptionRow row) {
    final json = row.replacementJson;
    OccurrenceReplacement? replacement;
    if (json != null) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      replacement = OccurrenceReplacement(
        title: map['title'] as String,
        time: timeFromJson(map['time'] as Map<String, dynamic>),
        details: detailsFromJson(map['details'] as Map<String, dynamic>),
      );
    }
    return OccurrenceException(
      originalKey: LocalDate.parse(row.originalKey),
      action: ExceptionAction.values.byName(row.action),
      replacement: replacement,
    );
  }

  AlertRule _toRule(AlertRuleRow r) => AlertRule(
        id: r.id,
        seriesId: r.seriesId,
        preference: AlertPreference(
          kind: AlertKind.values.byName(r.kind),
          enabled: r.enabled,
          offsetMinutes: r.offsetMinutes,
          dateOnlyAnchorTime: r.dateOnlyAnchorTime == null ? null : LocalTime.parse(r.dateOnlyAnchorTime!),
          dateOnlyAnchorZone: r.dateOnlyAnchorZone,
          lockScreenDetails: LockScreenDetails.values.byName(r.lockScreenDetails),
          presentationPreference: PresentationPreference.values.byName(r.presentationPreference),
          snoozeMinutes: r.snoozeMinutes,
        ),
      );
}
