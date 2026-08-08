import 'habitat_map.dart';

/// Compact A* on the habitat grid (4-neighborhood).
List<(int, int)> findPath({
  required HabitatMap map,
  required (int, int) from,
  required (int, int) to,
  bool Function(int x, int y)? allowed,
}) {
  if (from == to) return const [];
  if (!map.isWalkable(to.$1, to.$2)) return const [];
  if (allowed != null && !allowed(to.$1, to.$2)) return const [];

  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  final open = <_Node>[_Node(from.$1, from.$2, 0, _h(from, to), null)];
  final bestG = <(int, int), int>{from: 0};
  final closed = <(int, int)>{};

  while (open.isNotEmpty) {
    open.sort((a, b) => a.f.compareTo(b.f));
    final current = open.removeAt(0);
    final key = (current.x, current.y);
    if (closed.contains(key)) continue;
    closed.add(key);

    if (current.x == to.$1 && current.y == to.$2) {
      return _reconstruct(current);
    }

    for (final (dx, dy) in dirs) {
      final nx = current.x + dx;
      final ny = current.y + dy;
      if (!map.isWalkable(nx, ny)) continue;
      if (allowed != null && !allowed(nx, ny)) continue;
      final nKey = (nx, ny);
      if (closed.contains(nKey)) continue;
      final g = current.g + 1;
      if (g >= (bestG[nKey] ?? 1 << 30)) continue;
      bestG[nKey] = g;
      open.add(_Node(nx, ny, g, g + _h(nKey, to), current));
    }
  }
  return const [];
}

int _h((int, int) a, (int, int) b) =>
    (a.$1 - b.$1).abs() + (a.$2 - b.$2).abs();

List<(int, int)> _reconstruct(_Node end) {
  final out = <(int, int)>[];
  _Node? n = end;
  while (n?.parent != null) {
    out.add((n!.x, n.y));
    n = n.parent;
  }
  return out.reversed.toList();
}

class _Node {
  _Node(this.x, this.y, this.g, this.f, this.parent);
  final int x;
  final int y;
  final int g;
  final int f;
  final _Node? parent;
}

/// Nearest walkable cell adjacent to a prop footprint (for “go to furniture”).
(int, int)? approachCell(HabitatMap map, HabitatProp prop, (int, int) from) {
  final (ox, oy) = prop.origin;
  final (w, h) = prop.size;
  final candidates = <(int, int)>[];
  for (var y = oy - 1; y <= oy + h; y++) {
    for (var x = ox - 1; x <= ox + w; x++) {
      final onBorder = x == ox - 1 ||
          x == ox + w ||
          y == oy - 1 ||
          y == oy + h;
      if (!onBorder) continue;
      if (map.isWalkable(x, y)) candidates.add((x, y));
    }
  }
  if (candidates.isEmpty) return null;
  candidates.sort(
    (a, b) =>
        ((a.$1 - from.$1).abs() + (a.$2 - from.$2).abs()) -
        ((b.$1 - from.$1).abs() + (b.$2 - from.$2).abs()),
  );
  return candidates.first;
}
