import '../mirror/mirror_signal.dart';
import 'pawn_embodied_state.dart';

/// Derives capacities from needs / circadian / movement / conditions (M6).
class CapacityEngine {
  CapacityEngine({this.tickIntervalSimSeconds = 10});

  final double tickIntervalSimSeconds;
  final Map<String, double> _lastTickAt = {};

  PawnEmbodiedState maybeTick({
    required PawnEmbodiedState state,
    required double simSeconds,
    required DateTime observedAt,
  }) {
    final last = _lastTickAt[state.pawnId] ?? 0;
    if (simSeconds - last < tickIntervalSimSeconds) return state;
    _lastTickAt[state.pawnId] = simSeconds;
    return recompute(state, observedAt: observedAt);
  }

  PawnEmbodiedState recompute(
    PawnEmbodiedState state, {
    required DateTime observedAt,
  }) {
    final sleep = state.need(NeedKind.sleep)?.pressure ?? 0.3;
    final rest = state.need(NeedKind.rest)?.pressure ?? 0.2;
    final move = state.need(NeedKind.movement)?.pressure ?? 0.2;
    final social = state.need(NeedKind.socialConnection)?.pressure ?? 0.3;
    final solitude = state.need(NeedKind.solitude)?.pressure ?? 0.15;
    final creative = state.need(NeedKind.creativeExpression)?.pressure ?? 0.2;
    final alert = state.circadian.alertness;
    final inertia = state.circadian.sleepInertia;
    final fatigue = state.movement.physicalFatigue;

    double clamp01(double v) => v.clamp(0.0, 1.0);

    CapacityReading cap(
      CapacityKind k,
      double level,
      List<String> from,
    ) =>
        CapacityReading(
          kind: k,
          level: clamp01(level),
          source: MirrorSignalSource.systemDerived,
          derivedFrom: from,
          observedAt: observedAt,
        );

    final energy = cap(
      CapacityKind.energy,
      0.95 - sleep * 0.55 - rest * 0.2 - inertia * 0.35 - fatigue * 0.15,
      [
        'need.sleep=${sleep.toStringAsFixed(2)}',
        'need.rest=${rest.toStringAsFixed(2)}',
        'circadian.sleepInertia=${inertia.toStringAsFixed(2)}',
        'movement.fatigue=${fatigue.toStringAsFixed(2)}',
      ],
    );
    final focus = cap(
      CapacityKind.focus,
      energy.level * 0.55 + alert * 0.45 - sleep * 0.15,
      [
        'capacity.energy=${energy.level.toStringAsFixed(2)}',
        'circadian.alertness=${alert.toStringAsFixed(2)}',
      ],
    );
    final physical = cap(
      CapacityKind.physicalReadiness,
      0.9 - fatigue * 0.6 - move * 0.1 + (1 - sleep) * 0.05,
      [
        'movement.fatigue=${fatigue.toStringAsFixed(2)}',
        'need.movement=${move.toStringAsFixed(2)}',
      ],
    );
    final socialTol = cap(
      CapacityKind.socialTolerance,
      0.85 - solitude * 0.35 - (social > 0.7 ? 0.15 : 0) - fatigue * 0.1,
      [
        'need.solitude=${solitude.toStringAsFixed(2)}',
        'need.socialConnection=${social.toStringAsFixed(2)}',
      ],
    );
    final creativeCap = cap(
      CapacityKind.creativeCapacity,
      focus.level * 0.5 + (1 - creative) * 0.15 + alert * 0.25 - inertia * 0.2,
      [
        'capacity.focus=${focus.level.toStringAsFixed(2)}',
        'need.creativeExpression=${creative.toStringAsFixed(2)}',
      ],
    );
    final decision = cap(
      CapacityKind.decisionCapacity,
      focus.level * 0.6 + energy.level * 0.3 - sleep * 0.2,
      [
        'capacity.focus=${focus.level.toStringAsFixed(2)}',
        'capacity.energy=${energy.level.toStringAsFixed(2)}',
      ],
    );
    final recovery = cap(
      CapacityKind.recovery,
      0.7 + (1 - fatigue) * 0.2 - sleep * 0.15,
      [
        'movement.fatigue=${fatigue.toStringAsFixed(2)}',
        'need.sleep=${sleep.toStringAsFixed(2)}',
      ],
    );

    return state.copyWith(
      capacities: {
        CapacityKind.energy: energy,
        CapacityKind.focus: focus,
        CapacityKind.physicalReadiness: physical,
        CapacityKind.socialTolerance: socialTol,
        CapacityKind.creativeCapacity: creativeCap,
        CapacityKind.decisionCapacity: decision,
        CapacityKind.recovery: recovery,
      },
    );
  }
}
