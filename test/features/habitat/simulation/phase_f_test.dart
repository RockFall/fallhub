import 'package:fallhub/features/habitat/flame/habitat_editor.dart';
import 'package:fallhub/features/habitat/flame/habitat_locations.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_room_stats.dart';
import 'package:fallhub/features/habitat/simulation/world/habitat_commands.dart';
import 'package:fallhub/features/habitat/simulation/world/room_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M26 structural editor', () {
    test('drawRoom fills floor and adds interior walls', () {
      final map = HabitatLocations.create(HabitatLocationIds.bedroom);
      final editor = HabitatEditor(map)..enter();
      editor.tool = HabitatEditTool.drawRoom;
      expect(editor.applyRoomRect(3, 3, 8, 7), isTrue);
      expect(map.floorAt(5, 5), isNotNull);
      expect(map.customWalls.isNotEmpty || map.doorCell != (0, 0), isTrue);
      editor.tool = HabitatEditTool.window;
      // Place window on an interior wall cell if any.
      if (map.customWalls.isNotEmpty) {
        final (wx, wy) = map.customWalls.first;
        map.windowCells.clear();
        editor.applyTap(wx, wy);
        expect(map.windowCells, isNotEmpty);
      }
    });
  });

  group('M27 room detection', () {
    test('detects regions and bedroom role for demo room', () {
      final map = HabitatLocations.create(HabitatLocationIds.bedroom);
      final regions = HabitatRoomDetector.detect(map);
      expect(regions, isNotEmpty);
      expect(regions.first.area, greaterThan(10));
      expect(
        regions.any((r) => r.role == HabitatRoomRole.bedroom),
        isTrue,
      );
    });
  });

  group('M28 commands / prefabs', () {
    test('stamp prefab places props and logs command', () {
      final map = HabitatLocations.create(HabitatLocationIds.office);
      final editor = HabitatEditor(map)..enter();
      final stack = HabitatCommandStack(editor);
      final ok = stack.stampPrefab(HabitatPrefabs.deskSet, 4, 4);
      expect(ok, isTrue);
      expect(map.props.length, greaterThan(0));
      expect(stack.history.last.label, contains('prefab:desk_set'));
    });
  });

  group('M29 auto-furnish', () {
    test('furnishes empty-ish map', () {
      final map = HabitatMap(
        width: 10,
        height: 8,
        floors: List.filled(80, HabitatFloor.wood),
        props: [],
      );
      final n = HabitatAutoFurnish.furnish(
        map,
        pickPrefab: HabitatAutoFurnish.prefabForRole,
        roleHint: 'office',
      );
      expect(n, greaterThan(0));
      expect(map.props, isNotEmpty);
    });
  });
}
