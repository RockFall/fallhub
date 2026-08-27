import 'package:fallhub/features/habitat/flame/habitat_editor.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_prop_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitatEditor', () {
    late HabitatMap map;
    late HabitatEditor editor;

    setUp(() {
      map = HabitatMap.demoRoom();
      editor = HabitatEditor(map)..enter();
    });

    test('paints floor and undoes', () {
      expect(map.floorAt(4, 8), HabitatFloor.wood);
      editor.tool = HabitatEditTool.floor;
      editor.paintFloor = HabitatFloor.carpet;
      expect(editor.applyTap(4, 8), isTrue);
      expect(map.floorAt(4, 8), HabitatFloor.carpet);
      expect(editor.undo(), isTrue);
      expect(map.floorAt(4, 8), HabitatFloor.wood);
    });

    test('places and erases prop with unique id', () {
      editor.tool = HabitatEditTool.place;
      editor.placeKind = HabitatPropKinds.lamp;
      final before = map.props.length;
      expect(editor.applyTap(4, 8), isTrue);
      expect(map.props.length, before + 1);
      expect(map.propAt(4, 8)?.kind, HabitatPropKinds.lamp);
      expect(map.propAt(4, 8)?.id, isNot(equals('lamp')));

      editor.tool = HabitatEditTool.erase;
      expect(editor.applyTap(4, 8), isTrue);
      expect(map.propAt(4, 8), isNull);
      expect(map.props.length, before);
    });

    test('moves prop and rebuilds walkable', () {
      final chair = map.propByKind(HabitatPropKinds.chair)!;
      expect(map.isWalkable(7, 7), isFalse);
      editor.tool = HabitatEditTool.move;
      expect(editor.applyTap(7, 7), isFalse); // pick up
      expect(editor.movingProp, chair);
      expect(editor.applyTap(4, 8), isTrue);
      expect(chair.origin, (4, 8));
      expect(map.isWalkable(7, 7), isTrue);
      expect(map.isWalkable(4, 8), isFalse);
    });

    test('toggles interior wall', () {
      editor.tool = HabitatEditTool.wall;
      expect(map.isWalkable(5, 5), isTrue);
      expect(editor.applyTap(5, 5), isTrue);
      expect(map.isWallCell(5, 5), isTrue);
      expect(map.isWalkable(5, 5), isFalse);
      expect(editor.applyTap(5, 5), isTrue);
      expect(map.isWallCell(5, 5), isFalse);
    });

    test('moves door along perimeter', () {
      editor.tool = HabitatEditTool.door;
      expect(map.doorCell, (8, 10));
      expect(editor.applyTap(3, 10), isTrue);
      expect(map.doorCell, (3, 10));
      expect(map.isWalkable(3, 10), isTrue);
      expect(map.isWalkable(8, 10), isFalse);
    });

    test('rejects prop overlap', () {
      editor.tool = HabitatEditTool.place;
      editor.placeKind = HabitatPropKinds.chair;
      expect(editor.applyTap(2, 2), isFalse); // bed footprint
    });
  });

  group('HabitatPropCatalog', () {
    test('labels and assets cover all kinds', () {
      for (final kind in HabitatPropKinds.all) {
        expect(HabitatPropCatalog.label(kind), isNotEmpty);
        final path = HabitatPropCatalog.assetPath(kind);
        expect(
          path == HabitatPropCatalog.proceduralAsset || path.contains('.png'),
          isTrue,
          reason: 'kind=$kind path=$path',
        );
      }
    });

    test('bed drawSize matches 1×2 footprint after atlas crop', () {
      final bed = HabitatPropCatalog.spawn(HabitatPropKinds.bed, (0, 0));
      expect(bed.size, (1, 2));
      expect(bed.drawSize, (1.0, 2.0));
      final crop = HabitatPropCatalog.srcRect(HabitatPropKinds.bed);
      expect(crop, isNotNull);
      // Cropped region is roughly tall, not a skinny strip of the 128² sheet.
      expect(crop!.$3 / crop.$4, greaterThan(0.45));
    });
  });
}
