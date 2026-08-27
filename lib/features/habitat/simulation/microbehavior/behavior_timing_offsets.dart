import 'habitat_rng.dart';

/// Per-pawn phase offsets so probes don't share a global metronome (MD 10 R9).
///
/// Do **not** apply these to semantically simultaneous events (confirmed
/// collective activity start, shared ritual beat, etc.).
class BehaviorTimingOffsets {
  const BehaviorTimingOffsets({
    required this.pawnId,
    required this.idleProbe,
    required this.microIdleCadence,
    required this.ambientReactionProbe,
    required this.socialProbe,
    required this.needReevaluation,
  });

  final String pawnId;

  /// Added to idle autonomy / clean-joy probe timer (seconds).
  final double idleProbe;

  /// Phase shift for micro-idle scheduler arming.
  final double microIdleCadence;

  /// Ambient event perception probe offset.
  final double ambientReactionProbe;

  /// Soft social join / encounter candidate refresh offset.
  final double socialProbe;

  /// Need reevaluation / embodied autonomy offset.
  final double needReevaluation;

  factory BehaviorTimingOffsets.fromSeed(
    String pawnId, {
    int worldSeed = 0,
  }) {
    double band(String concern, double lo, double hi) => HabitatRng.range(
          lo,
          hi,
          a: pawnId,
          b: concern,
          c: worldSeed,
        );

    return BehaviorTimingOffsets(
      pawnId: pawnId,
      idleProbe: band('idleProbe', 0.0, 2.8),
      microIdleCadence: band('microIdleCadence', 0.0, 3.5),
      ambientReactionProbe: band('ambientReaction', 0.0, 1.6),
      socialProbe: band('socialProbe', 0.0, 2.2),
      needReevaluation: band('needReeval', 0.0, 2.0),
    );
  }

  /// Effective period with phase: first fire after [offset] then every [period].
  double nextFireAt({
    required double now,
    required double period,
    required double offset,
    required double lastFireAt,
  }) {
    if (lastFireAt < 0) {
      return now + offset;
    }
    return lastFireAt + period;
  }
}

/// Tracks per-pawn probe clocks using [BehaviorTimingOffsets].
class BehaviorDesyncClock {
  BehaviorDesyncClock({
    required this.offsets,
  })  : _idleDueAt = offsets.idleProbe,
        _needDueAt = offsets.needReevaluation,
        _ambientDueAt = offsets.ambientReactionProbe,
        _socialDueAt = offsets.socialProbe;

  final BehaviorTimingOffsets offsets;

  double _idleDueAt;
  double _needDueAt;
  double _ambientDueAt;
  double _socialDueAt;

  bool consumeIdleProbe(double now, {double period = 7}) {
    if (now < _idleDueAt) return false;
    _idleDueAt = now + period;
    return true;
  }

  bool consumeNeedReeval(double now, {double period = 4.5}) {
    if (now < _needDueAt) return false;
    _needDueAt = now + period;
    return true;
  }

  bool consumeAmbientProbe(double now, {double period = 5}) {
    if (now < _ambientDueAt) return false;
    _ambientDueAt = now + period;
    return true;
  }

  bool consumeSocialProbe(double now, {double period = 3.5}) {
    if (now < _socialDueAt) return false;
    _socialDueAt = now + period;
    return true;
  }

  /// Debug: seconds until each probe.
  Map<String, double> debugDueIn(double now) => {
        'idle': (_idleDueAt - now),
        'need': (_needDueAt - now),
        'ambient': (_ambientDueAt - now),
        'social': (_socialDueAt - now),
      };
}
