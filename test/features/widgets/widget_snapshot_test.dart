import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/schedule/models.dart';
import 'package:schediel/core/schedule/occurrence_engine.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';
import 'package:schediel/features/categories/domain/category.dart';
import 'package:schediel/features/widgets/application/widget_snapshot_builder.dart';
import 'package:schediel/features/widgets/application/widget_snapshot_reader.dart';
import 'package:schediel/features/widgets/domain/widget_config.dart';

void main() {
  late ZoneResolver zones;
  late WidgetSnapshotBuilder builder;

  setUpAll(() {
    zones = ZoneResolver.initialized();
    builder = WidgetSnapshotBuilder(zones, OccurrenceEngine(zones));
  });

  group('reader matches the shared fixtures', () {
    final doc = jsonDecode(File('contracts/fixtures/widget-snapshot-cases.json').readAsStringSync()) as Map<String, dynamic>;
    final snapshot = jsonEncode(doc['snapshot']);
    for (final check in (doc['checks'] as List).cast<Map<String, dynamic>>()) {
      test(check['name'] as String, () {
        final result = readWidgetSnapshot(
          snapshot,
          widgetKey: check['widgetKey'] as String,
          now: DateTime.parse(check['now'] as String),
          deviceZone: doc['deviceTimeZone'] as String,
          zones: zones,
        );
        final expected = check['expect'] as Map<String, dynamic>;
        expect(result.state.name, expected['state']);
        if (expected['state'] == 'entries') {
          expect(result.ongoing, expected['ongoing']);
          expect(result.next, expected['next']);
          expect(result.upcoming, expected['upcoming']);
          expect(result.allDay, expected['allDay']);
          expect(result.needsReview, expected['needsReview']);
        } else {
          expect(result.message, expected['emptyMessage'] ?? expected['message']);
        }
      });
    }

    test('unsupported snapshots open the app', () {
      final result = readWidgetSnapshot(jsonEncode(doc['unsupportedSnapshot']),
          widgetKey: 'default', now: DateTime.utc(2026, 11, 2), deviceZone: 'Asia/Manila', zones: zones);
      expect(result.state.name, (doc['unsupportedExpect'] as Map)['state']);
      expect(result.message, (doc['unsupportedExpect'] as Map)['message']);
      expect(readWidgetSnapshot(null, widgetKey: 'default', now: DateTime.utc(2026), deviceZone: 'UTC', zones: zones).message,
          'Open Schediel');
      expect(readWidgetSnapshot('{not json', widgetKey: 'default', now: DateTime.utc(2026), deviceZone: 'UTC', zones: zones).message,
          'Open Schediel');
    });
  });

  group('builder', () {
    ScheduleSeries series(String id, {String? category, int hour = 9, String zone = 'Asia/Manila', String? room}) => ScheduleSeries(
          id: id,
          revision: 1,
          title: 'Fixture $id',
          categoryId: category,
          time: TimedSpec(
            startDate: LocalDate(2026, 11, 2),
            startTime: LocalTime(hour, 0),
            timeZone: zone,
            endTime: LocalTime(hour + 1, 0),
            endDayOffset: 0,
          ),
          recurrence: RecurrenceSpec(frequency: RecurrenceFrequency.daily),
          details: ScheduleDetails(location: room, professor: 'Fixture person'),
        );

    test('produces a contract-shaped snapshot that its own reader understands', () {
      final json = builder.build(
        series: [series('a', room: 'Fixture room'), series('b', hour: 13)],
        configs: [WidgetConfig.defaults],
        now: DateTime.utc(2026, 11, 2, 0, 30),
        zone: 'Asia/Manila',
        dataRevision: 4,
        use24h: true,
      );
      expect(json.keys.toSet(), {'schemaVersion', 'dataRevision', 'generatedAt', 'deviceTimeZone', 'coverageEnd', 'widgets'});
      expect(json['schemaVersion'], '1.0');
      expect(json['dataRevision'], 4);
      expect(json['coverageEnd'], '2026-11-08T16:00:00.000Z');
      final projection = (json['widgets'] as Map)['default'] as Map<String, dynamic>;
      expect((projection['configuration'] as Map).keys.toSet(),
          {'configRevision', 'layout', 'surface', 'textTone', 'nextEmphasis', 'visibleDetails'});
      final occurrences = (projection['occurrences'] as List).cast<Map<String, dynamic>>();
      expect(occurrences, hasLength(14));
      expect(occurrences.first.keys, hasLength(15));
      expect(occurrences.first['deepLink'], 'schediel://occurrence/a/2026-11-02');
      expect(occurrences.first['location'], 'Fixture room');

      final read = readWidgetSnapshot(jsonEncode(json),
          widgetKey: 'default', now: DateTime.utc(2026, 11, 2, 0, 30), deviceZone: 'Asia/Manila', zones: zones);
      expect(read.next, 'a/2026-11-02');
    });

    test('caps each widget at 24 occurrences and pulls coverage in accordingly', () {
      final many = [for (var i = 0; i < 6; i++) series('s$i', hour: 8 + i)];
      final json = builder.build(
        series: many,
        configs: [WidgetConfig.defaults],
        now: DateTime.utc(2026, 11, 2, 0, 0),
        zone: 'Asia/Manila',
        dataRevision: 1,
        use24h: true,
      );
      final occurrences = ((json['widgets'] as Map)['default'] as Map)['occurrences'] as List;
      expect(occurrences, hasLength(24));
      expect(DateTime.parse(json['coverageEnd'] as String), DateTime.utc(2026, 11, 6, 0));
    });

    test('applies per-widget filters, detail visibility and empty reasons', () {
      final json = builder.build(
        series: [series('a', category: 'school', room: 'Fixture room')],
        configs: [
          WidgetConfig.defaults,
          WidgetConfig.defaults.copyWith(widgetKey: '12', filter: const CategoryFilter.only({'work'})),
          WidgetConfig.defaults.copyWith(widgetKey: '13', showLocation: false, showProfessor: false),
        ],
        now: DateTime.utc(2026, 11, 2),
        zone: 'Asia/Manila',
        dataRevision: 1,
        use24h: true,
      );
      final widgets = json['widgets'] as Map;
      expect((widgets['12'] as Map)['emptyReason'], 'noneInFilter');
      expect((widgets['12'] as Map)['occurrences'], isEmpty);
      final hidden = ((widgets['13'] as Map)['occurrences'] as List).first as Map;
      expect(hidden['location'], isNull);
      expect(hidden['professor'], isNull);

      final none = builder.build(
        series: const [],
        configs: [WidgetConfig.defaults],
        now: DateTime.utc(2026, 11, 2),
        zone: 'Asia/Manila',
        dataRevision: 0,
        use24h: true,
      );
      expect(((none['widgets'] as Map)['default'] as Map)['emptyReason'], 'noSchedules');
    });

    test('labels schedules set in another zone with their own wall time', () {
      final json = builder.build(
        series: [series('ny', zone: 'America/New_York', hour: 9)],
        configs: [WidgetConfig.defaults],
        now: DateTime.utc(2026, 11, 2),
        zone: 'Asia/Manila',
        dataRevision: 1,
        use24h: true,
      );
      final first = (((json['widgets'] as Map)['default'] as Map)['occurrences'] as List).first as Map;
      expect(first['zoneLabel'], '09:00 New York');
    });
  });
}
