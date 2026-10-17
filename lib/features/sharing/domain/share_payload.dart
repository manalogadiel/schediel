import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/schedule/limits.dart';
import '../../../core/schedule/models.dart';
import '../../../core/schedule/occurrence_engine.dart';
import '../../../core/schedule/schedule_json.dart';
import '../../../core/schedule/validation.dart';
import '../../../core/time/local_date.dart';
import '../../../core/time/local_time.dart';
import '../../../core/time/zone_resolver.dart';

export '../../../core/schedule/schedule_json.dart';

const String sharePayloadSchemaVersion = '1.0';

/// Which optional details a sender included (CONTRACTS.md section 5.1).
@immutable
class SharedFieldPolicy {
  const SharedFieldPolicy({
    required this.location,
    required this.professor,
    required this.subtitle,
    required this.notes,
  });

  final bool location;
  final bool professor;
  final bool subtitle;
  final bool notes;

  ScheduleDetails apply(ScheduleDetails d) => ScheduleDetails(
        location: location ? d.location : null,
        professor: professor ? d.professor : null,
        subtitle: subtitle ? d.subtitle : null,
        notes: notes ? d.notes : null,
      );

  Map<String, Object?> toJson() =>
      {'location': location, 'professor': professor, 'subtitle': subtitle, 'notes': notes};

  factory SharedFieldPolicy.fromJson(Map<String, dynamic> json) => SharedFieldPolicy(
        location: json['location'] as bool,
        professor: json['professor'] as bool,
        subtitle: json['subtitle'] as bool,
        notes: json['notes'] as bool,
      );
}

/// One canonical schedule item in a share snapshot.
@immutable
class ShareItem {
  ShareItem({
    required this.sourceItemId,
    required this.revision,
    required this.title,
    required this.categoryLabel,
    required this.time,
    required this.recurrence,
    required this.details,
    Iterable<OccurrenceException> exceptions = const [],
  }) : exceptions = List.unmodifiable(exceptions);

  final String sourceItemId;
  final int revision;
  final String title;
  final String? categoryLabel;
  final TimeSpec time;
  final RecurrenceSpec? recurrence;
  final ScheduleDetails details;
  final List<OccurrenceException> exceptions;

  /// The item as a series for rule evaluation; ids stay source ids.
  ScheduleSeries toSeries() => ScheduleSeries(
        id: sourceItemId,
        revision: revision,
        title: title,
        time: time,
        recurrence: recurrence,
        details: details,
        exceptions: exceptions,
      );

  Map<String, Object?> toJson() => {
        'sourceItemId': sourceItemId,
        'revision': revision,
        'title': title,
        'categoryLabel': categoryLabel,
        'time': timeToJson(time),
        'recurrence': recurrence == null ? null : recurrenceToJson(recurrence!),
        'details': detailsToJson(details),
        'exceptions': [for (final e in exceptions) exceptionToJson(e)],
      };

  factory ShareItem.fromJson(Map<String, dynamic> json) => ShareItem(
        sourceItemId: json['sourceItemId'] as String,
        revision: (json['revision'] as num).toInt(),
        title: json['title'] as String,
        categoryLabel: json['categoryLabel'] as String?,
        time: timeFromJson(json['time'] as Map<String, dynamic>),
        recurrence: json['recurrence'] == null
            ? null
            : recurrenceFromJson(json['recurrence'] as Map<String, dynamic>),
        details: detailsFromJson(json['details'] as Map<String, dynamic>),
        exceptions: [
          for (final e in json['exceptions'] as List) exceptionFromJson(e as Map<String, dynamic>),
        ],
      );
}

@immutable
class SharePayload {
  SharePayload({required Iterable<ShareItem> items, required this.sharedFieldPolicy})
      : items = List.unmodifiable(items);

  final List<ShareItem> items;
  final SharedFieldPolicy sharedFieldPolicy;

  Map<String, Object?> toJson() => {
        'schemaVersion': sharePayloadSchemaVersion,
        'items': [for (final item in items) item.toJson()],
        'sharedFieldPolicy': sharedFieldPolicy.toJson(),
      };

  /// Canonical UTF-8 serialization used for size limits and request hashes.
  List<int> canonicalBytes() => utf8.encode(jsonEncode(toJson()));

  factory SharePayload.fromJson(Map<String, dynamic> json) => SharePayload(
        items: [for (final i in json['items'] as List) ShareItem.fromJson(i as Map<String, dynamic>)],
        sharedFieldPolicy: SharedFieldPolicy.fromJson(json['sharedFieldPolicy'] as Map<String, dynamic>),
      );
}

/// A contract violation at a JSON Pointer [path].
@immutable
class ContractError {
  const ContractError(this.code, this.path);

  final String code;
  final String path;

  @override
  String toString() => '$code@$path';
}

/// Strict validator for share payload 1.0, matching
/// contracts/schemas/share-payload-v1.schema.json and its semantic rules.
class SharePayloadValidator {
  SharePayloadValidator(ZoneResolver zones, OccurrenceEngine engine)
      : _series = SeriesValidator(zones, engine);

  final SeriesValidator _series;

  static final RegExp _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

  List<ContractError> validate(Object? json) {
    final errors = <ContractError>[];
    if (json is! Map<String, dynamic>) return [const ContractError('invalid_type', '')];
    _keys(errors, json, '', const ['schemaVersion', 'items', 'sharedFieldPolicy']);
    if (json.containsKey('schemaVersion')) {
      final version = json['schemaVersion'];
      if (version is! String) {
        errors.add(const ContractError('invalid_type', '/schemaVersion'));
      } else if (version != sharePayloadSchemaVersion) {
        return [...errors, const ContractError('unsupported_version', '/schemaVersion')];
      }
    }

    Map<String, dynamic>? policy;
    if (json.containsKey('sharedFieldPolicy')) {
      final raw = json['sharedFieldPolicy'];
      if (raw is! Map<String, dynamic>) {
        errors.add(const ContractError('invalid_type', '/sharedFieldPolicy'));
      } else {
        _keys(errors, raw, '/sharedFieldPolicy', const ['location', 'professor', 'subtitle', 'notes']);
        var ok = true;
        for (final key in const ['location', 'professor', 'subtitle', 'notes']) {
          if (raw.containsKey(key) && raw[key] is! bool) {
            errors.add(ContractError('invalid_type', '/sharedFieldPolicy/$key'));
            ok = false;
          }
        }
        if (ok && raw.length == 4) policy = raw;
      }
    }

    if (!json.containsKey('items')) return errors;
    final items = json['items'];
    if (items is! List) return [...errors, const ContractError('invalid_type', '/items')];
    if (items.isEmpty) return [...errors, const ContractError('invalid_value', '/items')];
    if (items.length > ScheduleLimits.shareMaxItems) {
      return [...errors, const ContractError('too_many', '/items')];
    }

    final ids = <String>{};
    var exceptionCount = 0;
    for (var i = 0; i < items.length; i++) {
      final path = '/items/$i';
      final itemErrors = <ContractError>[];
      _item(itemErrors, items[i], path);
      if (itemErrors.isNotEmpty) {
        errors.addAll(itemErrors);
        continue;
      }
      final item = ShareItem.fromJson(items[i] as Map<String, dynamic>);
      for (final issue in _series.validate(item.toSeries())) {
        errors.add(ContractError(issue.code, '$path/${issue.path}'));
      }
      if (!ids.add(item.sourceItemId)) errors.add(ContractError('duplicate', '$path/sourceItemId'));
      exceptionCount += item.exceptions.length;
      if (policy != null) _policy(errors, item, path, policy);
    }
    if (exceptionCount > ScheduleLimits.shareMaxExceptions) {
      errors.add(const ContractError('too_many', '/items'));
    }
    if (errors.isEmpty && utf8.encode(jsonEncode(json)).length > ScheduleLimits.shareMaxBytes) {
      errors.add(const ContractError('payload_too_large', ''));
    }
    return errors;
  }

  void _policy(List<ContractError> errors, ShareItem item, String path, Map<String, dynamic> policy) {
    void check(String detailsPath, ScheduleDetails d) {
      final values = {'location': d.location, 'professor': d.professor, 'subtitle': d.subtitle, 'notes': d.notes};
      values.forEach((key, value) {
        if (policy[key] == false && value != null) errors.add(ContractError('policy_violation', '$detailsPath/$key'));
      });
    }

    check('$path/details', item.details);
    for (var k = 0; k < item.exceptions.length; k++) {
      final replacement = item.exceptions[k].replacement;
      if (replacement != null) check('$path/exceptions/$k/replacement/details', replacement.details);
    }
  }

  void _keys(List<ContractError> errors, Map<String, dynamic> map, String path, List<String> allowed) {
    for (final key in map.keys) {
      if (!allowed.contains(key)) errors.add(ContractError('unknown_field', '$path/$key'));
    }
    for (final key in allowed) {
      if (!map.containsKey(key)) errors.add(ContractError('missing_field', '$path/$key'));
    }
  }

  bool _isInteger(Object? v) => v is int || (v is double && v.isFinite && v == v.truncateToDouble());

  void _text(List<ContractError> errors, Object? value, String path, int max, {required bool nullable}) {
    if (value == null) {
      if (!nullable) errors.add(ContractError('invalid_type', path));
      return;
    }
    if (value is! String) {
      errors.add(ContractError('invalid_type', path));
    } else if (value.isEmpty || !isTrimmed(value)) {
      errors.add(ContractError('invalid_text', path));
    } else if (codePointLength(value) > max) {
      errors.add(ContractError('too_long', path));
    }
  }

  void _date(List<ContractError> errors, Object? value, String path, {bool nullable = false}) {
    if (value == null && nullable) return;
    if (value is! String) {
      errors.add(ContractError('invalid_type', path));
    } else if (LocalDate.tryParse(value) == null) {
      errors.add(ContractError('invalid_date', path));
    }
  }

  void _clock(List<ContractError> errors, Object? value, String path, {bool nullable = false}) {
    if (value == null && nullable) return;
    if (value is! String) {
      errors.add(ContractError('invalid_type', path));
    } else if (LocalTime.tryParse(value) == null) {
      errors.add(ContractError('invalid_time', path));
    }
  }

  void _item(List<ContractError> errors, Object? raw, String path) {
    if (raw is! Map<String, dynamic>) {
      errors.add(ContractError('invalid_type', path));
      return;
    }
    _keys(errors, raw, path, const [
      'sourceItemId',
      'revision',
      'title',
      'categoryLabel',
      'time',
      'recurrence',
      'details',
      'exceptions',
    ]);
    final id = raw['sourceItemId'];
    if (raw.containsKey('sourceItemId')) {
      if (id is! String) {
        errors.add(ContractError('invalid_type', '$path/sourceItemId'));
      } else if (!_uuid.hasMatch(id)) {
        errors.add(ContractError('invalid_value', '$path/sourceItemId'));
      }
    }
    if (raw.containsKey('revision')) {
      final revision = raw['revision'];
      if (!_isInteger(revision)) {
        errors.add(ContractError('invalid_type', '$path/revision'));
      } else if ((revision as num) < 1 || revision > 2147483647) {
        errors.add(ContractError('invalid_value', '$path/revision'));
      }
    }
    if (raw.containsKey('title')) _text(errors, raw['title'], '$path/title', ScheduleLimits.titleMax, nullable: false);
    if (raw.containsKey('categoryLabel')) {
      _text(errors, raw['categoryLabel'], '$path/categoryLabel', ScheduleLimits.categoryNameMax, nullable: true);
    }
    if (raw.containsKey('time')) _time(errors, raw['time'], '$path/time');
    if (raw.containsKey('recurrence') && raw['recurrence'] != null) {
      _recurrence(errors, raw['recurrence'], '$path/recurrence');
    }
    if (raw.containsKey('details')) _details(errors, raw['details'], '$path/details');
    if (raw.containsKey('exceptions')) _exceptions(errors, raw['exceptions'], '$path/exceptions');
  }

  void _time(List<ContractError> errors, Object? raw, String path) {
    if (raw is! Map<String, dynamic>) {
      errors.add(ContractError('invalid_type', path));
      return;
    }
    final kind = raw['kind'];
    if (!raw.containsKey('kind')) {
      errors.add(ContractError('missing_field', '$path/kind'));
      return;
    }
    if (kind == 'dateOnly') {
      _keys(errors, raw, path, const ['kind', 'startDate', 'endDateExclusive']);
      if (raw.containsKey('startDate')) _date(errors, raw['startDate'], '$path/startDate');
      if (raw.containsKey('endDateExclusive')) _date(errors, raw['endDateExclusive'], '$path/endDateExclusive');
      return;
    }
    if (kind != 'timed') {
      errors.add(ContractError('invalid_value', '$path/kind'));
      return;
    }
    _keys(errors, raw, path, const [
      'kind',
      'startDate',
      'startTime',
      'timeZone',
      'endTime',
      'endDayOffset',
      'seedTimeResolution',
      'endTimeResolution',
    ]);
    if (raw.containsKey('startDate')) _date(errors, raw['startDate'], '$path/startDate');
    if (raw.containsKey('startTime')) _clock(errors, raw['startTime'], '$path/startTime');
    if (raw.containsKey('timeZone')) {
      final zone = raw['timeZone'];
      if (zone is! String) {
        errors.add(ContractError('invalid_type', '$path/timeZone'));
      } else if (zone.isEmpty || zone.length > 64) {
        errors.add(ContractError('invalid_time_zone', '$path/timeZone'));
      }
    }
    if (raw.containsKey('endTime')) _clock(errors, raw['endTime'], '$path/endTime', nullable: true);
    if (raw.containsKey('endDayOffset')) {
      final offset = raw['endDayOffset'];
      if (offset != null && !(_isInteger(offset) && (offset == 0 || offset == 1))) {
        errors.add(ContractError('invalid_value', '$path/endDayOffset'));
      }
    }
    for (final key in const ['seedTimeResolution', 'endTimeResolution']) {
      final value = raw[key];
      if (raw.containsKey(key) && value != null && value != 'earlier' && value != 'later') {
        errors.add(ContractError('invalid_value', '$path/$key'));
      }
    }
  }

  void _recurrence(List<ContractError> errors, Object? raw, String path) {
    if (raw is! Map<String, dynamic>) {
      errors.add(ContractError('invalid_type', path));
      return;
    }
    _keys(errors, raw, path, const ['frequency', 'interval', 'weekdays', 'untilDateInclusive']);
    final frequency = raw['frequency'];
    if (raw.containsKey('frequency') && frequency != 'daily' && frequency != 'weekly') {
      errors.add(ContractError('invalid_value', '$path/frequency'));
    }
    if (raw.containsKey('interval')) {
      final interval = raw['interval'];
      if (!_isInteger(interval)) {
        errors.add(ContractError('invalid_type', '$path/interval'));
      } else if (interval != 1) {
        errors.add(ContractError('invalid_value', '$path/interval'));
      }
    }
    if (raw.containsKey('weekdays')) {
      final weekdays = raw['weekdays'];
      if (weekdays is! List) {
        errors.add(ContractError('invalid_type', '$path/weekdays'));
      } else if (weekdays.any((d) => !_isInteger(d))) {
        errors.add(ContractError('invalid_type', '$path/weekdays'));
      } else {
        final values = [for (final d in weekdays) (d as num).toInt()];
        if (values.length > 7 || values.toSet().length != values.length || values.any((d) => d < 1 || d > 7)) {
          errors.add(ContractError('invalid_recurrence', '$path/weekdays'));
        }
      }
    }
    if (raw.containsKey('untilDateInclusive')) {
      _date(errors, raw['untilDateInclusive'], '$path/untilDateInclusive', nullable: true);
    }
  }

  void _details(List<ContractError> errors, Object? raw, String path) {
    if (raw is! Map<String, dynamic>) {
      errors.add(ContractError('invalid_type', path));
      return;
    }
    _keys(errors, raw, path, const ['location', 'professor', 'subtitle', 'notes']);
    const limits = {
      'location': ScheduleLimits.locationMax,
      'professor': ScheduleLimits.professorMax,
      'subtitle': ScheduleLimits.subtitleMax,
      'notes': ScheduleLimits.notesMax,
    };
    limits.forEach((key, max) {
      if (raw.containsKey(key)) _text(errors, raw[key], '$path/$key', max, nullable: true);
    });
  }

  void _exceptions(List<ContractError> errors, Object? raw, String path) {
    if (raw is! List) {
      errors.add(ContractError('invalid_type', path));
      return;
    }
    if (raw.length > ScheduleLimits.shareMaxExceptions) {
      errors.add(ContractError('too_many', path));
      return;
    }
    for (var k = 0; k < raw.length; k++) {
      final p = '$path/$k';
      final e = raw[k];
      if (e is! Map<String, dynamic>) {
        errors.add(ContractError('invalid_type', p));
        continue;
      }
      _keys(errors, e, p, const ['originalOccurrenceKey', 'action', 'replacement']);
      if (e.containsKey('originalOccurrenceKey')) _date(errors, e['originalOccurrenceKey'], '$p/originalOccurrenceKey');
      final action = e['action'];
      if (e.containsKey('action') && action != 'cancel' && action != 'override') {
        errors.add(ContractError('invalid_value', '$p/action'));
      }
      final replacement = e['replacement'];
      if (replacement == null) continue;
      if (replacement is! Map<String, dynamic>) {
        errors.add(ContractError('invalid_type', '$p/replacement'));
        continue;
      }
      final rp = '$p/replacement';
      _keys(errors, replacement, rp, const ['title', 'time', 'details']);
      if (replacement.containsKey('title')) {
        _text(errors, replacement['title'], '$rp/title', ScheduleLimits.titleMax, nullable: false);
      }
      if (replacement.containsKey('time')) _time(errors, replacement['time'], '$rp/time');
      if (replacement.containsKey('details')) _details(errors, replacement['details'], '$rp/details');
    }
  }
}
