import 'dart:convert';
import 'dart:io';

import 'package:colony_domain/colony_domain.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../colony_database.dart'
    hide DomainEvent, NeedDefinition, NeedReading, CheckIn, MoodFactor, DailyReview, WeeklyReview, WorkPriority, Bill, ScheduleBlock, Quest, Project, QuestProject, DecisionRecord, QuestDecision, ResearchNode, ResearchPrerequisite;

class ProfileRepository {
  ProfileRepository(this._db, this._ids, this._clock);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;

  Future<ColonyProfile?> getActive() async {
    final row = await (_db.select(_db.profiles)
          ..where((t) => t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toProfile(row);
  }

  Future<ColonyProfile> create({
    required String colonyName,
    required String displayName,
    required String timezone,
    required String locale,
    required String baseCurrency,
  }) async {
    final now = _clock();
    final profile = ColonyProfile.create(
      id: EntityId(_ids.newId()),
      colonyName: colonyName,
      displayName: displayName,
      timezone: timezone,
      locale: locale,
      baseCurrency: baseCurrency,
      createdAt: now,
    );

    await _db.into(_db.profiles).insert(ColonyMappers.fromProfile(profile));
    return profile;
  }

  Future<void> update(ColonyProfile profile) async {
    await (_db.update(_db.profiles)..where((t) => t.id.equals(profile.id.value)))
        .write(
      ProfilesCompanion(
        colonyName: Value(profile.colonyName),
        displayName: Value(profile.displayName),
        timezone: Value(profile.timezone),
        locale: Value(profile.locale),
        baseCurrency: Value(profile.baseCurrency),
        updatedAt: Value(profile.updatedAt.millisecondsSinceEpoch),
        version: Value(profile.version),
      ),
    );
  }
}

class PreferencesRepository {
  PreferencesRepository(this._db);

  final ColonyDatabase _db;

  Future<AppPreferences> get() async {
    final row = await (_db.select(_db.preferences)..limit(1)).getSingleOrNull();
    return row == null
        ? AppPreferences.defaults()
        : ColonyMappers.toPreferences(row);
  }

  Future<void> save(AppPreferences preferences) async {
    await _db.into(_db.preferences).insertOnConflictUpdate(
          ColonyMappers.fromPreferences(preferences),
        );
  }
}

class DomainEventRepository {
  DomainEventRepository(this._db, this._ids, this._clock);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;

  Future<void> append(DomainEvent event) async {
    await _db.into(_db.domainEvents).insert(ColonyMappers.fromEvent(event));
  }

  Future<DomainEvent> record({
    required AggregateType aggregateType,
    required EntityId aggregateId,
    required EventType eventType,
    required Map<String, Object?> payload,
    SourceType sourceType = SourceType.system,
    PrivacyClass privacyClass = PrivacyClass.personal,
    DateTime? occurredAt,
    String? correlationId,
    String? causationId,
    EntityId? id,
  }) async {
    final now = _clock();
    final event = DomainEvent.record(
      id: id ?? EntityId(_ids.newId()),
      aggregateType: aggregateType,
      aggregateId: aggregateId,
      eventType: eventType,
      occurredAt: occurredAt ?? now,
      recordedAt: now,
      sourceType: sourceType,
      payload: payload,
      privacyClass: privacyClass,
      correlationId: correlationId,
      causationId: causationId,
    );
    await append(event);
    return event;
  }

  Stream<List<DomainEvent>> watchTimeline({int limit = 100}) {
    final query = _db.select(_db.domainEvents)
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
      ..limit(limit);
    return query.watch().map<List<DomainEvent>>(
          (rows) => rows.map(ColonyMappers.toEvent).toList(),
        );
  }

  Future<List<DomainEvent>> listTimeline({int limit = 100}) async {
    final rows = await (_db.select(_db.domainEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
          ..limit(limit))
        .get();
    return rows.map(ColonyMappers.toEvent).toList();
  }
}

class TaskRepository {
  TaskRepository(this._db, this._ids, this._clock, this._events, [this._sync]);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;
  final SyncRepository? _sync;

  Stream<List<ColonyTask>> watchInbox(EntityId profileId) {
    return (_db.select(_db.tasks)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.status.equals(TaskStatus.inbox.name) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toTask).toList());
  }

  Stream<List<ColonyTask>> watchActive(EntityId profileId) {
    final activeStatuses = TaskStatus.values
        .where((s) => s.isActive)
        .map((s) => s.name)
        .toList();
    return (_db.select(_db.tasks)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.status.isIn(activeStatuses) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toTask).toList());
  }

  Future<ColonyTask?> getById(EntityId id) async {
    final row = await (_db.select(_db.tasks)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toTask(row);
  }

  Future<ColonyTask> capture({
    required EntityId profileId,
    required String title,
  }) async {
    final now = _clock();
    final task = ColonyTask.capture(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title.trim(),
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.tasks).insert(ColonyMappers.fromTask(task));
      await _events.record(
        aggregateType: AggregateType.task,
        aggregateId: task.id,
        eventType: EventType.captureCreated,
        payload: {'title': task.title, 'status': task.status.name},
        sourceType: SourceType.manual,
      );
    });
    // Pilot outbox enqueue (ADR-025) — best-effort; never blocks create.
    final sync = _sync;
    if (sync != null) {
      try {
        await sync.enqueue(
          entityType: 'task',
          entityId: task.id,
          payloadJson: '{"id":"${task.id.value}"}',
        );
      } catch (_) {}
    }

    return task;
  }

  Future<ColonyTask> save(ColonyTask task, {EventType? eventType}) async {
    await _db.into(_db.tasks).insertOnConflictUpdate(
          ColonyMappers.fromTask(task),
        );
    await _events.record(
      aggregateType: AggregateType.task,
      aggregateId: task.id,
      eventType: eventType ?? EventType.taskUpdated,
      payload: {
        'title': task.title,
        'status': task.status.name,
      },
      sourceType: SourceType.manual,
    );
    return task;
  }

  Future<ColonyTask> updateStatus(
    ColonyTask task,
    TaskStatus status, {
    String? blockedReason,
  }) async {
    if (!TaskTransitionPolicy.canTransition(task.status, status)) {
      throw StateError('Transição inválida: ${task.status.name} → ${status.name}');
    }
    if (status == TaskStatus.blocked &&
        (blockedReason == null || blockedReason.trim().isEmpty)) {
      throw ArgumentError('Blocked exige motivo');
    }

    final now = _clock();
    final updated = task.copyWith(
      status: status,
      updatedAt: now,
      completedAt: status == TaskStatus.done ? now : null,
      clearCompletedAt: status != TaskStatus.done,
      blockedReason: status == TaskStatus.blocked ? blockedReason : null,
      clearBlockedReason: status != TaskStatus.blocked,
      version: task.version + 1,
    );

    await save(updated, eventType: EventType.taskStatusChanged);
    return updated;
  }

  Future<ColonyTask> archive(ColonyTask task) async {
    return updateStatus(task, TaskStatus.archived);
  }

  Future<void> deleteSoft(ColonyTask task) async {
    final now = _clock();
    final archived = task.copyWith(
      deletedAt: now,
      updatedAt: now,
      status: TaskStatus.archived,
    );
    await save(archived, eventType: EventType.taskArchived);
  }

  Future<List<ColonyTask>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.tasks)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toTask).toList();
  }

  Future<List<ColonyTask>> listByQuest(EntityId questId) async {
    final rows = await (_db.select(_db.tasks)
          ..where(
            (t) => t.questId.equals(questId.value) & t.deletedAt.isNull(),
          ))
        .get();
    return rows.map(ColonyMappers.toTask).toList();
  }

  Stream<List<ColonyTask>> watchByQuest(EntityId questId) {
    return (_db.select(_db.tasks)
          ..where(
            (t) => t.questId.equals(questId.value) & t.deletedAt.isNull(),
          ))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toTask).toList());
  }

  Future<ColonyTask> linkToQuest(ColonyTask task, EntityId? questId) async {
    final now = _clock();
    final updated = task.copyWith(
      questId: questId,
      clearQuestId: questId == null,
      updatedAt: now,
      version: task.version + 1,
    );
    return save(updated);
  }

  Stream<List<ColonyTask>> watchScheduledForDay(EntityId profileId, DateTime day) {
    final bounds = scheduleDayUtcBounds(day);
    return (_db.select(_db.tasks)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.scheduledStart.isBiggerOrEqualValue(bounds.start.millisecondsSinceEpoch) &
                t.scheduledStart.isSmallerThanValue(bounds.end.millisecondsSinceEpoch) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledStart)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toTask).toList());
  }
}

class ExportRepository {
  ExportRepository(
    this._profiles,
    this._preferences,
    this._tasks,
    this._events,
    this._quests,
    this._projects,
    this._decisions,
    this._research,
    this._finance,
    this._health,
    this._inventory,
    this._people,
    this._trips,
    this._organizations,
    this._homeMaintenance,
    this._commitments,
    this._contextZones,
    this._integrations,
    this._workPriorities,
    this._bills,
    this._schedule,
    this._needs,
    this._checkIns,
    this._dailyReviews,
    this._weeklyReviews,
    this._flashcards,
    this._googleTimeline,
    this._clock,
  );

  final ProfileRepository _profiles;
  final PreferencesRepository _preferences;
  final TaskRepository _tasks;
  final DomainEventRepository _events;
  final QuestRepository _quests;
  final ProjectRepository _projects;
  final DecisionRepository _decisions;
  final ResearchRepository _research;
  final FinanceRepository _finance;
  final HealthRepository _health;
  final InventoryRepository _inventory;
  final PersonRepository _people;
  final TripRepository _trips;
  final OrganizationRepository _organizations;
  final HomeMaintenanceRepository _homeMaintenance;
  final CommitmentRepository _commitments;
  final ContextZoneRepository _contextZones;
  final IntegrationRepository _integrations;
  final WorkPriorityRepository _workPriorities;
  final BillRepository _bills;
  final ScheduleRepository _schedule;
  final NeedRepository _needs;
  final CheckInRepository _checkIns;
  final DailyReviewRepository _dailyReviews;
  final WeeklyReviewRepository _weeklyReviews;
  final FlashcardRepository _flashcards;
  final GoogleTimelineRepository _googleTimeline;
  final DateTime Function() _clock;

  Future<ExportSnapshot> buildSnapshot() async {
    final profile = await _profiles.getActive();
    if (profile == null) {
      throw StateError('Perfil não encontrado');
    }
    final prefs = await _preferences.get();
    final tasks = await _tasks.listAll(profile.id);
    final events = await _events.listTimeline(limit: 5000);
    final quests = await _quests.listAll(profile.id);
    final projects = await _projects.listAll(profile.id);
    final questProjectLinks = await _projects.listLinks(profile.id);
    final decisionRecords = await _decisions.listAll(profile.id);
    final questDecisionLinks = await _decisions.listLinks(profile.id);
    final questPrerequisiteLinks = await _quests.listPrerequisiteLinks(profile.id);
    final workPriorities = await _workPriorities.listAll(profile.id);
    final bills = await _bills.listAll(profile.id);
    final scheduleBlocks = await _schedule.listAll(profile.id);
    final needDefinitions = await _needs.listDefinitions(profile.id);
    final needReadings = await _needs.listReadingsForProfile(profile.id);
    final checkIns = await _checkIns.listAll(profile.id);
    final dailyReviews = await _dailyReviews.listAll(profile.id);
    final moodFactors = await _checkIns.listAllMoodFactors(profile.id);
    final weeklyReviews = await _weeklyReviews.listAll(profile.id);
    final researchNodes = await _research.listAll(profile.id);
    final researchPrerequisiteLinks =
        await _research.listPrerequisiteLinks(profile.id);
    final questResearchLinks = await _research.listQuestLinks(profile.id);
    final learningSessions = await _research.listAllSessions(profile.id);
    final researchEvidence = await _research.listAllEvidence(profile.id);
    final financialEntities = await _finance.listEntities(profile.id);
    final financialAccounts = await _finance.listAccounts(profile.id);
    final transactions = await _finance.listTransactions(profile.id);
    final healthConditions = await _health.listAll(profile.id);
    final symptomEntries = await _health.listAllSymptomEntries(profile.id);
    final healthAppointments = await _health.listAppointments(profile.id);
    final inventoryItems = await _inventory.listAll(profile.id);
    final people = await _people.listAll(profile.id);
    final categoryBudgets = await _finance.listBudgets(profile.id);
    final personInteractions = await _people.listAllInteractions(profile.id);
    final trips = await _trips.listAll(profile.id);
    final organizations = await _organizations.listAll(profile.id);
    final personOrganizationLinks =
        await _organizations.listMemberships(profile.id);
    final homeMaintenanceTasks =
        await _homeMaintenance.listAll(profile.id);
    final questInventoryLinks = await _inventory.listQuestLinks(profile.id);
    final commitments = await _commitments.listAll(profile.id);
    final contextZones = await _contextZones.listAll(profile.id);
    final integrationConsents = await _integrations.listConsents(profile.id);
    final externalCalendarEvents =
        await _integrations.listCalendarEvents(profile.id);
    final zoneTripLinks = await _contextZones.listTripLinks(profile.id);
    final tripInventoryLinks = await _trips.listInventoryLinks(profile.id);
    final knowledgeAreas = await _flashcards.listAreas(profile.id);
    final flashcardDecks = await _flashcards.listDecks(profile.id);
    final flashcards = await _flashcards.listCards(profile.id);
    final flashcardSrs = await _flashcards.listSrs(profile.id);
    final flashcardReviewLogs = await _flashcards.listLogs(profile.id);
    final knowledgeAreaPlacements =
        await _flashcards.listPlacements(profile.id);
    final researchKnowledgeLinks =
        await _flashcards.listResearchLinks(profile.id);
    final flashcardTags = await _flashcards.listTags(profile.id);
    final flashcardTagLinks = await _flashcards.listTagLinks(profile.id);
    final googleTimelineImport =
        await _googleTimeline.getForProfile(profile.id);
    final googleTimelinePlaceLabels =
        await _googleTimeline.listLabels(profile.id);

    return ExportSnapshot(
      exportedAt: _clock(),
      version: 34,
      profile: profile,
      preferences: prefs,
      tasks: tasks,
      events: events,
      quests: quests,
      projects: projects,
      questProjectLinks: questProjectLinks,
      decisionRecords: decisionRecords,
      questDecisionLinks: questDecisionLinks,
      questPrerequisiteLinks: questPrerequisiteLinks,
      workPriorities: workPriorities,
      bills: bills,
      scheduleBlocks: scheduleBlocks,
      needDefinitions: needDefinitions,
      needReadings: needReadings,
      checkIns: checkIns,
      dailyReviews: dailyReviews,
      moodFactors: moodFactors,
      weeklyReviews: weeklyReviews,
      researchNodes: researchNodes,
      researchPrerequisiteLinks: researchPrerequisiteLinks,
      questResearchLinks: questResearchLinks,
      learningSessions: learningSessions,
      researchEvidence: researchEvidence,
      financialEntities: financialEntities,
      financialAccounts: financialAccounts,
      transactions: transactions,
      healthConditions: healthConditions,
      symptomEntries: symptomEntries,
      healthAppointments: healthAppointments,
      inventoryItems: inventoryItems,
      people: people,
      categoryBudgets: categoryBudgets,
      personInteractions: personInteractions,
      trips: trips,
      organizations: organizations,
      personOrganizationLinks: personOrganizationLinks,
      homeMaintenanceTasks: homeMaintenanceTasks,
      questInventoryLinks: questInventoryLinks,
      commitments: commitments,
      contextZones: contextZones,
      integrationConsents: integrationConsents,
      externalCalendarEvents: externalCalendarEvents,
      zoneTripLinks: zoneTripLinks,
      tripInventoryLinks: tripInventoryLinks,
      knowledgeAreas: knowledgeAreas,
      flashcardDecks: flashcardDecks,
      flashcards: flashcards,
      flashcardSrs: flashcardSrs,
      flashcardReviewLogs: flashcardReviewLogs,
      knowledgeAreaPlacements: knowledgeAreaPlacements,
      researchKnowledgeLinks: researchKnowledgeLinks,
      flashcardTags: flashcardTags,
      flashcardTagLinks: flashcardTagLinks,
      googleTimelineImport: googleTimelineImport,
      googleTimelinePlaceLabels: googleTimelinePlaceLabels,
    );
  }

  Future<String> exportJson() async {
    final snapshot = await buildSnapshot();
    final json = snapshot.toJson();
    json['preferences'] = {
      'density_mode': snapshot.preferences.densityMode.name,
      'theme_mode': snapshot.preferences.themeMode.name,
      'week_starts_on_monday': snapshot.preferences.weekStartsOnMonday,
      'use_24_hour_format': snapshot.preferences.use24HourFormat,
      'sectors_enabled': snapshot.preferences.sectorsEnabled,
      'onboarding_completed': snapshot.preferences.onboardingCompleted,
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }
}

class RestoreRepository {
  RestoreRepository(this._db, this._events, this._clock);

  final ColonyDatabase _db;
  final DomainEventRepository _events;
  final DateTime Function() _clock;

  Future<void> restore(ExportSnapshot snapshot) async {
    await _db.transaction(() async {
      await _wipeAll();
      await _insertAll(snapshot);
      await _events.record(
        aggregateType: AggregateType.profile,
        aggregateId: snapshot.profile.id,
        eventType: EventType.exportRestored,
        payload: {
          'version': snapshot.version,
          ...snapshot.entityCounts,
        },
        sourceType: SourceType.manual,
        occurredAt: _clock(),
      );
    });
  }

  Future<void> _wipeAll() async {
    await GoogleTimelineRepository(
      _db,
      UuidIdGenerator.v7(() => const Uuid().v4()),
      _clock,
      _events,
    ).deletePayloadFiles();
    await _db.delete(_db.capturedNotifications).go();
    await _db.delete(_db.googleTimelinePlaceLabels).go();
    await _db.delete(_db.googleTimelineImports).go();
    await _db.delete(_db.researchKnowledgeLinks).go();
    await _db.delete(_db.knowledgeAreaPlacements).go();
    await _db.delete(_db.flashcardTagLinks).go();
    await _db.delete(_db.flashcardTags).go();
    await _db.delete(_db.flashcardReviewLogs).go();
    await _db.delete(_db.flashcardSrs).go();
    await _db.delete(_db.flashcards).go();
    await _db.delete(_db.flashcardDecks).go();
    await _db.delete(_db.knowledgeAreas).go();
    await _db.delete(_db.syncOperations).go();
    await _db.delete(_db.deviceIdentities).go();
    await _db.delete(_db.externalCalendarEvents).go();
    await _db.delete(_db.integrationConsents).go();
    await _db.delete(_db.zoneTrips).go();
    await _db.delete(_db.tripInventory).go();
    await _db.delete(_db.contextZones).go();
    await _db.delete(_db.commitments).go();
    await _db.delete(_db.questInventory).go();
    await _db.delete(_db.homeMaintenanceTasks).go();
    await _db.delete(_db.personOrganizations).go();
    await _db.delete(_db.organizations).go();
    await _db.delete(_db.trips).go();
    await _db.delete(_db.personInteractions).go();
    await _db.delete(_db.categoryBudgets).go();
    await _db.delete(_db.people).go();
    await _db.delete(_db.inventoryItems).go();
    await _db.delete(_db.healthAppointments).go();
    await _db.delete(_db.symptomEntries).go();
    await _db.delete(_db.healthConditions).go();
    await _db.delete(_db.ledgerTransactions).go();
    await _db.delete(_db.financialAccounts).go();
    await _db.delete(_db.financialEntities).go();
    await _db.delete(_db.questDecisions).go();
    await _db.delete(_db.questPrerequisites).go();
    await _db.delete(_db.researchEvidenceItems).go();
    await _db.delete(_db.learningSessions).go();
    await _db.delete(_db.researchPrerequisites).go();
    await _db.delete(_db.questResearch).go();
    await _db.delete(_db.questProjects).go();
    await _db.delete(_db.moodFactors).go();
    await _db.delete(_db.needReadings).go();
    await _db.delete(_db.tasks).go();
    await _db.delete(_db.domainEvents).go();
    await _db.delete(_db.checkIns).go();
    await _db.delete(_db.dailyReviews).go();
    await _db.delete(_db.weeklyReviews).go();
    await _db.delete(_db.scheduleBlocks).go();
    await _db.delete(_db.bills).go();
    await _db.delete(_db.workPriorities).go();
    await _db.delete(_db.decisionRecords).go();
    await _db.delete(_db.quests).go();
    await _db.delete(_db.researchNodes).go();
    await _db.delete(_db.projects).go();
    await _db.delete(_db.needDefinitions).go();
    await _db.delete(_db.preferences).go();
    await _db.delete(_db.profiles).go();
  }

  Future<void> _insertAll(ExportSnapshot snapshot) async {
    await _db.into(_db.profiles).insert(ColonyMappers.fromProfile(snapshot.profile));

    await _db.into(_db.preferences).insert(
          ColonyMappers.fromPreferences(snapshot.preferences),
        );

    for (final def in snapshot.needDefinitions) {
      await _db.into(_db.needDefinitions).insert(ColonyMappers.fromNeedDefinition(def));
    }
    for (final quest in snapshot.quests) {
      await _db.into(_db.quests).insert(ColonyMappers.fromQuest(quest));
    }
    for (final project in snapshot.projects) {
      await _db.into(_db.projects).insert(ColonyMappers.fromProject(project));
    }
    for (final node in snapshot.researchNodes) {
      await _db.into(_db.researchNodes).insert(ColonyMappers.fromResearchNode(node));
    }
    for (final area in snapshot.knowledgeAreas) {
      await _db
          .into(_db.knowledgeAreas)
          .insert(ColonyMappers.fromKnowledgeArea(area));
    }
    for (final placement in snapshot.knowledgeAreaPlacements) {
      await _db
          .into(_db.knowledgeAreaPlacements)
          .insert(ColonyMappers.fromKnowledgeAreaPlacement(placement));
    }
    for (final link in snapshot.researchKnowledgeLinks) {
      await _db
          .into(_db.researchKnowledgeLinks)
          .insert(ColonyMappers.fromResearchKnowledgeLink(link));
    }
    final timelineImport = snapshot.googleTimelineImport;
    if (timelineImport != null) {
      await GoogleTimelineRepository(
        _db,
        UuidIdGenerator.v7(() => const Uuid().v4()),
        _clock,
        _events,
      ).putImport(timelineImport);
    }
    for (final label in snapshot.googleTimelinePlaceLabels) {
      await _db.into(_db.googleTimelinePlaceLabels).insert(
            ColonyMappers.fromTimelinePlaceLabel(
              profileId: snapshot.profile.id,
              label: label,
              updatedAt: snapshot.exportedAt,
            ),
          );
    }
    for (final deck in snapshot.flashcardDecks) {
      await _db
          .into(_db.flashcardDecks)
          .insert(ColonyMappers.fromFlashcardDeck(deck));
    }
    for (final card in snapshot.flashcards) {
      await _db.into(_db.flashcards).insert(ColonyMappers.fromFlashcard(card));
    }
    final remainingTags = [...snapshot.flashcardTags];
    final insertedTagIds = <String>{};
    while (remainingTags.isNotEmpty) {
      final ready = remainingTags
          .where(
            (tag) =>
                tag.parentId == null ||
                insertedTagIds.contains(tag.parentId!.value),
          )
          .toList();
      final batch = ready.isEmpty ? [remainingTags.first] : ready;
      for (final tag in batch) {
        await _db
            .into(_db.flashcardTags)
            .insert(ColonyMappers.fromFlashcardTag(tag));
        insertedTagIds.add(tag.id.value);
        remainingTags.remove(tag);
      }
    }
    for (final link in snapshot.flashcardTagLinks) {
      await _db
          .into(_db.flashcardTagLinks)
          .insert(ColonyMappers.fromFlashcardTagLink(link));
    }
    for (final srs in snapshot.flashcardSrs) {
      await _db.into(_db.flashcardSrs).insert(ColonyMappers.fromFlashcardSrs(srs));
    }
    for (final log in snapshot.flashcardReviewLogs) {
      await _db
          .into(_db.flashcardReviewLogs)
          .insert(ColonyMappers.fromFlashcardReviewLog(log));
    }
    for (final entity in snapshot.financialEntities) {
      await _db
          .into(_db.financialEntities)
          .insert(ColonyMappers.fromFinancialEntity(entity));
    }
    for (final account in snapshot.financialAccounts) {
      await _db
          .into(_db.financialAccounts)
          .insert(ColonyMappers.fromFinancialAccount(account));
    }
    for (final transaction in snapshot.transactions) {
      await _db
          .into(_db.ledgerTransactions)
          .insert(ColonyMappers.fromLedgerTransaction(transaction));
    }
    for (final condition in snapshot.healthConditions) {
      await _db
          .into(_db.healthConditions)
          .insert(ColonyMappers.fromHealthCondition(condition));
    }
    for (final entry in snapshot.symptomEntries) {
      await _db
          .into(_db.symptomEntries)
          .insert(ColonyMappers.fromSymptomEntry(entry));
    }
    for (final appointment in snapshot.healthAppointments) {
      await _db
          .into(_db.healthAppointments)
          .insert(ColonyMappers.fromHealthAppointment(appointment));
    }
    for (final item in snapshot.inventoryItems) {
      await _db
          .into(_db.inventoryItems)
          .insert(ColonyMappers.fromInventoryItem(item));
    }
    for (final person in snapshot.people) {
      await _db.into(_db.people).insert(ColonyMappers.fromPerson(person));
    }
    for (final interaction in snapshot.personInteractions) {
      await _db
          .into(_db.personInteractions)
          .insert(ColonyMappers.fromPersonInteraction(interaction));
    }
    for (final budget in snapshot.categoryBudgets) {
      await _db
          .into(_db.categoryBudgets)
          .insert(ColonyMappers.fromCategoryBudget(budget));
    }
    for (final trip in snapshot.trips) {
      await _db.into(_db.trips).insert(ColonyMappers.fromTrip(trip));
    }
    for (final org in snapshot.organizations) {
      await _db
          .into(_db.organizations)
          .insert(ColonyMappers.fromOrganization(org));
    }
    for (final link in snapshot.personOrganizationLinks) {
      await _db
          .into(_db.personOrganizations)
          .insert(ColonyMappers.fromPersonOrganizationLink(link));
    }
    for (final task in snapshot.homeMaintenanceTasks) {
      await _db
          .into(_db.homeMaintenanceTasks)
          .insert(ColonyMappers.fromHomeMaintenanceTask(task));
    }
    for (final link in snapshot.questInventoryLinks) {
      await _db
          .into(_db.questInventory)
          .insert(ColonyMappers.fromQuestInventoryLink(link));
    }
    for (final link in snapshot.tripInventoryLinks) {
      await _db
          .into(_db.tripInventory)
          .insert(ColonyMappers.fromTripInventoryLink(link));
    }
    for (final commitment in snapshot.commitments) {
      await _db
          .into(_db.commitments)
          .insert(ColonyMappers.fromCommitment(commitment));
    }
    for (final zone in snapshot.contextZones) {
      await _db
          .into(_db.contextZones)
          .insert(ColonyMappers.fromContextZone(zone));
    }
    for (final link in snapshot.zoneTripLinks) {
      await _db
          .into(_db.zoneTrips)
          .insert(ColonyMappers.fromZoneTripLink(link));
    }
    for (final consent in snapshot.integrationConsents) {
      await _db
          .into(_db.integrationConsents)
          .insert(ColonyMappers.fromIntegrationConsent(consent));
    }
    for (final event in snapshot.externalCalendarEvents) {
      await _db
          .into(_db.externalCalendarEvents)
          .insert(ColonyMappers.fromExternalCalendarEvent(event));
    }
    for (final session in snapshot.learningSessions) {
      await _db
          .into(_db.learningSessions)
          .insert(ColonyMappers.fromLearningSession(session));
    }
    for (final evidence in snapshot.researchEvidence) {
      await _db
          .into(_db.researchEvidenceItems)
          .insert(ColonyMappers.fromResearchEvidence(evidence));
    }
    for (final record in snapshot.decisionRecords) {
      await _db.into(_db.decisionRecords).insert(ColonyMappers.fromDecisionRecord(record));
    }
    for (final task in snapshot.tasks) {
      await _db.into(_db.tasks).insert(ColonyMappers.fromTask(task));
    }
    for (final event in snapshot.events) {
      await _db.into(_db.domainEvents).insert(ColonyMappers.fromEvent(event));
    }
    for (final bill in snapshot.bills) {
      await _db.into(_db.bills).insert(ColonyMappers.fromBill(bill));
    }
    for (final block in snapshot.scheduleBlocks) {
      await _db.into(_db.scheduleBlocks).insert(ColonyMappers.fromScheduleBlock(block));
    }
    for (final checkIn in snapshot.checkIns) {
      await _db.into(_db.checkIns).insert(ColonyMappers.fromCheckIn(checkIn));
    }
    for (final factor in snapshot.moodFactors) {
      await _db.into(_db.moodFactors).insert(ColonyMappers.fromMoodFactor(factor));
    }
    for (final review in snapshot.dailyReviews) {
      await _db.into(_db.dailyReviews).insert(ColonyMappers.fromDailyReview(review));
    }
    for (final review in snapshot.weeklyReviews) {
      await _db.into(_db.weeklyReviews).insert(ColonyMappers.fromWeeklyReview(review));
    }
    for (final reading in snapshot.needReadings) {
      await _db.into(_db.needReadings).insert(ColonyMappers.fromNeedReading(reading));
    }
    for (final link in snapshot.questProjectLinks) {
      await _db.into(_db.questProjects).insert(ColonyMappers.fromQuestProjectLink(link));
    }
    for (final link in snapshot.questDecisionLinks) {
      await _db.into(_db.questDecisions).insert(ColonyMappers.fromQuestDecisionLink(link));
    }
    for (final link in snapshot.questPrerequisiteLinks) {
      await _db
          .into(_db.questPrerequisites)
          .insert(ColonyMappers.fromQuestPrerequisiteLink(link));
    }
    for (final link in snapshot.researchPrerequisiteLinks) {
      await _db
          .into(_db.researchPrerequisites)
          .insert(ColonyMappers.fromResearchPrerequisiteLink(link));
    }
    for (final link in snapshot.questResearchLinks) {
      await _db
          .into(_db.questResearch)
          .insert(ColonyMappers.fromQuestResearchLink(link));
    }
    for (final priority in snapshot.workPriorities) {
      await _db.into(_db.workPriorities).insert(ColonyMappers.fromWorkPriority(priority));
    }
  }
}

class NeedRepository {
  NeedRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Future<void> seedDefaults(EntityId profileId) async {
    final existing = await (_db.select(_db.needDefinitions)
          ..where((t) => t.profileId.equals(profileId.value))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return;

    final now = _clock();
    var order = 0;
    for (final seed in DefaultNeedSeeds.core) {
      final def = NeedDefinition(
        id: EntityId(_ids.newId()),
        profileId: profileId,
        name: seed.name,
        slug: seed.slug,
        calculationMode: CalculationMode.manual,
        privacyClass: NeedPrivacyClass.standard,
        isSubjective: seed.subjective,
        sortOrder: order++,
        createdAt: now,
        updatedAt: now,
      );
      await _db.into(_db.needDefinitions).insert(ColonyMappers.fromNeedDefinition(def));
    }
  }

  Stream<List<NeedDefinition>> watchEnabled(EntityId profileId) {
    return (_db.select(_db.needDefinitions)
          ..where(
            (t) => t.profileId.equals(profileId.value) & t.isEnabled.equals(true),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toNeedDefinition).toList());
  }

  Future<List<NeedSnapshot>> buildSnapshots(EntityId profileId) async {
    final defs = await watchEnabled(profileId).first;
    final now = _clock();
    final snapshots = <NeedSnapshot>[];
    for (final def in defs) {
      final reading = await getLatestReading(def.id);
      snapshots.add(NeedSnapshotCalculator.build(def, reading, now));
    }
    return snapshots;
  }

  Stream<List<NeedSnapshot>> watchSnapshots(EntityId profileId) async* {
    await for (final _ in watchEnabled(profileId)) {
      yield await buildSnapshots(profileId);
    }
  }

  Future<NeedReading?> getLatestReading(EntityId needId) async {
    final row = await (_db.select(_db.needReadings)
          ..where((t) => t.needId.equals(needId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.observedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toNeedReading(row);
  }

  Future<NeedReading> recordReading({
    required EntityId needId,
    required double normalizedValue,
    String? note,
    DateTime? observedAt,
  }) async {
    final now = _clock();
    final reading = NeedReading.manual(
      id: EntityId(_ids.newId()),
      needId: needId,
      normalizedValue: normalizedValue,
      observedAt: observedAt ?? now,
      createdAt: now,
      note: note,
    );

    await _db.transaction(() async {
      await _db.into(_db.needReadings).insert(ColonyMappers.fromNeedReading(reading));
      await _events.record(
        aggregateType: AggregateType.need,
        aggregateId: needId,
        eventType: EventType.needReadingRecorded,
        payload: {'value': normalizedValue, if (note != null) 'note': note},
        sourceType: SourceType.manual,
      );
    });

    return reading;
  }

  Future<List<NeedDefinition>> listDefinitions(EntityId profileId) async {
    final rows = await (_db.select(_db.needDefinitions)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toNeedDefinition).toList();
  }

  Future<List<NeedReading>> listReadingsForProfile(EntityId profileId) async {
    final defs = await listDefinitions(profileId);
    if (defs.isEmpty) return [];
    final needIds = defs.map((d) => d.id.value).toList();
    final rows = await (_db.select(_db.needReadings)
          ..where((t) => t.needId.isIn(needIds)))
        .get();
    return rows.map(ColonyMappers.toNeedReading).toList();
  }
}

class CheckInRepository {
  CheckInRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Future<CheckIn?> getLatest(EntityId profileId) async {
    final row = await (_db.select(_db.checkIns)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.observedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toCheckIn(row);
  }

  Stream<CheckIn?> watchLatest(EntityId profileId) {
    return (_db.select(_db.checkIns)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.observedAt)])
          ..limit(1))
        .watchSingleOrNull()
        .map((row) => row == null ? null : ColonyMappers.toCheckIn(row));
  }

  Future<List<MoodFactor>> getFactors(EntityId checkInId) async {
    final rows = await (_db.select(_db.moodFactors)
          ..where((t) => t.checkInId.equals(checkInId.value)))
        .get();
    return rows.map(ColonyMappers.toMoodFactor).toList();
  }

  Future<CheckIn> save({
    required EntityId profileId,
    required double mood,
    required double energy,
    required double tension,
    required double focus,
    String? note,
    List<String> contextTags = const [],
    List<({String label, int? impact, bool uncertain})> factors = const [],
  }) async {
    final now = _clock();
    final checkIn = CheckIn(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      observedAt: now,
      createdAt: now,
      mood: mood.clamp(0, 1),
      energy: energy.clamp(0, 1),
      tension: tension.clamp(0, 1),
      focus: focus.clamp(0, 1),
      note: note,
      contextTags: contextTags,
    );

    await _db.transaction(() async {
      await _db.into(_db.checkIns).insert(ColonyMappers.fromCheckIn(checkIn));
      for (final factor in factors) {
        await _db.into(_db.moodFactors).insert(
              ColonyMappers.fromMoodFactor(
                MoodFactor(
                  id: EntityId(_ids.newId()),
                  checkInId: checkIn.id,
                  label: factor.label,
                  kind: MoodFactorKind.userConfirmed,
                  impact: factor.impact,
                  uncertain: factor.uncertain,
                ),
              ),
            );
      }
      await _events.record(
        aggregateType: AggregateType.checkIn,
        aggregateId: checkIn.id,
        eventType: EventType.checkInRecorded,
        payload: {'mood': mood, 'energy': energy},
        sourceType: SourceType.manual,
      );
    });

    return checkIn;
  }

  Future<List<CheckIn>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.checkIns)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toCheckIn).toList();
  }

  Future<List<MoodFactor>> listAllMoodFactors(EntityId profileId) async {
    final checkInIds = await (_db.selectOnly(_db.checkIns)
          ..addColumns([_db.checkIns.id])
          ..where(_db.checkIns.profileId.equals(profileId.value)))
        .map((row) => row.read(_db.checkIns.id)!)
        .get();
    if (checkInIds.isEmpty) return [];

    final rows = await (_db.select(_db.moodFactors)
          ..where((t) => t.checkInId.isIn(checkInIds)))
        .get();
    return rows.map(ColonyMappers.toMoodFactor).toList();
  }
}

class DailyReviewRepository {
  DailyReviewRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Future<DailyReview?> getForDate(EntityId profileId, DateTime date) async {
    final dayStart = DateTime.utc(date.year, date.month, date.day);
    final row = await (_db.select(_db.dailyReviews)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.reviewDate.equals(dayStart.millisecondsSinceEpoch),
          )
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toDailyReview(row);
  }

  Future<DailyReview> save({
    required EntityId profileId,
    required DateTime reviewDate,
    String? whatHappened,
    String? currentState,
    String? tomorrowCommitments,
    String? routeCorrection,
  }) async {
    final now = _clock();
    final dayStart = DateTime.utc(reviewDate.year, reviewDate.month, reviewDate.day);
    final existing = await getForDate(profileId, reviewDate);

    final review = DailyReview(
      id: existing?.id ?? EntityId(_ids.newId()),
      profileId: profileId,
      reviewDate: dayStart,
      createdAt: now,
      whatHappened: whatHappened,
      currentState: currentState,
      tomorrowCommitments: tomorrowCommitments,
      routeCorrection: routeCorrection,
    );

    await _db.transaction(() async {
      if (existing != null) {
        await (_db.update(_db.dailyReviews)
              ..where((t) => t.id.equals(review.id.value)))
            .write(
          DailyReviewsCompanion(
            whatHappened: Value(review.whatHappened),
            currentState: Value(review.currentState),
            tomorrowCommitments: Value(review.tomorrowCommitments),
            routeCorrection: Value(review.routeCorrection),
            createdAt: Value(review.createdAt.millisecondsSinceEpoch),
          ),
        );
      } else {
        await _db.into(_db.dailyReviews).insert(ColonyMappers.fromDailyReview(review));
      }
      await _events.record(
        aggregateType: AggregateType.profile,
        aggregateId: profileId,
        eventType: EventType.dailyReviewCompleted,
        payload: {'date': dayStart.toIso8601String()},
        sourceType: SourceType.manual,
      );
    });

    return review;
  }

  Future<List<DailyReview>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.dailyReviews)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toDailyReview).toList();
  }
}

class WeeklyReviewRepository {
  WeeklyReviewRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Future<WeeklyReview?> getForWeek(EntityId profileId, DateTime weekStart) async {
    final start = DateTime.utc(weekStart.year, weekStart.month, weekStart.day);
    final row = await (_db.select(_db.weeklyReviews)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.weekStartDate.equals(start.millisecondsSinceEpoch),
          )
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toWeeklyReview(row);
  }

  Future<WeeklyReview> save({
    required EntityId profileId,
    required DateTime weekStartDate,
    String? facts,
    String? wins,
    String? problems,
    String? projects,
    String? learning,
    String? nextWeek,
  }) async {
    final now = _clock();
    final weekStart =
        DateTime.utc(weekStartDate.year, weekStartDate.month, weekStartDate.day);
    final existing = await getForWeek(profileId, weekStart);

    final review = WeeklyReview(
      id: existing?.id ?? EntityId(_ids.newId()),
      profileId: profileId,
      weekStartDate: weekStart,
      createdAt: now,
      facts: facts,
      wins: wins,
      problems: problems,
      projects: projects,
      learning: learning,
      nextWeek: nextWeek,
    );

    await _db.transaction(() async {
      if (existing != null) {
        await (_db.update(_db.weeklyReviews)
              ..where((t) => t.id.equals(review.id.value)))
            .write(
          WeeklyReviewsCompanion(
            facts: Value(review.facts),
            wins: Value(review.wins),
            problems: Value(review.problems),
            projects: Value(review.projects),
            learning: Value(review.learning),
            nextWeek: Value(review.nextWeek),
            createdAt: Value(review.createdAt.millisecondsSinceEpoch),
          ),
        );
      } else {
        await _db.into(_db.weeklyReviews).insert(ColonyMappers.fromWeeklyReview(review));
      }
      await _events.record(
        aggregateType: AggregateType.profile,
        aggregateId: profileId,
        eventType: EventType.weeklyReviewCompleted,
        payload: {'week_start': weekStart.toIso8601String()},
        sourceType: SourceType.manual,
      );
    });

    return review;
  }

  Future<List<WeeklyReview>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.weeklyReviews)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toWeeklyReview).toList();
  }
}

class WorkPriorityRepository {
  WorkPriorityRepository(this._db, this._clock, this._events);

  final ColonyDatabase _db;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Future<void> seedDefaults(EntityId profileId) async {
    final existing = await (_db.select(_db.workPriorities)
          ..where((t) => t.profileId.equals(profileId.value))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return;

    final now = _clock();
    for (final workType in DefaultWorkTypeSeeds.core) {
      final priority = WorkPriority(
        profileId: profileId,
        workType: workType,
        level: PriorityLevel.normal,
        updatedAt: now,
      );
      await _db.into(_db.workPriorities).insert(ColonyMappers.fromWorkPriority(priority));
    }
  }

  Stream<List<WorkPriority>> watchAll(EntityId profileId) {
    return (_db.select(_db.workPriorities)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.workType)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toWorkPriority).toList());
  }

  Future<List<WorkPriority>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.workPriorities)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toWorkPriority).toList();
  }

  Future<WorkPriority> save(WorkPriority priority) async {
    await _db.into(_db.workPriorities).insertOnConflictUpdate(
          ColonyMappers.fromWorkPriority(priority),
        );
    await _events.record(
      aggregateType: AggregateType.work,
      aggregateId: priority.profileId,
      eventType: EventType.workPriorityChanged,
      payload: {
        'workType': priority.workType.name,
        'level': priority.level.name,
      },
      sourceType: SourceType.manual,
    );
    return priority;
  }

  Future<WorkPriority> cyclePriority(WorkPriority priority) async {
    final now = _clock();
    final updated = priority.copyWith(
      level: PriorityCyclePolicy.next(priority.level),
      updatedAt: now,
    );
    return save(updated);
  }
}

class BillRepository {
  BillRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<Bill>> watchAll(EntityId profileId) {
    return (_db.select(_db.bills)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toBill).toList());
  }

  Future<Bill> create({
    required EntityId profileId,
    required String title,
    BillRepeatMode repeatMode = BillRepeatMode.fixed,
    String target = '1',
  }) async {
    final now = _clock();
    final bill = Bill.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title.trim(),
      repeatMode: repeatMode,
      target: target,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.bills).insert(ColonyMappers.fromBill(bill));
      await _events.record(
        aggregateType: AggregateType.bill,
        aggregateId: bill.id,
        eventType: EventType.billCreated,
        payload: {'title': bill.title, 'repeatMode': bill.repeatMode.name},
        sourceType: SourceType.manual,
      );
    });

    return bill;
  }

  Future<Bill> save(Bill bill) async {
    await _db.into(_db.bills).insertOnConflictUpdate(ColonyMappers.fromBill(bill));
    await _events.record(
      aggregateType: AggregateType.bill,
      aggregateId: bill.id,
      eventType: EventType.billUpdated,
      payload: {'title': bill.title},
      sourceType: SourceType.manual,
    );
    return bill;
  }

  Future<List<Bill>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.bills)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toBill).toList();
  }
}

class ScheduleRepository {
  ScheduleRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<ScheduleBlock>> watchForDay(EntityId profileId, DateTime day) {
    final bounds = scheduleDayUtcBounds(day);
    return (_db.select(_db.scheduleBlocks)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.startAt.isBiggerOrEqualValue(bounds.start.millisecondsSinceEpoch) &
                t.startAt.isSmallerThanValue(bounds.end.millisecondsSinceEpoch),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toScheduleBlock).toList());
  }

  Future<ScheduleBlock> create({
    required EntityId profileId,
    required DateTime startAt,
    required DateTime endAt,
    required ScheduleBlockMode mode,
    SourceType sourceType = SourceType.manual,
  }) async {
    final now = _clock();
    final block = ScheduleBlock.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      startAt: startAt,
      endAt: endAt,
      mode: mode,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.scheduleBlocks).insert(ColonyMappers.fromScheduleBlock(block));
      await _events.record(
        aggregateType: AggregateType.schedule,
        aggregateId: block.id,
        eventType: EventType.scheduleBlockCreated,
        payload: {'mode': block.mode.name},
        sourceType: sourceType,
      );
    });

    return block;
  }

  Future<ScheduleBlock> save(ScheduleBlock block) async {
    await _db.into(_db.scheduleBlocks).insertOnConflictUpdate(
          ColonyMappers.fromScheduleBlock(block),
        );
    await _events.record(
      aggregateType: AggregateType.schedule,
      aggregateId: block.id,
      eventType: EventType.scheduleBlockUpdated,
      payload: {'mode': block.mode.name},
      sourceType: SourceType.manual,
    );
    return block;
  }

  Future<List<ScheduleBlock>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.scheduleBlocks)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toScheduleBlock).toList();
  }

  Future<void> delete(EntityId id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.scheduleBlocks)..where((t) => t.id.equals(id.value)))
          .go();
      await _events.record(
        aggregateType: AggregateType.schedule,
        aggregateId: id,
        eventType: EventType.scheduleBlockDeleted,
        payload: const {},
        sourceType: SourceType.manual,
      );
    });
  }
}

class QuestRepository {
  QuestRepository(this._db, this._ids, this._clock, this._events, [this._sync]);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;
  final SyncRepository? _sync;

  Stream<List<Quest>> watchAll(EntityId profileId) {
    return (_db.select(_db.quests)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toQuest).toList());
  }

  Stream<List<Quest>> watchByStatus(EntityId profileId, QuestStatus status) {
    return (_db.select(_db.quests)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.status.equals(status.name),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toQuest).toList());
  }

  Future<List<Quest>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.quests)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toQuest).toList();
  }

  Future<List<Quest>> listByStatus(EntityId profileId, QuestStatus status) async {
    final rows = await (_db.select(_db.quests)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.status.equals(status.name),
          ))
        .get();
    return rows.map(ColonyMappers.toQuest).toList();
  }

  Future<Quest?> getById(EntityId id) async {
    final row = await (_db.select(_db.quests)..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toQuest(row);
  }

  Future<Quest> create({
    required EntityId profileId,
    required String title,
    required String purpose,
    QuestStatus status = QuestStatus.draft,
    List<String> successCriteria = const [],
    List<String> risks = const [],
    DateTime? deadline,
    DateTime? acceptedAt,
    List<String> acceptanceAssumptions = const [],
    DateTime? acceptanceDeadline,
  }) async {
    final now = _clock();
    var quest = Quest.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      purpose: purpose,
      createdAt: now,
      status: status,
      successCriteria: successCriteria,
      risks: risks,
      deadline: deadline,
    );

    if (status == QuestStatus.active) {
      await _assertCanActivate(quest);
      quest = quest.copyWith(
        acceptedAt: acceptedAt ?? now,
        acceptanceAssumptions: acceptanceAssumptions,
        acceptanceDeadline: acceptanceDeadline,
      );
    }

    await _db.transaction(() async {
      await _db.into(_db.quests).insert(ColonyMappers.fromQuest(quest));
      await _events.record(
        aggregateType: AggregateType.quest,
        aggregateId: quest.id,
        eventType: EventType.questCreated,
        payload: {
          'title': quest.title,
          'status': quest.status.name,
        },
        sourceType: SourceType.manual,
      );
    });
    // Pilot outbox enqueue (ADR-025) — best-effort; never blocks create.
    final sync = _sync;
    if (sync != null) {
      try {
        await sync.enqueue(
          entityType: 'quest',
          entityId: quest.id,
          payloadJson: '{"id":"${quest.id.value}"}',
        );
      } catch (_) {}
    }

    return quest;
  }

  Future<Quest> save(Quest quest, {EventType? eventType}) async {
    await _db.into(_db.quests).insertOnConflictUpdate(
          ColonyMappers.fromQuest(quest),
        );
    await _events.record(
      aggregateType: AggregateType.quest,
      aggregateId: quest.id,
      eventType: eventType ?? EventType.questUpdated,
      payload: {
        'title': quest.title,
        'status': quest.status.name,
        if (quest.pauseReason != null) 'pause_reason': quest.pauseReason,
      },
      sourceType: SourceType.manual,
    );
    return quest;
  }

  Future<Quest> updateStatus(
    Quest quest,
    QuestStatus status, {
    String? exitReason,
    String? pauseReason,
  }) async {
    if (!QuestLifecyclePolicy.canTransition(quest.status, status)) {
      throw StateError(
        'Transição inválida: ${quest.status.name} → ${status.name}',
      );
    }

    if (status == QuestStatus.active) {
      if (quest.status == QuestStatus.draft) {
        throw StateError('Use acceptAndActivate para ativar rascunho');
      }
      await _assertCanActivate(quest);
    }

    final now = _clock();
    final completing = status == QuestStatus.completed;
    final abandoning = status == QuestStatus.abandoned;
    final pausing = status == QuestStatus.paused;

    final updated = quest.copyWith(
      status: status,
      updatedAt: now,
      completedAt: completing ? now : null,
      clearCompletedAt: !completing,
      exitReason: abandoning ? exitReason : null,
      clearExitReason: !abandoning,
      pauseReason: pausing ? pauseReason : null,
      clearPauseReason: !pausing,
      version: quest.version + 1,
    );

    await save(updated, eventType: EventType.questStatusChanged);
    return updated;
  }

  Future<Quest> acceptAndActivate(
    Quest quest, {
    required List<String> acceptanceAssumptions,
    DateTime? acceptanceDeadline,
  }) async {
    if (quest.status != QuestStatus.draft) {
      throw StateError('Aceite só permitido em rascunho');
    }
    if (!QuestLifecyclePolicy.canTransition(quest.status, QuestStatus.active)) {
      throw StateError(
        'Transição inválida: ${quest.status.name} → active',
      );
    }

    await _assertCanActivate(quest);

    final assumptions = acceptanceAssumptions
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (assumptions.isEmpty) {
      throw ArgumentError('Premissas de aceite obrigatórias');
    }

    final now = _clock();
    final updated = quest.copyWith(
      status: QuestStatus.active,
      acceptedAt: now,
      acceptanceAssumptions: assumptions,
      acceptanceDeadline: acceptanceDeadline,
      updatedAt: now,
      version: quest.version + 1,
    );

    await _db.transaction(() async {
      await _db.into(_db.quests).insertOnConflictUpdate(
            ColonyMappers.fromQuest(updated),
          );
      await _events.record(
        aggregateType: AggregateType.quest,
        aggregateId: quest.id,
        eventType: EventType.questAccepted,
        payload: {
          'title': quest.title,
          'assumptions_count': assumptions.length,
        },
        sourceType: SourceType.manual,
      );
    });

    return updated;
  }

  Future<void> _assertCanActivate(Quest quest) async {
    final prerequisites = await listPrerequisites(quest.id);
    if (!QuestPrerequisitePolicy.canActivate(
      quest: quest,
      prerequisites: prerequisites,
    )) {
      throw QuestPrerequisiteException(
        'Pré-requisitos incompletos',
      );
    }
  }

  Future<List<QuestPrerequisiteLink>> listPrerequisiteLinks(
    EntityId profileId,
  ) async {
    final rows = await (_db.select(_db.questPrerequisites).join([
      innerJoin(
        _db.quests,
        _db.quests.id.equalsExp(_db.questPrerequisites.questId),
      ),
    ])
          ..where(_db.quests.profileId.equals(profileId.value)))
        .get();
    return rows
        .map(
          (row) => ColonyMappers.toQuestPrerequisiteLink(
            row.readTable(_db.questPrerequisites),
          ),
        )
        .toList();
  }

  Stream<List<Quest>> watchPrerequisites(EntityId questId) {
    final query = _db.select(_db.quests).join([
      innerJoin(
        _db.questPrerequisites,
        _db.questPrerequisites.prerequisiteQuestId.equalsExp(_db.quests.id),
      ),
    ])
      ..where(_db.questPrerequisites.questId.equals(questId.value))
      ..orderBy([OrderingTerm.desc(_db.quests.updatedAt)]);

    return query.watch().map(
          (rows) =>
              rows.map((row) => ColonyMappers.toQuest(row.readTable(_db.quests))).toList(),
        );
  }

  Future<List<Quest>> listPrerequisites(EntityId questId) async {
    final rows = await (_db.select(_db.quests).join([
      innerJoin(
        _db.questPrerequisites,
        _db.questPrerequisites.prerequisiteQuestId.equalsExp(_db.quests.id),
      ),
    ])
          ..where(_db.questPrerequisites.questId.equals(questId.value)))
        .get();
    return rows.map((row) => ColonyMappers.toQuest(row.readTable(_db.quests))).toList();
  }

  Future<void> linkPrerequisite({
    required EntityId questId,
    required EntityId prerequisiteQuestId,
  }) async {
    final profileId = await _questProfileId(questId);
    final existing = await listPrerequisiteLinks(profileId);
    QuestPrerequisitePolicy.validateLink(
      existingLinks: existing,
      questId: questId,
      prerequisiteQuestId: prerequisiteQuestId,
    );

    final link = QuestPrerequisiteLink(
      questId: questId,
      prerequisiteQuestId: prerequisiteQuestId,
      linkedAt: _clock(),
    );
    await _db.into(_db.questPrerequisites).insert(
          ColonyMappers.fromQuestPrerequisiteLink(link),
        );
  }

  Future<void> unlinkPrerequisite({
    required EntityId questId,
    required EntityId prerequisiteQuestId,
  }) async {
    await (_db.delete(_db.questPrerequisites)
          ..where(
            (t) =>
                t.questId.equals(questId.value) &
                t.prerequisiteQuestId.equals(prerequisiteQuestId.value),
          ))
        .go();
  }

  Future<EntityId> _questProfileId(EntityId questId) async {
    final row = await (_db.select(_db.quests)..where((t) => t.id.equals(questId.value)))
        .getSingleOrNull();
    if (row == null) {
      throw StateError('Missão não encontrada');
    }
    return EntityId(row.profileId);
  }
}

class ResearchRepository {
  ResearchRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<ResearchNode>> watchAll(EntityId profileId) {
    return (_db.select(_db.researchNodes)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toResearchNode).toList());
  }

  Future<List<ResearchNode>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.researchNodes)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toResearchNode).toList();
  }

  Future<ResearchNode?> getById(EntityId id) async {
    final row = await (_db.select(_db.researchNodes)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toResearchNode(row);
  }

  Future<ResearchNode> create({
    required EntityId profileId,
    required String title,
    required ResearchNodeType type,
    String? description,
    ResearchNodeStatus status = ResearchNodeStatus.available,
  }) async {
    final now = _clock();
    final node = ResearchNode.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      type: type,
      description: description,
      createdAt: now,
      status: status,
    );

    await _db.transaction(() async {
      await _db.into(_db.researchNodes).insert(ColonyMappers.fromResearchNode(node));
      await _events.record(
        aggregateType: AggregateType.research,
        aggregateId: node.id,
        eventType: EventType.researchNodeCreated,
        payload: {
          'title': node.title,
          'type': node.type.name,
          'status': node.status.name,
        },
        sourceType: SourceType.manual,
      );
    });

    return node;
  }

  Future<ResearchNode> save(ResearchNode node, {EventType? eventType}) async {
    await _db.into(_db.researchNodes).insertOnConflictUpdate(
          ColonyMappers.fromResearchNode(node),
        );
    await _events.record(
      aggregateType: AggregateType.research,
      aggregateId: node.id,
      eventType: eventType ?? EventType.researchStatusChanged,
      payload: {
        'title': node.title,
        'status': node.status.name,
      },
      sourceType: SourceType.manual,
    );
    return node;
  }

  Future<ResearchNode> updateStatus(
    ResearchNode node,
    ResearchNodeStatus status, {
    String? demonstratedNote,
  }) async {
    if (!ResearchLifecyclePolicy.canTransition(node.status, status)) {
      throw StateError(
        'Transição inválida: ${node.status.name} → ${status.name}',
      );
    }

    if (status == ResearchNodeStatus.inResearch) {
      await _assertCanSetInResearch(node);
    }

    if (status == ResearchNodeStatus.demonstrated) {
      final evidenceCount = await countEvidence(node.id);
      if (!ResearchDemonstrationPolicy.canDemonstrate(
        evidenceCount: evidenceCount,
      )) {
        throw ResearchDemonstrationException(
          'Evidência necessária para demonstrar',
        );
      }
    }

    final now = _clock();
    final demonstrating = status == ResearchNodeStatus.demonstrated;

    final updated = node.copyWith(
      status: status,
      updatedAt: now,
      demonstratedNote: demonstrating ? demonstratedNote : null,
      clearDemonstratedNote: !demonstrating,
      version: node.version + 1,
    );

    await save(updated, eventType: EventType.researchStatusChanged);
    return updated;
  }

  Future<void> _assertCanSetInResearch(ResearchNode node) async {
    final prerequisites = await listPrerequisites(node.id);
    if (!ResearchPrerequisitePolicy.canSetInResearch(
      node: node,
      prerequisites: prerequisites,
    )) {
      throw ResearchPrerequisiteException(
        'Pré-requisitos incompletos',
      );
    }

    final profileId = await _nodeProfileId(node.id);
    final allNodes = await listAll(profileId);
    if (!ActiveResearchPolicy.canStartFocus(node: node, allNodes: allNodes)) {
      throw ActiveResearchException(
        'Já existe uma pesquisa em foco',
      );
    }
  }

  Future<List<ResearchPrerequisiteLink>> listPrerequisiteLinks(
    EntityId profileId,
  ) async {
    final rows = await (_db.select(_db.researchPrerequisites).join([
      innerJoin(
        _db.researchNodes,
        _db.researchNodes.id.equalsExp(_db.researchPrerequisites.nodeId),
      ),
    ])
          ..where(_db.researchNodes.profileId.equals(profileId.value)))
        .get();
    return rows
        .map(
          (row) => ColonyMappers.toResearchPrerequisiteLink(
            row.readTable(_db.researchPrerequisites),
          ),
        )
        .toList();
  }

  Stream<List<ResearchNode>> watchPrerequisites(EntityId nodeId) {
    final query = _db.select(_db.researchNodes).join([
      innerJoin(
        _db.researchPrerequisites,
        _db.researchPrerequisites.prerequisiteNodeId.equalsExp(_db.researchNodes.id),
      ),
    ])
      ..where(_db.researchPrerequisites.nodeId.equals(nodeId.value))
      ..orderBy([OrderingTerm.desc(_db.researchNodes.updatedAt)]);

    return query.watch().map(
          (rows) => rows
              .map((row) => ColonyMappers.toResearchNode(row.readTable(_db.researchNodes)))
              .toList(),
        );
  }

  Future<List<ResearchNode>> listPrerequisites(EntityId nodeId) async {
    final rows = await (_db.select(_db.researchNodes).join([
      innerJoin(
        _db.researchPrerequisites,
        _db.researchPrerequisites.prerequisiteNodeId.equalsExp(_db.researchNodes.id),
      ),
    ])
          ..where(_db.researchPrerequisites.nodeId.equals(nodeId.value)))
        .get();
    return rows
        .map((row) => ColonyMappers.toResearchNode(row.readTable(_db.researchNodes)))
        .toList();
  }

  Future<void> linkPrerequisite({
    required EntityId nodeId,
    required EntityId prerequisiteNodeId,
  }) async {
    final profileId = await _nodeProfileId(nodeId);
    final existing = await listPrerequisiteLinks(profileId);
    ResearchPrerequisitePolicy.validateLink(
      existingLinks: existing,
      nodeId: nodeId,
      prerequisiteNodeId: prerequisiteNodeId,
    );

    final link = ResearchPrerequisiteLink(
      nodeId: nodeId,
      prerequisiteNodeId: prerequisiteNodeId,
      linkedAt: _clock(),
    );
    await _db.into(_db.researchPrerequisites).insert(
          ColonyMappers.fromResearchPrerequisiteLink(link),
        );
  }

  Future<void> unlinkPrerequisite({
    required EntityId nodeId,
    required EntityId prerequisiteNodeId,
  }) async {
    await (_db.delete(_db.researchPrerequisites)
          ..where(
            (t) =>
                t.nodeId.equals(nodeId.value) &
                t.prerequisiteNodeId.equals(prerequisiteNodeId.value),
          ))
        .go();
  }

  Future<List<QuestResearchLink>> listQuestLinks(EntityId profileId) async {
    final rows = await (_db.select(_db.questResearch).join([
      innerJoin(
        _db.quests,
        _db.quests.id.equalsExp(_db.questResearch.questId),
      ),
    ])
          ..where(_db.quests.profileId.equals(profileId.value)))
        .get();
    return rows
        .map(
          (row) => ColonyMappers.toQuestResearchLink(
            row.readTable(_db.questResearch),
          ),
        )
        .toList();
  }

  Stream<List<ResearchNode>> watchLinkedToQuest(EntityId questId) {
    final query = _db.select(_db.researchNodes).join([
      innerJoin(
        _db.questResearch,
        _db.questResearch.researchNodeId.equalsExp(_db.researchNodes.id),
      ),
    ])
      ..where(_db.questResearch.questId.equals(questId.value))
      ..orderBy([OrderingTerm.desc(_db.researchNodes.updatedAt)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => ColonyMappers.toResearchNode(
                  row.readTable(_db.researchNodes),
                ),
              )
              .toList(),
        );
  }

  Stream<List<Quest>> watchLinkedQuests(EntityId researchNodeId) {
    final query = _db.select(_db.quests).join([
      innerJoin(
        _db.questResearch,
        _db.questResearch.questId.equalsExp(_db.quests.id),
      ),
    ])
      ..where(_db.questResearch.researchNodeId.equals(researchNodeId.value))
      ..orderBy([OrderingTerm.desc(_db.quests.updatedAt)]);

    return query.watch().map(
          (rows) => rows
              .map((row) => ColonyMappers.toQuest(row.readTable(_db.quests)))
              .toList(),
        );
  }

  Future<void> linkQuest({
    required EntityId questId,
    required EntityId researchNodeId,
  }) async {
    final now = _clock();
    final existing = await (_db.select(_db.questResearch)
          ..where(
            (t) =>
                t.questId.equals(questId.value) &
                t.researchNodeId.equals(researchNodeId.value),
          ))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.into(_db.questResearch).insert(
          ColonyMappers.fromQuestResearchLink(
            QuestResearchLink(
              questId: questId,
              researchNodeId: researchNodeId,
              linkedAt: now,
            ),
          ),
        );
  }

  Future<void> unlinkQuest({
    required EntityId questId,
    required EntityId researchNodeId,
  }) async {
    await (_db.delete(_db.questResearch)
          ..where(
            (t) =>
                t.questId.equals(questId.value) &
                t.researchNodeId.equals(researchNodeId.value),
          ))
        .go();
  }

  Future<EntityId> _nodeProfileId(EntityId nodeId) async {
    final row = await (_db.select(_db.researchNodes)
          ..where((t) => t.id.equals(nodeId.value)))
        .getSingleOrNull();
    if (row == null) {
      throw StateError('Nó de pesquisa não encontrado');
    }
    return EntityId(row.profileId);
  }

  Stream<List<LearningSession>> watchSessions(EntityId nodeId) {
    return (_db.select(_db.learningSessions)
          ..where((t) => t.nodeId.equals(nodeId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toLearningSession).toList());
  }

  Future<List<LearningSession>> listSessions(EntityId nodeId) async {
    final rows = await (_db.select(_db.learningSessions)
          ..where((t) => t.nodeId.equals(nodeId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    return rows.map(ColonyMappers.toLearningSession).toList();
  }

  Future<List<LearningSession>> listAllSessions(EntityId profileId) async {
    final rows = await (_db.select(_db.learningSessions)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toLearningSession).toList();
  }

  Future<LearningSession> logSession({
    required EntityId profileId,
    required EntityId nodeId,
    required DateTime startedAt,
    required int durationMinutes,
    required LearningSessionMode mode,
    String? notes,
  }) async {
    final session = LearningSession.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      nodeId: nodeId,
      startedAt: startedAt,
      durationMinutes: durationMinutes,
      mode: mode,
      notes: notes,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.learningSessions)
          .insert(ColonyMappers.fromLearningSession(session));
      await _events.record(
        aggregateType: AggregateType.research,
        aggregateId: nodeId,
        eventType: EventType.researchSessionLogged,
        payload: {
          'node_id': nodeId.value,
          'mode': mode.name,
          'duration_minutes': durationMinutes,
        },
        sourceType: SourceType.manual,
      );
    });

    return session;
  }

  Stream<List<ResearchEvidence>> watchEvidence(EntityId nodeId) {
    return (_db.select(_db.researchEvidenceItems)
          ..where((t) => t.nodeId.equals(nodeId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toResearchEvidence).toList());
  }

  Future<List<ResearchEvidence>> listEvidence(EntityId nodeId) async {
    final rows = await (_db.select(_db.researchEvidenceItems)
          ..where((t) => t.nodeId.equals(nodeId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(ColonyMappers.toResearchEvidence).toList();
  }

  Future<List<ResearchEvidence>> listAllEvidence(EntityId profileId) async {
    final rows = await (_db.select(_db.researchEvidenceItems)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toResearchEvidence).toList();
  }

  Future<int> countEvidence(EntityId nodeId) async {
    final count = await (_db.selectOnly(_db.researchEvidenceItems)
          ..addColumns([_db.researchEvidenceItems.id.count()])
          ..where(_db.researchEvidenceItems.nodeId.equals(nodeId.value)))
        .getSingle();
    return count.read(_db.researchEvidenceItems.id.count()) ?? 0;
  }

  Future<ResearchEvidence> addEvidence({
    required EntityId profileId,
    required EntityId nodeId,
    required ResearchEvidenceType type,
    required String title,
    required String body,
    EntityId? sessionId,
  }) async {
    final now = _clock();
    final evidence = ResearchEvidence.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      nodeId: nodeId,
      type: type,
      title: title,
      body: body,
      createdAt: now,
      sessionId: sessionId,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.researchEvidenceItems)
          .insert(ColonyMappers.fromResearchEvidence(evidence));
      await _events.record(
        aggregateType: AggregateType.research,
        aggregateId: nodeId,
        eventType: EventType.researchEvidenceCreated,
        payload: {
          'node_id': nodeId.value,
          'type': type.name,
          'title': title,
        },
        sourceType: SourceType.manual,
      );
    });

    return evidence;
  }

  Future<void> deleteEvidence(EntityId evidenceId) async {
    final row = await (_db.select(_db.researchEvidenceItems)
          ..where((t) => t.id.equals(evidenceId.value)))
        .getSingleOrNull();
    if (row == null) return;

    final evidence = ColonyMappers.toResearchEvidence(row);
    final node = await getById(evidence.nodeId);
    if (node == null) return;

    final evidenceCount = await countEvidence(evidence.nodeId);
    if (!ResearchDemonstrationPolicy.canDeleteEvidence(
      nodeStatus: node.status,
      evidenceCount: evidenceCount,
    )) {
      throw const ResearchEvidenceDeleteException();
    }

    await (_db.delete(_db.researchEvidenceItems)
          ..where((t) => t.id.equals(evidenceId.value)))
        .go();
  }
}

class FinanceRepository {
  FinanceRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<FinancialEntity>> watchEntities(EntityId profileId) {
    return (_db.select(_db.financialEntities)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toFinancialEntity).toList());
  }

  Future<List<FinancialEntity>> listEntities(EntityId profileId) async {
    final rows = await (_db.select(_db.financialEntities)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toFinancialEntity).toList();
  }

  Future<FinancialEntity?> getEntityById(EntityId id) async {
    final row = await (_db.select(_db.financialEntities)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toFinancialEntity(row);
  }

  Future<void> seedDefaults(EntityId profileId) async {
    final existing = await listEntities(profileId);
    if (existing.isNotEmpty) return;

    await createEntity(
      profileId: profileId,
      name: 'Pessoal',
      kind: FinancialEntityKind.personal,
    );
  }

  Future<FinancialEntity> createEntity({
    required EntityId profileId,
    required String name,
    required FinancialEntityKind kind,
  }) async {
    FinanceLedgerPolicy.validateEntityName(name);
    final now = _clock();
    final entity = FinancialEntity.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      name: name,
      kind: kind,
      createdAt: now,
    );

    await _db.into(_db.financialEntities).insert(
          ColonyMappers.fromFinancialEntity(entity),
        );
    return entity;
  }

  Stream<List<FinancialAccount>> watchAccounts(EntityId profileId) {
    return (_db.select(_db.financialAccounts)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toFinancialAccount).toList());
  }

  Future<List<FinancialAccount>> listAccounts(EntityId profileId) async {
    final rows = await (_db.select(_db.financialAccounts)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toFinancialAccount).toList();
  }

  Future<FinancialAccount?> getAccountById(EntityId id) async {
    final row = await (_db.select(_db.financialAccounts)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toFinancialAccount(row);
  }

  Future<FinancialAccount> createAccount({
    required EntityId profileId,
    required EntityId entityId,
    required String institution,
    required String name,
    required FinancialAccountType type,
    required String currency,
    int currentBalanceMinor = 0,
    DateTime? balanceAsOf,
    bool includeInNetWorth = true,
    SensitiveDisplayMode sensitiveDisplayMode = SensitiveDisplayMode.hidden,
  }) async {
    FinanceLedgerPolicy.validateAccountName(name);
    final now = _clock();
    final account = FinancialAccount.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      entityId: entityId,
      institution: institution,
      name: name,
      type: type,
      currency: currency,
      currentBalanceMinor: currentBalanceMinor,
      balanceAsOf: balanceAsOf,
      includeInNetWorth: includeInNetWorth,
      sensitiveDisplayMode: sensitiveDisplayMode,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.financialAccounts).insert(
            ColonyMappers.fromFinancialAccount(account),
          );
      await _events.record(
        aggregateType: AggregateType.transaction,
        aggregateId: account.id,
        eventType: EventType.financialAccountCreated,
        payload: {
          'name': account.name,
          'type': account.type.name,
          'entity_id': entityId.value,
        },
        sourceType: SourceType.manual,
      );
    });

    return account;
  }

  Future<FinancialAccount> saveAccount(FinancialAccount account) async {
    FinanceLedgerPolicy.validateAccountName(account.name);
    final updated = account.copyWith(updatedAt: _clock());
    await _db.into(_db.financialAccounts).insertOnConflictUpdate(
          ColonyMappers.fromFinancialAccount(updated),
        );
    await _events.record(
      aggregateType: AggregateType.transaction,
      aggregateId: updated.id,
      eventType: EventType.financialAccountUpdated,
      payload: {
        'name': updated.name,
        'type': updated.type.name,
        'is_archived': updated.isArchived,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<FinancialAccount> archiveAccount(FinancialAccount account) async {
    return saveAccount(
      account.copyWith(
        isArchived: true,
        includeInNetWorth: false,
        updatedAt: _clock(),
      ),
    );
  }

  Stream<List<LedgerTransaction>> watchTransactions(EntityId profileId) {
    return (_db.select(_db.ledgerTransactions)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toLedgerTransaction).toList());
  }

  Future<List<LedgerTransaction>> listTransactions(EntityId profileId) async {
    final rows = await (_db.select(_db.ledgerTransactions)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .get();
    return rows.map(ColonyMappers.toLedgerTransaction).toList();
  }

  Future<List<LedgerTransaction>> listTransactionsForAccount(
    EntityId accountId,
  ) async {
    final rows = await (_db.select(_db.ledgerTransactions)
          ..where((t) => t.accountId.equals(accountId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .get();
    return rows.map(ColonyMappers.toLedgerTransaction).toList();
  }

  Future<LedgerTransaction?> getTransactionById(EntityId id) async {
    final row = await (_db.select(_db.ledgerTransactions)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toLedgerTransaction(row);
  }

  Future<LedgerTransaction> createTransaction({
    required EntityId profileId,
    required EntityId accountId,
    required DateTime occurredAt,
    required String descriptionOriginal,
    required int amountMinor,
    required String currency,
    required TransactionDirection direction,
    EntityId? categoryId,
    String? notes,
    String? fingerprint,
    SourceType sourceType = SourceType.manual,
  }) async {
    FinanceLedgerPolicy.validateTransactionAmount(amountMinor);
    FinanceLedgerPolicy.validateCategoryId(categoryId);
    final now = _clock();
    final transaction = LedgerTransaction.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      accountId: accountId,
      occurredAt: occurredAt,
      descriptionOriginal: descriptionOriginal,
      amountMinor: amountMinor,
      currency: currency,
      direction: direction,
      categoryId: categoryId,
      notes: notes,
      fingerprint: fingerprint,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.ledgerTransactions).insert(
            ColonyMappers.fromLedgerTransaction(transaction),
          );
      await _events.record(
        aggregateType: AggregateType.transaction,
        aggregateId: transaction.id,
        eventType: EventType.transactionCreated,
        payload: {
          'account_id': accountId.value,
          'description': transaction.descriptionOriginal,
          'amount_minor': transaction.amountMinor,
          'direction': transaction.direction.name,
        },
        sourceType: sourceType,
      );
    });

    return transaction;
  }

  /// Plans CSV import without writing (dedup by fingerprint).
  Future<FinanceCsvImportPlan> planCsvImport({
    required EntityId profileId,
    required List<FinanceCsvPreviewRow> preview,
    EntityId? accountOverride,
  }) async {
    final rows = accountOverride == null
        ? preview
        : FinanceCsvImportPolicy.withAccountOverride(
            rows: preview,
            accountId: accountOverride.value,
          );
    final existing = await listTransactions(profileId);
    return FinanceCsvImportPolicy.plan(
      preview: rows,
      existingFingerprints: existing.map((t) => t.fingerprint).toSet(),
    );
  }

  /// Applies a planned CSV import, preserving each row's fingerprint.
  Future<FinanceCsvImportPlan> applyCsvImport({
    required EntityId profileId,
    required FinanceCsvImportPlan plan,
  }) async {
    for (final row in plan.toImport) {
      await createTransaction(
        profileId: profileId,
        accountId: EntityId(row.accountId),
        occurredAt: row.occurredAt,
        descriptionOriginal: row.descriptionOriginal,
        amountMinor: row.amountMinor,
        currency: row.currency,
        direction: row.direction,
        categoryId:
            row.categoryId == null ? null : EntityId(row.categoryId!),
        fingerprint: row.fingerprint,
        sourceType: SourceType.import,
      );
    }
    return plan;
  }

  /// Plans then applies CSV rows (compat). Prefer [planCsvImport]/[applyCsvImport].
  Future<FinanceCsvImportPlan> importCsvPreview({
    required EntityId profileId,
    required List<FinanceCsvPreviewRow> preview,
    EntityId? accountOverride,
  }) async {
    final plan = await planCsvImport(
      profileId: profileId,
      preview: preview,
      accountOverride: accountOverride,
    );
    return applyCsvImport(profileId: profileId, plan: plan);
  }

  Future<LedgerTransaction> saveTransaction(LedgerTransaction transaction) async {
    FinanceLedgerPolicy.validateTransactionAmount(transaction.amountMinor);
    FinanceLedgerPolicy.validateCategoryId(transaction.categoryId);
    final updated = transaction.copyWith(updatedAt: _clock());
    await _db.into(_db.ledgerTransactions).insertOnConflictUpdate(
          ColonyMappers.fromLedgerTransaction(updated),
        );
    await _events.record(
      aggregateType: AggregateType.transaction,
      aggregateId: updated.id,
      eventType: EventType.transactionUpdated,
      payload: {
        'description': updated.descriptionOriginal,
        'amount_minor': updated.amountMinor,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<bool> fingerprintExists({
    required EntityId profileId,
    required String fingerprint,
  }) async {
    final row = await (_db.select(_db.ledgerTransactions)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.fingerprint.equals(fingerprint),
          )
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Checking (`Inter Conta`) or credit (`Inter Cartão`) created on demand.
  Future<FinancialAccount> ensureInterAccount({
    required EntityId profileId,
    required FinancialAccountType type,
  }) async {
    await seedDefaults(profileId);
    final name = type == FinancialAccountType.creditCard
        ? 'Inter Cartão'
        : 'Inter Conta';
    final existing = await listAccounts(profileId);
    for (final account in existing) {
      if (account.isArchived) continue;
      if (account.type != type) continue;
      final institution = account.institution.trim().toLowerCase();
      if (institution == 'inter' || account.name == name) {
        return account;
      }
    }
    final entities = await listEntities(profileId);
    if (entities.isEmpty) {
      throw StateError('Nenhuma entidade financeira para contas Inter');
    }
    return createAccount(
      profileId: profileId,
      entityId: entities.first.id,
      institution: 'Inter',
      name: name,
      type: type,
      currency: 'BRL',
    );
  }

  Future<List<FinancialAccount>> ensureInterAccounts(EntityId profileId) async {
    final checking = await ensureInterAccount(
      profileId: profileId,
      type: FinancialAccountType.checking,
    );
    final card = await ensureInterAccount(
      profileId: profileId,
      type: FinancialAccountType.creditCard,
    );
    return [checking, card];
  }

  Future<void> deleteTransaction(EntityId id) async {
    final existing = await getTransactionById(id);
    if (existing == null) return;

    await _db.transaction(() async {
      await (_db.delete(_db.ledgerTransactions)
            ..where((t) => t.id.equals(id.value)))
          .go();
      await _events.record(
        aggregateType: AggregateType.transaction,
        aggregateId: id,
        eventType: EventType.transactionDeleted,
        payload: {
          'description': existing.descriptionOriginal,
        },
        sourceType: SourceType.manual,
      );
    });
  }

  Stream<List<CategoryBudget>> watchBudgets(EntityId profileId) {
    return (_db.select(_db.categoryBudgets)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.categoryId)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toCategoryBudget).toList());
  }

  Future<List<CategoryBudget>> listBudgets(EntityId profileId) async {
    final rows = await (_db.select(_db.categoryBudgets)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toCategoryBudget).toList();
  }

  Future<CategoryBudget> createBudget({
    required EntityId profileId,
    required EntityId categoryId,
    required String currency,
    required int limitAmountMinor,
  }) async {
    final now = _clock();
    final budget = CategoryBudget.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      categoryId: categoryId,
      currency: currency,
      limitAmountMinor: limitAmountMinor,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.categoryBudgets)
          .insert(ColonyMappers.fromCategoryBudget(budget));
      await _events.record(
        aggregateType: AggregateType.budget,
        aggregateId: budget.id,
        eventType: EventType.categoryBudgetCreated,
        payload: {
          'category_id': budget.categoryId.value,
          'limit_amount_minor': budget.limitAmountMinor,
          'currency': budget.currency,
        },
        sourceType: SourceType.manual,
      );
    });
    return budget;
  }

  Future<CategoryBudget> saveBudget(CategoryBudget budget) async {
    final updated = budget.copyWith(updatedAt: _clock());
    await _db.into(_db.categoryBudgets).insertOnConflictUpdate(
          ColonyMappers.fromCategoryBudget(updated),
        );
    await _events.record(
      aggregateType: AggregateType.budget,
      aggregateId: updated.id,
      eventType: EventType.categoryBudgetUpdated,
      payload: {
        'category_id': updated.categoryId.value,
        'limit_amount_minor': updated.limitAmountMinor,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<void> deleteBudget(EntityId id) async {
    final row = await (_db.select(_db.categoryBudgets)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    if (row == null) return;
    final existing = ColonyMappers.toCategoryBudget(row);

    await _db.transaction(() async {
      await (_db.delete(_db.categoryBudgets)
            ..where((t) => t.id.equals(id.value)))
          .go();
      await _events.record(
        aggregateType: AggregateType.budget,
        aggregateId: id,
        eventType: EventType.categoryBudgetDeleted,
        payload: {
          'category_id': existing.categoryId.value,
        },
        sourceType: SourceType.manual,
      );
    });
  }
}

class ProjectRepository {
  ProjectRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<Project>> watchAll(EntityId profileId) {
    return (_db.select(_db.projects)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toProject).toList());
  }

  Stream<List<Project>> watchByStatus(EntityId profileId, ProjectStatus status) {
    return (_db.select(_db.projects)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.status.equals(status.name),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toProject).toList());
  }

  Future<List<Project>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.projects)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toProject).toList();
  }

  Future<Project?> getById(EntityId id) async {
    final row =
        await (_db.select(_db.projects)..where((t) => t.id.equals(id.value)))
            .getSingleOrNull();
    return row == null ? null : ColonyMappers.toProject(row);
  }

  Future<Project> create({
    required EntityId profileId,
    required String title,
    String? purpose,
    ProjectStatus status = ProjectStatus.active,
  }) async {
    final now = _clock();
    final project = Project.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      purpose: purpose,
      createdAt: now,
      status: status,
    );

    await _db.transaction(() async {
      await _db.into(_db.projects).insert(ColonyMappers.fromProject(project));
      await _events.record(
        aggregateType: AggregateType.project,
        aggregateId: project.id,
        eventType: EventType.projectCreated,
        payload: {
          'title': project.title,
          'status': project.status.name,
        },
        sourceType: SourceType.manual,
      );
    });

    return project;
  }

  Future<Project> save(Project project) async {
    final existing = await getById(project.id);
    if (existing != null &&
        existing.status != project.status &&
        !ProjectLifecyclePolicy.canTransition(existing.status, project.status)) {
      throw StateError(
        'Transição inválida: ${existing.status.name} → ${project.status.name}',
      );
    }
    await _db.into(_db.projects).insertOnConflictUpdate(
          ColonyMappers.fromProject(project),
        );
    await _events.record(
      aggregateType: AggregateType.project,
      aggregateId: project.id,
      eventType: EventType.projectUpdated,
      payload: {
        'title': project.title,
        'status': project.status.name,
      },
      sourceType: SourceType.manual,
    );
    return project;
  }

  Future<List<QuestProjectLink>> listLinks(EntityId profileId) async {
    final rows = await (_db.select(_db.questProjects).join([
      innerJoin(
        _db.quests,
        _db.quests.id.equalsExp(_db.questProjects.questId),
      ),
    ])
          ..where(_db.quests.profileId.equals(profileId.value)))
        .get();
    return rows
        .map((row) => ColonyMappers.toQuestProjectLink(row.readTable(_db.questProjects)))
        .toList();
  }

  Stream<List<Project>> watchLinkedToQuest(EntityId questId) {
    final query = _db.select(_db.projects).join([
      innerJoin(
        _db.questProjects,
        _db.questProjects.projectId.equalsExp(_db.projects.id),
      ),
    ])
      ..where(_db.questProjects.questId.equals(questId.value))
      ..orderBy([OrderingTerm.desc(_db.projects.updatedAt)]);

    return query.watch().map(
          (rows) => rows.map((row) => ColonyMappers.toProject(row.readTable(_db.projects))).toList(),
        );
  }

  Stream<List<Quest>> watchLinkedQuests(EntityId projectId) {
    final query = _db.select(_db.quests).join([
      innerJoin(
        _db.questProjects,
        _db.questProjects.questId.equalsExp(_db.quests.id),
      ),
    ])
      ..where(_db.questProjects.projectId.equals(projectId.value))
      ..orderBy([OrderingTerm.desc(_db.quests.updatedAt)]);

    return query.watch().map(
          (rows) => rows.map((row) => ColonyMappers.toQuest(row.readTable(_db.quests))).toList(),
        );
  }

  Future<void> linkQuest({
    required EntityId questId,
    required EntityId projectId,
  }) async {
    final now = _clock();
    final existing = await (_db.select(_db.questProjects)
          ..where(
            (t) =>
                t.questId.equals(questId.value) &
                t.projectId.equals(projectId.value),
          ))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.into(_db.questProjects).insert(
          ColonyMappers.fromQuestProjectLink(
            QuestProjectLink(
              questId: questId,
              projectId: projectId,
              linkedAt: now,
            ),
          ),
        );
  }

  Future<void> unlinkQuest({
    required EntityId questId,
    required EntityId projectId,
  }) async {
    await (_db.delete(_db.questProjects)
          ..where(
            (t) =>
                t.questId.equals(questId.value) &
                t.projectId.equals(projectId.value),
          ))
        .go();
  }
}

class DecisionRepository {
  DecisionRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<DecisionRecord>> watchAll(EntityId profileId) {
    return (_db.select(_db.decisionRecords)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.decidedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toDecisionRecord).toList());
  }

  Future<List<DecisionRecord>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.decisionRecords)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toDecisionRecord).toList();
  }

  Future<DecisionRecord?> getById(EntityId id) async {
    final row = await (_db.select(_db.decisionRecords)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toDecisionRecord(row);
  }

  Future<DecisionRecord> create({
    required EntityId profileId,
    required String title,
    required String context,
    required String decision,
    List<String> alternatives = const [],
    List<String> criteria = const [],
    List<String> assumptions = const [],
    List<String> expectedOutcomes = const [],
    List<String> risks = const [],
    DecisionReversibility reversibility = DecisionReversibility.moderate,
    DateTime? decidedAt,
    DateTime? reviewAt,
  }) async {
    final now = _clock();
    final record = DecisionRecord.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      context: context,
      decision: decision,
      alternatives: alternatives,
      criteria: criteria,
      assumptions: assumptions,
      expectedOutcomes: expectedOutcomes,
      risks: risks,
      reversibility: reversibility,
      decidedAt: decidedAt ?? now,
      reviewAt: reviewAt,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.decisionRecords).insert(ColonyMappers.fromDecisionRecord(record));
      await _events.record(
        aggregateType: AggregateType.decision,
        aggregateId: record.id,
        eventType: EventType.decisionCreated,
        payload: {
          'title': record.title,
          'reversibility': record.reversibility.name,
        },
        sourceType: SourceType.manual,
      );
    });

    return record;
  }

  Future<DecisionRecord> save(DecisionRecord record) async {
    await _db.into(_db.decisionRecords).insertOnConflictUpdate(
          ColonyMappers.fromDecisionRecord(record),
        );
    await _events.record(
      aggregateType: AggregateType.decision,
      aggregateId: record.id,
      eventType: EventType.decisionUpdated,
      payload: {
        'title': record.title,
        'reversibility': record.reversibility.name,
      },
      sourceType: SourceType.manual,
    );
    return record;
  }

  Future<List<QuestDecisionLink>> listLinks(EntityId profileId) async {
    final rows = await (_db.select(_db.questDecisions).join([
      innerJoin(
        _db.decisionRecords,
        _db.decisionRecords.id.equalsExp(_db.questDecisions.decisionId),
      ),
    ])
          ..where(_db.decisionRecords.profileId.equals(profileId.value)))
        .get();
    return rows
        .map((row) => ColonyMappers.toQuestDecisionLink(row.readTable(_db.questDecisions)))
        .toList();
  }

  Stream<List<DecisionRecord>> watchByQuest(EntityId questId) {
    final query = _db.select(_db.decisionRecords).join([
      innerJoin(
        _db.questDecisions,
        _db.questDecisions.decisionId.equalsExp(_db.decisionRecords.id),
      ),
    ])
      ..where(_db.questDecisions.questId.equals(questId.value))
      ..orderBy([OrderingTerm.desc(_db.decisionRecords.decidedAt)]);

    return query.watch().map(
          (rows) =>
              rows.map((row) => ColonyMappers.toDecisionRecord(row.readTable(_db.decisionRecords))).toList(),
        );
  }

  Future<void> linkQuest({
    required EntityId questId,
    required EntityId decisionId,
  }) async {
    final now = _clock();
    final existing = await (_db.select(_db.questDecisions)
          ..where(
            (t) =>
                t.questId.equals(questId.value) &
                t.decisionId.equals(decisionId.value),
          ))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.into(_db.questDecisions).insert(
          ColonyMappers.fromQuestDecisionLink(
            QuestDecisionLink(
              questId: questId,
              decisionId: decisionId,
              linkedAt: now,
            ),
          ),
        );
  }

  Future<void> unlinkQuest({
    required EntityId questId,
    required EntityId decisionId,
  }) async {
    await (_db.delete(_db.questDecisions)
          ..where(
            (t) =>
                t.questId.equals(questId.value) &
                t.decisionId.equals(decisionId.value),
          ))
        .go();
  }

  Future<void> delete(EntityId id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.questDecisions)
            ..where((t) => t.decisionId.equals(id.value)))
          .go();
      await (_db.delete(_db.decisionRecords)..where((t) => t.id.equals(id.value)))
          .go();
      await _events.record(
        aggregateType: AggregateType.decision,
        aggregateId: id,
        eventType: EventType.decisionDeleted,
        payload: const {},
        sourceType: SourceType.manual,
      );
    });
  }
}

class HealthRepository {
  HealthRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<HealthCondition>> watchAll(EntityId profileId) {
    return (_db.select(_db.healthConditions)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toHealthCondition).toList());
  }

  Future<List<HealthCondition>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.healthConditions)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toHealthCondition).toList();
  }

  Future<HealthCondition?> getById(EntityId id) async {
    final row = await (_db.select(_db.healthConditions)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toHealthCondition(row);
  }

  Future<HealthCondition> create({
    required EntityId profileId,
    required String title,
    required HealthConditionType type,
    HealthConditionStatus status = HealthConditionStatus.active,
    DateTime? onsetAt,
    int? severityUserReported,
    List<String> bodyRegions = const [],
    bool clinicianConfirmed = false,
    String? notes,
  }) async {
    HealthSafetyPolicy.validateTitle(title);
    HealthSafetyPolicy.validateSeverity(severityUserReported);
    final now = _clock();
    final condition = HealthCondition.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      type: type,
      status: status,
      onsetAt: onsetAt,
      severityUserReported: severityUserReported,
      bodyRegions: bodyRegions,
      clinicianConfirmed: clinicianConfirmed,
      notes: notes,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.healthConditions)
          .insert(ColonyMappers.fromHealthCondition(condition));
      await _events.record(
        aggregateType: AggregateType.health,
        aggregateId: condition.id,
        eventType: EventType.healthConditionCreated,
        payload: {
          'title': condition.title,
          'type': condition.type.name,
          'status': condition.status.name,
        },
        sourceType: SourceType.manual,
      );
    });
    return condition;
  }

  Future<HealthCondition> save(HealthCondition condition) async {
    HealthSafetyPolicy.validateTitle(condition.title);
    HealthSafetyPolicy.validateSeverity(condition.severityUserReported);
    final updated = condition.copyWith(updatedAt: _clock());
    await _db.into(_db.healthConditions).insertOnConflictUpdate(
          ColonyMappers.fromHealthCondition(updated),
        );
    await _events.record(
      aggregateType: AggregateType.health,
      aggregateId: updated.id,
      eventType: EventType.healthConditionUpdated,
      payload: {
        'title': updated.title,
        'status': updated.status.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<HealthCondition> archive(HealthCondition condition) async {
    final updated = condition.copyWith(
      status: HealthSafetyPolicy.nextStatusOnArchive(),
      updatedAt: _clock(),
    );
    await _db.into(_db.healthConditions).insertOnConflictUpdate(
          ColonyMappers.fromHealthCondition(updated),
        );
    await _events.record(
      aggregateType: AggregateType.health,
      aggregateId: updated.id,
      eventType: EventType.healthConditionStatusChanged,
      payload: {
        'from': condition.status.name,
        'to': updated.status.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Stream<List<SymptomEntry>> watchSymptomEntriesForCondition(
    EntityId conditionId,
  ) {
    return (_db.select(_db.symptomEntries)
          ..where((t) => t.conditionId.equals(conditionId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toSymptomEntry).toList());
  }

  Future<List<SymptomEntry>> listAllSymptomEntries(EntityId profileId) async {
    final rows = await (_db.select(_db.symptomEntries)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .get();
    return rows.map(ColonyMappers.toSymptomEntry).toList();
  }

  Future<SymptomEntry> logSymptomEntry({
    required EntityId profileId,
    EntityId? conditionId,
    required int intensity,
    DateTime? occurredAt,
    String? note,
    String? bodyRegion,
  }) async {
    HealthSafetyPolicy.validateSeverity(intensity);
    final now = _clock();
    final entry = SymptomEntry.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      conditionId: conditionId,
      occurredAt: occurredAt ?? now,
      intensity: intensity,
      note: note,
      bodyRegion: bodyRegion,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.symptomEntries)
          .insert(ColonyMappers.fromSymptomEntry(entry));
      await _events.record(
        aggregateType: AggregateType.health,
        aggregateId: entry.conditionId ?? entry.id,
        eventType: EventType.symptomEntryLogged,
        payload: {
          'entry_id': entry.id.value,
          'intensity': entry.intensity,
          if (entry.conditionId != null)
            'condition_id': entry.conditionId!.value,
        },
        sourceType: SourceType.manual,
      );
    });
    return entry;
  }

  Stream<List<HealthAppointment>> watchAppointments(EntityId profileId) {
    return (_db.select(_db.healthAppointments)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toHealthAppointment).toList());
  }

  Future<List<HealthAppointment>> listAppointments(EntityId profileId) async {
    final rows = await (_db.select(_db.healthAppointments)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .get();
    return rows.map(ColonyMappers.toHealthAppointment).toList();
  }

  Future<HealthAppointment> createAppointment({
    required EntityId profileId,
    required String title,
    required DateTime scheduledAt,
    String? locationLabel,
    String? clinicianLabel,
    String? notes,
  }) async {
    final now = _clock();
    final appointment = HealthAppointment.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      scheduledAt: scheduledAt,
      locationLabel: locationLabel,
      clinicianLabel: clinicianLabel,
      notes: notes,
      createdAt: now,
    );
    await _db.transaction(() async {
      await _db
          .into(_db.healthAppointments)
          .insert(ColonyMappers.fromHealthAppointment(appointment));
      await _events.record(
        aggregateType: AggregateType.health,
        aggregateId: appointment.id,
        eventType: EventType.healthAppointmentCreated,
        payload: {
          'title': appointment.title,
          'scheduled_at': appointment.scheduledAt.toIso8601String(),
        },
        sourceType: SourceType.manual,
      );
    });
    return appointment;
  }

  Future<HealthAppointment> saveAppointment(HealthAppointment appointment) async {
    final updated = appointment.copyWith(updatedAt: _clock());
    await _db.into(_db.healthAppointments).insertOnConflictUpdate(
          ColonyMappers.fromHealthAppointment(updated),
        );
    await _events.record(
      aggregateType: AggregateType.health,
      aggregateId: updated.id,
      eventType: EventType.healthAppointmentUpdated,
      payload: {
        'title': updated.title,
        'status': updated.status.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }
}

class InventoryRepository {
  InventoryRepository(this._db, this._ids, this._clock, this._events, [this._sync]);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;
  final SyncRepository? _sync;

  Stream<List<InventoryItem>> watchAll(EntityId profileId) {
    return (_db.select(_db.inventoryItems)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toInventoryItem).toList());
  }

  Future<List<InventoryItem>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.inventoryItems)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toInventoryItem).toList();
  }

  Future<InventoryItem?> getById(EntityId id) async {
    final row = await (_db.select(_db.inventoryItems)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toInventoryItem(row);
  }

  Future<InventoryItem> create({
    required EntityId profileId,
    required String name,
    required InventoryCategory category,
    InventoryItemStatus status = InventoryItemStatus.active,
    String? locationLabel,
    String? notes,
    List<String> tags = const [],
    DateTime? purchaseDate,
    int? purchasePriceMinor,
    String? purchaseCurrency,
    DateTime? warrantyEnd,
  }) async {
    final now = _clock();
    final item = InventoryItem.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      name: name,
      category: category,
      status: status,
      locationLabel: locationLabel,
      notes: notes,
      tags: tags,
      purchaseDate: purchaseDate,
      purchasePriceMinor: purchasePriceMinor,
      purchaseCurrency: purchaseCurrency,
      warrantyEnd: warrantyEnd,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.inventoryItems)
          .insert(ColonyMappers.fromInventoryItem(item));
      await _events.record(
        aggregateType: AggregateType.inventory,
        aggregateId: item.id,
        eventType: EventType.inventoryItemCreated,
        payload: {
          'name': item.name,
          'category': item.category.name,
          'status': item.status.name,
        },
        sourceType: SourceType.manual,
      );
    });
    // Pilot outbox enqueue (ADR-025) — best-effort; never blocks create.
    final sync = _sync;
    if (sync != null) {
      try {
        await sync.enqueue(
          entityType: 'inventory_item',
          entityId: item.id,
          payloadJson: '{"id":"${item.id.value}"}',
        );
      } catch (_) {}
    }
    return item;
  }

  Future<InventoryItem> save(InventoryItem item) async {
    final updated = item.copyWith(updatedAt: _clock());
    await _db.into(_db.inventoryItems).insertOnConflictUpdate(
          ColonyMappers.fromInventoryItem(updated),
        );
    await _events.record(
      aggregateType: AggregateType.inventory,
      aggregateId: updated.id,
      eventType: EventType.inventoryItemUpdated,
      payload: {
        'name': updated.name,
        'status': updated.status.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<InventoryItem> archive(InventoryItem item) async {
    final updated = item.copyWith(
      status: InventoryItemStatus.archived,
      updatedAt: _clock(),
    );
    await _db.into(_db.inventoryItems).insertOnConflictUpdate(
          ColonyMappers.fromInventoryItem(updated),
        );
    await _events.record(
      aggregateType: AggregateType.inventory,
      aggregateId: updated.id,
      eventType: EventType.inventoryItemStatusChanged,
      payload: {
        'from': item.status.name,
        'to': updated.status.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<List<QuestInventoryLink>> listQuestLinks(EntityId profileId) async {
    final rows = await (_db.select(_db.questInventory).join([
      innerJoin(
        _db.inventoryItems,
        _db.inventoryItems.id.equalsExp(_db.questInventory.inventoryItemId),
      ),
    ])
          ..where(_db.inventoryItems.profileId.equals(profileId.value)))
        .get();
    return rows
        .map(
          (row) => ColonyMappers.toQuestInventoryLink(
            row.readTable(_db.questInventory),
          ),
        )
        .toList();
  }

  Stream<List<Quest>> watchLinkedQuests(EntityId inventoryItemId) {
    final query = _db.select(_db.quests).join([
      innerJoin(
        _db.questInventory,
        _db.questInventory.questId.equalsExp(_db.quests.id),
      ),
    ])
      ..where(
        _db.questInventory.inventoryItemId.equals(inventoryItemId.value),
      )
      ..orderBy([OrderingTerm.desc(_db.quests.updatedAt)]);

    return query.watch().map(
          (rows) => rows
              .map((row) => ColonyMappers.toQuest(row.readTable(_db.quests)))
              .toList(),
        );
  }

  Future<void> linkQuest({
    required EntityId questId,
    required EntityId inventoryItemId,
  }) async {
    final now = _clock();
    final existing = await (_db.select(_db.questInventory)
          ..where(
            (t) =>
                t.questId.equals(questId.value) &
                t.inventoryItemId.equals(inventoryItemId.value),
          ))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.into(_db.questInventory).insert(
          ColonyMappers.fromQuestInventoryLink(
            QuestInventoryLink(
              questId: questId,
              inventoryItemId: inventoryItemId,
              linkedAt: now,
            ),
          ),
        );
  }

  Future<void> unlinkQuest({
    required EntityId questId,
    required EntityId inventoryItemId,
  }) async {
    await (_db.delete(_db.questInventory)
          ..where(
            (t) =>
                t.questId.equals(questId.value) &
                t.inventoryItemId.equals(inventoryItemId.value),
          ))
        .go();
  }
}

class PersonRepository {
  PersonRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<Person>> watchAll(EntityId profileId) {
    return (_db.select(_db.people)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toPerson).toList());
  }

  Future<List<Person>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.people)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toPerson).toList();
  }

  Future<Person> create({
    required EntityId profileId,
    required String displayName,
    String? preferredName,
    List<String> relationshipTypes = const [],
    String? notes,
  }) async {
    final now = _clock();
    final person = Person.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      displayName: displayName,
      preferredName: preferredName,
      relationshipTypes: relationshipTypes,
      notes: notes,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.people).insert(ColonyMappers.fromPerson(person));
      await _events.record(
        aggregateType: AggregateType.person,
        aggregateId: person.id,
        eventType: EventType.personCreated,
        payload: {
          'display_name': person.displayName,
        },
        sourceType: SourceType.manual,
      );
    });
    return person;
  }

  Future<Person> save(Person person) async {
    final updated = person.copyWith(updatedAt: _clock());
    await _db
        .into(_db.people)
        .insertOnConflictUpdate(ColonyMappers.fromPerson(updated));
    await _events.record(
      aggregateType: AggregateType.person,
      aggregateId: updated.id,
      eventType: EventType.personUpdated,
      payload: {
        'display_name': updated.displayName,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<Person> archive(Person person) async {
    final now = _clock();
    final updated = person.copyWith(archivedAt: now, updatedAt: now);
    await _db
        .into(_db.people)
        .insertOnConflictUpdate(ColonyMappers.fromPerson(updated));
    await _events.record(
      aggregateType: AggregateType.person,
      aggregateId: updated.id,
      eventType: EventType.personArchived,
      payload: {
        'display_name': updated.displayName,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Stream<List<PersonInteraction>> watchInteractionsForPerson(EntityId personId) {
    return (_db.select(_db.personInteractions)
          ..where((t) => t.personId.equals(personId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toPersonInteraction).toList());
  }

  Future<List<PersonInteraction>> listAllInteractions(EntityId profileId) async {
    final rows = await (_db.select(_db.personInteractions)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toPersonInteraction).toList();
  }

  Future<PersonInteraction> logInteraction({
    required EntityId profileId,
    required Person person,
    required InteractionKind kind,
    required DateTime occurredAt,
    String? note,
  }) async {
    final now = _clock();
    final interaction = PersonInteraction.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      personId: person.id,
      kind: kind,
      occurredAt: occurredAt,
      note: note,
      createdAt: now,
    );
    final personUpdated = person.copyWith(
      lastInteractionAt: interaction.occurredAt,
      updatedAt: now,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.personInteractions)
          .insert(ColonyMappers.fromPersonInteraction(interaction));
      await _db
          .into(_db.people)
          .insertOnConflictUpdate(ColonyMappers.fromPerson(personUpdated));
      await _events.record(
        aggregateType: AggregateType.personInteraction,
        aggregateId: interaction.id,
        eventType: EventType.personInteractionLogged,
        payload: {
          'person_id': person.id.value,
          'kind': kind.name,
        },
        sourceType: SourceType.manual,
      );
    });
    return interaction;
  }
}

class TripRepository {
  TripRepository(
    this._db,
    this._ids,
    this._clock,
    this._events, [
    this._sync,
  ]);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;
  final SyncRepository? _sync;

  Stream<List<Trip>> watchAll(EntityId profileId) {
    return (_db.select(_db.trips)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toTrip).toList());
  }

  Future<List<Trip>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.trips)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toTrip).toList();
  }

  Future<Trip> create({
    required EntityId profileId,
    required String title,
    List<String> destinations = const [],
    DateTime? startAt,
    DateTime? endAt,
    String? purpose,
    String? notes,
    TripStatus status = TripStatus.planned,
  }) async {
    final now = _clock();
    final trip = Trip.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      destinations: destinations,
      startAt: startAt,
      endAt: endAt,
      purpose: purpose,
      notes: notes,
      status: status,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.trips).insert(ColonyMappers.fromTrip(trip));
      await _events.record(
        aggregateType: AggregateType.trip,
        aggregateId: trip.id,
        eventType: EventType.tripCreated,
        payload: {
          'title': trip.title,
          'status': trip.status.name,
        },
        sourceType: SourceType.manual,
      );
    });
    // Pilot outbox enqueue (ADR-025) — best-effort; never blocks create.
    final sync = _sync;
    if (sync != null) {
      try {
        await sync.enqueue(
          entityType: 'trip',
          entityId: trip.id,
          payloadJson: '{"id":"${trip.id.value}"}',
        );
      } catch (_) {}
    }
    return trip;
  }

  Future<Trip> save(Trip trip) async {
    final updated = trip.copyWith(updatedAt: _clock());
    await _db
        .into(_db.trips)
        .insertOnConflictUpdate(ColonyMappers.fromTrip(updated));
    await _events.record(
      aggregateType: AggregateType.trip,
      aggregateId: updated.id,
      eventType: EventType.tripUpdated,
      payload: {
        'title': updated.title,
        'status': updated.status.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<Trip> setStatus(Trip trip, TripStatus status) async {
    final updated = trip.copyWith(status: status, updatedAt: _clock());
    await _db
        .into(_db.trips)
        .insertOnConflictUpdate(ColonyMappers.fromTrip(updated));
    await _events.record(
      aggregateType: AggregateType.trip,
      aggregateId: updated.id,
      eventType: EventType.tripStatusChanged,
      payload: {
        'from': trip.status.name,
        'to': updated.status.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<List<TripInventoryLink>> listInventoryLinks(EntityId profileId) async {
    final rows = await (_db.select(_db.tripInventory).join([
      innerJoin(
        _db.trips,
        _db.trips.id.equalsExp(_db.tripInventory.tripId),
      ),
    ])
          ..where(_db.trips.profileId.equals(profileId.value)))
        .get();
    return rows
        .map(
          (row) => ColonyMappers.toTripInventoryLink(
            row.readTable(_db.tripInventory),
          ),
        )
        .toList();
  }

  Stream<List<InventoryItem>> watchLinkedInventory(EntityId tripId) {
    final query = _db.select(_db.inventoryItems).join([
      innerJoin(
        _db.tripInventory,
        _db.tripInventory.inventoryItemId.equalsExp(_db.inventoryItems.id),
      ),
    ])
      ..where(_db.tripInventory.tripId.equals(tripId.value))
      ..orderBy([OrderingTerm.desc(_db.inventoryItems.updatedAt)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => ColonyMappers.toInventoryItem(
                  row.readTable(_db.inventoryItems),
                ),
              )
              .toList(),
        );
  }

  Future<void> linkInventoryItem({
    required EntityId tripId,
    required EntityId inventoryItemId,
  }) async {
    final now = _clock();
    final existing = await (_db.select(_db.tripInventory)
          ..where(
            (t) =>
                t.tripId.equals(tripId.value) &
                t.inventoryItemId.equals(inventoryItemId.value),
          ))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.into(_db.tripInventory).insert(
          ColonyMappers.fromTripInventoryLink(
            TripInventoryLink(
              tripId: tripId,
              inventoryItemId: inventoryItemId,
              linkedAt: now,
            ),
          ),
        );
  }

  Future<void> unlinkInventoryItem({
    required EntityId tripId,
    required EntityId inventoryItemId,
  }) async {
    await (_db.delete(_db.tripInventory)
          ..where(
            (t) =>
                t.tripId.equals(tripId.value) &
                t.inventoryItemId.equals(inventoryItemId.value),
          ))
        .go();
  }

  /// Copies packing links from [sourceTripId] onto [targetTripId].
  /// Skips items already linked. Returns how many new links were created.
  Future<int> copyInventoryLinksFrom({
    required EntityId sourceTripId,
    required EntityId targetTripId,
  }) async {
    if (sourceTripId == targetTripId) return 0;
    final sourceItems = await watchLinkedInventory(sourceTripId).first;
    final targetItems = await watchLinkedInventory(targetTripId).first;
    final missing = TripPackingCopyPolicy.missingItemIds(
      sourceItemIds: sourceItems.map((i) => i.id),
      targetItemIds: targetItems.map((i) => i.id),
    );
    for (final itemId in missing) {
      await linkInventoryItem(
        tripId: targetTripId,
        inventoryItemId: itemId,
      );
    }
    return missing.length;
  }
}

class OrganizationRepository {
  OrganizationRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<Organization>> watchAll(EntityId profileId) {
    return (_db.select(_db.organizations)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toOrganization).toList());
  }

  Future<List<Organization>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.organizations)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toOrganization).toList();
  }

  Future<Organization> create({
    required EntityId profileId,
    required String name,
    required OrganizationKind kind,
    String? notes,
  }) async {
    final now = _clock();
    final org = Organization.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      name: name,
      kind: kind,
      notes: notes,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.organizations)
          .insert(ColonyMappers.fromOrganization(org));
      await _events.record(
        aggregateType: AggregateType.organization,
        aggregateId: org.id,
        eventType: EventType.organizationCreated,
        payload: {
          'name': org.name,
          'kind': org.kind.name,
        },
        sourceType: SourceType.manual,
      );
    });
    return org;
  }

  Future<Organization> save(Organization organization) async {
    final updated = organization.copyWith(updatedAt: _clock());
    await _db
        .into(_db.organizations)
        .insertOnConflictUpdate(ColonyMappers.fromOrganization(updated));
    await _events.record(
      aggregateType: AggregateType.organization,
      aggregateId: updated.id,
      eventType: EventType.organizationUpdated,
      payload: {
        'name': updated.name,
        'kind': updated.kind.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<Organization> archive(Organization organization) async {
    final now = _clock();
    final updated =
        organization.copyWith(archivedAt: now, updatedAt: now);
    await _db
        .into(_db.organizations)
        .insertOnConflictUpdate(ColonyMappers.fromOrganization(updated));
    await _events.record(
      aggregateType: AggregateType.organization,
      aggregateId: updated.id,
      eventType: EventType.organizationArchived,
      payload: {
        'name': updated.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<List<PersonOrganizationLink>> listMemberships(
    EntityId profileId,
  ) async {
    final rows = await (_db.select(_db.personOrganizations).join([
      innerJoin(
        _db.organizations,
        _db.organizations.id.equalsExp(_db.personOrganizations.organizationId),
      ),
    ])
          ..where(_db.organizations.profileId.equals(profileId.value)))
        .get();
    return rows
        .map(
          (row) => ColonyMappers.toPersonOrganizationLink(
            row.readTable(_db.personOrganizations),
          ),
        )
        .toList();
  }

  Stream<List<Person>> watchMembers(EntityId organizationId) {
    final query = _db.select(_db.people).join([
      innerJoin(
        _db.personOrganizations,
        _db.personOrganizations.personId.equalsExp(_db.people.id),
      ),
    ])
      ..where(
        _db.personOrganizations.organizationId.equals(organizationId.value),
      )
      ..orderBy([OrderingTerm.desc(_db.people.updatedAt)]);

    return query.watch().map(
          (rows) => rows
              .map((row) => ColonyMappers.toPerson(row.readTable(_db.people)))
              .toList(),
        );
  }

  Stream<List<Organization>> watchMembershipsForPerson(EntityId personId) {
    final query = _db.select(_db.organizations).join([
      innerJoin(
        _db.personOrganizations,
        _db.personOrganizations.organizationId.equalsExp(_db.organizations.id),
      ),
    ])
      ..where(_db.personOrganizations.personId.equals(personId.value))
      ..orderBy([OrderingTerm.desc(_db.organizations.updatedAt)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => ColonyMappers.toOrganization(
                  row.readTable(_db.organizations),
                ),
              )
              .toList(),
        );
  }

  Future<void> linkPerson({
    required EntityId personId,
    required EntityId organizationId,
    String? role,
  }) async {
    final now = _clock();
    final existing = await (_db.select(_db.personOrganizations)
          ..where(
            (t) =>
                t.personId.equals(personId.value) &
                t.organizationId.equals(organizationId.value),
          ))
        .getSingleOrNull();
    if (existing != null) return;

    final trimmedRole = role?.trim();
    await _db.into(_db.personOrganizations).insert(
          ColonyMappers.fromPersonOrganizationLink(
            PersonOrganizationLink(
              personId: personId,
              organizationId: organizationId,
              linkedAt: now,
              role: (trimmedRole == null || trimmedRole.isEmpty)
                  ? null
                  : trimmedRole,
            ),
          ),
        );
  }

  Future<void> unlinkPerson({
    required EntityId personId,
    required EntityId organizationId,
  }) async {
    await (_db.delete(_db.personOrganizations)
          ..where(
            (t) =>
                t.personId.equals(personId.value) &
                t.organizationId.equals(organizationId.value),
          ))
        .go();
  }
}

class HomeMaintenanceRepository {
  HomeMaintenanceRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<HomeMaintenanceTask>> watchAll(EntityId profileId) {
    return (_db.select(_db.homeMaintenanceTasks)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([
            (t) => OrderingTerm.asc(t.nextDueAt),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toHomeMaintenanceTask).toList());
  }

  Future<List<HomeMaintenanceTask>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.homeMaintenanceTasks)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toHomeMaintenanceTask).toList();
  }

  Future<HomeMaintenanceTask> create({
    required EntityId profileId,
    required String title,
    required String systemOrItem,
    int? cadenceDays,
    DateTime? nextDueAt,
    String? vendorLabel,
    int? estimatedCostMinor,
    String? currency,
    String? notes,
    EntityId? linkedInventoryItemId,
  }) async {
    final now = _clock();
    final task = HomeMaintenanceTask.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      systemOrItem: systemOrItem,
      cadenceDays: cadenceDays,
      nextDueAt: nextDueAt,
      vendorLabel: vendorLabel,
      estimatedCostMinor: estimatedCostMinor,
      currency: currency,
      notes: notes,
      linkedInventoryItemId: linkedInventoryItemId,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.homeMaintenanceTasks)
          .insert(ColonyMappers.fromHomeMaintenanceTask(task));
      await _events.record(
        aggregateType: AggregateType.homeMaintenance,
        aggregateId: task.id,
        eventType: EventType.homeMaintenanceCreated,
        payload: {
          'title': task.title,
          'system_or_item': task.systemOrItem,
        },
        sourceType: SourceType.manual,
      );
    });
    return task;
  }

  Future<HomeMaintenanceTask> save(HomeMaintenanceTask task) async {
    final updated = task.copyWith(updatedAt: _clock());
    await _db
        .into(_db.homeMaintenanceTasks)
        .insertOnConflictUpdate(ColonyMappers.fromHomeMaintenanceTask(updated));
    await _events.record(
      aggregateType: AggregateType.homeMaintenance,
      aggregateId: updated.id,
      eventType: EventType.homeMaintenanceUpdated,
      payload: {
        'title': updated.title,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<HomeMaintenanceTask> markDone(HomeMaintenanceTask task) async {
    final updated = task.markDone(_clock());
    await _db
        .into(_db.homeMaintenanceTasks)
        .insertOnConflictUpdate(ColonyMappers.fromHomeMaintenanceTask(updated));
    await _events.record(
      aggregateType: AggregateType.homeMaintenance,
      aggregateId: updated.id,
      eventType: EventType.homeMaintenanceCompleted,
      payload: {
        'title': updated.title,
        if (updated.lastDoneAt != null)
          'last_done_at': updated.lastDoneAt!.toUtc().toIso8601String(),
        if (updated.nextDueAt != null)
          'next_due_at': updated.nextDueAt!.toUtc().toIso8601String(),
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<HomeMaintenanceTask> archive(HomeMaintenanceTask task) async {
    final now = _clock();
    final updated = task.copyWith(archivedAt: now, updatedAt: now);
    await _db
        .into(_db.homeMaintenanceTasks)
        .insertOnConflictUpdate(ColonyMappers.fromHomeMaintenanceTask(updated));
    await _events.record(
      aggregateType: AggregateType.homeMaintenance,
      aggregateId: updated.id,
      eventType: EventType.homeMaintenanceArchived,
      payload: {
        'title': updated.title,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }
}

class SyncRepository {
  SyncRepository(this._db, this._ids, this._clock, this._events)
      : _syncIds = UuidIdGenerator.v7(() => const Uuid().v4());

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  /// Separate generator so outbox ops never drain FixedIdGenerator in tests.
  final IdGenerator _syncIds;

  Stream<List<SyncOperation>> watchPending() {
    return (_db.select(_db.syncOperations)
          ..where(
            (t) => t.status.isIn([
              SyncOpStatus.pending.name,
              SyncOpStatus.processing.name,
              SyncOpStatus.failed.name,
            ]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toSyncOperation).toList());
  }

  Future<List<SyncOperation>> listPending() async {
    final rows = await (_db.select(_db.syncOperations)
          ..where((t) => t.status.equals(SyncOpStatus.pending.name)))
        .get();
    return rows.map(ColonyMappers.toSyncOperation).toList();
  }

  Future<DeviceIdentity?> getLocalDevice() async {
    final row = await (_db.select(_db.deviceIdentities)..limit(1))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toDeviceIdentity(row);
  }

  Future<DeviceIdentity> ensureLocalDevice({String label = 'Este dispositivo'}) async {
    final existing = await getLocalDevice();
    if (existing != null) {
      final touched = existing.touch(_clock());
      await _db
          .into(_db.deviceIdentities)
          .insertOnConflictUpdate(ColonyMappers.fromDeviceIdentity(touched));
      return touched;
    }
    final now = _clock();
    final device = DeviceIdentity.create(
      id: EntityId(_syncIds.newId()),
      label: label,
      createdAt: now,
    );
    await _db.transaction(() async {
      await _db
          .into(_db.deviceIdentities)
          .insert(ColonyMappers.fromDeviceIdentity(device));
      await _events.record(
        aggregateType: AggregateType.deviceIdentity,
        aggregateId: device.id,
        eventType: EventType.deviceIdentityEnsured,
        payload: {'label': device.label},
        sourceType: SourceType.manual,
        id: EntityId(_syncIds.newId()),
      );
    });
    return device;
  }

  Future<SyncOperation> enqueue({
    required String entityType,
    required EntityId entityId,
    SyncOpKind operation = SyncOpKind.upsert,
    int? baseVersion,
    required String payloadJson,
  }) async {
    await ensureLocalDevice();
    final now = _clock();
    final op = SyncOperation.enqueue(
      id: EntityId(_syncIds.newId()),
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      baseVersion: baseVersion,
      payloadJson: payloadJson,
      createdAt: now,
    );
    await _db.transaction(() async {
      await _db
          .into(_db.syncOperations)
          .insert(ColonyMappers.fromSyncOperation(op));
      await _events.record(
        aggregateType: AggregateType.syncOperation,
        aggregateId: op.id,
        eventType: EventType.syncOperationEnqueued,
        payload: {
          'entity_type': op.entityType,
          'entity_id': op.entityId.value,
          'operation': op.operation.name,
        },
        sourceType: SourceType.manual,
        id: EntityId(_syncIds.newId()),
      );
    });
    return op;
  }

  /// Local no-op worker: ack all pending ops without network (ADR-025 stub).
  Future<int> processLocalNoop() async {
    final pending = await listPending();
    if (pending.isEmpty) return 0;
    final now = _clock();
    await _db.transaction(() async {
      for (final op in pending) {
        final acked = op.ackLocal(now);
        await _db
            .into(_db.syncOperations)
            .insertOnConflictUpdate(ColonyMappers.fromSyncOperation(acked));
        await _events.record(
          aggregateType: AggregateType.syncOperation,
          aggregateId: acked.id,
          eventType: EventType.syncOperationAcked,
          payload: {
            'entity_type': acked.entityType,
            'entity_id': acked.entityId.value,
            'local_noop': true,
          },
          sourceType: SourceType.manual,
          id: EntityId(_syncIds.newId()),
        );
      }
    });
    return pending.length;
  }
}

class CommitmentRepository {
  CommitmentRepository(
    this._db,
    this._ids,
    this._clock,
    this._events, [
    this._sync,
  ]);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;
  final SyncRepository? _sync;

  Stream<List<Commitment>> watchAll(EntityId profileId) {
    return (_db.select(_db.commitments)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([
            (t) => OrderingTerm.asc(t.dueAt),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toCommitment).toList());
  }

  Future<List<Commitment>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.commitments)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toCommitment).toList();
  }

  Future<Commitment> create({
    required EntityId profileId,
    required String description,
    String madeByLabel = 'eu',
    EntityId? madeToPersonId,
    EntityId? madeToOrganizationId,
    String? madeToLabel,
    DateTime? dueAt,
    String? notes,
    EntityId? linkedQuestId,
  }) async {
    final now = _clock();
    final commitment = Commitment.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      description: description,
      madeByLabel: madeByLabel,
      madeToPersonId: madeToPersonId,
      madeToOrganizationId: madeToOrganizationId,
      madeToLabel: madeToLabel,
      dueAt: dueAt,
      notes: notes,
      linkedQuestId: linkedQuestId,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db
          .into(_db.commitments)
          .insert(ColonyMappers.fromCommitment(commitment));
      await _events.record(
        aggregateType: AggregateType.commitment,
        aggregateId: commitment.id,
        eventType: EventType.commitmentCreated,
        payload: {
          'description': commitment.description,
          'status': commitment.status.name,
        },
        sourceType: SourceType.manual,
      );
    });
    // Pilot outbox enqueue (ADR-025) — best-effort; never blocks create.
    final sync = _sync;
    if (sync != null) {
      try {
        await sync.enqueue(
          entityType: 'commitment',
          entityId: commitment.id,
          payloadJson: '{"id":"${commitment.id.value}"}',
        );
      } catch (_) {
        // Local-first: sync failure must not fail the mutation.
      }
    }
    return commitment;
  }

  Future<Commitment> save(Commitment commitment) async {
    final updated = commitment.copyWith(updatedAt: _clock());
    await _db
        .into(_db.commitments)
        .insertOnConflictUpdate(ColonyMappers.fromCommitment(updated));
    await _events.record(
      aggregateType: AggregateType.commitment,
      aggregateId: updated.id,
      eventType: EventType.commitmentUpdated,
      payload: {
        'description': updated.description,
        'status': updated.status.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<Commitment> setStatus(
    Commitment commitment,
    CommitmentStatus status,
  ) async {
    final updated = commitment.withStatus(status, _clock());
    await _db
        .into(_db.commitments)
        .insertOnConflictUpdate(ColonyMappers.fromCommitment(updated));
    await _events.record(
      aggregateType: AggregateType.commitment,
      aggregateId: updated.id,
      eventType: EventType.commitmentStatusChanged,
      payload: {
        'from': commitment.status.name,
        'to': updated.status.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }
}

class IntegrationRepository {
  IntegrationRepository(
    this._db,
    this._ids,
    this._clock,
    this._events,
    this._finance,
  );

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;
  final FinanceRepository _finance;

  Stream<List<IntegrationConsent>> watchConsents(EntityId profileId) {
    return (_db.select(_db.integrationConsents)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.kind)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toIntegrationConsent).toList());
  }

  Future<List<IntegrationConsent>> listConsents(EntityId profileId) async {
    final rows = await (_db.select(_db.integrationConsents)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toIntegrationConsent).toList();
  }

  Stream<List<ExternalCalendarEvent>> watchCalendarEvents(EntityId profileId) {
    return (_db.select(_db.externalCalendarEvents)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.startAt)]))
        .watch()
        .map(
          (rows) => rows.map(ColonyMappers.toExternalCalendarEvent).toList(),
        );
  }

  Future<List<ExternalCalendarEvent>> listCalendarEvents(
    EntityId profileId,
  ) async {
    final rows = await (_db.select(_db.externalCalendarEvents)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toExternalCalendarEvent).toList();
  }

  Future<IntegrationConsent> ensureConsent({
    required EntityId profileId,
    required IntegrationKind kind,
  }) async {
    final existing = await (_db.select(_db.integrationConsents)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.kind.equals(kind.name),
          ))
        .getSingleOrNull();
    if (existing != null) {
      return ColonyMappers.toIntegrationConsent(existing);
    }
    final now = _clock();
    final consent = IntegrationConsent.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      kind: kind,
      createdAt: now,
    );
    await _db
        .into(_db.integrationConsents)
        .insert(ColonyMappers.fromIntegrationConsent(consent));
    return consent;
  }

  Future<IntegrationConsent> setConsentEnabled({
    required EntityId profileId,
    required IntegrationKind kind,
    required bool enabled,
  }) async {
    final current = await ensureConsent(profileId: profileId, kind: kind);
    final now = _clock();
    final updated = enabled ? current.grant(now) : current.revoke(now);
    await _db
        .into(_db.integrationConsents)
        .insertOnConflictUpdate(ColonyMappers.fromIntegrationConsent(updated));
    await _events.record(
      aggregateType: AggregateType.integrationConsent,
      aggregateId: updated.id,
      eventType: enabled
          ? EventType.integrationConsentGranted
          : EventType.integrationConsentRevoked,
      payload: {'kind': kind.name, 'enabled': enabled},
      sourceType: SourceType.manual,
    );
    return updated;
  }

  /// Persist confirmed ICS preview rows. Requires calendarIcs consent enabled.
  Future<List<ExternalCalendarEvent>> importCalendarPreviews({
    required EntityId profileId,
    required List<IcsEventPreview> previews,
  }) async {
    final consent = await ensureConsent(
      profileId: profileId,
      kind: IntegrationKind.calendarIcs,
    );
    if (!consent.enabled) {
      throw StateError('Integração ICS desativada; conceda opt-in primeiro');
    }
    if (previews.isEmpty) return const [];
    final now = _clock();
    final created = <ExternalCalendarEvent>[];
    await _db.transaction(() async {
      for (final preview in previews) {
        final event = ExternalCalendarEvent.fromPreview(
          id: EntityId(_ids.newId()),
          profileId: profileId,
          preview: preview,
          importedAt: now,
        );
        await _db
            .into(_db.externalCalendarEvents)
            .insert(ColonyMappers.fromExternalCalendarEvent(event));
        created.add(event);
      }
      await _events.record(
        aggregateType: AggregateType.externalCalendarEvent,
        aggregateId: created.first.id,
        eventType: EventType.externalCalendarEventsImported,
        payload: {
          'count': created.length,
          'titles': created.map((e) => e.title).take(5).toList(),
        },
        sourceType: SourceType.integration,
      );
    });
    return created;
  }

  Stream<List<CapturedNotification>> watchCapturedNotifications(
    EntityId profileId,
  ) {
    return (_db.select(_db.capturedNotifications)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.postedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toCapturedNotification).toList());
  }

  Future<List<CapturedNotification>> listCapturedNotifications(
    EntityId profileId,
  ) async {
    final rows = await (_db.select(_db.capturedNotifications)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.postedAt)]))
        .get();
    return rows.map(ColonyMappers.toCapturedNotification).toList();
  }

  /// Persist a captured notification and book finance spends when extracted.
  /// OTP/ignored payloads are dropped. Duplicate [nativeKey] is a no-op.
  /// Requires notificationListener consent enabled.
  Future<NotificationIngestResult> ingestCapturedNotification({
    required EntityId profileId,
    required NotificationCapturePayload payload,
  }) async {
    final consent = await ensureConsent(
      profileId: profileId,
      kind: IntegrationKind.notificationListener,
    );
    if (!consent.enabled) {
      throw StateError(
        'Leitor de notificações desativado; conceda opt-in primeiro',
      );
    }
    if (payload.nativeKey.trim().isEmpty) {
      return NotificationIngestResult.skipped();
    }

    final kind = NotificationExtractionPipeline.classify(payload.extractInput);
    if (kind == NotificationExtractorKind.ignored) {
      return NotificationIngestResult.skipped();
    }

    final existing = await (_db.select(_db.capturedNotifications)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.nativeKey.equals(payload.nativeKey),
          ))
        .getSingleOrNull();
    if (existing != null) {
      final captured = ColonyMappers.toCapturedNotification(existing);
      LedgerTransaction? tx;
      if (captured.ledgerTransactionId != null) {
        tx = await _finance.getTransactionById(captured.ledgerTransactionId!);
      }
      return NotificationIngestResult(
        skipped: false,
        notification: captured,
        transaction: tx,
        duplicate: true,
      );
    }

    LedgerTransaction? booked;
    var extractorKind = kind;
    if (kind == NotificationExtractorKind.finance) {
      final spend = FinanceNotificationExtractor.tryParse(payload.extractInput);
      if (spend != null) {
        final account = await _finance.ensureInterAccount(
          profileId: profileId,
          type: spend.accountType,
        );
        const fingerprintPrefix = 'notif:';
        final fingerprint = '$fingerprintPrefix${payload.nativeKey}';
        final already = await _finance.fingerprintExists(
          profileId: profileId,
          fingerprint: fingerprint,
        );
        if (!already) {
          booked = await _finance.createTransaction(
            profileId: profileId,
            accountId: account.id,
            occurredAt: spend.occurredAt,
            descriptionOriginal: spend.description,
            amountMinor: spend.amountMinor,
            currency: spend.currency,
            direction: spend.direction,
            fingerprint: fingerprint,
            notes: 'Leitor de notificações · ${payload.packageName}',
            sourceType: SourceType.integration,
          );
        }
      } else {
        extractorKind = NotificationExtractorKind.unknown;
      }
    }

    final now = _clock();
    final captured = CapturedNotification(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      packageName: payload.packageName,
      appLabel: payload.appLabel,
      title: payload.title,
      text: payload.text,
      postedAt: payload.postedAt.toUtc(),
      nativeKey: payload.nativeKey,
      extractorKind: extractorKind,
      ledgerTransactionId: booked?.id,
      createdAt: now,
    );
    await _db
        .into(_db.capturedNotifications)
        .insert(ColonyMappers.fromCapturedNotification(captured));
    return NotificationIngestResult(
      skipped: false,
      notification: captured,
      transaction: booked,
    );
  }
}

class ContextZoneRepository {
  ContextZoneRepository(
    this._db,
    this._ids,
    this._clock,
    this._events, [
    this._sync,
  ]);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;
  final SyncRepository? _sync;

  Stream<List<ContextZone>> watchAll(EntityId profileId) {
    return (_db.select(_db.contextZones)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toContextZone).toList());
  }

  Future<List<ContextZone>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.contextZones)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toContextZone).toList();
  }

  Future<ContextZone> create({
    required EntityId profileId,
    required String name,
    String? locationLabel,
    List<String> capabilities = const [],
    List<String> unavailableWorkTypes = const [],
    ZoneConnectivity connectivity = ZoneConnectivity.unknown,
    String? notes,
  }) async {
    final now = _clock();
    final zone = ContextZone.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      name: name,
      locationLabel: locationLabel,
      capabilities: capabilities,
      unavailableWorkTypes: unavailableWorkTypes,
      connectivity: connectivity,
      notes: notes,
      createdAt: now,
    );
    await _db.transaction(() async {
      await _db
          .into(_db.contextZones)
          .insert(ColonyMappers.fromContextZone(zone));
      await _events.record(
        aggregateType: AggregateType.contextZone,
        aggregateId: zone.id,
        eventType: EventType.contextZoneCreated,
        payload: {'name': zone.name},
        sourceType: SourceType.manual,
      );
    });
    // Pilot outbox enqueue (ADR-025) — best-effort; never blocks create.
    final sync = _sync;
    if (sync != null) {
      try {
        await sync.enqueue(
          entityType: 'context_zone',
          entityId: zone.id,
          payloadJson: '{"id":"${zone.id.value}"}',
        );
      } catch (_) {}
    }
    return zone;
  }

  Future<ContextZone> save(ContextZone zone) async {
    final updated = zone.copyWith(updatedAt: _clock());
    await _db
        .into(_db.contextZones)
        .insertOnConflictUpdate(ColonyMappers.fromContextZone(updated));
    await _events.record(
      aggregateType: AggregateType.contextZone,
      aggregateId: updated.id,
      eventType: EventType.contextZoneUpdated,
      payload: {'name': updated.name},
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<ContextZone> archive(ContextZone zone) async {
    final now = _clock();
    final updated = zone.copyWith(archivedAt: now, updatedAt: now);
    await _db
        .into(_db.contextZones)
        .insertOnConflictUpdate(ColonyMappers.fromContextZone(updated));
    await _events.record(
      aggregateType: AggregateType.contextZone,
      aggregateId: updated.id,
      eventType: EventType.contextZoneArchived,
      payload: {'name': updated.name},
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<List<ZoneTripLink>> listTripLinks(EntityId profileId) async {
    final rows = await (_db.select(_db.zoneTrips).join([
      innerJoin(
        _db.contextZones,
        _db.contextZones.id.equalsExp(_db.zoneTrips.zoneId),
      ),
    ])
          ..where(_db.contextZones.profileId.equals(profileId.value)))
        .get();
    return rows
        .map(
          (row) => ColonyMappers.toZoneTripLink(row.readTable(_db.zoneTrips)),
        )
        .toList();
  }

  Stream<List<Trip>> watchLinkedTrips(EntityId zoneId) {
    final query = _db.select(_db.trips).join([
      innerJoin(
        _db.zoneTrips,
        _db.zoneTrips.tripId.equalsExp(_db.trips.id),
      ),
    ])
      ..where(_db.zoneTrips.zoneId.equals(zoneId.value))
      ..orderBy([OrderingTerm.desc(_db.trips.updatedAt)]);

    return query.watch().map(
          (rows) => rows
              .map((row) => ColonyMappers.toTrip(row.readTable(_db.trips)))
              .toList(),
        );
  }

  Future<void> linkTrip({
    required EntityId zoneId,
    required EntityId tripId,
  }) async {
    final now = _clock();
    final existing = await (_db.select(_db.zoneTrips)
          ..where(
            (t) => t.zoneId.equals(zoneId.value) & t.tripId.equals(tripId.value),
          ))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.into(_db.zoneTrips).insert(
          ColonyMappers.fromZoneTripLink(
            ZoneTripLink(
              zoneId: zoneId,
              tripId: tripId,
              linkedAt: now,
            ),
          ),
        );
  }

  Future<void> unlinkTrip({
    required EntityId zoneId,
    required EntityId tripId,
  }) async {
    await (_db.delete(_db.zoneTrips)
          ..where(
            (t) => t.zoneId.equals(zoneId.value) & t.tripId.equals(tripId.value),
          ))
        .go();
  }
}

class FlashcardRepository {
  FlashcardRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<KnowledgeArea>> watchAreas(EntityId profileId) {
    return (_db.select(_db.knowledgeAreas)
          ..where((t) => t.profileId.equals(profileId.value)))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toKnowledgeArea).toList());
  }

  Future<List<KnowledgeArea>> listAreas(EntityId profileId) async {
    final rows = await (_db.select(_db.knowledgeAreas)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toKnowledgeArea).toList();
  }

  Future<KnowledgeArea> createArea({
    required EntityId profileId,
    required String title,
    EntityId? parentId,
    String? description,
    String? iconKey,
    String? catalogKey,
    int sortOrder = 0,
  }) async {
    final now = _clock();
    final area = KnowledgeArea.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      parentId: parentId,
      description: description,
      iconKey: iconKey,
      catalogKey: catalogKey,
      sortOrder: sortOrder,
      createdAt: now,
    );
    final existing = await listAreas(profileId);
    KnowledgeAreaPolicy.assertAcyclic(
      areaId: area.id,
      parentId: parentId,
      parentById: {for (final item in existing) item.id: item.parentId},
    );
    await _db.transaction(() async {
      await _db
          .into(_db.knowledgeAreas)
          .insert(ColonyMappers.fromKnowledgeArea(area));
      await _events.record(
        aggregateType: AggregateType.knowledgeArea,
        aggregateId: area.id,
        eventType: EventType.knowledgeAreaCreated,
        payload: {'title': area.title, 'catalog_key': area.catalogKey},
        sourceType: SourceType.manual,
      );
    });
    return area;
  }

  Future<void> updateArea(KnowledgeArea area) async {
    final existing = await listAreas(area.profileId);
    KnowledgeAreaPolicy.assertAcyclic(
      areaId: area.id,
      parentId: area.parentId,
      parentById: {
        for (final item in existing)
          if (item.id != area.id) item.id: item.parentId,
      },
    );
    final updated = area.copyWith(updatedAt: _clock());
    await _db.transaction(() async {
      await (_db.update(_db.knowledgeAreas)
            ..where((t) => t.id.equals(area.id.value)))
          .write(ColonyMappers.fromKnowledgeArea(updated));
      await _events.record(
        aggregateType: AggregateType.knowledgeArea,
        aggregateId: area.id,
        eventType: EventType.knowledgeAreaUpdated,
        payload: {'title': updated.title},
        sourceType: SourceType.manual,
      );
    });
  }

  Future<List<KnowledgeArea>> seedCatalog({
    required EntityId profileId,
    required Iterable<String> keys,
  }) async {
    final selected = KnowledgeAreaCatalog.expandKeys(keys);
    if (selected.isEmpty) return const [];
    final existing = await listAreas(profileId);
    final byCatalog = {
      for (final area in existing)
        if (area.catalogKey != null) area.catalogKey!: area,
    };
    final created = <KnowledgeArea>[];
    var order = existing.length;

    bool needed(KnowledgeCatalogEntry entry) {
      if (selected.contains(entry.key)) return true;
      return entry.children.any(needed);
    }

    Future<KnowledgeArea?> ensure(
      KnowledgeCatalogEntry entry,
      EntityId? parentId,
    ) async {
      if (!needed(entry)) return byCatalog[entry.key];
      var area = byCatalog[entry.key];
      if (area == null) {
        area = await createArea(
          profileId: profileId,
          title: entry.title,
          parentId: parentId,
          description: entry.description,
          iconKey: entry.iconKey,
          catalogKey: entry.key,
          sortOrder: order++,
        );
        byCatalog[entry.key] = area;
        created.add(area);
      }
      for (final child in entry.children) {
        await ensure(child, area.id);
      }
      return area;
    }

    for (final root in KnowledgeAreaCatalog.entries) {
      await ensure(root, null);
    }
    await _seedCatalogPlacements(byCatalog);
    if (created.isNotEmpty) {
      await _events.record(
        aggregateType: AggregateType.knowledgeArea,
        aggregateId: created.first.id,
        eventType: EventType.flashcardCatalogSeeded,
        payload: {'count': created.length},
        sourceType: SourceType.manual,
      );
    }
    return created;
  }

  Future<void> _seedCatalogPlacements(
    Map<String, KnowledgeArea> byCatalog,
  ) async {
    Future<void> walk(KnowledgeCatalogEntry entry) async {
      final area = byCatalog[entry.key];
      if (area != null) {
        for (final parentKey in entry.catalogPlacements) {
          final parent = byCatalog[parentKey];
          if (parent == null) continue;
          await addPlacement(
            areaId: area.id,
            parentAreaId: parent.id,
            catalogKey: parentKey,
          );
        }
      }
      for (final child in entry.children) {
        await walk(child);
      }
    }

    for (final root in KnowledgeAreaCatalog.entries) {
      await walk(root);
    }
  }

  Stream<List<KnowledgeAreaPlacement>> watchPlacements(EntityId profileId) {
    return _db
        .select(_db.knowledgeAreaPlacements)
        .watch()
        .asyncMap((_) => listPlacements(profileId));
  }

  Future<List<KnowledgeAreaPlacement>> listPlacements(
    EntityId profileId,
  ) async {
    final areas = await listAreas(profileId);
    if (areas.isEmpty) return const [];
    final ids = {for (final area in areas) area.id.value};
    final rows = await _db.select(_db.knowledgeAreaPlacements).get();
    return [
      for (final row in rows)
        if (ids.contains(row.areaId))
          ColonyMappers.toKnowledgeAreaPlacement(row),
    ];
  }

  Future<KnowledgeAreaPlacement> addPlacement({
    required EntityId areaId,
    required EntityId parentAreaId,
    String? catalogKey,
  }) async {
    final areaRow = await (_db.select(_db.knowledgeAreas)
          ..where((t) => t.id.equals(areaId.value)))
        .getSingle();
    final areas = await listAreas(EntityId(areaRow.profileId));
    final existing = await listPlacements(EntityId(areaRow.profileId));
    final duplicate = existing.any(
      (p) => p.areaId == areaId && p.parentAreaId == parentAreaId,
    );
    if (duplicate) {
      return existing.firstWhere(
        (p) => p.areaId == areaId && p.parentAreaId == parentAreaId,
      );
    }
    KnowledgeAreaPolicy.assertPlacementAcyclic(
      areaId: areaId,
      parentAreaId: parentAreaId,
      areas: areas,
      placements: existing,
    );
    final placement = KnowledgeAreaPlacement(
      areaId: areaId,
      parentAreaId: parentAreaId,
      linkedAt: _clock(),
      catalogKey: catalogKey,
    );
    await _db.transaction(() async {
      await _db
          .into(_db.knowledgeAreaPlacements)
          .insert(ColonyMappers.fromKnowledgeAreaPlacement(placement));
      await _events.record(
        aggregateType: AggregateType.knowledgeArea,
        aggregateId: areaId,
        eventType: EventType.knowledgeAreaPlacementAdded,
        payload: {'parent_area_id': parentAreaId.value},
        sourceType: SourceType.manual,
      );
    });
    return placement;
  }

  Future<void> removePlacement({
    required EntityId areaId,
    required EntityId parentAreaId,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.knowledgeAreaPlacements)
            ..where(
              (t) =>
                  t.areaId.equals(areaId.value) &
                  t.parentAreaId.equals(parentAreaId.value),
            ))
          .go();
      await _events.record(
        aggregateType: AggregateType.knowledgeArea,
        aggregateId: areaId,
        eventType: EventType.knowledgeAreaPlacementRemoved,
        payload: {'parent_area_id': parentAreaId.value},
        sourceType: SourceType.manual,
      );
    });
  }

  Stream<List<ResearchKnowledgeLink>> watchResearchLinks(EntityId profileId) {
    return _db
        .select(_db.researchKnowledgeLinks)
        .watch()
        .asyncMap((_) => listResearchLinks(profileId));
  }

  Future<List<ResearchKnowledgeLink>> listResearchLinks(
    EntityId profileId,
  ) async {
    final areas = await listAreas(profileId);
    if (areas.isEmpty) return const [];
    final ids = {for (final area in areas) area.id.value};
    final rows = await _db.select(_db.researchKnowledgeLinks).get();
    return [
      for (final row in rows)
        if (ids.contains(row.areaId))
          ColonyMappers.toResearchKnowledgeLink(row),
    ];
  }

  Stream<List<ResearchKnowledgeLink>> watchResearchLinksForNode(
    EntityId nodeId,
  ) {
    return (_db.select(_db.researchKnowledgeLinks)
          ..where((t) => t.researchNodeId.equals(nodeId.value)))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toResearchKnowledgeLink).toList());
  }

  Future<ResearchKnowledgeLink> linkResearch({
    required EntityId researchNodeId,
    required EntityId areaId,
    ResearchKnowledgeLinkKind kind = ResearchKnowledgeLinkKind.related,
  }) async {
    final existing = await (_db.select(_db.researchKnowledgeLinks)
          ..where(
            (t) =>
                t.researchNodeId.equals(researchNodeId.value) &
                t.areaId.equals(areaId.value),
          ))
        .getSingleOrNull();
    if (existing != null) {
      return ColonyMappers.toResearchKnowledgeLink(existing);
    }
    final link = ResearchKnowledgeLink(
      researchNodeId: researchNodeId,
      areaId: areaId,
      kind: kind,
      linkedAt: _clock(),
    );
    await _db.transaction(() async {
      await _db
          .into(_db.researchKnowledgeLinks)
          .insert(ColonyMappers.fromResearchKnowledgeLink(link));
      await _events.record(
        aggregateType: AggregateType.knowledgeArea,
        aggregateId: areaId,
        eventType: EventType.researchKnowledgeLinked,
        payload: {
          'research_node_id': researchNodeId.value,
          'kind': kind.name,
        },
        sourceType: SourceType.manual,
      );
    });
    return link;
  }

  Future<void> unlinkResearch({
    required EntityId researchNodeId,
    required EntityId areaId,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.researchKnowledgeLinks)
            ..where(
              (t) =>
                  t.researchNodeId.equals(researchNodeId.value) &
                  t.areaId.equals(areaId.value),
            ))
          .go();
      await _events.record(
        aggregateType: AggregateType.knowledgeArea,
        aggregateId: areaId,
        eventType: EventType.researchKnowledgeUnlinked,
        payload: {'research_node_id': researchNodeId.value},
        sourceType: SourceType.manual,
      );
    });
  }

  Stream<List<FlashcardTag>> watchTags(EntityId profileId) {
    return (_db.select(_db.flashcardTags)
          ..where((t) => t.profileId.equals(profileId.value)))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toFlashcardTag).toList());
  }

  Future<List<FlashcardTag>> listTags(EntityId profileId) async {
    final rows = await (_db.select(_db.flashcardTags)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toFlashcardTag).toList();
  }

  Stream<List<FlashcardTagLink>> watchTagLinks(EntityId profileId) {
    return _db.select(_db.flashcardTagLinks).watch().asyncMap((_) async {
      return listTagLinks(profileId);
    });
  }

  Future<List<FlashcardTagLink>> listTagLinks(EntityId profileId) async {
    final cards = await listCards(profileId);
    final ids = {for (final card in cards) card.id.value};
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(_db.flashcardTagLinks)
          ..where((t) => t.cardId.isIn(ids)))
        .get();
    return rows.map(ColonyMappers.toFlashcardTagLink).toList();
  }

  Future<FlashcardTag> createTag({
    required EntityId profileId,
    required String title,
    EntityId? parentId,
    int sortOrder = 0,
  }) async {
    if (title.trim().isEmpty) {
      throw StateError('Título de tag vazio');
    }
    final existing = await listTags(profileId);
    final found = FlashcardTagPolicy.childNamed(
      parentId: parentId,
      title: title,
      tags: existing,
    );
    if (found != null) return found;
    final tag = FlashcardTag.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      parentId: parentId,
      sortOrder: sortOrder,
      createdAt: _clock(),
    );
    FlashcardTagPolicy.assertAcyclic(
      tagId: tag.id,
      parentId: parentId,
      parentById: {for (final item in existing) item.id: item.parentId},
    );
    await _db.transaction(() async {
      await _db.into(_db.flashcardTags).insert(ColonyMappers.fromFlashcardTag(tag));
      await _events.record(
        aggregateType: AggregateType.flashcard,
        aggregateId: tag.id,
        eventType: EventType.flashcardTagCreated,
        payload: {'title': tag.title},
        sourceType: SourceType.manual,
      );
    });
    return tag;
  }

  Future<void> updateTag(FlashcardTag tag) async {
    if (tag.title.trim().isEmpty) {
      throw StateError('Título de tag vazio');
    }
    final existing = await listTags(tag.profileId);
    final clash = FlashcardTagPolicy.childNamed(
      parentId: tag.parentId,
      title: tag.title,
      tags: [for (final item in existing) if (item.id != tag.id) item],
    );
    if (clash != null) {
      throw StateError('Já existe uma tag com este nome neste nível.');
    }
    FlashcardTagPolicy.assertAcyclic(
      tagId: tag.id,
      parentId: tag.parentId,
      parentById: {
        for (final item in existing)
          if (item.id != tag.id) item.id: item.parentId,
      },
    );
    await _db.transaction(() async {
      await (_db.update(_db.flashcardTags)..where((t) => t.id.equals(tag.id.value)))
          .write(ColonyMappers.fromFlashcardTag(tag));
      await _events.record(
        aggregateType: AggregateType.flashcard,
        aggregateId: tag.id,
        eventType: EventType.flashcardTagUpdated,
        payload: {'title': tag.title},
        sourceType: SourceType.manual,
      );
    });
  }

  Future<FlashcardTag> ensureTagPath({
    required EntityId profileId,
    required List<String> path,
  }) async {
    EntityId? parentId;
    FlashcardTag? last;
    for (final title in path) {
      last = await createTag(
        profileId: profileId,
        title: title,
        parentId: parentId,
      );
      parentId = last.id;
    }
    if (last == null) {
      throw StateError('Caminho de tag vazio');
    }
    return last;
  }

  Future<void> setCardTags({
    required Flashcard card,
    required List<EntityId> tagIds,
  }) async {
    final unique = <EntityId>{...tagIds};
    final tags = await listTags(card.profileId);
    final byId = {for (final tag in tags) tag.id: tag};
    final titles = [
      for (final id in unique)
        if (byId[id] != null) byId[id]!.title,
    ];
    await _db.transaction(() async {
      await (_db.delete(_db.flashcardTagLinks)
            ..where((t) => t.cardId.equals(card.id.value)))
          .go();
      final now = _clock();
      for (final id in unique) {
        if (byId[id] == null) continue;
        await _db.into(_db.flashcardTagLinks).insert(
              ColonyMappers.fromFlashcardTagLink(
                FlashcardTagLink(
                  cardId: card.id,
                  tagId: id,
                  linkedAt: now,
                ),
              ),
            );
      }
      final updated = card.copyWith(
        tags: titles,
        updatedAt: now,
        version: card.version + 1,
      );
      await (_db.update(_db.flashcards)
            ..where((t) => t.id.equals(card.id.value)))
          .write(ColonyMappers.fromFlashcard(updated));
      await _events.record(
        aggregateType: AggregateType.flashcard,
        aggregateId: card.id,
        eventType: EventType.flashcardTagged,
        payload: {'tag_ids': [for (final id in unique) id.value]},
        sourceType: SourceType.manual,
      );
    });
  }

  Future<void> _applyTagLabels({
    required EntityId profileId,
    required Iterable<Flashcard> cards,
    required List<String> labels,
    bool replace = false,
  }) async {
    final tagIds = <EntityId>[];
    for (final label in labels) {
      final path = FlashcardTagPolicy.parsePath(label);
      if (path.isEmpty) continue;
      final tag = await ensureTagPath(profileId: profileId, path: path);
      tagIds.add(tag.id);
    }
    if (tagIds.isEmpty && !replace) return;
    for (final card in cards) {
      await setCardTags(card: card, tagIds: tagIds);
    }
  }

  Stream<List<FlashcardDeck>> watchDecks(EntityId profileId) {
    return (_db.select(_db.flashcardDecks)
          ..where((t) => t.profileId.equals(profileId.value)))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toFlashcardDeck).toList());
  }

  Future<List<FlashcardDeck>> listDecks(EntityId profileId) async {
    final rows = await (_db.select(_db.flashcardDecks)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toFlashcardDeck).toList();
  }

  Future<FlashcardDeck?> getDeck(EntityId id) async {
    final row = await (_db.select(_db.flashcardDecks)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toFlashcardDeck(row);
  }

  Future<List<FlashcardDeck>> listDecksForResearch(EntityId nodeId) async {
    final rows = await (_db.select(_db.flashcardDecks)
          ..where((t) => t.researchNodeId.equals(nodeId.value)))
        .get();
    return rows.map(ColonyMappers.toFlashcardDeck).toList();
  }

  Stream<List<FlashcardDeck>> watchDecksForResearch(EntityId nodeId) {
    return (_db.select(_db.flashcardDecks)
          ..where((t) => t.researchNodeId.equals(nodeId.value)))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toFlashcardDeck).toList());
  }

  Future<FlashcardDeck> createDeck({
    required EntityId profileId,
    required String title,
    EntityId? areaId,
    EntityId? researchNodeId,
    String? description,
    int newLimitPerDay = 20,
    int reviewLimitPerDay = 200,
  }) async {
    final deck = FlashcardDeck.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      title: title,
      areaId: areaId,
      researchNodeId: researchNodeId,
      description: description,
      newLimitPerDay: newLimitPerDay,
      reviewLimitPerDay: reviewLimitPerDay,
      createdAt: _clock(),
    );
    await _db.transaction(() async {
      await _db
          .into(_db.flashcardDecks)
          .insert(ColonyMappers.fromFlashcardDeck(deck));
      await _events.record(
        aggregateType: AggregateType.flashcardDeck,
        aggregateId: deck.id,
        eventType: EventType.flashcardDeckCreated,
        payload: {'title': deck.title},
        sourceType: SourceType.manual,
      );
    });
    return deck;
  }

  Future<void> updateDeck(FlashcardDeck deck) async {
    final updated = deck.copyWith(
      updatedAt: _clock(),
      version: deck.version + 1,
    );
    await _db.transaction(() async {
      await (_db.update(_db.flashcardDecks)
            ..where((t) => t.id.equals(deck.id.value)))
          .write(ColonyMappers.fromFlashcardDeck(updated));
      await _events.record(
        aggregateType: AggregateType.flashcardDeck,
        aggregateId: deck.id,
        eventType: EventType.flashcardDeckUpdated,
        payload: {'title': updated.title},
        sourceType: SourceType.manual,
      );
    });
  }

  Stream<List<Flashcard>> watchCards(EntityId profileId) {
    return (_db.select(_db.flashcards)
          ..where((t) => t.profileId.equals(profileId.value)))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toFlashcard).toList());
  }

  Future<List<Flashcard>> listCards(EntityId profileId) async {
    final rows = await (_db.select(_db.flashcards)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toFlashcard).toList();
  }

  Future<List<Flashcard>> listCardsInDeck(EntityId deckId) async {
    final rows = await (_db.select(_db.flashcards)
          ..where((t) => t.deckId.equals(deckId.value)))
        .get();
    return rows.map(ColonyMappers.toFlashcard).toList();
  }

  Future<Flashcard?> getCard(EntityId id) async {
    final row = await (_db.select(_db.flashcards)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toFlashcard(row);
  }

  Future<List<FlashcardSrsState>> listSrs(EntityId profileId) async {
    final cards = await listCards(profileId);
    if (cards.isEmpty) return const [];
    final ids = cards.map((c) => c.id.value).toList();
    final rows = await (_db.select(_db.flashcardSrs)
          ..where((t) => t.cardId.isIn(ids)))
        .get();
    return rows.map(ColonyMappers.toFlashcardSrs).toList();
  }

  Stream<List<FlashcardSrsState>> watchSrs(EntityId profileId) {
    return _db.select(_db.flashcardSrs).watch().asyncMap((_) => listSrs(profileId));
  }

  Future<List<FlashcardReviewLog>> listLogs(EntityId profileId) async {
    final cards = await listCards(profileId);
    if (cards.isEmpty) return const [];
    final ids = cards.map((c) => c.id.value).toList();
    final rows = await (_db.select(_db.flashcardReviewLogs)
          ..where((t) => t.cardId.isIn(ids)))
        .get();
    return rows.map(ColonyMappers.toFlashcardReviewLog).toList();
  }

  Stream<List<FlashcardReviewLog>> watchLogs(EntityId profileId) {
    return _db
        .select(_db.flashcardReviewLogs)
        .watch()
        .asyncMap((_) => listLogs(profileId));
  }

  Future<FlashcardSrsState> _srsFor(EntityId cardId, DateTime createdAt) async {
    final row = await (_db.select(_db.flashcardSrs)
          ..where((t) => t.cardId.equals(cardId.value)))
        .getSingleOrNull();
    return row == null
        ? FlashcardSrsState.fresh(cardId: cardId, createdAt: createdAt)
        : ColonyMappers.toFlashcardSrs(row);
  }

  Future<Flashcard> _insertCard(Flashcard card) async {
    FlashcardPolicy.validateCard(card);
    await _db.into(_db.flashcards).insert(ColonyMappers.fromFlashcard(card));
    if (card.scheduleMode == FlashcardScheduleMode.scheduled) {
      final srs =
          FlashcardSrsState.fresh(cardId: card.id, createdAt: card.createdAt);
      await _db.into(_db.flashcardSrs).insert(ColonyMappers.fromFlashcardSrs(srs));
    }
    await _events.record(
      aggregateType: AggregateType.flashcard,
      aggregateId: card.id,
      eventType: EventType.flashcardCreated,
      payload: {
        'kind': card.kind.name,
        'deck_id': card.deckId.value,
        'schedule_mode': card.scheduleMode.name,
      },
      sourceType: SourceType.manual,
    );
    return card;
  }

  Future<List<Flashcard>> createCard({
    required EntityId profileId,
    required EntityId deckId,
    required String front,
    required String back,
    FlashcardKind kind = FlashcardKind.basic,
    EntityId? areaId,
    String? extra,
    List<String> tags = const [],
    bool bidirectional = false,
    FlashcardScheduleMode scheduleMode = FlashcardScheduleMode.scheduled,
    int? priority,
  }) async {
    final now = _clock();
    final created = <Flashcard>[];
    await _db.transaction(() async {
      if (kind == FlashcardKind.cloze) {
        final indices = ClozeRenderer.indicesIn(front).toList()..sort();
        if (indices.isEmpty) {
          throw FlashcardValidationException(
            'Cartão cloze precisa de {{c1::texto}} na frente.',
          );
        }
        for (final index in indices) {
          created.add(
            await _insertCard(
              Flashcard.create(
                id: EntityId(_ids.newId()),
                profileId: profileId,
                deckId: deckId,
                areaId: areaId,
                kind: kind,
                front: front,
                back: back,
                extra: extra,
                tags: tags,
                clozeIndex: index,
                scheduleMode: scheduleMode,
                priority: priority,
                createdAt: now,
              ),
            ),
          );
        }
      } else {
        final card = await _insertCard(
          Flashcard.create(
            id: EntityId(_ids.newId()),
            profileId: profileId,
            deckId: deckId,
            areaId: areaId,
            kind: kind,
            front: front,
            back: back,
            extra: extra,
            tags: tags,
            scheduleMode: scheduleMode,
            priority: priority,
            createdAt: now,
          ),
        );
        created.add(card);
        if (bidirectional || kind == FlashcardKind.reverse) {
          created.add(
            await _insertCard(
              Flashcard.create(
                id: EntityId(_ids.newId()),
                profileId: profileId,
                deckId: deckId,
                areaId: areaId,
                kind: FlashcardKind.reverse,
                front: back,
                back: front,
                extra: extra,
                tags: tags,
                reverseOfId: card.id,
                scheduleMode: scheduleMode,
                priority: priority,
                createdAt: now,
              ),
            ),
          );
        }
      }
    });
    await _applyTagLabels(
      profileId: profileId,
      cards: created,
      labels: tags,
    );
    return created;
  }

  Future<void> updateCard(Flashcard card) async {
    FlashcardPolicy.validateCard(card);
    final updated = card.copyWith(
      updatedAt: _clock(),
      version: card.version + 1,
    );
    await _db.transaction(() async {
      await (_db.update(_db.flashcards)
            ..where((t) => t.id.equals(card.id.value)))
          .write(ColonyMappers.fromFlashcard(updated));
      await _events.record(
        aggregateType: AggregateType.flashcard,
        aggregateId: card.id,
        eventType: EventType.flashcardUpdated,
        payload: {'kind': updated.kind.name},
        sourceType: SourceType.manual,
      );
    });
  }

  Future<void> applyCardTagLabels({
    required Flashcard card,
    required List<String> labels,
  }) {
    return _applyTagLabels(
      profileId: card.profileId,
      cards: [card],
      labels: labels,
      replace: true,
    );
  }

  Future<void> setSuspended(Flashcard card, bool suspended) async {
    await updateCard(card.copyWith(suspended: suspended));
  }

  Future<void> bury(Flashcard card) async {
    final now = _clock();
    final srs = await _srsFor(card.id, card.createdAt);
    final next = srs.copyWith(dueAt: StudyQueuePolicy.startOfNextLocalDay(now));
    await (_db.update(_db.flashcardSrs)
          ..where((t) => t.cardId.equals(card.id.value)))
        .write(ColonyMappers.fromFlashcardSrs(next));
  }

  Future<FlashcardReviewOutcome> review({
    required Flashcard card,
    required FlashcardRating rating,
    int? durationMs,
  }) async {
    final now = _clock();
    final previous = await _srsFor(card.id, card.createdAt);
    final applied = Sm2Scheduler.apply(
      state: previous,
      rating: rating,
      now: now,
    );
    var next = applied.state;
    if (applied.becameLeech) {
      await updateCard(card.copyWith(suspended: true));
    }
    final log = FlashcardReviewLog(
      id: EntityId(_ids.newId()),
      cardId: card.id,
      reviewedAt: now,
      rating: rating,
      intervalDaysBefore: previous.intervalDays,
      intervalDaysAfter: next.intervalDays,
      easeBefore: previous.easeFactor,
      easeAfter: next.easeFactor,
      durationMs: durationMs,
      reviewKind: FlashcardReviewKind.srs,
    );
    await _db.transaction(() async {
      await (_db.update(_db.flashcardSrs)
            ..where((t) => t.cardId.equals(card.id.value)))
          .write(ColonyMappers.fromFlashcardSrs(next));
      await _db
          .into(_db.flashcardReviewLogs)
          .insert(ColonyMappers.fromFlashcardReviewLog(log));
      await _events.record(
        aggregateType: AggregateType.flashcard,
        aggregateId: card.id,
        eventType: EventType.flashcardReviewed,
        payload: {
          'rating': rating.name,
          'leech': applied.becameLeech,
        },
        sourceType: SourceType.manual,
      );
    });
    return FlashcardReviewOutcome(
      previous: previous,
      next: next,
      log: log,
      becameLeech: applied.becameLeech,
    );
  }

  Future<void> undoReview({
    required FlashcardReviewOutcome outcome,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.flashcardReviewLogs)
            ..where((t) => t.id.equals(outcome.log.id.value)))
          .go();
      if (outcome.log.reviewKind == FlashcardReviewKind.srs) {
        await (_db.update(_db.flashcardSrs)
              ..where((t) => t.cardId.equals(outcome.previous.cardId.value)))
            .write(ColonyMappers.fromFlashcardSrs(outcome.previous));
      }
    });
  }

  Future<FlashcardReviewLog> practice({
    required Flashcard card,
    required FlashcardRating rating,
    int? durationMs,
  }) async {
    final now = _clock();
    final previous = await _srsFor(card.id, card.createdAt);
    final log = FlashcardReviewLog(
      id: EntityId(_ids.newId()),
      cardId: card.id,
      reviewedAt: now,
      rating: rating,
      intervalDaysBefore: previous.intervalDays,
      intervalDaysAfter: previous.intervalDays,
      easeBefore: previous.easeFactor,
      easeAfter: previous.easeFactor,
      durationMs: durationMs,
      reviewKind: FlashcardReviewKind.practice,
    );
    await _db.transaction(() async {
      await _db
          .into(_db.flashcardReviewLogs)
          .insert(ColonyMappers.fromFlashcardReviewLog(log));
      await _events.record(
        aggregateType: AggregateType.flashcard,
        aggregateId: card.id,
        eventType: EventType.flashcardPracticed,
        payload: {'rating': rating.name},
        sourceType: SourceType.manual,
      );
    });
    return log;
  }

  Future<void> undoPractice(FlashcardReviewLog log) async {
    await (_db.delete(_db.flashcardReviewLogs)
          ..where((t) => t.id.equals(log.id.value)))
        .go();
  }

  Future<void> scheduleCard(Flashcard card) async {
    if (card.scheduleMode == FlashcardScheduleMode.scheduled) return;
    final updated = card.copyWith(
      scheduleMode: FlashcardScheduleMode.scheduled,
      updatedAt: _clock(),
      version: card.version + 1,
    );
    await _db.transaction(() async {
      await (_db.update(_db.flashcards)
            ..where((t) => t.id.equals(card.id.value)))
          .write(ColonyMappers.fromFlashcard(updated));
      final existing = await (_db.select(_db.flashcardSrs)
            ..where((t) => t.cardId.equals(card.id.value)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.into(_db.flashcardSrs).insert(
              ColonyMappers.fromFlashcardSrs(
                FlashcardSrsState.fresh(
                  cardId: card.id,
                  createdAt: updated.updatedAt,
                ),
              ),
            );
      }
      await _events.record(
        aggregateType: AggregateType.flashcard,
        aggregateId: card.id,
        eventType: EventType.flashcardScheduled,
        payload: const {},
        sourceType: SourceType.manual,
      );
    });
  }

  Future<void> unscheduleCard(Flashcard card) async {
    if (card.scheduleMode == FlashcardScheduleMode.unscheduled) return;
    final updated = card.copyWith(
      scheduleMode: FlashcardScheduleMode.unscheduled,
      updatedAt: _clock(),
      version: card.version + 1,
    );
    await _db.transaction(() async {
      await (_db.update(_db.flashcards)
            ..where((t) => t.id.equals(card.id.value)))
          .write(ColonyMappers.fromFlashcard(updated));
      await (_db.delete(_db.flashcardSrs)
            ..where((t) => t.cardId.equals(card.id.value)))
          .go();
      await _events.record(
        aggregateType: AggregateType.flashcard,
        aggregateId: card.id,
        eventType: EventType.flashcardUnscheduled,
        payload: const {},
        sourceType: SourceType.manual,
      );
    });
  }

  Future<List<EntityId>> deleteCard(Flashcard card) async {
    return _db.transaction(() async {
      final related = await (_db.select(_db.flashcards)
            ..where(
              (t) =>
                  t.id.equals(card.id.value) |
                  t.reverseOfId.equals(card.id.value),
            ))
          .get();
      final ids = [for (final row in related) row.id];
      if (ids.isEmpty) return const <EntityId>[];
      await (_db.delete(_db.flashcardTagLinks)
            ..where((t) => t.cardId.isIn(ids)))
          .go();
      await (_db.delete(_db.flashcardReviewLogs)
            ..where((t) => t.cardId.isIn(ids)))
          .go();
      await (_db.delete(_db.flashcardSrs)
            ..where((t) => t.cardId.isIn(ids)))
          .go();
      await (_db.delete(_db.flashcards)..where((t) => t.id.isIn(ids))).go();
      await _events.record(
        aggregateType: AggregateType.flashcard,
        aggregateId: card.id,
        eventType: EventType.flashcardDeleted,
        payload: {
          'front': card.front,
          'deleted_ids': ids,
        },
        sourceType: SourceType.manual,
      );
      return [for (final id in ids) EntityId(id)];
    });
  }

  Future<FlashcardJsonImportResult> importJson({
    required EntityId profileId,
    required String source,
  }) async {
    final document = FlashcardJsonCodec.parse(source);
    final areas = await listAreas(profileId);
    final placements = await listPlacements(profileId);
    final decks = await listDecks(profileId);
    final cards = await listCards(profileId);
    final plan = FlashcardJsonImportPolicy.plan(
      document: document,
      areas: areas,
      placements: placements,
      decks: decks,
      cards: cards,
    );

    final areaIds = <String, EntityId>{};
    var createdAreas = 0;
    var createdDecks = 0;
    var createdCards = 0;
    var skippedCards = 0;
    var overwrittenCards = 0;

    Future<EntityId?> areaIdFor(List<String> path) async {
      if (path.isEmpty) return null;
      return areaIds[FlashcardJsonImportPolicy.pathKey(path)];
    }

    for (final step in plan.areas) {
      final key = FlashcardJsonImportPolicy.pathKey(step.path);
      if (step.existingId != null) {
        areaIds[key] = step.existingId!;
        continue;
      }
      final parentId = await areaIdFor(step.parentPath);
      final created = await createArea(
        profileId: profileId,
        title: step.title,
        parentId: parentId,
        description: step.description,
        catalogKey: step.catalogKey,
      );
      areaIds[key] = created.id;
      createdAreas += 1;
    }

    for (final step in plan.placements) {
      final areaId = await areaIdFor(step.areaPath);
      final parentId = await areaIdFor(step.parentPath);
      if (areaId == null || parentId == null || areaId == parentId) continue;
      try {
        await addPlacement(areaId: areaId, parentAreaId: parentId);
      } on KnowledgeAreaCycleException {
        continue;
      }
    }

    final deckIds = <String, EntityId>{
      for (final deck in decks)
        if (!deck.isArchived)
          FlashcardJsonCodec.normalizeText(deck.title): deck.id,
    };
    for (final step in plan.decks) {
      final key = FlashcardJsonCodec.normalizeText(step.title);
      if (step.existingId != null) {
        deckIds[key] = step.existingId!;
        continue;
      }
      final created = await createDeck(
        profileId: profileId,
        title: step.title,
        areaId: await areaIdFor(step.areaPath),
      );
      deckIds[key] = created.id;
      createdDecks += 1;
    }

    final byId = {for (final card in cards) card.id: card};
    for (final step in plan.cards) {
      final deckId =
          deckIds[FlashcardJsonCodec.normalizeText(step.card.deckTitle)];
      if (deckId == null) {
        throw FlashcardJsonException(
          'Baralho não resolvido: ${step.card.deckTitle}',
        );
      }
      final areaId = await areaIdFor(step.card.areaPath);
      switch (step.action) {
        case FlashcardJsonCardActionKind.skip:
          skippedCards += 1;
          break;
        case FlashcardJsonCardActionKind.overwrite:
          for (final id in step.existingIds) {
            final current = byId[id];
            if (current == null) continue;
            final updated = current.copyWith(
              back: step.card.back,
              extra: step.card.extra,
              tags: step.card.tags,
              areaId: areaId ?? current.areaId,
              priority: step.card.priority,
              clearExtra: (step.card.extra ?? '').trim().isEmpty,
            );
            await updateCard(updated);
            await applyCardTagLabels(
              card: updated,
              labels: step.card.tags,
            );
          }
          overwrittenCards += 1;
          break;
        case FlashcardJsonCardActionKind.create:
          final created = await createCard(
            profileId: profileId,
            deckId: deckId,
            front: step.card.front,
            back: step.card.back,
            kind: step.card.kind,
            areaId: areaId,
            extra: step.card.extra,
            tags: step.card.tags,
            bidirectional: step.card.bidirectional,
            scheduleMode: step.card.scheduleMode,
            priority: step.card.priority,
          );
          createdCards += created.length;
          break;
      }
    }

    await _events.record(
      aggregateType: AggregateType.flashcard,
      aggregateId: profileId,
      eventType: EventType.flashcardJsonImported,
      payload: {
        'created': createdCards,
        'skipped': skippedCards,
        'overwritten': overwrittenCards,
        'areas': createdAreas,
        'decks': createdDecks,
      },
      sourceType: SourceType.import,
    );

    return FlashcardJsonImportResult(
      createdCards: createdCards,
      skippedCards: skippedCards,
      overwrittenCards: overwrittenCards,
      createdAreas: createdAreas,
      createdDecks: createdDecks,
    );
  }
}

class GoogleTimelineRepository {
  GoogleTimelineRepository(
    this._db,
    this._ids,
    this._clock,
    this._events,
  );

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<GoogleTimelineImport?> watchImport(EntityId profileId) {
    return (_db.select(_db.googleTimelineImports)
          ..where((t) => t.profileId.equals(profileId.value)))
        .watch()
        .asyncMap(
          (rows) async => rows.isEmpty ? null : _hydrate(rows.first),
        );
  }

  Future<GoogleTimelineImport?> getForProfile(EntityId profileId) async {
    final row = await (_db.select(_db.googleTimelineImports)
          ..where((t) => t.profileId.equals(profileId.value))
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _hydrate(row);
  }

  Stream<List<TimelinePlaceLabel>> watchLabels(EntityId profileId) {
    return (_db.select(_db.googleTimelinePlaceLabels)
          ..where((t) => t.profileId.equals(profileId.value)))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toTimelinePlaceLabel).toList());
  }

  Future<List<TimelinePlaceLabel>> listLabels(EntityId profileId) async {
    final rows = await (_db.select(_db.googleTimelinePlaceLabels)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toTimelinePlaceLabel).toList();
  }

  /// Writes [import] using a sidecar file when the DB has a documents directory,
  /// so Android never SELECTs a multi-megabyte TEXT column.
  Future<void> putImport(GoogleTimelineImport import) async {
    final payloadJson = await _encodePayload(import);
    await _db.into(_db.googleTimelineImports).insert(
          GoogleTimelineImportsCompanion.insert(
            id: import.id.value,
            profileId: import.profileId.value,
            fileName: import.fileName,
            importedAt: import.importedAt.millisecondsSinceEpoch,
            payloadJson: payloadJson,
          ),
        );
  }

  /// Replaces any previous Timeline payload for the profile. Place labels stay.
  Future<GoogleTimelineImport> replaceImport({
    required EntityId profileId,
    required String fileName,
    required GoogleTimelineDocument document,
  }) async {
    final now = _clock();
    final existingRow = await (_db.select(_db.googleTimelineImports)
          ..where((t) => t.profileId.equals(profileId.value))
          ..limit(1))
        .getSingleOrNull();
    final import = GoogleTimelineImport(
      id: existingRow == null
          ? EntityId(_ids.newId())
          : EntityId(existingRow.id),
      profileId: profileId,
      fileName: fileName,
      importedAt: now,
      document: document,
    );
    await _db.transaction(() async {
      await (_db.delete(_db.googleTimelineImports)
            ..where((t) => t.profileId.equals(profileId.value)))
          .go();
      await _deletePayloadFile(profileId);
      await putImport(import);
      await _events.record(
        aggregateType: AggregateType.googleTimeline,
        aggregateId: import.id,
        eventType: EventType.googleTimelineImported,
        payload: {
          'file_name': fileName,
          'visits': document.visits.length,
          'activities': document.activities.length,
          'trips': document.trips.length,
          'overwrote': existingRow != null,
        },
        sourceType: SourceType.import,
      );
    });
    return import;
  }

  Future<void> deletePayloadFiles() async {
    final dirPath = _db.dataDirectory;
    if (dirPath == null) return;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;
    await for (final entity in dir.list()) {
      if (entity is File &&
          p.basename(entity.path).startsWith('google_timeline_') &&
          entity.path.endsWith('.json')) {
        try {
          await entity.delete();
        } on FileSystemException {
          // Best-effort cleanup during restore wipe.
        }
      }
    }
  }

  Future<GoogleTimelineImport> _hydrate(GoogleTimelineImportRow row) async {
    final decoded = jsonDecode(row.payloadJson);
    if (decoded is Map &&
        decoded[ColonyMappers.googleTimelineExternalFileKey] is String) {
      final name =
          decoded[ColonyMappers.googleTimelineExternalFileKey] as String;
      final dir = _db.dataDirectory;
      if (dir != null) {
        final file = File(p.join(dir, name));
        if (file.existsSync()) {
          final payload = jsonDecode(await file.readAsString());
          if (payload is Map) {
            return GoogleTimelineImport(
              id: EntityId(row.id),
              profileId: EntityId(row.profileId),
              fileName: row.fileName,
              importedAt: DateTime.fromMillisecondsSinceEpoch(
                row.importedAt,
                isUtc: true,
              ),
              document: GoogleTimelineDocument.fromJson(
                payload is Map<String, dynamic>
                    ? payload
                    : Map<String, dynamic>.from(payload),
              ),
            );
          }
        }
      }
    }
    return ColonyMappers.toGoogleTimelineImport(row);
  }

  Future<String> _encodePayload(GoogleTimelineImport import) async {
    final json = jsonEncode(import.document.toJson());
    if (_db.dataDirectory == null) return json;
    await _writePayloadJson(import.profileId, json);
    return jsonEncode({
      ColonyMappers.googleTimelineExternalFileKey:
          _payloadFileName(import.profileId),
    });
  }

  Future<void> _writePayloadJson(EntityId profileId, String json) async {
    final dir = _db.dataDirectory;
    if (dir == null) return;
    final file = File(p.join(dir, _payloadFileName(profileId)));
    await file.writeAsString(json, flush: true);
  }

  Future<void> _deletePayloadFile(EntityId profileId) async {
    final dir = _db.dataDirectory;
    if (dir == null) return;
    final file = File(p.join(dir, _payloadFileName(profileId)));
    if (file.existsSync()) {
      await file.delete();
    }
  }

  String _payloadFileName(EntityId profileId) =>
      'google_timeline_${profileId.value}.json';

  Future<TimelinePlaceLabel> upsertLabel({
    required EntityId profileId,
    required TimelinePlaceLabel label,
  }) async {
    final now = _clock();
    await _db.into(_db.googleTimelinePlaceLabels).insertOnConflictUpdate(
          ColonyMappers.fromTimelinePlaceLabel(
            profileId: profileId,
            label: label,
            updatedAt: now,
          ),
        );
    return label;
  }

  Future<void> deleteLabel({
    required EntityId profileId,
    required String placeId,
  }) async {
    await (_db.delete(_db.googleTimelinePlaceLabels)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) & t.placeId.equals(placeId),
          ))
        .go();
  }
}

class ColonyRepositories {
  ColonyRepositories({
    required this.database,
    required this.profiles,
    required this.preferences,
    required this.events,
    required this.tasks,
    required this.needs,
    required this.checkIns,
    required this.dailyReviews,
    required this.weeklyReviews,
    required this.workPriorities,
    required this.bills,
    required this.schedule,
    required this.quests,
    required this.projects,
    required this.decisions,
    required this.research,
    required this.finance,
    required this.health,
    required this.inventory,
    required this.people,
    required this.trips,
    required this.organizations,
    required this.homeMaintenance,
    required this.commitments,
    required this.contextZones,
    required this.integrations,
    required this.flashcards,
    required this.googleTimeline,
    required this.sync,
    required this.export,
    required this.restore,
  });

  final ColonyDatabase database;
  final ProfileRepository profiles;
  final PreferencesRepository preferences;
  final DomainEventRepository events;
  final TaskRepository tasks;
  final NeedRepository needs;
  final CheckInRepository checkIns;
  final DailyReviewRepository dailyReviews;
  final WeeklyReviewRepository weeklyReviews;
  final WorkPriorityRepository workPriorities;
  final BillRepository bills;
  final ScheduleRepository schedule;
  final QuestRepository quests;
  final ProjectRepository projects;
  final DecisionRepository decisions;
  final ResearchRepository research;
  final FinanceRepository finance;
  final HealthRepository health;
  final InventoryRepository inventory;
  final PersonRepository people;
  final TripRepository trips;
  final OrganizationRepository organizations;
  final HomeMaintenanceRepository homeMaintenance;
  final CommitmentRepository commitments;
  final ContextZoneRepository contextZones;
  final IntegrationRepository integrations;
  final FlashcardRepository flashcards;
  final GoogleTimelineRepository googleTimeline;
  final SyncRepository sync;
  final ExportRepository export;
  final RestoreRepository restore;

  factory ColonyRepositories.create(
    ColonyDatabase database, {
    IdGenerator? idGenerator,
    DateTime Function()? clock,
  }) {
    final ids = idGenerator ?? UuidIdGenerator.v7(() => const Uuid().v4());
    final now = clock ?? DateTime.now;
    final events = DomainEventRepository(database, ids, now);
    final profiles = ProfileRepository(database, ids, now);
    final preferences = PreferencesRepository(database);
    final needs = NeedRepository(database, ids, now, events);
    final checkIns = CheckInRepository(database, ids, now, events);
    final workPriorities = WorkPriorityRepository(database, now, events);
    final bills = BillRepository(database, ids, now, events);
    final schedule = ScheduleRepository(database, ids, now, events);
    final projects = ProjectRepository(database, ids, now, events);
    final decisions = DecisionRepository(database, ids, now, events);
    final research = ResearchRepository(database, ids, now, events);
    final finance = FinanceRepository(database, ids, now, events);
    final health = HealthRepository(database, ids, now, events);
    final peopleRepo = PersonRepository(database, ids, now, events);
    final syncRepo = SyncRepository(database, ids, now, events);
    final tasks = TaskRepository(database, ids, now, events, syncRepo);
    final quests = QuestRepository(database, ids, now, events, syncRepo);
    final inventory = InventoryRepository(database, ids, now, events, syncRepo);
    final tripsRepo = TripRepository(database, ids, now, events, syncRepo);
    final orgsRepo = OrganizationRepository(database, ids, now, events);
    final homeRepo = HomeMaintenanceRepository(database, ids, now, events);
    final commitmentsRepo =
        CommitmentRepository(database, ids, now, events, syncRepo);
    final zonesRepo =
        ContextZoneRepository(database, ids, now, events, syncRepo);
    final integrationsRepo =
        IntegrationRepository(database, ids, now, events, finance);
    final flashcardsRepo = FlashcardRepository(database, ids, now, events);
    final googleTimelineRepo =
        GoogleTimelineRepository(database, ids, now, events);
    final dailyReviews = DailyReviewRepository(database, ids, now, events);
    final weeklyReviews = WeeklyReviewRepository(database, ids, now, events);
    final restore = RestoreRepository(database, events, now);
    return ColonyRepositories(
      database: database,
      profiles: profiles,
      preferences: preferences,
      events: events,
      tasks: tasks,
      needs: needs,
      checkIns: checkIns,
      dailyReviews: dailyReviews,
      weeklyReviews: weeklyReviews,
      workPriorities: workPriorities,
      bills: bills,
      schedule: schedule,
      quests: quests,
      projects: projects,
      decisions: decisions,
      research: research,
      finance: finance,
      health: health,
      inventory: inventory,
      people: peopleRepo,
      trips: tripsRepo,
      organizations: orgsRepo,
      homeMaintenance: homeRepo,
      commitments: commitmentsRepo,
      contextZones: zonesRepo,
      integrations: integrationsRepo,
      flashcards: flashcardsRepo,
      googleTimeline: googleTimelineRepo,
      sync: syncRepo,
      export: ExportRepository(
        profiles,
        preferences,
        tasks,
        events,
        quests,
        projects,
        decisions,
        research,
        finance,
        health,
        inventory,
        peopleRepo,
        tripsRepo,
        orgsRepo,
        homeRepo,
        commitmentsRepo,
        zonesRepo,
        integrationsRepo,
        workPriorities,
        bills,
        schedule,
        needs,
        checkIns,
        dailyReviews,
        weeklyReviews,
        flashcardsRepo,
        googleTimelineRepo,
        now,
      ),
      restore: restore,
    );
  }
}