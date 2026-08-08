import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitatMap filth V9.9', () {
    test('addTrafficFilth accumulates and cleanCell resets', () {
      final map = HabitatMap(
        width: 6,
        height: 6,
        floors: List.filled(36, HabitatFloor.wood),
        props: const [],
      );
      expect(map.filthAt(2, 2), 0);
      map.addTrafficFilth(2, 2);
      expect(
        map.filthAt(2, 2),
        closeTo(HabitatMap.trafficFilthPerStep, 0.001),
      );
      map.addTrafficFilth(2, 2);
      expect(
        map.filthAt(2, 2),
        closeTo(HabitatMap.trafficFilthPerStep * 2, 0.001),
      );
      map.cleanCell(2, 2);
      expect(map.filthAt(2, 2), 0);
    });

    test('averageFilth reflects walkable cells', () {
      final map = HabitatMap(
        width: 4,
        height: 4,
        floors: List.filled(16, HabitatFloor.concrete),
        props: const [],
      );
      map.addTrafficFilth(1, 1, 0.5);
      expect(map.averageFilth, greaterThan(0.03));
    });

    test('cleanAll wipes every cell', () {
      final map = HabitatMap(
        width: 4,
        height: 4,
        floors: List.filled(16, HabitatFloor.wood),
        props: const [],
      );
      map.addTrafficFilth(1, 1, 0.5);
      map.addTrafficFilth(2, 3, 0.3);
      map.cleanAll();
      expect(map.averageFilth, 0);
      expect(map.filthAt(1, 1), 0);
      expect(map.filthAt(2, 3), 0);
    });

    test('snapshot restore preserves filth', () {
      final map = HabitatMap(
        width: 5,
        height: 5,
        floors: List.filled(25, HabitatFloor.wood),
        props: const [],
      );
      map.addTrafficFilth(2, 2, 0.4);
      final snap = map.snapshot();
      map.cleanCell(2, 2);
      expect(map.filthAt(2, 2), 0);
      map.restore(snap);
      expect(map.filthAt(2, 2), closeTo(0.4, 0.001));
    });
  });
}
