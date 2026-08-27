import '../identity/identity.dart';
import '../mirror/mirror_signal.dart';
import '../presence/habitat_appointment.dart';
import '../presence/presence_lifecycle.dart';
import '../time/habitat_episode.dart';

/// Future integration ports — no real adapters (MD 08 M44).

class HabitatSleepEpisode {
  const HabitatSleepEpisode({
    required this.startSim,
    required this.endSim,
    this.quality = 0.7,
  });

  final double startSim;
  final double endSim;
  final double quality;
}

class HabitatPresenceObservation {
  const HabitatPresenceObservation({
    required this.pawnId,
    required this.state,
  });

  final String pawnId;
  final PresenceState state;
}

class EnvironmentSignalBundle {
  const EnvironmentSignalBundle({
    required this.siteId,
    this.temperatureC,
    this.noise = 0.3,
    this.light = 0.7,
  });

  final String siteId;
  final double? temperatureC;
  final double noise;
  final double light;
}

abstract interface class HabitatSleepSignalPort {
  List<MirrorSignal<HabitatSleepEpisode>> readSleepSignals(String pawnId);
}

abstract interface class HabitatPresenceSignalPort {
  List<MirrorSignal<HabitatPresenceObservation>> readPresence(String pawnId);
}

abstract interface class HabitatAppointmentPort {
  List<MirrorSignal<HabitatAppointment>> readAppointments(String pawnId);
}

abstract interface class HabitatInterestPort {
  List<MirrorSignal<PreferenceReading>> readPreferences(String pawnId);
}

abstract interface class HabitatEnvironmentPort {
  EnvironmentSignalBundle readEnvironment(String siteId);
}

abstract interface class HabitatTravelContextPort {
  MirrorSignal<String>? readActiveTravelId();
}

class NullSleepSignalPort implements HabitatSleepSignalPort {
  @override
  List<MirrorSignal<HabitatSleepEpisode>> readSleepSignals(String pawnId) =>
      const [];
}

class NullPresenceSignalPort implements HabitatPresenceSignalPort {
  @override
  List<MirrorSignal<HabitatPresenceObservation>> readPresence(String pawnId) =>
      const [];
}

class NullAppointmentPort implements HabitatAppointmentPort {
  @override
  List<MirrorSignal<HabitatAppointment>> readAppointments(String pawnId) =>
      const [];
}

class NullTravelContextPort implements HabitatTravelContextPort {
  @override
  MirrorSignal<String>? readActiveTravelId() => null;
}

class SimulatedSleepSignalPort implements HabitatSleepSignalPort {
  SimulatedSleepSignalPort({this.episodes = const []});

  List<HabitatSleepEpisode> episodes;

  @override
  List<MirrorSignal<HabitatSleepEpisode>> readSleepSignals(String pawnId) {
    return [
      for (final e in episodes)
        MirrorSignal<HabitatSleepEpisode>(
          id: 'sleep.sim.$pawnId.${e.startSim}',
          value: e,
          source: MirrorSignalSource.simulated,
          observedAt: DateTime.now().toUtc(),
          confidence: 0.8,
        ),
    ];
  }
}

class ManualInterestPort implements HabitatInterestPort {
  ManualInterestPort({Map<String, List<PreferenceReading>>? seeded})
      : _seeded = seeded ?? {};

  final Map<String, List<PreferenceReading>> _seeded;

  void set(String pawnId, List<PreferenceReading> readings) =>
      _seeded[pawnId] = readings;

  @override
  List<MirrorSignal<PreferenceReading>> readPreferences(String pawnId) {
    final list = _seeded[pawnId] ?? const <PreferenceReading>[];
    return [
      for (final r in list)
        MirrorSignal<PreferenceReading>(
          id: 'interest.manual.$pawnId.${r.path.id}',
          value: r,
          source: MirrorSignalSource.manual,
          observedAt: r.observedAt ?? DateTime.now().toUtc(),
          confidence: r.confidence,
        ),
    ];
  }
}

class SimulatedEnvironmentPort implements HabitatEnvironmentPort {
  @override
  EnvironmentSignalBundle readEnvironment(String siteId) {
    return EnvironmentSignalBundle(siteId: siteId, temperatureC: 22);
  }
}

class SimulatedPresenceSignalPort implements HabitatPresenceSignalPort {
  SimulatedPresenceSignalPort(this.presence);
  final VisitorLifecycleDirector presence;

  @override
  List<MirrorSignal<HabitatPresenceObservation>> readPresence(String pawnId) {
    final p = presence.status[pawnId];
    if (p == null) return const [];
    return [
      MirrorSignal<HabitatPresenceObservation>(
        id: 'presence.sim.$pawnId',
        value: HabitatPresenceObservation(pawnId: pawnId, state: p.state),
        source: MirrorSignalSource.simulated,
        observedAt: DateTime.now().toUtc(),
        confidence: 1,
      ),
    ];
  }
}

/// Bundle of ports wired to null/simulated defaults (M44).
class HabitatPortBundle {
  HabitatPortBundle({
    HabitatSleepSignalPort? sleep,
    HabitatPresenceSignalPort? presence,
    HabitatAppointmentPort? appointments,
    HabitatInterestPort? interests,
    HabitatEnvironmentPort? environment,
    HabitatTravelContextPort? travel,
    HabitatEpisodeLedger? episodes,
  })  : sleep = sleep ?? NullSleepSignalPort(),
        presence = presence ??
            (episodes != null
                ? SimulatedPresenceSignalPort(
                    VisitorLifecycleDirector(episodes: episodes),
                  )
                : NullPresenceSignalPort()),
        appointments = appointments ?? NullAppointmentPort(),
        interests = interests ?? ManualInterestPort(),
        environment = environment ?? SimulatedEnvironmentPort(),
        travel = travel ?? NullTravelContextPort();

  HabitatSleepSignalPort sleep;
  HabitatPresenceSignalPort presence;
  HabitatAppointmentPort appointments;
  HabitatInterestPort interests;
  HabitatEnvironmentPort environment;
  HabitatTravelContextPort travel;
}
