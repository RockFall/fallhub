import 'package:fallhub/features/habitat/flame/habitat_climate.dart';
import 'package:fallhub/features/habitat/flame/habitat_locations.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_prop_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitatClimateField V9.12', () {
    test('indoor base differs by locale', () {
      expect(
        HabitatClimateField.indoorBase(HabitatLocationIds.bedroom),
        22,
      );
      expect(
        HabitatClimateField.indoorBase(HabitatLocationIds.office),
        21,
      );
      expect(
        HabitatClimateField.indoorBase(HabitatLocationIds.kitchen),
        23,
      );
    });

    test('heater raises nearby temperature', () {
      final map = HabitatMap(
        width: 8,
        height: 8,
        floors: List.filled(64, HabitatFloor.concrete),
        props: [
          HabitatPropCatalog.spawn(HabitatPropKinds.heater, (3, 3)),
        ],
      );
      final field = HabitatClimateField.compute(
        map,
        locationId: HabitatLocationIds.terrace,
        phase: 0.5,
        outdoorC: 10,
      );
      final atHeater = HabitatClimateField.at(field, map, 3, 3);
      final far = HabitatClimateField.at(field, map, 7, 7);
      expect(atHeater, greaterThan(far));
    });

    test('comfortDelta outside band', () {
      expect(HabitatClimateField.comfortDelta(15), lessThan(0));
      expect(HabitatClimateField.comfortDelta(30), greaterThan(0));
      expect(HabitatClimateField.comfortDelta(22), 0);
    });

    test('night lowers effective outdoor', () {
      final day = HabitatClimateField.effectiveOutdoor(22, phase: 0.45);
      final night = HabitatClimateField.effectiveOutdoor(22, phase: 0.9);
      expect(night, day - 3);
    });
  });
}
