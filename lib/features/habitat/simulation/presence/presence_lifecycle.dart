import '../mirror/mirror_signal.dart';
import '../time/habitat_episode.dart';

enum PresenceRole {
  resident,
  frequentVisitor,
  visitor,
  temporaryGuest,
  remoteParticipant,
}

enum PresenceState {
  absent,
  arriving,
  present,
  leaving,
  remote,
}

enum PresenceMode { physical, remote }

/// Presence episode at a site (MD 08 M18).
class HabitatPresenceEpisode {
  const HabitatPresenceEpisode({
    required this.id,
    required this.pawnId,
    required this.siteId,
    required this.startAt,
    required this.mode,
    required this.source,
    this.endAt,
  });

  final String id;
  final String pawnId;
  final String siteId;
  final double startAt;
  final double? endAt;
  final PresenceMode mode;
  final MirrorSignalSource source;

  bool get isOpen => endAt == null;

  HabitatPresenceEpisode end(double at) => HabitatPresenceEpisode(
        id: id,
        pawnId: pawnId,
        siteId: siteId,
        startAt: startAt,
        endAt: at,
        mode: mode,
        source: source,
      );
}

class PawnPresenceStatus {
  const PawnPresenceStatus({
    required this.pawnId,
    required this.role,
    required this.state,
    this.favoriteSeat,
    this.preferredRoom,
  });

  final String pawnId;
  final PresenceRole role;
  final PresenceState state;
  final (int, int)? favoriteSeat;
  final String? preferredRoom;

  PawnPresenceStatus copyWith({
    PresenceRole? role,
    PresenceState? state,
    (int, int)? favoriteSeat,
    String? preferredRoom,
  }) {
    return PawnPresenceStatus(
      pawnId: pawnId,
      role: role ?? this.role,
      state: state ?? this.state,
      favoriteSeat: favoriteSeat ?? this.favoriteSeat,
      preferredRoom: preferredRoom ?? this.preferredRoom,
    );
  }
}

/// Visitor enter/exit lifecycle without mid-room teleport (M18).
class VisitorLifecycleDirector {
  VisitorLifecycleDirector({required this.episodes});

  final HabitatEpisodeLedger episodes;
  final Map<String, PawnPresenceStatus> status = {};
  final Map<String, HabitatPresenceEpisode> openPresence = {};

  /// Scheduled visitor arrivals: pawnId → simSeconds.
  final Map<String, double> scheduledArrivals = {};
  final Map<String, double> scheduledDepartures = {};

  PawnPresenceStatus ensure(
    String pawnId, {
    PresenceRole role = PresenceRole.resident,
    PresenceState state = PresenceState.present,
  }) {
    return status.putIfAbsent(
      pawnId,
      () => PawnPresenceStatus(pawnId: pawnId, role: role, state: state),
    );
  }

  void scheduleVisit({
    required String pawnId,
    required double arriveAtSim,
    required double leaveAtSim,
    PresenceRole role = PresenceRole.visitor,
  }) {
    status[pawnId] = PawnPresenceStatus(
      pawnId: pawnId,
      role: role,
      state: PresenceState.absent,
    );
    scheduledArrivals[pawnId] = arriveAtSim;
    scheduledDepartures[pawnId] = leaveAtSim;
  }

  /// Tick lifecycle; returns pawns that should spawn at entrance / despawn.
  VisitorLifecycleEvents tick({
    required double simSeconds,
    required String siteId,
  }) {
    final spawn = <String>[];
    final despawn = <String>[];
    final greet = <String>[];
    final farewell = <String>[];

    for (final e in scheduledArrivals.entries.toList()) {
      final id = e.key;
      final at = e.value;
      final st = ensure(id, role: PresenceRole.visitor, state: PresenceState.absent);
      if (st.state == PresenceState.absent && simSeconds >= at - 30 && simSeconds < at) {
        status[id] = st.copyWith(state: PresenceState.arriving);
      }
      if ((st.state == PresenceState.absent || st.state == PresenceState.arriving) &&
          simSeconds >= at) {
        status[id] = st.copyWith(state: PresenceState.present);
        scheduledArrivals.remove(id);
        final epId = 'presence-$id-$simSeconds';
        openPresence[id] = HabitatPresenceEpisode(
          id: epId,
          pawnId: id,
          siteId: siteId,
          startAt: simSeconds,
          mode: PresenceMode.physical,
          source: MirrorSignalSource.simulated,
        );
        episodes.start(
          id: epId,
          kind: 'presence',
          atSimSeconds: simSeconds,
          data: {'pawnId': id, 'role': 'visitor'},
        );
        spawn.add(id);
        greet.add(id);
      }
    }

    for (final e in scheduledDepartures.entries.toList()) {
      final id = e.key;
      final at = e.value;
      final st = status[id];
      if (st == null) continue;
      // Farewell only after a real stay — not in the same tick as arrival,
      // and not if the visit is shorter than the farewell window.
      final open = openPresence[id];
      final farewellStart = at - 45;
      final mayFarewell = open != null &&
          open.startAt < farewellStart &&
          open.startAt < simSeconds;
      if (st.state == PresenceState.present &&
          mayFarewell &&
          simSeconds >= farewellStart &&
          simSeconds < at) {
        status[id] = st.copyWith(state: PresenceState.leaving);
        farewell.add(id);
      }
      if ((st.state == PresenceState.present || st.state == PresenceState.leaving) &&
          simSeconds >= at) {
        status[id] = st.copyWith(state: PresenceState.absent);
        scheduledDepartures.remove(id);
        final closing = openPresence.remove(id);
        if (closing != null) {
          episodes.end(closing.id, simSeconds);
        }
        despawn.add(id);
      }
    }

    return VisitorLifecycleEvents(
      spawnAtEntrance: spawn,
      despawn: despawn,
      greetOpportunity: greet,
      farewellOpportunity: farewell,
    );
  }
}

class VisitorLifecycleEvents {
  const VisitorLifecycleEvents({
    this.spawnAtEntrance = const [],
    this.despawn = const [],
    this.greetOpportunity = const [],
    this.farewellOpportunity = const [],
  });

  final List<String> spawnAtEntrance;
  final List<String> despawn;
  final List<String> greetOpportunity;
  final List<String> farewellOpportunity;
}
