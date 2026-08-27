import 'anticipation_profile.dart';
import 'desired_facing.dart';
import 'habitat_rng.dart';

/// Arrival pipeline phases (MD 10 R7).
enum ArrivalPhase {
  /// Still pathing toward the target.
  approaching,

  /// Path empty — facing settle delay running.
  settling,

  /// Brief anticipation before interaction start.
  anticipating,

  /// Pose / interaction running.
  interacting,

  /// Idle / cleared.
  none,
}

/// Snapshot driving one arrival choreography.
class ArrivalChoreographyState {
  const ArrivalChoreographyState({
    this.phase = ArrivalPhase.none,
    this.phaseEndsAt = 0,
    this.desiredFacing,
    this.facingApplied = false,
    this.affordanceId,
    this.propId,
    this.anticipation,
    this.reservationHeld = false,
  });

  final ArrivalPhase phase;
  final double phaseEndsAt;
  final DesiredFacingResult? desiredFacing;
  final bool facingApplied;
  final String? affordanceId;
  final String? propId;
  final AnticipationProfile? anticipation;
  final bool reservationHeld;

  bool get isBusy =>
      phase == ArrivalPhase.settling ||
      phase == ArrivalPhase.anticipating ||
      phase == ArrivalPhase.interacting;

  bool get blocksInteractionStart =>
      phase == ArrivalPhase.approaching ||
      phase == ArrivalPhase.settling ||
      phase == ArrivalPhase.anticipating;

  ArrivalChoreographyState copyWith({
    ArrivalPhase? phase,
    double? phaseEndsAt,
    DesiredFacingResult? desiredFacing,
    bool? facingApplied,
    String? affordanceId,
    String? propId,
    AnticipationProfile? anticipation,
    bool? reservationHeld,
    bool clearFacing = false,
    bool clearAnticipation = false,
  }) =>
      ArrivalChoreographyState(
        phase: phase ?? this.phase,
        phaseEndsAt: phaseEndsAt ?? this.phaseEndsAt,
        desiredFacing:
            clearFacing ? null : (desiredFacing ?? this.desiredFacing),
        facingApplied: facingApplied ?? this.facingApplied,
        affordanceId: affordanceId ?? this.affordanceId,
        propId: propId ?? this.propId,
        anticipation: clearAnticipation
            ? null
            : (anticipation ?? this.anticipation),
        reservationHeld: reservationHeld ?? this.reservationHeld,
      );
}

/// Orchestrates slowdown → settle → anticipation → interact (R7).
///
/// Cancel during settling/anticipating releases reservation without starting
/// the interaction pose.
class ArrivalChoreographer {
  ArrivalChoreographyState _state = const ArrivalChoreographyState();

  ArrivalChoreographyState get state => _state;

  void reset() {
    _state = const ArrivalChoreographyState();
  }

  /// Path just emptied — begin settle with facing intent.
  void onPathArrived({
    required double now,
    required DesiredFacingResult facing,
    required String affordanceId,
    String? propId,
    AnticipationProfile? anticipation,
    required String pawnId,
  }) {
    final settle = facing.settleDelaySeconds;
    _state = ArrivalChoreographyState(
      phase: ArrivalPhase.settling,
      phaseEndsAt: now + settle,
      desiredFacing: facing,
      facingApplied: false,
      affordanceId: affordanceId,
      propId: propId,
      anticipation: anticipation ??
          AnticipationCatalog.forAffordance(affordanceId),
      reservationHeld: true,
    );
    // Deterministic micro-variation already in facing.settleDelaySeconds.
    assert(pawnId.isNotEmpty);
  }

  /// Apply facing once settle timer elapses (caller sets pawn.facing).
  DesiredFacingResult? takeFacingIfDue(double now) {
    if (_state.phase != ArrivalPhase.settling) return null;
    if (_state.facingApplied) return null;
    if (now < _state.phaseEndsAt) return null;
    final f = _state.desiredFacing;
    _state = _state.copyWith(facingApplied: true);
    return f;
  }

  /// Advance settling → anticipating → ready-for-interact.
  ///
  /// Returns true when interaction may start (transition into interacting
  /// should be done by caller via [beginInteracting]).
  bool tick(double now) {
    switch (_state.phase) {
      case ArrivalPhase.settling:
        if (now < _state.phaseEndsAt) return false;
        // Ensure facing was applied even if caller missed takeFacingIfDue.
        final anti = _state.anticipation;
        final hold = anti?.holdSecondsFor(
              HabitatRng.unit(
                _state.affordanceId ?? 'aff',
                'anti',
                _state.propId,
              ),
            ) ??
            HabitatRng.range(0.08, 0.25, a: 'arrival', b: _state.affordanceId);
        _state = _state.copyWith(
          phase: ArrivalPhase.anticipating,
          phaseEndsAt: now + hold,
          facingApplied: true,
        );
        return false;
      case ArrivalPhase.anticipating:
        if (now < _state.phaseEndsAt) return false;
        return true;
      case ArrivalPhase.approaching:
      case ArrivalPhase.interacting:
      case ArrivalPhase.none:
        return false;
    }
  }

  void beginInteracting({required double now, required double poseSeconds}) {
    _state = _state.copyWith(
      phase: ArrivalPhase.interacting,
      phaseEndsAt: now + poseSeconds,
      reservationHeld: true,
    );
  }

  /// Cancel mid settle/anticipate — frees reservation, no interact start.
  bool cancel({required double now}) {
    if (_state.phase == ArrivalPhase.settling ||
        _state.phase == ArrivalPhase.anticipating ||
        _state.phase == ArrivalPhase.approaching) {
      _state = const ArrivalChoreographyState();
      return true;
    }
    return false;
  }

  void finish() {
    _state = const ArrivalChoreographyState();
  }

  void markApproaching({String? affordanceId, String? propId}) {
    _state = ArrivalChoreographyState(
      phase: ArrivalPhase.approaching,
      affordanceId: affordanceId,
      propId: propId,
      reservationHeld: propId != null,
    );
  }
}
