import '../mirror/mirror_signal.dart';

/// Representational travel between timezones (MD 08 M40) — not Trips module.
class HabitatTravelContext {
  HabitatTravelContext({
    required this.id,
    required this.originSiteId,
    required this.destinationSiteIds,
    required this.timezoneSequence,
    required this.startsAt,
    this.endsAt,
    this.participantPawnIds = const {},
    this.source = MirrorSignalSource.manual,
  });

  final String id;
  final String originSiteId;
  final List<String> destinationSiteIds;
  final List<String> timezoneSequence;
  final double startsAt;
  double? endsAt;
  final Set<String> participantPawnIds;
  final MirrorSignalSource source;
}

/// Body vs site clock offset for soft jet-lag cosmetics (not medical).
class CircadianTravelState {
  CircadianTravelState({
    this.bodyClockOffsetHours = 0,
    this.siteClockOffsetHours = 0,
    this.adaptationProgress = 1,
  });

  /// Hours body clock lags behind site local (positive = body still "behind").
  double bodyClockOffsetHours;
  double siteClockOffsetHours;
  double adaptationProgress;

  bool get isJetLagged =>
      adaptationProgress < 0.95 && bodyClockOffsetHours.abs() > 0.5;

  double get sleepinessBoost =>
      isJetLagged ? (1 - adaptationProgress) * 0.35 : 0;

  double get napUtilityBoost =>
      isJetLagged ? (1 - adaptationProgress) * 0.25 : 0;
}

/// Travel + jet-lag director (M40).
class HabitatTravelDirector {
  HabitatTravelContext? active;
  final Map<String, CircadianTravelState> circadianByPawn = {};
  final List<String> debugLog = [];

  CircadianTravelState stateFor(String pawnId) =>
      circadianByPawn.putIfAbsent(pawnId, CircadianTravelState.new);

  /// Debug: São Paulo → distant timezone (e.g. Tokyo +12 approx).
  HabitatTravelContext beginTimezoneHop({
    required String pawnId,
    required String originSiteId,
    required String destinationSiteId,
    required String destinationTimezoneId,
    required double siteHourDelta,
    required double nowSim,
  }) {
    final ctx = HabitatTravelContext(
      id: 'travel.$nowSim',
      originSiteId: originSiteId,
      destinationSiteIds: [destinationSiteId],
      timezoneSequence: ['America/Sao_Paulo', destinationTimezoneId],
      startsAt: nowSim,
      participantPawnIds: {pawnId},
    );
    active = ctx;
    final circ = stateFor(pawnId);
    circ.siteClockOffsetHours = siteHourDelta;
    // Body does not jump — offset equals the hop; adaptation starts at 0.
    circ.bodyClockOffsetHours = siteHourDelta;
    circ.adaptationProgress = 0;
    debugLog.add(
      'hop $originSiteId→$destinationSiteId Δ${siteHourDelta}h tz=$destinationTimezoneId',
    );
    return ctx;
  }

  /// Gradual adaptation of body clock toward site (call on sim ticks).
  void tickAdaptation(String pawnId, {double dtSim = 1, double rate = 0.02}) {
    final c = stateFor(pawnId);
    if (c.adaptationProgress >= 1) return;
    c.adaptationProgress = (c.adaptationProgress + rate * dtSim).clamp(0.0, 1.0);
    c.bodyClockOffsetHours =
        c.siteClockOffsetHours * (1 - c.adaptationProgress);
  }

  void endTravel({required double nowSim}) {
    final a = active;
    if (a == null) return;
    a.endsAt = nowSim;
    debugLog.add('travel end ${a.id}');
    active = null;
  }
}
