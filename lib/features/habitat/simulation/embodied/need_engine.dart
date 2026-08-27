import '../mirror/mirror_signal.dart';
import 'pawn_embodied_state.dart';

/// Gradual need pressure evolution (MD 08 M5). Ticks on sim cadence, not frames.
class NeedEngine {
  NeedEngine({this.tickIntervalSimSeconds = 10});

  final double tickIntervalSimSeconds;
  final Map<String, double> _lastTickAt = {};

  static const Map<NeedKind, double> baselineRisePerHour = {
    NeedKind.sleep: 0.045,
    NeedKind.food: 0.04,
    NeedKind.movement: 0.035,
    NeedKind.rest: 0.025,
    NeedKind.socialConnection: 0.03,
    NeedKind.solitude: 0.02,
    NeedKind.recreation: 0.028,
    NeedKind.stimulation: 0.022,
    NeedKind.creativeExpression: 0.02,
    NeedKind.comfort: 0.015,
  };

  PawnEmbodiedState maybeTick({
    required PawnEmbodiedState state,
    required double simSeconds,
    required DateTime observedAt,
    bool isSedentary = false,
    bool isMoving = false,
    bool isSleeping = false,
    double comfortStress = 0,
    double socialIntensity = 0,
  }) {
    final last = _lastTickAt[state.pawnId] ?? 0;
    if (simSeconds - last < tickIntervalSimSeconds) return state;
    final dtHours = (simSeconds - last) / 3600.0;
    _lastTickAt[state.pawnId] = simSeconds;
    if (dtHours <= 0) return state;

    final next = Map<NeedKind, NeedReading>.from(state.needs);
    for (final kind in NeedKind.values) {
      final cur = next[kind] ??
          NeedReading(
            kind: kind,
            pressure: 0.2,
            source: MirrorSignalSource.simulated,
          );
      var rise = (baselineRisePerHour[kind] ?? 0.02) * dtHours;
      if (isSleeping && (kind == NeedKind.sleep || kind == NeedKind.rest)) {
        rise = -0.55 * dtHours; // satisfied while sleeping
      }
      if (isSedentary && kind == NeedKind.movement) {
        rise += 0.08 * dtHours;
      }
      if (isMoving && kind == NeedKind.movement) {
        rise -= 0.12 * dtHours;
      }
      if (isMoving && kind == NeedKind.rest) {
        rise += 0.03 * dtHours;
      }
      if (socialIntensity > 0.2 && kind == NeedKind.socialConnection) {
        rise -= 0.25 * socialIntensity * dtHours;
      }
      if (socialIntensity > 0.25 && kind == NeedKind.solitude) {
        rise += 0.15 * socialIntensity * dtHours;
      }
      if (comfortStress > 0 && kind == NeedKind.comfort) {
        rise += 0.1 * comfortStress * dtHours;
      }

      final pressure = (cur.pressure + rise).clamp(0.0, 1.0);
      final trend = rise > 0.002
          ? EmbodiedTrend.rising
          : rise < -0.002
              ? EmbodiedTrend.falling
              : EmbodiedTrend.steady;
      next[kind] = cur.copyWith(
        pressure: pressure,
        trend: trend,
        trendPerSimHour: rise / dtHours,
        observedAt: observedAt,
        source: MirrorSignalSource.simulated,
      );
    }
    return state.copyWith(needs: next);
  }

  /// Coarse background advance without requiring intermediate ticks (M48).
  PawnEmbodiedState advance({
    required PawnEmbodiedState state,
    required double deltaSimTime,
    required DateTime observedAt,
    bool isSleeping = false,
  }) {
    if (deltaSimTime <= 0) return state;
    final last = _lastTickAt[state.pawnId] ?? 0;
    final target = last + deltaSimTime;
    // Bypass cadence gate so large gaps integrate in one step.
    _lastTickAt[state.pawnId] = target - tickIntervalSimSeconds - 0.01;
    return maybeTick(
      state: state,
      simSeconds: target,
      observedAt: observedAt,
      isSleeping: isSleeping,
    );
  }

  /// Apply satisfaction deltas from completing an affordance.
  PawnEmbodiedState applySatisfaction({
    required PawnEmbodiedState state,
    required Map<NeedKind, double> satisfies,
    required DateTime observedAt,
  }) {
    if (satisfies.isEmpty) return state;
    final next = Map<NeedKind, NeedReading>.from(state.needs);
    for (final e in satisfies.entries) {
      final cur = next[e.key];
      if (cur == null) continue;
      next[e.key] = cur.copyWith(
        pressure: (cur.pressure - e.value).clamp(0.0, 1.0),
        trend: e.value > 0 ? EmbodiedTrend.falling : EmbodiedTrend.rising,
        observedAt: observedAt,
      );
    }
    return state.copyWith(needs: next);
  }
}
