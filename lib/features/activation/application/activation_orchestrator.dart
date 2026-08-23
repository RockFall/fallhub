import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';

/// Orquestra um episódio: persiste o evento antes de qualquer side-effect.
class ActivationOrchestrator {
  ActivationOrchestrator({
    required this.repository,
    required this.ids,
    required this.clock,
  });

  final ActivationRepository repository;
  final IdGenerator ids;
  final DateTime Function() clock;

  static const compiler = ActivationCommandCompiler();
  static const proofs = ActivationProofEngine();
  static const release = ActivationReleaseEvaluator();
  static const selector = ActivationProtocolSelector();
  static const intervention = ActivationInterventionPolicy();
  static const experiments = ActivationExperimentAnalyzer();

  Future<int> ensureSeeded(EntityId profileId) {
    return repository.seedDefaults(profileId);
  }

  Future<ActivationEpisode?> restoreOpen(EntityId profileId) {
    return repository.getOpenEpisode(profileId);
  }

  Future<ActivationProtocolBundle?> pickProtocol({
    required EntityId profileId,
    required ActivationCapacityMode capacity,
    ActivationProtocolType? preferredType,
    InertiaHypothesisType? hypothesis,
  }) async {
    final bundles = await repository.listBundles(profileId);
    return selector.select(
      candidates: bundles.where((b) => b.protocol.isEnabled).toList(),
      capacity: capacity,
      preferredType: preferredType,
      hypothesis: hypothesis,
    );
  }

  Future<ActivationEpisode> start({
    required EntityId profileId,
    required ActivationProtocolBundle bundle,
    ActivationCapacityMode capacity = ActivationCapacityMode.standard,
    ActivationTriggerType triggerType = ActivationTriggerType.userRequested,
    InertiaHypothesis? hypothesis,
    EntityId? linkedTaskId,
    String? firstActionDeepLink,
  }) async {
    final open = await repository.getOpenEpisode(profileId);
    if (open != null) {
      throw StateError('Já existe uma rota em andamento');
    }
    if (triggerType == ActivationTriggerType.automatic) {
      final today = await repository.countStartedToday(profileId, clock());
      if (!intervention.withinBudget(today)) {
        throw StateError('Orçamento diário de intervenção atingido');
      }
    }
    List<ActivationCommandTemplate> bindFirstAction(
      List<ActivationCommandTemplate> templates,
    ) {
      if (linkedTaskId == null && firstActionDeepLink == null) {
        return templates;
      }
      return [
        for (final template in templates)
          template.isFirstMeaningfulAction
              ? template.copyWith(
                  opensTaskId: linkedTaskId ?? template.opensTaskId,
                  deepLink: firstActionDeepLink ?? template.deepLink,
                )
              : template,
      ];
    }

    final fallback = bundle.version.fallbackProtocolId == null
        ? const <ActivationCommandTemplate>[]
        : (await repository.getBundle(bundle.version.fallbackProtocolId!))
                ?.commands ??
            const <ActivationCommandTemplate>[];
    final compiled = compiler.compile(
      templates: bindFirstAction(bundle.orderedCommands),
      capacity: capacity,
      fallbackMinimal: bindFirstAction(fallback),
    );
    if (compiled.isEmpty) {
      throw StateError('Protocolo sem comandos concretos');
    }
    final episode = await repository.startEpisode(
      profileId: profileId,
      bundle: bundle,
      capacity: capacity,
      compiled: compiled,
      triggerType: triggerType,
      hypothesis: hypothesis,
      linkedTaskId: linkedTaskId,
    );
    final running = (await repository.listExperiments(profileId))
        .where((e) => e.status == ActivationExperimentStatus.running)
        .toList();
    if (running.isNotEmpty) {
      final experiment = running.first;
      final count = (await repository.listAssignments(experiment.id)).length;
      final assignment = await repository.assignExperiment(
        experiment: experiment,
        episodeId: episode.id,
        variant: experiments.pickVariant(
          experiment: experiment,
          assignmentCount: count,
        ),
      );
      await repository.saveEpisode(
        episode.copyWith(experimentAssignmentId: assignment.id),
      );
    }
    return episode;
  }

  Future<ActivationSnapshot> loadSnapshot(EntityId episodeId) async {
    final episode = await repository.getEpisode(episodeId);
    if (episode == null) {
      throw StateError('Episódio não encontrado');
    }
    final runs = await repository.listRuns(episodeId);
    final current = await repository.getCurrentRun(episodeId);
    final protocol = episode.protocolId == null
        ? null
        : await repository.getBundle(episode.protocolId!);
    return ActivationSnapshot(
      episode: episode,
      runs: runs,
      current: current,
      bundle: protocol,
      proofs: await repository.listProofs(episodeId),
    );
  }

  Future<ActivationSnapshot> confirmCurrent({
    required EntityId episodeId,
    ActivationConfirmationMode mode = ActivationConfirmationMode.manual,
    ActivationProofType proofType = ActivationProofType.manualTap,
    double confidence = 1,
    String source = 'manual',
  }) async {
    final snapshot = await loadSnapshot(episodeId);
    final current = snapshot.current;
    if (current == null) return snapshot;
    if (!ActivationCommandRunMachine.canTransition(
      current.status,
      ActivationCommandRunStatus.confirmed,
    )) {
      throw StateError('Este passo não pode ser confirmado agora');
    }
    final now = clock();
    final proof = ActivationProof(
      id: EntityId(ids.newId()),
      episodeId: episodeId,
      commandRunId: current.id,
      proofType: proofType,
      observedAt: now,
      source: source,
      confidence: confidence,
      userConfirmed: mode == ActivationConfirmationMode.manual ||
          mode == ActivationConfirmationMode.override,
    );
    await repository.addProof(proof);
    var run = current.copyWith(
      status: ActivationCommandRunStatus.confirmed,
      confirmedAt: now,
      firstSignalAt: current.firstSignalAt ?? now,
      confirmationMode: mode,
      proofConfidence: confidence,
    );
    await repository.saveRun(run);
    await repository.recordEvent(
      episodeId: episodeId,
      eventType: EventType.activationCommandConfirmed,
      payload: {
        'instruction': run.instructionRendered,
        'mode': mode.name,
      },
    );
    var episode = snapshot.episode;
    if (episode.firstMotionAt == null) {
      episode = episode.copyWith(firstMotionAt: now);
    }
    final runs = [
      for (final item in snapshot.runs)
        if (item.id == run.id) run else item,
    ];
    final decision = release.evaluate(
      conditions: snapshot.bundle?.version.releaseConditions ??
          const ActivationReleaseConditions(),
      episode: episode,
      runs: runs,
      explicitRelease: run.isFirstMeaningfulAction,
      recoveryStarted: false,
    );
    if (decision.shouldRelease) {
      return _release(episode, runs, reason: decision.reason);
    }
    return _presentNext(episode, snapshot.bundle, runs);
  }

  Future<ActivationSnapshot> skipCurrent(EntityId episodeId) async {
    final snapshot = await loadSnapshot(episodeId);
    final current = snapshot.current;
    if (current == null) return snapshot;
    if (!ActivationCommandRunMachine.canTransition(
      current.status,
      ActivationCommandRunStatus.skipped,
    )) {
      throw StateError('Este passo não pode ser pulado');
    }
    final now = clock();
    final run = current.copyWith(
      status: ActivationCommandRunStatus.skipped,
      skippedAt: now,
    );
    await repository.saveRun(run);
    await repository.recordEvent(
      episodeId: episodeId,
      eventType: EventType.activationCommandSkipped,
      payload: {'instruction': run.instructionRendered},
    );
    final runs = [
      for (final item in snapshot.runs)
        if (item.id == run.id) run else item,
    ];
    return _presentNext(snapshot.episode, snapshot.bundle, runs);
  }

  Future<ActivationSnapshot> adaptCurrent(EntityId episodeId) async {
    final snapshot = await loadSnapshot(episodeId);
    final current = snapshot.current;
    if (current == null) return snapshot;
    final now = clock();
    ActivationCommandTemplate? template;
    for (final command in snapshot.bundle?.commands ?? const <ActivationCommandTemplate>[]) {
      if (command.id == current.templateId) {
        template = command;
        break;
      }
    }
    template ??= ActivationCommandTemplate(
      id: EntityId(ids.newId()),
      protocolId: snapshot.episode.protocolId ?? snapshot.episode.id,
      protocolVersion: snapshot.episode.protocolVersion ?? 1,
      sequenceKey: '99',
      instruction: current.instructionRendered,
      actionVerb: 'Faça',
      fallback: const ActivationFallbackPolicy(
        splitInstructions: [
          'Fique em pé.',
          'Dê três passos para frente.',
        ],
      ),
    );
    final adapted = current.copyWith(
      status: ActivationCommandRunStatus.adapted,
      adaptedAt: now,
      adaptationReason: 'user_adapt',
    );
    await repository.saveRun(adapted);
    final splits = compiler.adapt(
      current: template,
      nextSequence: current.sequenceIndex + 1,
      newId: () => EntityId(ids.newId()),
    );
    final insertAt = current.sequenceIndex + 1;
    for (final run in snapshot.runs) {
      if (run.id == current.id) continue;
      if (run.sequenceIndex >= insertAt) {
        await repository.saveRun(
          run.copyWith(sequenceIndex: run.sequenceIndex + splits.length),
        );
      }
    }
    for (var i = 0; i < splits.length; i++) {
      final command = splits[i];
      await repository.saveRun(
        ActivationCommandRun(
          id: EntityId(ids.newId()),
          episodeId: episodeId,
          templateId: command.id,
          sequenceIndex: insertAt + i,
          instructionRendered: command.instruction,
          status: i == 0
              ? ActivationCommandRunStatus.presented
              : ActivationCommandRunStatus.pending,
          presentedAt: now,
          isFirstMeaningfulAction: command.isFirstMeaningfulAction,
          deepLink: command.deepLink,
          opensTaskId: command.opensTaskId,
        ),
      );
    }
    await repository.saveEpisode(
      snapshot.episode.copyWith(status: ActivationEpisodeStatus.adapted),
    );
    await repository.recordEvent(
      episodeId: episodeId,
      eventType: EventType.activationRouteAdapted,
      payload: {'from': current.instructionRendered},
    );
    return loadSnapshot(episodeId);
  }

  Future<ActivationSnapshot> pause(EntityId episodeId) {
    return _end(
      episodeId,
      ActivationEpisodeStatus.paused,
      EventType.activationEpisodePaused,
    );
  }

  Future<ActivationSnapshot> resume(EntityId episodeId) async {
    final snapshot = await loadSnapshot(episodeId);
    if (!ActivationEpisodeMachine.canTransition(
      snapshot.episode.status,
      ActivationEpisodeStatus.mobilizing,
    )) {
      throw StateError('Esta rota não pode ser retomada');
    }
    await repository.saveEpisode(
      snapshot.episode.copyWith(status: ActivationEpisodeStatus.mobilizing),
    );
    return loadSnapshot(episodeId);
  }

  Future<ActivationSnapshot> abort(EntityId episodeId) {
    return _end(
      episodeId,
      ActivationEpisodeStatus.aborted,
      EventType.activationEpisodeAborted,
    );
  }

  Future<ActivationSnapshot> convertToRecovery(EntityId episodeId) {
    return _end(
      episodeId,
      ActivationEpisodeStatus.convertedToRecovery,
      EventType.activationEpisodeConvertedToRecovery,
    );
  }

  Future<ActivationSnapshot> reportFalsePositive(EntityId episodeId) {
    return _end(
      episodeId,
      ActivationEpisodeStatus.falsePositive,
      EventType.activationFalsePositiveReported,
    );
  }

  Future<ActivationSnapshot> markAlreadyDone(EntityId episodeId) async {
    final snapshot = await loadSnapshot(episodeId);
    if (!ActivationEpisodeMachine.canTransition(
          snapshot.episode.status,
          ActivationEpisodeStatus.released,
        ) &&
        snapshot.episode.status != ActivationEpisodeStatus.released) {
      throw StateError('Esta rota não pode ser liberada agora');
    }
    return _release(
      snapshot.episode,
      snapshot.runs,
      reason: 'explicit_already_done',
    );
  }

  Future<ActivationDetectionProposal> detect({
    required EntityId profileId,
    required ActivationScheduleContext schedule,
    bool autoStartAuthorized = false,
  }) async {
    final falsePositives =
        await repository.countRecentFalsePositives(profileId);
    final resting = await repository.isRestingDeclared(profileId);
    return const ActivationConservativeDetector().evaluate(
      schedule: ActivationScheduleContext(
        plannedRest: schedule.plannedRest || resting,
        morningWindow: schedule.morningWindow,
        hasUpcomingFocus: schedule.hasUpcomingFocus,
        restingDeclared: schedule.restingDeclared || resting,
      ),
      explicitStuck: false,
      recentFalsePositives: falsePositives,
      autoStartAuthorized: autoStartAuthorized,
    );
  }

  Future<void> declareResting(EntityId profileId) {
    return repository.declareResting(profileId);
  }

  Future<ActivationInsight?> analyzeRunningExperiments(
    EntityId profileId,
  ) async {
    final running = (await repository.listExperiments(profileId))
        .where((e) => e.status == ActivationExperimentStatus.running);
    ActivationInsight? last;
    for (final experiment in running) {
      final assignments = await repository.listAssignments(experiment.id);
      final latencyByVariant = <String, List<Duration>>{};
      for (final assignment in assignments) {
        final episode = await repository.getEpisode(assignment.episodeId);
        final latency = episode?.activationLatency;
        if (latency == null) continue;
        latencyByVariant
            .putIfAbsent(assignment.variant, () => [])
            .add(latency);
      }
      final insight = experiments.analyze(
        insightId: EntityId(ids.newId()),
        profileId: profileId,
        experiment: experiment,
        latencyByVariant: latencyByVariant,
        now: clock(),
      );
      if (insight != null) {
        last = await repository.saveInsight(insight);
      }
    }
    return last;
  }

  Future<RescueContract> armRescue(RescueContract contract) async {
    final armed = RescueContract(
      id: contract.id,
      profileId: contract.profileId,
      contactLabel: contract.contactLabel,
      messageTemplate: contract.messageTemplate,
      status: ActivationRescuePolicy.arm(contract.status),
      personId: contract.personId,
      requiresConfirmation: true,
      lastConfirmedAt: contract.lastConfirmedAt,
    );
    return repository.upsertRescue(armed);
  }

  /// Nunca transmite. Confirmação só registra intenção local.
  Future<RescueContract> requestRescueSend(RescueContract contract) async {
    if (ActivationRescuePolicy.mayTransmit(
      previouslyAuthorized: contract.status == RescueContractStatus.armed,
      confirmedNow: true,
    )) {
      throw StateError('Transmissão social não está disponível');
    }
    return repository.upsertRescue(
      RescueContract(
        id: contract.id,
        profileId: contract.profileId,
        contactLabel: contract.contactLabel,
        messageTemplate: contract.messageTemplate,
        status: RescueContractStatus.awaitingConfirmation,
        personId: contract.personId,
        requiresConfirmation: true,
        lastConfirmedAt: clock(),
      ),
    );
  }

  Future<HomeAutomationDryRun> simulateScene(ActivationScene scene) {
    return Future.value(ActivationHomeAutomationPolicy.dryRun(scene));
  }

  Future<ActivationSnapshot> observeWaypointToken({
    required EntityId profileId,
    required String token,
  }) async {
    final waypoint = await repository.findWaypointByToken(token);
    if (waypoint == null || !waypoint.isEnabled) {
      throw StateError('Waypoint não encontrado');
    }
    final open = await repository.getOpenEpisode(profileId);
    await repository.observeWaypoint(
      waypoint: waypoint,
      episodeId: open?.id,
      state: ActivationWaypointListenState.confirmed,
      latencyMs: 0,
      source: waypoint.waypointType.name,
    );
    if (open == null) {
      throw StateError('Nenhuma rota ativa para avançar');
    }
    return confirmCurrent(
      episodeId: open.id,
      mode: ActivationConfirmationMode.passive,
      proofType: ActivationProofType.waypointQr,
      confidence: 0.85,
      source: 'waypoint',
    );
  }

  Future<FrictionShieldSession?> applyShield({
    required EntityId profileId,
    required EntityId episodeId,
  }) async {
    final profiles = await repository.listShieldProfiles(profileId);
    if (profiles.isEmpty) return null;
    final profile = profiles.first;
    if (!profile.isEnabled) return null;
    final session = FrictionShieldSession(
      id: EntityId(ids.newId()),
      profileId: profileId,
      shieldProfileId: profile.id,
      episodeId: episodeId,
      state: FrictionShieldState.active,
      startedAt: clock(),
    );
    await repository.saveShieldSession(session);
    await repository.recordEvent(
      episodeId: episodeId,
      eventType: EventType.frictionShieldApplied,
      payload: {
        'platform_mode': profile.platformMode.name,
        'policy_only':
            profile.platformMode == FrictionShieldPlatformMode.policyOnly,
      },
    );
    final episode = await repository.getEpisode(episodeId);
    if (episode != null) {
      await repository.saveEpisode(episode.copyWith(shieldUsed: true));
    }
    return session;
  }

  Future<FrictionShieldSession?> escapeShield(EntityId profileId) async {
    final session = await repository.getOpenShieldSession(profileId);
    if (session == null) return null;
    if (!FrictionShieldMachine.canTransition(
      session.state,
      FrictionShieldState.temporarilyReleased,
    )) {
      return session;
    }
    final updated = session.copyWith(
      state: FrictionShieldState.temporarilyReleased,
      escapeCount: session.escapeCount + 1,
    );
    await repository.saveShieldSession(updated);
    if (session.episodeId != null) {
      await repository.recordEvent(
        episodeId: session.episodeId!,
        eventType: EventType.frictionShieldEscaped,
        payload: {'offline': true},
      );
      final episode = await repository.getEpisode(session.episodeId!);
      if (episode != null) {
        await repository.saveEpisode(episode.copyWith(escapeUsed: true));
      }
    }
    return updated;
  }

  Future<ActivationSnapshot> _presentNext(
    ActivationEpisode episode,
    ActivationProtocolBundle? bundle,
    List<ActivationCommandRun> runs,
  ) async {
    final pending = [
      for (final run in runs)
        if (run.status == ActivationCommandRunStatus.pending) run,
    ]..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
    if (pending.isEmpty) {
      final anyConfirmed = runs.any(
        (r) => r.status == ActivationCommandRunStatus.confirmed,
      );
      return _release(
        episode,
        runs,
        reason: anyConfirmed ? 'route_exhausted' : 'route_exhausted_unsigned',
      );
    }
    final now = clock();
    final next = pending.first.copyWith(
      status: ActivationCommandRunStatus.presented,
      presentedAt: now,
    );
    await repository.saveRun(next);
    await repository.saveEpisode(
      episode.copyWith(status: ActivationEpisodeStatus.mobilizing),
    );
    await repository.recordEvent(
      episodeId: episode.id,
      eventType: EventType.activationCommandPresented,
      payload: {
        'instruction': next.instructionRendered,
        'index': next.sequenceIndex,
      },
    );
    return loadSnapshot(episode.id);
  }

  Future<ActivationSnapshot> _release(
    ActivationEpisode episode,
    List<ActivationCommandRun> runs, {
    required String reason,
  }) async {
    final now = clock();
    final released = episode.copyWith(
      status: ActivationEpisodeStatus.released,
      releasedAt: now,
      endedAt: now,
    );
    await repository.saveEpisode(released);
    await repository.recordEvent(
      episodeId: episode.id,
      eventType: EventType.activationEpisodeReleased,
      payload: {'reason': reason},
    );
    return loadSnapshot(episode.id);
  }

  Future<ActivationSnapshot> _end(
    EntityId episodeId,
    ActivationEpisodeStatus status,
    EventType eventType,
  ) async {
    final snapshot = await loadSnapshot(episodeId);
    if (!ActivationEpisodeMachine.canTransition(
          snapshot.episode.status,
          status,
        ) &&
        snapshot.episode.status != status) {
      throw StateError('Transição de episódio inválida');
    }
    final now = clock();
    await repository.saveEpisode(
      snapshot.episode.copyWith(
        status: status,
        endedAt: status.isTerminal ? now : snapshot.episode.endedAt,
        releasedAt: status == ActivationEpisodeStatus.convertedToRecovery
            ? now
            : snapshot.episode.releasedAt,
      ),
    );
    final current = snapshot.current;
    if (current != null && status.isTerminal) {
      await repository.saveRun(
        current.copyWith(status: ActivationCommandRunStatus.cancelled),
      );
    }
    await repository.recordEvent(
      episodeId: episodeId,
      eventType: eventType,
      payload: {'status': status.name},
    );
    return loadSnapshot(episodeId);
  }
}

class ActivationSnapshot {
  const ActivationSnapshot({
    required this.episode,
    required this.runs,
    required this.current,
    required this.bundle,
    required this.proofs,
  });

  final ActivationEpisode episode;
  final List<ActivationCommandRun> runs;
  final ActivationCommandRun? current;
  final ActivationProtocolBundle? bundle;
  final List<ActivationProof> proofs;

  List<String> get routeRibbon {
    final names = <String>[];
    for (final run in runs) {
      names.add(run.instructionRendered);
    }
    if (bundle != null) {
      for (final command in bundle!.orderedCommands.skip(runs.length)) {
        names.add(command.destinationRef ?? command.actionVerb);
      }
    }
    return names;
  }
}
