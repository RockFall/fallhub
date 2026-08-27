/// Body posture pipeline for sit / stand / lie (MD 10 R4).
enum PostureKind {
  standing,
  seated,
  lying,
}

enum PosturePhase {
  standing,
  preparingToSit,
  seated,
  preparingToStand,
  preparingToLie,
  lying,
  preparingToRise,
}

/// Active posture transition — seat reservation stays held while not standing.
class PostureTransitionState {
  const PostureTransitionState({
    required this.phase,
    required this.phaseEndsAt,
    this.seatPropId,
    this.from = PostureKind.standing,
    this.to = PostureKind.standing,
    this.cancelRequested = false,
  });

  final PosturePhase phase;
  final double phaseEndsAt;
  final String? seatPropId;
  final PostureKind from;
  final PostureKind to;
  final bool cancelRequested;

  bool get holdsSeatReservation =>
      phase == PosturePhase.preparingToSit ||
      phase == PosturePhase.seated ||
      phase == PosturePhase.preparingToStand ||
      phase == PosturePhase.preparingToLie ||
      phase == PosturePhase.lying ||
      phase == PosturePhase.preparingToRise;

  bool get isTransient =>
      phase == PosturePhase.preparingToSit ||
      phase == PosturePhase.preparingToStand ||
      phase == PosturePhase.preparingToLie ||
      phase == PosturePhase.preparingToRise;

  bool get isSettledSeated => phase == PosturePhase.seated;
  bool get isSettledLying => phase == PosturePhase.lying;
  bool get isStanding => phase == PosturePhase.standing;

  PostureTransitionState copyWith({
    PosturePhase? phase,
    double? phaseEndsAt,
    String? seatPropId,
    PostureKind? from,
    PostureKind? to,
    bool? cancelRequested,
    bool clearSeat = false,
  }) =>
      PostureTransitionState(
        phase: phase ?? this.phase,
        phaseEndsAt: phaseEndsAt ?? this.phaseEndsAt,
        seatPropId: clearSeat ? null : (seatPropId ?? this.seatPropId),
        from: from ?? this.from,
        to: to ?? this.to,
        cancelRequested: cancelRequested ?? this.cancelRequested,
      );
}

/// Durations kept short so sim isn't blocked by cosmetics (R4).
abstract final class PostureTimings {
  static const sitPrep = 0.28;
  static const standPrep = 0.24;
  static const liePrep = 0.36;
  static const risePrep = 0.32;

  /// Visual squash / offset envelope (presentation only).
  static double visualProgress(PosturePhase phase, double now, double endsAt) {
    final total = switch (phase) {
      PosturePhase.preparingToSit => sitPrep,
      PosturePhase.preparingToStand => standPrep,
      PosturePhase.preparingToLie => liePrep,
      PosturePhase.preparingToRise => risePrep,
      _ => 0.0,
    };
    if (total <= 0) return 1;
    final start = endsAt - total;
    return ((now - start) / total).clamp(0.0, 1.0);
  }
}

/// FSM for posture — cancel always ends in a consistent settled state (R4).
class PostureController {
  PostureTransitionState _state = const PostureTransitionState(
    phase: PosturePhase.standing,
    phaseEndsAt: 0,
  );

  PostureTransitionState get state => _state;

  void reset() {
    _state = const PostureTransitionState(
      phase: PosturePhase.standing,
      phaseEndsAt: 0,
    );
  }

  /// Begin sit — caller keeps seat reserved while [holdsSeatReservation].
  void beginSit({required double now, String? seatPropId}) {
    if (_state.phase == PosturePhase.seated ||
        _state.phase == PosturePhase.preparingToSit) {
      return;
    }
    _state = PostureTransitionState(
      phase: PosturePhase.preparingToSit,
      phaseEndsAt: now + PostureTimings.sitPrep,
      seatPropId: seatPropId,
      from: PostureKind.standing,
      to: PostureKind.seated,
    );
  }

  void beginStand({required double now}) {
    if (_state.phase == PosturePhase.standing ||
        _state.phase == PosturePhase.preparingToStand) {
      return;
    }
    if (_state.phase == PosturePhase.lying ||
        _state.phase == PosturePhase.preparingToLie) {
      beginRise(now: now);
      return;
    }
    _state = PostureTransitionState(
      phase: PosturePhase.preparingToStand,
      phaseEndsAt: now + PostureTimings.standPrep,
      seatPropId: _state.seatPropId,
      from: PostureKind.seated,
      to: PostureKind.standing,
    );
  }

  void beginLie({required double now, String? bedPropId}) {
    if (_state.phase == PosturePhase.lying ||
        _state.phase == PosturePhase.preparingToLie) {
      return;
    }
    _state = PostureTransitionState(
      phase: PosturePhase.preparingToLie,
      phaseEndsAt: now + PostureTimings.liePrep,
      seatPropId: bedPropId,
      from: PostureKind.standing,
      to: PostureKind.lying,
    );
  }

  void beginRise({required double now}) {
    if (_state.phase == PosturePhase.standing ||
        _state.phase == PosturePhase.preparingToRise) {
      return;
    }
    _state = PostureTransitionState(
      phase: PosturePhase.preparingToRise,
      phaseEndsAt: now + PostureTimings.risePrep,
      seatPropId: _state.seatPropId,
      from: PostureKind.lying,
      to: PostureKind.standing,
    );
  }

  /// Manual cancel / draft — snap toward a consistent settled posture.
  ///
  /// Mid sit-prep → standing (release seat).
  /// Mid stand-prep → standing (release seat).
  /// Mid lie-prep → standing.
  /// Mid rise-prep → standing.
  /// Already seated/lying → begin exit transition (or force standing if [force]).
  void requestCancel({required double now, bool force = false}) {
    switch (_state.phase) {
      case PosturePhase.standing:
        return;
      case PosturePhase.preparingToSit:
      case PosturePhase.preparingToLie:
        _state = const PostureTransitionState(
          phase: PosturePhase.standing,
          phaseEndsAt: 0,
        );
      case PosturePhase.preparingToStand:
      case PosturePhase.preparingToRise:
        _state = const PostureTransitionState(
          phase: PosturePhase.standing,
          phaseEndsAt: 0,
        );
      case PosturePhase.seated:
        if (force) {
          _state = const PostureTransitionState(
            phase: PosturePhase.standing,
            phaseEndsAt: 0,
          );
        } else {
          beginStand(now: now);
          _state = _state.copyWith(cancelRequested: true);
        }
      case PosturePhase.lying:
        if (force) {
          _state = const PostureTransitionState(
            phase: PosturePhase.standing,
            phaseEndsAt: 0,
          );
        } else {
          beginRise(now: now);
          _state = _state.copyWith(cancelRequested: true);
        }
    }
  }

  /// Advance FSM. Returns true when a phase boundary was crossed.
  bool tick(double now) {
    if (!_state.isTransient) return false;
    if (now < _state.phaseEndsAt) return false;

    switch (_state.phase) {
      case PosturePhase.preparingToSit:
        _state = PostureTransitionState(
          phase: PosturePhase.seated,
          phaseEndsAt: now,
          seatPropId: _state.seatPropId,
          from: PostureKind.standing,
          to: PostureKind.seated,
          cancelRequested: _state.cancelRequested,
        );
        if (_state.cancelRequested) {
          beginStand(now: now);
        }
        return true;
      case PosturePhase.preparingToStand:
        _state = const PostureTransitionState(
          phase: PosturePhase.standing,
          phaseEndsAt: 0,
        );
        return true;
      case PosturePhase.preparingToLie:
        _state = PostureTransitionState(
          phase: PosturePhase.lying,
          phaseEndsAt: now,
          seatPropId: _state.seatPropId,
          from: PostureKind.standing,
          to: PostureKind.lying,
          cancelRequested: _state.cancelRequested,
        );
        if (_state.cancelRequested) {
          beginRise(now: now);
        }
        return true;
      case PosturePhase.preparingToRise:
        _state = const PostureTransitionState(
          phase: PosturePhase.standing,
          phaseEndsAt: 0,
        );
        return true;
      case PosturePhase.standing:
      case PosturePhase.seated:
      case PosturePhase.lying:
        return false;
    }
  }
}
