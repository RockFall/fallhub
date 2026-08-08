import 'package:fallhub/features/habitat/flame/habitat_beauty.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_prop_catalog.dart';
import 'package:fallhub/features/habitat/flame/habitat_room_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitatBeautyField', () {
    test('decor raises aggregate beauty vs empty room', () {
      final empty = HabitatMap(
        width: 10,
        height: 8,
        floors: List.filled(80, HabitatFloor.concrete),
        props: const [],
      );
      final emptyScore = HabitatBeautyField.aggregate(empty);

      final fancy = HabitatMap(
        width: 10,
        height: 8,
        floors: List.filled(80, HabitatFloor.wood),
        props: [
          HabitatPropCatalog.spawn(HabitatPropKinds.plant, (3, 3)),
          HabitatPropCatalog.spawn(HabitatPropKinds.painting, (5, 2)),
          HabitatPropCatalog.spawn(HabitatPropKinds.vase, (6, 4)),
        ],
      );
      final fancyScore = HabitatBeautyField.aggregate(fancy);
      expect(fancyScore, greaterThan(emptyScore));
    });

    test('walls block line of sight contribution', () {
      final map = HabitatMap(
        width: 10,
        height: 8,
        floors: List.filled(80, HabitatFloor.wood),
        props: [
          HabitatPropCatalog.spawn(HabitatPropKinds.painting, (2, 2)),
        ],
        customWalls: {(4, 2), (4, 3), (4, 4)},
      );
      final field = HabitatBeautyField.compute(map);
      final near = field[2 * 10 + 3]; // east of painting, no wall
      final far = field[2 * 10 + 6]; // past wall
      expect(near, greaterThan(far));
    });

    test('room stats beauty follows field when decor added', () {
      final map = HabitatMap.demoRoom();
      final before = HabitatRoomAnalyzer.analyze(map).beauty;
      map.placeProp(
        HabitatPropCatalog.spawn(HabitatPropKinds.plant, (8, 4)),
      );
      map.placeProp(
        HabitatPropCatalog.spawn(HabitatPropKinds.painting, (9, 3)),
      );
      final after = HabitatRoomAnalyzer.analyze(map).beauty;
      expect(after, greaterThan(before));
    });
  });
}
