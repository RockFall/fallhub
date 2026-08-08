import 'habitat_map.dart';

/// Allowed-area helpers for V9.13 (null = unrestricted whole map).
abstract final class HabitatZones {
  static bool isAllowed(Set<(int, int)>? zone, int x, int y) =>
      zone == null || zone.contains((x, y));

  static Set<(int, int)> allWalkable(HabitatMap map) => {
        for (final c in map.walkableCells()) c,
      };

  /// Nearest walkable cell inside [zone] to [from] (Chebyshev).
  static (int, int)? nearestAllowed(
    HabitatMap map,
    Set<(int, int)> zone,
    (int, int) from,
  ) {
    (int, int)? best;
    var bestD = 1 << 30;
    for (final c in zone) {
      if (!map.isWalkable(c.$1, c.$2)) continue;
      final d = (c.$1 - from.$1).abs() + (c.$2 - from.$2).abs();
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  static Set<(int, int)> decodeCells(List<dynamic>? raw) {
    if (raw == null) return {};
    final out = <(int, int)>{};
    for (final e in raw) {
      if (e is List && e.length >= 2) {
        out.add(((e[0] as num).toInt(), (e[1] as num).toInt()));
      }
    }
    return out;
  }

  static List<List<int>> encodeCells(Set<(int, int)> cells) => [
        for (final c in cells) [c.$1, c.$2],
      ];
}
