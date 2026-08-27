import 'package:fallhub/features/habitat/flame/habitat_door.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitatDoor', () {
    test('starts closed and blocks passage until fully open', () {
      final map = HabitatMap.demoRoom();
      final door = map.door;
      expect(door.openProgress, 0);
      expect(door.blocksPassage, isTrue);
      expect(map.canStepOnto(door.cell.$1, door.cell.$2), isFalse);
      expect(map.isWalkable(door.cell.$1, door.cell.$2), isTrue);
    });

    test('south perimeter door slides horizontally', () {
      final map = HabitatMap.demoRoom();
      expect(map.door.slideAxis, HabitatDoorSlideAxis.horizontal);
    });

    test('opens to 1.0 then allows step; closes when not held', () {
      final map = HabitatMap.demoRoom();
      final door = map.door;

      door.requestOpen();
      for (var i = 0; i < 40; i++) {
        door.requestOpen();
        door.tick(0.05);
      }
      expect(door.openProgress, closeTo(1.0, 1e-6));
      expect(door.phase, HabitatDoorPhase.open);
      expect(door.blocksPassage, isFalse);
      expect(map.canStepOnto(door.cell.$1, door.cell.$2), isTrue);

      // Stop requesting — after hold timer, door closes.
      for (var i = 0; i < 80; i++) {
        door.tick(0.05);
      }
      expect(door.openProgress, 0);
      expect(door.phase, HabitatDoorPhase.closed);
      expect(door.blocksPassage, isTrue);
    });

    test('partial open still blocks passage', () {
      final map = HabitatMap.demoRoom();
      final door = map.door;
      door.requestOpen();
      door.tick(0.1);
      expect(door.openProgress, greaterThan(0));
      expect(door.openProgress, lessThan(1));
      expect(door.blocksPassage, isTrue);
    });

    test('setDoor reseats and resets animation', () {
      final map = HabitatMap.demoRoom();
      map.door.requestOpen();
      map.door.tick(1);
      expect(map.door.openProgress, greaterThan(0));

      map.setDoor((3, map.height - 1));
      expect(map.doorCell, (3, map.height - 1));
      expect(map.door.cell, (3, map.height - 1));
      expect(map.door.openProgress, 0);
      expect(map.door.phase, HabitatDoorPhase.closed);
    });
  });
}
