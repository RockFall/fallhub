import 'package:fallhub/features/habitat/flame/habitat_locations.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_prop_catalog.dart';
import 'package:fallhub/features/habitat/flame/habitat_room_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitatRoomAnalyzer', () {
    test('bedroom demo maps to Quarto with meters in range', () {
      final map = HabitatMap.demoRoom();
      final stats = HabitatRoomAnalyzer.analyze(
        map,
        locationId: HabitatLocationIds.bedroom,
      );
      expect(stats.role, HabitatRoomRole.bedroom);
      expect(stats.beauty, inInclusiveRange(0, 100));
      expect(stats.space, inInclusiveRange(0, 100));
      expect(stats.cleanliness, inInclusiveRange(0, 100));
      expect(stats.wealth, inInclusiveRange(0, 100));
      expect(stats.breakdown, isNotEmpty);
    });

    test('kitchen is dining; terrace is exterior', () {
      final kitchen = HabitatLocations.create(HabitatLocationIds.kitchen);
      final k = HabitatRoomAnalyzer.analyze(
        kitchen,
        locationId: HabitatLocationIds.kitchen,
      );
      expect(k.role, HabitatRoomRole.dining);

      final terrace = HabitatLocations.create(HabitatLocationIds.terrace);
      final t = HabitatRoomAnalyzer.analyze(
        terrace,
        locationId: HabitatLocationIds.terrace,
      );
      expect(t.role, HabitatRoomRole.exterior);
    });

    test('office with desk+lamp is Escritório', () {
      final office = HabitatLocations.create(HabitatLocationIds.office);
      final o = HabitatRoomAnalyzer.analyze(
        office,
        locationId: HabitatLocationIds.office,
      );
      expect(o.role, HabitatRoomRole.office);
    });

    test('adding furniture raises beauty and wealth', () {
      final map = HabitatMap(
        width: 10,
        height: 8,
        floors: List.filled(80, HabitatFloor.concrete),
        props: const [],
      );
      final empty = HabitatRoomAnalyzer.analyze(map);
      map.placeProp(
        HabitatPropCatalog.spawn(HabitatPropKinds.table, (3, 3)),
      );
      map.placeProp(
        HabitatPropCatalog.spawn(HabitatPropKinds.chair, (3, 5)),
      );
      map.placeProp(
        HabitatPropCatalog.spawn(HabitatPropKinds.lamp, (6, 2)),
      );
      final furnished = HabitatRoomAnalyzer.analyze(map);
      expect(furnished.beauty, greaterThan(empty.beauty));
      expect(furnished.wealth, greaterThan(empty.wealth));
      expect(furnished.role, HabitatRoomRole.office);
    });
  });
}
