/// Route preference when alternatives have similar cost (MD 10 R17).
enum RoutePreferenceProfile {
  shortest,
  quiet,
  scenic,
  social,
  avoidCrowd,
}

class RoutePreferenceContext {
  const RoutePreferenceContext({
    required this.profile,
    this.outdoorCells = const {},
    this.scenicCells = const {},
    this.quietCells = const {},
    this.socialCells = const {},
    this.crowdCostAt,
    this.maxDetourRatio = 1.35,
    this.maxExtraTiles = 6,
  });

  final RoutePreferenceProfile profile;
  final Set<(int, int)> outdoorCells;
  final Set<(int, int)> scenicCells;
  final Set<(int, int)> quietCells;
  final Set<(int, int)> socialCells;
  final double Function(int x, int y)? crowdCostAt;

  /// Never take a path longer than shortest * ratio or + maxExtraTiles.
  final double maxDetourRatio;
  final int maxExtraTiles;
}

/// Soft cell cost for A* (additive to geometric 1).
abstract final class RoutePreference {
  static double cellExtraCost({
    required int x,
    required int y,
    required RoutePreferenceContext ctx,
  }) {
    final cell = (x, y);
    switch (ctx.profile) {
      case RoutePreferenceProfile.shortest:
        return 0;
      case RoutePreferenceProfile.quiet:
        if (ctx.quietCells.contains(cell)) return -0.25;
        return (ctx.crowdCostAt?.call(x, y) ?? 0) * 0.4;
      case RoutePreferenceProfile.scenic:
        if (ctx.scenicCells.contains(cell) ||
            ctx.outdoorCells.contains(cell)) {
          return -0.35;
        }
        return 0.05;
      case RoutePreferenceProfile.social:
        if (ctx.socialCells.contains(cell)) return -0.3;
        return 0;
      case RoutePreferenceProfile.avoidCrowd:
        return (ctx.crowdCostAt?.call(x, y) ?? 0) * 0.85;
    }
  }

  /// Whether a candidate path length is an acceptable detour vs shortest.
  static bool isAcceptableDetour({
    required int shortestLen,
    required int candidateLen,
    required RoutePreferenceContext ctx,
  }) {
    if (candidateLen <= shortestLen) return true;
    final extra = candidateLen - shortestLen;
    if (extra > ctx.maxExtraTiles) return false;
    if (shortestLen == 0) return extra <= ctx.maxExtraTiles;
    return candidateLen <= shortestLen * ctx.maxDetourRatio;
  }

  static String debugLabel(RoutePreferenceProfile p) => p.name;
}
