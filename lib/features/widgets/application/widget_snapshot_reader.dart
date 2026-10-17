import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show immutable;

import '../../../core/time/local_date.dart';
import '../../../core/time/zone_resolver.dart';

enum WidgetReadState { entries, empty, stale, unsupported }

@immutable
class WidgetSnapshotEntry {
  const WidgetSnapshotEntry(this.json);
  final Map<String, dynamic> json;

  String get id => json['occurrenceId'] as String;
  String get title => json['title'] as String;
  int? get startEpochMs => json['startEpochMs'] as int?;
  int? get endEpochMs => json['endEpochMs'] as int?;
  String get startDate => json['startDate'] as String;
  String? get zoneLabel => json['zoneLabel'] as String?;
  String? get location => json['location'] as String?;
  String? get professor => json['professor'] as String?;
  String? get subtitle => json['subtitle'] as String?;
  String get deepLink => json['deepLink'] as String;
}

/// Result of applying the reader rules (x-readerRules R01-R10) at [now].
@immutable
class WidgetReadResult {
  const WidgetReadResult({
    required this.state,
    this.message,
    this.configuration = const {},
    this.entries = const {},
    this.ongoing = const [],
    this.next,
    this.upcoming = const [],
    this.allDay = const [],
    this.needsReview = const [],
  });

  final WidgetReadState state;
  final String? message;
  final Map<String, dynamic> configuration;
  final Map<String, WidgetSnapshotEntry> entries;
  final List<String> ongoing;
  final String? next;
  final List<String> upcoming;
  final List<String> allDay;
  final List<String> needsReview;
}

/// Dart reference reader for the widget snapshot. The Android and iOS
/// readers implement the same rules against the same fixtures; the app uses
/// this one for the in-app widget preview.
WidgetReadResult readWidgetSnapshot(
  String? raw, {
  required String widgetKey,
  required DateTime now,
  required String deviceZone,
  required ZoneResolver zones,
}) {
  const unsupported = WidgetReadResult(state: WidgetReadState.unsupported, message: 'Open Schediel');
  if (raw == null) return unsupported;
  Map<String, dynamic> snapshot;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != '1.0') return unsupported;
    snapshot = decoded;
  } on FormatException {
    return unsupported;
  }
  try {
    final nowMs = now.toUtc().millisecondsSinceEpoch;
    final coverageEnd = DateTime.parse(snapshot['coverageEnd'] as String).millisecondsSinceEpoch;
    if (nowMs >= coverageEnd) {
      return const WidgetReadResult(state: WidgetReadState.stale, message: 'Open Schediel to update');
    }
    final widgets = snapshot['widgets'] as Map<String, dynamic>;
    final projection = (widgets[widgetKey] ?? widgets['default']) as Map<String, dynamic>;
    final configuration = projection['configuration'] as Map<String, dynamic>;
    switch (projection['emptyReason']) {
      case 'noSchedules':
        return WidgetReadResult(state: WidgetReadState.empty, message: 'No schedules yet', configuration: configuration);
      case 'noneInFilter':
        return WidgetReadResult(
            state: WidgetReadState.empty, message: 'No schedules in this filter', configuration: configuration);
    }

    final today = zones.localDateOf(now, deviceZone);
    final entries = <String, WidgetSnapshotEntry>{};
    final allDay = <String>[];
    final needsReview = <String>[];
    final ongoing = <WidgetSnapshotEntry>[];
    final future = <WidgetSnapshotEntry>[];
    for (final raw in (projection['occurrences'] as List).cast<Map<String, dynamic>>()) {
      final e = WidgetSnapshotEntry(raw);
      entries[e.id] = e;
      if (raw['kind'] == 'dateOnly') {
        final start = LocalDate.parse(e.startDate);
        final end = LocalDate.parse(raw['endDateExclusive'] as String);
        if (!today.isBefore(start) && today.isBefore(end)) allDay.add(e.id);
        continue;
      }
      if (raw['timeStatus'] == 'needsTimeReview') {
        if (!LocalDate.parse(e.startDate).isBefore(today)) needsReview.add(e.id);
        continue;
      }
      final start = e.startEpochMs!;
      final end = e.endEpochMs;
      if (end == null) {
        if (nowMs < start) future.add(e);
      } else if (start <= nowMs && nowMs < end) {
        ongoing.add(e);
      } else if (nowMs < start) {
        future.add(e);
      }
    }
    mergeSort(future, compare: (a, b) => a.startEpochMs!.compareTo(b.startEpochMs!));
    final hasAny = ongoing.isNotEmpty || future.isNotEmpty || allDay.isNotEmpty || needsReview.isNotEmpty;
    if (!hasAny) {
      return WidgetReadResult(state: WidgetReadState.empty, message: 'No upcoming schedules', configuration: configuration);
    }
    return WidgetReadResult(
      state: WidgetReadState.entries,
      configuration: configuration,
      entries: entries,
      ongoing: [for (final e in ongoing) e.id],
      next: future.isEmpty ? null : future.first.id,
      upcoming: [for (final e in future.skip(1)) e.id],
      allDay: allDay,
      needsReview: needsReview,
    );
  } on Object {
    return unsupported;
  }
}
