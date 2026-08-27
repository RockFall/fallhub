import 'habitat_rng.dart';
import 'micro_facing.dart';

/// A walkable cell adjacent to a prop footprint (MD 10 R10).
class ApproachSlot {
  const ApproachSlot({
    required this.cell,
    required this.score,
    this.facingQuality = 0,
    this.crowdPenalty = 0,
    this.personalSpacePenalty = 0,
    this.routeCost = 0,
    this.preferenceBonus = 0,
    this.groupFitBonus = 0,
    this.debugLabel = '',
  });

  final (int, int) cell;
  final double score;
  final double facingQuality;
  final double crowdPenalty;
  final double personalSpacePenalty;
  final double routeCost;
  final double preferenceBonus;
  final double groupFitBonus;
  final String debugLabel;
}

/// Context for ranking approach slots around a prop.
class ApproachSlotContext {
  const ApproachSlotContext({
    required this.from,
    required this.propOrigin,
    required this.propSize,
    this.propFacing,
    this.lookAtCell,
    this.occupiedCells = const {},
    this.pawnCells = const [],
    this.personalSpaceCostAt,
    this.routeLengthTo,
    this.preferFacing,
    this.activityGroupCells = const [],
    this.preferenceBias = 0,
  });

  final (int, int) from;
  final (int, int) propOrigin;
  final (int, int) propSize;

  /// Seat/prop forward direction (for facing quality).
  final MicroFacing? propFacing;

  /// Semantic look target (TV, table center) — better LOS from slot = higher.
  final (int, int)? lookAtCell;

  /// Cells already reserved / occupied by other users.
  final Set<(int, int)> occupiedCells;

  /// Other pawn positions for crowding.
  final List<(int, int)> pawnCells;

  /// Optional soft personal-space cost at a cell (R12).
  final double Function(int x, int y)? personalSpaceCostAt;

  /// Optional path length from [from] to candidate (else Manhattan).
  final int Function(int x, int y)? routeLengthTo;

  /// Preferred approach facing for the job (optional).
  final MicroFacing? preferFacing;

  /// Cells of activity partners — prefer nearby for group fit.
  final List<(int, int)> activityGroupCells;

  /// Soft preference bonus applied equally (personality / habit).
  final double preferenceBias;
}

/// Rank approach slots — not just nearest (R10).
abstract final class ApproachSlotRanker {
  /// Enumerate border walkable candidates (same ring as classic approachCell).
  static List<(int, int)> candidateCells({
    required (int, int) propOrigin,
    required (int, int) propSize,
    required bool Function(int x, int y) isWalkable,
  }) {
    final (ox, oy) = propOrigin;
    final (w, h) = propSize;
    final out = <(int, int)>[];
    for (var y = oy - 1; y <= oy + h; y++) {
      for (var x = ox - 1; x <= ox + w; x++) {
        final onBorder =
            x == ox - 1 || x == ox + w || y == oy - 1 || y == oy + h;
        if (!onBorder) continue;
        if (isWalkable(x, y)) out.add((x, y));
      }
    }
    return out;
  }

  static List<ApproachSlot> rank({
    required ApproachSlotContext ctx,
    required bool Function(int x, int y) isWalkable,
  }) {
    final cells = candidateCells(
      propOrigin: ctx.propOrigin,
      propSize: ctx.propSize,
      isWalkable: isWalkable,
    );
    final scored = <ApproachSlot>[];
    for (final cell in cells) {
      if (ctx.occupiedCells.contains(cell)) continue;

      final dist = ((cell.$1 - ctx.from.$1).abs() +
              (cell.$2 - ctx.from.$2).abs())
          .toDouble();
      final route = (ctx.routeLengthTo?.call(cell.$1, cell.$2) ?? dist.toInt())
          .toDouble();

      final facingQ = _facingQuality(cell, ctx);
      final crowd = _crowdPenalty(cell, ctx.pawnCells);
      final personal =
          ctx.personalSpaceCostAt?.call(cell.$1, cell.$2) ?? 0.0;
      final groupFit = _groupFit(cell, ctx.activityGroupCells);
      final pref = ctx.preferenceBias;

      // Lower is better after invert facing/group into score.
      // score = distance + route + penalties - bonuses
      final score = dist * 0.55 +
          route * 0.35 +
          crowd * 1.4 +
          personal * 1.1 -
          facingQ * 2.2 -
          groupFit * 1.0 -
          pref;

      scored.add(
        ApproachSlot(
          cell: cell,
          score: score,
          facingQuality: facingQ,
          crowdPenalty: crowd,
          personalSpacePenalty: personal,
          routeCost: route,
          preferenceBonus: pref,
          groupFitBonus: groupFit,
          debugLabel:
              'd=${dist.toStringAsFixed(0)} f=${facingQ.toStringAsFixed(2)} '
              'c=${crowd.toStringAsFixed(2)}',
        ),
      );
    }
    scored.sort((a, b) => a.score.compareTo(b.score));
    return scored;
  }

  static (int, int)? best({
    required ApproachSlotContext ctx,
    required bool Function(int x, int y) isWalkable,
  }) {
    final list = rank(ctx: ctx, isWalkable: isWalkable);
    return list.isEmpty ? null : list.first.cell;
  }

  static double _facingQuality((int, int) cell, ApproachSlotContext ctx) {
    final look = ctx.lookAtCell;
    if (look != null) {
      // Prefer slots that face the look target (delta from slot → look).
      final dx = look.$1 - cell.$1;
      final dy = look.$2 - cell.$2;
      if (dx == 0 && dy == 0) return 0.2;
      final toward = microFacingFromDelta(dx, dy);
      // Soft LOS: closer axial alignment scores higher.
      final axial = dx.abs() == 0 || dy.abs() == 0 ? 0.35 : 0.1;
      var q = axial + 0.4;
      if (ctx.propFacing != null && toward == ctx.propFacing) q += 0.45;
      if (ctx.preferFacing != null && toward == ctx.preferFacing) q += 0.25;
      // Distance to look target — mid distance ok for TV.
      final d = dx.abs() + dy.abs();
      if (d >= 1 && d <= 4) q += 0.2;
      return q.clamp(0.0, 1.5);
    }
    if (ctx.propFacing != null) {
      // Prefer standing on the "front" side of the prop.
      final (ox, oy) = ctx.propOrigin;
      final (w, h) = ctx.propSize;
      final cx = ox + (w - 1) / 2.0;
      final cy = oy + (h - 1) / 2.0;
      final dx = (cell.$1 - cx).round();
      final dy = (cell.$2 - cy).round();
      final fromCenter = microFacingFromDelta(dx, dy);
      return fromCenter == ctx.propFacing ? 0.85 : 0.25;
    }
    return 0.3;
  }

  static double _crowdPenalty((int, int) cell, List<(int, int)> pawns) {
    var p = 0.0;
    for (final o in pawns) {
      final d = (o.$1 - cell.$1).abs() + (o.$2 - cell.$2).abs();
      if (d == 0) p += 3.0;
      else if (d == 1) p += 1.2;
      else if (d == 2) p += 0.35;
    }
    return p;
  }

  static double _groupFit((int, int) cell, List<(int, int)> group) {
    if (group.isEmpty) return 0;
    var best = 99.0;
    for (final g in group) {
      final d = ((g.$1 - cell.$1).abs() + (g.$2 - cell.$2).abs()).toDouble();
      if (d < best) best = d;
    }
    if (best <= 2) return 0.8;
    if (best <= 4) return 0.35;
    return 0;
  }
}

/// Deterministic tie-break noise so equal scores don't always pick the same cell.
double slotTieNoise(String pawnId, (int, int) cell) =>
    HabitatRng.unit(pawnId, 'slot', Object.hash(cell.$1, cell.$2)) * 0.05;
