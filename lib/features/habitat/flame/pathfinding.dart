import '../simulation/microbehavior/approach_slots.dart';
import '../simulation/microbehavior/micro_facing.dart';
import '../simulation/microbehavior/route_preference.dart';
import 'habitat_map.dart';

/// Compact A* on the habitat grid (4-neighborhood).
///
/// Optional [cellCost] adds soft preference weight (R12/R17) without blocking.
List<(int, int)> findPath({
  required HabitatMap map,
  required (int, int) from,
  required (int, int) to,
  bool Function(int x, int y)? allowed,
  double Function(int x, int y)? cellCost,
}) {
  if (from == to) return const [];
  if (!map.isWalkable(to.$1, to.$2)) return const [];
  if (allowed != null && !allowed(to.$1, to.$2)) return const [];

  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  final open = <_Node>[
    _Node(from.$1, from.$2, 0, _h(from, to).toDouble(), null),
  ];
  final bestG = <(int, int), double>{from: 0};
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
      final extra = cellCost?.call(nx, ny) ?? 0.0;
      // Keep costs positive-ish so A* stays well-behaved.
      final step = (1.0 + extra).clamp(0.15, 4.0);
      final g = current.g + step;
      if (g >= (bestG[nKey] ?? 1e18)) continue;
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
  final double g;
  final double f;
  final _Node? parent;
}

/// Options for intelligent approach slot ranking (R10).
class ApproachOptions {
  const ApproachOptions({
    this.lookAtCell,
    this.propFacing,
    this.occupiedCells = const {},
    this.pawnCells = const [],
    this.personalSpaceCostAt,
    this.activityGroupCells = const [],
    this.preferenceBias = 0,
    this.pawnId,
  });

  final (int, int)? lookAtCell;
  final MicroFacing? propFacing;
  final Set<(int, int)> occupiedCells;
  final List<(int, int)> pawnCells;
  final double Function(int x, int y)? personalSpaceCostAt;
  final List<(int, int)> activityGroupCells;
  final double preferenceBias;
  final String? pawnId;
}

/// Best walkable cell adjacent to a prop footprint (R10 ranking when options set).
(int, int)? approachCell(
  HabitatMap map,
  HabitatProp prop,
  (int, int) from, {
  ApproachOptions? options,
}) {
  final opts = options;
  if (opts == null) {
    // Legacy: nearest Manhattan border cell.
    final ranked = ApproachSlotRanker.rank(
      ctx: ApproachSlotContext(
        from: from,
        propOrigin: prop.origin,
        propSize: prop.size,
      ),
      isWalkable: map.isWalkable,
    );
    return ranked.isEmpty ? null : ranked.first.cell;
  }

  var ranked = ApproachSlotRanker.rank(
    ctx: ApproachSlotContext(
      from: from,
      propOrigin: prop.origin,
      propSize: prop.size,
      propFacing: opts.propFacing,
      lookAtCell: opts.lookAtCell,
      occupiedCells: opts.occupiedCells,
      pawnCells: opts.pawnCells,
      personalSpaceCostAt: opts.personalSpaceCostAt,
      activityGroupCells: opts.activityGroupCells,
      preferenceBias: opts.preferenceBias,
      routeLengthTo: (x, y) =>
          findPath(map: map, from: from, to: (x, y)).length,
    ),
    isWalkable: map.isWalkable,
  );
  if (opts.pawnId != null && ranked.length > 1) {
    // Tiny deterministic tie-break.
    ranked = [
      for (final s in ranked)
        ApproachSlot(
          cell: s.cell,
          score: s.score + slotTieNoise(opts.pawnId!, s.cell),
          facingQuality: s.facingQuality,
          crowdPenalty: s.crowdPenalty,
          personalSpacePenalty: s.personalSpacePenalty,
          routeCost: s.routeCost,
          preferenceBonus: s.preferenceBonus,
          groupFitBonus: s.groupFitBonus,
          debugLabel: s.debugLabel,
        ),
    ]..sort((a, b) => a.score.compareTo(b.score));
  }
  return ranked.isEmpty ? null : ranked.first.cell;
}

/// Pick among near-equal length paths using [RoutePreference] (R17).
List<(int, int)> findPreferredPath({
  required HabitatMap map,
  required (int, int) from,
  required (int, int) to,
  bool Function(int x, int y)? allowed,
  RoutePreferenceContext? preference,
}) {
  final shortest = findPath(map: map, from: from, to: to, allowed: allowed);
  if (preference == null ||
      preference.profile == RoutePreferenceProfile.shortest) {
    return shortest;
  }
  final preferred = findPath(
    map: map,
    from: from,
    to: to,
    allowed: allowed,
    cellCost: (x, y) => RoutePreference.cellExtraCost(
      x: x,
      y: y,
      ctx: preference,
    ),
  );
  if (preferred.isEmpty) return shortest;
  if (!RoutePreference.isAcceptableDetour(
    shortestLen: shortest.length,
    candidateLen: preferred.length,
    ctx: preference,
  )) {
    return shortest;
  }
  return preferred;
}
