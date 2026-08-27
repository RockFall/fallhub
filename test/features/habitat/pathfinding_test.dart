import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/pathfinding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HabitatMap map;

  setUp(() {
    map = HabitatMap.demoRoom();
  });

  test('findPath reaches open cell around furniture', () {
    const from = (4, 5);
    expect(map.isWalkable(from.$1, from.$2), isTrue);
    final bed = map.props.firstWhere((p) => p.id == 'bed');
    final target = approachCell(map, bed, from);
    expect(target, isNotNull);
    final path = findPath(map: map, from: from, to: target!);
    expect(path, isNotEmpty);
    expect(path.last, target);
    for (final step in path) {
      expect(map.isWalkable(step.$1, step.$2), isTrue);
    }
  });

  test('findPath empty when target blocked', () {
    final bed = map.props.firstWhere((p) => p.id == 'bed');
    final path = findPath(
      map: map,
      from: (4, 5),
      to: bed.origin, // bed footprint cell
    );
    expect(path, isEmpty);
  });
}
