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

    (int, int) freeInteriorCell() {
      for (final c in map.walkableCells()) {
        if (map.propAt(c.$1, c.$2) != null) continue;
        if (map.isWallCell(c.$1, c.$2)) continue;
        if (map.doorCell == c) continue;
        return c;
      }
      fail('no free interior cell');
    }

    test('paints floor and undoes', () {
      final cell = freeInteriorCell();
      final before = map.floorAt(cell.$1, cell.$2);
      editor.tool = HabitatEditTool.floor;
      editor.paintFloor = HabitatFloor.carpet;
      expect(editor.applyTap(cell.$1, cell.$2), isTrue);
      expect(map.floorAt(cell.$1, cell.$2), HabitatFloor.carpet);
      expect(editor.undo(), isTrue);
      expect(map.floorAt(cell.$1, cell.$2), before);
    });

    test('places and erases prop with unique id', () {
      final cell = freeInteriorCell();
      editor.tool = HabitatEditTool.place;
      editor.placeKind = HabitatPropKinds.lamp;
      final before = map.props.length;
      expect(editor.applyTap(cell.$1, cell.$2), isTrue);
      expect(map.props.length, before + 1);
      final placed = map.propAt(cell.$1, cell.$2);
      expect(placed, isNotNull);
      expect(placed!.id, isNot(equals(HabitatPropKinds.lamp)));

      editor.tool = HabitatEditTool.erase;
      expect(editor.applyTap(cell.$1, cell.$2), isTrue);
      expect(map.propAt(cell.$1, cell.$2), isNull);
      expect(map.props.length, before);
    });

    test('moves prop and rebuilds walkable', () {
      final chair = map.props.firstWhere(
        (p) => p.kind == 'dining_chair' || p.kind == HabitatPropKinds.chair,
        orElse: () => map.props.firstWhere((p) => p.size == (1, 1)),
      );
      final from = chair.origin;
      expect(map.isWalkable(from.$1, from.$2), isFalse);
      final dest = freeInteriorCell();
      editor.tool = HabitatEditTool.move;
      expect(editor.applyTap(from.$1, from.$2), isFalse); // pick up
      expect(editor.movingProp, chair);
      expect(editor.applyTap(dest.$1, dest.$2), isTrue);
      expect(chair.origin, dest);
      expect(map.isWalkable(from.$1, from.$2), isTrue);
      expect(map.isWalkable(dest.$1, dest.$2), isFalse);
    });

    test('toggles interior wall', () {
      final cell = freeInteriorCell();
      editor.tool = HabitatEditTool.wall;
      expect(map.isWalkable(cell.$1, cell.$2), isTrue);
      expect(editor.applyTap(cell.$1, cell.$2), isTrue);
      expect(map.isWallCell(cell.$1, cell.$2), isTrue);
      expect(map.isWalkable(cell.$1, cell.$2), isFalse);
      expect(editor.applyTap(cell.$1, cell.$2), isTrue);
      expect(map.isWallCell(cell.$1, cell.$2), isFalse);
    });

    test('moves door along perimeter', () {
      editor.tool = HabitatEditTool.door;
      final original = map.doorCell;
      expect(original, isNotNull);
      // Pick another perimeter cell on the south edge.
      final target = (3, map.height - 1);
      expect(editor.applyTap(target.$1, target.$2), isTrue);
      expect(map.doorCell, target);
      expect(map.isWalkable(target.$1, target.$2), isTrue);
      expect(map.isWalkable(original.$1, original.$2), isFalse);
    });

    test('rejects prop overlap', () {
      editor.tool = HabitatEditTool.place;
      editor.placeKind = HabitatPropKinds.chair;
      final bed = map.propByKind(HabitatPropKinds.bed)!;
      expect(editor.applyTap(bed.origin.$1, bed.origin.$2), isFalse);
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

    test('bed footprint is 1×2 with visual drawSize', () {
      final bed = HabitatPropCatalog.spawn(HabitatPropKinds.bed, (0, 0));
      expect(bed.size, (1, 2));
      final draw = bed.drawSize;
      expect(draw, isNotNull);
      expect(draw!.$1, greaterThan(0));
      expect(draw.$2, greaterThan(0));
    });
  });
}
