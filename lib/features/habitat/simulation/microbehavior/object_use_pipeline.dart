/// Generic object interaction phases (MD 10 R20).
enum ObjectUsePhase {
  approach,
  anticipate,
  reach,
  engage,
  useLoop,
  release,
  settle,
  cancelled,
  done,
}

/// Which phases an affordance actually runs.
class ObjectUseProfile {
  const ObjectUseProfile({
    required this.id,
    this.phases = const [
      ObjectUsePhase.approach,
      ObjectUsePhase.anticipate,
      ObjectUsePhase.reach,
      ObjectUsePhase.engage,
      ObjectUsePhase.useLoop,
      ObjectUsePhase.release,
      ObjectUsePhase.settle,
    ],
    this.reachSeconds = 0.18,
    this.engageSeconds = 0.12,
    this.releaseSeconds = 0.16,
    this.settleSeconds = 0.1,
  });

  final String id;
  final List<ObjectUsePhase> phases;
  final double reachSeconds;
  final double engageSeconds;
  final double releaseSeconds;
  final double settleSeconds;

  bool includes(ObjectUsePhase p) => phases.contains(p);
}

abstract final class ObjectUseProfiles {
  static const book = ObjectUseProfile(
    id: 'book',
    phases: [
      ObjectUsePhase.approach,
      ObjectUsePhase.anticipate,
      ObjectUsePhase.reach,
      ObjectUsePhase.engage,
      ObjectUsePhase.useLoop,
      ObjectUsePhase.release,
      ObjectUsePhase.settle,
    ],
    reachSeconds: 0.22,
    engageSeconds: 0.2,
  );

  static const cup = ObjectUseProfile(
    id: 'cup',
    phases: [
      ObjectUsePhase.approach,
      ObjectUsePhase.reach,
      ObjectUsePhase.engage,
      ObjectUsePhase.useLoop,
      ObjectUsePhase.release,
      ObjectUsePhase.settle,
    ],
    reachSeconds: 0.15,
  );

  static const piano = ObjectUseProfile(
    id: 'piano',
    phases: [
      ObjectUsePhase.approach,
      ObjectUsePhase.anticipate,
      ObjectUsePhase.engage,
      ObjectUsePhase.useLoop,
      ObjectUsePhase.release,
      ObjectUsePhase.settle,
    ],
    // No reach — hands already at keys after sit.
    engageSeconds: 0.25,
  );

  static const lightSwitch = ObjectUseProfile(
    id: 'switch',
    phases: [
      ObjectUsePhase.approach,
      ObjectUsePhase.reach,
      ObjectUsePhase.engage,
      ObjectUsePhase.release,
      ObjectUsePhase.settle,
    ],
    reachSeconds: 0.12,
    engageSeconds: 0.08,
    releaseSeconds: 0.08,
  );

  static ObjectUseProfile forTags(Set<String> tags) {
    if (tags.contains('book')) return book;
    if (tags.contains('cup') || tags.contains('mug')) return cup;
    if (tags.contains('piano') || tags.contains('instrument')) return piano;
    if (tags.contains('switch') || tags.contains('light')) return lightSwitch;
    return book;
  }
}

class ObjectUseSession {
  ObjectUseSession({
    required this.profile,
    required this.pawnId,
    required this.targetId,
    required this.startedAt,
  }) : phase = profile.phases.first;

  final ObjectUseProfile profile;
  final String pawnId;
  final String targetId;
  final double startedAt;
  ObjectUsePhase phase;
  double phaseEndsAt = 0;
  bool cancelled = false;

  void begin(double now) {
    phase = profile.phases.first;
    phaseEndsAt = now + _duration(phase);
  }

  double _duration(ObjectUsePhase p) => switch (p) {
        ObjectUsePhase.reach => profile.reachSeconds,
        ObjectUsePhase.engage => profile.engageSeconds,
        ObjectUsePhase.release => profile.releaseSeconds,
        ObjectUsePhase.settle => profile.settleSeconds,
        ObjectUsePhase.anticipate => 0.2,
        ObjectUsePhase.useLoop => 0, // driven externally
        ObjectUsePhase.approach ||
        ObjectUsePhase.cancelled ||
        ObjectUsePhase.done =>
          0,
      };

  /// Advance timed phases. Returns true when [done] or [cancelled].
  bool tick(double now, {bool useLoopComplete = false}) {
    if (cancelled) {
      phase = ObjectUsePhase.cancelled;
      return true;
    }
    if (phase == ObjectUsePhase.useLoop) {
      if (!useLoopComplete) return false;
      return _advance(now);
    }
    if (_duration(phase) <= 0) {
      return _advance(now);
    }
    if (now < phaseEndsAt) return false;
    return _advance(now);
  }

  bool _advance(double now) {
    final idx = profile.phases.indexOf(phase);
    if (idx < 0 || idx >= profile.phases.length - 1) {
      phase = ObjectUsePhase.done;
      return true;
    }
    phase = profile.phases[idx + 1];
    phaseEndsAt = now + _duration(phase);
    if (phase == ObjectUsePhase.done) return true;
    return false;
  }

  /// Safe cancel — leave phase as cancelled; caller restores item location.
  void cancel() {
    cancelled = true;
    phase = ObjectUsePhase.cancelled;
  }

  bool get isTerminal =>
      phase == ObjectUsePhase.done || phase == ObjectUsePhase.cancelled;
}
