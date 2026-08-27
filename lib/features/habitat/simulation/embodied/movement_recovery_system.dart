import '../mirror/mirror_signal.dart';
import 'condition_engine.dart';
import 'pawn_embodied_state.dart';

/// Sedentary duration, physical fatigue, recovery (MD 08 M9).
class MovementRecoverySystem {
  MovementRecoverySystem({
    this.tickIntervalSimSeconds = 5,
    ConditionEngine? conditions,
  }) : conditions = conditions ?? ConditionEngine();

  final double tickIntervalSimSeconds;
  final ConditionEngine conditions;
  final Map<String, double> _lastTickAt = {};

  PawnEmbodiedState maybeTick({
    required PawnEmbodiedState state,
    required double simSeconds,
    required DateTime observedAt,
    required bool isMoving,
    required bool isSedentary,
    required bool isSleeping,
    double activityPhysicalLoad = 0,
  }) {
    final last = _lastTickAt[state.pawnId] ?? simSeconds;
    if (simSeconds - last < tickIntervalSimSeconds && last != simSeconds) {
      return state;
    }
    final dt = (simSeconds - last).clamp(0.0, 60.0);
    _lastTickAt[state.pawnId] = simSeconds;
    if (dt <= 0) return state;

    var sedentary = state.movement.sedentarySeconds;
    var fatigue = state.movement.physicalFatigue;
    var load = state.movement.recentMovementLoad;

    if (isSedentary && !isMoving && !isSleeping) {
      sedentary += dt;
    } else if (isMoving || isSleeping) {
      sedentary = (sedentary - dt * 2).clamp(0.0, 1e9);
    }

    if (isMoving || activityPhysicalLoad > 0) {
      final add = (0.02 * (dt / 5) + activityPhysicalLoad * 0.08);
      fatigue = (fatigue + add).clamp(0.0, 1.0);
      load = (load + add * 2).clamp(0.0, 1.0);
    } else if (isSleeping || isSedentary) {
      fatigue = (fatigue - 0.04 * (dt / 5) * (isSleeping ? 2.5 : 1)).clamp(0.0, 1.0);
      load = (load - 0.05 * (dt / 5)).clamp(0.0, 1.0);
    } else {
      fatigue = (fatigue - 0.015 * (dt / 5)).clamp(0.0, 1.0);
      load = (load - 0.03 * (dt / 5)).clamp(0.0, 1.0);
    }

    var next = state.copyWith(
      movement: state.movement.copyWith(
        sedentarySeconds: sedentary,
        physicalFatigue: fatigue,
        recentMovementLoad: load,
      ),
    );

    // Movement need rises with sedentary time.
    final needs = Map<NeedKind, NeedReading>.from(next.needs);
    final moveNeed = needs[NeedKind.movement];
    if (moveNeed != null && sedentary > 120) {
      final bump = ((sedentary - 120) / 600).clamp(0.0, 0.4);
      needs[NeedKind.movement] = moveNeed.copyWith(
        pressure: (moveNeed.pressure + bump * 0.05).clamp(0.0, 1.0),
        observedAt: observedAt,
        source: MirrorSignalSource.systemDerived,
      );
      next = next.copyWith(needs: needs);
    }

    if (fatigue > 0.55) {
      next = conditions.upsert(
        next,
        conditions.create(
          kind: PawnConditionKind.physicallyTired,
          intensity: fatigue,
          atSimSeconds: simSeconds,
          durationSeconds: 600,
        ),
      );
    }
    if (sedentary > 240 && (moveNeed?.pressure ?? 0) > 0.55) {
      next = conditions.upsert(
        next,
        conditions.create(
          kind: PawnConditionKind.restless,
          intensity: 0.5,
          atSimSeconds: simSeconds,
          durationSeconds: 400,
        ),
      );
    }

    return next;
  }
}
