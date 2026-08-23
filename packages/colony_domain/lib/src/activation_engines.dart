import 'activation_enums.dart';
import 'activation_models.dart';
import 'enums.dart';
import 'id_generator.dart';
import 'work_enums.dart';

/// Gramática de comandos (§17). Rejeita linguagem moral e abstrata.
abstract final class ActivationCommandGrammar {
  static const prohibitedFragments = [
    'seja produtivo',
    'tenha disciplina',
    'pare de procrastinar',
    'faça sua rotina',
    'comece tudo',
    'recupere o tempo perdido',
    'você consegue',
    'você falhou',
    'força de vontade',
    'streak',
  ];

  static const abstractVerbs = [
    'organize-se',
    'estude',
    'foque',
    'mantenha o foco',
    'seja',
    'tenha',
  ];

  static String? rejectReason(String instruction) {
    final normalized = instruction.trim().toLowerCase();
    if (normalized.isEmpty) return 'empty';
    for (final fragment in prohibitedFragments) {
      if (normalized.contains(fragment)) return 'prohibited:$fragment';
    }
    for (final verb in abstractVerbs) {
      if (normalized == verb || normalized.startsWith('$verb ')) {
        return 'abstract:$verb';
      }
    }
    return null;
  }

  static bool isConcrete(String instruction) =>
      rejectReason(instruction) == null;

  static bool startsWithVerb(String instruction) {
    final trimmed = instruction.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[A-ZÁÉÍÓÚÂÊÔÃÕÇ]').hasMatch(trimmed);
  }
}

/// Máquina de estados do episódio (§12).
abstract final class ActivationEpisodeMachine {
  static const _allowed = <ActivationEpisodeStatus, Set<ActivationEpisodeStatus>>{
    ActivationEpisodeStatus.proposed: {
      ActivationEpisodeStatus.active,
      ActivationEpisodeStatus.dismissed,
      ActivationEpisodeStatus.falsePositive,
    },
    ActivationEpisodeStatus.active: {
      ActivationEpisodeStatus.mobilizing,
      ActivationEpisodeStatus.paused,
      ActivationEpisodeStatus.aborted,
      ActivationEpisodeStatus.convertedToRecovery,
      ActivationEpisodeStatus.falsePositive,
      ActivationEpisodeStatus.released,
    },
    ActivationEpisodeStatus.mobilizing: {
      ActivationEpisodeStatus.mobilizing,
      ActivationEpisodeStatus.adapted,
      ActivationEpisodeStatus.released,
      ActivationEpisodeStatus.paused,
      ActivationEpisodeStatus.aborted,
      ActivationEpisodeStatus.convertedToRecovery,
      ActivationEpisodeStatus.falsePositive,
    },
    ActivationEpisodeStatus.adapted: {
      ActivationEpisodeStatus.mobilizing,
      ActivationEpisodeStatus.released,
      ActivationEpisodeStatus.paused,
      ActivationEpisodeStatus.aborted,
      ActivationEpisodeStatus.convertedToRecovery,
    },
    ActivationEpisodeStatus.paused: {
      ActivationEpisodeStatus.mobilizing,
      ActivationEpisodeStatus.expired,
      ActivationEpisodeStatus.aborted,
      ActivationEpisodeStatus.convertedToRecovery,
      ActivationEpisodeStatus.released,
      ActivationEpisodeStatus.falsePositive,
    },
    ActivationEpisodeStatus.released: {},
    ActivationEpisodeStatus.aborted: {},
    ActivationEpisodeStatus.convertedToRecovery: {},
    ActivationEpisodeStatus.falsePositive: {},
    ActivationEpisodeStatus.expired: {},
    ActivationEpisodeStatus.dismissed: {},
  };

  static bool canTransition(
    ActivationEpisodeStatus from,
    ActivationEpisodeStatus to,
  ) {
    if (from == to && from == ActivationEpisodeStatus.mobilizing) return true;
    return _allowed[from]?.contains(to) ?? false;
  }
}

/// Máquina de estados do command run (§65.1).
abstract final class ActivationCommandRunMachine {
  static const _allowed =
      <ActivationCommandRunStatus, Set<ActivationCommandRunStatus>>{
    ActivationCommandRunStatus.pending: {
      ActivationCommandRunStatus.presented,
      ActivationCommandRunStatus.cancelled,
    },
    ActivationCommandRunStatus.presented: {
      ActivationCommandRunStatus.evidencePending,
      ActivationCommandRunStatus.confirmed,
      ActivationCommandRunStatus.skipped,
      ActivationCommandRunStatus.adapted,
      ActivationCommandRunStatus.cancelled,
    },
    ActivationCommandRunStatus.evidencePending: {
      ActivationCommandRunStatus.confirmed,
      ActivationCommandRunStatus.uncertain,
      ActivationCommandRunStatus.adapted,
      ActivationCommandRunStatus.cancelled,
    },
    ActivationCommandRunStatus.uncertain: {
      ActivationCommandRunStatus.confirmed,
      ActivationCommandRunStatus.presented,
      ActivationCommandRunStatus.skipped,
      ActivationCommandRunStatus.cancelled,
    },
    ActivationCommandRunStatus.confirmed: {},
    ActivationCommandRunStatus.skipped: {},
    ActivationCommandRunStatus.adapted: {},
    ActivationCommandRunStatus.cancelled: {},
  };

  static bool canTransition(
    ActivationCommandRunStatus from,
    ActivationCommandRunStatus to,
  ) {
    return _allowed[from]?.contains(to) ?? false;
  }
}

/// Máquina do escudo (§65.2).
abstract final class FrictionShieldMachine {
  static const _allowed = <FrictionShieldState, Set<FrictionShieldState>>{
    FrictionShieldState.inactive: {FrictionShieldState.armed},
    FrictionShieldState.armed: {
      FrictionShieldState.active,
      FrictionShieldState.disabled,
    },
    FrictionShieldState.active: {
      FrictionShieldState.temporarilyReleased,
      FrictionShieldState.released,
      FrictionShieldState.disabled,
    },
    FrictionShieldState.temporarilyReleased: {
      FrictionShieldState.active,
      FrictionShieldState.released,
      FrictionShieldState.disabled,
    },
    FrictionShieldState.released: {},
    FrictionShieldState.disabled: {},
  };

  static bool canTransition(FrictionShieldState from, FrictionShieldState to) {
    return _allowed[from]?.contains(to) ?? false;
  }
}

/// Score inspecionável de inércia (§66.1). Nunca vira score moral.
class InertiaHypothesisScorer {
  const InertiaHypothesisScorer();

  InertiaHypothesis score({
    required InertiaHypothesisType type,
    double scheduleWindowWeight = 0,
    double alarmTransitionWeight = 0,
    double stationaryWeight = 0,
    double distractingUsageWeight = 0,
    double historicalContextWeight = 0,
    double explicitGoalWeight = 0,
    double plannedRestWeight = 0,
    double lowDataPenalty = 0,
    double falsePositiveContextPenalty = 0,
  }) {
    final breakdown = <String, double>{
      'schedule_window': scheduleWindowWeight,
      'alarm_transition': alarmTransitionWeight,
      'stationary': stationaryWeight,
      'distracting_usage': distractingUsageWeight,
      'historical_context': historicalContextWeight,
      'explicit_goal': explicitGoalWeight,
      'planned_rest': -plannedRestWeight,
      'low_data_penalty': -lowDataPenalty,
      'false_positive_context': -falsePositiveContextPenalty,
    };
    final raw = breakdown.values.fold<double>(0, (sum, item) => sum + item);
    final confidence = raw.clamp(0.0, 1.0);
    final counter = <String>[
      if (plannedRestWeight > 0) 'planned_rest',
      if (lowDataPenalty > 0) 'low_data',
      if (falsePositiveContextPenalty > 0) 'prior_false_positive',
    ];
    return InertiaHypothesis(
      type: type,
      confidence: confidence,
      breakdown: breakdown,
      counterevidence: counter,
    );
  }

  /// Auto-start só com autorização prévia e confiança alta.
  bool mayPropose(InertiaHypothesis hypothesis, {required bool plannedRest}) {
    if (plannedRest) return false;
    return hypothesis.confidence >= ActivationProofConfidence.mediumThreshold &&
        hypothesis.band != ConfidenceLevel.insufficient;
  }
}

/// Seleção de protocolo (§66.2).
class ActivationProtocolSelector {
  const ActivationProtocolSelector();

  ActivationProtocolBundle? select({
    required List<ActivationProtocolBundle> candidates,
    required ActivationCapacityMode capacity,
    InertiaHypothesisType? hypothesis,
    ActivationProtocolType? preferredType,
  }) {
    if (candidates.isEmpty) return null;
    ActivationProtocolBundle? best;
    var bestScore = double.negativeInfinity;
    for (final candidate in candidates) {
      if (!candidate.protocol.isEnabled) continue;
      final score = utility(
        candidate,
        capacity: capacity,
        hypothesis: hypothesis,
        preferredType: preferredType,
      );
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best;
  }

  double utility(
    ActivationProtocolBundle bundle, {
    required ActivationCapacityMode capacity,
    InertiaHypothesisType? hypothesis,
    ActivationProtocolType? preferredType,
  }) {
    final protocol = bundle.protocol;
    var contextMatch = preferredType == null
        ? 0.4
        : (protocol.protocolType == preferredType ? 1.0 : 0.1);
    if (hypothesis != null) {
      contextMatch += _hypothesisFit(protocol.protocolType, hypothesis);
    }
    final capacityFit = _capacityFit(protocol, capacity);
    final decisionLoad = bundle.commands.length / 12.0;
    final proofAvailability = bundle.commands.every(
      (c) => c.proofPolicy.fallback == ActivationProofType.manualTap,
    )
        ? 0.4
        : 0.2;
    return contextMatch +
        capacityFit +
        0.3 +
        proofAvailability -
        decisionLoad -
        0.1;
  }

  double _hypothesisFit(
    ActivationProtocolType type,
    InertiaHypothesisType hypothesis,
  ) {
    return switch ((type, hypothesis)) {
      (ActivationProtocolType.wakeUp, InertiaHypothesisType.morningBedInertia) =>
        0.5,
      (ActivationProtocolType.hygiene, InertiaHypothesisType.showerResistance) =>
        0.5,
      (ActivationProtocolType.departure, InertiaHypothesisType.departureFreeze) =>
        0.5,
      (ActivationProtocolType.antiScroll, InertiaHypothesisType.antiScroll) =>
        0.5,
      (ActivationProtocolType.workStart, InertiaHypothesisType.preTaskAvoidance) =>
        0.4,
      (ActivationProtocolType.studyStart, InertiaHypothesisType.preTaskAvoidance) =>
        0.4,
      _ => 0.0,
    };
  }

  double _capacityFit(
    ActivationProtocol protocol,
    ActivationCapacityMode capacity,
  ) {
    final seed = protocol.seedKey ?? '';
    return switch (capacity) {
      ActivationCapacityMode.lowCapacity ||
      ActivationCapacityMode.emergencyMinimum =>
        seed.contains('minimal') || seed.contains('reset') ? 0.5 : 0.1,
      ActivationCapacityMode.highEnergy =>
        seed.contains('standard') || seed.contains('code') ? 0.4 : 0.2,
      ActivationCapacityMode.standard =>
        seed.contains('standard')
            ? 0.5
            : seed.contains('minimal')
                ? 0.15
                : 0.3,
    };
  }
}

/// Compila templates em fila física (§16, §66.3).
class ActivationCommandCompiler {
  const ActivationCommandCompiler();

  List<ActivationCommandTemplate> compile({
    required List<ActivationCommandTemplate> templates,
    required ActivationCapacityMode capacity,
    List<ActivationCommandTemplate> fallbackMinimal = const [],
  }) {
    final ordered = [...templates]
      ..sort((a, b) => a.sequenceKey.compareTo(b.sequenceKey));
    final source = switch (capacity) {
      ActivationCapacityMode.lowCapacity ||
      ActivationCapacityMode.emergencyMinimum
          when fallbackMinimal.isNotEmpty =>
        [...fallbackMinimal]
          ..sort((a, b) => a.sequenceKey.compareTo(b.sequenceKey)),
      _ => ordered,
    };

    final validated = [
      for (final command in source)
        if (ActivationCommandGrammar.isConcrete(command.instruction)) command,
    ];
    if (validated.isEmpty) return source;

    if (capacity == ActivationCapacityMode.emergencyMinimum &&
        validated.length > 3) {
      return validated.take(2).toList();
    }
    if (capacity == ActivationCapacityMode.highEnergy &&
        validated.length >= 4) {
      return _compress(validated);
    }
    return validated;
  }

  List<ActivationCommandTemplate> adapt({
    required ActivationCommandTemplate current,
    required int nextSequence,
    required EntityId Function() newId,
  }) {
    final splits = current.fallback.splitInstructions
        .where(ActivationCommandGrammar.isConcrete)
        .toList();
    if (splits.isEmpty) {
      return [
        ActivationCommandTemplate(
          id: newId(),
          protocolId: current.protocolId,
          protocolVersion: current.protocolVersion,
          sequenceKey: _seq(nextSequence),
          instruction: current.instruction,
          actionVerb: current.actionVerb,
          objectRef: current.objectRef,
          destinationRef: current.destinationRef,
          proofPolicy: current.proofPolicy,
          timeoutPolicy: current.timeoutPolicy,
          skippable: current.skippable,
          estimatedSeconds: current.estimatedSeconds,
          isFirstMeaningfulAction: current.isFirstMeaningfulAction,
          releasesOnConfirm: current.releasesOnConfirm,
        ),
      ];
    }
    return [
      for (var i = 0; i < splits.length; i++)
        ActivationCommandTemplate(
          id: newId(),
          protocolId: current.protocolId,
          protocolVersion: current.protocolVersion,
          sequenceKey: _seq(nextSequence + i),
          instruction: splits[i],
          actionVerb: _firstWord(splits[i]),
          proofPolicy: current.proofPolicy,
          skippable: true,
          estimatedSeconds: 30,
          isFirstMeaningfulAction:
              current.isFirstMeaningfulAction && i == splits.length - 1,
          releasesOnConfirm:
              current.releasesOnConfirm && i == splits.length - 1,
        ),
    ];
  }

  List<ActivationCommandTemplate> _compress(
    List<ActivationCommandTemplate> commands,
  ) {
    if (commands.length < 2) return commands;
    final first = commands.first;
    final second = commands[1];
    final merged = ActivationCommandTemplate(
      id: first.id,
      protocolId: first.protocolId,
      protocolVersion: first.protocolVersion,
      sequenceKey: first.sequenceKey,
      instruction: '${first.instruction} ${second.instruction}',
      actionVerb: first.actionVerb,
      objectRef: first.objectRef,
      destinationRef: second.destinationRef ?? first.destinationRef,
      proofPolicy: second.proofPolicy,
      skippable: first.skippable && second.skippable,
      estimatedSeconds:
          (first.estimatedSeconds ?? 60) + (second.estimatedSeconds ?? 60),
      isFirstMeaningfulAction:
          first.isFirstMeaningfulAction || second.isFirstMeaningfulAction,
      releasesOnConfirm: first.releasesOnConfirm || second.releasesOnConfirm,
    );
    if (!ActivationCommandGrammar.isConcrete(merged.instruction)) {
      return commands;
    }
    return [merged, ...commands.skip(2)];
  }

  static String _seq(int index) => index.toString().padLeft(2, '0');

  static String _firstWord(String instruction) {
    final parts = instruction.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Faça' : parts.first;
  }
}

/// Agrega provas (§22, ADR-ACT-003). Confiança da evidência, não do usuário.
class ActivationProofEngine {
  const ActivationProofEngine();

  double aggregate(Iterable<ActivationProof> proofs) {
    final items = proofs.toList();
    if (items.isEmpty) return 0;
    final sorted = [...items]..sort((a, b) => a.confidence.compareTo(b.confidence));
    if (sorted.length.isOdd) {
      return sorted[sorted.length ~/ 2].confidence;
    }
    final mid = sorted.length ~/ 2;
    return (sorted[mid - 1].confidence + sorted[mid].confidence) / 2;
  }

  bool isSufficient(Iterable<ActivationProof> proofs, double threshold) {
    return aggregate(proofs) >= threshold;
  }

  ActivationCommandRunStatus nextStatus({
    required ActivationCommandRunStatus current,
    required double confidence,
    required double threshold,
    required bool userOverride,
  }) {
    if (userOverride) return ActivationCommandRunStatus.confirmed;
    if (confidence >= threshold) return ActivationCommandRunStatus.confirmed;
    if (confidence >= ActivationProofConfidence.lowThreshold) {
      return ActivationCommandRunStatus.uncertain;
    }
    return current == ActivationCommandRunStatus.presented
        ? ActivationCommandRunStatus.evidencePending
        : current;
  }
}

class ActivationReleaseDecision {
  const ActivationReleaseDecision({
    required this.shouldRelease,
    required this.reason,
  });

  final bool shouldRelease;
  final String reason;
}

/// Condições suficientes, não perfeitas (§66.4).
class ActivationReleaseEvaluator {
  const ActivationReleaseEvaluator();

  ActivationReleaseDecision evaluate({
    required ActivationReleaseConditions conditions,
    required ActivationEpisode episode,
    required List<ActivationCommandRun> runs,
    required bool explicitRelease,
    required bool recoveryStarted,
    Duration? firstMeaningfulActionDuration,
  }) {
    if (explicitRelease && conditions.allowExplicitRelease) {
      return const ActivationReleaseDecision(
        shouldRelease: true,
        reason: 'explicit_release',
      );
    }
    if (recoveryStarted && conditions.allowRecoveryRelease) {
      return const ActivationReleaseDecision(
        shouldRelease: true,
        reason: 'recovery_plan_started',
      );
    }
    final meaningful = runs.where((r) => r.isFirstMeaningfulAction);
    if (conditions.requireFirstMeaningfulAction &&
        meaningful.any((r) => r.status == ActivationCommandRunStatus.confirmed)) {
      final duration = firstMeaningfulActionDuration ?? Duration.zero;
      if (duration.inSeconds >= conditions.minimumMeaningfulSeconds ||
          meaningful.any((r) => r.confirmationMode != null)) {
        return const ActivationReleaseDecision(
          shouldRelease: true,
          reason: 'first_meaningful_action',
        );
      }
    }
    if (runs.isNotEmpty &&
        runs.any((r) => r.status == ActivationCommandRunStatus.confirmed) &&
        runs
            .where((r) => r.status == ActivationCommandRunStatus.confirmed)
            .any((r) => r.isFirstMeaningfulAction == false) &&
        runs.every((r) => r.status.isClosed) &&
        runs.any((r) => r.isFirstMeaningfulAction)) {
      return const ActivationReleaseDecision(
        shouldRelease: true,
        reason: 'route_complete_with_meaningful_action',
      );
    }
    if (runs.isNotEmpty &&
        runs.every((r) => r.status.isClosed) &&
        runs.any((r) => r.status == ActivationCommandRunStatus.confirmed)) {
      final last = [...runs]..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
      if (last.last.isFirstMeaningfulAction ||
          last.last.status == ActivationCommandRunStatus.confirmed) {
        return const ActivationReleaseDecision(
          shouldRelease: true,
          reason: 'target_state_proof',
        );
      }
    }
    return const ActivationReleaseDecision(
      shouldRelease: false,
      reason: 'insufficient',
    );
  }
}

/// Escada adaptativa (§29). Sobe só após timeout/ignorado; desce após sucesso.
class ActivationInterventionPolicy {
  const ActivationInterventionPolicy();

  static const dailyBudget = 6;

  ActivationInterventionLevel nextLevel({
    required ActivationInterventionLevel current,
    required bool commandTimedOut,
    required bool userIgnored,
    required bool commandConfirmed,
  }) {
    if (commandConfirmed) {
      return switch (current) {
        ActivationInterventionLevel.shield => ActivationInterventionLevel.route,
        ActivationInterventionLevel.route => ActivationInterventionLevel.oneCommand,
        ActivationInterventionLevel.oneCommand => ActivationInterventionLevel.letter,
        _ => ActivationInterventionLevel.silent,
      };
    }
    if (commandTimedOut || userIgnored) {
      return switch (current) {
        ActivationInterventionLevel.silent => ActivationInterventionLevel.badge,
        ActivationInterventionLevel.badge => ActivationInterventionLevel.letter,
        ActivationInterventionLevel.letter =>
          ActivationInterventionLevel.oneCommand,
        ActivationInterventionLevel.oneCommand => ActivationInterventionLevel.route,
        ActivationInterventionLevel.route => ActivationInterventionLevel.shield,
        ActivationInterventionLevel.shield => ActivationInterventionLevel.shield,
      };
    }
    return current;
  }

  bool withinBudget(int interventionsToday) => interventionsToday < dailyBudget;
}

/// Experimentos N-of-1 (§41). Sem causalidade.
class ActivationExperimentAnalyzer {
  const ActivationExperimentAnalyzer();

  String pickVariant({
    required ActivationExperiment experiment,
    required int assignmentCount,
  }) {
    if (experiment.variants.isEmpty) return 'control';
    return experiment.variants[assignmentCount % experiment.variants.length];
  }

  ActivationInsight? analyze({
    required EntityId insightId,
    required EntityId profileId,
    required ActivationExperiment experiment,
    required Map<String, List<Duration>> latencyByVariant,
    required DateTime now,
  }) {
    if (latencyByVariant.values.fold<int>(0, (sum, list) => sum + list.length) <
        experiment.minimumSamples) {
      return null;
    }
    String? best;
    Duration? bestMedian;
    for (final entry in latencyByVariant.entries) {
      if (entry.value.isEmpty) continue;
      final median = _median(entry.value);
      if (bestMedian == null || median < bestMedian) {
        bestMedian = median;
        best = entry.key;
      }
    }
    if (best == null || bestMedian == null) return null;
    final samples = latencyByVariant.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    return ActivationInsight(
      id: insightId,
      profileId: profileId,
      title: experiment.name,
      body:
          'A variante "$best" está associada a latência mediana de '
          '${bestMedian.inMinutes} min. '
          '${ActivationInsight.causalityDisclaimer}',
      createdAt: now,
      sampleSize: samples,
      confidence: samples >= experiment.minimumSamples * 2
          ? ConfidenceLevel.medium
          : ConfidenceLevel.low,
    );
  }

  Duration _median(List<Duration> values) {
    final sorted = [...values]..sort((a, b) => a.compareTo(b));
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return Duration(
      milliseconds:
          ((sorted[mid - 1].inMilliseconds + sorted[mid].inMilliseconds) / 2)
              .round(),
    );
  }
}

/// Assistente local de mobilização (§61). Sem LLM.
class ActivationLocalAssistant {
  const ActivationLocalAssistant();

  List<String> compileIntent(String intent) {
    final normalized = intent.trim().toLowerCase();
    if (normalized.contains('estud')) {
      return const [
        'Levante-se da cadeira atual.',
        'Leve água até a mesa.',
        'Coloque o telefone no dock.',
        'Abra o material exato.',
        'Leia apenas o primeiro enunciado.',
        'Escreva o que a questão pede.',
      ];
    }
    if (normalized.contains('trabalh') || normalized.contains('código') ||
        normalized.contains('codigo')) {
      return const [
        'Coloque o telefone no dock.',
        'Abra o workspace já escolhido.',
        'Abra o arquivo ou issue definido.',
        'Leia a nota de continuidade.',
        'Faça a primeira mudança visível.',
      ];
    }
    if (normalized.contains('banho')) {
      return const [
        'Coloque os dois pés no chão.',
        'Leve o telefone ao dock do banheiro.',
        'Abra o chuveiro.',
      ];
    }
    return const [
      'Coloque os dois pés no chão.',
      'Fique em pé.',
      'Dê três passos para fora do lugar atual.',
    ];
  }

  List<String> validate(List<String> instructions) {
    return [
      for (final instruction in instructions)
        if (ActivationCommandGrammar.isConcrete(instruction)) instruction,
    ];
  }
}

/// Capacidade de plataforma descrita, nunca prometida.
class ActivationPlatformCapability {
  const ActivationPlatformCapability({
    required this.platform,
    required this.canExactAlarm,
    required this.canSteps,
    required this.canUsageStats,
    required this.canAppShield,
    required this.canNfc,
    required this.watchCommands,
    required this.homeAutomation,
  });

  final String platform;
  final bool canExactAlarm;
  final bool canSteps;
  final bool canUsageStats;
  final bool canAppShield;
  final bool canNfc;
  final bool watchCommands;
  final bool homeAutomation;

  static const desktop = ActivationPlatformCapability(
    platform: 'desktop',
    canExactAlarm: false,
    canSteps: false,
    canUsageStats: false,
    canAppShield: false,
    canNfc: false,
    watchCommands: false,
    homeAutomation: false,
  );

  static const androidConservative = ActivationPlatformCapability(
    platform: 'android',
    canExactAlarm: false,
    canSteps: false,
    canUsageStats: false,
    canAppShield: false,
    canNfc: false,
    watchCommands: false,
    homeAutomation: false,
  );

  static const iosConservative = ActivationPlatformCapability(
    platform: 'ios',
    canExactAlarm: false,
    canSteps: false,
    canUsageStats: false,
    canAppShield: false,
    canNfc: false,
    watchCommands: false,
    homeAutomation: false,
  );
}

class ActivationStuckChoice {
  const ActivationStuckChoice({
    required this.protocolType,
    required this.label,
  });

  final ActivationProtocolType protocolType;
  final String label;
}

/// Fluxo "Estou travado agora": no máximo duas escolhas (§39).
abstract final class ActivationStuckNowPolicy {
  static List<ActivationStuckChoice> choices({
    required DateTime now,
    required bool hasUpcomingFocus,
  }) {
    final hour = now.toLocal().hour;
    if (hour < 11) {
      return const [
        ActivationStuckChoice(
          protocolType: ActivationProtocolType.wakeUp,
          label: 'Começar o dia',
        ),
        ActivationStuckChoice(
          protocolType: ActivationProtocolType.hygiene,
          label: 'Ir ao banho',
        ),
      ];
    }
    if (hasUpcomingFocus || (hour >= 11 && hour < 18)) {
      return const [
        ActivationStuckChoice(
          protocolType: ActivationProtocolType.workStart,
          label: 'Começar a primeira ação',
        ),
        ActivationStuckChoice(
          protocolType: ActivationProtocolType.studyStart,
          label: 'Começar a estudar',
        ),
      ];
    }
    if (hour >= 21) {
      return const [
        ActivationStuckChoice(
          protocolType: ActivationProtocolType.sleepPreparation,
          label: 'Preparar o terreno',
        ),
        ActivationStuckChoice(
          protocolType: ActivationProtocolType.antiScroll,
          label: 'Sair da tela',
        ),
      ];
    }
    return const [
      ActivationStuckChoice(
        protocolType: ActivationProtocolType.antiScroll,
        label: 'Sair da tela',
      ),
      ActivationStuckChoice(
        protocolType: ActivationProtocolType.houseReset,
        label: 'Reset curto',
      ),
    ];
  }
}

class HomeAutomationDryRun {
  const HomeAutomationDryRun({
    required this.sceneId,
    required this.action,
    required this.reversible,
  });

  final String sceneId;
  final String action;
  final bool reversible;
}

/// Adapter local: só dry-run até ADR-ACT-010 + consentimento.
abstract final class ActivationHomeAutomationPolicy {
  static HomeAutomationDryRun dryRun(ActivationScene scene) {
    return HomeAutomationDryRun(
      sceneId: scene.id.value,
      action: 'simulate:${scene.kind.name}',
      reversible: true,
    );
  }
}

/// Janela de agenda usada pela detecção conservadora (§13, §55).
class ActivationScheduleContext {
  const ActivationScheduleContext({
    required this.plannedRest,
    required this.morningWindow,
    required this.hasUpcomingFocus,
    this.restingDeclared = false,
  });

  final bool plannedRest;
  final bool morningWindow;
  final bool hasUpcomingFocus;
  final bool restingDeclared;

  bool get blocksAutoStart => plannedRest || restingDeclared;

  factory ActivationScheduleContext.fromBlocks({
    required DateTime now,
    required Iterable<ScheduleBlockMode> currentModes,
    required bool hasUpcomingFocus,
    bool restingDeclared = false,
  }) {
    final hour = now.toLocal().hour;
    return ActivationScheduleContext(
      plannedRest: currentModes.contains(ScheduleBlockMode.sleep) ||
          currentModes.contains(ScheduleBlockMode.recovery),
      morningWindow: hour >= 5 && hour < 11,
      hasUpcomingFocus: hasUpcomingFocus,
      restingDeclared: restingDeclared,
    );
  }
}

class ActivationDetectionProposal {
  const ActivationDetectionProposal({
    required this.hypothesis,
    required this.preferredType,
    required this.mayPropose,
  });

  final InertiaHypothesis hypothesis;
  final ActivationProtocolType preferredType;
  final bool mayPropose;
}

/// Detecção conservadora: sem sensores, sem auto-start em descanso.
class ActivationConservativeDetector {
  const ActivationConservativeDetector();

  ActivationDetectionProposal evaluate({
    required ActivationScheduleContext schedule,
    required bool explicitStuck,
    required int recentFalsePositives,
    required bool autoStartAuthorized,
  }) {
    const scorer = InertiaHypothesisScorer();
    final type = schedule.morningWindow
        ? InertiaHypothesisType.morningBedInertia
        : schedule.hasUpcomingFocus
            ? InertiaHypothesisType.preTaskAvoidance
            : InertiaHypothesisType.unknown;
    final hypothesis = scorer.score(
      type: type,
      scheduleWindowWeight: schedule.morningWindow ? 0.35 : 0.15,
      explicitGoalWeight: explicitStuck ? 0.5 : 0,
      plannedRestWeight: schedule.blocksAutoStart ? 0.9 : 0,
      falsePositiveContextPenalty: recentFalsePositives > 0 ? 0.4 : 0,
      lowDataPenalty: explicitStuck ? 0 : 0.25,
    );
    final preferred = switch (type) {
      InertiaHypothesisType.morningBedInertia =>
        ActivationProtocolType.wakeUp,
      InertiaHypothesisType.preTaskAvoidance =>
        ActivationProtocolType.workStart,
      InertiaHypothesisType.antiScroll => ActivationProtocolType.antiScroll,
      _ => ActivationProtocolType.antiScroll,
    };
    final mayPropose = !schedule.blocksAutoStart &&
        (explicitStuck ||
            (autoStartAuthorized &&
                scorer.mayPropose(hypothesis, plannedRest: false)));
    return ActivationDetectionProposal(
      hypothesis: hypothesis,
      preferredType: preferred,
      mayPropose: mayPropose,
    );
  }
}

/// Maturidade da rota: encolhe com uso, nunca vira score moral.
abstract final class ActivationRouteMaturityEvaluator {
  static ActivationRouteMaturity evaluate({
    required int releasedCount,
    required int adaptedCount,
  }) {
    if (releasedCount >= 12 && adaptedCount == 0) {
      return ActivationRouteMaturity.internalized;
    }
    if (releasedCount >= 8) return ActivationRouteMaturity.compressible;
    if (releasedCount >= 3) return ActivationRouteMaturity.reliable;
    return ActivationRouteMaturity.experimental;
  }
}

/// Resgate social: o núcleo nunca transmite (ADR-ACT-012).
abstract final class ActivationRescuePolicy {
  static bool mayTransmit({
    required bool previouslyAuthorized,
    required bool confirmedNow,
  }) {
    return false;
  }

  static RescueContractStatus arm(RescueContractStatus current) {
    return current == RescueContractStatus.inactive
        ? RescueContractStatus.armed
        : current;
  }
}
