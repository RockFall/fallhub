import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitatMap.bedroomPreset / demoRoom', () {
    late HabitatMap map;

    setUp(() {
      map = HabitatMap.demoRoom();
    });

    test('has suite size with balcony strip', () {
      expect(map.width, 18);
      expect(map.height, 13);
      expect(map.props.any((p) => p.id == 'bed'), isTrue);
      expect(map.props.any((p) => p.id == 'tv'), isTrue);
      expect(map.props.any((p) => p.id.startsWith('balcony_')), isTrue);
      expect(map.props.any((p) => p.kind == 'couch'), isTrue);
    });

    test('border cells are blocked except south door', () {
      expect(map.isWalkable(0, 5), isFalse);
      expect(map.isWalkable(17, 5), isFalse);
      expect(map.isWalkable(5, 0), isFalse);
      expect(map.isWalkable(5, 12), isFalse);
      expect(map.doorCell, (9, 12));
      // Pathfinding sees the doorway; stepping waits until the door is fully open.
      expect(map.isWalkable(9, 12), isTrue);
      expect(map.canStepOnto(9, 12), isFalse);
    });

    test('bed blocks footprint; lamp does not', () {
      expect(map.isWalkable(3, 2), isFalse);
      expect(map.isWalkable(3, 3), isFalse);
      expect(map.props.firstWhere((p) => p.id == 'bed').size, (1, 2));
      final lamp = map.props.firstWhere((p) => p.id == 'bed_lamp');
      expect(map.isWalkable(lamp.origin.$1, lamp.origin.$2), isTrue);
    });

    test('indoor and balcony floors differ', () {
      expect(map.floorAt(3, 3), HabitatFloor.carpet);
      expect(map.floorAt(12, 4), HabitatFloor.wood);
      expect(map.floorAt(8, 10), HabitatFloor.concrete);
    });

    test('partition leaves sleep↔living passage', () {
      expect(map.isWallCell(8, 3), isFalse);
      expect(map.isWallCell(8, 4), isFalse);
      expect(map.isWallCell(8, 1), isTrue);
    });

    test('propAt finds key furniture', () {
      expect(map.propAt(3, 2)?.id, 'bed');
      expect(map.propAt(14, 2)?.id, 'tv');
      expect(map.propAt(12, 4)?.kind, 'couch');
    });

    test('open floor is walkable', () {
      expect(map.isWalkable(4, 5), isTrue);
      expect(map.walkableCells(), isNotEmpty);
    });
  });

  group('facingFromDelta', () {
    test('maps cardinal deltas', () {
      expect(facingFromDelta(1, 0), HabitatFacing.east);
      expect(facingFromDelta(-1, 0), HabitatFacing.west);
      expect(facingFromDelta(0, 1), HabitatFacing.south);
      expect(facingFromDelta(0, -1), HabitatFacing.north);
    });
  });
}
