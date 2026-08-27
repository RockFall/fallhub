import '../identity/identity.dart';
import 'habitat_rng.dart';

/// Short, non-activity body beats while idle (MD 10 R3).
enum MicroIdleKind {
  weightShift,
  lookLeftRight,
  briefStretch,
  scratchHead,
  checkObject,
  smallSighPose,
  footTap,
  adjustSeat,
  lookAtWindow,
}

/// Presentation hints for a micro-idle — renderer maps to offset/facing/time.
class MicroIdlePresentation {
  const MicroIdlePresentation({
    required this.kind,
    required this.durationSeconds,
    this.poseAmp = 1,
    this.affectsFacing = false,
    this.highMotion = false,
  });

  final MicroIdleKind kind;
  final double durationSeconds;

  /// Scales poseOffsetX / squash intensity.
  final double poseAmp;

  /// When true, renderer may briefly glance left/right.
  final bool affectsFacing;

  /// Gated by reducedMotion preference.
  final bool highMotion;
}

abstract final class MicroIdleLibrary {
  static MicroIdlePresentation presentation(MicroIdleKind kind) =>
      switch (kind) {
        MicroIdleKind.weightShift => const MicroIdlePresentation(
            kind: MicroIdleKind.weightShift,
            durationSeconds: 0.55,
            poseAmp: 0.7,
          ),
        MicroIdleKind.lookLeftRight => const MicroIdlePresentation(
            kind: MicroIdleKind.lookLeftRight,
            durationSeconds: 0.9,
            poseAmp: 0.35,
            affectsFacing: true,
          ),
        MicroIdleKind.briefStretch => const MicroIdlePresentation(
            kind: MicroIdleKind.briefStretch,
            durationSeconds: 1.1,
            poseAmp: 0.5,
            highMotion: true,
          ),
        MicroIdleKind.scratchHead => const MicroIdlePresentation(
            kind: MicroIdleKind.scratchHead,
            durationSeconds: 0.7,
            poseAmp: 0.4,
            highMotion: true,
          ),
        MicroIdleKind.checkObject => const MicroIdlePresentation(
            kind: MicroIdleKind.checkObject,
            durationSeconds: 0.85,
            poseAmp: 0.45,
            affectsFacing: true,
          ),
        MicroIdleKind.smallSighPose => const MicroIdlePresentation(
            kind: MicroIdleKind.smallSighPose,
            durationSeconds: 0.65,
            poseAmp: 0.25,
          ),
        MicroIdleKind.footTap => const MicroIdlePresentation(
            kind: MicroIdleKind.footTap,
            durationSeconds: 0.8,
            poseAmp: 0.55,
            highMotion: true,
          ),
        MicroIdleKind.adjustSeat => const MicroIdlePresentation(
            kind: MicroIdleKind.adjustSeat,
            durationSeconds: 0.6,
            poseAmp: 0.6,
          ),
        MicroIdleKind.lookAtWindow => const MicroIdlePresentation(
            kind: MicroIdleKind.lookAtWindow,
            durationSeconds: 1.2,
            poseAmp: 0.3,
            affectsFacing: true,
          ),
      };

  static const standingPool = <MicroIdleKind>[
    MicroIdleKind.weightShift,
    MicroIdleKind.lookLeftRight,
    MicroIdleKind.briefStretch,
    MicroIdleKind.scratchHead,
    MicroIdleKind.checkObject,
    MicroIdleKind.smallSighPose,
    MicroIdleKind.footTap,
    MicroIdleKind.lookAtWindow,
  ];

  static const seatedPool = <MicroIdleKind>[
    MicroIdleKind.adjustSeat,
    MicroIdleKind.lookLeftRight,
    MicroIdleKind.smallSighPose,
    MicroIdleKind.checkObject,
    MicroIdleKind.lookAtWindow,
  ];
}

/// Active micro-idle instance (at most one per pawn).
class ActiveMicroIdle {
  ActiveMicroIdle({
    required this.presentation,
    required this.startedAt,
    required this.facingBiasSign,
  });

  final MicroIdlePresentation presentation;
  final double startedAt;
  final int facingBiasSign;

  double get endsAt => startedAt + presentation.durationSeconds;

  bool isDone(double now) => now >= endsAt;

  double progress(double now) {
    final d = presentation.durationSeconds;
    if (d <= 0) return 1;
    return ((now - startedAt) / d).clamp(0.0, 1.0);
  }
}

/// Schedules discrete micro-idles — never an activity / memory / need (R3).
class MicroIdleScheduler {
  MicroIdleScheduler({
    required this.pawnId,
    this.worldSeed = 0,
    this.reducedMotion = false,
    double initialProbeOffset = 0,
  }) : _nextProbeAt = initialProbeOffset;

  final String pawnId;
  final int worldSeed;
  bool reducedMotion;

  ActiveMicroIdle? _active;
  double _nextProbeAt;
  int _salt = 0;
  MicroIdleKind? _lastKind;

  ActiveMicroIdle? get active => _active;

  bool get isPlaying => _active != null;

  void reset({double now = 0, double probeOffset = 0}) {
    _active = null;
    _nextProbeAt = now + probeOffset;
    _salt = 0;
    _lastKind = null;
  }

  void armFirstProbe(double offset) {
    if (_active == null && _salt == 0) {
      _nextProbeAt = offset;
    }
  }

  /// Suppress during important speech / posture transitions.
  void interrupt() {
    _active = null;
  }

  /// Call each frame while pawn is eligible for idle microbeats.
  ///
  /// [idleDurationMultiplier] from conditions (M7) spaces probes further when
  /// tired / closer when restless.
  ActiveMicroIdle? tick({
    required double now,
    required bool eligible,
    required bool seated,
    required bool speakingImportant,
    BehaviorProfile? profile,
    double idleDurationMultiplier = 1,
    String? preferredIdlePoseTag,
  }) {
    if (_active != null) {
      if (_active!.isDone(now)) {
        _active = null;
        _armNextProbe(now, idleDurationMultiplier, profile);
      }
      return _active;
    }

    if (!eligible || speakingImportant) return null;
    if (now < _nextProbeAt) return null;

    final kind = _pickKind(
      seated: seated,
      profile: profile,
      preferredTag: preferredIdlePoseTag,
    );
    if (kind == null) {
      _armNextProbe(now, idleDurationMultiplier, profile);
      return null;
    }

    final pres = MicroIdleLibrary.presentation(kind);
    if (reducedMotion && pres.highMotion) {
      // Soft substitute instead of skipping the beat entirely.
      final soft = MicroIdleLibrary.presentation(MicroIdleKind.smallSighPose);
      _active = ActiveMicroIdle(
        presentation: soft,
        startedAt: now,
        facingBiasSign: _sign(),
      );
    } else {
      _active = ActiveMicroIdle(
        presentation: pres,
        startedAt: now,
        facingBiasSign: _sign(),
      );
    }
    _lastKind = kind;
    _salt++;
    return _active;
  }

  void _armNextProbe(
    double now,
    double idleDurationMultiplier,
    BehaviorProfile? profile,
  ) {
    // Base cadence ~3.5–9s; personality nudges; conditions stretch.
    var gap = HabitatRng.range(
      3.5,
      9.0,
      a: pawnId,
      b: 'microIdleGap',
      c: Object.hash(worldSeed, _salt),
    );
    gap *= idleDurationMultiplier.clamp(0.55, 1.8);
    if (profile != null) {
      // Restless / neurotic fidget more; conscientious less.
      gap *= (1.15 - profile.neuroticism * 0.35);
      gap *= (0.9 + profile.conscientiousness * 0.25);
    }
    _nextProbeAt = now + gap.clamp(2.2, 14.0);
  }

  MicroIdleKind? _pickKind({
    required bool seated,
    BehaviorProfile? profile,
    String? preferredTag,
  }) {
    var pool = List<MicroIdleKind>.from(
      seated ? MicroIdleLibrary.seatedPool : MicroIdleLibrary.standingPool,
    );
    if (reducedMotion) {
      pool.removeWhere(
        (k) => MicroIdleLibrary.presentation(k).highMotion,
      );
      if (pool.isEmpty) pool = [MicroIdleKind.smallSighPose];
    }
    // Avoid immediate repeat of the same beat.
    if (_lastKind != null && pool.length > 1) {
      pool.remove(_lastKind);
    }

    // Soft bias from idlePoseTag (M7) when present.
    if (preferredTag != null) {
      final bias = switch (preferredTag) {
        'yawn' || 'groggy' || 'sleepy' => MicroIdleKind.smallSighPose,
        'restless' => MicroIdleKind.footTap,
        'stretch' => MicroIdleKind.briefStretch,
        _ => null,
      };
      if (bias != null && pool.contains(bias)) {
        final u = HabitatRng.unit(pawnId, 'idleBias', _salt);
        if (u < 0.45) return bias;
      }
    }

    // Extraversion slightly favors look-around / check.
    if (profile != null && profile.extraversion > 0.65) {
      final socialish = [
        MicroIdleKind.lookLeftRight,
        MicroIdleKind.checkObject,
        MicroIdleKind.lookAtWindow,
      ].where(pool.contains).toList();
      if (socialish.isNotEmpty &&
          HabitatRng.unit(pawnId, 'ext', _salt) < 0.4) {
        final i = (HabitatRng.unit(pawnId, 'extPick', _salt) * socialish.length)
            .floor()
            .clamp(0, socialish.length - 1);
        return socialish[i];
      }
    }

    final i = (HabitatRng.unit(pawnId, 'pick', Object.hash(worldSeed, _salt)) *
            pool.length)
        .floor()
        .clamp(0, pool.length - 1);
    return pool[i];
  }

  int _sign() =>
      HabitatRng.unit(pawnId, 'facingBias', _salt) < 0.5 ? -1 : 1;
}
