import 'dart:convert';

import 'package:colony_domain/colony_domain.dart';
import 'package:drift/drift.dart';

import '../colony_database.dart';
import 'colony_repositories.dart';

class MusicAtlasRepository {
  MusicAtlasRepository(
    this._db,
    this._ids,
    this._clock,
    this._events, {
    FlashcardRepository? flashcards,
    ResearchRepository? research,
  }) : _flashcards = flashcards,
       _research = research;

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;
  final FlashcardRepository? _flashcards;
  final ResearchRepository? _research;

  Stream<List<MusicNode>> watchNodes() {
    return (_db.select(_db.musicNodes)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortName)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toMusicNode).toList());
  }

  Future<List<MusicNode>> listNodes() async {
    final rows = await (_db.select(_db.musicNodes)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortName)]))
        .get();
    return rows.map(ColonyMappers.toMusicNode).toList();
  }

  Future<MusicNode?> getNode(EntityId id) async {
    final row = await (_db.select(_db.musicNodes)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toMusicNode(row);
  }

  Future<List<PersonalMusicNodeState>> listStates(EntityId profileId) async {
    final rows = await (_db.select(_db.personalMusicNodeStates)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toPersonalMusicNodeState).toList();
  }

  Future<List<MusicEncounter>> listEncounters(EntityId profileId) async {
    final rows = await (_db.select(_db.musicEncounters)
          ..where(
            (t) => t.profileId.equals(profileId.value) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .get();
    return rows.map(ColonyMappers.toMusicEncounter).toList();
  }

  Future<List<MusicExternalIdentity>> listIdentities() async {
    final rows = await _db.select(_db.musicExternalIdentities).get();
    return rows.map(ColonyMappers.toMusicExternalIdentity).toList();
  }

  Future<List<MusicRelationClaim>> listClaims() async {
    final rows = await (_db.select(_db.musicRelationClaims)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return rows.map(ColonyMappers.toMusicRelationClaim).toList();
  }

  Future<List<MusicExpedition>> listExpeditions(EntityId profileId) async {
    final rows = await (_db.select(_db.musicExpeditions)
          ..where(
            (t) => t.profileId.equals(profileId.value) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(ColonyMappers.toMusicExpedition).toList();
  }

  Future<List<MusicExpeditionStop>> listStops(EntityId expeditionId) async {
    final rows = await (_db.select(_db.musicExpeditionStops)
          ..where((t) => t.expeditionId.equals(expeditionId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
        .get();
    return rows.map(ColonyMappers.toMusicExpeditionStop).toList();
  }

  Future<List<MusicImportRun>> listImportRuns(EntityId profileId) async {
    final rows = await (_db.select(_db.musicImportRuns)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(ColonyMappers.toMusicImportRun).toList();
  }

  Future<MusicSpotifySyncState?> getSpotifySync(EntityId profileId) async {
    final row = await (_db.select(_db.musicSpotifySyncStates)
          ..where((t) => t.profileId.equals(profileId.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toMusicSpotifySyncState(row);
  }

  Future<MusicAtlasOverview> overview(EntityId profileId) async {
    return MusicAtlasOverview(
      nodes: await listNodes(),
      states: await listStates(profileId),
      encounters: await listEncounters(profileId),
      expeditions: await listExpeditions(profileId),
      identities: await listIdentities(),
    );
  }

  Future<MusicNodeInspect?> inspect(EntityId nodeId, EntityId profileId) async {
    final node = await getNode(nodeId);
    if (node == null) return null;
    final stateRow = await (_db.select(_db.personalMusicNodeStates)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.nodeId.equals(nodeId.value),
          ))
        .getSingleOrNull();
    final identities = await (_db.select(_db.musicExternalIdentities)
          ..where((t) => t.nodeId.equals(nodeId.value)))
        .get();
    final encounters = await (_db.select(_db.musicEncounters)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.nodeId.equals(nodeId.value) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .get();
    final from = await (_db.select(_db.musicRelationClaims)
          ..where(
            (t) => t.fromNodeId.equals(nodeId.value) & t.deletedAt.isNull(),
          ))
        .get();
    final to = await (_db.select(_db.musicRelationClaims)
          ..where((t) => t.toNodeId.equals(nodeId.value) & t.deletedAt.isNull()))
        .get();
    return MusicNodeInspect(
      node: node,
      state: stateRow == null
          ? null
          : ColonyMappers.toPersonalMusicNodeState(stateRow),
      identities: identities.map(ColonyMappers.toMusicExternalIdentity).toList(),
      encounters: encounters.map(ColonyMappers.toMusicEncounter).toList(),
      claimsFrom: from.map(ColonyMappers.toMusicRelationClaim).toList(),
      claimsTo: to.map(ColonyMappers.toMusicRelationClaim).toList(),
    );
  }

  Future<MusicNode> createNode({
    required MusicNodeType nodeType,
    required String canonicalName,
    String? description,
    int? beginYear,
    int? endYear,
    String provenanceJson = '{}',
    SourceType sourceType = SourceType.manual,
  }) async {
    final now = _clock().toUtc();
    final node = MusicNode.create(
      id: EntityId(_ids.newId()),
      nodeType: nodeType,
      canonicalName: canonicalName,
      now: now,
      description: description,
      beginYear: beginYear,
      endYear: endYear,
      provenanceJson: provenanceJson,
    );
    await _db.into(_db.musicNodes).insert(ColonyMappers.fromMusicNode(node));
    await _events.record(
      aggregateType: AggregateType.musicNode,
      aggregateId: node.id,
      eventType: EventType.musicNodeCreated,
      payload: {'title': node.canonicalName, 'type': node.nodeType.name},
      sourceType: sourceType,
    );
    return node;
  }

  Future<PersonalMusicNodeState> setDiscoveryState({
    required EntityId profileId,
    required EntityId nodeId,
    required MusicDiscoveryState state,
    int? resonance,
    String? personalSummary,
  }) async {
    final now = _clock().toUtc();
    final existing = await (_db.select(_db.personalMusicNodeStates)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.nodeId.equals(nodeId.value),
          ))
        .getSingleOrNull();
    final next = existing == null
        ? PersonalMusicNodeState(
            profileId: profileId,
            nodeId: nodeId,
            discoveryState: state,
            resonance: resonance,
            personalSummary: personalSummary,
            createdAt: now,
            updatedAt: now,
          )
        : ColonyMappers.toPersonalMusicNodeState(existing).copyWith(
            discoveryState: state,
            resonance: resonance,
            personalSummary: personalSummary,
            updatedAt: now,
          );
    await _db
        .into(_db.personalMusicNodeStates)
        .insertOnConflictUpdate(ColonyMappers.fromPersonalMusicNodeState(next));
    return next;
  }

  Future<MusicEncounter> recordEncounter({
    required EntityId profileId,
    required EntityId nodeId,
    required MusicEncounterType encounterType,
    DateTime? occurredAt,
    int? durationSeconds,
    int? attentionQuality,
    int? resonance,
    String? note,
    SourceType sourceType = SourceType.manual,
    String provenanceJson = '{}',
    bool applySuggestedState = true,
  }) async {
    final now = _clock().toUtc();
    final encounter = MusicEncounter.record(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      nodeId: nodeId,
      encounterType: encounterType,
      occurredAt: (occurredAt ?? now).toUtc(),
      now: now,
      sourceType: sourceType,
      durationSeconds: durationSeconds,
      attentionQuality: attentionQuality,
      resonance: resonance,
      note: note,
      provenanceJson: provenanceJson,
    );
    await _db.transaction(() async {
      await _db
          .into(_db.musicEncounters)
          .insert(ColonyMappers.fromMusicEncounter(encounter));
      if (applySuggestedState) {
        await _touchState(
          profileId: profileId,
          nodeId: nodeId,
          encounter: encounter,
          now: now,
        );
      }
      await _events.record(
        aggregateType: AggregateType.musicEncounter,
        aggregateId: encounter.id,
        eventType: EventType.musicEncounterRecorded,
        payload: {
          'nodeId': nodeId.value,
          'type': encounterType.name,
          if (note != null) 'note': note,
        },
        sourceType: sourceType,
        occurredAt: encounter.occurredAt,
      );
    });
    return encounter;
  }

  Future<MusicRelationClaim> addClaim({
    required EntityId fromNodeId,
    required EntityId toNodeId,
    required MusicRelationType relationType,
    String? description,
    MusicClaimStatus status = MusicClaimStatus.proposed,
    double? confidence,
    String? validFrom,
    String? validTo,
    String provenanceJson = '{}',
  }) async {
    final now = _clock().toUtc();
    final claim = MusicRelationClaim(
      id: EntityId(_ids.newId()),
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      relationType: relationType,
      description: description,
      status: status,
      confidence: confidence,
      validFrom: validFrom,
      validTo: validTo,
      provenanceJson: provenanceJson,
      createdAt: now,
      updatedAt: now,
    );
    await _db
        .into(_db.musicRelationClaims)
        .insert(ColonyMappers.fromMusicRelationClaim(claim));
    await _events.record(
      aggregateType: AggregateType.musicNode,
      aggregateId: fromNodeId,
      eventType: EventType.musicRelationClaimAdded,
      payload: {
        'to': toNodeId.value,
        'type': relationType.name,
        'status': status.name,
      },
    );
    return claim;
  }

  Future<MusicExpedition> draftExpedition({
    required EntityId profileId,
    required String title,
    required String question,
    String? purpose,
    List<MusicExpeditionStop> stops = const [],
  }) async {
    final now = _clock().toUtc();
    final expedition = MusicExpedition.draft(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      question: question,
      now: now,
      purpose: purpose,
    );
    await _db.transaction(() async {
      await _db
          .into(_db.musicExpeditions)
          .insert(ColonyMappers.fromMusicExpedition(expedition));
      for (final stop in stops) {
        final stored = MusicExpeditionStop(
          id: EntityId(_ids.newId()),
          expeditionId: expedition.id,
          nodeId: stop.nodeId,
          displayOrder: stop.displayOrder,
          role: stop.role,
          reason: stop.reason,
          cues: stop.cues,
          isOptional: stop.isOptional,
        );
        await _db
            .into(_db.musicExpeditionStops)
            .insert(ColonyMappers.fromMusicExpeditionStop(stored));
      }
      await _events.record(
        aggregateType: AggregateType.musicExpedition,
        aggregateId: expedition.id,
        eventType: EventType.musicExpeditionDrafted,
        payload: {'title': expedition.title},
      );
    });
    return expedition;
  }

  Future<MusicExpedition> startExpedition(MusicExpedition expedition) async {
    if (expedition.question.trim().isEmpty) {
      throw StateError('A expedição precisa de uma pergunta antes de activar.');
    }
    final now = _clock().toUtc();
    final updated = expedition.copyWith(
      status: MusicExpeditionStatus.active,
      startedAt: now,
      updatedAt: now,
    );
    await _db
        .into(_db.musicExpeditions)
        .insertOnConflictUpdate(ColonyMappers.fromMusicExpedition(updated));
    await _events.record(
      aggregateType: AggregateType.musicExpedition,
      aggregateId: updated.id,
      eventType: EventType.musicExpeditionStarted,
      payload: {'title': updated.title},
    );
    return updated;
  }

  Future<MusicExpedition> completeExpedition(MusicExpedition expedition) async {
    final now = _clock().toUtc();
    final updated = expedition.copyWith(
      status: MusicExpeditionStatus.completed,
      completedAt: now,
      updatedAt: now,
    );
    await _db
        .into(_db.musicExpeditions)
        .insertOnConflictUpdate(ColonyMappers.fromMusicExpedition(updated));
    await _events.record(
      aggregateType: AggregateType.musicExpedition,
      aggregateId: updated.id,
      eventType: EventType.musicExpeditionCompleted,
      payload: {'title': updated.title},
    );
    return updated;
  }

  Future<MusicAtlasJsonImportPlan> planJson({
    required MusicAtlasJsonDocument document,
  }) async {
    return MusicAtlasJsonImportPolicy.plan(
      document: document,
      existingNodes: await listNodes(),
      existingIdentities: await listIdentities(),
      existingClaims: await listClaims(),
    );
  }

  Future<MusicAtlasJsonImportResult> importJson({
    required EntityId profileId,
    required MusicAtlasJsonDocument document,
    MusicAtlasJsonImportPlan? plan,
  }) async {
    final resolved =
        plan ??
        await planJson(document: document);
    final now = _clock().toUtc();
    final keyToId = <String, EntityId>{};
    var createdNodes = 0;
    var linkedNodes = 0;
    var createdClaims = 0;
    var createdEncounters = 0;
    var createdExpeditions = 0;
    FlashcardJsonImportResult? flashResult;
    late EntityId runId;

    await _db.transaction(() async {
      for (final step in resolved.nodes) {
        if (step.action == MusicAtlasJsonNodeAction.conflict ||
            step.action == MusicAtlasJsonNodeAction.skip) {
          continue;
        }
        if (step.action == MusicAtlasJsonNodeAction.link &&
            step.existingId != null) {
          keyToId[step.node.key] = step.existingId!;
          linkedNodes++;
          await _upsertIdentities(step.node, step.existingId!, now);
          continue;
        }
        final node = await createNode(
          nodeType: step.node.nodeType,
          canonicalName: step.node.title,
          description: step.node.summary,
          beginYear: step.node.year,
          provenanceJson: jsonEncode({
            'source_type': 'imported_json',
            'parser_version': 'music_atlas_json_v1',
          }),
          sourceType: SourceType.import,
        );
        keyToId[step.node.key] = node.id;
        createdNodes++;
        await _upsertIdentities(step.node, node.id, now);
        final imported = step.clampedState ??
            MusicDiscoveryPolicy.clampImported(step.node.discoveryState);
        await setDiscoveryState(
          profileId: profileId,
          nodeId: node.id,
          state: imported.state == MusicDiscoveryState.unmapped
              ? MusicDiscoveryState.sighted
              : imported.state,
        );
      }

      for (final step in resolved.claims) {
        if (!step.create) continue;
        final from = keyToId[step.claim.fromKey];
        final to = keyToId[step.claim.toKey];
        if (from == null || to == null) continue;
        await addClaim(
          fromNodeId: from,
          toNodeId: to,
          relationType: step.claim.relationType,
          description: step.claim.description,
          status: step.claim.acceptedByUser
              ? MusicClaimStatus.accepted
              : MusicClaimStatus.proposed,
          confidence: step.claim.confidence,
          validFrom: step.claim.validFrom,
          validTo: step.claim.validTo,
          provenanceJson: jsonEncode({
            'source_type': 'imported_json',
            'sources': step.claim.sources,
            'uncertainties': step.claim.uncertainties,
          }),
        );
        createdClaims++;
      }

      for (final encounter in resolved.encounters) {
        final nodeId = keyToId[encounter.nodeKey];
        if (nodeId == null) continue;
        await recordEncounter(
          profileId: profileId,
          nodeId: nodeId,
          encounterType: encounter.encounterType,
          occurredAt: encounter.occurredAt,
          note: encounter.note,
          resonance: encounter.resonance,
          sourceType: SourceType.import,
          provenanceJson: jsonEncode({'source_type': 'imported_json'}),
          applySuggestedState: false,
        );
        createdEncounters++;
      }

      for (final expedition in resolved.expeditions) {
        final stops = <MusicExpeditionStop>[];
        for (var i = 0; i < expedition.stops.length; i++) {
          final stop = expedition.stops[i];
          final nodeId = keyToId[stop.nodeKey];
          if (nodeId == null) continue;
          stops.add(
            MusicExpeditionStop(
              id: EntityId('pending'),
              expeditionId: const EntityId('pending'),
              nodeId: nodeId,
              displayOrder: i,
              role: stop.role,
              reason: stop.reason,
              cues: stop.cues,
              isOptional: stop.optional,
            ),
          );
        }
        await draftExpedition(
          profileId: profileId,
          title: expedition.title,
          question: expedition.question,
          stops: stops,
        );
        createdExpeditions++;
      }

      if (document.cards.isNotEmpty && _flashcards != null) {
        flashResult = await _flashcards.importJson(
          profileId: profileId,
          document: FlashcardJsonDocument(cards: document.cards),
        );
      }

      await _applyResearchLinks(
        profileId: profileId,
        links: resolved.researchLinks,
        keyToId: keyToId,
      );

      runId = EntityId(_ids.newId());
      final run = MusicImportRun(
        id: runId,
        profileId: profileId,
        sourceKind: MusicImportSourceKind.json,
        status: MusicImportRunStatus.applied,
        documentVersion: document.version,
        itemCount: resolved.nodes.length,
        createdCount: createdNodes,
        skippedCount: resolved.skipCount + resolved.linkCount,
        conflictCount: resolved.conflictCount,
        provenanceJson: jsonEncode({
          'source_type': 'imported_json',
          'parser_version': 'music_atlas_json_v1',
          if (document.userRequest != null) 'userRequest': document.userRequest,
          'createdNodeIds': [
            for (final step in resolved.nodes)
              if (step.action == MusicAtlasJsonNodeAction.create)
                keyToId[step.node.key]?.value,
          ].whereType<String>().toList(),
        }),
        reportJson: jsonEncode({
          'clamped': document.clampedDiscoveryStates,
          'createdNodes': createdNodes,
          'linkedNodes': linkedNodes,
        }),
        createdAt: now,
        appliedAt: now,
      );
      await _db
          .into(_db.musicImportRuns)
          .insert(ColonyMappers.fromMusicImportRun(run));
      await _events.record(
        aggregateType: AggregateType.musicImportRun,
        aggregateId: runId,
        eventType: EventType.musicAtlasJsonImported,
        payload: {
          'created': createdNodes,
          'linked': linkedNodes,
          'claims': createdClaims,
        },
        sourceType: SourceType.import,
      );
    });

    return MusicAtlasJsonImportResult(
      runId: runId,
      createdNodes: createdNodes,
      linkedNodes: linkedNodes,
      skippedNodes: resolved.skipCount,
      conflictNodes: resolved.conflictCount,
      createdClaims: createdClaims,
      createdEncounters: createdEncounters,
      createdExpeditions: createdExpeditions,
      flashcards: flashResult,
    );
  }

  Future<void> rollbackImport(EntityId runId) async {
    final row = await (_db.select(_db.musicImportRuns)
          ..where((t) => t.id.equals(runId.value)))
        .getSingleOrNull();
    if (row == null) return;
    final run = ColonyMappers.toMusicImportRun(row);
    final decoded = jsonDecode(run.provenanceJson);
    final ids = decoded is Map && decoded['createdNodeIds'] is List
        ? [
            for (final id in decoded['createdNodeIds'] as List)
              id.toString(),
          ]
        : const <String>[];
    final now = _clock().toUtc();
    await _db.transaction(() async {
      for (final id in ids) {
        await (_db.update(_db.musicNodes)..where((t) => t.id.equals(id))).write(
          MusicNodesCompanion(deletedAt: Value(now.millisecondsSinceEpoch)),
        );
      }
      await (_db.update(_db.musicImportRuns)
            ..where((t) => t.id.equals(runId.value)))
          .write(
            MusicImportRunsCompanion(
              status: Value(MusicImportRunStatus.rolledBack.name),
              rolledBackAt: Value(now.millisecondsSinceEpoch),
            ),
          );
      await _events.record(
        aggregateType: AggregateType.musicImportRun,
        aggregateId: runId,
        eventType: EventType.musicAtlasJsonRolledBack,
        payload: {'count': ids.length},
        sourceType: SourceType.import,
      );
    });
  }

  Future<MusicAtlasJsonImportResult> importSpotifyLibrary({
    required EntityId profileId,
    required List<SpotifySavedAlbum> albums,
    required EntityId consentId,
  }) async {
    final now = _clock().toUtc();
    var created = 0;
    var linked = 0;
    await _db.transaction(() async {
      for (final album in albums) {
        final existing = await _findByExternal(
          provider: 'spotify',
          entityType: 'album',
          externalId: album.spotifyId,
        );
        final node = existing ??
            await createNode(
              nodeType: MusicNodeType.releaseGroup,
              canonicalName: album.title,
              beginYear: album.year,
              description: album.artistCredit,
              provenanceJson: jsonEncode({
                'source_type': 'spotify_library',
              }),
              sourceType: SourceType.integration,
            );
        if (existing == null) {
          created++;
        } else {
          linked++;
        }
        await _upsertIdentities(
          MusicAtlasJsonNode(
            key: album.spotifyId,
            nodeType: MusicNodeType.releaseGroup,
            title: album.title,
            artists: album.artists,
            year: album.year,
            externalIds: [
              MusicAtlasJsonExternalId(
                provider: 'spotify',
                entityType: 'album',
                id: album.spotifyId,
                url: album.externalUrl,
              ),
            ],
          ),
          node.id,
          now,
        );
        await recordEncounter(
          profileId: profileId,
          nodeId: node.id,
          encounterType: MusicEncounterType.contact,
          occurredAt: album.addedAt ?? now,
          sourceType: SourceType.integration,
          provenanceJson: jsonEncode({
            'source_type': 'spotify_library',
            'spotifyId': album.spotifyId,
          }),
          applySuggestedState: false,
        );
        final current = await (_db.select(_db.personalMusicNodeStates)
              ..where(
                (t) =>
                    t.profileId.equals(profileId.value) &
                    t.nodeId.equals(node.id.value),
              ))
            .getSingleOrNull();
        if (current == null) {
          await setDiscoveryState(
            profileId: profileId,
            nodeId: node.id,
            state: MusicDiscoveryState.rumor,
          );
        }
      }
      await upsertSpotifySync(
        MusicSpotifySyncState(
          profileId: profileId,
          consentId: consentId,
          grantedScopes: const [MusicSpotifyPolicy.libraryScope],
          lastLibraryAt: now,
          updatedAt: now,
        ),
      );
      await _events.record(
        aggregateType: AggregateType.musicImportRun,
        aggregateId: profileId,
        eventType: EventType.spotifyLibraryPulled,
        payload: {'created': created, 'linked': linked, 'count': albums.length},
        sourceType: SourceType.integration,
      );
    });
    return MusicAtlasJsonImportResult(
      runId: profileId,
      createdNodes: created,
      linkedNodes: linked,
      skippedNodes: 0,
      conflictNodes: 0,
      createdClaims: 0,
      createdEncounters: albums.length,
      createdExpeditions: 0,
    );
  }

  Future<MusicEncounter> captureNowPlaying({
    required EntityId profileId,
    required SpotifyNowPlaying playing,
    int? resonance,
    String? note,
  }) async {
    final existing = playing.albumId == null
        ? null
        : await _findByExternal(
            provider: 'spotify',
            entityType: 'album',
            externalId: playing.albumId!,
          );
    final node = existing ??
        await createNode(
          nodeType: playing.albumTitle == null
              ? MusicNodeType.recording
              : MusicNodeType.releaseGroup,
          canonicalName: playing.albumTitle ?? playing.trackTitle,
          description: playing.artists.join(', '),
          provenanceJson: jsonEncode({'source_type': 'spotify_now_playing'}),
          sourceType: SourceType.integration,
        );
    if (playing.albumId != null) {
      await _upsertIdentities(
        MusicAtlasJsonNode(
          key: playing.albumId!,
          nodeType: MusicNodeType.releaseGroup,
          title: playing.albumTitle ?? playing.trackTitle,
          artists: playing.artists,
          externalIds: [
            MusicAtlasJsonExternalId(
              provider: 'spotify',
              entityType: 'album',
              id: playing.albumId!,
              url: playing.externalUrl,
            ),
          ],
        ),
        node.id,
        _clock().toUtc(),
      );
    }
    final encounter = await recordEncounter(
      profileId: profileId,
      nodeId: node.id,
      encounterType: MusicEncounterType.listen,
      note: note,
      resonance: resonance,
      sourceType: SourceType.integration,
      provenanceJson: jsonEncode({
        'source_type': 'spotify_now_playing',
        'trackId': playing.trackId,
      }),
    );
    await _events.record(
      aggregateType: AggregateType.musicEncounter,
      aggregateId: encounter.id,
      eventType: EventType.spotifyNowPlayingCaptured,
      payload: {'title': node.canonicalName, 'track': playing.trackTitle},
      sourceType: SourceType.integration,
    );
    return encounter;
  }

  Future<MusicExpedition> draftExpeditionFromPlaylist({
    required EntityId profileId,
    required SpotifyPlaylistSummary playlist,
  }) async {
    if (playlist.tracks.isEmpty) {
      throw StateError('A playlist não tem faixas resolvidas.');
    }
    final now = _clock().toUtc();
    final stops = <MusicExpeditionStop>[];
    for (var i = 0; i < playlist.tracks.length; i++) {
      final track = playlist.tracks[i];
      final existing = await _findByExternal(
        provider: 'spotify',
        entityType: 'album',
        externalId: track.spotifyId,
      );
      final node = existing ??
          await createNode(
            nodeType: MusicNodeType.releaseGroup,
            canonicalName: track.title,
            description: track.artistCredit,
            beginYear: track.year,
            sourceType: SourceType.integration,
          );
      stops.add(
        MusicExpeditionStop(
          id: EntityId('pending'),
          expeditionId: const EntityId('pending'),
          nodeId: node.id,
          displayOrder: i,
          role: MusicExpeditionStopRole.destination,
          reason: playlist.name,
          isOptional: true,
        ),
      );
    }
    final expedition = await draftExpedition(
      profileId: profileId,
      title: playlist.name,
      question: 'O que esta playlist está a tentar contar?',
      purpose: 'Draft a partir do Spotify (${playlist.spotifyId})',
      stops: stops,
    );
    await _events.record(
      aggregateType: AggregateType.musicExpedition,
      aggregateId: expedition.id,
      eventType: EventType.spotifyPlaylistDrafted,
      payload: {'playlistId': playlist.spotifyId, 'title': playlist.name},
      sourceType: SourceType.integration,
      occurredAt: now,
    );
    return expedition;
  }

  Future<void> upsertSpotifySync(MusicSpotifySyncState state) async {
    await _db
        .into(_db.musicSpotifySyncStates)
        .insertOnConflictUpdate(ColonyMappers.fromMusicSpotifySyncState(state));
  }

  Future<void> clearSpotifySync(EntityId profileId) async {
    await (_db.delete(_db.musicSpotifySyncStates)
          ..where((t) => t.profileId.equals(profileId.value)))
        .go();
  }

  Future<MusicSpotifyConstellation> constellation(EntityId profileId) async {
    final overview = await this.overview(profileId);
    return MusicSpotifyPolicy.buildConstellation(
      nodes: overview.nodes,
      states: overview.states,
      identities: overview.identities,
      encounters: overview.encounters,
    );
  }

  Future<List<MusicFlashcardCandidate>> candidatesForEncounter(
    EntityId encounterId,
  ) async {
    final row = await (_db.select(_db.musicEncounters)
          ..where((t) => t.id.equals(encounterId.value)))
        .getSingleOrNull();
    if (row == null) return const [];
    final encounter = ColonyMappers.toMusicEncounter(row);
    final node = await getNode(encounter.nodeId);
    if (node == null) return const [];
    return MusicFlashcardCandidatePolicy.fromEncounter(
      node: node,
      encounter: encounter,
    );
  }

  Future<MusicNode?> _findByExternal({
    required String provider,
    required String entityType,
    required String externalId,
  }) async {
    final row = await (_db.select(_db.musicExternalIdentities)
          ..where(
            (t) =>
                t.provider.equals(provider) &
                t.entityType.equals(entityType) &
                t.externalId.equals(externalId),
          ))
        .getSingleOrNull();
    if (row == null) return null;
    return getNode(EntityId(row.nodeId));
  }

  Future<void> _upsertIdentities(
    MusicAtlasJsonNode node,
    EntityId nodeId,
    DateTime now,
  ) async {
    for (final ext in node.externalIds) {
      final existing = await (_db.select(_db.musicExternalIdentities)
            ..where(
              (t) =>
                  t.provider.equals(ext.provider) &
                  t.entityType.equals(ext.entityType) &
                  t.externalId.equals(ext.id),
            ))
          .getSingleOrNull();
      if (existing != null) continue;
      final identity = MusicExternalIdentity(
        id: EntityId(_ids.newId()),
        nodeId: nodeId,
        provider: ext.provider,
        entityType: ext.entityType,
        externalId: ext.id,
        externalUrl: ext.url,
        createdAt: now,
        updatedAt: now,
      );
      await _db
          .into(_db.musicExternalIdentities)
          .insert(ColonyMappers.fromMusicExternalIdentity(identity));
    }
  }

  Future<void> _touchState({
    required EntityId profileId,
    required EntityId nodeId,
    required MusicEncounter encounter,
    required DateTime now,
  }) async {
    final existing = await (_db.select(_db.personalMusicNodeStates)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.nodeId.equals(nodeId.value),
          ))
        .getSingleOrNull();
    final current = existing == null
        ? null
        : ColonyMappers.toPersonalMusicNodeState(existing);
    final suggested = MusicDiscoveryPolicy.suggestAfterEncounter(
      current: current?.discoveryState ?? MusicDiscoveryState.unmapped,
      encounterType: encounter.encounterType,
    );
    final next = PersonalMusicNodeState(
      profileId: profileId,
      nodeId: nodeId,
      discoveryState: suggested,
      resonance: encounter.resonance ?? current?.resonance,
      firstEncounterAt: current?.firstEncounterAt ?? encounter.occurredAt,
      lastEncounterAt: encounter.occurredAt,
      encounterCount: (current?.encounterCount ?? 0) + 1,
      personalSummary: current?.personalSummary,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );
    await _db
        .into(_db.personalMusicNodeStates)
        .insertOnConflictUpdate(ColonyMappers.fromPersonalMusicNodeState(next));
  }

  Future<void> _applyResearchLinks({
    required EntityId profileId,
    required List<MusicAtlasJsonResearchLink> links,
    required Map<String, EntityId> keyToId,
  }) async {
    if (links.isEmpty || _research == null || _flashcards == null) {
      return;
    }
    for (final link in links) {
      if (!keyToId.containsKey(link.nodeKey)) continue;
      final existing = await _research.listAll(profileId);
      final matches = [
        for (final node in existing)
          if (node.title.trim().toLowerCase() ==
              link.researchTitle.trim().toLowerCase())
            node,
      ];
      final researchNode = matches.isEmpty
          ? await _research.create(
              profileId: profileId,
              title: link.researchTitle.trim(),
              type: ResearchNodeType.knowledge,
              description: 'Ligado ao Atlas (${link.nodeKey})',
            )
          : matches.first;
      final path = link.areaPath.isEmpty
          ? const ['Artes', 'Música']
          : link.areaPath;
      final areaId = await _ensureAreaPath(profileId, path);
      if (areaId == null) continue;
      await _flashcards.linkResearch(
        researchNodeId: researchNode.id,
        areaId: areaId,
        kind: link.kind,
      );
    }
  }

  Future<EntityId?> _ensureAreaPath(
    EntityId profileId,
    List<String> path,
  ) async {
    if (_flashcards == null || path.isEmpty) return null;
    final existing = await _flashcards.listAreas(profileId);
    EntityId? parentId;
    EntityId? currentId;
    for (final segment in path) {
      final title = segment.trim();
      if (title.isEmpty) continue;
      final matches = [
        for (final area in existing)
          if (area.title.trim().toLowerCase() == title.toLowerCase() &&
              area.parentId == parentId)
            area.id,
      ];
      if (matches.isEmpty) {
        final created = await _flashcards.createArea(
          profileId: profileId,
          title: title,
          parentId: parentId,
        );
        currentId = created.id;
      } else {
        currentId = matches.first;
      }
      parentId = currentId;
    }
    return currentId;
  }
}
