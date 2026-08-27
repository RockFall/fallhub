/// Rank free surface slots for placement (MD 10 R22).
class SurfaceSlotCandidate {
  const SurfaceSlotCandidate({
    required this.containerId,
    required this.slotId,
    required this.score,
  });

  final String containerId;
  final String slotId;
  final double score;
}

class SurfacePlacementContext {
  const SurfacePlacementContext({
    required this.containerId,
    required this.freeSlotIds,
    this.occupiedCount = 0,
    this.capacity = 1,
    this.nearUser = false,
    this.sameActivityCluster = false,
    this.occludesImportant = false,
  });

  final String containerId;
  final List<String> freeSlotIds;
  final int occupiedCount;
  final int capacity;
  final bool nearUser;
  final bool sameActivityCluster;
  final bool occludesImportant;
}

abstract final class SurfacePlacementRanker {
  static List<SurfaceSlotCandidate> rank(SurfacePlacementContext ctx) {
    final out = <SurfaceSlotCandidate>[];
    for (var i = 0; i < ctx.freeSlotIds.length; i++) {
      final slot = ctx.freeSlotIds[i];
      var score = i * 0.05; // slight spread
      score += ctx.occupiedCount * 0.35;
      if (ctx.nearUser) score -= 0.4;
      if (ctx.sameActivityCluster) score -= 0.25;
      if (ctx.occludesImportant) score += 1.2;
      // Prefer not overcrowding.
      final fill = ctx.capacity <= 0
          ? 1.0
          : ctx.occupiedCount / ctx.capacity;
      score += fill * 0.5;
      out.add(
        SurfaceSlotCandidate(
          containerId: ctx.containerId,
          slotId: slot,
          score: score,
        ),
      );
    }
    out.sort((a, b) => a.score.compareTo(b.score));
    return out;
  }

  static SurfaceSlotCandidate? best(SurfacePlacementContext ctx) {
    final list = rank(ctx);
    return list.isEmpty ? null : list.first;
  }
}
