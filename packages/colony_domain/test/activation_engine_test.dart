import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ActivationCommandGrammar', () {
    test('rejects moral and abstract instructions', () {
      expect(
        ActivationCommandGrammar.rejectReason('Seja produtivo.'),
        isNotNull,
      );
      expect(
        ActivationCommandGrammar.rejectReason('Você consegue!'),
        isNotNull,
      );
      expect(
        ActivationCommandGrammar.isConcrete('Coloque os dois pés no chão.'),
        isTrue,
      );
    });
  });

  group('ActivationEpisodeMachine', () {
    test('allows pause abort and recovery from mobilizing', () {
      expect(
        ActivationEpisodeMachine.canTransition(
          ActivationEpisodeStatus.mobilizing,
          ActivationEpisodeStatus.paused,
        ),
        isTrue,
      );
      expect(
        ActivationEpisodeMachine.canTransition(
          ActivationEpisodeStatus.mobilizing,
          ActivationEpisodeStatus.aborted,
        ),
        isTrue,
      );
      expect(
        ActivationEpisodeMachine.canTransition(
          ActivationEpisodeStatus.mobilizing,
          ActivationEpisodeStatus.convertedToRecovery,
        ),
        isTrue,
      );
      expect(
        ActivationEpisodeMachine.canTransition(
          ActivationEpisodeStatus.released,
          ActivationEpisodeStatus.mobilizing,
        ),
        isFalse,
      );
    });
  });

  group('ActivationCommandRunMachine', () {
    test('manual confirm from presented is allowed', () {
      expect(
        ActivationCommandRunMachine.canTransition(
          ActivationCommandRunStatus.presented,
          ActivationCommandRunStatus.confirmed,
        ),
        isTrue,
      );
    });
  });

  group('InertiaHypothesisScorer', () {
    test('is inspectable and blocked by planned rest', () {
      const scorer = InertiaHypothesisScorer();
      final hypothesis = scorer.score(
        type: InertiaHypothesisType.morningBedInertia,
        alarmTransitionWeight: 0.3,
        stationaryWeight: 0.3,
        explicitGoalWeight: 0.3,
        plannedRestWeight: 0.8,
      );
      expect(hypothesis.breakdown.containsKey('planned_rest'), isTrue);
      expect(hypothesis.counterevidence, contains('planned_rest'));
      expect(
        scorer.mayPropose(hypothesis, plannedRest: true),
        isFalse,
      );
    });
  });

  group('ActivationCommandCompiler', () {
    test('keeps one concrete order and splits on adapt', () {
      const compiler = ActivationCommandCompiler();
      final protocolId = EntityId('p1');
      final templates = [
        ActivationCommandTemplate(
          id: const EntityId('c1'),
          protocolId: protocolId,
          protocolVersion: 1,
          sequenceKey: '01',
          instruction: 'Coloque os dois pés no chão.',
          actionVerb: 'Coloque',
          fallback: const ActivationFallbackPolicy(
            splitInstructions: [
              'Sente-se na beira da cama.',
              'Coloque um pé no chão.',
            ],
          ),
        ),
        const ActivationCommandTemplate(
          id: EntityId('c2'),
          protocolId: EntityId('p1'),
          protocolVersion: 1,
          sequenceKey: '02',
          instruction: 'Seja produtivo.',
          actionVerb: 'Seja',
        ),
      ];
      final compiled = compiler.compile(
        templates: templates,
        capacity: ActivationCapacityMode.standard,
      );
      expect(compiled, hasLength(1));
      expect(compiled.single.instruction, 'Coloque os dois pés no chão.');

      var n = 0;
      final adapted = compiler.adapt(
        current: templates.first,
        nextSequence: 10,
        newId: () => EntityId('a${n++}'),
      );
      expect(adapted, hasLength(2));
      expect(adapted.first.instruction, 'Sente-se na beira da cama.');
    });

    test('emergency minimum keeps two commands', () {
      const compiler = ActivationCommandCompiler();
      final templates = [
        for (var i = 1; i <= 5; i++)
          ActivationCommandTemplate(
            id: EntityId('c$i'),
            protocolId: const EntityId('p1'),
            protocolVersion: 1,
            sequenceKey: i.toString().padLeft(2, '0'),
            instruction: 'Dê o passo $i no chão.',
            actionVerb: 'Dê',
          ),
      ];
      final compiled = compiler.compile(
        templates: templates,
        capacity: ActivationCapacityMode.emergencyMinimum,
      );
      expect(compiled, hasLength(2));
    });
  });

  group('ActivationProofEngine', () {
    test('uses median and never scores the person', () {
      const engine = ActivationProofEngine();
      final proofs = [
        _proof(0.2),
        _proof(0.9),
        _proof(0.5),
      ];
      expect(engine.aggregate(proofs), closeTo(0.5, 0.0001));
      expect(
        engine.nextStatus(
          current: ActivationCommandRunStatus.presented,
          confidence: 0.9,
          threshold: 0.5,
          userOverride: false,
        ),
        ActivationCommandRunStatus.confirmed,
      );
    });
  });

  group('ActivationReleaseEvaluator', () {
    test('releases on first meaningful action or explicit escape', () {
      const evaluator = ActivationReleaseEvaluator();
      final episode = ActivationEpisode(
        id: EntityId('e1'),
        profileId: EntityId('pr'),
        triggerType: ActivationTriggerType.userRequested,
        capacityMode: ActivationCapacityMode.standard,
        initialState: ActivationTransitionState(label: 'a'),
        targetState: ActivationTransitionState(label: 'b'),
        status: ActivationEpisodeStatus.mobilizing,
        startedAt: _now,
      );
      final runs = [
        ActivationCommandRun(
          id: const EntityId('r1'),
          episodeId: const EntityId('e1'),
          sequenceIndex: 0,
          instructionRendered: 'Abra a primeira ação já escolhida.',
          status: ActivationCommandRunStatus.confirmed,
          presentedAt: _now,
          confirmationMode: ActivationConfirmationMode.manual,
          isFirstMeaningfulAction: true,
        ),
      ];
      expect(
        evaluator
            .evaluate(
              conditions: const ActivationReleaseConditions(),
              episode: episode,
              runs: runs,
              explicitRelease: false,
              recoveryStarted: false,
            )
            .shouldRelease,
        isTrue,
      );
      expect(
        evaluator
            .evaluate(
              conditions: const ActivationReleaseConditions(),
              episode: episode,
              runs: const [],
              explicitRelease: true,
              recoveryStarted: false,
            )
            .reason,
        'explicit_release',
      );
    });
  });

  group('ActivationProtocolSelector', () {
    test('prefers matching type without ranking character', () {
      const selector = ActivationProtocolSelector();
      final morning = _bundle('morning_launch_standard');
      final study = _bundle('study_ignition');
      final chosen = selector.select(
        candidates: [study, morning],
        capacity: ActivationCapacityMode.standard,
        preferredType: ActivationProtocolType.wakeUp,
      );
      expect(chosen?.protocol.seedKey, 'morning_launch_standard');
    });
  });

  group('ActivationProtocolSeeds', () {
    test('morning launch starts with feet on the floor', () {
      final spec = ActivationProtocolSeeds.byKey('morning_launch_standard')!;
      expect(spec.commands.first.instruction, 'Coloque os dois pés no chão.');
      expect(spec.commands.last.isFirstMeaningfulAction, isTrue);
      var n = 0;
      final bundle = ActivationProtocolSeeds.materialize(
        spec: spec,
        profileId: const EntityId('pr'),
        protocolId: const EntityId('p1'),
        now: _now,
        newId: () => EntityId('id-${n++}'),
      );
      expect(bundle.commands, isNotEmpty);
      for (final command in bundle.commands) {
        expect(ActivationCommandGrammar.isConcrete(command.instruction), isTrue);
      }
    });
  });

  group('ActivationStuckNowPolicy', () {
    test('offers at most two choices', () {
      final morning = ActivationStuckNowPolicy.choices(
        now: DateTime.utc(2026, 8, 23, 8),
        hasUpcomingFocus: false,
      );
      expect(morning, hasLength(2));
      expect(morning.first.protocolType, ActivationProtocolType.wakeUp);
    });
  });

  group('ActivationExperimentAnalyzer', () {
    test('writes associative insight only after enough samples', () {
      const analyzer = ActivationExperimentAnalyzer();
      final experiment = ActivationExperiment(
        id: const EntityId('x1'),
        profileId: const EntityId('pr'),
        name: 'Dock first',
        hypothesis: 'telefone no dock reduz latência',
        variableKey: 'phone_first',
        variants: const ['control', 'dock'],
        minimumSamples: 4,
        status: ActivationExperimentStatus.running,
      );
      expect(
        analyzer.analyze(
          insightId: const EntityId('i1'),
          profileId: const EntityId('pr'),
          experiment: experiment,
          latencyByVariant: {
            'control': const [Duration(minutes: 20), Duration(minutes: 18)],
            'dock': const [Duration(minutes: 9)],
          },
          now: _now,
        ),
        isNull,
      );
      final insight = analyzer.analyze(
        insightId: const EntityId('i1'),
        profileId: const EntityId('pr'),
        experiment: experiment,
        latencyByVariant: {
          'control': const [Duration(minutes: 20), Duration(minutes: 18)],
          'dock': const [Duration(minutes: 9), Duration(minutes: 11)],
        },
        now: _now,
      );
      expect(insight, isNotNull);
      expect(insight!.associativeOnly, isTrue);
      expect(insight.body, contains('não demonstrou causa'));
    });
  });

  group('ActivationConservativeDetector', () {
    test('planned rest blocks proposal', () {
      const detector = ActivationConservativeDetector();
      final proposal = detector.evaluate(
        schedule: const ActivationScheduleContext(
          plannedRest: true,
          morningWindow: true,
          hasUpcomingFocus: false,
        ),
        explicitStuck: false,
        recentFalsePositives: 0,
        autoStartAuthorized: true,
      );
      expect(proposal.mayPropose, isFalse);
      expect(proposal.hypothesis.counterevidence, contains('planned_rest'));
    });
  });

  group('ActivationRescuePolicy', () {
    test('never transmits even with consent flags', () {
      expect(
        ActivationRescuePolicy.mayTransmit(
          previouslyAuthorized: true,
          confirmedNow: true,
        ),
        isFalse,
      );
    });
  });

  group('ActivationRouteMaturityEvaluator', () {
    test('does not encode a discipline score', () {
      expect(
        ActivationRouteMaturityEvaluator.evaluate(
          releasedCount: 12,
          adaptedCount: 0,
        ),
        ActivationRouteMaturity.internalized,
      );
    });
  });

  group('ActivationInsight', () {
    test('never encodes a discipline score field', () {
      final insight = ActivationInsight(
        id: EntityId('i'),
        profileId: EntityId('p'),
        title: 't',
        body: 'b',
        createdAt: _now,
      );
      expect(insight.toJson().containsKey('discipline_score'), isFalse);
    });
  });
}

final _now = DateTime.utc(2026, 8, 23, 12);

ActivationProof _proof(double confidence) {
  return ActivationProof(
    id: EntityId('p$confidence'),
    episodeId: const EntityId('e1'),
    proofType: ActivationProofType.manualTap,
    observedAt: _now,
    source: 'test',
    confidence: confidence,
  );
}

ActivationProtocolBundle _bundle(String seedKey) {
  final spec = ActivationProtocolSeeds.byKey(seedKey)!;
  var n = 0;
  return ActivationProtocolSeeds.materialize(
    spec: spec,
    profileId: const EntityId('pr'),
    protocolId: EntityId('p-$seedKey'),
    now: _now,
    newId: () => EntityId('$seedKey-${n++}'),
  );
}
