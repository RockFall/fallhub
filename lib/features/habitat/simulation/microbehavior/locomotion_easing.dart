import 'dart:math' as math;

/// Start/stop envelope for cell slides (MD 10 R6).
abstract final class LocomotionEasing {
  static const accelerateMin = 0.08;
  static const accelerateMax = 0.18;
  static const decelerateMin = 0.10;
  static const decelerateMax = 0.22;

  /// Smoothstep ease-in-out on normalized path progress [t] ∈ [0,1].
  ///
  /// Short paths (1 tile, urgent) should pass [applyEnvelope]=false and use
  /// linear [t] for responsiveness. Never overshoots destination.
  static double easeProgress(double t, {required bool applyEnvelope}) {
    final x = t.clamp(0.0, 1.0);
    if (!applyEnvelope) return x;
    return x * x * (3 - 2 * x);
  }

  /// Whether a path of [pathLengthIncludingCurrentStep] should ease.
  ///
  /// Skip for single-tile / urgent manual hops.
  static bool shouldEase({
    required int pathLengthIncludingCurrentStep,
    required bool urgent,
  }) {
    if (urgent) return false;
    return pathLengthIncludingCurrentStep >= 4;
  }

  /// Deterministic envelope durations from a unit noise (telemetry / debug).
  static (double accel, double decel) envelopeDurations(double unit) {
    final u = unit.clamp(0.0, 1.0);
    return (
      accelerateMin + (accelerateMax - accelerateMin) * u,
      decelerateMin + (decelerateMax - decelerateMin) * (1 - u),
    );
  }

  /// Asymmetric ease with a longer cruise mid-path (still monotonic).
  static double easeProgressCruise(double t, {double edge = 0.22}) {
    final x = t.clamp(0.0, 1.0);
    final e = edge.clamp(0.05, 0.4);
    if (x < e) {
      final u = x / e;
      return 0.5 * e * (1 - math.cos(math.pi * u));
    }
    if (x > 1 - e) {
      final u = (x - (1 - e)) / e;
      final base = 1 - e;
      // At u=0 → base; at u=1 → base + e = 1.
      return base + 0.5 * e * (1 - math.cos(math.pi * u));
    }
    // Linear cruise; edge values meet at `e` and `1-e`.
    final u = (x - e) / (1 - 2 * e);
    return e + (1 - 2 * e) * u;
  }
}
