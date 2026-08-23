import 'package:colony_domain/colony_domain.dart';
import 'package:drift/drift.dart';

import '../colony_database.dart';
import 'activation_mappers.dart';
import 'colony_repositories.dart';

class ActivationRepository {
  ActivationRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  EntityId _newId() => EntityId(_ids.newId());

  Stream<List<ActivationProtocol>> watchProtocols(EntityId profileId) {
    return (_db.select(_db.activationProtocols)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(ActivationMappers.toProtocol).toList());
  }

  Future<List<ActivationProtocol>> listProtocols(EntityId profileId) async {
    final rows = await (_db.select(_db.activationProtocols)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ActivationMappers.toProtocol).toList();
  }

  Future<ActivationProtocol?> getProtocol(EntityId id) async {
    final row = await (_db.select(_db.activationProtocols)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ActivationMappers.toProtocol(row);
  }

  Future<ActivationProtocolBundle?> getBundle(EntityId protocolId) async {
    final protocol = await getProtocol(protocolId);
    if (protocol == null) return null;
    final versionRow = await (_db.select(_db.activationProtocolVersions)
          ..where(
            (t) =>
                t.protocolId.equals(protocolId.value) &
                t.version.equals(protocol.activeVersion),
          ))
        .getSingleOrNull();
    if (versionRow == null) return null;
    final commands = await (_db.select(_db.activationCommandTemplates)
          ..where(
            (t) =>
                t.protocolId.equals(protocolId.value) &
                t.protocolVersion.equals(protocol.activeVersion),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sequenceKey)]))
        .get();
    return ActivationProtocolBundle(
      protocol: protocol,
      version: ActivationMappers.toVersion(versionRow),
      commands: commands.map(ActivationMappers.toCommand).toList(),
    );
  }

  Future<List<ActivationProtocolBundle>> listBundles(EntityId profileId) async {
    final protocols = await listProtocols(profileId);
    final bundles = <ActivationProtocolBundle>[];
    for (final protocol in protocols) {
      final bundle = await getBundle(protocol.id);
      if (bundle != null) bundles.add(bundle);
    }
    return bundles;
  }

  Future<void> saveBundle(ActivationProtocolBundle bundle) async {
    await _db.transaction(() async {
      await _db
          .into(_db.activationProtocols)
          .insertOnConflictUpdate(ActivationMappers.fromProtocol(bundle.protocol));
      await _db
          .into(_db.activationProtocolVersions)
          .insertOnConflictUpdate(ActivationMappers.fromVersion(bundle.version));
      await (_db.delete(_db.activationCommandTemplates)
            ..where(
              (t) =>
                  t.protocolId.equals(bundle.protocol.id.value) &
                  t.protocolVersion.equals(bundle.version.version),
            ))
          .go();
      for (final command in bundle.commands) {
        await _db
            .into(_db.activationCommandTemplates)
            .insert(ActivationMappers.fromCommand(command));
      }
    });
  }

  Future<int> seedDefaults(EntityId profileId) async {
    final existing = await listProtocols(profileId);
    final existingKeys = {
      for (final protocol in existing)
        if (protocol.seedKey != null) protocol.seedKey!,
    };
    var created = 0;
    final now = _clock();
    final fallbackIds = <String, EntityId>{};
    for (final spec in ActivationProtocolSeeds.catalog) {
      if (existingKeys.contains(spec.key)) continue;
      fallbackIds[spec.key] = _newId();
    }
    for (final spec in ActivationProtocolSeeds.catalog) {
      if (existingKeys.contains(spec.key)) continue;
      final protocolId = fallbackIds[spec.key]!;
      final fallbackId =
          spec.fallbackKey == null ? null : fallbackIds[spec.fallbackKey!];
      final bundle = ActivationProtocolSeeds.materialize(
        spec: spec,
        profileId: profileId,
        protocolId: protocolId,
        now: now,
        newId: _newId,
        fallbackProtocolId: fallbackId,
      );
      await saveBundle(bundle);
      created += 1;
    }
    await _ensureDefaultWaypoints(profileId);
    await _ensureDefaultShield(profileId);
    await _ensureDefaultExperiment(profileId);
    await _ensureDefaultScene(profileId);
    return created;
  }

  Future<void> _ensureDefaultWaypoints(EntityId profileId) async {
    final existing = await listWaypoints(profileId);
    final keys = <String>{
      for (final waypoint in existing)
        if (waypoint.settings['seed_key'] is String)
          waypoint.settings['seed_key']! as String,
    };
    final now = _clock();
    for (final spec in ActivationWaypointSeeds.catalog) {
      if (keys.contains(spec.key)) continue;
      await upsertWaypoint(
        ActivationWaypoint(
          id: _newId(),
          profileId: profileId,
          name: spec.name,
          waypointType: spec.waypointType,
          token: spec.token,
          settings: spec.settings(),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  Future<void> _ensureDefaultShield(EntityId profileId) async {
    final existing = await (_db.select(_db.frictionShieldProfiles)
          ..where((t) => t.profileId.equals(profileId.value))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return;
    final profile = FrictionShieldProfile(
      id: _newId(),
      profileId: profileId,
      name: 'Escudo local',
      platformMode: FrictionShieldPlatformMode.policyOnly,
      protectedCategories: const ['feeds', 'shorts'],
    );
    await _db
        .into(_db.frictionShieldProfiles)
        .insert(ActivationMappers.fromShieldProfile(profile));
  }

  Future<void> _ensureDefaultScene(EntityId profileId) async {
    final existing = await listScenes(profileId);
    if (existing.isNotEmpty) return;
    await upsertScene(
      ActivationScene(
        id: _newId(),
        profileId: profileId,
        name: 'Luz local (simulação)',
        kind: ActivationSceneKind.light,
        payload: const {'reversible': true},
      ),
    );
  }

  Future<void> _ensureDefaultExperiment(EntityId profileId) async {
    final existing = await listExperiments(profileId);
    if (existing.isNotEmpty) return;
    await upsertExperiment(
      ActivationExperiment(
        id: _newId(),
        profileId: profileId,
        name: 'Dock first',
        hypothesis: 'Colocar o telefone no dock primeiro reduz a latência.',
        variableKey: 'phone_first',
        variants: const ['control', 'dock'],
        minimumSamples: 6,
        status: ActivationExperimentStatus.running,
        startedAt: _clock(),
      ),
    );
  }

  Future<ActivationProtocolBundle> publishNewVersion({
    required ActivationProtocolBundle current,
    required List<ActivationCommandTemplate> commands,
  }) async {
    final now = _clock();
    final nextVersion = current.version.version + 1;
    final rewritten = [
      for (var i = 0; i < commands.length; i++)
        commands[i].copyWith(
          protocolVersion: nextVersion,
          sequenceKey: (i + 1).toString().padLeft(2, '0'),
        ),
    ];
    final bundle = ActivationProtocolBundle(
      protocol: current.protocol.copyWith(
        activeVersion: nextVersion,
        updatedAt: now,
      ),
      version: current.version.copyWith(version: nextVersion, createdAt: now),
      commands: rewritten,
    );
    await saveBundle(bundle);
    return bundle;
  }

  Future<int> countStartedToday(EntityId profileId, DateTime now) async {
    final start = DateTime.utc(now.year, now.month, now.day);
    final episodes = await listEpisodes(profileId);
    return episodes
        .where(
          (e) =>
              !e.startedAt.isBefore(start) &&
              e.status != ActivationEpisodeStatus.falsePositive,
        )
        .length;
  }

  Future<int> countRecentFalsePositives(EntityId profileId) async {
    final cutoff = _clock().subtract(const Duration(days: 7));
    final episodes = await listEpisodes(profileId);
    return episodes
        .where(
          (e) =>
              e.status == ActivationEpisodeStatus.falsePositive &&
              e.startedAt.isAfter(cutoff),
        )
        .length;
  }

  Future<bool> isRestingDeclared(EntityId profileId) async {
    final now = _clock();
    final signals = await (_db.select(_db.inertiaSignals)
          ..where((t) => t.signalType.equals(InertiaSignalType.plannedRest.name)))
        .get();
    return signals.any((row) {
      final expires = row.expiresAt;
      return expires == null || expires > now.millisecondsSinceEpoch;
    });
  }

  Future<void> declareResting(EntityId profileId) async {
    final now = _clock();
    final endOfDay = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
    await addSignal(
      InertiaSignal(
        id: _newId(),
        signalType: InertiaSignalType.plannedRest,
        observedAt: now,
        source: 'user_declared',
        confidence: 1,
        expiresAt: endOfDay,
        privacyClass: PrivacyClass.personal,
      ),
    );
  }

  Stream<List<ActivationEpisode>> watchEpisodes(EntityId profileId) {
    return (_db.select(_db.activationEpisodes)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch()
        .map((rows) => rows.map(ActivationMappers.toEpisode).toList());
  }

  Future<List<ActivationEpisode>> listEpisodes(EntityId profileId) async {
    final rows = await (_db.select(_db.activationEpisodes)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    return rows.map(ActivationMappers.toEpisode).toList();
  }

  Future<ActivationEpisode?> getEpisode(EntityId id) async {
    final row = await (_db.select(_db.activationEpisodes)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ActivationMappers.toEpisode(row);
  }

  Future<ActivationEpisode?> getOpenEpisode(EntityId profileId) async {
    final rows = await (_db.select(_db.activationEpisodes)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    for (final row in rows) {
      final episode = ActivationMappers.toEpisode(row);
      if (episode.status.isOpen) return episode;
    }
    return null;
  }

  Future<List<ActivationCommandRun>> listRuns(EntityId episodeId) async {
    final rows = await (_db.select(_db.activationCommandRuns)
          ..where((t) => t.episodeId.equals(episodeId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.sequenceIndex)]))
        .get();
    return rows.map(ActivationMappers.toRun).toList();
  }

  Future<ActivationCommandRun?> getCurrentRun(EntityId episodeId) async {
    final runs = await listRuns(episodeId);
    for (final run in runs) {
      if (run.status.isOpen) return run;
    }
    return null;
  }

  Future<List<ActivationProof>> listProofs(EntityId episodeId) async {
    final rows = await (_db.select(_db.activationProofs)
          ..where((t) => t.episodeId.equals(episodeId.value)))
        .get();
    return rows.map(ActivationMappers.toProof).toList();
  }

  Future<ActivationEpisode> startEpisode({
    required EntityId profileId,
    required ActivationProtocolBundle bundle,
    required ActivationCapacityMode capacity,
    required List<ActivationCommandTemplate> compiled,
    ActivationTriggerType triggerType = ActivationTriggerType.userRequested,
    InertiaHypothesis? hypothesis,
    EntityId? linkedTaskId,
    EntityId? experimentAssignmentId,
  }) async {
    final now = _clock();
    final episode = ActivationEpisode(
      id: _newId(),
      profileId: profileId,
      protocolId: bundle.protocol.id,
      protocolVersion: bundle.version.version,
      triggerType: triggerType,
      hypothesisType: hypothesis?.type,
      hypothesisConfidence: hypothesis?.confidence,
      capacityMode: capacity,
      initialState: bundle.protocol.originState,
      targetState: bundle.protocol.targetState,
      status: ActivationEpisodeStatus.mobilizing,
      startedAt: now,
      linkedTaskId: linkedTaskId ?? bundle.protocol.linkedTaskId,
      experimentAssignmentId: experimentAssignmentId,
      provenance: const ActivationProvenance(source: 'activation'),
    );
    await _db.transaction(() async {
      await _events.record(
        aggregateType: AggregateType.activationEpisode,
        aggregateId: episode.id,
        eventType: EventType.activationEpisodeStarted,
        payload: {
          'protocol_id': bundle.protocol.id.value,
          'capacity_mode': capacity.name,
          'trigger_type': triggerType.name,
          'protocol_name': bundle.protocol.name,
        },
        sourceType: SourceType.manual,
      );
      await _db
          .into(_db.activationEpisodes)
          .insert(ActivationMappers.fromEpisode(episode));
      for (var i = 0; i < compiled.length; i++) {
        final command = compiled[i];
        final run = ActivationCommandRun(
          id: _newId(),
          episodeId: episode.id,
          templateId: command.id,
          sequenceIndex: i,
          instructionRendered: command.instruction,
          status: i == 0
              ? ActivationCommandRunStatus.presented
              : ActivationCommandRunStatus.pending,
          presentedAt: now,
          isFirstMeaningfulAction: command.isFirstMeaningfulAction,
          deepLink: command.deepLink,
          opensTaskId: command.opensTaskId,
        );
        await _db.into(_db.activationCommandRuns).insert(
              ActivationMappers.fromRun(run),
            );
        if (i == 0) {
          await _events.record(
            aggregateType: AggregateType.activationEpisode,
            aggregateId: episode.id,
            eventType: EventType.activationCommandPresented,
            payload: {'instruction': command.instruction, 'index': 0},
          );
        }
      }
    });
    return episode;
  }

  Future<void> saveEpisode(ActivationEpisode episode) async {
    await (_db.update(_db.activationEpisodes)
          ..where((t) => t.id.equals(episode.id.value)))
        .write(ActivationMappers.fromEpisode(episode));
  }

  Future<void> saveRun(ActivationCommandRun run) async {
    await _db
        .into(_db.activationCommandRuns)
        .insertOnConflictUpdate(ActivationMappers.fromRun(run));
  }

  Future<ActivationProof> addProof(ActivationProof proof) async {
    await _db.transaction(() async {
      await _events.record(
        aggregateType: AggregateType.activationEpisode,
        aggregateId: proof.episodeId,
        eventType: EventType.activationProofObserved,
        payload: {
          'proof_type': proof.proofType.name,
          'confidence': proof.confidence,
          'source': proof.source,
        },
        privacyClass: proof.privacyClass,
      );
      await _db.into(_db.activationProofs).insert(ActivationMappers.fromProof(proof));
    });
    return proof;
  }

  Future<InertiaSignal> addSignal(InertiaSignal signal) async {
    await _db.into(_db.inertiaSignals).insert(ActivationMappers.fromSignal(signal));
    return signal;
  }

  Future<int> expireSignals(DateTime now) async {
    return (_db.delete(_db.inertiaSignals)
          ..where((t) => t.expiresAt.isSmallerOrEqualValue(now.millisecondsSinceEpoch)))
        .go();
  }

  Future<List<InertiaSignal>> listSignals({EntityId? episodeId}) async {
    final query = _db.select(_db.inertiaSignals);
    if (episodeId != null) {
      query.where((t) => t.episodeId.equals(episodeId.value));
    }
    final rows = await query.get();
    return rows.map(ActivationMappers.toSignal).toList();
  }

  Stream<List<ActivationWaypoint>> watchWaypoints(EntityId profileId) {
    return (_db.select(_db.activationWaypoints)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(ActivationMappers.toWaypoint).toList());
  }

  Future<List<ActivationWaypoint>> listWaypoints(EntityId profileId) async {
    final rows = await (_db.select(_db.activationWaypoints)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ActivationMappers.toWaypoint).toList();
  }

  Future<ActivationWaypoint> upsertWaypoint(ActivationWaypoint waypoint) async {
    await _db
        .into(_db.activationWaypoints)
        .insertOnConflictUpdate(ActivationMappers.fromWaypoint(waypoint));
    return waypoint;
  }

  Future<ActivationWaypoint?> findWaypointByToken(String token) async {
    final row = await (_db.select(_db.activationWaypoints)
          ..where((t) => t.token.equals(token))
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : ActivationMappers.toWaypoint(row);
  }

  Future<WaypointObservation> observeWaypoint({
    required ActivationWaypoint waypoint,
    EntityId? episodeId,
    required ActivationWaypointListenState state,
    required int latencyMs,
    String source = 'qr',
  }) async {
    final now = _clock();
    final observation = WaypointObservation(
      id: _newId(),
      waypointId: waypoint.id,
      episodeId: episodeId,
      observedAt: now,
      state: state,
      latencyMs: latencyMs,
      source: source,
    );
    final samples = await (_db.select(_db.waypointObservations)
          ..where((t) => t.waypointId.equals(waypoint.id.value)))
        .get();
    final confirmed = samples
            .where(
              (s) =>
                  s.state == ActivationWaypointListenState.confirmed.name ||
                  s.state == ActivationWaypointListenState.detected.name,
            )
            .length +
        (state == ActivationWaypointListenState.confirmed ||
                state == ActivationWaypointListenState.detected
            ? 1
            : 0);
    final reliability = samples.isEmpty
        ? 1.0
        : (confirmed / (samples.length + 1)).clamp(0.0, 1.0);
    await _db.transaction(() async {
      await _db
          .into(_db.waypointObservations)
          .insert(ActivationMappers.fromObservation(observation));
      await (_db.update(_db.activationWaypoints)
            ..where((t) => t.id.equals(waypoint.id.value)))
          .write(
        ActivationWaypointsCompanion(
          reliabilityScore: Value(reliability),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (episodeId != null) {
        await _events.record(
          aggregateType: AggregateType.activationWaypoint,
          aggregateId: waypoint.id,
          eventType: EventType.waypointReached,
          payload: {
            'name': waypoint.name,
            'state': state.name,
            'episode_id': episodeId.value,
          },
        );
      }
    });
    return observation;
  }

  Future<List<FrictionShieldProfile>> listShieldProfiles(
    EntityId profileId,
  ) async {
    final rows = await (_db.select(_db.frictionShieldProfiles)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ActivationMappers.toShieldProfile).toList();
  }

  Future<FrictionShieldProfile> upsertShieldProfile(
    FrictionShieldProfile profile,
  ) async {
    await _db
        .into(_db.frictionShieldProfiles)
        .insertOnConflictUpdate(ActivationMappers.fromShieldProfile(profile));
    return profile;
  }

  Future<FrictionShieldSession?> getOpenShieldSession(EntityId profileId) async {
    final rows = await (_db.select(_db.frictionShieldSessions)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    for (final row in rows) {
      final session = ActivationMappers.toShieldSession(row);
      if (session.state == FrictionShieldState.active ||
          session.state == FrictionShieldState.armed ||
          session.state == FrictionShieldState.temporarilyReleased) {
        return session;
      }
    }
    return null;
  }

  Future<FrictionShieldSession> saveShieldSession(
    FrictionShieldSession session,
  ) async {
    await _db
        .into(_db.frictionShieldSessions)
        .insertOnConflictUpdate(ActivationMappers.fromShieldSession(session));
    return session;
  }

  Future<List<TemptationBundle>> listBundlesOfPleasure(EntityId profileId) async {
    final rows = await (_db.select(_db.temptationBundles)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ActivationMappers.toBundle).toList();
  }

  Future<TemptationBundle> upsertBundle(TemptationBundle bundle) async {
    await _db
        .into(_db.temptationBundles)
        .insertOnConflictUpdate(ActivationMappers.fromBundle(bundle));
    return bundle;
  }

  Future<List<ActivationScene>> listScenes(EntityId profileId) async {
    final rows = await (_db.select(_db.activationScenes)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ActivationMappers.toScene).toList();
  }

  Future<ActivationScene> upsertScene(ActivationScene scene) async {
    await _db
        .into(_db.activationScenes)
        .insertOnConflictUpdate(ActivationMappers.fromScene(scene));
    return scene;
  }

  Future<List<RescueContract>> listRescueContracts(EntityId profileId) async {
    final rows = await (_db.select(_db.rescueContracts)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ActivationMappers.toRescue).toList();
  }

  Future<RescueContract> upsertRescue(RescueContract contract) async {
    await _db
        .into(_db.rescueContracts)
        .insertOnConflictUpdate(ActivationMappers.fromRescue(contract));
    return contract;
  }

  Future<List<ActivationExperiment>> listExperiments(EntityId profileId) async {
    final rows = await (_db.select(_db.activationExperiments)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ActivationMappers.toExperiment).toList();
  }

  Future<ActivationExperiment> upsertExperiment(
    ActivationExperiment experiment,
  ) async {
    await _db
        .into(_db.activationExperiments)
        .insertOnConflictUpdate(ActivationMappers.fromExperiment(experiment));
    return experiment;
  }

  Future<List<ActivationExperimentAssignment>> listAssignments(
    EntityId experimentId,
  ) async {
    final rows = await (_db.select(_db.activationExperimentAssignments)
          ..where((t) => t.experimentId.equals(experimentId.value)))
        .get();
    return rows.map(ActivationMappers.toAssignment).toList();
  }

  Future<ActivationExperimentAssignment> assignExperiment({
    required ActivationExperiment experiment,
    required EntityId episodeId,
    required String variant,
  }) async {
    final assignment = ActivationExperimentAssignment(
      id: _newId(),
      experimentId: experiment.id,
      episodeId: episodeId,
      variant: variant,
      assignedAt: _clock(),
    );
    await _db
        .into(_db.activationExperimentAssignments)
        .insert(ActivationMappers.fromAssignment(assignment));
    return assignment;
  }

  Future<List<ActivationInsight>> listInsights(EntityId profileId) async {
    final rows = await (_db.select(_db.activationInsights)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(ActivationMappers.toInsight).toList();
  }

  Future<ActivationInsight> saveInsight(ActivationInsight insight) async {
    await _db.transaction(() async {
      await _events.record(
        aggregateType: AggregateType.activationExperiment,
        aggregateId: insight.id,
        eventType: EventType.activationInsightGenerated,
        payload: {
          'title': insight.title,
          'sample_size': insight.sampleSize,
          'associative_only': true,
        },
      );
      await _db
          .into(_db.activationInsights)
          .insert(ActivationMappers.fromInsight(insight));
    });
    return insight;
  }

  Future<void> recordEvent({
    required EntityId episodeId,
    required EventType eventType,
    required Map<String, Object?> payload,
    PrivacyClass privacyClass = PrivacyClass.personal,
  }) {
    return _events.record(
      aggregateType: AggregateType.activationEpisode,
      aggregateId: episodeId,
      eventType: eventType,
      payload: payload,
      privacyClass: privacyClass,
    );
  }

  Future<ActivationExportBundle> exportBundle(EntityId profileId) async {
    final protocols = await listProtocols(profileId);
    final versions = <ActivationProtocolVersion>[];
    final commands = <ActivationCommandTemplate>[];
    for (final protocol in protocols) {
      final bundle = await getBundle(protocol.id);
      if (bundle == null) continue;
      versions.add(bundle.version);
      commands.addAll(bundle.commands);
    }
    final episodes = await listEpisodes(profileId);
    final runs = <ActivationCommandRun>[];
    final proofs = <ActivationProof>[];
    for (final episode in episodes) {
      runs.addAll(await listRuns(episode.id));
      proofs.addAll(
        (await listProofs(episode.id)).map(
          (proof) => ActivationProof(
            id: proof.id,
            episodeId: proof.episodeId,
            commandRunId: proof.commandRunId,
            proofType: proof.proofType,
            observedAt: proof.observedAt,
            source: proof.source,
            confidence: proof.confidence,
            privacyClass: proof.privacyClass,
            interpretation: proof.interpretation,
            userConfirmed: proof.userConfirmed,
          ),
        ),
      );
    }
    final waypoints = [
      for (final waypoint in await listWaypoints(profileId))
        ActivationWaypoint(
          id: waypoint.id,
          profileId: waypoint.profileId,
          name: waypoint.name,
          waypointType: waypoint.waypointType,
          zoneId: waypoint.zoneId,
          equipmentId: waypoint.equipmentId,
          settings: waypoint.settings,
          reliabilityScore: waypoint.reliabilityScore,
          privacyClass: waypoint.privacyClass,
          isEnabled: waypoint.isEnabled,
          createdAt: waypoint.createdAt,
          updatedAt: waypoint.updatedAt,
        ),
    ];
    return ActivationExportBundle(
      protocols: protocols,
      versions: versions,
      commands: commands,
      episodes: [
        for (final episode in episodes)
          episode.copyWith(userCorrection: episode.userCorrection),
      ],
      commandRuns: runs,
      proofs: proofs,
      waypoints: waypoints,
      shieldProfiles: await listShieldProfiles(profileId),
      bundles: await listBundlesOfPleasure(profileId),
      scenes: await listScenes(profileId),
      experiments: await listExperiments(profileId),
      insights: await listInsights(profileId),
    );
  }

  Future<void> restoreBundle(ActivationExportBundle bundle) async {
    for (final protocol in bundle.protocols) {
      await _db
          .into(_db.activationProtocols)
          .insert(ActivationMappers.fromProtocol(protocol));
    }
    for (final version in bundle.versions) {
      await _db
          .into(_db.activationProtocolVersions)
          .insert(ActivationMappers.fromVersion(version));
    }
    for (final command in bundle.commands) {
      await _db
          .into(_db.activationCommandTemplates)
          .insert(ActivationMappers.fromCommand(command));
    }
    for (final episode in bundle.episodes) {
      await _db
          .into(_db.activationEpisodes)
          .insert(ActivationMappers.fromEpisode(episode));
    }
    for (final run in bundle.commandRuns) {
      await _db
          .into(_db.activationCommandRuns)
          .insert(ActivationMappers.fromRun(run));
    }
    for (final proof in bundle.proofs) {
      await _db.into(_db.activationProofs).insert(ActivationMappers.fromProof(proof));
    }
    for (final waypoint in bundle.waypoints) {
      await _db
          .into(_db.activationWaypoints)
          .insert(ActivationMappers.fromWaypoint(waypoint));
    }
    for (final profile in bundle.shieldProfiles) {
      await _db
          .into(_db.frictionShieldProfiles)
          .insert(ActivationMappers.fromShieldProfile(profile));
    }
    for (final pleasure in bundle.bundles) {
      await _db
          .into(_db.temptationBundles)
          .insert(ActivationMappers.fromBundle(pleasure));
    }
    for (final scene in bundle.scenes) {
      await _db.into(_db.activationScenes).insert(ActivationMappers.fromScene(scene));
    }
    for (final experiment in bundle.experiments) {
      await _db
          .into(_db.activationExperiments)
          .insert(ActivationMappers.fromExperiment(experiment));
    }
    for (final assignment in bundle.assignments) {
      await _db
          .into(_db.activationExperimentAssignments)
          .insert(ActivationMappers.fromAssignment(assignment));
    }
    for (final insight in bundle.insights) {
      await _db
          .into(_db.activationInsights)
          .insert(ActivationMappers.fromInsight(insight));
    }
  }

  Future<void> wipeAll() async {
    await _db.delete(_db.activationInsights).go();
    await _db.delete(_db.activationExperimentAssignments).go();
    await _db.delete(_db.activationExperiments).go();
    await _db.delete(_db.rescueContracts).go();
    await _db.delete(_db.activationScenes).go();
    await _db.delete(_db.temptationBundles).go();
    await _db.delete(_db.frictionShieldSessions).go();
    await _db.delete(_db.frictionShieldProfiles).go();
    await _db.delete(_db.inertiaSignals).go();
    await _db.delete(_db.waypointObservations).go();
    await _db.delete(_db.activationProofs).go();
    await _db.delete(_db.activationCommandRuns).go();
    await _db.delete(_db.activationEpisodes).go();
    await _db.delete(_db.activationCommandTemplates).go();
    await _db.delete(_db.activationProtocolVersions).go();
    await _db.delete(_db.activationWaypoints).go();
    await _db.delete(_db.activationProtocols).go();
  }
}
