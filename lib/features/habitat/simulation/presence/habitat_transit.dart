import '../mirror/mirror_signal.dart';
import '../time/habitat_episode.dart';

enum PawnPresenceLocation {
  atSite,
  leaving,
  inTransit,
  arriving,
  away,
  unknown,
}

enum TransitMode { walk, car, publicTransit, train, plane, abstract }

class HabitatTransitEpisode {
  const HabitatTransitEpisode({
    required this.id,
    required this.pawnId,
    required this.originSiteId,
    required this.destinationSiteId,
    required this.startAt,
    required this.expectedArrivalAt,
    required this.mode,
    this.source = MirrorSignalSource.simulated,
    this.endAt,
  });

  final String id;
  final String pawnId;
  final String originSiteId;
  final String destinationSiteId;
  final double startAt;
  final double expectedArrivalAt;
  final double? endAt;
  final TransitMode mode;
  final MirrorSignalSource source;

  bool get isOpen => endAt == null;
}

/// Tracks home / away / transit without rendering vehicles (MD 08 M23).
class HabitatTransitDirector {
  HabitatTransitDirector({
    required this.episodes,
    this.materializeSite,
  });

  final HabitatEpisodeLedger episodes;

  /// Returns true when [siteId] has a playable map to arrive into.
  bool Function(String siteId)? materializeSite;
  final Map<String, PawnPresenceLocation> locationState = {};
  final Map<String, String> currentSiteId = {};
  final Map<String, HabitatTransitEpisode> openTransit = {};

  void ensureAtSite(String pawnId, String siteId) {
    locationState[pawnId] = PawnPresenceLocation.atSite;
    currentSiteId[pawnId] = siteId;
  }

  /// Begin leaving [originSiteId] toward [destinationSiteId].
  HabitatTransitEpisode beginTransit({
    required String pawnId,
    required String originSiteId,
    required String destinationSiteId,
    required double nowSim,
    double durationSeconds = 60,
    TransitMode mode = TransitMode.walk,
  }) {
    locationState[pawnId] = PawnPresenceLocation.leaving;
    final ep = HabitatTransitEpisode(
      id: 'transit-$pawnId-$nowSim',
      pawnId: pawnId,
      originSiteId: originSiteId,
      destinationSiteId: destinationSiteId,
      startAt: nowSim,
      expectedArrivalAt: nowSim + durationSeconds,
      mode: mode,
    );
    openTransit[pawnId] = ep;
    episodes.start(
      id: ep.id,
      kind: 'transit',
      atSimSeconds: nowSim,
      data: {
        'from': originSiteId,
        'to': destinationSiteId,
        'mode': mode.name,
      },
    );
    return ep;
  }

  /// Mark as away when destination has no materialized map.
  void markAway(String pawnId, double nowSim) {
    locationState[pawnId] = PawnPresenceLocation.away;
    final open = openTransit.remove(pawnId);
    if (open != null) {
      episodes.end(open.id, nowSim);
    }
  }

  List<TransitTickEvent> tick(double nowSim) {
    final events = <TransitTickEvent>[];
    for (final e in openTransit.entries.toList()) {
      final id = e.key;
      final ep = e.value;
      final st = locationState[id] ?? PawnPresenceLocation.unknown;

      if (st == PawnPresenceLocation.leaving &&
          nowSim >= ep.startAt + 3) {
        locationState[id] = PawnPresenceLocation.inTransit;
        events.add(TransitTickEvent.leftSite(id, ep.originSiteId));
      }

      if ((locationState[id] == PawnPresenceLocation.inTransit ||
              locationState[id] == PawnPresenceLocation.leaving) &&
          nowSim >= ep.expectedArrivalAt) {
        // Destinations without a playable map stay "away".
        final materialized = materializeSite?.call(ep.destinationSiteId) ?? true;
        if (!materialized) {
          locationState[id] = PawnPresenceLocation.away;
          currentSiteId[id] = ep.destinationSiteId;
          events.add(TransitTickEvent.away(id, ep.destinationSiteId));
          episodes.end(ep.id, nowSim);
          openTransit.remove(id);
          continue;
        }
        locationState[id] = PawnPresenceLocation.arriving;
        currentSiteId[id] = ep.destinationSiteId;
        events.add(
          TransitTickEvent.arrived(id, ep.destinationSiteId),
        );
        episodes.end(ep.id, nowSim);
        openTransit.remove(id);
        locationState[id] = PawnPresenceLocation.atSite;
      }
    }
    return events;
  }

  bool isPhysicallyPresent(String pawnId, String siteId) {
    final st = locationState[pawnId];
    if (st == PawnPresenceLocation.away ||
        st == PawnPresenceLocation.inTransit ||
        st == PawnPresenceLocation.leaving) {
      return false;
    }
    return currentSiteId[pawnId] == siteId;
  }
}

class TransitTickEvent {
  const TransitTickEvent._(this.kind, this.pawnId, this.siteId);

  final String kind;
  final String pawnId;
  final String siteId;

  factory TransitTickEvent.leftSite(String pawnId, String siteId) =>
      TransitTickEvent._('left', pawnId, siteId);

  factory TransitTickEvent.arrived(String pawnId, String siteId) =>
      TransitTickEvent._('arrived', pawnId, siteId);

  factory TransitTickEvent.away(String pawnId, String siteId) =>
      TransitTickEvent._('away', pawnId, siteId);
}
