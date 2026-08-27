import '../../flame/habitat_map.dart';
import '../../flame/habitat_prop_catalog.dart';
import '../../flame/habitat_room_stats.dart';

/// Detected enclosed walkable region (MD 08 M27).
class DetectedRoomRegion {
  const DetectedRoomRegion({
    required this.id,
    required this.cells,
    required this.role,
    required this.confidence,
  });

  final String id;
  final Set<(int, int)> cells;
  final HabitatRoomRole role;
  final double confidence;

  int get area => cells.length;
}

/// Flood-fill room detection + semantic guess from props (M27).
abstract final class HabitatRoomDetector {
  static List<DetectedRoomRegion> detect(HabitatMap map) {
    final visited = <(int, int)>{};
    final regions = <DetectedRoomRegion>[];
    var idx = 0;
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final key = (x, y);
        if (visited.contains(key) || map.isWallCell(x, y)) continue;
        final cells = <(int, int)>{};
        final queue = <(int, int)>[(x, y)];
        visited.add(key);
        while (queue.isNotEmpty) {
          final (cx, cy) = queue.removeLast();
          if (map.isWallCell(cx, cy)) continue;
          cells.add((cx, cy));
          for (final (nx, ny) in [
            (cx + 1, cy),
            (cx - 1, cy),
            (cx, cy + 1),
            (cx, cy - 1),
          ]) {
            final nk = (nx, ny);
            if (!map.inBounds(nx, ny) || visited.contains(nk)) continue;
            if (map.isWallCell(nx, ny)) continue;
            visited.add(nk);
            queue.add(nk);
          }
        }
        if (cells.length < 4) continue;
        final (role, conf) = inferRole(map, cells);
        regions.add(
          DetectedRoomRegion(
            id: 'region-$idx',
            cells: cells,
            role: role,
            confidence: conf,
          ),
        );
        idx++;
      }
    }
    return regions;
  }

  static (HabitatRoomRole, double) inferRole(
    HabitatMap map,
    Set<(int, int)> cells,
  ) {
    final scores = <HabitatRoomRole, double>{
      for (final r in HabitatRoomRole.values) r: 0,
    };
    for (final p in map.props) {
      if (!cells.contains(p.origin)) continue;
      switch (p.kind) {
        case HabitatPropKinds.bed:
          scores[HabitatRoomRole.bedroom] =
              (scores[HabitatRoomRole.bedroom] ?? 0) + 8;
        case HabitatPropKinds.table:
          scores[HabitatRoomRole.dining] =
              (scores[HabitatRoomRole.dining] ?? 0) + 1.5;
          scores[HabitatRoomRole.office] =
              (scores[HabitatRoomRole.office] ?? 0) + 0.8;
        case HabitatPropKinds.chair:
          scores[HabitatRoomRole.office] =
              (scores[HabitatRoomRole.office] ?? 0) + 0.5;
          scores[HabitatRoomRole.dining] =
              (scores[HabitatRoomRole.dining] ?? 0) + 0.4;
        case HabitatPropKinds.tv:
        case HabitatPropKinds.boardgame:
          scores[HabitatRoomRole.generic] =
              (scores[HabitatRoomRole.generic] ?? 0) + 1.2;
        case HabitatPropKinds.lamp:
          scores[HabitatRoomRole.bedroom] =
              (scores[HabitatRoomRole.bedroom] ?? 0) + 0.3;
        default:
          scores[HabitatRoomRole.generic] =
              (scores[HabitatRoomRole.generic] ?? 0) + 0.2;
      }
    }
    var carpet = 0;
    var concrete = 0;
    for (final (x, y) in cells) {
      final f = map.floorAt(x, y);
      if (f == HabitatFloor.carpet) carpet++;
      if (f == HabitatFloor.concrete) concrete++;
    }
    if (carpet > cells.length * 0.3) {
      scores[HabitatRoomRole.bedroom] =
          (scores[HabitatRoomRole.bedroom] ?? 0) + 1;
    }
    // A bed always wins suite detection (open-plan sleep+living+balcony).
    final hasBed = map.props.any(
      (p) => p.kind == HabitatPropKinds.bed && cells.contains(p.origin),
    );
    if (hasBed) {
      scores[HabitatRoomRole.bedroom] =
          (scores[HabitatRoomRole.bedroom] ?? 0) + 6;
    }
    if (concrete > cells.length * 0.25) {
      scores[HabitatRoomRole.dining] =
          (scores[HabitatRoomRole.dining] ?? 0) + 1.2;
      scores[HabitatRoomRole.office] =
          (scores[HabitatRoomRole.office] ?? 0) + 0.6;
    }

    var best = HabitatRoomRole.generic;
    var bestScore = -1.0;
    for (final e in scores.entries) {
      if (e.value > bestScore) {
        bestScore = e.value;
        best = e.key;
      }
    }
    final conf = (bestScore / (bestScore + 2)).clamp(0.15, 0.95);
    return (best, conf);
  }
}
