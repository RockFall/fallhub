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
      expect(sizes.length, greaterThan(1));
    });

    test('bedroom matches demoRoom and has outdoor balcony', () {
      final bed = HabitatLocations.create(HabitatLocationIds.bedroom);
      final demo = HabitatMap.demoRoom();
      expect(bed.width, demo.width);
      expect(bed.height, demo.height);
      expect(bed.floorAt(8, 10), HabitatFloor.concrete);
      expect(bed.props.any((p) => p.id.contains('balcony')), isTrue);
    });

    test('office and kitchen expose outdoor side courts', () {
      final office = HabitatLocations.create(HabitatLocationIds.office);
      expect(office.floorAt(13, 5), HabitatFloor.concrete);
      expect(office.props.any((p) => p.id.startsWith('court_')), isTrue);

      final kitchen = HabitatLocations.create(HabitatLocationIds.kitchen);
      expect(kitchen.floorAt(13, 5), HabitatFloor.concrete);
      expect(kitchen.props.any((p) => p.id.startsWith('patio_')), isTrue);
    });

    test('terrace is decked garden exterior', () {
      final t = HabitatLocations.create(HabitatLocationIds.terrace);
      expect(t.floorAt(8, 6), HabitatFloor.carpet);
      expect(t.floorAt(8, 4), HabitatFloor.wood);
      expect(t.props.where((p) => p.kind == 'plant').length, greaterThan(4));
    });
  });

  group('HabitatGame.switchLocation', () {
    test('rebinds map, preserves session edits, teleports pawn', () async {
      final game = HabitatGame(locationId: HabitatLocationIds.bedroom);
      await game.onLoad();
      final bedroom = game.map;
      expect(game.locationId, HabitatLocationIds.bedroom);

      bedroom.setFloor(4, 5, HabitatFloor.concrete);

      game.switchLocation(HabitatLocationIds.kitchen);
      expect(game.locationId, HabitatLocationIds.kitchen);
      expect(identical(game.map, bedroom), isFalse);
      expect(game.map.width, 16);
      expect(game.pawn!.map, same(game.map));
      expect(game.map.isWalkable(game.pawn!.cellX, game.pawn!.cellY), isTrue);

      game.switchLocation(HabitatLocationIds.bedroom);
      expect(game.map.floorAt(4, 5), HabitatFloor.concrete);
      game.dispose();
    });
  });
}
