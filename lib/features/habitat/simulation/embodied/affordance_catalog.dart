import 'pawn_embodied_state.dart';

/// Affordance ids used by ChoiceScorer / jobs (M5–M6).
abstract final class HabitatAffordances {
  static const sleep = 'sleep';
  static const sit = 'sit';
  static const goToTable = 'goToTable';
  static const wander = 'wander';
  static const clean = 'clean';
  static const recreate = 'recreate';
  static const stretch = 'stretch';
  static const terraceWalk = 'terraceWalk';
  static const socialChat = 'socialChat';
  static const listenMusic = 'listenMusic';
  static const creativeShort = 'creativeShort';
  static const watchTv = 'watchTv';
  static const rest = 'rest';

  static const all = <String>[
    sleep,
    sit,
    goToTable,
    wander,
    clean,
    recreate,
    stretch,
    terraceWalk,
    socialChat,
    listenMusic,
    creativeShort,
    watchTv,
    rest,
  ];
}

class AffordanceDefinition {
  const AffordanceDefinition({
    required this.id,
    this.needWeights = const {},
    this.capacityWeights = const {},
    this.sedentary = false,
    this.physicalLoad = 0,
    this.socialIntensity = 0,
    this.satisfies = const {},
  });

  final String id;
  final Map<NeedKind, double> needWeights;
  final Map<CapacityKind, double> capacityWeights;
  final bool sedentary;
  final double physicalLoad;
  final double socialIntensity;
  final Map<NeedKind, double> satisfies;
}

/// Data-driven affordance catalog (M5–M6).
abstract final class AffordanceCatalog {
  static final Map<String, AffordanceDefinition> byId = {
    HabitatAffordances.sleep: const AffordanceDefinition(
      id: HabitatAffordances.sleep,
      needWeights: {NeedKind.sleep: 1.0, NeedKind.rest: 0.4},
      capacityWeights: {
        CapacityKind.energy: 0.05,
        CapacityKind.recovery: 0.2,
      },
      satisfies: {NeedKind.sleep: 0.9, NeedKind.rest: 0.5},
    ),
    HabitatAffordances.sit: const AffordanceDefinition(
      id: HabitatAffordances.sit,
      needWeights: {NeedKind.rest: 0.6, NeedKind.comfort: 0.3},
      capacityWeights: {CapacityKind.energy: 0.05},
      sedentary: true,
      satisfies: {NeedKind.rest: 0.35, NeedKind.comfort: 0.2},
    ),
    HabitatAffordances.goToTable: const AffordanceDefinition(
      id: HabitatAffordances.goToTable,
      needWeights: {NeedKind.food: 0.7, NeedKind.socialConnection: 0.25},
      capacityWeights: {CapacityKind.energy: 0.1},
      sedentary: true,
      socialIntensity: 0.2,
      satisfies: {NeedKind.food: 0.5},
    ),
    HabitatAffordances.wander: const AffordanceDefinition(
      id: HabitatAffordances.wander,
      needWeights: {NeedKind.movement: 0.55, NeedKind.stimulation: 0.2},
      capacityWeights: {
        CapacityKind.physicalReadiness: 0.2,
        CapacityKind.energy: 0.1,
      },
      physicalLoad: 0.15,
      satisfies: {NeedKind.movement: 0.4, NeedKind.stimulation: 0.15},
    ),
    HabitatAffordances.stretch: const AffordanceDefinition(
      id: HabitatAffordances.stretch,
      needWeights: {NeedKind.movement: 0.8, NeedKind.rest: 0.2},
      capacityWeights: {CapacityKind.physicalReadiness: 0.15},
      physicalLoad: 0.25,
      satisfies: {NeedKind.movement: 0.55},
    ),
    HabitatAffordances.terraceWalk: const AffordanceDefinition(
      id: HabitatAffordances.terraceWalk,
      needWeights: {
        NeedKind.movement: 0.7,
        NeedKind.solitude: 0.25,
        NeedKind.stimulation: 0.2,
      },
      capacityWeights: {
        CapacityKind.physicalReadiness: 0.25,
        CapacityKind.energy: 0.15,
      },
      physicalLoad: 0.35,
      satisfies: {NeedKind.movement: 0.6, NeedKind.solitude: 0.2},
    ),
    HabitatAffordances.recreate: const AffordanceDefinition(
      id: HabitatAffordances.recreate,
      needWeights: {
        NeedKind.recreation: 0.85,
        NeedKind.stimulation: 0.3,
      },
      capacityWeights: {
        CapacityKind.focus: 0.1,
        CapacityKind.energy: 0.1,
      },
      sedentary: true,
      satisfies: {NeedKind.recreation: 0.55, NeedKind.stimulation: 0.25},
    ),
    HabitatAffordances.listenMusic: const AffordanceDefinition(
      id: HabitatAffordances.listenMusic,
      needWeights: {
        NeedKind.recreation: 0.5,
        NeedKind.creativeExpression: 0.35,
        NeedKind.solitude: 0.2,
      },
      capacityWeights: {
        CapacityKind.creativeCapacity: 0.15,
        CapacityKind.focus: 0.05,
      },
      sedentary: true,
      satisfies: {
        NeedKind.recreation: 0.35,
        NeedKind.creativeExpression: 0.3,
      },
    ),
    HabitatAffordances.creativeShort: const AffordanceDefinition(
      id: HabitatAffordances.creativeShort,
      needWeights: {NeedKind.creativeExpression: 0.9},
      capacityWeights: {
        CapacityKind.creativeCapacity: 0.35,
        CapacityKind.focus: 0.25,
        CapacityKind.energy: 0.15,
        CapacityKind.recovery: 0.05,
      },
      sedentary: true,
      satisfies: {NeedKind.creativeExpression: 0.5},
    ),
    HabitatAffordances.watchTv: const AffordanceDefinition(
      id: HabitatAffordances.watchTv,
      needWeights: {NeedKind.recreation: 0.45, NeedKind.rest: 0.25},
      capacityWeights: {
        CapacityKind.energy: 0.05,
        CapacityKind.focus: 0.05,
      },
      sedentary: true,
      satisfies: {NeedKind.recreation: 0.3, NeedKind.rest: 0.15},
    ),
    HabitatAffordances.socialChat: const AffordanceDefinition(
      id: HabitatAffordances.socialChat,
      needWeights: {NeedKind.socialConnection: 0.9},
      capacityWeights: {
        CapacityKind.socialTolerance: 0.4,
        CapacityKind.energy: 0.1,
      },
      socialIntensity: 0.35,
      satisfies: {NeedKind.socialConnection: 0.45, NeedKind.solitude: -0.15},
    ),
    HabitatAffordances.clean: const AffordanceDefinition(
      id: HabitatAffordances.clean,
      needWeights: {NeedKind.comfort: 0.4, NeedKind.movement: 0.2},
      capacityWeights: {
        CapacityKind.physicalReadiness: 0.2,
        CapacityKind.energy: 0.2,
      },
      physicalLoad: 0.3,
      satisfies: {NeedKind.comfort: 0.35},
    ),
    HabitatAffordances.rest: const AffordanceDefinition(
      id: HabitatAffordances.rest,
      needWeights: {NeedKind.rest: 0.85, NeedKind.comfort: 0.3},
      capacityWeights: {CapacityKind.recovery: 0.25},
      sedentary: true,
      satisfies: {NeedKind.rest: 0.5},
    ),
  };

  static AffordanceDefinition? get(String id) => byId[id];
}

/// Scores affordances from needs + capacities + conditions (M5–M6).
class ChoiceScorer {
  const ChoiceScorer();

  double score({
    required String affordanceId,
    required PawnEmbodiedState state,
  }) {
    final def = AffordanceCatalog.get(affordanceId);
    if (def == null) return 0;

    var needScore = 0.0;
    var needW = 0.0;
    for (final e in def.needWeights.entries) {
      final p = state.need(e.key)?.pressure ?? 0;
      needScore += p * e.value;
      needW += e.value;
    }
    if (needW > 0) needScore /= needW;

    var ready = 1.0;
    if (def.capacityWeights.isNotEmpty) {
      ready = readinessFor(def, state);
    }

    var condMod = 1.0;
    for (final c in state.conditions) {
      final m = c.affordanceModifiers[affordanceId];
      if (m != null) condMod *= (1 + m * c.intensity);
    }
    condMod = condMod.clamp(0.25, 2.0);

    // Caps: one need cannot fully dominate.
    final cappedNeed = 0.25 + needScore * 0.75;
    return (cappedNeed * (0.35 + 0.65 * ready) * condMod).clamp(0.0, 1.5);
  }

  /// Contextual readiness — not a single global score (M6).
  double readinessFor(AffordanceDefinition def, PawnEmbodiedState state) {
    if (def.capacityWeights.isEmpty) return 1;
    var sum = 0.0;
    var w = 0.0;
    for (final e in def.capacityWeights.entries) {
      var level = state.capacity(e.key)?.level ?? 0.5;
      for (final c in state.conditions) {
        final m = c.capacityModifiers[e.key];
        if (m != null) level = (level + m * c.intensity).clamp(0.0, 1.0);
      }
      sum += level * e.value;
      w += e.value;
    }
    return w <= 0 ? 1 : (sum / w).clamp(0.0, 1.0);
  }

  /// Ranked affordance ids for autonomous choice.
  List<({String id, double score})> rank(
    PawnEmbodiedState state, {
    Iterable<String>? candidates,
    double Function(String affordanceId)? noveltyBonus,
    double personalityOpenness = 0.5,
    double personalityExtraversion = 0.5,
    double? jazzAffinity,
    Set<String> topicBoostIds = const {},
  }) {
    final ids = candidates ?? HabitatAffordances.all;
    final scored = [
      for (final id in ids)
        (
          id: id,
          score: score(
                affordanceId: id,
                state: state,
              ) *
              _personalityScale(id, personalityOpenness, personalityExtraversion) *
              (1 + 0.2 * (noveltyBonus?.call(id) ?? 0)) *
              _preferenceScale(id, jazzAffinity) *
              (topicBoostIds.contains(id) ? 1.35 : 1.0),
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  double _personalityScale(String id, double openness, double extraversion) {
    var m = 1.0;
    if (id == HabitatAffordances.socialChat) {
      m *= 0.7 + 0.6 * extraversion;
    }
    if (id == HabitatAffordances.creativeShort ||
        id == HabitatAffordances.listenMusic) {
      m *= 0.75 + 0.5 * openness;
    }
    return m;
  }

  double _preferenceScale(String id, double? jazzAffinity) {
    if (jazzAffinity == null) return 1;
    if (id == HabitatAffordances.listenMusic) {
      return 0.85 + 0.4 * jazzAffinity;
    }
    return 1;
  }
}
