import 'dart:math' as math;

/// Deterministic RNG streams for microbehaviors (MD 10 §3.2).
///
/// Prefer derived streams over ad-hoc `Random()` so the same pawn + world
/// seed reproduces attention jitter, reaction latency, and probe offsets.
abstract final class HabitatRng {
  /// Stable 32-bit mix of [parts] — not cryptographic.
  static int mix(Object a, [Object? b, Object? c, Object? d]) {
    var h = Object.hash(a, b, c, d);
    h = (h ^ (h >>> 16)) * 0x45d9f3b;
    h = (h ^ (h >>> 16)) * 0x45d9f3b;
    return h ^ (h >>> 16);
  }

  /// Stream for a named concern of a pawn (e.g. `'attention'`, `'reaction'`).
  static math.Random stream({
    required String pawnId,
    required String concern,
    int worldSeed = 0,
  }) =>
      math.Random(mix(pawnId, concern, worldSeed));

  /// Unit float in [0, 1) from a hash (no Random object).
  static double unit(Object a, [Object? b, Object? c]) {
    final h = mix(a, b, c).abs();
    return (h % 10000) / 10000.0;
  }

  /// Lerp [lo]→[hi] with deterministic unit noise.
  static double range(
    double lo,
    double hi, {
    required Object a,
    Object? b,
    Object? c,
  }) {
    if (hi <= lo) return lo;
    return lo + (hi - lo) * unit(a, b, c);
  }
}
