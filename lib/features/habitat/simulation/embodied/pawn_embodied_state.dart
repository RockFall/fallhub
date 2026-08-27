import '../mirror/mirror_signal.dart';

/// Habitat need kinds (MD 08 M5). Prefer pressure 0..1 (not “happiness”).
enum NeedKind {
  sleep,
  food,
  movement,
  rest,
  socialConnection,
  solitude,
  recreation,
  stimulation,
  creativeExpression,
  comfort,
}

/// Momentary capacities (MD 08 M6).
enum CapacityKind {
  energy,
  focus,
  physicalReadiness,
  socialTolerance,
  creativeCapacity,
  decisionCapacity,
  recovery,
}

enum EmbodiedTrend {
  rising,
  steady,
  falling,
}

class NeedReading {
  const NeedReading({
    required this.kind,
    required this.pressure,
    required this.source,
    this.trend = EmbodiedTrend.steady,
    this.trendPerSimHour = 0,
    this.observedAt,
  });

  final NeedKind kind;
  final double pressure;
  final MirrorSignalSource source;
  final EmbodiedTrend trend;
  final double trendPerSimHour;
  final DateTime? observedAt;

  NeedReading copyWith({
    double? pressure,
    MirrorSignalSource? source,
    EmbodiedTrend? trend,
    double? trendPerSimHour,
    DateTime? observedAt,
  }) {
    return NeedReading(
      kind: kind,
      pressure: (pressure ?? this.pressure).clamp(0.0, 1.0),
      source: source ?? this.source,
      trend: trend ?? this.trend,
      trendPerSimHour: trendPerSimHour ?? this.trendPerSimHour,
      observedAt: observedAt ?? this.observedAt,
    );
  }
}

class CapacityReading {
  const CapacityReading({
    required this.kind,
    required this.level,
    required this.source,
    this.derivedFrom = const [],
    this.observedAt,
  });

  final CapacityKind kind;
  final double level;
  final MirrorSignalSource source;
  final List<String> derivedFrom;
  final DateTime? observedAt;

  CapacityReading copyWith({
    double? level,
    MirrorSignalSource? source,
    List<String>? derivedFrom,
    DateTime? observedAt,
  }) {
    return CapacityReading(
      kind: kind,
      level: (level ?? this.level).clamp(0.0, 1.0),
      source: source ?? this.source,
      derivedFrom: derivedFrom ?? this.derivedFrom,
      observedAt: observedAt ?? this.observedAt,
    );
  }
}

enum PawnConditionKind {
  sleepy,
  tired,
  wellRested,
  groggy,
  physicallyTired,
  mentallyFatigued,
  sociallyDrained,
  restless,
  relaxed,
  inspired,
  cold,
  hot,
}

class ConditionPresentation {
  const ConditionPresentation({
    this.moteTag,
    this.bubbleTag,
    this.walkSpeedMultiplier = 1,
    this.idlePoseTag,
    this.idleDurationMultiplier = 1,
  });

  final String? moteTag;
  final String? bubbleTag;
  final double walkSpeedMultiplier;
  final String? idlePoseTag;
  final double idleDurationMultiplier;
}

class PawnCondition {
  const PawnCondition({
    required this.id,
    required this.kind,
    required this.intensity,
    required this.source,
    required this.startedAtSimSeconds,
    this.expectedEndAtSimSeconds,
    this.capacityModifiers = const {},
    this.affordanceModifiers = const {},
    this.presentation = const ConditionPresentation(),
  });

  final String id;
  final PawnConditionKind kind;
  final double intensity;
  final MirrorSignalSource source;
  final double startedAtSimSeconds;
  final double? expectedEndAtSimSeconds;
  final Map<CapacityKind, double> capacityModifiers;
  final Map<String, double> affordanceModifiers;
  final ConditionPresentation presentation;

  String get label => kind.name;

  bool isActiveAt(double simSeconds) {
    final end = expectedEndAtSimSeconds;
    if (end == null) return intensity > 0.02;
    return simSeconds < end && intensity > 0.02;
  }

  PawnCondition copyWith({
    double? intensity,
    double? expectedEndAtSimSeconds,
  }) {
    return PawnCondition(
      id: id,
      kind: kind,
      intensity: (intensity ?? this.intensity).clamp(0.0, 1.0),
      source: source,
      startedAtSimSeconds: startedAtSimSeconds,
      expectedEndAtSimSeconds:
          expectedEndAtSimSeconds ?? this.expectedEndAtSimSeconds,
      capacityModifiers: capacityModifiers,
      affordanceModifiers: affordanceModifiers,
      presentation: presentation,
    );
  }
}

class CircadianState {
  const CircadianState({
    this.phaseOffsetHours = 0,
    this.alertness = 0.7,
    this.sleepPressure = 0.3,
    this.circadianDrive = 0.2,
    this.sleepInertia = 0,
    this.source = MirrorSignalSource.simulated,
  });

  final double phaseOffsetHours;
  final double alertness;
  final double sleepPressure;
  final double circadianDrive;
  final double sleepInertia;
  final MirrorSignalSource source;

  CircadianState copyWith({
    double? phaseOffsetHours,
    double? alertness,
    double? sleepPressure,
    double? circadianDrive,
    double? sleepInertia,
    MirrorSignalSource? source,
  }) {
    return CircadianState(
      phaseOffsetHours: phaseOffsetHours ?? this.phaseOffsetHours,
      alertness: (alertness ?? this.alertness).clamp(0.0, 1.0),
      sleepPressure: (sleepPressure ?? this.sleepPressure).clamp(0.0, 1.0),
      circadianDrive: (circadianDrive ?? this.circadianDrive).clamp(0.0, 1.0),
      sleepInertia: (sleepInertia ?? this.sleepInertia).clamp(0.0, 1.0),
      source: source ?? this.source,
    );
  }
}

class EmbodiedPresenceContext {
  const EmbodiedPresenceContext({
    this.siteId = 'home',
    this.roomRole = 'generic',
    this.isHome = true,
  });

  final String siteId;
  final String roomRole;
  final bool isHome;
}

/// Physical movement / recovery slice (M9).
class MovementBodyState {
  const MovementBodyState({
    this.sedentarySeconds = 0,
    this.physicalFatigue = 0,
    this.recentMovementLoad = 0,
  });

  final double sedentarySeconds;
  final double physicalFatigue;
  final double recentMovementLoad;

  MovementBodyState copyWith({
    double? sedentarySeconds,
    double? physicalFatigue,
    double? recentMovementLoad,
  }) {
    return MovementBodyState(
      sedentarySeconds: sedentarySeconds ?? this.sedentarySeconds,
      physicalFatigue: (physicalFatigue ?? this.physicalFatigue).clamp(0.0, 1.0),
      recentMovementLoad:
          (recentMovementLoad ?? this.recentMovementLoad).clamp(0.0, 1.0),
    );
  }
}

enum SleepPhase {
  awake,
  windingDown,
  sleepy,
  goingToBed,
  sleeping,
  waking,
  nap,
}

class PawnEmbodiedState {
  const PawnEmbodiedState({
    required this.pawnId,
    required this.needs,
    required this.capacities,
    required this.conditions,
    required this.circadian,
    this.presence = const EmbodiedPresenceContext(),
    this.movement = const MovementBodyState(),
    this.sleepPhase = SleepPhase.awake,
    this.activeSleepEpisodeId,
  });

  final String pawnId;
  final Map<NeedKind, NeedReading> needs;
  final Map<CapacityKind, CapacityReading> capacities;
  final List<PawnCondition> conditions;
  final CircadianState circadian;
  final EmbodiedPresenceContext presence;
  final MovementBodyState movement;
  final SleepPhase sleepPhase;
  final String? activeSleepEpisodeId;

  NeedReading? need(NeedKind kind) => needs[kind];
  CapacityReading? capacity(CapacityKind kind) => capacities[kind];

  PawnEmbodiedState copyWith({
    Map<NeedKind, NeedReading>? needs,
    Map<CapacityKind, CapacityReading>? capacities,
    List<PawnCondition>? conditions,
    CircadianState? circadian,
    EmbodiedPresenceContext? presence,
    MovementBodyState? movement,
    SleepPhase? sleepPhase,
    String? activeSleepEpisodeId,
    bool clearSleepEpisode = false,
  }) {
    return PawnEmbodiedState(
      pawnId: pawnId,
      needs: needs ?? this.needs,
      capacities: capacities ?? this.capacities,
      conditions: conditions ?? this.conditions,
      circadian: circadian ?? this.circadian,
      presence: presence ?? this.presence,
      movement: movement ?? this.movement,
      sleepPhase: sleepPhase ?? this.sleepPhase,
      activeSleepEpisodeId: clearSleepEpisode
          ? null
          : (activeSleepEpisodeId ?? this.activeSleepEpisodeId),
    );
  }

  factory PawnEmbodiedState.mock(
    String pawnId, {
    DateTime? observedAt,
    EmbodiedPresenceContext? presence,
  }) {
    final at = observedAt ?? DateTime.now().toUtc();
    NeedReading n(NeedKind k, double p, {double trend = 0.02}) => NeedReading(
          kind: k,
          pressure: p,
          source: MirrorSignalSource.simulated,
          trendPerSimHour: trend,
          observedAt: at,
        );
    CapacityReading c(CapacityKind k, double v, {List<String> from = const []}) =>
        CapacityReading(
          kind: k,
          level: v,
          source: from.isEmpty
              ? MirrorSignalSource.simulated
              : MirrorSignalSource.systemDerived,
          derivedFrom: from,
          observedAt: at,
        );

    return PawnEmbodiedState(
      pawnId: pawnId,
      needs: {
        for (final k in NeedKind.values)
          k: n(
            k,
            switch (k) {
              NeedKind.sleep => 0.35,
              NeedKind.food => 0.25,
              NeedKind.movement => 0.2,
              NeedKind.rest => 0.15,
              NeedKind.socialConnection => 0.3,
              NeedKind.solitude => 0.15,
              NeedKind.recreation => 0.28,
              NeedKind.stimulation => 0.22,
              NeedKind.creativeExpression => 0.18,
              NeedKind.comfort => 0.12,
            },
          ),
      },
      capacities: {
        CapacityKind.energy: c(
          CapacityKind.energy,
          0.65,
          from: const ['need.sleep', 'circadian.alertness'],
        ),
        CapacityKind.focus: c(
          CapacityKind.focus,
          0.58,
          from: const ['capacity.energy', 'circadian.alertness'],
        ),
        CapacityKind.physicalReadiness: c(CapacityKind.physicalReadiness, 0.8),
        CapacityKind.socialTolerance: c(CapacityKind.socialTolerance, 0.7),
        CapacityKind.creativeCapacity: c(CapacityKind.creativeCapacity, 0.55),
        CapacityKind.decisionCapacity: c(CapacityKind.decisionCapacity, 0.6),
        CapacityKind.recovery: c(CapacityKind.recovery, 0.75),
      },
      conditions: const [],
      circadian: const CircadianState(),
      presence: presence ?? const EmbodiedPresenceContext(),
    );
  }
}
