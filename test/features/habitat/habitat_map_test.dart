import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitatMap.demoRoom', () {
    late HabitatMap map;

    setUp(() {
      map = HabitatMap.demoRoom();
    });

    test('has expected size', () {
      expect(map.width, 16);
      expect(map.height, 11);
    });

    test('border cells are blocked except south door', () {
      expect(map.isWalkable(0, 5), isFalse);
      expect(map.isWalkable(15, 5), isFalse);
      expect(map.isWalkable(5, 0), isFalse);
      expect(map.isWalkable(5, 10), isFalse);
      expect(map.doorCell, (8, 10));
      expect(map.isWalkable(8, 10), isTrue);
    });

    test('furniture footprints block walk', () {
      expect(map.isWalkable(2, 2), isFalse); // bed 1×2 (vertical)
      expect(map.isWalkable(2, 3), isFalse);
      expect(map.isWalkable(3, 2), isTrue); // east of bed is free
      expect(map.props.firstWhere((p) => p.id == 'bed').size, (1, 2));
      expect(map.isWalkable(7, 5), isFalse); // table
      expect(map.isWalkable(7, 7), isFalse); // chair
    });

    test('lamp does not block walk', () {
      expect(map.isWalkable(12, 3), isTrue);
    });

    test('open floor is walkable', () {
      expect(map.isWalkable(4, 8), isTrue);
      expect(map.walkableCells(), isNotEmpty);
    });

    test('propAt finds furniture', () {
      expect(map.propAt(2, 2)?.id, 'bed');
      expect(map.propAt(12, 3)?.id, 'lamp');
      expect(map.propAt(4, 8), isNull);
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
