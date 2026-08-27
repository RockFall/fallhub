/// Soft locomotion presentation multipliers (MD 10 R5).
class LocomotorStyleInput {
  const LocomotorStyleInput({
    this.fatigue = 0,
    this.sleepiness = 0,
    this.urgency = 0,
    this.relaxed = 0,
    this.carryingItem = false,
    this.socialApproach = false,
    this.conditionWalkMultiplier = 1,
  });

  /// 0..1 physical fatigue.
  final double fatigue;

  /// 0..1 sleep pressure.
  final double sleepiness;

  /// 0..1 — draft goTo, urgent need, late appointment.
  final double urgency;

  /// 0..1 — leisure wander, post-meal.
  final double relaxed;

  final bool carryingItem;
  final bool socialApproach;

  /// Existing M7 combined condition walk multiplier.
  final double conditionWalkMultiplier;
}

class LocomotorStyleResult {
  const LocomotorStyleResult({
    required this.speedMultiplier,
    required this.cadenceMultiplier,
    required this.bobAmpMultiplier,
  });

  /// Applied to tile slide + wander step rate.
  final double speedMultiplier;

  /// Step timing feel (idle gaps between wander steps scale inversely).
  final double cadenceMultiplier;

  /// Walk bob amplitude.
  final double bobAmpMultiplier;
}

/// Compose subtle speed/cadence without caricature (R5).
abstract final class LocomotorStyle {
  /// Soft everyday band.
  static const normalMin = 0.90;
  static const normalMax = 1.08;

  /// Strong states may reach these.
  static const strongMin = 0.82;
  static const strongMax = 1.15;

  static LocomotorStyleResult resolve(LocomotorStyleInput input) {
    var speed = 1.0;
    var cadence = 1.0;
    var bob = 1.0;

    final fatigue = input.fatigue.clamp(0.0, 1.0);
    final sleep = input.sleepiness.clamp(0.0, 1.0);
    final urgency = input.urgency.clamp(0.0, 1.0);
    final relaxed = input.relaxed.clamp(0.0, 1.0);

    // Fatigue / sleepiness slow without "sick" visual — mild bob dampen.
    speed -= fatigue * 0.12;
    speed -= sleep * 0.08;
    cadence -= fatigue * 0.1;
    bob -= fatigue * 0.15 + sleep * 0.1;

    // Urgency lifts speed within strongMax; relax softens.
    speed += urgency * 0.14;
    speed -= relaxed * 0.06;
    cadence += urgency * 0.08;
    cadence -= relaxed * 0.05;
    bob += urgency * 0.05;

    if (input.carryingItem) {
      speed -= 0.06;
      cadence -= 0.04;
      bob -= 0.08;
    }
    if (input.socialApproach) {
      // Approach is slightly measured, not a sprint.
      speed = speed * 0.96 + 0.04;
      bob *= 0.92;
    }

    // Fold M7 condition walk into the same envelope.
    speed *= input.conditionWalkMultiplier.clamp(0.75, 1.2);

    final strong = fatigue > 0.55 ||
        sleep > 0.55 ||
        urgency > 0.6 ||
        input.conditionWalkMultiplier < 0.88 ||
        input.conditionWalkMultiplier > 1.05;

    final lo = strong ? strongMin : normalMin;
    final hi = strong ? strongMax : normalMax;
    speed = speed.clamp(lo, hi);
    cadence = cadence.clamp(0.85, 1.12);
    bob = bob.clamp(0.7, 1.15);

    return LocomotorStyleResult(
      speedMultiplier: speed,
      cadenceMultiplier: cadence,
      bobAmpMultiplier: bob,
    );
  }
}
