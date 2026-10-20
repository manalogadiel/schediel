// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorKeyMeta = const VerificationMeta(
    'colorKey',
  );
  @override
  late final GeneratedColumn<String> colorKey = GeneratedColumn<String>(
    'color_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _builtInMeta = const VerificationMeta(
    'builtIn',
  );
  @override
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorKey,
    builtIn,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_key')) {
      context.handle(
        _colorKeyMeta,
        colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta),
      );
    }
    if (data.containsKey('built_in')) {
      context.handle(
        _builtInMeta,
        builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_key'],
      ),
      builtIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}built_in'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String? colorKey;
  final bool builtIn;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CategoryRow({
    required this.id,
    required this.name,
    this.colorKey,
    required this.builtIn,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorKey != null) {
      map['color_key'] = Variable<String>(colorKey);
    }
    map['built_in'] = Variable<bool>(builtIn);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorKey: colorKey == null && nullToAbsent
          ? const Value.absent()
          : Value(colorKey),
      builtIn: Value(builtIn),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorKey: serializer.fromJson<String?>(json['colorKey']),
      builtIn: serializer.fromJson<bool>(json['builtIn']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorKey': serializer.toJson<String?>(colorKey),
      'builtIn': serializer.toJson<bool>(builtIn),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    Value<String?> colorKey = const Value.absent(),
    bool? builtIn,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    colorKey: colorKey.present ? colorKey.value : this.colorKey,
    builtIn: builtIn ?? this.builtIn,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorKey: $colorKey, ')
          ..write('builtIn: $builtIn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, colorKey, builtIn, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorKey == this.colorKey &&
          other.builtIn == this.builtIn &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> colorKey;
  final Value<bool> builtIn;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.colorKey = const Value.absent(),
    this.builtIn = const Value.absent(),
    required int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorKey,
    Expression<bool>? builtIn,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorKey != null) 'color_key': colorKey,
      if (builtIn != null) 'built_in': builtIn,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? colorKey,
    Value<bool>? builtIn,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorKey: colorKey ?? this.colorKey,
      builtIn: builtIn ?? this.builtIn,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorKey.present) {
      map['color_key'] = Variable<String>(colorKey.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorKey: $colorKey, ')
          ..write('builtIn: $builtIn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduleSeriesTableTable extends ScheduleSeriesTable
    with TableInfo<$ScheduleSeriesTableTable, SeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleSeriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _timeKindMeta = const VerificationMeta(
    'timeKind',
  );
  @override
  late final GeneratedColumn<String> timeKind = GeneratedColumn<String>(
    'time_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta(
    'timeZone',
  );
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDayOffsetMeta = const VerificationMeta(
    'endDayOffset',
  );
  @override
  late final GeneratedColumn<int> endDayOffset = GeneratedColumn<int>(
    'end_day_offset',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seedTimeResolutionMeta =
      const VerificationMeta('seedTimeResolution');
  @override
  late final GeneratedColumn<String> seedTimeResolution =
      GeneratedColumn<String>(
        'seed_time_resolution',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _endTimeResolutionMeta = const VerificationMeta(
    'endTimeResolution',
  );
  @override
  late final GeneratedColumn<String> endTimeResolution =
      GeneratedColumn<String>(
        'end_time_resolution',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _endDateExclusiveMeta = const VerificationMeta(
    'endDateExclusive',
  );
  @override
  late final GeneratedColumn<String> endDateExclusive = GeneratedColumn<String>(
    'end_date_exclusive',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceFrequencyMeta =
      const VerificationMeta('recurrenceFrequency');
  @override
  late final GeneratedColumn<String> recurrenceFrequency =
      GeneratedColumn<String>(
        'recurrence_frequency',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recurrenceWeekdaysMeta =
      const VerificationMeta('recurrenceWeekdays');
  @override
  late final GeneratedColumn<String> recurrenceWeekdays =
      GeneratedColumn<String>(
        'recurrence_weekdays',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recurrenceUntilMeta = const VerificationMeta(
    'recurrenceUntil',
  );
  @override
  late final GeneratedColumn<String> recurrenceUntil = GeneratedColumn<String>(
    'recurrence_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _professorMeta = const VerificationMeta(
    'professor',
  );
  @override
  late final GeneratedColumn<String> professor = GeneratedColumn<String>(
    'professor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    revision,
    title,
    categoryId,
    timeKind,
    startDate,
    startTime,
    timeZone,
    endTime,
    endDayOffset,
    seedTimeResolution,
    endTimeResolution,
    endDateExclusive,
    recurrenceFrequency,
    recurrenceWeekdays,
    recurrenceUntil,
    location,
    professor,
    subtitle,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('time_kind')) {
      context.handle(
        _timeKindMeta,
        timeKind.isAcceptableOrUnknown(data['time_kind']!, _timeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_timeKindMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('end_day_offset')) {
      context.handle(
        _endDayOffsetMeta,
        endDayOffset.isAcceptableOrUnknown(
          data['end_day_offset']!,
          _endDayOffsetMeta,
        ),
      );
    }
    if (data.containsKey('seed_time_resolution')) {
      context.handle(
        _seedTimeResolutionMeta,
        seedTimeResolution.isAcceptableOrUnknown(
          data['seed_time_resolution']!,
          _seedTimeResolutionMeta,
        ),
      );
    }
    if (data.containsKey('end_time_resolution')) {
      context.handle(
        _endTimeResolutionMeta,
        endTimeResolution.isAcceptableOrUnknown(
          data['end_time_resolution']!,
          _endTimeResolutionMeta,
        ),
      );
    }
    if (data.containsKey('end_date_exclusive')) {
      context.handle(
        _endDateExclusiveMeta,
        endDateExclusive.isAcceptableOrUnknown(
          data['end_date_exclusive']!,
          _endDateExclusiveMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_frequency')) {
      context.handle(
        _recurrenceFrequencyMeta,
        recurrenceFrequency.isAcceptableOrUnknown(
          data['recurrence_frequency']!,
          _recurrenceFrequencyMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_weekdays')) {
      context.handle(
        _recurrenceWeekdaysMeta,
        recurrenceWeekdays.isAcceptableOrUnknown(
          data['recurrence_weekdays']!,
          _recurrenceWeekdaysMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_until')) {
      context.handle(
        _recurrenceUntilMeta,
        recurrenceUntil.isAcceptableOrUnknown(
          data['recurrence_until']!,
          _recurrenceUntilMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('professor')) {
      context.handle(
        _professorMeta,
        professor.isAcceptableOrUnknown(data['professor']!, _professorMeta),
      );
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      timeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_kind'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      endDayOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_day_offset'],
      ),
      seedTimeResolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_time_resolution'],
      ),
      endTimeResolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time_resolution'],
      ),
      endDateExclusive: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date_exclusive'],
      ),
      recurrenceFrequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_frequency'],
      ),
      recurrenceWeekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_weekdays'],
      ),
      recurrenceUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_until'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      professor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}professor'],
      ),
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ScheduleSeriesTableTable createAlias(String alias) {
    return $ScheduleSeriesTableTable(attachedDatabase, alias);
  }
}

class SeriesRow extends DataClass implements Insertable<SeriesRow> {
  final String id;
  final int revision;
  final String title;
  final String? categoryId;
  final String timeKind;
  final String startDate;
  final String? startTime;
  final String? timeZone;
  final String? endTime;
  final int? endDayOffset;
  final String? seedTimeResolution;
  final String? endTimeResolution;
  final String? endDateExclusive;
  final String? recurrenceFrequency;
  final String? recurrenceWeekdays;
  final String? recurrenceUntil;
  final String? location;
  final String? professor;
  final String? subtitle;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SeriesRow({
    required this.id,
    required this.revision,
    required this.title,
    this.categoryId,
    required this.timeKind,
    required this.startDate,
    this.startTime,
    this.timeZone,
    this.endTime,
    this.endDayOffset,
    this.seedTimeResolution,
    this.endTimeResolution,
    this.endDateExclusive,
    this.recurrenceFrequency,
    this.recurrenceWeekdays,
    this.recurrenceUntil,
    this.location,
    this.professor,
    this.subtitle,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['revision'] = Variable<int>(revision);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['time_kind'] = Variable<String>(timeKind);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || timeZone != null) {
      map['time_zone'] = Variable<String>(timeZone);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    if (!nullToAbsent || endDayOffset != null) {
      map['end_day_offset'] = Variable<int>(endDayOffset);
    }
    if (!nullToAbsent || seedTimeResolution != null) {
      map['seed_time_resolution'] = Variable<String>(seedTimeResolution);
    }
    if (!nullToAbsent || endTimeResolution != null) {
      map['end_time_resolution'] = Variable<String>(endTimeResolution);
    }
    if (!nullToAbsent || endDateExclusive != null) {
      map['end_date_exclusive'] = Variable<String>(endDateExclusive);
    }
    if (!nullToAbsent || recurrenceFrequency != null) {
      map['recurrence_frequency'] = Variable<String>(recurrenceFrequency);
    }
    if (!nullToAbsent || recurrenceWeekdays != null) {
      map['recurrence_weekdays'] = Variable<String>(recurrenceWeekdays);
    }
    if (!nullToAbsent || recurrenceUntil != null) {
      map['recurrence_until'] = Variable<String>(recurrenceUntil);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || professor != null) {
      map['professor'] = Variable<String>(professor);
    }
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ScheduleSeriesTableCompanion toCompanion(bool nullToAbsent) {
    return ScheduleSeriesTableCompanion(
      id: Value(id),
      revision: Value(revision),
      title: Value(title),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      timeKind: Value(timeKind),
      startDate: Value(startDate),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      timeZone: timeZone == null && nullToAbsent
          ? const Value.absent()
          : Value(timeZone),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      endDayOffset: endDayOffset == null && nullToAbsent
          ? const Value.absent()
          : Value(endDayOffset),
      seedTimeResolution: seedTimeResolution == null && nullToAbsent
          ? const Value.absent()
          : Value(seedTimeResolution),
      endTimeResolution: endTimeResolution == null && nullToAbsent
          ? const Value.absent()
          : Value(endTimeResolution),
      endDateExclusive: endDateExclusive == null && nullToAbsent
          ? const Value.absent()
          : Value(endDateExclusive),
      recurrenceFrequency: recurrenceFrequency == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceFrequency),
      recurrenceWeekdays: recurrenceWeekdays == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceWeekdays),
      recurrenceUntil: recurrenceUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceUntil),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      professor: professor == null && nullToAbsent
          ? const Value.absent()
          : Value(professor),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SeriesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRow(
      id: serializer.fromJson<String>(json['id']),
      revision: serializer.fromJson<int>(json['revision']),
      title: serializer.fromJson<String>(json['title']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      timeKind: serializer.fromJson<String>(json['timeKind']),
      startDate: serializer.fromJson<String>(json['startDate']),
      startTime: serializer.fromJson<String?>(json['startTime']),
      timeZone: serializer.fromJson<String?>(json['timeZone']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      endDayOffset: serializer.fromJson<int?>(json['endDayOffset']),
      seedTimeResolution: serializer.fromJson<String?>(
        json['seedTimeResolution'],
      ),
      endTimeResolution: serializer.fromJson<String?>(
        json['endTimeResolution'],
      ),
      endDateExclusive: serializer.fromJson<String?>(json['endDateExclusive']),
      recurrenceFrequency: serializer.fromJson<String?>(
        json['recurrenceFrequency'],
      ),
      recurrenceWeekdays: serializer.fromJson<String?>(
        json['recurrenceWeekdays'],
      ),
      recurrenceUntil: serializer.fromJson<String?>(json['recurrenceUntil']),
      location: serializer.fromJson<String?>(json['location']),
      professor: serializer.fromJson<String?>(json['professor']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'revision': serializer.toJson<int>(revision),
      'title': serializer.toJson<String>(title),
      'categoryId': serializer.toJson<String?>(categoryId),
      'timeKind': serializer.toJson<String>(timeKind),
      'startDate': serializer.toJson<String>(startDate),
      'startTime': serializer.toJson<String?>(startTime),
      'timeZone': serializer.toJson<String?>(timeZone),
      'endTime': serializer.toJson<String?>(endTime),
      'endDayOffset': serializer.toJson<int?>(endDayOffset),
      'seedTimeResolution': serializer.toJson<String?>(seedTimeResolution),
      'endTimeResolution': serializer.toJson<String?>(endTimeResolution),
      'endDateExclusive': serializer.toJson<String?>(endDateExclusive),
      'recurrenceFrequency': serializer.toJson<String?>(recurrenceFrequency),
      'recurrenceWeekdays': serializer.toJson<String?>(recurrenceWeekdays),
      'recurrenceUntil': serializer.toJson<String?>(recurrenceUntil),
      'location': serializer.toJson<String?>(location),
      'professor': serializer.toJson<String?>(professor),
      'subtitle': serializer.toJson<String?>(subtitle),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SeriesRow copyWith({
    String? id,
    int? revision,
    String? title,
    Value<String?> categoryId = const Value.absent(),
    String? timeKind,
    String? startDate,
    Value<String?> startTime = const Value.absent(),
    Value<String?> timeZone = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    Value<int?> endDayOffset = const Value.absent(),
    Value<String?> seedTimeResolution = const Value.absent(),
    Value<String?> endTimeResolution = const Value.absent(),
    Value<String?> endDateExclusive = const Value.absent(),
    Value<String?> recurrenceFrequency = const Value.absent(),
    Value<String?> recurrenceWeekdays = const Value.absent(),
    Value<String?> recurrenceUntil = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> professor = const Value.absent(),
    Value<String?> subtitle = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SeriesRow(
    id: id ?? this.id,
    revision: revision ?? this.revision,
    title: title ?? this.title,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    timeKind: timeKind ?? this.timeKind,
    startDate: startDate ?? this.startDate,
    startTime: startTime.present ? startTime.value : this.startTime,
    timeZone: timeZone.present ? timeZone.value : this.timeZone,
    endTime: endTime.present ? endTime.value : this.endTime,
    endDayOffset: endDayOffset.present ? endDayOffset.value : this.endDayOffset,
    seedTimeResolution: seedTimeResolution.present
        ? seedTimeResolution.value
        : this.seedTimeResolution,
    endTimeResolution: endTimeResolution.present
        ? endTimeResolution.value
        : this.endTimeResolution,
    endDateExclusive: endDateExclusive.present
        ? endDateExclusive.value
        : this.endDateExclusive,
    recurrenceFrequency: recurrenceFrequency.present
        ? recurrenceFrequency.value
        : this.recurrenceFrequency,
    recurrenceWeekdays: recurrenceWeekdays.present
        ? recurrenceWeekdays.value
        : this.recurrenceWeekdays,
    recurrenceUntil: recurrenceUntil.present
        ? recurrenceUntil.value
        : this.recurrenceUntil,
    location: location.present ? location.value : this.location,
    professor: professor.present ? professor.value : this.professor,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SeriesRow copyWithCompanion(ScheduleSeriesTableCompanion data) {
    return SeriesRow(
      id: data.id.present ? data.id.value : this.id,
      revision: data.revision.present ? data.revision.value : this.revision,
      title: data.title.present ? data.title.value : this.title,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      timeKind: data.timeKind.present ? data.timeKind.value : this.timeKind,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      endDayOffset: data.endDayOffset.present
          ? data.endDayOffset.value
          : this.endDayOffset,
      seedTimeResolution: data.seedTimeResolution.present
          ? data.seedTimeResolution.value
          : this.seedTimeResolution,
      endTimeResolution: data.endTimeResolution.present
          ? data.endTimeResolution.value
          : this.endTimeResolution,
      endDateExclusive: data.endDateExclusive.present
          ? data.endDateExclusive.value
          : this.endDateExclusive,
      recurrenceFrequency: data.recurrenceFrequency.present
          ? data.recurrenceFrequency.value
          : this.recurrenceFrequency,
      recurrenceWeekdays: data.recurrenceWeekdays.present
          ? data.recurrenceWeekdays.value
          : this.recurrenceWeekdays,
      recurrenceUntil: data.recurrenceUntil.present
          ? data.recurrenceUntil.value
          : this.recurrenceUntil,
      location: data.location.present ? data.location.value : this.location,
      professor: data.professor.present ? data.professor.value : this.professor,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRow(')
          ..write('id: $id, ')
          ..write('revision: $revision, ')
          ..write('title: $title, ')
          ..write('categoryId: $categoryId, ')
          ..write('timeKind: $timeKind, ')
          ..write('startDate: $startDate, ')
          ..write('startTime: $startTime, ')
          ..write('timeZone: $timeZone, ')
          ..write('endTime: $endTime, ')
          ..write('endDayOffset: $endDayOffset, ')
          ..write('seedTimeResolution: $seedTimeResolution, ')
          ..write('endTimeResolution: $endTimeResolution, ')
          ..write('endDateExclusive: $endDateExclusive, ')
          ..write('recurrenceFrequency: $recurrenceFrequency, ')
          ..write('recurrenceWeekdays: $recurrenceWeekdays, ')
          ..write('recurrenceUntil: $recurrenceUntil, ')
          ..write('location: $location, ')
          ..write('professor: $professor, ')
          ..write('subtitle: $subtitle, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    revision,
    title,
    categoryId,
    timeKind,
    startDate,
    startTime,
    timeZone,
    endTime,
    endDayOffset,
    seedTimeResolution,
    endTimeResolution,
    endDateExclusive,
    recurrenceFrequency,
    recurrenceWeekdays,
    recurrenceUntil,
    location,
    professor,
    subtitle,
    notes,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRow &&
          other.id == this.id &&
          other.revision == this.revision &&
          other.title == this.title &&
          other.categoryId == this.categoryId &&
          other.timeKind == this.timeKind &&
          other.startDate == this.startDate &&
          other.startTime == this.startTime &&
          other.timeZone == this.timeZone &&
          other.endTime == this.endTime &&
          other.endDayOffset == this.endDayOffset &&
          other.seedTimeResolution == this.seedTimeResolution &&
          other.endTimeResolution == this.endTimeResolution &&
          other.endDateExclusive == this.endDateExclusive &&
          other.recurrenceFrequency == this.recurrenceFrequency &&
          other.recurrenceWeekdays == this.recurrenceWeekdays &&
          other.recurrenceUntil == this.recurrenceUntil &&
          other.location == this.location &&
          other.professor == this.professor &&
          other.subtitle == this.subtitle &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScheduleSeriesTableCompanion extends UpdateCompanion<SeriesRow> {
  final Value<String> id;
  final Value<int> revision;
  final Value<String> title;
  final Value<String?> categoryId;
  final Value<String> timeKind;
  final Value<String> startDate;
  final Value<String?> startTime;
  final Value<String?> timeZone;
  final Value<String?> endTime;
  final Value<int?> endDayOffset;
  final Value<String?> seedTimeResolution;
  final Value<String?> endTimeResolution;
  final Value<String?> endDateExclusive;
  final Value<String?> recurrenceFrequency;
  final Value<String?> recurrenceWeekdays;
  final Value<String?> recurrenceUntil;
  final Value<String?> location;
  final Value<String?> professor;
  final Value<String?> subtitle;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ScheduleSeriesTableCompanion({
    this.id = const Value.absent(),
    this.revision = const Value.absent(),
    this.title = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.timeKind = const Value.absent(),
    this.startDate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.endTime = const Value.absent(),
    this.endDayOffset = const Value.absent(),
    this.seedTimeResolution = const Value.absent(),
    this.endTimeResolution = const Value.absent(),
    this.endDateExclusive = const Value.absent(),
    this.recurrenceFrequency = const Value.absent(),
    this.recurrenceWeekdays = const Value.absent(),
    this.recurrenceUntil = const Value.absent(),
    this.location = const Value.absent(),
    this.professor = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduleSeriesTableCompanion.insert({
    required String id,
    required int revision,
    required String title,
    this.categoryId = const Value.absent(),
    required String timeKind,
    required String startDate,
    this.startTime = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.endTime = const Value.absent(),
    this.endDayOffset = const Value.absent(),
    this.seedTimeResolution = const Value.absent(),
    this.endTimeResolution = const Value.absent(),
    this.endDateExclusive = const Value.absent(),
    this.recurrenceFrequency = const Value.absent(),
    this.recurrenceWeekdays = const Value.absent(),
    this.recurrenceUntil = const Value.absent(),
    this.location = const Value.absent(),
    this.professor = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       revision = Value(revision),
       title = Value(title),
       timeKind = Value(timeKind),
       startDate = Value(startDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SeriesRow> custom({
    Expression<String>? id,
    Expression<int>? revision,
    Expression<String>? title,
    Expression<String>? categoryId,
    Expression<String>? timeKind,
    Expression<String>? startDate,
    Expression<String>? startTime,
    Expression<String>? timeZone,
    Expression<String>? endTime,
    Expression<int>? endDayOffset,
    Expression<String>? seedTimeResolution,
    Expression<String>? endTimeResolution,
    Expression<String>? endDateExclusive,
    Expression<String>? recurrenceFrequency,
    Expression<String>? recurrenceWeekdays,
    Expression<String>? recurrenceUntil,
    Expression<String>? location,
    Expression<String>? professor,
    Expression<String>? subtitle,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (revision != null) 'revision': revision,
      if (title != null) 'title': title,
      if (categoryId != null) 'category_id': categoryId,
      if (timeKind != null) 'time_kind': timeKind,
      if (startDate != null) 'start_date': startDate,
      if (startTime != null) 'start_time': startTime,
      if (timeZone != null) 'time_zone': timeZone,
      if (endTime != null) 'end_time': endTime,
      if (endDayOffset != null) 'end_day_offset': endDayOffset,
      if (seedTimeResolution != null)
        'seed_time_resolution': seedTimeResolution,
      if (endTimeResolution != null) 'end_time_resolution': endTimeResolution,
      if (endDateExclusive != null) 'end_date_exclusive': endDateExclusive,
      if (recurrenceFrequency != null)
        'recurrence_frequency': recurrenceFrequency,
      if (recurrenceWeekdays != null) 'recurrence_weekdays': recurrenceWeekdays,
      if (recurrenceUntil != null) 'recurrence_until': recurrenceUntil,
      if (location != null) 'location': location,
      if (professor != null) 'professor': professor,
      if (subtitle != null) 'subtitle': subtitle,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduleSeriesTableCompanion copyWith({
    Value<String>? id,
    Value<int>? revision,
    Value<String>? title,
    Value<String?>? categoryId,
    Value<String>? timeKind,
    Value<String>? startDate,
    Value<String?>? startTime,
    Value<String?>? timeZone,
    Value<String?>? endTime,
    Value<int?>? endDayOffset,
    Value<String?>? seedTimeResolution,
    Value<String?>? endTimeResolution,
    Value<String?>? endDateExclusive,
    Value<String?>? recurrenceFrequency,
    Value<String?>? recurrenceWeekdays,
    Value<String?>? recurrenceUntil,
    Value<String?>? location,
    Value<String?>? professor,
    Value<String?>? subtitle,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ScheduleSeriesTableCompanion(
      id: id ?? this.id,
      revision: revision ?? this.revision,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      timeKind: timeKind ?? this.timeKind,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      timeZone: timeZone ?? this.timeZone,
      endTime: endTime ?? this.endTime,
      endDayOffset: endDayOffset ?? this.endDayOffset,
      seedTimeResolution: seedTimeResolution ?? this.seedTimeResolution,
      endTimeResolution: endTimeResolution ?? this.endTimeResolution,
      endDateExclusive: endDateExclusive ?? this.endDateExclusive,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceWeekdays: recurrenceWeekdays ?? this.recurrenceWeekdays,
      recurrenceUntil: recurrenceUntil ?? this.recurrenceUntil,
      location: location ?? this.location,
      professor: professor ?? this.professor,
      subtitle: subtitle ?? this.subtitle,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (timeKind.present) {
      map['time_kind'] = Variable<String>(timeKind.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (endDayOffset.present) {
      map['end_day_offset'] = Variable<int>(endDayOffset.value);
    }
    if (seedTimeResolution.present) {
      map['seed_time_resolution'] = Variable<String>(seedTimeResolution.value);
    }
    if (endTimeResolution.present) {
      map['end_time_resolution'] = Variable<String>(endTimeResolution.value);
    }
    if (endDateExclusive.present) {
      map['end_date_exclusive'] = Variable<String>(endDateExclusive.value);
    }
    if (recurrenceFrequency.present) {
      map['recurrence_frequency'] = Variable<String>(recurrenceFrequency.value);
    }
    if (recurrenceWeekdays.present) {
      map['recurrence_weekdays'] = Variable<String>(recurrenceWeekdays.value);
    }
    if (recurrenceUntil.present) {
      map['recurrence_until'] = Variable<String>(recurrenceUntil.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (professor.present) {
      map['professor'] = Variable<String>(professor.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleSeriesTableCompanion(')
          ..write('id: $id, ')
          ..write('revision: $revision, ')
          ..write('title: $title, ')
          ..write('categoryId: $categoryId, ')
          ..write('timeKind: $timeKind, ')
          ..write('startDate: $startDate, ')
          ..write('startTime: $startTime, ')
          ..write('timeZone: $timeZone, ')
          ..write('endTime: $endTime, ')
          ..write('endDayOffset: $endDayOffset, ')
          ..write('seedTimeResolution: $seedTimeResolution, ')
          ..write('endTimeResolution: $endTimeResolution, ')
          ..write('endDateExclusive: $endDateExclusive, ')
          ..write('recurrenceFrequency: $recurrenceFrequency, ')
          ..write('recurrenceWeekdays: $recurrenceWeekdays, ')
          ..write('recurrenceUntil: $recurrenceUntil, ')
          ..write('location: $location, ')
          ..write('professor: $professor, ')
          ..write('subtitle: $subtitle, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OccurrenceExceptionsTable extends OccurrenceExceptions
    with TableInfo<$OccurrenceExceptionsTable, ExceptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrenceExceptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES schedule_series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _originalKeyMeta = const VerificationMeta(
    'originalKey',
  );
  @override
  late final GeneratedColumn<String> originalKey = GeneratedColumn<String>(
    'original_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replacementJsonMeta = const VerificationMeta(
    'replacementJson',
  );
  @override
  late final GeneratedColumn<String> replacementJson = GeneratedColumn<String>(
    'replacement_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesId,
    originalKey,
    action,
    replacementJson,
    revision,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrence_exceptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExceptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('original_key')) {
      context.handle(
        _originalKeyMeta,
        originalKey.isAcceptableOrUnknown(
          data['original_key']!,
          _originalKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalKeyMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('replacement_json')) {
      context.handle(
        _replacementJsonMeta,
        replacementJson.isAcceptableOrUnknown(
          data['replacement_json']!,
          _replacementJsonMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {seriesId, originalKey},
  ];
  @override
  ExceptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExceptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      originalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_key'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      replacementJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replacement_json'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OccurrenceExceptionsTable createAlias(String alias) {
    return $OccurrenceExceptionsTable(attachedDatabase, alias);
  }
}

class ExceptionRow extends DataClass implements Insertable<ExceptionRow> {
  final String id;
  final String seriesId;
  final String originalKey;
  final String action;
  final String? replacementJson;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExceptionRow({
    required this.id,
    required this.seriesId,
    required this.originalKey,
    required this.action,
    this.replacementJson,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['series_id'] = Variable<String>(seriesId);
    map['original_key'] = Variable<String>(originalKey);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || replacementJson != null) {
      map['replacement_json'] = Variable<String>(replacementJson);
    }
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OccurrenceExceptionsCompanion toCompanion(bool nullToAbsent) {
    return OccurrenceExceptionsCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      originalKey: Value(originalKey),
      action: Value(action),
      replacementJson: replacementJson == null && nullToAbsent
          ? const Value.absent()
          : Value(replacementJson),
      revision: Value(revision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExceptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExceptionRow(
      id: serializer.fromJson<String>(json['id']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      originalKey: serializer.fromJson<String>(json['originalKey']),
      action: serializer.fromJson<String>(json['action']),
      replacementJson: serializer.fromJson<String?>(json['replacementJson']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seriesId': serializer.toJson<String>(seriesId),
      'originalKey': serializer.toJson<String>(originalKey),
      'action': serializer.toJson<String>(action),
      'replacementJson': serializer.toJson<String?>(replacementJson),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExceptionRow copyWith({
    String? id,
    String? seriesId,
    String? originalKey,
    String? action,
    Value<String?> replacementJson = const Value.absent(),
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExceptionRow(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    originalKey: originalKey ?? this.originalKey,
    action: action ?? this.action,
    replacementJson: replacementJson.present
        ? replacementJson.value
        : this.replacementJson,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExceptionRow copyWithCompanion(OccurrenceExceptionsCompanion data) {
    return ExceptionRow(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      originalKey: data.originalKey.present
          ? data.originalKey.value
          : this.originalKey,
      action: data.action.present ? data.action.value : this.action,
      replacementJson: data.replacementJson.present
          ? data.replacementJson.value
          : this.replacementJson,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExceptionRow(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('originalKey: $originalKey, ')
          ..write('action: $action, ')
          ..write('replacementJson: $replacementJson, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seriesId,
    originalKey,
    action,
    replacementJson,
    revision,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExceptionRow &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.originalKey == this.originalKey &&
          other.action == this.action &&
          other.replacementJson == this.replacementJson &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OccurrenceExceptionsCompanion extends UpdateCompanion<ExceptionRow> {
  final Value<String> id;
  final Value<String> seriesId;
  final Value<String> originalKey;
  final Value<String> action;
  final Value<String?> replacementJson;
  final Value<int> revision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OccurrenceExceptionsCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.originalKey = const Value.absent(),
    this.action = const Value.absent(),
    this.replacementJson = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccurrenceExceptionsCompanion.insert({
    required String id,
    required String seriesId,
    required String originalKey,
    required String action,
    this.replacementJson = const Value.absent(),
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seriesId = Value(seriesId),
       originalKey = Value(originalKey),
       action = Value(action),
       revision = Value(revision),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExceptionRow> custom({
    Expression<String>? id,
    Expression<String>? seriesId,
    Expression<String>? originalKey,
    Expression<String>? action,
    Expression<String>? replacementJson,
    Expression<int>? revision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (originalKey != null) 'original_key': originalKey,
      if (action != null) 'action': action,
      if (replacementJson != null) 'replacement_json': replacementJson,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccurrenceExceptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? seriesId,
    Value<String>? originalKey,
    Value<String>? action,
    Value<String?>? replacementJson,
    Value<int>? revision,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OccurrenceExceptionsCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      originalKey: originalKey ?? this.originalKey,
      action: action ?? this.action,
      replacementJson: replacementJson ?? this.replacementJson,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (originalKey.present) {
      map['original_key'] = Variable<String>(originalKey.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (replacementJson.present) {
      map['replacement_json'] = Variable<String>(replacementJson.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceExceptionsCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('originalKey: $originalKey, ')
          ..write('action: $action, ')
          ..write('replacementJson: $replacementJson, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertRulesTable extends AlertRules
    with TableInfo<$AlertRulesTable, AlertRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES schedule_series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('*'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateOnlyAnchorTimeMeta =
      const VerificationMeta('dateOnlyAnchorTime');
  @override
  late final GeneratedColumn<String> dateOnlyAnchorTime =
      GeneratedColumn<String>(
        'date_only_anchor_time',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dateOnlyAnchorZoneMeta =
      const VerificationMeta('dateOnlyAnchorZone');
  @override
  late final GeneratedColumn<String> dateOnlyAnchorZone =
      GeneratedColumn<String>(
        'date_only_anchor_zone',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lockScreenDetailsMeta = const VerificationMeta(
    'lockScreenDetails',
  );
  @override
  late final GeneratedColumn<String> lockScreenDetails =
      GeneratedColumn<String>(
        'lock_screen_details',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _presentationPreferenceMeta =
      const VerificationMeta('presentationPreference');
  @override
  late final GeneratedColumn<String> presentationPreference =
      GeneratedColumn<String>(
        'presentation_preference',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _snoozeMinutesMeta = const VerificationMeta(
    'snoozeMinutes',
  );
  @override
  late final GeneratedColumn<int> snoozeMinutes = GeneratedColumn<int>(
    'snooze_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesId,
    scopeKey,
    kind,
    enabled,
    offsetMinutes,
    dateOnlyAnchorTime,
    dateOnlyAnchorZone,
    lockScreenDetails,
    presentationPreference,
    snoozeMinutes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alert_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlertRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offsetMinutesMeta);
    }
    if (data.containsKey('date_only_anchor_time')) {
      context.handle(
        _dateOnlyAnchorTimeMeta,
        dateOnlyAnchorTime.isAcceptableOrUnknown(
          data['date_only_anchor_time']!,
          _dateOnlyAnchorTimeMeta,
        ),
      );
    }
    if (data.containsKey('date_only_anchor_zone')) {
      context.handle(
        _dateOnlyAnchorZoneMeta,
        dateOnlyAnchorZone.isAcceptableOrUnknown(
          data['date_only_anchor_zone']!,
          _dateOnlyAnchorZoneMeta,
        ),
      );
    }
    if (data.containsKey('lock_screen_details')) {
      context.handle(
        _lockScreenDetailsMeta,
        lockScreenDetails.isAcceptableOrUnknown(
          data['lock_screen_details']!,
          _lockScreenDetailsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lockScreenDetailsMeta);
    }
    if (data.containsKey('presentation_preference')) {
      context.handle(
        _presentationPreferenceMeta,
        presentationPreference.isAcceptableOrUnknown(
          data['presentation_preference']!,
          _presentationPreferenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_presentationPreferenceMeta);
    }
    if (data.containsKey('snooze_minutes')) {
      context.handle(
        _snoozeMinutesMeta,
        snoozeMinutes.isAcceptableOrUnknown(
          data['snooze_minutes']!,
          _snoozeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {seriesId, scopeKey, kind},
  ];
  @override
  AlertRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      )!,
      dateOnlyAnchorTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_only_anchor_time'],
      ),
      dateOnlyAnchorZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_only_anchor_zone'],
      ),
      lockScreenDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lock_screen_details'],
      )!,
      presentationPreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}presentation_preference'],
      )!,
      snoozeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_minutes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AlertRulesTable createAlias(String alias) {
    return $AlertRulesTable(attachedDatabase, alias);
  }
}

class AlertRuleRow extends DataClass implements Insertable<AlertRuleRow> {
  final String id;
  final String seriesId;
  final String scopeKey;
  final String kind;
  final bool enabled;
  final int offsetMinutes;
  final String? dateOnlyAnchorTime;
  final String? dateOnlyAnchorZone;
  final String lockScreenDetails;
  final String presentationPreference;
  final int? snoozeMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AlertRuleRow({
    required this.id,
    required this.seriesId,
    required this.scopeKey,
    required this.kind,
    required this.enabled,
    required this.offsetMinutes,
    this.dateOnlyAnchorTime,
    this.dateOnlyAnchorZone,
    required this.lockScreenDetails,
    required this.presentationPreference,
    this.snoozeMinutes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['series_id'] = Variable<String>(seriesId);
    map['scope_key'] = Variable<String>(scopeKey);
    map['kind'] = Variable<String>(kind);
    map['enabled'] = Variable<bool>(enabled);
    map['offset_minutes'] = Variable<int>(offsetMinutes);
    if (!nullToAbsent || dateOnlyAnchorTime != null) {
      map['date_only_anchor_time'] = Variable<String>(dateOnlyAnchorTime);
    }
    if (!nullToAbsent || dateOnlyAnchorZone != null) {
      map['date_only_anchor_zone'] = Variable<String>(dateOnlyAnchorZone);
    }
    map['lock_screen_details'] = Variable<String>(lockScreenDetails);
    map['presentation_preference'] = Variable<String>(presentationPreference);
    if (!nullToAbsent || snoozeMinutes != null) {
      map['snooze_minutes'] = Variable<int>(snoozeMinutes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AlertRulesCompanion toCompanion(bool nullToAbsent) {
    return AlertRulesCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      scopeKey: Value(scopeKey),
      kind: Value(kind),
      enabled: Value(enabled),
      offsetMinutes: Value(offsetMinutes),
      dateOnlyAnchorTime: dateOnlyAnchorTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOnlyAnchorTime),
      dateOnlyAnchorZone: dateOnlyAnchorZone == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOnlyAnchorZone),
      lockScreenDetails: Value(lockScreenDetails),
      presentationPreference: Value(presentationPreference),
      snoozeMinutes: snoozeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozeMinutes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AlertRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertRuleRow(
      id: serializer.fromJson<String>(json['id']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      kind: serializer.fromJson<String>(json['kind']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      offsetMinutes: serializer.fromJson<int>(json['offsetMinutes']),
      dateOnlyAnchorTime: serializer.fromJson<String?>(
        json['dateOnlyAnchorTime'],
      ),
      dateOnlyAnchorZone: serializer.fromJson<String?>(
        json['dateOnlyAnchorZone'],
      ),
      lockScreenDetails: serializer.fromJson<String>(json['lockScreenDetails']),
      presentationPreference: serializer.fromJson<String>(
        json['presentationPreference'],
      ),
      snoozeMinutes: serializer.fromJson<int?>(json['snoozeMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seriesId': serializer.toJson<String>(seriesId),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'kind': serializer.toJson<String>(kind),
      'enabled': serializer.toJson<bool>(enabled),
      'offsetMinutes': serializer.toJson<int>(offsetMinutes),
      'dateOnlyAnchorTime': serializer.toJson<String?>(dateOnlyAnchorTime),
      'dateOnlyAnchorZone': serializer.toJson<String?>(dateOnlyAnchorZone),
      'lockScreenDetails': serializer.toJson<String>(lockScreenDetails),
      'presentationPreference': serializer.toJson<String>(
        presentationPreference,
      ),
      'snoozeMinutes': serializer.toJson<int?>(snoozeMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AlertRuleRow copyWith({
    String? id,
    String? seriesId,
    String? scopeKey,
    String? kind,
    bool? enabled,
    int? offsetMinutes,
    Value<String?> dateOnlyAnchorTime = const Value.absent(),
    Value<String?> dateOnlyAnchorZone = const Value.absent(),
    String? lockScreenDetails,
    String? presentationPreference,
    Value<int?> snoozeMinutes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AlertRuleRow(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    scopeKey: scopeKey ?? this.scopeKey,
    kind: kind ?? this.kind,
    enabled: enabled ?? this.enabled,
    offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    dateOnlyAnchorTime: dateOnlyAnchorTime.present
        ? dateOnlyAnchorTime.value
        : this.dateOnlyAnchorTime,
    dateOnlyAnchorZone: dateOnlyAnchorZone.present
        ? dateOnlyAnchorZone.value
        : this.dateOnlyAnchorZone,
    lockScreenDetails: lockScreenDetails ?? this.lockScreenDetails,
    presentationPreference:
        presentationPreference ?? this.presentationPreference,
    snoozeMinutes: snoozeMinutes.present
        ? snoozeMinutes.value
        : this.snoozeMinutes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AlertRuleRow copyWithCompanion(AlertRulesCompanion data) {
    return AlertRuleRow(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
      dateOnlyAnchorTime: data.dateOnlyAnchorTime.present
          ? data.dateOnlyAnchorTime.value
          : this.dateOnlyAnchorTime,
      dateOnlyAnchorZone: data.dateOnlyAnchorZone.present
          ? data.dateOnlyAnchorZone.value
          : this.dateOnlyAnchorZone,
      lockScreenDetails: data.lockScreenDetails.present
          ? data.lockScreenDetails.value
          : this.lockScreenDetails,
      presentationPreference: data.presentationPreference.present
          ? data.presentationPreference.value
          : this.presentationPreference,
      snoozeMinutes: data.snoozeMinutes.present
          ? data.snoozeMinutes.value
          : this.snoozeMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertRuleRow(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('kind: $kind, ')
          ..write('enabled: $enabled, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('dateOnlyAnchorTime: $dateOnlyAnchorTime, ')
          ..write('dateOnlyAnchorZone: $dateOnlyAnchorZone, ')
          ..write('lockScreenDetails: $lockScreenDetails, ')
          ..write('presentationPreference: $presentationPreference, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seriesId,
    scopeKey,
    kind,
    enabled,
    offsetMinutes,
    dateOnlyAnchorTime,
    dateOnlyAnchorZone,
    lockScreenDetails,
    presentationPreference,
    snoozeMinutes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertRuleRow &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.scopeKey == this.scopeKey &&
          other.kind == this.kind &&
          other.enabled == this.enabled &&
          other.offsetMinutes == this.offsetMinutes &&
          other.dateOnlyAnchorTime == this.dateOnlyAnchorTime &&
          other.dateOnlyAnchorZone == this.dateOnlyAnchorZone &&
          other.lockScreenDetails == this.lockScreenDetails &&
          other.presentationPreference == this.presentationPreference &&
          other.snoozeMinutes == this.snoozeMinutes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AlertRulesCompanion extends UpdateCompanion<AlertRuleRow> {
  final Value<String> id;
  final Value<String> seriesId;
  final Value<String> scopeKey;
  final Value<String> kind;
  final Value<bool> enabled;
  final Value<int> offsetMinutes;
  final Value<String?> dateOnlyAnchorTime;
  final Value<String?> dateOnlyAnchorZone;
  final Value<String> lockScreenDetails;
  final Value<String> presentationPreference;
  final Value<int?> snoozeMinutes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AlertRulesCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.enabled = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.dateOnlyAnchorTime = const Value.absent(),
    this.dateOnlyAnchorZone = const Value.absent(),
    this.lockScreenDetails = const Value.absent(),
    this.presentationPreference = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertRulesCompanion.insert({
    required String id,
    required String seriesId,
    this.scopeKey = const Value.absent(),
    required String kind,
    required bool enabled,
    required int offsetMinutes,
    this.dateOnlyAnchorTime = const Value.absent(),
    this.dateOnlyAnchorZone = const Value.absent(),
    required String lockScreenDetails,
    required String presentationPreference,
    this.snoozeMinutes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seriesId = Value(seriesId),
       kind = Value(kind),
       enabled = Value(enabled),
       offsetMinutes = Value(offsetMinutes),
       lockScreenDetails = Value(lockScreenDetails),
       presentationPreference = Value(presentationPreference),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AlertRuleRow> custom({
    Expression<String>? id,
    Expression<String>? seriesId,
    Expression<String>? scopeKey,
    Expression<String>? kind,
    Expression<bool>? enabled,
    Expression<int>? offsetMinutes,
    Expression<String>? dateOnlyAnchorTime,
    Expression<String>? dateOnlyAnchorZone,
    Expression<String>? lockScreenDetails,
    Expression<String>? presentationPreference,
    Expression<int>? snoozeMinutes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (kind != null) 'kind': kind,
      if (enabled != null) 'enabled': enabled,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (dateOnlyAnchorTime != null)
        'date_only_anchor_time': dateOnlyAnchorTime,
      if (dateOnlyAnchorZone != null)
        'date_only_anchor_zone': dateOnlyAnchorZone,
      if (lockScreenDetails != null) 'lock_screen_details': lockScreenDetails,
      if (presentationPreference != null)
        'presentation_preference': presentationPreference,
      if (snoozeMinutes != null) 'snooze_minutes': snoozeMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? seriesId,
    Value<String>? scopeKey,
    Value<String>? kind,
    Value<bool>? enabled,
    Value<int>? offsetMinutes,
    Value<String?>? dateOnlyAnchorTime,
    Value<String?>? dateOnlyAnchorZone,
    Value<String>? lockScreenDetails,
    Value<String>? presentationPreference,
    Value<int?>? snoozeMinutes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AlertRulesCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      scopeKey: scopeKey ?? this.scopeKey,
      kind: kind ?? this.kind,
      enabled: enabled ?? this.enabled,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      dateOnlyAnchorTime: dateOnlyAnchorTime ?? this.dateOnlyAnchorTime,
      dateOnlyAnchorZone: dateOnlyAnchorZone ?? this.dateOnlyAnchorZone,
      lockScreenDetails: lockScreenDetails ?? this.lockScreenDetails,
      presentationPreference:
          presentationPreference ?? this.presentationPreference,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (dateOnlyAnchorTime.present) {
      map['date_only_anchor_time'] = Variable<String>(dateOnlyAnchorTime.value);
    }
    if (dateOnlyAnchorZone.present) {
      map['date_only_anchor_zone'] = Variable<String>(dateOnlyAnchorZone.value);
    }
    if (lockScreenDetails.present) {
      map['lock_screen_details'] = Variable<String>(lockScreenDetails.value);
    }
    if (presentationPreference.present) {
      map['presentation_preference'] = Variable<String>(
        presentationPreference.value,
      );
    }
    if (snoozeMinutes.present) {
      map['snooze_minutes'] = Variable<int>(snoozeMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertRulesCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('kind: $kind, ')
          ..write('enabled: $enabled, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('dateOnlyAnchorTime: $dateOnlyAnchorTime, ')
          ..write('dateOnlyAnchorZone: $dateOnlyAnchorZone, ')
          ..write('lockScreenDetails: $lockScreenDetails, ')
          ..write('presentationPreference: $presentationPreference, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduledAlertsTable extends ScheduledAlerts
    with TableInfo<$ScheduledAlertsTable, ScheduledAlertRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduledAlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _requestKeyMeta = const VerificationMeta(
    'requestKey',
  );
  @override
  late final GeneratedColumn<String> requestKey = GeneratedColumn<String>(
    'request_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceKeyMeta = const VerificationMeta(
    'occurrenceKey',
  );
  @override
  late final GeneratedColumn<String> occurrenceKey = GeneratedColumn<String>(
    'occurrence_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRevisionMeta = const VerificationMeta(
    'sourceRevision',
  );
  @override
  late final GeneratedColumn<int> sourceRevision = GeneratedColumn<int>(
    'source_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nativeRequestIdMeta = const VerificationMeta(
    'nativeRequestId',
  );
  @override
  late final GeneratedColumn<String> nativeRequestId = GeneratedColumn<String>(
    'native_request_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triggerAtMeta = const VerificationMeta(
    'triggerAt',
  );
  @override
  late final GeneratedColumn<DateTime> triggerAt = GeneratedColumn<DateTime>(
    'trigger_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReconciledAtMeta = const VerificationMeta(
    'lastReconciledAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReconciledAt =
      GeneratedColumn<DateTime>(
        'last_reconciled_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    requestKey,
    ruleId,
    seriesId,
    occurrenceKey,
    kind,
    platform,
    sourceRevision,
    nativeRequestId,
    triggerAt,
    status,
    errorCode,
    lastReconciledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduled_alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduledAlertRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('request_key')) {
      context.handle(
        _requestKeyMeta,
        requestKey.isAcceptableOrUnknown(data['request_key']!, _requestKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_requestKeyMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('occurrence_key')) {
      context.handle(
        _occurrenceKeyMeta,
        occurrenceKey.isAcceptableOrUnknown(
          data['occurrence_key']!,
          _occurrenceKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('source_revision')) {
      context.handle(
        _sourceRevisionMeta,
        sourceRevision.isAcceptableOrUnknown(
          data['source_revision']!,
          _sourceRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRevisionMeta);
    }
    if (data.containsKey('native_request_id')) {
      context.handle(
        _nativeRequestIdMeta,
        nativeRequestId.isAcceptableOrUnknown(
          data['native_request_id']!,
          _nativeRequestIdMeta,
        ),
      );
    }
    if (data.containsKey('trigger_at')) {
      context.handle(
        _triggerAtMeta,
        triggerAt.isAcceptableOrUnknown(data['trigger_at']!, _triggerAtMeta),
      );
    } else if (isInserting) {
      context.missing(_triggerAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('last_reconciled_at')) {
      context.handle(
        _lastReconciledAtMeta,
        lastReconciledAt.isAcceptableOrUnknown(
          data['last_reconciled_at']!,
          _lastReconciledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastReconciledAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {requestKey};
  @override
  ScheduledAlertRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduledAlertRow(
      requestKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_key'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      occurrenceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      sourceRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_revision'],
      )!,
      nativeRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}native_request_id'],
      ),
      triggerAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}trigger_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      lastReconciledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reconciled_at'],
      )!,
    );
  }

  @override
  $ScheduledAlertsTable createAlias(String alias) {
    return $ScheduledAlertsTable(attachedDatabase, alias);
  }
}

class ScheduledAlertRow extends DataClass
    implements Insertable<ScheduledAlertRow> {
  final String requestKey;

  /// Not a foreign key: rows outlive a deleted rule until reconciliation
  /// cancels the native request they describe.
  final String ruleId;
  final String seriesId;
  final String occurrenceKey;
  final String kind;
  final String platform;
  final int sourceRevision;
  final String? nativeRequestId;
  final DateTime triggerAt;
  final String status;
  final String? errorCode;
  final DateTime lastReconciledAt;
  const ScheduledAlertRow({
    required this.requestKey,
    required this.ruleId,
    required this.seriesId,
    required this.occurrenceKey,
    required this.kind,
    required this.platform,
    required this.sourceRevision,
    this.nativeRequestId,
    required this.triggerAt,
    required this.status,
    this.errorCode,
    required this.lastReconciledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['request_key'] = Variable<String>(requestKey);
    map['rule_id'] = Variable<String>(ruleId);
    map['series_id'] = Variable<String>(seriesId);
    map['occurrence_key'] = Variable<String>(occurrenceKey);
    map['kind'] = Variable<String>(kind);
    map['platform'] = Variable<String>(platform);
    map['source_revision'] = Variable<int>(sourceRevision);
    if (!nullToAbsent || nativeRequestId != null) {
      map['native_request_id'] = Variable<String>(nativeRequestId);
    }
    map['trigger_at'] = Variable<DateTime>(triggerAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    map['last_reconciled_at'] = Variable<DateTime>(lastReconciledAt);
    return map;
  }

  ScheduledAlertsCompanion toCompanion(bool nullToAbsent) {
    return ScheduledAlertsCompanion(
      requestKey: Value(requestKey),
      ruleId: Value(ruleId),
      seriesId: Value(seriesId),
      occurrenceKey: Value(occurrenceKey),
      kind: Value(kind),
      platform: Value(platform),
      sourceRevision: Value(sourceRevision),
      nativeRequestId: nativeRequestId == null && nullToAbsent
          ? const Value.absent()
          : Value(nativeRequestId),
      triggerAt: Value(triggerAt),
      status: Value(status),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      lastReconciledAt: Value(lastReconciledAt),
    );
  }

  factory ScheduledAlertRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduledAlertRow(
      requestKey: serializer.fromJson<String>(json['requestKey']),
      ruleId: serializer.fromJson<String>(json['ruleId']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      occurrenceKey: serializer.fromJson<String>(json['occurrenceKey']),
      kind: serializer.fromJson<String>(json['kind']),
      platform: serializer.fromJson<String>(json['platform']),
      sourceRevision: serializer.fromJson<int>(json['sourceRevision']),
      nativeRequestId: serializer.fromJson<String?>(json['nativeRequestId']),
      triggerAt: serializer.fromJson<DateTime>(json['triggerAt']),
      status: serializer.fromJson<String>(json['status']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      lastReconciledAt: serializer.fromJson<DateTime>(json['lastReconciledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'requestKey': serializer.toJson<String>(requestKey),
      'ruleId': serializer.toJson<String>(ruleId),
      'seriesId': serializer.toJson<String>(seriesId),
      'occurrenceKey': serializer.toJson<String>(occurrenceKey),
      'kind': serializer.toJson<String>(kind),
      'platform': serializer.toJson<String>(platform),
      'sourceRevision': serializer.toJson<int>(sourceRevision),
      'nativeRequestId': serializer.toJson<String?>(nativeRequestId),
      'triggerAt': serializer.toJson<DateTime>(triggerAt),
      'status': serializer.toJson<String>(status),
      'errorCode': serializer.toJson<String?>(errorCode),
      'lastReconciledAt': serializer.toJson<DateTime>(lastReconciledAt),
    };
  }

  ScheduledAlertRow copyWith({
    String? requestKey,
    String? ruleId,
    String? seriesId,
    String? occurrenceKey,
    String? kind,
    String? platform,
    int? sourceRevision,
    Value<String?> nativeRequestId = const Value.absent(),
    DateTime? triggerAt,
    String? status,
    Value<String?> errorCode = const Value.absent(),
    DateTime? lastReconciledAt,
  }) => ScheduledAlertRow(
    requestKey: requestKey ?? this.requestKey,
    ruleId: ruleId ?? this.ruleId,
    seriesId: seriesId ?? this.seriesId,
    occurrenceKey: occurrenceKey ?? this.occurrenceKey,
    kind: kind ?? this.kind,
    platform: platform ?? this.platform,
    sourceRevision: sourceRevision ?? this.sourceRevision,
    nativeRequestId: nativeRequestId.present
        ? nativeRequestId.value
        : this.nativeRequestId,
    triggerAt: triggerAt ?? this.triggerAt,
    status: status ?? this.status,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    lastReconciledAt: lastReconciledAt ?? this.lastReconciledAt,
  );
  ScheduledAlertRow copyWithCompanion(ScheduledAlertsCompanion data) {
    return ScheduledAlertRow(
      requestKey: data.requestKey.present
          ? data.requestKey.value
          : this.requestKey,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      occurrenceKey: data.occurrenceKey.present
          ? data.occurrenceKey.value
          : this.occurrenceKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      platform: data.platform.present ? data.platform.value : this.platform,
      sourceRevision: data.sourceRevision.present
          ? data.sourceRevision.value
          : this.sourceRevision,
      nativeRequestId: data.nativeRequestId.present
          ? data.nativeRequestId.value
          : this.nativeRequestId,
      triggerAt: data.triggerAt.present ? data.triggerAt.value : this.triggerAt,
      status: data.status.present ? data.status.value : this.status,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      lastReconciledAt: data.lastReconciledAt.present
          ? data.lastReconciledAt.value
          : this.lastReconciledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledAlertRow(')
          ..write('requestKey: $requestKey, ')
          ..write('ruleId: $ruleId, ')
          ..write('seriesId: $seriesId, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('kind: $kind, ')
          ..write('platform: $platform, ')
          ..write('sourceRevision: $sourceRevision, ')
          ..write('nativeRequestId: $nativeRequestId, ')
          ..write('triggerAt: $triggerAt, ')
          ..write('status: $status, ')
          ..write('errorCode: $errorCode, ')
          ..write('lastReconciledAt: $lastReconciledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    requestKey,
    ruleId,
    seriesId,
    occurrenceKey,
    kind,
    platform,
    sourceRevision,
    nativeRequestId,
    triggerAt,
    status,
    errorCode,
    lastReconciledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledAlertRow &&
          other.requestKey == this.requestKey &&
          other.ruleId == this.ruleId &&
          other.seriesId == this.seriesId &&
          other.occurrenceKey == this.occurrenceKey &&
          other.kind == this.kind &&
          other.platform == this.platform &&
          other.sourceRevision == this.sourceRevision &&
          other.nativeRequestId == this.nativeRequestId &&
          other.triggerAt == this.triggerAt &&
          other.status == this.status &&
          other.errorCode == this.errorCode &&
          other.lastReconciledAt == this.lastReconciledAt);
}

class ScheduledAlertsCompanion extends UpdateCompanion<ScheduledAlertRow> {
  final Value<String> requestKey;
  final Value<String> ruleId;
  final Value<String> seriesId;
  final Value<String> occurrenceKey;
  final Value<String> kind;
  final Value<String> platform;
  final Value<int> sourceRevision;
  final Value<String?> nativeRequestId;
  final Value<DateTime> triggerAt;
  final Value<String> status;
  final Value<String?> errorCode;
  final Value<DateTime> lastReconciledAt;
  final Value<int> rowid;
  const ScheduledAlertsCompanion({
    this.requestKey = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.occurrenceKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.platform = const Value.absent(),
    this.sourceRevision = const Value.absent(),
    this.nativeRequestId = const Value.absent(),
    this.triggerAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.lastReconciledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduledAlertsCompanion.insert({
    required String requestKey,
    required String ruleId,
    required String seriesId,
    required String occurrenceKey,
    required String kind,
    required String platform,
    required int sourceRevision,
    this.nativeRequestId = const Value.absent(),
    required DateTime triggerAt,
    required String status,
    this.errorCode = const Value.absent(),
    required DateTime lastReconciledAt,
    this.rowid = const Value.absent(),
  }) : requestKey = Value(requestKey),
       ruleId = Value(ruleId),
       seriesId = Value(seriesId),
       occurrenceKey = Value(occurrenceKey),
       kind = Value(kind),
       platform = Value(platform),
       sourceRevision = Value(sourceRevision),
       triggerAt = Value(triggerAt),
       status = Value(status),
       lastReconciledAt = Value(lastReconciledAt);
  static Insertable<ScheduledAlertRow> custom({
    Expression<String>? requestKey,
    Expression<String>? ruleId,
    Expression<String>? seriesId,
    Expression<String>? occurrenceKey,
    Expression<String>? kind,
    Expression<String>? platform,
    Expression<int>? sourceRevision,
    Expression<String>? nativeRequestId,
    Expression<DateTime>? triggerAt,
    Expression<String>? status,
    Expression<String>? errorCode,
    Expression<DateTime>? lastReconciledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (requestKey != null) 'request_key': requestKey,
      if (ruleId != null) 'rule_id': ruleId,
      if (seriesId != null) 'series_id': seriesId,
      if (occurrenceKey != null) 'occurrence_key': occurrenceKey,
      if (kind != null) 'kind': kind,
      if (platform != null) 'platform': platform,
      if (sourceRevision != null) 'source_revision': sourceRevision,
      if (nativeRequestId != null) 'native_request_id': nativeRequestId,
      if (triggerAt != null) 'trigger_at': triggerAt,
      if (status != null) 'status': status,
      if (errorCode != null) 'error_code': errorCode,
      if (lastReconciledAt != null) 'last_reconciled_at': lastReconciledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduledAlertsCompanion copyWith({
    Value<String>? requestKey,
    Value<String>? ruleId,
    Value<String>? seriesId,
    Value<String>? occurrenceKey,
    Value<String>? kind,
    Value<String>? platform,
    Value<int>? sourceRevision,
    Value<String?>? nativeRequestId,
    Value<DateTime>? triggerAt,
    Value<String>? status,
    Value<String?>? errorCode,
    Value<DateTime>? lastReconciledAt,
    Value<int>? rowid,
  }) {
    return ScheduledAlertsCompanion(
      requestKey: requestKey ?? this.requestKey,
      ruleId: ruleId ?? this.ruleId,
      seriesId: seriesId ?? this.seriesId,
      occurrenceKey: occurrenceKey ?? this.occurrenceKey,
      kind: kind ?? this.kind,
      platform: platform ?? this.platform,
      sourceRevision: sourceRevision ?? this.sourceRevision,
      nativeRequestId: nativeRequestId ?? this.nativeRequestId,
      triggerAt: triggerAt ?? this.triggerAt,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      lastReconciledAt: lastReconciledAt ?? this.lastReconciledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (requestKey.present) {
      map['request_key'] = Variable<String>(requestKey.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (occurrenceKey.present) {
      map['occurrence_key'] = Variable<String>(occurrenceKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (sourceRevision.present) {
      map['source_revision'] = Variable<int>(sourceRevision.value);
    }
    if (nativeRequestId.present) {
      map['native_request_id'] = Variable<String>(nativeRequestId.value);
    }
    if (triggerAt.present) {
      map['trigger_at'] = Variable<DateTime>(triggerAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (lastReconciledAt.present) {
      map['last_reconciled_at'] = Variable<DateTime>(lastReconciledAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledAlertsCompanion(')
          ..write('requestKey: $requestKey, ')
          ..write('ruleId: $ruleId, ')
          ..write('seriesId: $seriesId, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('kind: $kind, ')
          ..write('platform: $platform, ')
          ..write('sourceRevision: $sourceRevision, ')
          ..write('nativeRequestId: $nativeRequestId, ')
          ..write('triggerAt: $triggerAt, ')
          ..write('status: $status, ')
          ..write('errorCode: $errorCode, ')
          ..write('lastReconciledAt: $lastReconciledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReconciliationOutboxTable extends ReconciliationOutbox
    with TableInfo<$ReconciliationOutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReconciliationOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationKeyMeta = const VerificationMeta(
    'operationKey',
  );
  @override
  late final GeneratedColumn<String> operationKey = GeneratedColumn<String>(
    'operation_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRevisionMeta = const VerificationMeta(
    'sourceRevision',
  );
  @override
  late final GeneratedColumn<int> sourceRevision = GeneratedColumn<int>(
    'source_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationKey,
    reason,
    sourceRevision,
    status,
    attempts,
    nextAttemptAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reconciliation_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_key')) {
      context.handle(
        _operationKeyMeta,
        operationKey.isAcceptableOrUnknown(
          data['operation_key']!,
          _operationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationKeyMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('source_revision')) {
      context.handle(
        _sourceRevisionMeta,
        sourceRevision.isAcceptableOrUnknown(
          data['source_revision']!,
          _sourceRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRevisionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_key'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      sourceRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_revision'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReconciliationOutboxTable createAlias(String alias) {
    return $ReconciliationOutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;
  final String operationKey;
  final String reason;
  final int sourceRevision;
  final String status;
  final int attempts;
  final DateTime? nextAttemptAt;
  final DateTime createdAt;
  const OutboxRow({
    required this.id,
    required this.operationKey,
    required this.reason,
    required this.sourceRevision,
    required this.status,
    required this.attempts,
    this.nextAttemptAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_key'] = Variable<String>(operationKey);
    map['reason'] = Variable<String>(reason);
    map['source_revision'] = Variable<int>(sourceRevision);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReconciliationOutboxCompanion toCompanion(bool nullToAbsent) {
    return ReconciliationOutboxCompanion(
      id: Value(id),
      operationKey: Value(operationKey),
      reason: Value(reason),
      sourceRevision: Value(sourceRevision),
      status: Value(status),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      operationKey: serializer.fromJson<String>(json['operationKey']),
      reason: serializer.fromJson<String>(json['reason']),
      sourceRevision: serializer.fromJson<int>(json['sourceRevision']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationKey': serializer.toJson<String>(operationKey),
      'reason': serializer.toJson<String>(reason),
      'sourceRevision': serializer.toJson<int>(sourceRevision),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? operationKey,
    String? reason,
    int? sourceRevision,
    String? status,
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    DateTime? createdAt,
  }) => OutboxRow(
    id: id ?? this.id,
    operationKey: operationKey ?? this.operationKey,
    reason: reason ?? this.reason,
    sourceRevision: sourceRevision ?? this.sourceRevision,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(ReconciliationOutboxCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      operationKey: data.operationKey.present
          ? data.operationKey.value
          : this.operationKey,
      reason: data.reason.present ? data.reason.value : this.reason,
      sourceRevision: data.sourceRevision.present
          ? data.sourceRevision.value
          : this.sourceRevision,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('operationKey: $operationKey, ')
          ..write('reason: $reason, ')
          ..write('sourceRevision: $sourceRevision, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationKey,
    reason,
    sourceRevision,
    status,
    attempts,
    nextAttemptAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.operationKey == this.operationKey &&
          other.reason == this.reason &&
          other.sourceRevision == this.sourceRevision &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.createdAt == this.createdAt);
}

class ReconciliationOutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> operationKey;
  final Value<String> reason;
  final Value<int> sourceRevision;
  final Value<String> status;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<DateTime> createdAt;
  const ReconciliationOutboxCompanion({
    this.id = const Value.absent(),
    this.operationKey = const Value.absent(),
    this.reason = const Value.absent(),
    this.sourceRevision = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReconciliationOutboxCompanion.insert({
    this.id = const Value.absent(),
    required String operationKey,
    required String reason,
    required int sourceRevision,
    required String status,
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    required DateTime createdAt,
  }) : operationKey = Value(operationKey),
       reason = Value(reason),
       sourceRevision = Value(sourceRevision),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? operationKey,
    Expression<String>? reason,
    Expression<int>? sourceRevision,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationKey != null) 'operation_key': operationKey,
      if (reason != null) 'reason': reason,
      if (sourceRevision != null) 'source_revision': sourceRevision,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReconciliationOutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? operationKey,
    Value<String>? reason,
    Value<int>? sourceRevision,
    Value<String>? status,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
    Value<DateTime>? createdAt,
  }) {
    return ReconciliationOutboxCompanion(
      id: id ?? this.id,
      operationKey: operationKey ?? this.operationKey,
      reason: reason ?? this.reason,
      sourceRevision: sourceRevision ?? this.sourceRevision,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationKey.present) {
      map['operation_key'] = Variable<String>(operationKey.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (sourceRevision.present) {
      map['source_revision'] = Variable<int>(sourceRevision.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReconciliationOutboxCompanion(')
          ..write('id: $id, ')
          ..write('operationKey: $operationKey, ')
          ..write('reason: $reason, ')
          ..write('sourceRevision: $sourceRevision, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WidgetConfigurationsTable extends WidgetConfigurations
    with TableInfo<$WidgetConfigurationsTable, WidgetConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WidgetConfigurationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _widgetIdMeta = const VerificationMeta(
    'widgetId',
  );
  @override
  late final GeneratedColumn<String> widgetId = GeneratedColumn<String>(
    'widget_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryFilterMeta = const VerificationMeta(
    'categoryFilter',
  );
  @override
  late final GeneratedColumn<String> categoryFilter = GeneratedColumn<String>(
    'category_filter',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _layoutMeta = const VerificationMeta('layout');
  @override
  late final GeneratedColumn<String> layout = GeneratedColumn<String>(
    'layout',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expanded'),
  );
  static const VerificationMeta _surfaceMeta = const VerificationMeta(
    'surface',
  );
  @override
  late final GeneratedColumn<String> surface = GeneratedColumn<String>(
    'surface',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('clear'),
  );
  static const VerificationMeta _textToneMeta = const VerificationMeta(
    'textTone',
  );
  @override
  late final GeneratedColumn<String> textTone = GeneratedColumn<String>(
    'text_tone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('light'),
  );
  static const VerificationMeta _nextEmphasisMeta = const VerificationMeta(
    'nextEmphasis',
  );
  @override
  late final GeneratedColumn<bool> nextEmphasis = GeneratedColumn<bool>(
    'next_emphasis',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("next_emphasis" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showLocationMeta = const VerificationMeta(
    'showLocation',
  );
  @override
  late final GeneratedColumn<bool> showLocation = GeneratedColumn<bool>(
    'show_location',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_location" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showProfessorMeta = const VerificationMeta(
    'showProfessor',
  );
  @override
  late final GeneratedColumn<bool> showProfessor = GeneratedColumn<bool>(
    'show_professor',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_professor" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showSubtitleMeta = const VerificationMeta(
    'showSubtitle',
  );
  @override
  late final GeneratedColumn<bool> showSubtitle = GeneratedColumn<bool>(
    'show_subtitle',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_subtitle" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _matchAppMeta = const VerificationMeta(
    'matchApp',
  );
  @override
  late final GeneratedColumn<bool> matchApp = GeneratedColumn<bool>(
    'match_app',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("match_app" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _useAppThemeMeta = const VerificationMeta(
    'useAppTheme',
  );
  @override
  late final GeneratedColumn<bool> useAppTheme = GeneratedColumn<bool>(
    'use_app_theme',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_app_theme" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    widgetId,
    categoryFilter,
    layout,
    surface,
    textTone,
    nextEmphasis,
    showLocation,
    showProfessor,
    showSubtitle,
    matchApp,
    useAppTheme,
    revision,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'widget_configurations';
  @override
  VerificationContext validateIntegrity(
    Insertable<WidgetConfigRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('widget_id')) {
      context.handle(
        _widgetIdMeta,
        widgetId.isAcceptableOrUnknown(data['widget_id']!, _widgetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_widgetIdMeta);
    }
    if (data.containsKey('category_filter')) {
      context.handle(
        _categoryFilterMeta,
        categoryFilter.isAcceptableOrUnknown(
          data['category_filter']!,
          _categoryFilterMeta,
        ),
      );
    }
    if (data.containsKey('layout')) {
      context.handle(
        _layoutMeta,
        layout.isAcceptableOrUnknown(data['layout']!, _layoutMeta),
      );
    }
    if (data.containsKey('surface')) {
      context.handle(
        _surfaceMeta,
        surface.isAcceptableOrUnknown(data['surface']!, _surfaceMeta),
      );
    }
    if (data.containsKey('text_tone')) {
      context.handle(
        _textToneMeta,
        textTone.isAcceptableOrUnknown(data['text_tone']!, _textToneMeta),
      );
    }
    if (data.containsKey('next_emphasis')) {
      context.handle(
        _nextEmphasisMeta,
        nextEmphasis.isAcceptableOrUnknown(
          data['next_emphasis']!,
          _nextEmphasisMeta,
        ),
      );
    }
    if (data.containsKey('show_location')) {
      context.handle(
        _showLocationMeta,
        showLocation.isAcceptableOrUnknown(
          data['show_location']!,
          _showLocationMeta,
        ),
      );
    }
    if (data.containsKey('show_professor')) {
      context.handle(
        _showProfessorMeta,
        showProfessor.isAcceptableOrUnknown(
          data['show_professor']!,
          _showProfessorMeta,
        ),
      );
    }
    if (data.containsKey('show_subtitle')) {
      context.handle(
        _showSubtitleMeta,
        showSubtitle.isAcceptableOrUnknown(
          data['show_subtitle']!,
          _showSubtitleMeta,
        ),
      );
    }
    if (data.containsKey('match_app')) {
      context.handle(
        _matchAppMeta,
        matchApp.isAcceptableOrUnknown(data['match_app']!, _matchAppMeta),
      );
    }
    if (data.containsKey('use_app_theme')) {
      context.handle(
        _useAppThemeMeta,
        useAppTheme.isAcceptableOrUnknown(
          data['use_app_theme']!,
          _useAppThemeMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {widgetId};
  @override
  WidgetConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WidgetConfigRow(
      widgetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}widget_id'],
      )!,
      categoryFilter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_filter'],
      ),
      layout: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout'],
      )!,
      surface: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surface'],
      )!,
      textTone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_tone'],
      )!,
      nextEmphasis: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}next_emphasis'],
      )!,
      showLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_location'],
      )!,
      showProfessor: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_professor'],
      )!,
      showSubtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_subtitle'],
      )!,
      matchApp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}match_app'],
      )!,
      useAppTheme: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_app_theme'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WidgetConfigurationsTable createAlias(String alias) {
    return $WidgetConfigurationsTable(attachedDatabase, alias);
  }
}

class WidgetConfigRow extends DataClass implements Insertable<WidgetConfigRow> {
  final String widgetId;

  /// JSON {"categoryIds": [...], "includeUncategorized": bool}; null = all.
  final String? categoryFilter;
  final String layout;
  final String surface;
  final String textTone;
  final bool nextEmphasis;
  final bool showLocation;
  final bool showProfessor;
  final bool showSubtitle;
  final bool matchApp;

  /// Holders use the app theme's colors, shapes and display font. New widgets
  /// default on; widgets created before themes existed were migrated off.
  final bool useAppTheme;
  final int revision;
  final DateTime updatedAt;
  const WidgetConfigRow({
    required this.widgetId,
    this.categoryFilter,
    required this.layout,
    required this.surface,
    required this.textTone,
    required this.nextEmphasis,
    required this.showLocation,
    required this.showProfessor,
    required this.showSubtitle,
    required this.matchApp,
    required this.useAppTheme,
    required this.revision,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['widget_id'] = Variable<String>(widgetId);
    if (!nullToAbsent || categoryFilter != null) {
      map['category_filter'] = Variable<String>(categoryFilter);
    }
    map['layout'] = Variable<String>(layout);
    map['surface'] = Variable<String>(surface);
    map['text_tone'] = Variable<String>(textTone);
    map['next_emphasis'] = Variable<bool>(nextEmphasis);
    map['show_location'] = Variable<bool>(showLocation);
    map['show_professor'] = Variable<bool>(showProfessor);
    map['show_subtitle'] = Variable<bool>(showSubtitle);
    map['match_app'] = Variable<bool>(matchApp);
    map['use_app_theme'] = Variable<bool>(useAppTheme);
    map['revision'] = Variable<int>(revision);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WidgetConfigurationsCompanion toCompanion(bool nullToAbsent) {
    return WidgetConfigurationsCompanion(
      widgetId: Value(widgetId),
      categoryFilter: categoryFilter == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryFilter),
      layout: Value(layout),
      surface: Value(surface),
      textTone: Value(textTone),
      nextEmphasis: Value(nextEmphasis),
      showLocation: Value(showLocation),
      showProfessor: Value(showProfessor),
      showSubtitle: Value(showSubtitle),
      matchApp: Value(matchApp),
      useAppTheme: Value(useAppTheme),
      revision: Value(revision),
      updatedAt: Value(updatedAt),
    );
  }

  factory WidgetConfigRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WidgetConfigRow(
      widgetId: serializer.fromJson<String>(json['widgetId']),
      categoryFilter: serializer.fromJson<String?>(json['categoryFilter']),
      layout: serializer.fromJson<String>(json['layout']),
      surface: serializer.fromJson<String>(json['surface']),
      textTone: serializer.fromJson<String>(json['textTone']),
      nextEmphasis: serializer.fromJson<bool>(json['nextEmphasis']),
      showLocation: serializer.fromJson<bool>(json['showLocation']),
      showProfessor: serializer.fromJson<bool>(json['showProfessor']),
      showSubtitle: serializer.fromJson<bool>(json['showSubtitle']),
      matchApp: serializer.fromJson<bool>(json['matchApp']),
      useAppTheme: serializer.fromJson<bool>(json['useAppTheme']),
      revision: serializer.fromJson<int>(json['revision']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'widgetId': serializer.toJson<String>(widgetId),
      'categoryFilter': serializer.toJson<String?>(categoryFilter),
      'layout': serializer.toJson<String>(layout),
      'surface': serializer.toJson<String>(surface),
      'textTone': serializer.toJson<String>(textTone),
      'nextEmphasis': serializer.toJson<bool>(nextEmphasis),
      'showLocation': serializer.toJson<bool>(showLocation),
      'showProfessor': serializer.toJson<bool>(showProfessor),
      'showSubtitle': serializer.toJson<bool>(showSubtitle),
      'matchApp': serializer.toJson<bool>(matchApp),
      'useAppTheme': serializer.toJson<bool>(useAppTheme),
      'revision': serializer.toJson<int>(revision),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WidgetConfigRow copyWith({
    String? widgetId,
    Value<String?> categoryFilter = const Value.absent(),
    String? layout,
    String? surface,
    String? textTone,
    bool? nextEmphasis,
    bool? showLocation,
    bool? showProfessor,
    bool? showSubtitle,
    bool? matchApp,
    bool? useAppTheme,
    int? revision,
    DateTime? updatedAt,
  }) => WidgetConfigRow(
    widgetId: widgetId ?? this.widgetId,
    categoryFilter: categoryFilter.present
        ? categoryFilter.value
        : this.categoryFilter,
    layout: layout ?? this.layout,
    surface: surface ?? this.surface,
    textTone: textTone ?? this.textTone,
    nextEmphasis: nextEmphasis ?? this.nextEmphasis,
    showLocation: showLocation ?? this.showLocation,
    showProfessor: showProfessor ?? this.showProfessor,
    showSubtitle: showSubtitle ?? this.showSubtitle,
    matchApp: matchApp ?? this.matchApp,
    useAppTheme: useAppTheme ?? this.useAppTheme,
    revision: revision ?? this.revision,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WidgetConfigRow copyWithCompanion(WidgetConfigurationsCompanion data) {
    return WidgetConfigRow(
      widgetId: data.widgetId.present ? data.widgetId.value : this.widgetId,
      categoryFilter: data.categoryFilter.present
          ? data.categoryFilter.value
          : this.categoryFilter,
      layout: data.layout.present ? data.layout.value : this.layout,
      surface: data.surface.present ? data.surface.value : this.surface,
      textTone: data.textTone.present ? data.textTone.value : this.textTone,
      nextEmphasis: data.nextEmphasis.present
          ? data.nextEmphasis.value
          : this.nextEmphasis,
      showLocation: data.showLocation.present
          ? data.showLocation.value
          : this.showLocation,
      showProfessor: data.showProfessor.present
          ? data.showProfessor.value
          : this.showProfessor,
      showSubtitle: data.showSubtitle.present
          ? data.showSubtitle.value
          : this.showSubtitle,
      matchApp: data.matchApp.present ? data.matchApp.value : this.matchApp,
      useAppTheme: data.useAppTheme.present
          ? data.useAppTheme.value
          : this.useAppTheme,
      revision: data.revision.present ? data.revision.value : this.revision,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WidgetConfigRow(')
          ..write('widgetId: $widgetId, ')
          ..write('categoryFilter: $categoryFilter, ')
          ..write('layout: $layout, ')
          ..write('surface: $surface, ')
          ..write('textTone: $textTone, ')
          ..write('nextEmphasis: $nextEmphasis, ')
          ..write('showLocation: $showLocation, ')
          ..write('showProfessor: $showProfessor, ')
          ..write('showSubtitle: $showSubtitle, ')
          ..write('matchApp: $matchApp, ')
          ..write('useAppTheme: $useAppTheme, ')
          ..write('revision: $revision, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    widgetId,
    categoryFilter,
    layout,
    surface,
    textTone,
    nextEmphasis,
    showLocation,
    showProfessor,
    showSubtitle,
    matchApp,
    useAppTheme,
    revision,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WidgetConfigRow &&
          other.widgetId == this.widgetId &&
          other.categoryFilter == this.categoryFilter &&
          other.layout == this.layout &&
          other.surface == this.surface &&
          other.textTone == this.textTone &&
          other.nextEmphasis == this.nextEmphasis &&
          other.showLocation == this.showLocation &&
          other.showProfessor == this.showProfessor &&
          other.showSubtitle == this.showSubtitle &&
          other.matchApp == this.matchApp &&
          other.useAppTheme == this.useAppTheme &&
          other.revision == this.revision &&
          other.updatedAt == this.updatedAt);
}

class WidgetConfigurationsCompanion extends UpdateCompanion<WidgetConfigRow> {
  final Value<String> widgetId;
  final Value<String?> categoryFilter;
  final Value<String> layout;
  final Value<String> surface;
  final Value<String> textTone;
  final Value<bool> nextEmphasis;
  final Value<bool> showLocation;
  final Value<bool> showProfessor;
  final Value<bool> showSubtitle;
  final Value<bool> matchApp;
  final Value<bool> useAppTheme;
  final Value<int> revision;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WidgetConfigurationsCompanion({
    this.widgetId = const Value.absent(),
    this.categoryFilter = const Value.absent(),
    this.layout = const Value.absent(),
    this.surface = const Value.absent(),
    this.textTone = const Value.absent(),
    this.nextEmphasis = const Value.absent(),
    this.showLocation = const Value.absent(),
    this.showProfessor = const Value.absent(),
    this.showSubtitle = const Value.absent(),
    this.matchApp = const Value.absent(),
    this.useAppTheme = const Value.absent(),
    this.revision = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WidgetConfigurationsCompanion.insert({
    required String widgetId,
    this.categoryFilter = const Value.absent(),
    this.layout = const Value.absent(),
    this.surface = const Value.absent(),
    this.textTone = const Value.absent(),
    this.nextEmphasis = const Value.absent(),
    this.showLocation = const Value.absent(),
    this.showProfessor = const Value.absent(),
    this.showSubtitle = const Value.absent(),
    this.matchApp = const Value.absent(),
    this.useAppTheme = const Value.absent(),
    this.revision = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : widgetId = Value(widgetId),
       updatedAt = Value(updatedAt);
  static Insertable<WidgetConfigRow> custom({
    Expression<String>? widgetId,
    Expression<String>? categoryFilter,
    Expression<String>? layout,
    Expression<String>? surface,
    Expression<String>? textTone,
    Expression<bool>? nextEmphasis,
    Expression<bool>? showLocation,
    Expression<bool>? showProfessor,
    Expression<bool>? showSubtitle,
    Expression<bool>? matchApp,
    Expression<bool>? useAppTheme,
    Expression<int>? revision,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (widgetId != null) 'widget_id': widgetId,
      if (categoryFilter != null) 'category_filter': categoryFilter,
      if (layout != null) 'layout': layout,
      if (surface != null) 'surface': surface,
      if (textTone != null) 'text_tone': textTone,
      if (nextEmphasis != null) 'next_emphasis': nextEmphasis,
      if (showLocation != null) 'show_location': showLocation,
      if (showProfessor != null) 'show_professor': showProfessor,
      if (showSubtitle != null) 'show_subtitle': showSubtitle,
      if (matchApp != null) 'match_app': matchApp,
      if (useAppTheme != null) 'use_app_theme': useAppTheme,
      if (revision != null) 'revision': revision,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WidgetConfigurationsCompanion copyWith({
    Value<String>? widgetId,
    Value<String?>? categoryFilter,
    Value<String>? layout,
    Value<String>? surface,
    Value<String>? textTone,
    Value<bool>? nextEmphasis,
    Value<bool>? showLocation,
    Value<bool>? showProfessor,
    Value<bool>? showSubtitle,
    Value<bool>? matchApp,
    Value<bool>? useAppTheme,
    Value<int>? revision,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WidgetConfigurationsCompanion(
      widgetId: widgetId ?? this.widgetId,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      layout: layout ?? this.layout,
      surface: surface ?? this.surface,
      textTone: textTone ?? this.textTone,
      nextEmphasis: nextEmphasis ?? this.nextEmphasis,
      showLocation: showLocation ?? this.showLocation,
      showProfessor: showProfessor ?? this.showProfessor,
      showSubtitle: showSubtitle ?? this.showSubtitle,
      matchApp: matchApp ?? this.matchApp,
      useAppTheme: useAppTheme ?? this.useAppTheme,
      revision: revision ?? this.revision,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (widgetId.present) {
      map['widget_id'] = Variable<String>(widgetId.value);
    }
    if (categoryFilter.present) {
      map['category_filter'] = Variable<String>(categoryFilter.value);
    }
    if (layout.present) {
      map['layout'] = Variable<String>(layout.value);
    }
    if (surface.present) {
      map['surface'] = Variable<String>(surface.value);
    }
    if (textTone.present) {
      map['text_tone'] = Variable<String>(textTone.value);
    }
    if (nextEmphasis.present) {
      map['next_emphasis'] = Variable<bool>(nextEmphasis.value);
    }
    if (showLocation.present) {
      map['show_location'] = Variable<bool>(showLocation.value);
    }
    if (showProfessor.present) {
      map['show_professor'] = Variable<bool>(showProfessor.value);
    }
    if (showSubtitle.present) {
      map['show_subtitle'] = Variable<bool>(showSubtitle.value);
    }
    if (matchApp.present) {
      map['match_app'] = Variable<bool>(matchApp.value);
    }
    if (useAppTheme.present) {
      map['use_app_theme'] = Variable<bool>(useAppTheme.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WidgetConfigurationsCompanion(')
          ..write('widgetId: $widgetId, ')
          ..write('categoryFilter: $categoryFilter, ')
          ..write('layout: $layout, ')
          ..write('surface: $surface, ')
          ..write('textTone: $textTone, ')
          ..write('nextEmphasis: $nextEmphasis, ')
          ..write('showLocation: $showLocation, ')
          ..write('showProfessor: $showProfessor, ')
          ..write('showSubtitle: $showSubtitle, ')
          ..write('matchApp: $matchApp, ')
          ..write('useAppTheme: $useAppTheme, ')
          ..write('revision: $revision, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppearancePreferencesTable extends AppearancePreferences
    with TableInfo<$AppearancePreferencesTable, PreferencesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppearancePreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('light'),
  );
  static const VerificationMeta _accentKeyMeta = const VerificationMeta(
    'accentKey',
  );
  @override
  late final GeneratedColumn<String> accentKey = GeneratedColumn<String>(
    'accent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('blue'),
  );
  static const VerificationMeta _themeKeyMeta = const VerificationMeta(
    'themeKey',
  );
  @override
  late final GeneratedColumn<String> themeKey = GeneratedColumn<String>(
    'theme_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('lilac'),
  );
  static const VerificationMeta _customHueMeta = const VerificationMeta(
    'customHue',
  );
  @override
  late final GeneratedColumn<int> customHue = GeneratedColumn<int>(
    'custom_hue',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(250),
  );
  static const VerificationMeta _themeCustomizationsJsonMeta =
      const VerificationMeta('themeCustomizationsJson');
  @override
  late final GeneratedColumn<String> themeCustomizationsJson =
      GeneratedColumn<String>(
        'theme_customizations_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _densityMeta = const VerificationMeta(
    'density',
  );
  @override
  late final GeneratedColumn<String> density = GeneratedColumn<String>(
    'density',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('comfortable'),
  );
  static const VerificationMeta _showCategoryColorsMeta =
      const VerificationMeta('showCategoryColors');
  @override
  late final GeneratedColumn<bool> showCategoryColors = GeneratedColumn<bool>(
    'show_category_colors',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_category_colors" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    themeMode,
    accentKey,
    themeKey,
    customHue,
    themeCustomizationsJson,
    density,
    showCategoryColors,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'appearance_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferencesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('accent_key')) {
      context.handle(
        _accentKeyMeta,
        accentKey.isAcceptableOrUnknown(data['accent_key']!, _accentKeyMeta),
      );
    }
    if (data.containsKey('theme_key')) {
      context.handle(
        _themeKeyMeta,
        themeKey.isAcceptableOrUnknown(data['theme_key']!, _themeKeyMeta),
      );
    }
    if (data.containsKey('custom_hue')) {
      context.handle(
        _customHueMeta,
        customHue.isAcceptableOrUnknown(data['custom_hue']!, _customHueMeta),
      );
    }
    if (data.containsKey('theme_customizations_json')) {
      context.handle(
        _themeCustomizationsJsonMeta,
        themeCustomizationsJson.isAcceptableOrUnknown(
          data['theme_customizations_json']!,
          _themeCustomizationsJsonMeta,
        ),
      );
    }
    if (data.containsKey('density')) {
      context.handle(
        _densityMeta,
        density.isAcceptableOrUnknown(data['density']!, _densityMeta),
      );
    }
    if (data.containsKey('show_category_colors')) {
      context.handle(
        _showCategoryColorsMeta,
        showCategoryColors.isAcceptableOrUnknown(
          data['show_category_colors']!,
          _showCategoryColorsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PreferencesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferencesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      accentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accent_key'],
      )!,
      themeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_key'],
      )!,
      customHue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}custom_hue'],
      )!,
      themeCustomizationsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_customizations_json'],
      )!,
      density: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}density'],
      )!,
      showCategoryColors: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_category_colors'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppearancePreferencesTable createAlias(String alias) {
    return $AppearancePreferencesTable(attachedDatabase, alias);
  }
}

class PreferencesRow extends DataClass implements Insertable<PreferencesRow> {
  final int id;
  final String themeMode;

  /// Legacy v1 accent; read only by the v2 migration.
  final String accentKey;
  final String themeKey;
  final int customHue;
  final String themeCustomizationsJson;
  final String density;
  final bool showCategoryColors;
  final DateTime updatedAt;
  const PreferencesRow({
    required this.id,
    required this.themeMode,
    required this.accentKey,
    required this.themeKey,
    required this.customHue,
    required this.themeCustomizationsJson,
    required this.density,
    required this.showCategoryColors,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme_mode'] = Variable<String>(themeMode);
    map['accent_key'] = Variable<String>(accentKey);
    map['theme_key'] = Variable<String>(themeKey);
    map['custom_hue'] = Variable<int>(customHue);
    map['theme_customizations_json'] = Variable<String>(
      themeCustomizationsJson,
    );
    map['density'] = Variable<String>(density);
    map['show_category_colors'] = Variable<bool>(showCategoryColors);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppearancePreferencesCompanion toCompanion(bool nullToAbsent) {
    return AppearancePreferencesCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      accentKey: Value(accentKey),
      themeKey: Value(themeKey),
      customHue: Value(customHue),
      themeCustomizationsJson: Value(themeCustomizationsJson),
      density: Value(density),
      showCategoryColors: Value(showCategoryColors),
      updatedAt: Value(updatedAt),
    );
  }

  factory PreferencesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferencesRow(
      id: serializer.fromJson<int>(json['id']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      accentKey: serializer.fromJson<String>(json['accentKey']),
      themeKey: serializer.fromJson<String>(json['themeKey']),
      customHue: serializer.fromJson<int>(json['customHue']),
      themeCustomizationsJson: serializer.fromJson<String>(
        json['themeCustomizationsJson'],
      ),
      density: serializer.fromJson<String>(json['density']),
      showCategoryColors: serializer.fromJson<bool>(json['showCategoryColors']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'themeMode': serializer.toJson<String>(themeMode),
      'accentKey': serializer.toJson<String>(accentKey),
      'themeKey': serializer.toJson<String>(themeKey),
      'customHue': serializer.toJson<int>(customHue),
      'themeCustomizationsJson': serializer.toJson<String>(
        themeCustomizationsJson,
      ),
      'density': serializer.toJson<String>(density),
      'showCategoryColors': serializer.toJson<bool>(showCategoryColors),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PreferencesRow copyWith({
    int? id,
    String? themeMode,
    String? accentKey,
    String? themeKey,
    int? customHue,
    String? themeCustomizationsJson,
    String? density,
    bool? showCategoryColors,
    DateTime? updatedAt,
  }) => PreferencesRow(
    id: id ?? this.id,
    themeMode: themeMode ?? this.themeMode,
    accentKey: accentKey ?? this.accentKey,
    themeKey: themeKey ?? this.themeKey,
    customHue: customHue ?? this.customHue,
    themeCustomizationsJson:
        themeCustomizationsJson ?? this.themeCustomizationsJson,
    density: density ?? this.density,
    showCategoryColors: showCategoryColors ?? this.showCategoryColors,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PreferencesRow copyWithCompanion(AppearancePreferencesCompanion data) {
    return PreferencesRow(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      accentKey: data.accentKey.present ? data.accentKey.value : this.accentKey,
      themeKey: data.themeKey.present ? data.themeKey.value : this.themeKey,
      customHue: data.customHue.present ? data.customHue.value : this.customHue,
      themeCustomizationsJson: data.themeCustomizationsJson.present
          ? data.themeCustomizationsJson.value
          : this.themeCustomizationsJson,
      density: data.density.present ? data.density.value : this.density,
      showCategoryColors: data.showCategoryColors.present
          ? data.showCategoryColors.value
          : this.showCategoryColors,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesRow(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('accentKey: $accentKey, ')
          ..write('themeKey: $themeKey, ')
          ..write('customHue: $customHue, ')
          ..write('themeCustomizationsJson: $themeCustomizationsJson, ')
          ..write('density: $density, ')
          ..write('showCategoryColors: $showCategoryColors, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    themeMode,
    accentKey,
    themeKey,
    customHue,
    themeCustomizationsJson,
    density,
    showCategoryColors,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferencesRow &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.accentKey == this.accentKey &&
          other.themeKey == this.themeKey &&
          other.customHue == this.customHue &&
          other.themeCustomizationsJson == this.themeCustomizationsJson &&
          other.density == this.density &&
          other.showCategoryColors == this.showCategoryColors &&
          other.updatedAt == this.updatedAt);
}

class AppearancePreferencesCompanion extends UpdateCompanion<PreferencesRow> {
  final Value<int> id;
  final Value<String> themeMode;
  final Value<String> accentKey;
  final Value<String> themeKey;
  final Value<int> customHue;
  final Value<String> themeCustomizationsJson;
  final Value<String> density;
  final Value<bool> showCategoryColors;
  final Value<DateTime> updatedAt;
  const AppearancePreferencesCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.accentKey = const Value.absent(),
    this.themeKey = const Value.absent(),
    this.customHue = const Value.absent(),
    this.themeCustomizationsJson = const Value.absent(),
    this.density = const Value.absent(),
    this.showCategoryColors = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppearancePreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.accentKey = const Value.absent(),
    this.themeKey = const Value.absent(),
    this.customHue = const Value.absent(),
    this.themeCustomizationsJson = const Value.absent(),
    this.density = const Value.absent(),
    this.showCategoryColors = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<PreferencesRow> custom({
    Expression<int>? id,
    Expression<String>? themeMode,
    Expression<String>? accentKey,
    Expression<String>? themeKey,
    Expression<int>? customHue,
    Expression<String>? themeCustomizationsJson,
    Expression<String>? density,
    Expression<bool>? showCategoryColors,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (accentKey != null) 'accent_key': accentKey,
      if (themeKey != null) 'theme_key': themeKey,
      if (customHue != null) 'custom_hue': customHue,
      if (themeCustomizationsJson != null)
        'theme_customizations_json': themeCustomizationsJson,
      if (density != null) 'density': density,
      if (showCategoryColors != null)
        'show_category_colors': showCategoryColors,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppearancePreferencesCompanion copyWith({
    Value<int>? id,
    Value<String>? themeMode,
    Value<String>? accentKey,
    Value<String>? themeKey,
    Value<int>? customHue,
    Value<String>? themeCustomizationsJson,
    Value<String>? density,
    Value<bool>? showCategoryColors,
    Value<DateTime>? updatedAt,
  }) {
    return AppearancePreferencesCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      accentKey: accentKey ?? this.accentKey,
      themeKey: themeKey ?? this.themeKey,
      customHue: customHue ?? this.customHue,
      themeCustomizationsJson:
          themeCustomizationsJson ?? this.themeCustomizationsJson,
      density: density ?? this.density,
      showCategoryColors: showCategoryColors ?? this.showCategoryColors,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (accentKey.present) {
      map['accent_key'] = Variable<String>(accentKey.value);
    }
    if (themeKey.present) {
      map['theme_key'] = Variable<String>(themeKey.value);
    }
    if (customHue.present) {
      map['custom_hue'] = Variable<int>(customHue.value);
    }
    if (themeCustomizationsJson.present) {
      map['theme_customizations_json'] = Variable<String>(
        themeCustomizationsJson.value,
      );
    }
    if (density.present) {
      map['density'] = Variable<String>(density.value);
    }
    if (showCategoryColors.present) {
      map['show_category_colors'] = Variable<bool>(showCategoryColors.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppearancePreferencesCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('accentKey: $accentKey, ')
          ..write('themeKey: $themeKey, ')
          ..write('customHue: $customHue, ')
          ..write('themeCustomizationsJson: $themeCustomizationsJson, ')
          ..write('density: $density, ')
          ..write('showCategoryColors: $showCategoryColors, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ImportDraftsTable extends ImportDrafts
    with TableInfo<$ImportDraftsTable, ImportDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRefMeta = const VerificationMeta(
    'sourceRef',
  );
  @override
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRevisionMeta = const VerificationMeta(
    'sourceRevision',
  );
  @override
  late final GeneratedColumn<int> sourceRevision = GeneratedColumn<int>(
    'source_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _draftRevisionMeta = const VerificationMeta(
    'draftRevision',
  );
  @override
  late final GeneratedColumn<int> draftRevision = GeneratedColumn<int>(
    'draft_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewStateMeta = const VerificationMeta(
    'reviewState',
  );
  @override
  late final GeneratedColumn<String> reviewState = GeneratedColumn<String>(
    'review_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceType,
    sourceRef,
    sourceRevision,
    draftRevision,
    payloadJson,
    reviewState,
    createdAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_ref')) {
      context.handle(
        _sourceRefMeta,
        sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta),
      );
    }
    if (data.containsKey('source_revision')) {
      context.handle(
        _sourceRevisionMeta,
        sourceRevision.isAcceptableOrUnknown(
          data['source_revision']!,
          _sourceRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRevisionMeta);
    }
    if (data.containsKey('draft_revision')) {
      context.handle(
        _draftRevisionMeta,
        draftRevision.isAcceptableOrUnknown(
          data['draft_revision']!,
          _draftRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_draftRevisionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('review_state')) {
      context.handle(
        _reviewStateMeta,
        reviewState.isAcceptableOrUnknown(
          data['review_state']!,
          _reviewStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewStateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportDraftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref'],
      ),
      sourceRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_revision'],
      )!,
      draftRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}draft_revision'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      reviewState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $ImportDraftsTable createAlias(String alias) {
    return $ImportDraftsTable(attachedDatabase, alias);
  }
}

class ImportDraftRow extends DataClass implements Insertable<ImportDraftRow> {
  final String id;
  final String sourceType;
  final String? sourceRef;
  final int sourceRevision;
  final int draftRevision;
  final String payloadJson;
  final String reviewState;
  final DateTime createdAt;
  final DateTime expiresAt;
  const ImportDraftRow({
    required this.id,
    required this.sourceType,
    this.sourceRef,
    required this.sourceRevision,
    required this.draftRevision,
    required this.payloadJson,
    required this.reviewState,
    required this.createdAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourceRef != null) {
      map['source_ref'] = Variable<String>(sourceRef);
    }
    map['source_revision'] = Variable<int>(sourceRevision);
    map['draft_revision'] = Variable<int>(draftRevision);
    map['payload_json'] = Variable<String>(payloadJson);
    map['review_state'] = Variable<String>(reviewState);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  ImportDraftsCompanion toCompanion(bool nullToAbsent) {
    return ImportDraftsCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      sourceRef: sourceRef == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRef),
      sourceRevision: Value(sourceRevision),
      draftRevision: Value(draftRevision),
      payloadJson: Value(payloadJson),
      reviewState: Value(reviewState),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory ImportDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportDraftRow(
      id: serializer.fromJson<String>(json['id']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceRef: serializer.fromJson<String?>(json['sourceRef']),
      sourceRevision: serializer.fromJson<int>(json['sourceRevision']),
      draftRevision: serializer.fromJson<int>(json['draftRevision']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      reviewState: serializer.fromJson<String>(json['reviewState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceRef': serializer.toJson<String?>(sourceRef),
      'sourceRevision': serializer.toJson<int>(sourceRevision),
      'draftRevision': serializer.toJson<int>(draftRevision),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'reviewState': serializer.toJson<String>(reviewState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  ImportDraftRow copyWith({
    String? id,
    String? sourceType,
    Value<String?> sourceRef = const Value.absent(),
    int? sourceRevision,
    int? draftRevision,
    String? payloadJson,
    String? reviewState,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) => ImportDraftRow(
    id: id ?? this.id,
    sourceType: sourceType ?? this.sourceType,
    sourceRef: sourceRef.present ? sourceRef.value : this.sourceRef,
    sourceRevision: sourceRevision ?? this.sourceRevision,
    draftRevision: draftRevision ?? this.draftRevision,
    payloadJson: payloadJson ?? this.payloadJson,
    reviewState: reviewState ?? this.reviewState,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  ImportDraftRow copyWithCompanion(ImportDraftsCompanion data) {
    return ImportDraftRow(
      id: data.id.present ? data.id.value : this.id,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      sourceRevision: data.sourceRevision.present
          ? data.sourceRevision.value
          : this.sourceRevision,
      draftRevision: data.draftRevision.present
          ? data.draftRevision.value
          : this.draftRevision,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      reviewState: data.reviewState.present
          ? data.reviewState.value
          : this.reviewState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportDraftRow(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('sourceRevision: $sourceRevision, ')
          ..write('draftRevision: $draftRevision, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('reviewState: $reviewState, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceType,
    sourceRef,
    sourceRevision,
    draftRevision,
    payloadJson,
    reviewState,
    createdAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportDraftRow &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.sourceRef == this.sourceRef &&
          other.sourceRevision == this.sourceRevision &&
          other.draftRevision == this.draftRevision &&
          other.payloadJson == this.payloadJson &&
          other.reviewState == this.reviewState &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class ImportDraftsCompanion extends UpdateCompanion<ImportDraftRow> {
  final Value<String> id;
  final Value<String> sourceType;
  final Value<String?> sourceRef;
  final Value<int> sourceRevision;
  final Value<int> draftRevision;
  final Value<String> payloadJson;
  final Value<String> reviewState;
  final Value<DateTime> createdAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const ImportDraftsCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.sourceRevision = const Value.absent(),
    this.draftRevision = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportDraftsCompanion.insert({
    required String id,
    required String sourceType,
    this.sourceRef = const Value.absent(),
    required int sourceRevision,
    required int draftRevision,
    required String payloadJson,
    required String reviewState,
    required DateTime createdAt,
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceType = Value(sourceType),
       sourceRevision = Value(sourceRevision),
       draftRevision = Value(draftRevision),
       payloadJson = Value(payloadJson),
       reviewState = Value(reviewState),
       createdAt = Value(createdAt),
       expiresAt = Value(expiresAt);
  static Insertable<ImportDraftRow> custom({
    Expression<String>? id,
    Expression<String>? sourceType,
    Expression<String>? sourceRef,
    Expression<int>? sourceRevision,
    Expression<int>? draftRevision,
    Expression<String>? payloadJson,
    Expression<String>? reviewState,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (sourceRevision != null) 'source_revision': sourceRevision,
      if (draftRevision != null) 'draft_revision': draftRevision,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (reviewState != null) 'review_state': reviewState,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportDraftsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceType,
    Value<String?>? sourceRef,
    Value<int>? sourceRevision,
    Value<int>? draftRevision,
    Value<String>? payloadJson,
    Value<String>? reviewState,
    Value<DateTime>? createdAt,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return ImportDraftsCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceRef: sourceRef ?? this.sourceRef,
      sourceRevision: sourceRevision ?? this.sourceRevision,
      draftRevision: draftRevision ?? this.draftRevision,
      payloadJson: payloadJson ?? this.payloadJson,
      reviewState: reviewState ?? this.reviewState,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    if (sourceRevision.present) {
      map['source_revision'] = Variable<int>(sourceRevision.value);
    }
    if (draftRevision.present) {
      map['draft_revision'] = Variable<int>(draftRevision.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (reviewState.present) {
      map['review_state'] = Variable<String>(reviewState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportDraftsCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('sourceRevision: $sourceRevision, ')
          ..write('draftRevision: $draftRevision, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('reviewState: $reviewState, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportProvenanceTable extends ImportProvenance
    with TableInfo<$ImportProvenanceTable, ProvenanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportProvenanceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES schedule_series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shareIdMeta = const VerificationMeta(
    'shareId',
  );
  @override
  late final GeneratedColumn<String> shareId = GeneratedColumn<String>(
    'share_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceItemIdMeta = const VerificationMeta(
    'sourceItemId',
  );
  @override
  late final GeneratedColumn<String> sourceItemId = GeneratedColumn<String>(
    'source_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRevisionMeta = const VerificationMeta(
    'sourceRevision',
  );
  @override
  late final GeneratedColumn<int> sourceRevision = GeneratedColumn<int>(
    'source_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageDraftIdMeta = const VerificationMeta(
    'imageDraftId',
  );
  @override
  late final GeneratedColumn<String> imageDraftId = GeneratedColumn<String>(
    'image_draft_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesId,
    sourceType,
    shareId,
    sourceItemId,
    sourceRevision,
    imageDraftId,
    fingerprint,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_provenance';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProvenanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('share_id')) {
      context.handle(
        _shareIdMeta,
        shareId.isAcceptableOrUnknown(data['share_id']!, _shareIdMeta),
      );
    }
    if (data.containsKey('source_item_id')) {
      context.handle(
        _sourceItemIdMeta,
        sourceItemId.isAcceptableOrUnknown(
          data['source_item_id']!,
          _sourceItemIdMeta,
        ),
      );
    }
    if (data.containsKey('source_revision')) {
      context.handle(
        _sourceRevisionMeta,
        sourceRevision.isAcceptableOrUnknown(
          data['source_revision']!,
          _sourceRevisionMeta,
        ),
      );
    }
    if (data.containsKey('image_draft_id')) {
      context.handle(
        _imageDraftIdMeta,
        imageDraftId.isAcceptableOrUnknown(
          data['image_draft_id']!,
          _imageDraftIdMeta,
        ),
      );
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProvenanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProvenanceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      shareId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}share_id'],
      ),
      sourceItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_item_id'],
      ),
      sourceRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_revision'],
      ),
      imageDraftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_draft_id'],
      ),
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $ImportProvenanceTable createAlias(String alias) {
    return $ImportProvenanceTable(attachedDatabase, alias);
  }
}

class ProvenanceRow extends DataClass implements Insertable<ProvenanceRow> {
  final String id;
  final String seriesId;
  final String sourceType;
  final String? shareId;
  final String? sourceItemId;
  final int? sourceRevision;
  final String? imageDraftId;
  final String fingerprint;
  final DateTime importedAt;
  const ProvenanceRow({
    required this.id,
    required this.seriesId,
    required this.sourceType,
    this.shareId,
    this.sourceItemId,
    this.sourceRevision,
    this.imageDraftId,
    required this.fingerprint,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['series_id'] = Variable<String>(seriesId);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || shareId != null) {
      map['share_id'] = Variable<String>(shareId);
    }
    if (!nullToAbsent || sourceItemId != null) {
      map['source_item_id'] = Variable<String>(sourceItemId);
    }
    if (!nullToAbsent || sourceRevision != null) {
      map['source_revision'] = Variable<int>(sourceRevision);
    }
    if (!nullToAbsent || imageDraftId != null) {
      map['image_draft_id'] = Variable<String>(imageDraftId);
    }
    map['fingerprint'] = Variable<String>(fingerprint);
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  ImportProvenanceCompanion toCompanion(bool nullToAbsent) {
    return ImportProvenanceCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      sourceType: Value(sourceType),
      shareId: shareId == null && nullToAbsent
          ? const Value.absent()
          : Value(shareId),
      sourceItemId: sourceItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceItemId),
      sourceRevision: sourceRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRevision),
      imageDraftId: imageDraftId == null && nullToAbsent
          ? const Value.absent()
          : Value(imageDraftId),
      fingerprint: Value(fingerprint),
      importedAt: Value(importedAt),
    );
  }

  factory ProvenanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProvenanceRow(
      id: serializer.fromJson<String>(json['id']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      shareId: serializer.fromJson<String?>(json['shareId']),
      sourceItemId: serializer.fromJson<String?>(json['sourceItemId']),
      sourceRevision: serializer.fromJson<int?>(json['sourceRevision']),
      imageDraftId: serializer.fromJson<String?>(json['imageDraftId']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seriesId': serializer.toJson<String>(seriesId),
      'sourceType': serializer.toJson<String>(sourceType),
      'shareId': serializer.toJson<String?>(shareId),
      'sourceItemId': serializer.toJson<String?>(sourceItemId),
      'sourceRevision': serializer.toJson<int?>(sourceRevision),
      'imageDraftId': serializer.toJson<String?>(imageDraftId),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  ProvenanceRow copyWith({
    String? id,
    String? seriesId,
    String? sourceType,
    Value<String?> shareId = const Value.absent(),
    Value<String?> sourceItemId = const Value.absent(),
    Value<int?> sourceRevision = const Value.absent(),
    Value<String?> imageDraftId = const Value.absent(),
    String? fingerprint,
    DateTime? importedAt,
  }) => ProvenanceRow(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    sourceType: sourceType ?? this.sourceType,
    shareId: shareId.present ? shareId.value : this.shareId,
    sourceItemId: sourceItemId.present ? sourceItemId.value : this.sourceItemId,
    sourceRevision: sourceRevision.present
        ? sourceRevision.value
        : this.sourceRevision,
    imageDraftId: imageDraftId.present ? imageDraftId.value : this.imageDraftId,
    fingerprint: fingerprint ?? this.fingerprint,
    importedAt: importedAt ?? this.importedAt,
  );
  ProvenanceRow copyWithCompanion(ImportProvenanceCompanion data) {
    return ProvenanceRow(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      shareId: data.shareId.present ? data.shareId.value : this.shareId,
      sourceItemId: data.sourceItemId.present
          ? data.sourceItemId.value
          : this.sourceItemId,
      sourceRevision: data.sourceRevision.present
          ? data.sourceRevision.value
          : this.sourceRevision,
      imageDraftId: data.imageDraftId.present
          ? data.imageDraftId.value
          : this.imageDraftId,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProvenanceRow(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('sourceType: $sourceType, ')
          ..write('shareId: $shareId, ')
          ..write('sourceItemId: $sourceItemId, ')
          ..write('sourceRevision: $sourceRevision, ')
          ..write('imageDraftId: $imageDraftId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seriesId,
    sourceType,
    shareId,
    sourceItemId,
    sourceRevision,
    imageDraftId,
    fingerprint,
    importedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProvenanceRow &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.sourceType == this.sourceType &&
          other.shareId == this.shareId &&
          other.sourceItemId == this.sourceItemId &&
          other.sourceRevision == this.sourceRevision &&
          other.imageDraftId == this.imageDraftId &&
          other.fingerprint == this.fingerprint &&
          other.importedAt == this.importedAt);
}

class ImportProvenanceCompanion extends UpdateCompanion<ProvenanceRow> {
  final Value<String> id;
  final Value<String> seriesId;
  final Value<String> sourceType;
  final Value<String?> shareId;
  final Value<String?> sourceItemId;
  final Value<int?> sourceRevision;
  final Value<String?> imageDraftId;
  final Value<String> fingerprint;
  final Value<DateTime> importedAt;
  final Value<int> rowid;
  const ImportProvenanceCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.shareId = const Value.absent(),
    this.sourceItemId = const Value.absent(),
    this.sourceRevision = const Value.absent(),
    this.imageDraftId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportProvenanceCompanion.insert({
    required String id,
    required String seriesId,
    required String sourceType,
    this.shareId = const Value.absent(),
    this.sourceItemId = const Value.absent(),
    this.sourceRevision = const Value.absent(),
    this.imageDraftId = const Value.absent(),
    required String fingerprint,
    required DateTime importedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seriesId = Value(seriesId),
       sourceType = Value(sourceType),
       fingerprint = Value(fingerprint),
       importedAt = Value(importedAt);
  static Insertable<ProvenanceRow> custom({
    Expression<String>? id,
    Expression<String>? seriesId,
    Expression<String>? sourceType,
    Expression<String>? shareId,
    Expression<String>? sourceItemId,
    Expression<int>? sourceRevision,
    Expression<String>? imageDraftId,
    Expression<String>? fingerprint,
    Expression<DateTime>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (sourceType != null) 'source_type': sourceType,
      if (shareId != null) 'share_id': shareId,
      if (sourceItemId != null) 'source_item_id': sourceItemId,
      if (sourceRevision != null) 'source_revision': sourceRevision,
      if (imageDraftId != null) 'image_draft_id': imageDraftId,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportProvenanceCompanion copyWith({
    Value<String>? id,
    Value<String>? seriesId,
    Value<String>? sourceType,
    Value<String?>? shareId,
    Value<String?>? sourceItemId,
    Value<int?>? sourceRevision,
    Value<String?>? imageDraftId,
    Value<String>? fingerprint,
    Value<DateTime>? importedAt,
    Value<int>? rowid,
  }) {
    return ImportProvenanceCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      sourceType: sourceType ?? this.sourceType,
      shareId: shareId ?? this.shareId,
      sourceItemId: sourceItemId ?? this.sourceItemId,
      sourceRevision: sourceRevision ?? this.sourceRevision,
      imageDraftId: imageDraftId ?? this.imageDraftId,
      fingerprint: fingerprint ?? this.fingerprint,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (shareId.present) {
      map['share_id'] = Variable<String>(shareId.value);
    }
    if (sourceItemId.present) {
      map['source_item_id'] = Variable<String>(sourceItemId.value);
    }
    if (sourceRevision.present) {
      map['source_revision'] = Variable<int>(sourceRevision.value);
    }
    if (imageDraftId.present) {
      map['image_draft_id'] = Variable<String>(imageDraftId.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportProvenanceCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('sourceType: $sourceType, ')
          ..write('shareId: $shareId, ')
          ..write('sourceItemId: $sourceItemId, ')
          ..write('sourceRevision: $sourceRevision, ')
          ..write('imageDraftId: $imageDraftId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportCommitsTable extends ImportCommits
    with TableInfo<$ImportCommitsTable, ImportCommitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportCommitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _commandIdMeta = const VerificationMeta(
    'commandId',
  );
  @override
  late final GeneratedColumn<String> commandId = GeneratedColumn<String>(
    'command_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadHashMeta = const VerificationMeta(
    'payloadHash',
  );
  @override
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
    'payload_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdsJsonMeta = const VerificationMeta(
    'seriesIdsJson',
  );
  @override
  late final GeneratedColumn<String> seriesIdsJson = GeneratedColumn<String>(
    'series_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _committedAtMeta = const VerificationMeta(
    'committedAt',
  );
  @override
  late final GeneratedColumn<DateTime> committedAt = GeneratedColumn<DateTime>(
    'committed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    commandId,
    payloadHash,
    seriesIdsJson,
    committedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_commits';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportCommitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('command_id')) {
      context.handle(
        _commandIdMeta,
        commandId.isAcceptableOrUnknown(data['command_id']!, _commandIdMeta),
      );
    } else if (isInserting) {
      context.missing(_commandIdMeta);
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
        _payloadHashMeta,
        payloadHash.isAcceptableOrUnknown(
          data['payload_hash']!,
          _payloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadHashMeta);
    }
    if (data.containsKey('series_ids_json')) {
      context.handle(
        _seriesIdsJsonMeta,
        seriesIdsJson.isAcceptableOrUnknown(
          data['series_ids_json']!,
          _seriesIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seriesIdsJsonMeta);
    }
    if (data.containsKey('committed_at')) {
      context.handle(
        _committedAtMeta,
        committedAt.isAcceptableOrUnknown(
          data['committed_at']!,
          _committedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_committedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {commandId};
  @override
  ImportCommitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportCommitRow(
      commandId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command_id'],
      )!,
      payloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_hash'],
      )!,
      seriesIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_ids_json'],
      )!,
      committedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}committed_at'],
      )!,
    );
  }

  @override
  $ImportCommitsTable createAlias(String alias) {
    return $ImportCommitsTable(attachedDatabase, alias);
  }
}

class ImportCommitRow extends DataClass implements Insertable<ImportCommitRow> {
  final String commandId;
  final String payloadHash;
  final String seriesIdsJson;
  final DateTime committedAt;
  const ImportCommitRow({
    required this.commandId,
    required this.payloadHash,
    required this.seriesIdsJson,
    required this.committedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['command_id'] = Variable<String>(commandId);
    map['payload_hash'] = Variable<String>(payloadHash);
    map['series_ids_json'] = Variable<String>(seriesIdsJson);
    map['committed_at'] = Variable<DateTime>(committedAt);
    return map;
  }

  ImportCommitsCompanion toCompanion(bool nullToAbsent) {
    return ImportCommitsCompanion(
      commandId: Value(commandId),
      payloadHash: Value(payloadHash),
      seriesIdsJson: Value(seriesIdsJson),
      committedAt: Value(committedAt),
    );
  }

  factory ImportCommitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportCommitRow(
      commandId: serializer.fromJson<String>(json['commandId']),
      payloadHash: serializer.fromJson<String>(json['payloadHash']),
      seriesIdsJson: serializer.fromJson<String>(json['seriesIdsJson']),
      committedAt: serializer.fromJson<DateTime>(json['committedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'commandId': serializer.toJson<String>(commandId),
      'payloadHash': serializer.toJson<String>(payloadHash),
      'seriesIdsJson': serializer.toJson<String>(seriesIdsJson),
      'committedAt': serializer.toJson<DateTime>(committedAt),
    };
  }

  ImportCommitRow copyWith({
    String? commandId,
    String? payloadHash,
    String? seriesIdsJson,
    DateTime? committedAt,
  }) => ImportCommitRow(
    commandId: commandId ?? this.commandId,
    payloadHash: payloadHash ?? this.payloadHash,
    seriesIdsJson: seriesIdsJson ?? this.seriesIdsJson,
    committedAt: committedAt ?? this.committedAt,
  );
  ImportCommitRow copyWithCompanion(ImportCommitsCompanion data) {
    return ImportCommitRow(
      commandId: data.commandId.present ? data.commandId.value : this.commandId,
      payloadHash: data.payloadHash.present
          ? data.payloadHash.value
          : this.payloadHash,
      seriesIdsJson: data.seriesIdsJson.present
          ? data.seriesIdsJson.value
          : this.seriesIdsJson,
      committedAt: data.committedAt.present
          ? data.committedAt.value
          : this.committedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportCommitRow(')
          ..write('commandId: $commandId, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('seriesIdsJson: $seriesIdsJson, ')
          ..write('committedAt: $committedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(commandId, payloadHash, seriesIdsJson, committedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportCommitRow &&
          other.commandId == this.commandId &&
          other.payloadHash == this.payloadHash &&
          other.seriesIdsJson == this.seriesIdsJson &&
          other.committedAt == this.committedAt);
}

class ImportCommitsCompanion extends UpdateCompanion<ImportCommitRow> {
  final Value<String> commandId;
  final Value<String> payloadHash;
  final Value<String> seriesIdsJson;
  final Value<DateTime> committedAt;
  final Value<int> rowid;
  const ImportCommitsCompanion({
    this.commandId = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.seriesIdsJson = const Value.absent(),
    this.committedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportCommitsCompanion.insert({
    required String commandId,
    required String payloadHash,
    required String seriesIdsJson,
    required DateTime committedAt,
    this.rowid = const Value.absent(),
  }) : commandId = Value(commandId),
       payloadHash = Value(payloadHash),
       seriesIdsJson = Value(seriesIdsJson),
       committedAt = Value(committedAt);
  static Insertable<ImportCommitRow> custom({
    Expression<String>? commandId,
    Expression<String>? payloadHash,
    Expression<String>? seriesIdsJson,
    Expression<DateTime>? committedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (commandId != null) 'command_id': commandId,
      if (payloadHash != null) 'payload_hash': payloadHash,
      if (seriesIdsJson != null) 'series_ids_json': seriesIdsJson,
      if (committedAt != null) 'committed_at': committedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportCommitsCompanion copyWith({
    Value<String>? commandId,
    Value<String>? payloadHash,
    Value<String>? seriesIdsJson,
    Value<DateTime>? committedAt,
    Value<int>? rowid,
  }) {
    return ImportCommitsCompanion(
      commandId: commandId ?? this.commandId,
      payloadHash: payloadHash ?? this.payloadHash,
      seriesIdsJson: seriesIdsJson ?? this.seriesIdsJson,
      committedAt: committedAt ?? this.committedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (commandId.present) {
      map['command_id'] = Variable<String>(commandId.value);
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    if (seriesIdsJson.present) {
      map['series_ids_json'] = Variable<String>(seriesIdsJson.value);
    }
    if (committedAt.present) {
      map['committed_at'] = Variable<DateTime>(committedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportCommitsCompanion(')
          ..write('commandId: $commandId, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('seriesIdsJson: $seriesIdsJson, ')
          ..write('committedAt: $committedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OwnedShareLinksTable extends OwnedShareLinks
    with TableInfo<$OwnedShareLinksTable, OwnedShareLinkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnedShareLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shareIdMeta = const VerificationMeta(
    'shareId',
  );
  @override
  late final GeneratedColumn<String> shareId = GeneratedColumn<String>(
    'share_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotVersionMeta = const VerificationMeta(
    'snapshotVersion',
  );
  @override
  late final GeneratedColumn<int> snapshotVersion = GeneratedColumn<int>(
    'snapshot_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryLabelsJsonMeta =
      const VerificationMeta('categoryLabelsJson');
  @override
  late final GeneratedColumn<String> categoryLabelsJson =
      GeneratedColumn<String>(
        'category_labels_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _routePathMeta = const VerificationMeta(
    'routePath',
  );
  @override
  late final GeneratedColumn<String> routePath = GeneratedColumn<String>(
    'route_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    shareId,
    snapshotVersion,
    itemCount,
    categoryLabelsJson,
    routePath,
    createdAt,
    expiresAt,
    revokedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'owned_share_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<OwnedShareLinkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('share_id')) {
      context.handle(
        _shareIdMeta,
        shareId.isAcceptableOrUnknown(data['share_id']!, _shareIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shareIdMeta);
    }
    if (data.containsKey('snapshot_version')) {
      context.handle(
        _snapshotVersionMeta,
        snapshotVersion.isAcceptableOrUnknown(
          data['snapshot_version']!,
          _snapshotVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotVersionMeta);
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCountMeta);
    }
    if (data.containsKey('category_labels_json')) {
      context.handle(
        _categoryLabelsJsonMeta,
        categoryLabelsJson.isAcceptableOrUnknown(
          data['category_labels_json']!,
          _categoryLabelsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryLabelsJsonMeta);
    }
    if (data.containsKey('route_path')) {
      context.handle(
        _routePathMeta,
        routePath.isAcceptableOrUnknown(data['route_path']!, _routePathMeta),
      );
    } else if (isInserting) {
      context.missing(_routePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shareId};
  @override
  OwnedShareLinkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnedShareLinkRow(
      shareId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}share_id'],
      )!,
      snapshotVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snapshot_version'],
      )!,
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      categoryLabelsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_labels_json'],
      )!,
      routePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      ),
    );
  }

  @override
  $OwnedShareLinksTable createAlias(String alias) {
    return $OwnedShareLinksTable(attachedDatabase, alias);
  }
}

class OwnedShareLinkRow extends DataClass
    implements Insertable<OwnedShareLinkRow> {
  final String shareId;
  final int snapshotVersion;
  final int itemCount;
  final String categoryLabelsJson;
  final String routePath;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  const OwnedShareLinkRow({
    required this.shareId,
    required this.snapshotVersion,
    required this.itemCount,
    required this.categoryLabelsJson,
    required this.routePath,
    required this.createdAt,
    required this.expiresAt,
    this.revokedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['share_id'] = Variable<String>(shareId);
    map['snapshot_version'] = Variable<int>(snapshotVersion);
    map['item_count'] = Variable<int>(itemCount);
    map['category_labels_json'] = Variable<String>(categoryLabelsJson);
    map['route_path'] = Variable<String>(routePath);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<DateTime>(revokedAt);
    }
    return map;
  }

  OwnedShareLinksCompanion toCompanion(bool nullToAbsent) {
    return OwnedShareLinksCompanion(
      shareId: Value(shareId),
      snapshotVersion: Value(snapshotVersion),
      itemCount: Value(itemCount),
      categoryLabelsJson: Value(categoryLabelsJson),
      routePath: Value(routePath),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
    );
  }

  factory OwnedShareLinkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnedShareLinkRow(
      shareId: serializer.fromJson<String>(json['shareId']),
      snapshotVersion: serializer.fromJson<int>(json['snapshotVersion']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      categoryLabelsJson: serializer.fromJson<String>(
        json['categoryLabelsJson'],
      ),
      routePath: serializer.fromJson<String>(json['routePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      revokedAt: serializer.fromJson<DateTime?>(json['revokedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shareId': serializer.toJson<String>(shareId),
      'snapshotVersion': serializer.toJson<int>(snapshotVersion),
      'itemCount': serializer.toJson<int>(itemCount),
      'categoryLabelsJson': serializer.toJson<String>(categoryLabelsJson),
      'routePath': serializer.toJson<String>(routePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'revokedAt': serializer.toJson<DateTime?>(revokedAt),
    };
  }

  OwnedShareLinkRow copyWith({
    String? shareId,
    int? snapshotVersion,
    int? itemCount,
    String? categoryLabelsJson,
    String? routePath,
    DateTime? createdAt,
    DateTime? expiresAt,
    Value<DateTime?> revokedAt = const Value.absent(),
  }) => OwnedShareLinkRow(
    shareId: shareId ?? this.shareId,
    snapshotVersion: snapshotVersion ?? this.snapshotVersion,
    itemCount: itemCount ?? this.itemCount,
    categoryLabelsJson: categoryLabelsJson ?? this.categoryLabelsJson,
    routePath: routePath ?? this.routePath,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
  );
  OwnedShareLinkRow copyWithCompanion(OwnedShareLinksCompanion data) {
    return OwnedShareLinkRow(
      shareId: data.shareId.present ? data.shareId.value : this.shareId,
      snapshotVersion: data.snapshotVersion.present
          ? data.snapshotVersion.value
          : this.snapshotVersion,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      categoryLabelsJson: data.categoryLabelsJson.present
          ? data.categoryLabelsJson.value
          : this.categoryLabelsJson,
      routePath: data.routePath.present ? data.routePath.value : this.routePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OwnedShareLinkRow(')
          ..write('shareId: $shareId, ')
          ..write('snapshotVersion: $snapshotVersion, ')
          ..write('itemCount: $itemCount, ')
          ..write('categoryLabelsJson: $categoryLabelsJson, ')
          ..write('routePath: $routePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('revokedAt: $revokedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    shareId,
    snapshotVersion,
    itemCount,
    categoryLabelsJson,
    routePath,
    createdAt,
    expiresAt,
    revokedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnedShareLinkRow &&
          other.shareId == this.shareId &&
          other.snapshotVersion == this.snapshotVersion &&
          other.itemCount == this.itemCount &&
          other.categoryLabelsJson == this.categoryLabelsJson &&
          other.routePath == this.routePath &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.revokedAt == this.revokedAt);
}

class OwnedShareLinksCompanion extends UpdateCompanion<OwnedShareLinkRow> {
  final Value<String> shareId;
  final Value<int> snapshotVersion;
  final Value<int> itemCount;
  final Value<String> categoryLabelsJson;
  final Value<String> routePath;
  final Value<DateTime> createdAt;
  final Value<DateTime> expiresAt;
  final Value<DateTime?> revokedAt;
  final Value<int> rowid;
  const OwnedShareLinksCompanion({
    this.shareId = const Value.absent(),
    this.snapshotVersion = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.categoryLabelsJson = const Value.absent(),
    this.routePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OwnedShareLinksCompanion.insert({
    required String shareId,
    required int snapshotVersion,
    required int itemCount,
    required String categoryLabelsJson,
    required String routePath,
    required DateTime createdAt,
    required DateTime expiresAt,
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : shareId = Value(shareId),
       snapshotVersion = Value(snapshotVersion),
       itemCount = Value(itemCount),
       categoryLabelsJson = Value(categoryLabelsJson),
       routePath = Value(routePath),
       createdAt = Value(createdAt),
       expiresAt = Value(expiresAt);
  static Insertable<OwnedShareLinkRow> custom({
    Expression<String>? shareId,
    Expression<int>? snapshotVersion,
    Expression<int>? itemCount,
    Expression<String>? categoryLabelsJson,
    Expression<String>? routePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? revokedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shareId != null) 'share_id': shareId,
      if (snapshotVersion != null) 'snapshot_version': snapshotVersion,
      if (itemCount != null) 'item_count': itemCount,
      if (categoryLabelsJson != null)
        'category_labels_json': categoryLabelsJson,
      if (routePath != null) 'route_path': routePath,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OwnedShareLinksCompanion copyWith({
    Value<String>? shareId,
    Value<int>? snapshotVersion,
    Value<int>? itemCount,
    Value<String>? categoryLabelsJson,
    Value<String>? routePath,
    Value<DateTime>? createdAt,
    Value<DateTime>? expiresAt,
    Value<DateTime?>? revokedAt,
    Value<int>? rowid,
  }) {
    return OwnedShareLinksCompanion(
      shareId: shareId ?? this.shareId,
      snapshotVersion: snapshotVersion ?? this.snapshotVersion,
      itemCount: itemCount ?? this.itemCount,
      categoryLabelsJson: categoryLabelsJson ?? this.categoryLabelsJson,
      routePath: routePath ?? this.routePath,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt ?? this.revokedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shareId.present) {
      map['share_id'] = Variable<String>(shareId.value);
    }
    if (snapshotVersion.present) {
      map['snapshot_version'] = Variable<int>(snapshotVersion.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (categoryLabelsJson.present) {
      map['category_labels_json'] = Variable<String>(categoryLabelsJson.value);
    }
    if (routePath.present) {
      map['route_path'] = Variable<String>(routePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OwnedShareLinksCompanion(')
          ..write('shareId: $shareId, ')
          ..write('snapshotVersion: $snapshotVersion, ')
          ..write('itemCount: $itemCount, ')
          ..write('categoryLabelsJson: $categoryLabelsJson, ')
          ..write('routePath: $routePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingShareCreationsTable extends PendingShareCreations
    with TableInfo<$PendingShareCreationsTable, PendingShareRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingShareCreationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idempotencyKey,
    payloadJson,
    expiresAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_share_creations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingShareRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idempotencyKey};
  @override
  PendingShareRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingShareRow(
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingShareCreationsTable createAlias(String alias) {
    return $PendingShareCreationsTable(attachedDatabase, alias);
  }
}

class PendingShareRow extends DataClass implements Insertable<PendingShareRow> {
  final String idempotencyKey;
  final String payloadJson;
  final DateTime expiresAt;
  final DateTime createdAt;
  const PendingShareRow({
    required this.idempotencyKey,
    required this.payloadJson,
    required this.expiresAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['payload_json'] = Variable<String>(payloadJson);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingShareCreationsCompanion toCompanion(bool nullToAbsent) {
    return PendingShareCreationsCompanion(
      idempotencyKey: Value(idempotencyKey),
      payloadJson: Value(payloadJson),
      expiresAt: Value(expiresAt),
      createdAt: Value(createdAt),
    );
  }

  factory PendingShareRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingShareRow(
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingShareRow copyWith({
    String? idempotencyKey,
    String? payloadJson,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) => PendingShareRow(
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    payloadJson: payloadJson ?? this.payloadJson,
    expiresAt: expiresAt ?? this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingShareRow copyWithCompanion(PendingShareCreationsCompanion data) {
    return PendingShareRow(
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingShareRow(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(idempotencyKey, payloadJson, expiresAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingShareRow &&
          other.idempotencyKey == this.idempotencyKey &&
          other.payloadJson == this.payloadJson &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt);
}

class PendingShareCreationsCompanion extends UpdateCompanion<PendingShareRow> {
  final Value<String> idempotencyKey;
  final Value<String> payloadJson;
  final Value<DateTime> expiresAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PendingShareCreationsCompanion({
    this.idempotencyKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingShareCreationsCompanion.insert({
    required String idempotencyKey,
    required String payloadJson,
    required DateTime expiresAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : idempotencyKey = Value(idempotencyKey),
       payloadJson = Value(payloadJson),
       expiresAt = Value(expiresAt),
       createdAt = Value(createdAt);
  static Insertable<PendingShareRow> custom({
    Expression<String>? idempotencyKey,
    Expression<String>? payloadJson,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingShareCreationsCompanion copyWith({
    Value<String>? idempotencyKey,
    Value<String>? payloadJson,
    Value<DateTime>? expiresAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingShareCreationsCompanion(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      payloadJson: payloadJson ?? this.payloadJson,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingShareCreationsCompanion(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValueRow extends DataClass implements Insertable<KeyValueRow> {
  final String key;
  final String value;
  const KeyValueRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValueRow copyWith({String? key, String? value}) =>
      KeyValueRow(key: key ?? this.key, value: value ?? this.value);
  KeyValueRow copyWithCompanion(KeyValuesCompanion data) {
    return KeyValueRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueRow &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValueRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValueRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilePreferencesTable extends ProfilePreferences
    with TableInfo<$ProfilePreferencesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilePreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, displayName, photoPath, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfilePreferencesTable createAlias(String alias) {
    return $ProfilePreferencesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final int id;
  final String? displayName;

  /// Absolute path of the app-private 512x512 JPEG, or null.
  final String? photoPath;
  final DateTime updatedAt;
  const ProfileRow({
    required this.id,
    this.displayName,
    this.photoPath,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfilePreferencesCompanion toCompanion(bool nullToAbsent) {
    return ProfilePreferencesCompanion(
      id: Value(id),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String?>(displayName),
      'photoPath': serializer.toJson<String?>(photoPath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProfileRow copyWith({
    int? id,
    Value<String?> displayName = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    DateTime? updatedAt,
  }) => ProfileRow(
    id: id ?? this.id,
    displayName: displayName.present ? displayName.value : this.displayName,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfileRow copyWithCompanion(ProfilePreferencesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('photoPath: $photoPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, photoPath, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.photoPath == this.photoPath &&
          other.updatedAt == this.updatedAt);
}

class ProfilePreferencesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<int> id;
  final Value<String?> displayName;
  final Value<String?> photoPath;
  final Value<DateTime> updatedAt;
  const ProfilePreferencesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProfilePreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoPath = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<ProfileRow> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? photoPath,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (photoPath != null) 'photo_path': photoPath,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProfilePreferencesCompanion copyWith({
    Value<int>? id,
    Value<String?>? displayName,
    Value<String?>? photoPath,
    Value<DateTime>? updatedAt,
  }) {
    return ProfilePreferencesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      photoPath: photoPath ?? this.photoPath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilePreferencesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('photoPath: $photoPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ScheduleSeriesTableTable scheduleSeriesTable =
      $ScheduleSeriesTableTable(this);
  late final $OccurrenceExceptionsTable occurrenceExceptions =
      $OccurrenceExceptionsTable(this);
  late final $AlertRulesTable alertRules = $AlertRulesTable(this);
  late final $ScheduledAlertsTable scheduledAlerts = $ScheduledAlertsTable(
    this,
  );
  late final $ReconciliationOutboxTable reconciliationOutbox =
      $ReconciliationOutboxTable(this);
  late final $WidgetConfigurationsTable widgetConfigurations =
      $WidgetConfigurationsTable(this);
  late final $AppearancePreferencesTable appearancePreferences =
      $AppearancePreferencesTable(this);
  late final $ImportDraftsTable importDrafts = $ImportDraftsTable(this);
  late final $ImportProvenanceTable importProvenance = $ImportProvenanceTable(
    this,
  );
  late final $ImportCommitsTable importCommits = $ImportCommitsTable(this);
  late final $OwnedShareLinksTable ownedShareLinks = $OwnedShareLinksTable(
    this,
  );
  late final $PendingShareCreationsTable pendingShareCreations =
      $PendingShareCreationsTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $ProfilePreferencesTable profilePreferences =
      $ProfilePreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    scheduleSeriesTable,
    occurrenceExceptions,
    alertRules,
    scheduledAlerts,
    reconciliationOutbox,
    widgetConfigurations,
    appearancePreferences,
    importDrafts,
    importProvenance,
    importCommits,
    ownedShareLinks,
    pendingShareCreations,
    keyValues,
    profilePreferences,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedule_series', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'schedule_series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('occurrence_exceptions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'schedule_series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('alert_rules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'schedule_series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('import_provenance', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  Value<String?> colorKey,
  Value<bool> builtIn,
  required int sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> colorKey,
  Value<bool> builtIn,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScheduleSeriesTableTable, List<SeriesRow>>
  _scheduleSeriesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.scheduleSeriesTable,
        aliasName: 'categories__id__schedule_series__category_id',
      );

  $$ScheduleSeriesTableTableProcessedTableManager get scheduleSeriesTableRefs {
    final manager = $$ScheduleSeriesTableTableTableManager(
      $_db,
      $_db.scheduleSeriesTable,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scheduleSeriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> scheduleSeriesTableRefs(
    Expression<bool> Function($$ScheduleSeriesTableTableFilterComposer f) f,
  ) {
    final $$ScheduleSeriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleSeriesTable,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleSeriesTableTableFilterComposer(
            $db: $db,
            $table: $db.scheduleSeriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  GeneratedColumn<bool> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> scheduleSeriesTableRefs<T extends Object>(
    Expression<T> Function($$ScheduleSeriesTableTableAnnotationComposer a) f,
  ) {
    final $$ScheduleSeriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.scheduleSeriesTable,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleSeriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduleSeriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({bool scheduleSeriesTableRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> colorKey = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                colorKey: colorKey,
                builtIn: builtIn,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> colorKey = const Value.absent(),
                Value<bool> builtIn = const Value.absent(),
                required int sortOrder,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                colorKey: colorKey,
                builtIn: builtIn,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scheduleSeriesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (scheduleSeriesTableRefs) db.scheduleSeriesTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scheduleSeriesTableRefs)
                    await $_getPrefetchedData<
                      CategoryRow,
                      $CategoriesTable,
                      SeriesRow
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._scheduleSeriesTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).scheduleSeriesTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({bool scheduleSeriesTableRefs})
    >;
typedef $$ScheduleSeriesTableTableCreateCompanionBuilder =
    ScheduleSeriesTableCompanion Function({
      required String id,
      required int revision,
      required String title,
      Value<String?> categoryId,
      required String timeKind,
      required String startDate,
      Value<String?> startTime,
      Value<String?> timeZone,
      Value<String?> endTime,
      Value<int?> endDayOffset,
      Value<String?> seedTimeResolution,
      Value<String?> endTimeResolution,
      Value<String?> endDateExclusive,
      Value<String?> recurrenceFrequency,
      Value<String?> recurrenceWeekdays,
      Value<String?> recurrenceUntil,
      Value<String?> location,
      Value<String?> professor,
      Value<String?> subtitle,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ScheduleSeriesTableTableUpdateCompanionBuilder =
    ScheduleSeriesTableCompanion Function({
      Value<String> id,
      Value<int> revision,
      Value<String> title,
      Value<String?> categoryId,
      Value<String> timeKind,
      Value<String> startDate,
      Value<String?> startTime,
      Value<String?> timeZone,
      Value<String?> endTime,
      Value<int?> endDayOffset,
      Value<String?> seedTimeResolution,
      Value<String?> endTimeResolution,
      Value<String?> endDateExclusive,
      Value<String?> recurrenceFrequency,
      Value<String?> recurrenceWeekdays,
      Value<String?> recurrenceUntil,
      Value<String?> location,
      Value<String?> professor,
      Value<String?> subtitle,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ScheduleSeriesTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $ScheduleSeriesTableTable, SeriesRow> {
  $$ScheduleSeriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('schedule_series__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$OccurrenceExceptionsTable, List<ExceptionRow>>
  _occurrenceExceptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.occurrenceExceptions,
        aliasName: 'schedule_series__id__occurrence_exceptions__series_id',
      );

  $$OccurrenceExceptionsTableProcessedTableManager
  get occurrenceExceptionsRefs {
    final manager = $$OccurrenceExceptionsTableTableManager(
      $_db,
      $_db.occurrenceExceptions,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _occurrenceExceptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AlertRulesTable, List<AlertRuleRow>>
  _alertRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.alertRules,
    aliasName: 'schedule_series__id__alert_rules__series_id',
  );

  $$AlertRulesTableProcessedTableManager get alertRulesRefs {
    final manager = $$AlertRulesTableTableManager(
      $_db,
      $_db.alertRules,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_alertRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ImportProvenanceTable, List<ProvenanceRow>>
  _importProvenanceRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.importProvenance,
    aliasName: 'schedule_series__id__import_provenance__series_id',
  );

  $$ImportProvenanceTableProcessedTableManager get importProvenanceRefs {
    final manager = $$ImportProvenanceTableTableManager(
      $_db,
      $_db.importProvenance,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _importProvenanceRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScheduleSeriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleSeriesTableTable> {
  $$ScheduleSeriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeKind => $composableBuilder(
    column: $table.timeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endDayOffset => $composableBuilder(
    column: $table.endDayOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seedTimeResolution => $composableBuilder(
    column: $table.seedTimeResolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTimeResolution => $composableBuilder(
    column: $table.endTimeResolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDateExclusive => $composableBuilder(
    column: $table.endDateExclusive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceFrequency => $composableBuilder(
    column: $table.recurrenceFrequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceWeekdays => $composableBuilder(
    column: $table.recurrenceWeekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceUntil => $composableBuilder(
    column: $table.recurrenceUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get professor => $composableBuilder(
    column: $table.professor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> occurrenceExceptionsRefs(
    Expression<bool> Function($$OccurrenceExceptionsTableFilterComposer f) f,
  ) {
    final $$OccurrenceExceptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrenceExceptions,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrenceExceptionsTableFilterComposer(
            $db: $db,
            $table: $db.occurrenceExceptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> alertRulesRefs(
    Expression<bool> Function($$AlertRulesTableFilterComposer f) f,
  ) {
    final $$AlertRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alertRules,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertRulesTableFilterComposer(
            $db: $db,
            $table: $db.alertRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> importProvenanceRefs(
    Expression<bool> Function($$ImportProvenanceTableFilterComposer f) f,
  ) {
    final $$ImportProvenanceTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importProvenance,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportProvenanceTableFilterComposer(
            $db: $db,
            $table: $db.importProvenance,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScheduleSeriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleSeriesTableTable> {
  $$ScheduleSeriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeKind => $composableBuilder(
    column: $table.timeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDayOffset => $composableBuilder(
    column: $table.endDayOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seedTimeResolution => $composableBuilder(
    column: $table.seedTimeResolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTimeResolution => $composableBuilder(
    column: $table.endTimeResolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDateExclusive => $composableBuilder(
    column: $table.endDateExclusive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceFrequency => $composableBuilder(
    column: $table.recurrenceFrequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceWeekdays => $composableBuilder(
    column: $table.recurrenceWeekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceUntil => $composableBuilder(
    column: $table.recurrenceUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get professor => $composableBuilder(
    column: $table.professor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleSeriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleSeriesTableTable> {
  $$ScheduleSeriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get timeKind =>
      $composableBuilder(column: $table.timeKind, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get endDayOffset => $composableBuilder(
    column: $table.endDayOffset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seedTimeResolution => $composableBuilder(
    column: $table.seedTimeResolution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endTimeResolution => $composableBuilder(
    column: $table.endTimeResolution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endDateExclusive => $composableBuilder(
    column: $table.endDateExclusive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceFrequency => $composableBuilder(
    column: $table.recurrenceFrequency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceWeekdays => $composableBuilder(
    column: $table.recurrenceWeekdays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceUntil => $composableBuilder(
    column: $table.recurrenceUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get professor =>
      $composableBuilder(column: $table.professor, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> occurrenceExceptionsRefs<T extends Object>(
    Expression<T> Function($$OccurrenceExceptionsTableAnnotationComposer a) f,
  ) {
    final $$OccurrenceExceptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.occurrenceExceptions,
          getReferencedColumn: (t) => t.seriesId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OccurrenceExceptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.occurrenceExceptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> alertRulesRefs<T extends Object>(
    Expression<T> Function($$AlertRulesTableAnnotationComposer a) f,
  ) {
    final $$AlertRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alertRules,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.alertRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> importProvenanceRefs<T extends Object>(
    Expression<T> Function($$ImportProvenanceTableAnnotationComposer a) f,
  ) {
    final $$ImportProvenanceTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importProvenance,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportProvenanceTableAnnotationComposer(
            $db: $db,
            $table: $db.importProvenance,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScheduleSeriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleSeriesTableTable,
          SeriesRow,
          $$ScheduleSeriesTableTableFilterComposer,
          $$ScheduleSeriesTableTableOrderingComposer,
          $$ScheduleSeriesTableTableAnnotationComposer,
          $$ScheduleSeriesTableTableCreateCompanionBuilder,
          $$ScheduleSeriesTableTableUpdateCompanionBuilder,
          (SeriesRow, $$ScheduleSeriesTableTableReferences),
          SeriesRow,
          PrefetchHooks Function({
            bool categoryId,
            bool occurrenceExceptionsRefs,
            bool alertRulesRefs,
            bool importProvenanceRefs,
          })
        > {
  $$ScheduleSeriesTableTableTableManager(
    _$AppDatabase db,
    $ScheduleSeriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleSeriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleSeriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ScheduleSeriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> timeKind = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<int?> endDayOffset = const Value.absent(),
                Value<String?> seedTimeResolution = const Value.absent(),
                Value<String?> endTimeResolution = const Value.absent(),
                Value<String?> endDateExclusive = const Value.absent(),
                Value<String?> recurrenceFrequency = const Value.absent(),
                Value<String?> recurrenceWeekdays = const Value.absent(),
                Value<String?> recurrenceUntil = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> professor = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduleSeriesTableCompanion(
                id: id,
                revision: revision,
                title: title,
                categoryId: categoryId,
                timeKind: timeKind,
                startDate: startDate,
                startTime: startTime,
                timeZone: timeZone,
                endTime: endTime,
                endDayOffset: endDayOffset,
                seedTimeResolution: seedTimeResolution,
                endTimeResolution: endTimeResolution,
                endDateExclusive: endDateExclusive,
                recurrenceFrequency: recurrenceFrequency,
                recurrenceWeekdays: recurrenceWeekdays,
                recurrenceUntil: recurrenceUntil,
                location: location,
                professor: professor,
                subtitle: subtitle,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int revision,
                required String title,
                Value<String?> categoryId = const Value.absent(),
                required String timeKind,
                required String startDate,
                Value<String?> startTime = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<int?> endDayOffset = const Value.absent(),
                Value<String?> seedTimeResolution = const Value.absent(),
                Value<String?> endTimeResolution = const Value.absent(),
                Value<String?> endDateExclusive = const Value.absent(),
                Value<String?> recurrenceFrequency = const Value.absent(),
                Value<String?> recurrenceWeekdays = const Value.absent(),
                Value<String?> recurrenceUntil = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> professor = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ScheduleSeriesTableCompanion.insert(
                id: id,
                revision: revision,
                title: title,
                categoryId: categoryId,
                timeKind: timeKind,
                startDate: startDate,
                startTime: startTime,
                timeZone: timeZone,
                endTime: endTime,
                endDayOffset: endDayOffset,
                seedTimeResolution: seedTimeResolution,
                endTimeResolution: endTimeResolution,
                endDateExclusive: endDateExclusive,
                recurrenceFrequency: recurrenceFrequency,
                recurrenceWeekdays: recurrenceWeekdays,
                recurrenceUntil: recurrenceUntil,
                location: location,
                professor: professor,
                subtitle: subtitle,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduleSeriesTableTable, SeriesRow>(table),
                  $$ScheduleSeriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                occurrenceExceptionsRefs = false,
                alertRulesRefs = false,
                importProvenanceRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (occurrenceExceptionsRefs) db.occurrenceExceptions,
                    if (alertRulesRefs) db.alertRules,
                    if (importProvenanceRefs) db.importProvenance,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable:
                                $$ScheduleSeriesTableTableReferences
                                    ._categoryIdTable(db),
                            referencedColumn:
                                $$ScheduleSeriesTableTableReferences
                                    ._categoryIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (occurrenceExceptionsRefs)
                        await $_getPrefetchedData<
                          SeriesRow,
                          $ScheduleSeriesTableTable,
                          ExceptionRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScheduleSeriesTableTableReferences
                              ._occurrenceExceptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScheduleSeriesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).occurrenceExceptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (alertRulesRefs)
                        await $_getPrefetchedData<
                          SeriesRow,
                          $ScheduleSeriesTableTable,
                          AlertRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScheduleSeriesTableTableReferences
                              ._alertRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScheduleSeriesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).alertRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (importProvenanceRefs)
                        await $_getPrefetchedData<
                          SeriesRow,
                          $ScheduleSeriesTableTable,
                          ProvenanceRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScheduleSeriesTableTableReferences
                              ._importProvenanceRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScheduleSeriesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).importProvenanceRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScheduleSeriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleSeriesTableTable,
      SeriesRow,
      $$ScheduleSeriesTableTableFilterComposer,
      $$ScheduleSeriesTableTableOrderingComposer,
      $$ScheduleSeriesTableTableAnnotationComposer,
      $$ScheduleSeriesTableTableCreateCompanionBuilder,
      $$ScheduleSeriesTableTableUpdateCompanionBuilder,
      (SeriesRow, $$ScheduleSeriesTableTableReferences),
      SeriesRow,
      PrefetchHooks Function({
        bool categoryId,
        bool occurrenceExceptionsRefs,
        bool alertRulesRefs,
        bool importProvenanceRefs,
      })
    >;
typedef $$OccurrenceExceptionsTableCreateCompanionBuilder =
    OccurrenceExceptionsCompanion Function({
      required String id,
      required String seriesId,
      required String originalKey,
      required String action,
      Value<String?> replacementJson,
      required int revision,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$OccurrenceExceptionsTableUpdateCompanionBuilder =
    OccurrenceExceptionsCompanion Function({
      Value<String> id,
      Value<String> seriesId,
      Value<String> originalKey,
      Value<String> action,
      Value<String?> replacementJson,
      Value<int> revision,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$OccurrenceExceptionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OccurrenceExceptionsTable,
          ExceptionRow
        > {
  $$OccurrenceExceptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScheduleSeriesTableTable _seriesIdTable(_$AppDatabase db) => db
      .scheduleSeriesTable
      .createAlias('occurrence_exceptions__series_id__schedule_series__id');

  $$ScheduleSeriesTableTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<String>('series_id')!;

    final manager = $$ScheduleSeriesTableTableTableManager(
      $_db,
      $_db.scheduleSeriesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OccurrenceExceptionsTableFilterComposer
    extends Composer<_$AppDatabase, $OccurrenceExceptionsTable> {
  $$OccurrenceExceptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalKey => $composableBuilder(
    column: $table.originalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacementJson => $composableBuilder(
    column: $table.replacementJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScheduleSeriesTableTableFilterComposer get seriesId {
    final $$ScheduleSeriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.scheduleSeriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleSeriesTableTableFilterComposer(
            $db: $db,
            $table: $db.scheduleSeriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrenceExceptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $OccurrenceExceptionsTable> {
  $$OccurrenceExceptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalKey => $composableBuilder(
    column: $table.originalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacementJson => $composableBuilder(
    column: $table.replacementJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScheduleSeriesTableTableOrderingComposer get seriesId {
    final $$ScheduleSeriesTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.seriesId,
          referencedTable: $db.scheduleSeriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleSeriesTableTableOrderingComposer(
                $db: $db,
                $table: $db.scheduleSeriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$OccurrenceExceptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccurrenceExceptionsTable> {
  $$OccurrenceExceptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalKey => $composableBuilder(
    column: $table.originalKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get replacementJson => $composableBuilder(
    column: $table.replacementJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ScheduleSeriesTableTableAnnotationComposer get seriesId {
    final $$ScheduleSeriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.seriesId,
          referencedTable: $db.scheduleSeriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleSeriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduleSeriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$OccurrenceExceptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrenceExceptionsTable,
          ExceptionRow,
          $$OccurrenceExceptionsTableFilterComposer,
          $$OccurrenceExceptionsTableOrderingComposer,
          $$OccurrenceExceptionsTableAnnotationComposer,
          $$OccurrenceExceptionsTableCreateCompanionBuilder,
          $$OccurrenceExceptionsTableUpdateCompanionBuilder,
          (ExceptionRow, $$OccurrenceExceptionsTableReferences),
          ExceptionRow,
          PrefetchHooks Function({bool seriesId})
        > {
  $$OccurrenceExceptionsTableTableManager(
    _$AppDatabase db,
    $OccurrenceExceptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccurrenceExceptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccurrenceExceptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OccurrenceExceptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String> originalKey = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> replacementJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrenceExceptionsCompanion(
                id: id,
                seriesId: seriesId,
                originalKey: originalKey,
                action: action,
                replacementJson: replacementJson,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String seriesId,
                required String originalKey,
                required String action,
                Value<String?> replacementJson = const Value.absent(),
                required int revision,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OccurrenceExceptionsCompanion.insert(
                id: id,
                seriesId: seriesId,
                originalKey: originalKey,
                action: action,
                replacementJson: replacementJson,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OccurrenceExceptionsTable, ExceptionRow>(table),
                  $$OccurrenceExceptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({seriesId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (seriesId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.seriesId,
                        referencedTable: $$OccurrenceExceptionsTableReferences
                            ._seriesIdTable(db),
                        referencedColumn: $$OccurrenceExceptionsTableReferences
                            ._seriesIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OccurrenceExceptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrenceExceptionsTable,
      ExceptionRow,
      $$OccurrenceExceptionsTableFilterComposer,
      $$OccurrenceExceptionsTableOrderingComposer,
      $$OccurrenceExceptionsTableAnnotationComposer,
      $$OccurrenceExceptionsTableCreateCompanionBuilder,
      $$OccurrenceExceptionsTableUpdateCompanionBuilder,
      (ExceptionRow, $$OccurrenceExceptionsTableReferences),
      ExceptionRow,
      PrefetchHooks Function({bool seriesId})
    >;
typedef $$AlertRulesTableCreateCompanionBuilder = AlertRulesCompanion Function({
  required String id,
  required String seriesId,
  Value<String> scopeKey,
  required String kind,
  required bool enabled,
  required int offsetMinutes,
  Value<String?> dateOnlyAnchorTime,
  Value<String?> dateOnlyAnchorZone,
  required String lockScreenDetails,
  required String presentationPreference,
  Value<int?> snoozeMinutes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AlertRulesTableUpdateCompanionBuilder = AlertRulesCompanion Function({
  Value<String> id,
  Value<String> seriesId,
  Value<String> scopeKey,
  Value<String> kind,
  Value<bool> enabled,
  Value<int> offsetMinutes,
  Value<String?> dateOnlyAnchorTime,
  Value<String?> dateOnlyAnchorZone,
  Value<String> lockScreenDetails,
  Value<String> presentationPreference,
  Value<int?> snoozeMinutes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$AlertRulesTableReferences
    extends BaseReferences<_$AppDatabase, $AlertRulesTable, AlertRuleRow> {
  $$AlertRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScheduleSeriesTableTable _seriesIdTable(_$AppDatabase db) => db
      .scheduleSeriesTable
      .createAlias('alert_rules__series_id__schedule_series__id');

  $$ScheduleSeriesTableTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<String>('series_id')!;

    final manager = $$ScheduleSeriesTableTableTableManager(
      $_db,
      $_db.scheduleSeriesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AlertRulesTableFilterComposer
    extends Composer<_$AppDatabase, $AlertRulesTable> {
  $$AlertRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateOnlyAnchorTime => $composableBuilder(
    column: $table.dateOnlyAnchorTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateOnlyAnchorZone => $composableBuilder(
    column: $table.dateOnlyAnchorZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lockScreenDetails => $composableBuilder(
    column: $table.lockScreenDetails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presentationPreference => $composableBuilder(
    column: $table.presentationPreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScheduleSeriesTableTableFilterComposer get seriesId {
    final $$ScheduleSeriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.scheduleSeriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleSeriesTableTableFilterComposer(
            $db: $db,
            $table: $db.scheduleSeriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertRulesTable> {
  $$AlertRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateOnlyAnchorTime => $composableBuilder(
    column: $table.dateOnlyAnchorTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateOnlyAnchorZone => $composableBuilder(
    column: $table.dateOnlyAnchorZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lockScreenDetails => $composableBuilder(
    column: $table.lockScreenDetails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presentationPreference => $composableBuilder(
    column: $table.presentationPreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScheduleSeriesTableTableOrderingComposer get seriesId {
    final $$ScheduleSeriesTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.seriesId,
          referencedTable: $db.scheduleSeriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleSeriesTableTableOrderingComposer(
                $db: $db,
                $table: $db.scheduleSeriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AlertRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertRulesTable> {
  $$AlertRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dateOnlyAnchorTime => $composableBuilder(
    column: $table.dateOnlyAnchorTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dateOnlyAnchorZone => $composableBuilder(
    column: $table.dateOnlyAnchorZone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lockScreenDetails => $composableBuilder(
    column: $table.lockScreenDetails,
    builder: (column) => column,
  );

  GeneratedColumn<String> get presentationPreference => $composableBuilder(
    column: $table.presentationPreference,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ScheduleSeriesTableTableAnnotationComposer get seriesId {
    final $$ScheduleSeriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.seriesId,
          referencedTable: $db.scheduleSeriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleSeriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduleSeriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AlertRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertRulesTable,
          AlertRuleRow,
          $$AlertRulesTableFilterComposer,
          $$AlertRulesTableOrderingComposer,
          $$AlertRulesTableAnnotationComposer,
          $$AlertRulesTableCreateCompanionBuilder,
          $$AlertRulesTableUpdateCompanionBuilder,
          (AlertRuleRow, $$AlertRulesTableReferences),
          AlertRuleRow,
          PrefetchHooks Function({bool seriesId})
        > {
  $$AlertRulesTableTableManager(_$AppDatabase db, $AlertRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> offsetMinutes = const Value.absent(),
                Value<String?> dateOnlyAnchorTime = const Value.absent(),
                Value<String?> dateOnlyAnchorZone = const Value.absent(),
                Value<String> lockScreenDetails = const Value.absent(),
                Value<String> presentationPreference = const Value.absent(),
                Value<int?> snoozeMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertRulesCompanion(
                id: id,
                seriesId: seriesId,
                scopeKey: scopeKey,
                kind: kind,
                enabled: enabled,
                offsetMinutes: offsetMinutes,
                dateOnlyAnchorTime: dateOnlyAnchorTime,
                dateOnlyAnchorZone: dateOnlyAnchorZone,
                lockScreenDetails: lockScreenDetails,
                presentationPreference: presentationPreference,
                snoozeMinutes: snoozeMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String seriesId,
                Value<String> scopeKey = const Value.absent(),
                required String kind,
                required bool enabled,
                required int offsetMinutes,
                Value<String?> dateOnlyAnchorTime = const Value.absent(),
                Value<String?> dateOnlyAnchorZone = const Value.absent(),
                required String lockScreenDetails,
                required String presentationPreference,
                Value<int?> snoozeMinutes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AlertRulesCompanion.insert(
                id: id,
                seriesId: seriesId,
                scopeKey: scopeKey,
                kind: kind,
                enabled: enabled,
                offsetMinutes: offsetMinutes,
                dateOnlyAnchorTime: dateOnlyAnchorTime,
                dateOnlyAnchorZone: dateOnlyAnchorZone,
                lockScreenDetails: lockScreenDetails,
                presentationPreference: presentationPreference,
                snoozeMinutes: snoozeMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlertRulesTable, AlertRuleRow>(table),
                  $$AlertRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({seriesId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (seriesId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.seriesId,
                        referencedTable: $$AlertRulesTableReferences
                            ._seriesIdTable(db),
                        referencedColumn: $$AlertRulesTableReferences
                            ._seriesIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AlertRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertRulesTable,
      AlertRuleRow,
      $$AlertRulesTableFilterComposer,
      $$AlertRulesTableOrderingComposer,
      $$AlertRulesTableAnnotationComposer,
      $$AlertRulesTableCreateCompanionBuilder,
      $$AlertRulesTableUpdateCompanionBuilder,
      (AlertRuleRow, $$AlertRulesTableReferences),
      AlertRuleRow,
      PrefetchHooks Function({bool seriesId})
    >;
typedef $$ScheduledAlertsTableCreateCompanionBuilder =
    ScheduledAlertsCompanion Function({
      required String requestKey,
      required String ruleId,
      required String seriesId,
      required String occurrenceKey,
      required String kind,
      required String platform,
      required int sourceRevision,
      Value<String?> nativeRequestId,
      required DateTime triggerAt,
      required String status,
      Value<String?> errorCode,
      required DateTime lastReconciledAt,
      Value<int> rowid,
    });
typedef $$ScheduledAlertsTableUpdateCompanionBuilder =
    ScheduledAlertsCompanion Function({
      Value<String> requestKey,
      Value<String> ruleId,
      Value<String> seriesId,
      Value<String> occurrenceKey,
      Value<String> kind,
      Value<String> platform,
      Value<int> sourceRevision,
      Value<String?> nativeRequestId,
      Value<DateTime> triggerAt,
      Value<String> status,
      Value<String?> errorCode,
      Value<DateTime> lastReconciledAt,
      Value<int> rowid,
    });

class $$ScheduledAlertsTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduledAlertsTable> {
  $$ScheduledAlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get requestKey => $composableBuilder(
    column: $table.requestKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nativeRequestId => $composableBuilder(
    column: $table.nativeRequestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get triggerAt => $composableBuilder(
    column: $table.triggerAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReconciledAt => $composableBuilder(
    column: $table.lastReconciledAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScheduledAlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduledAlertsTable> {
  $$ScheduledAlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get requestKey => $composableBuilder(
    column: $table.requestKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nativeRequestId => $composableBuilder(
    column: $table.nativeRequestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get triggerAt => $composableBuilder(
    column: $table.triggerAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReconciledAt => $composableBuilder(
    column: $table.lastReconciledAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScheduledAlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduledAlertsTable> {
  $$ScheduledAlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get requestKey => $composableBuilder(
    column: $table.requestKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleId =>
      $composableBuilder(column: $table.ruleId, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nativeRequestId => $composableBuilder(
    column: $table.nativeRequestId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get triggerAt =>
      $composableBuilder(column: $table.triggerAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReconciledAt => $composableBuilder(
    column: $table.lastReconciledAt,
    builder: (column) => column,
  );
}

class $$ScheduledAlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduledAlertsTable,
          ScheduledAlertRow,
          $$ScheduledAlertsTableFilterComposer,
          $$ScheduledAlertsTableOrderingComposer,
          $$ScheduledAlertsTableAnnotationComposer,
          $$ScheduledAlertsTableCreateCompanionBuilder,
          $$ScheduledAlertsTableUpdateCompanionBuilder,
          (
            ScheduledAlertRow,
            BaseReferences<
              _$AppDatabase,
              $ScheduledAlertsTable,
              ScheduledAlertRow
            >,
          ),
          ScheduledAlertRow,
          PrefetchHooks Function()
        > {
  $$ScheduledAlertsTableTableManager(
    _$AppDatabase db,
    $ScheduledAlertsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduledAlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduledAlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduledAlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> requestKey = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String> occurrenceKey = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<int> sourceRevision = const Value.absent(),
                Value<String?> nativeRequestId = const Value.absent(),
                Value<DateTime> triggerAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<DateTime> lastReconciledAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduledAlertsCompanion(
                requestKey: requestKey,
                ruleId: ruleId,
                seriesId: seriesId,
                occurrenceKey: occurrenceKey,
                kind: kind,
                platform: platform,
                sourceRevision: sourceRevision,
                nativeRequestId: nativeRequestId,
                triggerAt: triggerAt,
                status: status,
                errorCode: errorCode,
                lastReconciledAt: lastReconciledAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String requestKey,
                required String ruleId,
                required String seriesId,
                required String occurrenceKey,
                required String kind,
                required String platform,
                required int sourceRevision,
                Value<String?> nativeRequestId = const Value.absent(),
                required DateTime triggerAt,
                required String status,
                Value<String?> errorCode = const Value.absent(),
                required DateTime lastReconciledAt,
                Value<int> rowid = const Value.absent(),
              }) => ScheduledAlertsCompanion.insert(
                requestKey: requestKey,
                ruleId: ruleId,
                seriesId: seriesId,
                occurrenceKey: occurrenceKey,
                kind: kind,
                platform: platform,
                sourceRevision: sourceRevision,
                nativeRequestId: nativeRequestId,
                triggerAt: triggerAt,
                status: status,
                errorCode: errorCode,
                lastReconciledAt: lastReconciledAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduledAlertsTable, ScheduledAlertRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ScheduledAlertsTable,
                    ScheduledAlertRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduledAlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduledAlertsTable,
      ScheduledAlertRow,
      $$ScheduledAlertsTableFilterComposer,
      $$ScheduledAlertsTableOrderingComposer,
      $$ScheduledAlertsTableAnnotationComposer,
      $$ScheduledAlertsTableCreateCompanionBuilder,
      $$ScheduledAlertsTableUpdateCompanionBuilder,
      (
        ScheduledAlertRow,
        BaseReferences<_$AppDatabase, $ScheduledAlertsTable, ScheduledAlertRow>,
      ),
      ScheduledAlertRow,
      PrefetchHooks Function()
    >;
typedef $$ReconciliationOutboxTableCreateCompanionBuilder =
    ReconciliationOutboxCompanion Function({
      Value<int> id,
      required String operationKey,
      required String reason,
      required int sourceRevision,
      required String status,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      required DateTime createdAt,
    });
typedef $$ReconciliationOutboxTableUpdateCompanionBuilder =
    ReconciliationOutboxCompanion Function({
      Value<int> id,
      Value<String> operationKey,
      Value<String> reason,
      Value<int> sourceRevision,
      Value<String> status,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime> createdAt,
    });

class $$ReconciliationOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $ReconciliationOutboxTable> {
  $$ReconciliationOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationKey => $composableBuilder(
    column: $table.operationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReconciliationOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $ReconciliationOutboxTable> {
  $$ReconciliationOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationKey => $composableBuilder(
    column: $table.operationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReconciliationOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReconciliationOutboxTable> {
  $$ReconciliationOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationKey => $composableBuilder(
    column: $table.operationKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReconciliationOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReconciliationOutboxTable,
          OutboxRow,
          $$ReconciliationOutboxTableFilterComposer,
          $$ReconciliationOutboxTableOrderingComposer,
          $$ReconciliationOutboxTableAnnotationComposer,
          $$ReconciliationOutboxTableCreateCompanionBuilder,
          $$ReconciliationOutboxTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<
              _$AppDatabase,
              $ReconciliationOutboxTable,
              OutboxRow
            >,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$ReconciliationOutboxTableTableManager(
    _$AppDatabase db,
    $ReconciliationOutboxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReconciliationOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReconciliationOutboxTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReconciliationOutboxTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operationKey = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int> sourceRevision = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReconciliationOutboxCompanion(
                id: id,
                operationKey: operationKey,
                reason: reason,
                sourceRevision: sourceRevision,
                status: status,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operationKey,
                required String reason,
                required int sourceRevision,
                required String status,
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                required DateTime createdAt,
              }) => ReconciliationOutboxCompanion.insert(
                id: id,
                operationKey: operationKey,
                reason: reason,
                sourceRevision: sourceRevision,
                status: status,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReconciliationOutboxTable, OutboxRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReconciliationOutboxTable,
                    OutboxRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReconciliationOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReconciliationOutboxTable,
      OutboxRow,
      $$ReconciliationOutboxTableFilterComposer,
      $$ReconciliationOutboxTableOrderingComposer,
      $$ReconciliationOutboxTableAnnotationComposer,
      $$ReconciliationOutboxTableCreateCompanionBuilder,
      $$ReconciliationOutboxTableUpdateCompanionBuilder,
      (
        OutboxRow,
        BaseReferences<_$AppDatabase, $ReconciliationOutboxTable, OutboxRow>,
      ),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$WidgetConfigurationsTableCreateCompanionBuilder =
    WidgetConfigurationsCompanion Function({
      required String widgetId,
      Value<String?> categoryFilter,
      Value<String> layout,
      Value<String> surface,
      Value<String> textTone,
      Value<bool> nextEmphasis,
      Value<bool> showLocation,
      Value<bool> showProfessor,
      Value<bool> showSubtitle,
      Value<bool> matchApp,
      Value<bool> useAppTheme,
      Value<int> revision,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WidgetConfigurationsTableUpdateCompanionBuilder =
    WidgetConfigurationsCompanion Function({
      Value<String> widgetId,
      Value<String?> categoryFilter,
      Value<String> layout,
      Value<String> surface,
      Value<String> textTone,
      Value<bool> nextEmphasis,
      Value<bool> showLocation,
      Value<bool> showProfessor,
      Value<bool> showSubtitle,
      Value<bool> matchApp,
      Value<bool> useAppTheme,
      Value<int> revision,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$WidgetConfigurationsTableFilterComposer
    extends Composer<_$AppDatabase, $WidgetConfigurationsTable> {
  $$WidgetConfigurationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get widgetId => $composableBuilder(
    column: $table.widgetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryFilter => $composableBuilder(
    column: $table.categoryFilter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surface => $composableBuilder(
    column: $table.surface,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textTone => $composableBuilder(
    column: $table.textTone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get nextEmphasis => $composableBuilder(
    column: $table.nextEmphasis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showLocation => $composableBuilder(
    column: $table.showLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showProfessor => $composableBuilder(
    column: $table.showProfessor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showSubtitle => $composableBuilder(
    column: $table.showSubtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get matchApp => $composableBuilder(
    column: $table.matchApp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useAppTheme => $composableBuilder(
    column: $table.useAppTheme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WidgetConfigurationsTableOrderingComposer
    extends Composer<_$AppDatabase, $WidgetConfigurationsTable> {
  $$WidgetConfigurationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get widgetId => $composableBuilder(
    column: $table.widgetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryFilter => $composableBuilder(
    column: $table.categoryFilter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surface => $composableBuilder(
    column: $table.surface,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textTone => $composableBuilder(
    column: $table.textTone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get nextEmphasis => $composableBuilder(
    column: $table.nextEmphasis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showLocation => $composableBuilder(
    column: $table.showLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showProfessor => $composableBuilder(
    column: $table.showProfessor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showSubtitle => $composableBuilder(
    column: $table.showSubtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get matchApp => $composableBuilder(
    column: $table.matchApp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useAppTheme => $composableBuilder(
    column: $table.useAppTheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WidgetConfigurationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WidgetConfigurationsTable> {
  $$WidgetConfigurationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get widgetId =>
      $composableBuilder(column: $table.widgetId, builder: (column) => column);

  GeneratedColumn<String> get categoryFilter => $composableBuilder(
    column: $table.categoryFilter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get layout =>
      $composableBuilder(column: $table.layout, builder: (column) => column);

  GeneratedColumn<String> get surface =>
      $composableBuilder(column: $table.surface, builder: (column) => column);

  GeneratedColumn<String> get textTone =>
      $composableBuilder(column: $table.textTone, builder: (column) => column);

  GeneratedColumn<bool> get nextEmphasis => $composableBuilder(
    column: $table.nextEmphasis,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showLocation => $composableBuilder(
    column: $table.showLocation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showProfessor => $composableBuilder(
    column: $table.showProfessor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showSubtitle => $composableBuilder(
    column: $table.showSubtitle,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get matchApp =>
      $composableBuilder(column: $table.matchApp, builder: (column) => column);

  GeneratedColumn<bool> get useAppTheme => $composableBuilder(
    column: $table.useAppTheme,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WidgetConfigurationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WidgetConfigurationsTable,
          WidgetConfigRow,
          $$WidgetConfigurationsTableFilterComposer,
          $$WidgetConfigurationsTableOrderingComposer,
          $$WidgetConfigurationsTableAnnotationComposer,
          $$WidgetConfigurationsTableCreateCompanionBuilder,
          $$WidgetConfigurationsTableUpdateCompanionBuilder,
          (
            WidgetConfigRow,
            BaseReferences<
              _$AppDatabase,
              $WidgetConfigurationsTable,
              WidgetConfigRow
            >,
          ),
          WidgetConfigRow,
          PrefetchHooks Function()
        > {
  $$WidgetConfigurationsTableTableManager(
    _$AppDatabase db,
    $WidgetConfigurationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WidgetConfigurationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WidgetConfigurationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WidgetConfigurationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> widgetId = const Value.absent(),
                Value<String?> categoryFilter = const Value.absent(),
                Value<String> layout = const Value.absent(),
                Value<String> surface = const Value.absent(),
                Value<String> textTone = const Value.absent(),
                Value<bool> nextEmphasis = const Value.absent(),
                Value<bool> showLocation = const Value.absent(),
                Value<bool> showProfessor = const Value.absent(),
                Value<bool> showSubtitle = const Value.absent(),
                Value<bool> matchApp = const Value.absent(),
                Value<bool> useAppTheme = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WidgetConfigurationsCompanion(
                widgetId: widgetId,
                categoryFilter: categoryFilter,
                layout: layout,
                surface: surface,
                textTone: textTone,
                nextEmphasis: nextEmphasis,
                showLocation: showLocation,
                showProfessor: showProfessor,
                showSubtitle: showSubtitle,
                matchApp: matchApp,
                useAppTheme: useAppTheme,
                revision: revision,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String widgetId,
                Value<String?> categoryFilter = const Value.absent(),
                Value<String> layout = const Value.absent(),
                Value<String> surface = const Value.absent(),
                Value<String> textTone = const Value.absent(),
                Value<bool> nextEmphasis = const Value.absent(),
                Value<bool> showLocation = const Value.absent(),
                Value<bool> showProfessor = const Value.absent(),
                Value<bool> showSubtitle = const Value.absent(),
                Value<bool> matchApp = const Value.absent(),
                Value<bool> useAppTheme = const Value.absent(),
                Value<int> revision = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WidgetConfigurationsCompanion.insert(
                widgetId: widgetId,
                categoryFilter: categoryFilter,
                layout: layout,
                surface: surface,
                textTone: textTone,
                nextEmphasis: nextEmphasis,
                showLocation: showLocation,
                showProfessor: showProfessor,
                showSubtitle: showSubtitle,
                matchApp: matchApp,
                useAppTheme: useAppTheme,
                revision: revision,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WidgetConfigurationsTable, WidgetConfigRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $WidgetConfigurationsTable,
                    WidgetConfigRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WidgetConfigurationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WidgetConfigurationsTable,
      WidgetConfigRow,
      $$WidgetConfigurationsTableFilterComposer,
      $$WidgetConfigurationsTableOrderingComposer,
      $$WidgetConfigurationsTableAnnotationComposer,
      $$WidgetConfigurationsTableCreateCompanionBuilder,
      $$WidgetConfigurationsTableUpdateCompanionBuilder,
      (
        WidgetConfigRow,
        BaseReferences<
          _$AppDatabase,
          $WidgetConfigurationsTable,
          WidgetConfigRow
        >,
      ),
      WidgetConfigRow,
      PrefetchHooks Function()
    >;
typedef $$AppearancePreferencesTableCreateCompanionBuilder =
    AppearancePreferencesCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<String> accentKey,
      Value<String> themeKey,
      Value<int> customHue,
      Value<String> themeCustomizationsJson,
      Value<String> density,
      Value<bool> showCategoryColors,
      required DateTime updatedAt,
    });
typedef $$AppearancePreferencesTableUpdateCompanionBuilder =
    AppearancePreferencesCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<String> accentKey,
      Value<String> themeKey,
      Value<int> customHue,
      Value<String> themeCustomizationsJson,
      Value<String> density,
      Value<bool> showCategoryColors,
      Value<DateTime> updatedAt,
    });

class $$AppearancePreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $AppearancePreferencesTable> {
  $$AppearancePreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accentKey => $composableBuilder(
    column: $table.accentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeKey => $composableBuilder(
    column: $table.themeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get customHue => $composableBuilder(
    column: $table.customHue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeCustomizationsJson => $composableBuilder(
    column: $table.themeCustomizationsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get density => $composableBuilder(
    column: $table.density,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showCategoryColors => $composableBuilder(
    column: $table.showCategoryColors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppearancePreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppearancePreferencesTable> {
  $$AppearancePreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accentKey => $composableBuilder(
    column: $table.accentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeKey => $composableBuilder(
    column: $table.themeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customHue => $composableBuilder(
    column: $table.customHue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeCustomizationsJson => $composableBuilder(
    column: $table.themeCustomizationsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get density => $composableBuilder(
    column: $table.density,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showCategoryColors => $composableBuilder(
    column: $table.showCategoryColors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppearancePreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppearancePreferencesTable> {
  $$AppearancePreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get accentKey =>
      $composableBuilder(column: $table.accentKey, builder: (column) => column);

  GeneratedColumn<String> get themeKey =>
      $composableBuilder(column: $table.themeKey, builder: (column) => column);

  GeneratedColumn<int> get customHue =>
      $composableBuilder(column: $table.customHue, builder: (column) => column);

  GeneratedColumn<String> get themeCustomizationsJson => $composableBuilder(
    column: $table.themeCustomizationsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get density =>
      $composableBuilder(column: $table.density, builder: (column) => column);

  GeneratedColumn<bool> get showCategoryColors => $composableBuilder(
    column: $table.showCategoryColors,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppearancePreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppearancePreferencesTable,
          PreferencesRow,
          $$AppearancePreferencesTableFilterComposer,
          $$AppearancePreferencesTableOrderingComposer,
          $$AppearancePreferencesTableAnnotationComposer,
          $$AppearancePreferencesTableCreateCompanionBuilder,
          $$AppearancePreferencesTableUpdateCompanionBuilder,
          (
            PreferencesRow,
            BaseReferences<
              _$AppDatabase,
              $AppearancePreferencesTable,
              PreferencesRow
            >,
          ),
          PreferencesRow,
          PrefetchHooks Function()
        > {
  $$AppearancePreferencesTableTableManager(
    _$AppDatabase db,
    $AppearancePreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppearancePreferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AppearancePreferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AppearancePreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> accentKey = const Value.absent(),
                Value<String> themeKey = const Value.absent(),
                Value<int> customHue = const Value.absent(),
                Value<String> themeCustomizationsJson = const Value.absent(),
                Value<String> density = const Value.absent(),
                Value<bool> showCategoryColors = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppearancePreferencesCompanion(
                id: id,
                themeMode: themeMode,
                accentKey: accentKey,
                themeKey: themeKey,
                customHue: customHue,
                themeCustomizationsJson: themeCustomizationsJson,
                density: density,
                showCategoryColors: showCategoryColors,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> accentKey = const Value.absent(),
                Value<String> themeKey = const Value.absent(),
                Value<int> customHue = const Value.absent(),
                Value<String> themeCustomizationsJson = const Value.absent(),
                Value<String> density = const Value.absent(),
                Value<bool> showCategoryColors = const Value.absent(),
                required DateTime updatedAt,
              }) => AppearancePreferencesCompanion.insert(
                id: id,
                themeMode: themeMode,
                accentKey: accentKey,
                themeKey: themeKey,
                customHue: customHue,
                themeCustomizationsJson: themeCustomizationsJson,
                density: density,
                showCategoryColors: showCategoryColors,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppearancePreferencesTable, PreferencesRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $AppearancePreferencesTable,
                    PreferencesRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppearancePreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppearancePreferencesTable,
      PreferencesRow,
      $$AppearancePreferencesTableFilterComposer,
      $$AppearancePreferencesTableOrderingComposer,
      $$AppearancePreferencesTableAnnotationComposer,
      $$AppearancePreferencesTableCreateCompanionBuilder,
      $$AppearancePreferencesTableUpdateCompanionBuilder,
      (
        PreferencesRow,
        BaseReferences<
          _$AppDatabase,
          $AppearancePreferencesTable,
          PreferencesRow
        >,
      ),
      PreferencesRow,
      PrefetchHooks Function()
    >;
typedef $$ImportDraftsTableCreateCompanionBuilder =
    ImportDraftsCompanion Function({
      required String id,
      required String sourceType,
      Value<String?> sourceRef,
      required int sourceRevision,
      required int draftRevision,
      required String payloadJson,
      required String reviewState,
      required DateTime createdAt,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$ImportDraftsTableUpdateCompanionBuilder =
    ImportDraftsCompanion Function({
      Value<String> id,
      Value<String> sourceType,
      Value<String?> sourceRef,
      Value<int> sourceRevision,
      Value<int> draftRevision,
      Value<String> payloadJson,
      Value<String> reviewState,
      Value<DateTime> createdAt,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$ImportDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportDraftsTable> {
  $$ImportDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get draftRevision => $composableBuilder(
    column: $table.draftRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportDraftsTable> {
  $$ImportDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get draftRevision => $composableBuilder(
    column: $table.draftRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportDraftsTable> {
  $$ImportDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRef =>
      $composableBuilder(column: $table.sourceRef, builder: (column) => column);

  GeneratedColumn<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get draftRevision => $composableBuilder(
    column: $table.draftRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$ImportDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportDraftsTable,
          ImportDraftRow,
          $$ImportDraftsTableFilterComposer,
          $$ImportDraftsTableOrderingComposer,
          $$ImportDraftsTableAnnotationComposer,
          $$ImportDraftsTableCreateCompanionBuilder,
          $$ImportDraftsTableUpdateCompanionBuilder,
          (
            ImportDraftRow,
            BaseReferences<_$AppDatabase, $ImportDraftsTable, ImportDraftRow>,
          ),
          ImportDraftRow,
          PrefetchHooks Function()
        > {
  $$ImportDraftsTableTableManager(_$AppDatabase db, $ImportDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourceRef = const Value.absent(),
                Value<int> sourceRevision = const Value.absent(),
                Value<int> draftRevision = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> reviewState = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportDraftsCompanion(
                id: id,
                sourceType: sourceType,
                sourceRef: sourceRef,
                sourceRevision: sourceRevision,
                draftRevision: draftRevision,
                payloadJson: payloadJson,
                reviewState: reviewState,
                createdAt: createdAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceType,
                Value<String?> sourceRef = const Value.absent(),
                required int sourceRevision,
                required int draftRevision,
                required String payloadJson,
                required String reviewState,
                required DateTime createdAt,
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportDraftsCompanion.insert(
                id: id,
                sourceType: sourceType,
                sourceRef: sourceRef,
                sourceRevision: sourceRevision,
                draftRevision: draftRevision,
                payloadJson: payloadJson,
                reviewState: reviewState,
                createdAt: createdAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportDraftsTable, ImportDraftRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ImportDraftsTable,
                    ImportDraftRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportDraftsTable,
      ImportDraftRow,
      $$ImportDraftsTableFilterComposer,
      $$ImportDraftsTableOrderingComposer,
      $$ImportDraftsTableAnnotationComposer,
      $$ImportDraftsTableCreateCompanionBuilder,
      $$ImportDraftsTableUpdateCompanionBuilder,
      (
        ImportDraftRow,
        BaseReferences<_$AppDatabase, $ImportDraftsTable, ImportDraftRow>,
      ),
      ImportDraftRow,
      PrefetchHooks Function()
    >;
typedef $$ImportProvenanceTableCreateCompanionBuilder =
    ImportProvenanceCompanion Function({
      required String id,
      required String seriesId,
      required String sourceType,
      Value<String?> shareId,
      Value<String?> sourceItemId,
      Value<int?> sourceRevision,
      Value<String?> imageDraftId,
      required String fingerprint,
      required DateTime importedAt,
      Value<int> rowid,
    });
typedef $$ImportProvenanceTableUpdateCompanionBuilder =
    ImportProvenanceCompanion Function({
      Value<String> id,
      Value<String> seriesId,
      Value<String> sourceType,
      Value<String?> shareId,
      Value<String?> sourceItemId,
      Value<int?> sourceRevision,
      Value<String?> imageDraftId,
      Value<String> fingerprint,
      Value<DateTime> importedAt,
      Value<int> rowid,
    });

final class $$ImportProvenanceTableReferences
    extends
        BaseReferences<_$AppDatabase, $ImportProvenanceTable, ProvenanceRow> {
  $$ImportProvenanceTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScheduleSeriesTableTable _seriesIdTable(_$AppDatabase db) => db
      .scheduleSeriesTable
      .createAlias('import_provenance__series_id__schedule_series__id');

  $$ScheduleSeriesTableTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<String>('series_id')!;

    final manager = $$ScheduleSeriesTableTableTableManager(
      $_db,
      $_db.scheduleSeriesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImportProvenanceTableFilterComposer
    extends Composer<_$AppDatabase, $ImportProvenanceTable> {
  $$ImportProvenanceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shareId => $composableBuilder(
    column: $table.shareId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceItemId => $composableBuilder(
    column: $table.sourceItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageDraftId => $composableBuilder(
    column: $table.imageDraftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScheduleSeriesTableTableFilterComposer get seriesId {
    final $$ScheduleSeriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.scheduleSeriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleSeriesTableTableFilterComposer(
            $db: $db,
            $table: $db.scheduleSeriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportProvenanceTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportProvenanceTable> {
  $$ImportProvenanceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shareId => $composableBuilder(
    column: $table.shareId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceItemId => $composableBuilder(
    column: $table.sourceItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageDraftId => $composableBuilder(
    column: $table.imageDraftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScheduleSeriesTableTableOrderingComposer get seriesId {
    final $$ScheduleSeriesTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.seriesId,
          referencedTable: $db.scheduleSeriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleSeriesTableTableOrderingComposer(
                $db: $db,
                $table: $db.scheduleSeriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ImportProvenanceTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportProvenanceTable> {
  $$ImportProvenanceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shareId =>
      $composableBuilder(column: $table.shareId, builder: (column) => column);

  GeneratedColumn<String> get sourceItemId => $composableBuilder(
    column: $table.sourceItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceRevision => $composableBuilder(
    column: $table.sourceRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageDraftId => $composableBuilder(
    column: $table.imageDraftId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  $$ScheduleSeriesTableTableAnnotationComposer get seriesId {
    final $$ScheduleSeriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.seriesId,
          referencedTable: $db.scheduleSeriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleSeriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduleSeriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ImportProvenanceTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportProvenanceTable,
          ProvenanceRow,
          $$ImportProvenanceTableFilterComposer,
          $$ImportProvenanceTableOrderingComposer,
          $$ImportProvenanceTableAnnotationComposer,
          $$ImportProvenanceTableCreateCompanionBuilder,
          $$ImportProvenanceTableUpdateCompanionBuilder,
          (ProvenanceRow, $$ImportProvenanceTableReferences),
          ProvenanceRow,
          PrefetchHooks Function({bool seriesId})
        > {
  $$ImportProvenanceTableTableManager(
    _$AppDatabase db,
    $ImportProvenanceTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportProvenanceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportProvenanceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportProvenanceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> shareId = const Value.absent(),
                Value<String?> sourceItemId = const Value.absent(),
                Value<int?> sourceRevision = const Value.absent(),
                Value<String?> imageDraftId = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportProvenanceCompanion(
                id: id,
                seriesId: seriesId,
                sourceType: sourceType,
                shareId: shareId,
                sourceItemId: sourceItemId,
                sourceRevision: sourceRevision,
                imageDraftId: imageDraftId,
                fingerprint: fingerprint,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String seriesId,
                required String sourceType,
                Value<String?> shareId = const Value.absent(),
                Value<String?> sourceItemId = const Value.absent(),
                Value<int?> sourceRevision = const Value.absent(),
                Value<String?> imageDraftId = const Value.absent(),
                required String fingerprint,
                required DateTime importedAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportProvenanceCompanion.insert(
                id: id,
                seriesId: seriesId,
                sourceType: sourceType,
                shareId: shareId,
                sourceItemId: sourceItemId,
                sourceRevision: sourceRevision,
                imageDraftId: imageDraftId,
                fingerprint: fingerprint,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportProvenanceTable, ProvenanceRow>(table),
                  $$ImportProvenanceTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({seriesId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (seriesId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.seriesId,
                        referencedTable: $$ImportProvenanceTableReferences
                            ._seriesIdTable(db),
                        referencedColumn: $$ImportProvenanceTableReferences
                            ._seriesIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImportProvenanceTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportProvenanceTable,
      ProvenanceRow,
      $$ImportProvenanceTableFilterComposer,
      $$ImportProvenanceTableOrderingComposer,
      $$ImportProvenanceTableAnnotationComposer,
      $$ImportProvenanceTableCreateCompanionBuilder,
      $$ImportProvenanceTableUpdateCompanionBuilder,
      (ProvenanceRow, $$ImportProvenanceTableReferences),
      ProvenanceRow,
      PrefetchHooks Function({bool seriesId})
    >;
typedef $$ImportCommitsTableCreateCompanionBuilder =
    ImportCommitsCompanion Function({
      required String commandId,
      required String payloadHash,
      required String seriesIdsJson,
      required DateTime committedAt,
      Value<int> rowid,
    });
typedef $$ImportCommitsTableUpdateCompanionBuilder =
    ImportCommitsCompanion Function({
      Value<String> commandId,
      Value<String> payloadHash,
      Value<String> seriesIdsJson,
      Value<DateTime> committedAt,
      Value<int> rowid,
    });

class $$ImportCommitsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportCommitsTable> {
  $$ImportCommitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get commandId => $composableBuilder(
    column: $table.commandId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesIdsJson => $composableBuilder(
    column: $table.seriesIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportCommitsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportCommitsTable> {
  $$ImportCommitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get commandId => $composableBuilder(
    column: $table.commandId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesIdsJson => $composableBuilder(
    column: $table.seriesIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportCommitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportCommitsTable> {
  $$ImportCommitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get commandId =>
      $composableBuilder(column: $table.commandId, builder: (column) => column);

  GeneratedColumn<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seriesIdsJson => $composableBuilder(
    column: $table.seriesIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => column,
  );
}

class $$ImportCommitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportCommitsTable,
          ImportCommitRow,
          $$ImportCommitsTableFilterComposer,
          $$ImportCommitsTableOrderingComposer,
          $$ImportCommitsTableAnnotationComposer,
          $$ImportCommitsTableCreateCompanionBuilder,
          $$ImportCommitsTableUpdateCompanionBuilder,
          (
            ImportCommitRow,
            BaseReferences<_$AppDatabase, $ImportCommitsTable, ImportCommitRow>,
          ),
          ImportCommitRow,
          PrefetchHooks Function()
        > {
  $$ImportCommitsTableTableManager(_$AppDatabase db, $ImportCommitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportCommitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportCommitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportCommitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> commandId = const Value.absent(),
                Value<String> payloadHash = const Value.absent(),
                Value<String> seriesIdsJson = const Value.absent(),
                Value<DateTime> committedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportCommitsCompanion(
                commandId: commandId,
                payloadHash: payloadHash,
                seriesIdsJson: seriesIdsJson,
                committedAt: committedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String commandId,
                required String payloadHash,
                required String seriesIdsJson,
                required DateTime committedAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportCommitsCompanion.insert(
                commandId: commandId,
                payloadHash: payloadHash,
                seriesIdsJson: seriesIdsJson,
                committedAt: committedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportCommitsTable, ImportCommitRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ImportCommitsTable,
                    ImportCommitRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportCommitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportCommitsTable,
      ImportCommitRow,
      $$ImportCommitsTableFilterComposer,
      $$ImportCommitsTableOrderingComposer,
      $$ImportCommitsTableAnnotationComposer,
      $$ImportCommitsTableCreateCompanionBuilder,
      $$ImportCommitsTableUpdateCompanionBuilder,
      (
        ImportCommitRow,
        BaseReferences<_$AppDatabase, $ImportCommitsTable, ImportCommitRow>,
      ),
      ImportCommitRow,
      PrefetchHooks Function()
    >;
typedef $$OwnedShareLinksTableCreateCompanionBuilder =
    OwnedShareLinksCompanion Function({
      required String shareId,
      required int snapshotVersion,
      required int itemCount,
      required String categoryLabelsJson,
      required String routePath,
      required DateTime createdAt,
      required DateTime expiresAt,
      Value<DateTime?> revokedAt,
      Value<int> rowid,
    });
typedef $$OwnedShareLinksTableUpdateCompanionBuilder =
    OwnedShareLinksCompanion Function({
      Value<String> shareId,
      Value<int> snapshotVersion,
      Value<int> itemCount,
      Value<String> categoryLabelsJson,
      Value<String> routePath,
      Value<DateTime> createdAt,
      Value<DateTime> expiresAt,
      Value<DateTime?> revokedAt,
      Value<int> rowid,
    });

class $$OwnedShareLinksTableFilterComposer
    extends Composer<_$AppDatabase, $OwnedShareLinksTable> {
  $$OwnedShareLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get shareId => $composableBuilder(
    column: $table.shareId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snapshotVersion => $composableBuilder(
    column: $table.snapshotVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryLabelsJson => $composableBuilder(
    column: $table.categoryLabelsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routePath => $composableBuilder(
    column: $table.routePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OwnedShareLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $OwnedShareLinksTable> {
  $$OwnedShareLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get shareId => $composableBuilder(
    column: $table.shareId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snapshotVersion => $composableBuilder(
    column: $table.snapshotVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryLabelsJson => $composableBuilder(
    column: $table.categoryLabelsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routePath => $composableBuilder(
    column: $table.routePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OwnedShareLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $OwnedShareLinksTable> {
  $$OwnedShareLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get shareId =>
      $composableBuilder(column: $table.shareId, builder: (column) => column);

  GeneratedColumn<int> get snapshotVersion => $composableBuilder(
    column: $table.snapshotVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<String> get categoryLabelsJson => $composableBuilder(
    column: $table.categoryLabelsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get routePath =>
      $composableBuilder(column: $table.routePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);
}

class $$OwnedShareLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OwnedShareLinksTable,
          OwnedShareLinkRow,
          $$OwnedShareLinksTableFilterComposer,
          $$OwnedShareLinksTableOrderingComposer,
          $$OwnedShareLinksTableAnnotationComposer,
          $$OwnedShareLinksTableCreateCompanionBuilder,
          $$OwnedShareLinksTableUpdateCompanionBuilder,
          (
            OwnedShareLinkRow,
            BaseReferences<
              _$AppDatabase,
              $OwnedShareLinksTable,
              OwnedShareLinkRow
            >,
          ),
          OwnedShareLinkRow,
          PrefetchHooks Function()
        > {
  $$OwnedShareLinksTableTableManager(
    _$AppDatabase db,
    $OwnedShareLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OwnedShareLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OwnedShareLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OwnedShareLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> shareId = const Value.absent(),
                Value<int> snapshotVersion = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<String> categoryLabelsJson = const Value.absent(),
                Value<String> routePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OwnedShareLinksCompanion(
                shareId: shareId,
                snapshotVersion: snapshotVersion,
                itemCount: itemCount,
                categoryLabelsJson: categoryLabelsJson,
                routePath: routePath,
                createdAt: createdAt,
                expiresAt: expiresAt,
                revokedAt: revokedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String shareId,
                required int snapshotVersion,
                required int itemCount,
                required String categoryLabelsJson,
                required String routePath,
                required DateTime createdAt,
                required DateTime expiresAt,
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OwnedShareLinksCompanion.insert(
                shareId: shareId,
                snapshotVersion: snapshotVersion,
                itemCount: itemCount,
                categoryLabelsJson: categoryLabelsJson,
                routePath: routePath,
                createdAt: createdAt,
                expiresAt: expiresAt,
                revokedAt: revokedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OwnedShareLinksTable, OwnedShareLinkRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OwnedShareLinksTable,
                    OwnedShareLinkRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OwnedShareLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OwnedShareLinksTable,
      OwnedShareLinkRow,
      $$OwnedShareLinksTableFilterComposer,
      $$OwnedShareLinksTableOrderingComposer,
      $$OwnedShareLinksTableAnnotationComposer,
      $$OwnedShareLinksTableCreateCompanionBuilder,
      $$OwnedShareLinksTableUpdateCompanionBuilder,
      (
        OwnedShareLinkRow,
        BaseReferences<_$AppDatabase, $OwnedShareLinksTable, OwnedShareLinkRow>,
      ),
      OwnedShareLinkRow,
      PrefetchHooks Function()
    >;
typedef $$PendingShareCreationsTableCreateCompanionBuilder =
    PendingShareCreationsCompanion Function({
      required String idempotencyKey,
      required String payloadJson,
      required DateTime expiresAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PendingShareCreationsTableUpdateCompanionBuilder =
    PendingShareCreationsCompanion Function({
      Value<String> idempotencyKey,
      Value<String> payloadJson,
      Value<DateTime> expiresAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PendingShareCreationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingShareCreationsTable> {
  $$PendingShareCreationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingShareCreationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingShareCreationsTable> {
  $$PendingShareCreationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingShareCreationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingShareCreationsTable> {
  $$PendingShareCreationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingShareCreationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingShareCreationsTable,
          PendingShareRow,
          $$PendingShareCreationsTableFilterComposer,
          $$PendingShareCreationsTableOrderingComposer,
          $$PendingShareCreationsTableAnnotationComposer,
          $$PendingShareCreationsTableCreateCompanionBuilder,
          $$PendingShareCreationsTableUpdateCompanionBuilder,
          (
            PendingShareRow,
            BaseReferences<
              _$AppDatabase,
              $PendingShareCreationsTable,
              PendingShareRow
            >,
          ),
          PendingShareRow,
          PrefetchHooks Function()
        > {
  $$PendingShareCreationsTableTableManager(
    _$AppDatabase db,
    $PendingShareCreationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingShareCreationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingShareCreationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingShareCreationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingShareCreationsCompanion(
                idempotencyKey: idempotencyKey,
                payloadJson: payloadJson,
                expiresAt: expiresAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idempotencyKey,
                required String payloadJson,
                required DateTime expiresAt,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingShareCreationsCompanion.insert(
                idempotencyKey: idempotencyKey,
                payloadJson: payloadJson,
                expiresAt: expiresAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingShareCreationsTable, PendingShareRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingShareCreationsTable,
                    PendingShareRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingShareCreationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingShareCreationsTable,
      PendingShareRow,
      $$PendingShareCreationsTableFilterComposer,
      $$PendingShareCreationsTableOrderingComposer,
      $$PendingShareCreationsTableAnnotationComposer,
      $$PendingShareCreationsTableCreateCompanionBuilder,
      $$PendingShareCreationsTableUpdateCompanionBuilder,
      (
        PendingShareRow,
        BaseReferences<
          _$AppDatabase,
          $PendingShareCreationsTable,
          PendingShareRow
        >,
      ),
      PendingShareRow,
      PrefetchHooks Function()
    >;
typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValueRow,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (
            KeyValueRow,
            BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>,
          ),
          KeyValueRow,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValueRow>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValueRow,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (
        KeyValueRow,
        BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>,
      ),
      KeyValueRow,
      PrefetchHooks Function()
    >;
typedef $$ProfilePreferencesTableCreateCompanionBuilder =
    ProfilePreferencesCompanion Function({
      Value<int> id,
      Value<String?> displayName,
      Value<String?> photoPath,
      required DateTime updatedAt,
    });
typedef $$ProfilePreferencesTableUpdateCompanionBuilder =
    ProfilePreferencesCompanion Function({
      Value<int> id,
      Value<String?> displayName,
      Value<String?> photoPath,
      Value<DateTime> updatedAt,
    });

class $$ProfilePreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilePreferencesTable> {
  $$ProfilePreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilePreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilePreferencesTable> {
  $$ProfilePreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilePreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilePreferencesTable> {
  $$ProfilePreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilePreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilePreferencesTable,
          ProfileRow,
          $$ProfilePreferencesTableFilterComposer,
          $$ProfilePreferencesTableOrderingComposer,
          $$ProfilePreferencesTableAnnotationComposer,
          $$ProfilePreferencesTableCreateCompanionBuilder,
          $$ProfilePreferencesTableUpdateCompanionBuilder,
          (
            ProfileRow,
            BaseReferences<_$AppDatabase, $ProfilePreferencesTable, ProfileRow>,
          ),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfilePreferencesTableTableManager(
    _$AppDatabase db,
    $ProfilePreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilePreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilePreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilePreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProfilePreferencesCompanion(
                id: id,
                displayName: displayName,
                photoPath: photoPath,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                required DateTime updatedAt,
              }) => ProfilePreferencesCompanion.insert(
                id: id,
                displayName: displayName,
                photoPath: photoPath,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilePreferencesTable, ProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProfilePreferencesTable,
                    ProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilePreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilePreferencesTable,
      ProfileRow,
      $$ProfilePreferencesTableFilterComposer,
      $$ProfilePreferencesTableOrderingComposer,
      $$ProfilePreferencesTableAnnotationComposer,
      $$ProfilePreferencesTableCreateCompanionBuilder,
      $$ProfilePreferencesTableUpdateCompanionBuilder,
      (
        ProfileRow,
        BaseReferences<_$AppDatabase, $ProfilePreferencesTable, ProfileRow>,
      ),
      ProfileRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ScheduleSeriesTableTableTableManager get scheduleSeriesTable =>
      $$ScheduleSeriesTableTableTableManager(_db, _db.scheduleSeriesTable);
  $$OccurrenceExceptionsTableTableManager get occurrenceExceptions =>
      $$OccurrenceExceptionsTableTableManager(_db, _db.occurrenceExceptions);
  $$AlertRulesTableTableManager get alertRules =>
      $$AlertRulesTableTableManager(_db, _db.alertRules);
  $$ScheduledAlertsTableTableManager get scheduledAlerts =>
      $$ScheduledAlertsTableTableManager(_db, _db.scheduledAlerts);
  $$ReconciliationOutboxTableTableManager get reconciliationOutbox =>
      $$ReconciliationOutboxTableTableManager(_db, _db.reconciliationOutbox);
  $$WidgetConfigurationsTableTableManager get widgetConfigurations =>
      $$WidgetConfigurationsTableTableManager(_db, _db.widgetConfigurations);
  $$AppearancePreferencesTableTableManager get appearancePreferences =>
      $$AppearancePreferencesTableTableManager(_db, _db.appearancePreferences);
  $$ImportDraftsTableTableManager get importDrafts =>
      $$ImportDraftsTableTableManager(_db, _db.importDrafts);
  $$ImportProvenanceTableTableManager get importProvenance =>
      $$ImportProvenanceTableTableManager(_db, _db.importProvenance);
  $$ImportCommitsTableTableManager get importCommits =>
      $$ImportCommitsTableTableManager(_db, _db.importCommits);
  $$OwnedShareLinksTableTableManager get ownedShareLinks =>
      $$OwnedShareLinksTableTableManager(_db, _db.ownedShareLinks);
  $$PendingShareCreationsTableTableManager get pendingShareCreations =>
      $$PendingShareCreationsTableTableManager(_db, _db.pendingShareCreations);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$ProfilePreferencesTableTableManager get profilePreferences =>
      $$ProfilePreferencesTableTableManager(_db, _db.profilePreferences);
}
