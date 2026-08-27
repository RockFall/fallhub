import 'dart:math' as math;

import '../identity/identity.dart';
import 'anticipation_profile.dart';
import 'arrival_choreography.dart';
import 'attention_target.dart';
import 'behavior_timing_offsets.dart';
import 'desired_facing.dart';
import 'habitat_rng.dart';
import 'locomotor_style.dart';
import 'micro_idle.dart';
import 'posture_transition.dart';
import 'reaction_latency.dart';

/// Per-pawn Block A state bag — simulation decides, Flame presents.
class PawnMicrobehavior {
  PawnMicrobehavior({
    required this.pawnId,
    this.worldSeed = 0,
    bool reducedMotion = false,
  })  : attention = AttentionController(),
        posture = PostureController(),
        arrival = ArrivalChoreographer(),
        reactions = ReactionScheduler(),
        microIdle = MicroIdleScheduler(
          pawnId: pawnId,
          worldSeed: worldSeed,
          reducedMotion: reducedMotion,
          initialProbeOffset: 0,
        ),
        offsets = BehaviorTimingOffsets.fromSeed(pawnId, worldSeed: worldSeed) {
    desync = BehaviorDesyncClock(offsets: offsets);
    microIdle.armFirstProbe(offsets.microIdleCadence);
  }

  final String pawnId;
  final int worldSeed;

  final AttentionController attention;
  final PostureController posture;
  final ArrivalChoreographer arrival;
  final ReactionScheduler reactions;
  final MicroIdleScheduler microIdle;
  final BehaviorTimingOffsets offsets;
  late final BehaviorDesyncClock desync;

  LocomotorStyleResult locomotor = const LocomotorStyleResult(
    speedMultiplier: 1,
    cadenceMultiplier: 1,
    bobAmpMultiplier: 1,
  );

  /// When true, current tile slides skip easing (manual 1-tile / urgent).
  bool urgentLocomotion = false;

  /// Path length at last step start (for R6 easing gate).
  int lastPathLengthHint = 0;

  BehaviorProfile? profile;

  void reset() {
    attention.clear();
    posture.reset();
    arrival.reset();
    reactions.clear();
    microIdle.reset();
    urgentLocomotion = false;
    lastPathLengthHint = 0;
    locomotor = const LocomotorStyleResult(
      speedMultiplier: 1,
      cadenceMultiplier: 1,
      bobAmpMultiplier: 1,
    );
  }

  void updateLocomotor(LocomotorStyleInput input) {
    locomotor = LocomotorStyle.resolve(input);
  }

  double reactionDelay(ReactionLatencyContext ctx) =>
      ReactionLatency.compute(ctx);

  DesiredFacingResult resolveArrivalFacing(FacingSettleContext ctx) =>
      DesiredFacingResolver.resolve(ctx);

  AnticipationProfile anticipationFor(String affordanceId) =>
      AnticipationCatalog.forAffordance(affordanceId);

  /// Presentation offset from active micro-idle (pixels scaled by caller).
  double microIdlePoseOffsetX(double now, double tileSize) {
    final a = microIdle.active;
    if (a == null) return 0;
    final p = a.progress(now);
    final wave = (p < 0.5 ? p * 2 : (1 - p) * 2);
    return a.facingBiasSign *
        wave *
        a.presentation.poseAmp *
        tileSize *
        0.06;
  }

  /// Soft squash during posture transitions (1 = normal).
  double postureSquash(double now) {
    final s = posture.state;
    if (!s.isTransient) return 1;
    final prog = PostureTimings.visualProgress(s.phase, now, s.phaseEndsAt);
    return switch (s.phase) {
      PosturePhase.preparingToSit || PosturePhase.preparingToLie =>
        1.0 - 0.06 * prog,
      PosturePhase.preparingToStand || PosturePhase.preparingToRise =>
        1.0 - 0.04 * (1 - prog),
      _ => 1.0,
    };
  }

  String get debugSummary {
    final att = attention.debugLabel;
    final arr = arrival.state.phase.name;
    final pos = posture.state.phase.name;
    final idle = microIdle.active?.presentation.kind.name ?? '—';
    return 'att=$att arr=$arr pos=$pos idle=$idle '
        'spd=${locomotor.speedMultiplier.toStringAsFixed(2)}';
  }
}

/// Seeded stream for a named concern of this pawn.
math.Random pawnStream(PawnMicrobehavior m, String concern) =>
    HabitatRng.stream(
      pawnId: m.pawnId,
      concern: concern,
      worldSeed: m.worldSeed,
    );
