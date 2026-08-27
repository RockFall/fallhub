import '../../flame/habitat_editor.dart';
import '../../flame/habitat_map.dart';
import '../../flame/habitat_prop_catalog.dart';
import '../../flame/habitat_tint.dart';

/// Named editor command for debug timeline (MD 08 M28).
class HabitatEditorCommand {
  const HabitatEditorCommand({
    required this.id,
    required this.label,
    required this.atSimSeconds,
  });

  final String id;
  final String label;
  final double atSimSeconds;
}

/// Prefab blueprint — list of prop placements relative to origin (M28).
class HabitatPrefab {
  const HabitatPrefab({
    required this.id,
    required this.label,
    required this.placements,
  });

  final String id;
  final String label;
  final List<({String kind, int dx, int dy})> placements;
}

abstract final class HabitatPrefabs {
  static const readingNook = HabitatPrefab(
    id: 'reading_nook',
    label: 'Cantinho de leitura',
    placements: [
      (kind: HabitatPropKinds.chair, dx: 0, dy: 0),
      (kind: HabitatPropKinds.lamp, dx: 1, dy: 0),
      (kind: HabitatPropKinds.plant, dx: 0, dy: 1),
    ],
  );

  static const deskSet = HabitatPrefab(
    id: 'desk_set',
    label: 'Mesa de trabalho',
    placements: [
      (kind: HabitatPropKinds.table, dx: 0, dy: 0),
      (kind: HabitatPropKinds.chair, dx: 0, dy: 2),
      (kind: HabitatPropKinds.lamp, dx: 2, dy: 0),
    ],
  );

  static const diningSet = HabitatPrefab(
    id: 'dining_set',
    label: 'Mesa de jantar',
    placements: [
      (kind: HabitatPropKinds.table, dx: 0, dy: 0),
      (kind: HabitatPropKinds.chair, dx: 0, dy: 2),
      (kind: HabitatPropKinds.chair, dx: 2, dy: 2),
    ],
  );

  static const all = [readingNook, deskSet, diningSet];
}

/// Thin command log + prefab stamp on top of [HabitatEditor] undo (M28).
class HabitatCommandStack {
  HabitatCommandStack(this.editor);

  final HabitatEditor editor;
  final List<HabitatEditorCommand> history = [];
  var _seq = 0;

  void _log(String label, double sim) {
    history.add(
      HabitatEditorCommand(
        id: 'cmd-${_seq++}',
        label: label,
        atSimSeconds: sim,
      ),
    );
    if (history.length > 80) history.removeAt(0);
  }

  bool stampPrefab(
    HabitatPrefab prefab,
    int originX,
    int originY, {
    double simSeconds = 0,
  }) {
    if (!editor.enabled) return false;
    editor.pushUndo();
    var placed = 0;
    for (final p in prefab.placements) {
      final x = originX + p.dx;
      final y = originY + p.dy;
      final ghost = HabitatPropCatalog.spawn(
        p.kind,
        (x, y),
        id: '${prefab.id}-$placed-$simSeconds',
        tint: StuffPalettes.wood,
      );
      if (!editor.map.canPlace(ghost, (x, y))) continue;
      editor.map.placeProp(ghost);
      placed++;
    }
    if (placed == 0) {
      editor.undo();
      return false;
    }
    editor.map.rebuildBlocked();
    _log('prefab:${prefab.id} @$originX,$originY', simSeconds);
    return true;
  }

  bool undo({double simSeconds = 0}) {
    final ok = editor.undo();
    if (ok) _log('undo', simSeconds);
    return ok;
  }
}

/// Auto-furnish empty regions by role (MD 08 M29).
abstract final class HabitatAutoFurnish {
  static int furnish(
    HabitatMap map, {
    required HabitatPrefab Function(String roleHint) pickPrefab,
    String roleHint = 'generic',
    int maxProps = 6,
  }) {
    // Find a walkable open cell near center.
    final cx = map.width ~/ 2;
    final cy = map.height ~/ 2;
    (int, int)? origin;
    for (var r = 0; r < 6 && origin == null; r++) {
      for (var dy = -r; dy <= r; dy++) {
        for (var dx = -r; dx <= r; dx++) {
          final x = cx + dx;
          final y = cy + dy;
          if (!map.inBounds(x, y) || map.isWallCell(x, y)) continue;
          if (!map.isWalkable(x, y)) continue;
          origin = (x, y);
          break;
        }
        if (origin != null) break;
      }
    }
    if (origin == null) return 0;
    final prefab = pickPrefab(roleHint);
    var placed = 0;
    for (final p in prefab.placements) {
      if (placed >= maxProps) break;
      final x = origin.$1 + p.dx;
      final y = origin.$2 + p.dy;
      final ghost = HabitatPropCatalog.spawn(
        p.kind,
        (x, y),
        id: 'autofurnish-$placed',
      );
      if (!map.canPlace(ghost, (x, y))) continue;
      map.placeProp(ghost);
      placed++;
    }
    map.rebuildBlocked();
    return placed;
  }

  static HabitatPrefab prefabForRole(String role) => switch (role) {
        'bedroom' => HabitatPrefabs.readingNook,
        'office' => HabitatPrefabs.deskSet,
        'dining' || 'kitchen' => HabitatPrefabs.diningSet,
        _ => HabitatPrefabs.readingNook,
      };
}
