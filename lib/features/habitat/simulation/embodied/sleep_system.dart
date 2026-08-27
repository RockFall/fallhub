import 'dart:math' as math;

import '../mirror/mirror_signal.dart';
import '../time/habitat_episode.dart';
import 'condition_engine.dart';
import 'pawn_embodied_state.dart';

/// Deterministic circadian profile from pawn id (M8).
class CircadianProfile {
  const CircadianProfile({
    required this.preferredSleepHour,
    required this.preferredWakeHour,
    required this.morningActivation,
    required this.eveningActivation,
    required this.napAffinity,
  });

  final double preferredSleepHour;
  final double preferredWakeHour;
  final double morningActivation;
  final double eveningActivation;
  final double napAffinity;

  factory CircadianProfile.fromSeed(String pawnId, {int worldSeed = 0}) {
    final h = Object.hash(pawnId, worldSeed);
    final sleep = 21.5 + (h % 30) / 10.0; // 21.5–24.4 → wrap
    final wake = 6.0 + (h % 25) / 10.0; // 6.0–8.4
    return CircadianProfile(
      preferredSleepHour: sleep % 24,
      preferredWakeHour: wake % 24,
      morningActivation: 0.55 + (h % 20) / 100,
      eveningActivation: 0.5 + ((h >> 3) % 25) / 100,
      napAffinity: 0.2 + ((h >> 5) % 40) / 100,
    );
  }
}

enum SleepEpisodeKind { mainSleep, nap }

class HabitatSleepEpisode {
  const HabitatSleepEpisode({
    required this.id,
    required this.pawnId,
    required this.startSimTime,
    required this.kind,
    required this.quality,
    required this.source,
    this.endSimTime,
  });

  final String id;
  final String pawnId;
  final double startSimTime;
  final double? endSimTime;
  final SleepEpisodeKind kind;
  final double quality;
  final MirrorSignalSource source;

  bool get isOpen => endSimTime == null;

  HabitatSleepEpisode end(double at, {double? quality}) {
    return HabitatSleepEpisode(
      id: id,
      pawnId: pawnId,
      startSimTime: startSimTime,
      endSimTime: at,
      kind: kind,
      quality: quality ?? this.quality,
      source: source,
    );
  }
}

/// Sleep pressure, circadian drive, episodes, inertia (MD 08 M8).
class SleepSystem {
  SleepSystem({
    required this.episodes,
    ConditionEngine? conditions,
  }) : conditions = conditions ?? ConditionEngine();

  final HabitatEpisodeLedger episodes;
  final ConditionEngine conditions;
  final Map<String, CircadianProfile> _profiles = {};
  final Map<String, HabitatSleepEpisode> _sleepById = {};
  final Map<String, double> _awakeSince = {};

  CircadianProfile profileFor(String pawnId) =>
      _profiles.putIfAbsent(pawnId, () => CircadianProfile.fromSeed(pawnId));

  /// Circadian sleep drive 0..1 from scene hour.
  double circadianDrive(CircadianProfile profile, double sceneHour) {
    final sleepH = profile.preferredSleepHour;
    // Distance to preferred sleep hour (circular).
    var d = (sceneHour - sleepH).abs();
    if (d > 12) d = 24 - d;
    // High near sleep hour, low mid-day.
    final nearSleep = math.exp(-(d * d) / 18);
    final nightBoost = (sceneHour >= 22 || sceneHour < 5) ? 0.25 : 0.0;
    return (nearSleep * 0.75 + nightBoost + profile.eveningActivation * 0.1)
        .clamp(0.0, 1.0);
  }

  PawnEmbodiedState tick({
    required PawnEmbodiedState state,
    required double simSeconds,
    required double sceneHour,
    required DateTime observedAt,
    required bool jobIsSleep,
    double bedComfort = 0.6,
    double darkness = 0.5,
    double tempComfort = 1,
  }) {
    final profile = profileFor(state.pawnId);
    final drive = circadianDrive(profile, sceneHour);
    var pressure = state.circadian.sleepPressure;
    var phase = state.sleepPhase;
    var inertia = state.circadian.sleepInertia;
    var next = state;

    final awakeSince = _awakeSince[state.pawnId] ?? simSeconds;
    if (phase == SleepPhase.sleeping || phase == SleepPhase.nap) {
      // Recover pressure while sleeping.
      pressure = (pressure - 0.12).clamp(0.0, 1.0);
      inertia = (inertia - 0.02).clamp(0.0, 1.0);
    } else {
      final awakeHours = (simSeconds - awakeSince) / 3600.0;
      pressure = (0.15 + awakeHours * 0.05 + drive * 0.25).clamp(0.0, 1.0);
      inertia = (inertia - 0.01).clamp(0.0, 1.0);
    }

    // Phase machine (lightweight).
    if (phase == SleepPhase.awake || phase == SleepPhase.windingDown) {
      if (pressure > 0.55 || drive > 0.7) {
        phase = SleepPhase.sleepy;
        next = conditions.upsert(
          next,
          conditions.create(
            kind: PawnConditionKind.sleepy,
            intensity: pressure.clamp(0.3, 0.9),
            atSimSeconds: simSeconds,
            durationSeconds: 1800,
          ),
        );
      }
    }
    if (phase == SleepPhase.sleepy && (jobIsSleep || pressure > 0.75)) {
      phase = SleepPhase.goingToBed;
    }
    if ((phase == SleepPhase.goingToBed || phase == SleepPhase.sleepy) &&
        jobIsSleep) {
      phase = SleepPhase.sleeping;
      if (next.activeSleepEpisodeId == null) {
        next = _beginSleep(
          next,
          simSeconds: simSeconds,
          kind: SleepEpisodeKind.mainSleep,
          quality: _estimateQuality(bedComfort, darkness, tempComfort),
        );
      }
    }

    // Nap opportunity
    if (phase == SleepPhase.awake &&
        pressure > 0.65 &&
        profile.napAffinity > 0.35 &&
        sceneHour >= 13 &&
        sceneHour <= 16 &&
        jobIsSleep &&
        next.activeSleepEpisodeId == null) {
      phase = SleepPhase.nap;
      next = _beginSleep(
        next,
        simSeconds: simSeconds,
        kind: SleepEpisodeKind.nap,
        quality: _estimateQuality(bedComfort, darkness, tempComfort) * 0.7,
      );
    }

    // Wake when sleep job ends
    if ((phase == SleepPhase.sleeping || phase == SleepPhase.nap) &&
        !jobIsSleep &&
        next.activeSleepEpisodeId != null) {
      next = _endSleep(next, simSeconds: simSeconds);
      phase = SleepPhase.waking;
      inertia = 0.55;
      next = conditions.upsert(
        next,
        conditions.create(
          kind: PawnConditionKind.groggy,
          intensity: 0.6,
          atSimSeconds: simSeconds,
          durationSeconds: 900,
        ),
      );
      next = conditions.upsert(
        next,
        conditions.create(
          kind: PawnConditionKind.wellRested,
          intensity: 0.4,
          atSimSeconds: simSeconds,
          durationSeconds: 2400,
        ),
      );
      _awakeSince[state.pawnId] = simSeconds;
    }
    if (phase == SleepPhase.waking && inertia < 0.2) {
      phase = SleepPhase.awake;
    }

    final alertness = (1.0 -
            pressure * 0.45 -
            drive * 0.15 -
            inertia * 0.4 +
            profile.morningActivation * 0.1)
        .clamp(0.05, 1.0);

    // Mirror sleep need pressure toward sleepPressure.
    final needs = Map<NeedKind, NeedReading>.from(next.needs);
    final sleepNeed = needs[NeedKind.sleep];
    if (sleepNeed != null) {
      needs[NeedKind.sleep] = sleepNeed.copyWith(
        pressure: (sleepNeed.pressure * 0.35 + pressure * 0.65).clamp(0.0, 1.0),
        observedAt: observedAt,
      );
    }

    return next.copyWith(
      needs: needs,
      sleepPhase: phase,
      circadian: next.circadian.copyWith(
        sleepPressure: pressure,
        circadianDrive: drive,
        sleepInertia: inertia,
        alertness: alertness,
        source: MirrorSignalSource.systemDerived,
      ),
    );
  }

  double _estimateQuality(double bed, double dark, double temp) {
    return (bed * 0.45 + dark * 0.3 + temp * 0.25).clamp(0.15, 1.0);
  }

  PawnEmbodiedState _beginSleep(
    PawnEmbodiedState state, {
    required double simSeconds,
    required SleepEpisodeKind kind,
    required double quality,
  }) {
    final id = 'sleep-${state.pawnId}-$simSeconds';
    final ep = HabitatSleepEpisode(
      id: id,
      pawnId: state.pawnId,
      startSimTime: simSeconds,
      kind: kind,
      quality: quality,
      source: MirrorSignalSource.simulated,
    );
    _sleepById[id] = ep;
    episodes.start(
      id: id,
      kind: kind == SleepEpisodeKind.nap ? 'nap' : 'sleep',
      atSimSeconds: simSeconds,
      data: {'quality': quality, 'pawnId': state.pawnId},
    );
    return state.copyWith(activeSleepEpisodeId: id);
  }

  PawnEmbodiedState _endSleep(
    PawnEmbodiedState state, {
    required double simSeconds,
  }) {
    final id = state.activeSleepEpisodeId;
    if (id == null) return state;
    final open = _sleepById[id];
    if (open != null) {
      _sleepById[id] = open.end(simSeconds);
    }
    episodes.end(id, simSeconds);
    return state.copyWith(clearSleepEpisode: true);
  }

  HabitatSleepEpisode? episode(String id) => _sleepById[id];
}
