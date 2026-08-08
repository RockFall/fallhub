import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:fallhub/features/habitat/flame/habitat_locations.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HabitatLocations', () {
    test('all presets build distinct maps with walkable spawn', () {
      final sizes = <(int, int)>{};
      for (final id in HabitatLocationIds.all) {
        final map = HabitatLocations.create(id);
        expect(map.width, greaterThan(8));
        expect(map.height, greaterThan(6));
        expect(map.props, isNotEmpty);
        expect(map.walkableCells(), isNotEmpty);
        final spawn = HabitatLocations.spawn(id);
        // Spawn itself may be on furniture — nearest walkable must exist.
        expect(
          map.walkableCells().any(
            (c) =>
                (c.$1 - spawn.$1).abs() + (c.$2 - spawn.$2).abs() <= 6,
          ),
          isTrue,
        );
        sizes.add((map.width, map.height));
        expect(HabitatLocations.label(id), isNotEmpty);
      }
      // Layouts are not all identical footprints.
      expect(sizes.length, greaterThan(1));
    });

    test('bedroom preset matches demoRoom size', () {
      final bed = HabitatLocations.create(HabitatLocationIds.bedroom);
      final demo = HabitatMap.demoRoom();
      expect(bed.width, demo.width);
      expect(bed.height, demo.height);
    });
  });

  group('HabitatGame.switchLocation', () {
    test('rebinds map, preserves session edits, teleports pawn', () async {
      final game = HabitatGame(locationId: HabitatLocationIds.bedroom);
      await game.onLoad();
      final bedroom = game.map;
      expect(game.locationId, HabitatLocationIds.bedroom);

      // Edit bedroom floor — should survive a round-trip.
      bedroom.setFloor(4, 8, HabitatFloor.concrete);

      game.switchLocation(HabitatLocationIds.kitchen);
      expect(game.locationId, HabitatLocationIds.kitchen);
      expect(identical(game.map, bedroom), isFalse);
      expect(game.map.width, 12);
      expect(game.pawn!.map, same(game.map));
      expect(game.map.isWalkable(game.pawn!.cellX, game.pawn!.cellY), isTrue);

      game.switchLocation(HabitatLocationIds.bedroom);
      expect(game.map.floorAt(4, 8), HabitatFloor.concrete);
      game.dispose();
    });
  });
}
