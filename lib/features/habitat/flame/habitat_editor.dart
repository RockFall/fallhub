import 'dart:ui';

import 'habitat_map.dart';
import 'habitat_prop_catalog.dart';
import 'habitat_tint.dart';

/// Active tool while Habitat edit mode is on (V7).
enum HabitatEditTool {
  select,
  floor,
  place,
  erase,
  wall,
  door,
  move,
  zone,
  zoneErase,
}

/// Session-local room editor: tools + undo stack (no Drift).
class HabitatEditor {
  HabitatEditor(this.map);

  HabitatMap map;

  bool enabled = false;
  HabitatEditTool tool = HabitatEditTool.select;
  HabitatFloor paintFloor = HabitatFloor.wood;
  String placeKind = HabitatPropKinds.chair;
  Color placeTint = StuffPalettes.wood;
  HabitatProp? movingProp;

  final List<HabitatMapSnapshot> _undo = [];
  static const int maxUndo = 40;

  bool get canUndo => _undo.isNotEmpty;

  void enter() {
    enabled = true;
    tool = HabitatEditTool.select;
    movingProp = null;
    _undo.clear();
  }

  void exit() {
    enabled = false;
    movingProp = null;
    tool = HabitatEditTool.select;
  }

  /// Point editor at another locale (clears session undo).
  void bind(HabitatMap next) {
    map = next;
    movingProp = null;
    _undo.clear();
  }

  void pushUndo() {
    _undo.add(map.snapshot());
    if (_undo.length > maxUndo) _undo.removeAt(0);
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    map.restore(_undo.removeLast());
    movingProp = null;
    return true;
  }

  /// Apply primary tap in edit mode. Returns true if the map changed.
  bool applyTap(int x, int y) {
    if (!enabled || !map.inBounds(x, y)) return false;

    switch (tool) {
      case HabitatEditTool.select:
        return false;
      case HabitatEditTool.floor:
        if (map.isWallCell(x, y)) return false;
        pushUndo();
        map.setFloor(x, y, paintFloor);
        return true;
      case HabitatEditTool.place:
        final ghost = HabitatPropCatalog.spawn(
          placeKind,
          (x, y),
          tint: placeTint,
        );
        if (!map.canPlace(ghost, (x, y))) return false;
        pushUndo();
        map.placeProp(ghost);
        return true;
      case HabitatEditTool.erase:
        final prop = map.propAt(x, y);
        if (prop == null) return false;
        pushUndo();
        map.removeProp(prop);
        if (identical(movingProp, prop)) movingProp = null;
        return true;
      case HabitatEditTool.wall:
        if (map.isPerimeter(x, y)) return false;
        pushUndo();
        map.toggleCustomWall(x, y);
        return true;
      case HabitatEditTool.door:
        if (!map.isPerimeter(x, y)) return false;
        if (map.doorCell == (x, y)) return false;
        pushUndo();
        map.setDoor((x, y));
        return true;
      case HabitatEditTool.move:
        final at = map.propAt(x, y);
        if (movingProp == null) {
          if (at == null) return false;
          movingProp = at;
          return false;
        }
        final prop = movingProp!;
        if (prop.origin == (x, y)) {
          movingProp = null;
          return false;
        }
        if (!map.canPlace(prop, (x, y), ignoreId: prop.id)) return false;
        pushUndo();
        map.moveProp(prop, (x, y));
        movingProp = null;
        return true;
      case HabitatEditTool.zone:
      case HabitatEditTool.zoneErase:
        return false;
    }
  }

  /// Ghost prop for place / move preview.
  HabitatProp? ghostAt(int x, int y) {
    if (!enabled) return null;
    if (tool == HabitatEditTool.place) {
      return HabitatPropCatalog.spawn(placeKind, (x, y), tint: placeTint);
    }
    if (tool == HabitatEditTool.move && movingProp != null) {
      return HabitatPropCatalog.copyOf(movingProp!, origin: (x, y));
    }
    return null;
  }

  bool ghostValidAt(int x, int y) {
    final ghost = ghostAt(x, y);
    if (ghost == null) return false;
    final ignore =
        tool == HabitatEditTool.move ? movingProp?.id : null;
    return map.canPlace(ghost, (x, y), ignoreId: ignore);
  }
}
