import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/core/time/local_date.dart';
import 'package:schediel/core/time/local_time.dart';
import 'package:schediel/core/time/zone_resolver.dart';

void main() {
  late ZoneResolver zones;

  setUpAll(() {
    zones = ZoneResolver.initialized();
  });

  test('accepts IANA identifiers and rejects fixed offsets or unknown names', () {
    expect(zones.isValidZone('Asia/Manila'), isTrue);
    expect(zones.isValidZone('America/New_York'), isTrue);
    expect(zones.isValidZone('UTC'), isTrue);
    expect(zones.isValidZone('Mars/Olympus'), isFalse);
    expect(zones.isValidZone('+08:00'), isFalse);
    expect(zones.isValidZone(''), isFalse);
  });

  test('resolves an ordinary wall time to exactly one instant', () {
    final result = zones.resolve('Asia/Manila', LocalDate(2026, 11, 2), LocalTime(9, 0));
    expect(result.kind, WallTimeKind.normal);
    expect(result.candidates, [DateTime.utc(2026, 11, 2, 1)]);
    expect(result.single, DateTime.utc(2026, 11, 2, 1));
  });

  test('reports a wall time inside a spring-forward gap as nonexistent', () {
    final result = zones.resolve('America/New_York', LocalDate(2026, 3, 8), LocalTime(2, 30));
    expect(result.kind, WallTimeKind.nonexistent);
    expect(result.candidates, isEmpty);
    expect(result.single, isNull);
  });

  test('reports both instants of a fall-back fold in ascending order', () {
    final result = zones.resolve('America/New_York', LocalDate(2026, 11, 1), LocalTime(1, 30));
    expect(result.kind, WallTimeKind.ambiguous);
    expect(result.candidates, [DateTime.utc(2026, 11, 1, 5, 30), DateTime.utc(2026, 11, 1, 6, 30)]);
    expect(result.single, isNull);
  });

  test('uses the offset in force after a transition', () {
    final result = zones.resolve('America/New_York', LocalDate(2026, 11, 5), LocalTime(22, 0));
    expect(result.single, DateTime.utc(2026, 11, 6, 3));
  });

  test('converts instants back to wall time in any zone', () {
    final instant = DateTime.utc(2026, 11, 6, 3);
    final ny = zones.toLocal(instant, 'America/New_York');
    expect(ny.date, LocalDate(2026, 11, 5));
    expect(ny.time, LocalTime(22, 0));
    final manila = zones.toLocal(instant, 'Asia/Manila');
    expect(manila.date, LocalDate(2026, 11, 6));
    expect(manila.time, LocalTime(11, 0));
  });

  test('provides zone abbreviations for labels', () {
    expect(zones.abbreviation(DateTime.utc(2026, 11, 6, 3), 'America/New_York'), 'EST');
    expect(zones.abbreviation(DateTime.utc(2026, 7, 6, 3), 'America/New_York'), 'EDT');
  });

  test('finds the UTC instant of a local midnight for day windows', () {
    expect(zones.startOfDay(LocalDate(2026, 11, 2), 'Asia/Manila'), DateTime.utc(2026, 11, 1, 16));
  });
}
