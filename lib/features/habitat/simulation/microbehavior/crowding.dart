import '../identity/identity.dart';

/// Local crowding score for idle / solitude / seat choice (MD 10 R19).
class LocalCrowdingScore {
  const LocalCrowdingScore({
    required this.cell,
    required this.score,
    required this.pawnCount,
    this.radius = 3,
  });

  final (int, int) cell;
  final double score;
  final int pawnCount;
  final int radius;
}

abstract final class CrowdingAwareness {
  static LocalCrowdingScore scoreAt({
    required (int, int) cell,
    required List<(int, int)> pawnCells,
    int radius = 3,
  }) {
    var count = 0;
    var weighted = 0.0;
    for (final p in pawnCells) {
      final d = (p.$1 - cell.$1).abs() + (p.$2 - cell.$2).abs();
      if (d == 0) continue; // self excluded by caller usually
      if (d > radius) continue;
      count++;
      weighted += 1.0 / d;
    }
    return LocalCrowdingScore(
      cell: cell,
      score: weighted,
      pawnCount: count,
      radius: radius,
    );
  }

  /// Whether idle pawn should relocate away from crowd.
  static bool shouldRelocate({
    required LocalCrowdingScore local,
    required SocialStyle socialStyle,
    double solitudePressure = 0,
    double socialTolerance = 0.5,
    bool activityCommitted = false,
  }) {
    if (activityCommitted) return false;
    var threshold = switch (socialStyle) {
      SocialStyle.reserved => 1.1,
      SocialStyle.balanced => 1.8,
      SocialStyle.outgoing => 2.6,
    };
    threshold *= (0.7 + socialTolerance.clamp(0.0, 1.0) * 0.8);
    // High solitude need → relocate sooner.
    threshold -= solitudePressure.clamp(0.0, 1.0) * 0.7;
    return local.score >= threshold && local.pawnCount >= 2;
  }

  /// Pick a quieter nearby walkable cell.
  static (int, int)? pickQuieterCell({
    required (int, int) from,
    required List<(int, int)> pawnCells,
    required bool Function(int x, int y) isWalkable,
    int searchRadius = 5,
  }) {
    final here = scoreAt(cell: from, pawnCells: pawnCells);
    (int, int)? best;
    var bestScore = here.score;
    for (var dy = -searchRadius; dy <= searchRadius; dy++) {
      for (var dx = -searchRadius; dx <= searchRadius; dx++) {
        if (dx == 0 && dy == 0) continue;
        final x = from.$1 + dx;
        final y = from.$2 + dy;
        if (!isWalkable(x, y)) continue;
        final s = scoreAt(cell: (x, y), pawnCells: pawnCells);
        if (s.score < bestScore - 0.35) {
          bestScore = s.score;
          best = (x, y);
        }
      }
    }
    return best;
  }
}
