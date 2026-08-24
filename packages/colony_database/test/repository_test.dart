import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ColonyDatabase db;
  late ColonyRepositories repos;

  setUp(() {
    db = ColonyDatabase.inMemory();
    repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'task-1',
        'event-1',
        'event-2',
        'need-1',
        'need-2',
        'need-3',
        'need-4',
        'need-5',
        'need-6',
        'reading-1',
        'checkin-1',
        'factor-1',
        'event-3',
        'event-4',
        'quest-1',
        'event-5',
        'task-2',
        'event-6',
        'project-1',
        'event-7',
        'event-8',
        'event-9',
        // Spare IDs for pilot sync enqueue (device + ops + events).
        for (var i = 0; i < 80; i++) 'sync-spare-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('capture creates inbox task and event', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final task = await repos.tasks.capture(
      profileId: profile.id,
      title: 'Comprar leite',
    );

    expect(task.status, TaskStatus.inbox);
    final inbox = await repos.tasks.watchInbox(profile.id).first;
    expect(inbox, hasLength(1));
    final events = await repos.events.listTimeline();
    expect(events, isNotEmpty);
  });

  test('export produces json snapshot', () async {
    await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    final json = await repos.export.exportJson();
    expect(json, contains('"profile"'));
    expect(json, contains('Test'));
  });

  test('seeds needs and records check-in', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    await repos.needs.seedDefaults(profile.id);
    final snapshots = await repos.needs.buildSnapshots(profile.id);
    expect(snapshots, hasLength(6));

    final checkIn = await repos.checkIns.save(
      profileId: profile.id,
      mood: 0.8,
      energy: 0.6,
      tension: 0.3,
      focus: 0.7,
      factors: [(label: 'Descanso', impact: 4, uncertain: false)],
    );

    expect(checkIn.moodLabel, isNotEmpty);
    final factors = await repos.checkIns.getFactors(checkIn.id);
    expect(factors, hasLength(1));
  });

  test('seeds work priorities and cycles level', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    await repos.workPriorities.seedDefaults(profile.id);
    final priorities = await repos.workPriorities.listAll(profile.id);
    expect(priorities, hasLength(WorkType.values.length));
    expect(priorities.first.level, PriorityLevel.normal);

    final first = priorities.first;
    final cycled = await repos.workPriorities.cyclePriority(first);
    expect(cycled.level, PriorityCyclePolicy.next(first.level));

    final saved = await repos.workPriorities.listAll(profile.id);
    expect(saved.first.level, cycled.level);

    final events = await repos.events.listTimeline();
    expect(events.any((e) => e.eventType == EventType.workPriorityChanged), isTrue);
  });

  test('creates bill and schedule block', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final bill = await repos.bills.create(
      profileId: profile.id,
      title: 'Praticar piano',
      repeatMode: BillRepeatMode.quotaWindow,
      target: '3/semana',
    );
    expect(bill.title, 'Praticar piano');

    final day = DateTime(2026, 8, 6);
    final block = await repos.schedule.create(
      profileId: profile.id,
      startAt: DateTime(2026, 8, 6, 9).toUtc(),
      endAt: DateTime(2026, 8, 6, 10).toUtc(),
      mode: ScheduleBlockMode.focus,
    );
    expect(block.mode, ScheduleBlockMode.focus);

    final blocks = await repos.schedule.watchForDay(profile.id, day).first;
    expect(blocks, hasLength(1));
  });

  test('schedule block update and delete round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final day = DateTime(2026, 8, 6);
    final block = await repos.schedule.create(
      profileId: profile.id,
      startAt: DateTime(2026, 8, 6, 9).toUtc(),
      endAt: DateTime(2026, 8, 6, 10).toUtc(),
      mode: ScheduleBlockMode.focus,
    );

    final updated = block.copyWith(
      startAt: DateTime(2026, 8, 6, 14).toUtc(),
      endAt: DateTime(2026, 8, 6, 15, 30).toUtc(),
      mode: ScheduleBlockMode.meeting,
      updatedAt: DateTime.utc(2026, 8, 6, 12),
    );
    await repos.schedule.save(updated);

    final afterUpdate = await repos.schedule.watchForDay(profile.id, day).first;
    expect(afterUpdate, hasLength(1));
    expect(afterUpdate.first.mode, ScheduleBlockMode.meeting);
    expect(afterUpdate.first.startAt, DateTime(2026, 8, 6, 14).toUtc());

    await repos.schedule.delete(block.id);

    final afterDelete = await repos.schedule.watchForDay(profile.id, day).first;
    expect(afterDelete, isEmpty);

    final events = await repos.events.watchTimeline().first;
    expect(
      events.any((e) => e.eventType == EventType.scheduleBlockDeleted),
      isTrue,
    );
  });

  test('creates quest, links task, export v3 includes quests', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Viagem internacional',
      purpose: 'Organizar documentação e reservas',
      status: QuestStatus.active,
      successCriteria: ['Passaporte válido', 'Seguro contratado'],
      risks: ['Prazo de visto'],
    );
    expect(quest.status, QuestStatus.active);

    final task = await repos.tasks.capture(
      profileId: profile.id,
      title: 'Renovar passaporte',
    );
    await repos.tasks.linkToQuest(task, quest.id);

    final linked = await repos.tasks.listByQuest(quest.id);
    expect(linked, hasLength(1));
    expect(linked.first.questId, quest.id);

    await repos.workPriorities.seedDefaults(profile.id);
    await repos.bills.create(profileId: profile.id, title: 'Praticar idioma');
    await repos.needs.seedDefaults(profile.id);

    final json = await repos.export.exportJson();
    expect(json, contains('"version": 37'));
    expect(json, contains('Viagem internacional'));
    expect(json, contains('"quests"'));
    expect(json, contains('"work_priorities"'));
    expect(json, contains('"bills"'));
  });

  test('quest edit round-trips criteria and risks', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Original',
      purpose: 'Propósito inicial',
      successCriteria: ['Critério A'],
      risks: ['Risco 1'],
    );

    final updated = quest.copyWith(
      title: 'Atualizada',
      purpose: 'Propósito revisado',
      successCriteria: ['Critério A revisado', 'Critério B'],
      risks: ['Risco 2'],
      updatedAt: DateTime.utc(2026, 8, 7),
      version: quest.version + 1,
    );

    await repos.quests.save(updated);

    final loaded = await repos.quests.getById(quest.id);
    expect(loaded, isNotNull);
    expect(loaded!.title, 'Atualizada');
    expect(loaded.purpose, 'Propósito revisado');
    expect(loaded.successCriteria, ['Critério A revisado', 'Critério B']);
    expect(loaded.risks, ['Risco 2']);

    final events = await repos.events.listTimeline();
    expect(events.any((e) => e.eventType == EventType.questUpdated), isTrue);
  });

  test('project CRUD, quest link and export v3', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    final project = await repos.projects.create(
      profileId: profile.id,
      title: 'Viagem 2026',
      purpose: 'Planejamento geral',
    );
    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Organizar documentos',
      purpose: 'Passaporte e seguro',
      status: QuestStatus.active,
    );
    await repos.projects.linkQuest(
      questId: quest.id,
      projectId: project.id,
    );

    final linked = await repos.projects.watchLinkedToQuest(quest.id).first;
    expect(linked, hasLength(1));
    expect(linked.first.title, 'Viagem 2026');

    final paused = await repos.quests.updateStatus(
      quest,
      QuestStatus.paused,
      pauseReason: 'Aguardando visto',
    );
    expect(paused.pauseReason, 'Aguardando visto');

    final pauseEvents = await repos.events.listTimeline();
    final pauseStatusEvents = pauseEvents
        .where((e) => e.eventType == EventType.questStatusChanged)
        .toList();
    expect(pauseStatusEvents, hasLength(1));
    expect(pauseStatusEvents.first.payload['pause_reason'], 'Aguardando visto');

    final json = await repos.export.exportJson();
    expect(json, contains('"version": 37'));
    expect(json, contains('"projects"'));
    expect(json, contains('"quest_project_links"'));
    expect(json, contains('Viagem 2026'));
  });

  test('project status transitions round-trip via save', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final project = await repos.projects.create(
      profileId: profile.id,
      title: 'Status flow',
    );
    expect(project.status, ProjectStatus.active);

    final completed = await repos.projects.save(
      project.copyWith(
        status: ProjectStatus.completed,
        updatedAt: DateTime.utc(2026, 8, 7),
      ),
    );
    expect(completed.status, ProjectStatus.completed);

    final loadedCompleted = await repos.projects.getById(project.id);
    expect(loadedCompleted?.status, ProjectStatus.completed);

    final archived = await repos.projects.save(
      completed.copyWith(
        status: ProjectStatus.archived,
        updatedAt: DateTime.utc(2026, 8, 8),
      ),
    );
    expect(archived.status, ProjectStatus.archived);

    final loadedArchived = await repos.projects.getById(project.id);
    expect(loadedArchived?.status, ProjectStatus.archived);

    final events = await repos.events.listTimeline();
    expect(
      events.where((e) => e.eventType == EventType.projectUpdated).length,
      greaterThanOrEqualTo(2),
    );
  });

  test('decision CRUD, quest link and export v4', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Mudança de emprego',
      purpose: 'Avaliar oferta',
      status: QuestStatus.active,
    );
    final decision = await repos.decisions.create(
      profileId: profile.id,
      title: 'Aceitar oferta',
      context: 'Proposta de nova função remota',
      decision: 'Aceitar com prazo de 30 dias',
      alternatives: ['Permanecer', 'Negociar contraproposta'],
      reversibility: DecisionReversibility.hard,
    );
    await repos.decisions.linkQuest(
      questId: quest.id,
      decisionId: decision.id,
    );

    final linked = await repos.decisions.watchByQuest(quest.id).first;
    expect(linked, hasLength(1));
    expect(linked.first.title, 'Aceitar oferta');

    final updated = decision.copyWith(
      decision: 'Aceitar com prazo de 45 dias',
      updatedAt: DateTime.utc(2026, 8, 7),
      version: decision.version + 1,
    );
    await repos.decisions.save(updated);
    final loaded = await repos.decisions.getById(decision.id);
    expect(loaded!.decision, 'Aceitar com prazo de 45 dias');

    final events = await repos.events.listTimeline();
    expect(events.any((e) => e.eventType == EventType.decisionCreated), isTrue);
    expect(events.any((e) => e.eventType == EventType.decisionUpdated), isTrue);

    final json = await repos.export.exportJson();
    expect(json, contains('"version": 37'));
    expect(json, contains('"decision_records"'));
    expect(json, contains('"quest_decision_links"'));
    expect(json, contains('Aceitar oferta'));
  });

  test('decision delete removes record and quest links', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Quest',
      purpose: 'P',
      status: QuestStatus.active,
    );
    final decision = await repos.decisions.create(
      profileId: profile.id,
      title: 'Decisão temp',
      context: 'Ctx',
      decision: 'Sim',
    );
    await repos.decisions.linkQuest(
      questId: quest.id,
      decisionId: decision.id,
    );

    await repos.decisions.delete(decision.id);

    expect(await repos.decisions.getById(decision.id), isNull);
    expect(await repos.decisions.listLinks(profile.id), isEmpty);

    final events = await repos.events.listTimeline();
    expect(events.any((e) => e.eventType == EventType.decisionDeleted), isTrue);
  });

  test('quest prerequisite link unlink and cycle rejection', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final a = await repos.quests.create(
      profileId: profile.id,
      title: 'A',
      purpose: 'P',
    );
    final b = await repos.quests.create(
      profileId: profile.id,
      title: 'B',
      purpose: 'P',
    );

    await repos.quests.linkPrerequisite(
      questId: b.id,
      prerequisiteQuestId: a.id,
    );

    final prereqs = await repos.quests.listPrerequisites(b.id);
    expect(prereqs, hasLength(1));
    expect(prereqs.first.id, a.id);

    await repos.quests.unlinkPrerequisite(
      questId: b.id,
      prerequisiteQuestId: a.id,
    );
    expect(await repos.quests.listPrerequisites(b.id), isEmpty);

    await repos.quests.linkPrerequisite(
      questId: a.id,
      prerequisiteQuestId: b.id,
    );
    expect(
      () => repos.quests.linkPrerequisite(
        questId: b.id,
        prerequisiteQuestId: a.id,
      ),
      throwsA(isA<QuestPrerequisiteException>()),
    );
  });

  test('updateStatus draft to active requires acceptAndActivate', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final main = await repos.quests.create(
      profileId: profile.id,
      title: 'Main',
      purpose: 'P',
      status: QuestStatus.draft,
    );

    expect(
      () => repos.quests.updateStatus(main, QuestStatus.active),
      throwsA(isA<StateError>()),
    );
  });

  test('acceptAndActivate blocked by incomplete prerequisite', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final prereq = await repos.quests.create(
      profileId: profile.id,
      title: 'Prereq',
      purpose: 'P',
      status: QuestStatus.draft,
    );
    final main = await repos.quests.create(
      profileId: profile.id,
      title: 'Main',
      purpose: 'P',
      status: QuestStatus.draft,
    );
    await repos.quests.linkPrerequisite(
      questId: main.id,
      prerequisiteQuestId: prereq.id,
    );

    expect(
      () => repos.quests.acceptAndActivate(
        main,
        acceptanceAssumptions: ['Premissa'],
      ),
      throwsA(isA<QuestPrerequisiteException>()),
    );
  });

  test('acceptAndActivate sets acceptance fields and records event', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final draft = await repos.quests.create(
      profileId: profile.id,
      title: 'Aceitar',
      purpose: 'Propósito',
      status: QuestStatus.draft,
    );

    final accepted = await repos.quests.acceptAndActivate(
      draft,
      acceptanceAssumptions: ['  Tenho tempo  ', ''],
      acceptanceDeadline: DateTime.utc(2026, 9, 1),
    );

    expect(accepted.status, QuestStatus.active);
    expect(accepted.acceptedAt, DateTime.utc(2026, 8, 6, 12));
    expect(accepted.acceptanceAssumptions, ['Tenho tempo']);
    expect(accepted.acceptanceDeadline, DateTime.utc(2026, 9, 1));

    final loaded = await repos.quests.getById(draft.id);
    expect(loaded!.acceptanceAssumptions, ['Tenho tempo']);

    final events = await repos.events.listTimeline(limit: 10);
    expect(events.any((e) => e.eventType == EventType.questAccepted), isTrue);
  });

  test('project save rejects active to archived', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final project = await repos.projects.create(
      profileId: profile.id,
      title: 'Skip complete',
    );

    expect(
      () => repos.projects.save(
        project.copyWith(
          status: ProjectStatus.archived,
          updatedAt: DateTime.utc(2026, 8, 7),
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('weekly review save records weeklyReviewCompleted event', () async {
    final weeklyDb = ColonyDatabase.inMemory();
    addTearDown(weeklyDb.close);
    final weeklyRepos = ColonyRepositories.create(
      weeklyDb,
      idGenerator: FixedIdGenerator(['profile-1', 'weekly-1', 'event-1']),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    final profile = await weeklyRepos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    await weeklyRepos.weeklyReviews.save(
      profileId: profile.id,
      weekStartDate: DateTime.utc(2026, 8, 4),
      wins: 'Boa semana',
    );

    final events = await weeklyRepos.events.listTimeline();
    expect(events.any((e) => e.eventType == EventType.weeklyReviewCompleted), isTrue);
  });

  test('research CRUD link prereq and export v9', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    final base = await repos.research.create(
      profileId: profile.id,
      title: 'Base',
      type: ResearchNodeType.knowledge,
    );
    var baseUpdated = await repos.research.updateStatus(
      base,
      ResearchNodeStatus.inResearch,
    );
    await repos.research.addEvidence(
      profileId: profile.id,
      nodeId: baseUpdated.id,
      type: ResearchEvidenceType.summary,
      title: 'Prova base',
      body: 'Conteúdo da demonstração',
    );
    baseUpdated = await repos.research.updateStatus(
      baseUpdated,
      ResearchNodeStatus.demonstrated,
    );

    final advanced = await repos.research.create(
      profileId: profile.id,
      title: 'Avançado',
      type: ResearchNodeType.skill,
    );
    await repos.research.linkPrerequisite(
      nodeId: advanced.id,
      prerequisiteNodeId: base.id,
    );

    await repos.research.updateStatus(advanced, ResearchNodeStatus.inResearch);

    final json = await repos.export.exportJson();
    expect(json, contains('"version": 37'));
    expect(json, contains('"research_nodes"'));
    expect(json, contains('"learning_sessions"'));
    expect(json, contains('"research_evidence"'));
  });

  test('quest research link unlink and watch', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Missão pesquisa',
      purpose: 'Vincular nó',
      status: QuestStatus.active,
    );
    final node = await repos.research.create(
      profileId: profile.id,
      title: 'Dart',
      type: ResearchNodeType.knowledge,
    );

    await repos.research.linkQuest(
      questId: quest.id,
      researchNodeId: node.id,
    );
    // idempotent
    await repos.research.linkQuest(
      questId: quest.id,
      researchNodeId: node.id,
    );

    final linked = await repos.research.watchLinkedToQuest(quest.id).first;
    expect(linked, hasLength(1));
    expect(linked.first.id, node.id);

    final reverse = await repos.research.watchLinkedQuests(node.id).first;
    expect(reverse, hasLength(1));
    expect(reverse.first.id, quest.id);

    final links = await repos.research.listQuestLinks(profile.id);
    expect(links, hasLength(1));

    await repos.research.unlinkQuest(
      questId: quest.id,
      researchNodeId: node.id,
    );
    expect(await repos.research.watchLinkedToQuest(quest.id).first, isEmpty);
    expect(await repos.research.watchLinkedQuests(node.id).first, isEmpty);
  });

  test('home maintenance links inventory item', () async {
    final profile = await repos.profiles.create(
      colonyName: 'HomeInv',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final item = await repos.inventory.create(
      profileId: profile.id,
      name: 'Filtro HVAC',
      category: InventoryCategory.other,
    );
    final task = await repos.homeMaintenance.create(
      profileId: profile.id,
      title: 'Trocar filtro',
      systemOrItem: 'HVAC',
      linkedInventoryItemId: item.id,
    );
    expect(task.linkedInventoryItemId, item.id);
    final listed = await repos.homeMaintenance.listAll(profile.id);
    expect(listed.single.linkedInventoryItemId, item.id);
  });

  test('ics preview creates schedule blocks as meeting', () async {
    final profile = await repos.profiles.create(
      colonyName: 'IcsSched',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final start = DateTime.utc(2026, 8, 7, 14);
    final end = start.add(const Duration(minutes: 30));
    final preview = IcsEventPreview(
      uid: 'u1',
      summary: 'Standup',
      startAt: start,
      endAt: end,
    );
    await repos.integrations.setConsentEnabled(
      profileId: profile.id,
      kind: IntegrationKind.calendarIcs,
      enabled: true,
    );
    await repos.integrations.importCalendarPreviews(
      profileId: profile.id,
      previews: [preview],
    );
    for (final p in IcsSchedulePolicy.selectableForSchedule([preview])) {
      await repos.schedule.create(
        profileId: profile.id,
        startAt: p.startAt,
        endAt: p.endAt,
        mode: IcsSchedulePolicy.defaultMode,
        sourceType: SourceType.integration,
      );
    }
    final blocks = await repos.schedule.listAll(profile.id);
    expect(blocks, hasLength(1));
    expect(blocks.single.mode, ScheduleBlockMode.meeting);
    expect(blocks.single.startAt, start);
  });

  test('trip and zone create enqueue sync outbox', () async {
    final profile = await repos.profiles.create(
      colonyName: 'SyncExpand',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final trip = await repos.trips.create(
      profileId: profile.id,
      title: 'Porto',
    );
    final zone = await repos.contextZones.create(
      profileId: profile.id,
      name: 'Escritório',
    );
    final pending = await repos.sync.listPending();
    expect(
      pending.any((op) => op.entityType == 'trip' && op.entityId == trip.id),
      isTrue,
    );
    expect(
      pending.any(
        (op) => op.entityType == 'context_zone' && op.entityId == zone.id,
      ),
      isTrue,
    );
  });

  test('task quest inventory create enqueue sync outbox', () async {
    final profile = await repos.profiles.create(
      colonyName: 'SyncWiden',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final task = await repos.tasks.capture(
      profileId: profile.id,
      title: 'Captura sync',
    );
    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Missão sync',
      purpose: 'Outbox',
    );
    final item = await repos.inventory.create(
      profileId: profile.id,
      name: 'Cabo',
      category: InventoryCategory.electronics,
    );
    final pending = await repos.sync.listPending();
    expect(
      pending.any((op) => op.entityType == 'task' && op.entityId == task.id),
      isTrue,
    );
    expect(
      pending.any((op) => op.entityType == 'quest' && op.entityId == quest.id),
      isTrue,
    );
    expect(
      pending.any(
        (op) => op.entityType == 'inventory_item' && op.entityId == item.id,
      ),
      isTrue,
    );
  });

  test('trip-inventory packing link unlink and export', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Packing',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final trip = await repos.trips.create(
      profileId: profile.id,
      title: 'Lisboa',
    );
    final item = await repos.inventory.create(
      profileId: profile.id,
      name: 'Mochila',
      category: InventoryCategory.electronics,
    );
    await repos.trips.linkInventoryItem(
      tripId: trip.id,
      inventoryItemId: item.id,
    );
    await repos.trips.linkInventoryItem(
      tripId: trip.id,
      inventoryItemId: item.id,
    );

    final linked = await repos.trips.watchLinkedInventory(trip.id).first;
    expect(linked, hasLength(1));
    expect(linked.single.name, 'Mochila');

    final snapshot = await repos.export.buildSnapshot();
    expect(snapshot.version, 37);
    expect(snapshot.tripInventoryLinks, hasLength(1));

    await repos.trips.unlinkInventoryItem(
      tripId: trip.id,
      inventoryItemId: item.id,
    );
    expect(await repos.trips.watchLinkedInventory(trip.id).first, isEmpty);
  });

  test('zone-trip link unlink and export', () async {
    final profile = await repos.profiles.create(
      colonyName: 'ZoneTrip',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final zone = await repos.contextZones.create(
      profileId: profile.id,
      name: 'Avião',
      connectivity: ZoneConnectivity.limited,
    );
    final trip = await repos.trips.create(
      profileId: profile.id,
      title: 'Lisboa',
    );
    await repos.contextZones.linkTrip(zoneId: zone.id, tripId: trip.id);
    await repos.contextZones.linkTrip(zoneId: zone.id, tripId: trip.id);

    final linked = await repos.contextZones.watchLinkedTrips(zone.id).first;
    expect(linked, hasLength(1));
    expect(linked.single.title, 'Lisboa');

    final snapshot = await repos.export.buildSnapshot();
    expect(snapshot.version, 37);
    expect(snapshot.zoneTripLinks, hasLength(1));

    await repos.contextZones.unlinkTrip(zoneId: zone.id, tripId: trip.id);
    expect(await repos.contextZones.watchLinkedTrips(zone.id).first, isEmpty);
  });

  test('quest-inventory link unlink and export', () async {
    final profile = await repos.profiles.create(
      colonyName: 'InvQuest',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final item = await repos.inventory.create(
      profileId: profile.id,
      name: 'Camera',
      category: InventoryCategory.electronics,
    );
    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Filmagem',
      purpose: 'Doc',
      status: QuestStatus.active,
    );
    await repos.inventory.linkQuest(
      questId: quest.id,
      inventoryItemId: item.id,
    );
    await repos.inventory.linkQuest(
      questId: quest.id,
      inventoryItemId: item.id,
    );

    final linked = await repos.inventory.watchLinkedQuests(item.id).first;
    expect(linked, hasLength(1));

    final snapshot = await repos.export.buildSnapshot();
    expect(snapshot.version, 37);
    expect(snapshot.questInventoryLinks, hasLength(1));

    await repos.inventory.unlinkQuest(
      questId: quest.id,
      inventoryItemId: item.id,
    );
    expect(await repos.inventory.watchLinkedQuests(item.id).first, isEmpty);
  });

  test('person-organization membership link unlink and export', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Membership',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final person = await repos.people.create(
      profileId: profile.id,
      displayName: 'Ana',
    );
    final org = await repos.organizations.create(
      profileId: profile.id,
      name: 'Acme',
      kind: OrganizationKind.company,
    );

    await repos.organizations.linkPerson(
      personId: person.id,
      organizationId: org.id,
      role: 'colega',
    );
    await repos.organizations.linkPerson(
      personId: person.id,
      organizationId: org.id,
      role: 'colega',
    );

    final members = await repos.organizations.watchMembers(org.id).first;
    expect(members, hasLength(1));
    expect(members.first.id, person.id);

    final memberships =
        await repos.organizations.watchMembershipsForPerson(person.id).first;
    expect(memberships, hasLength(1));
    expect(memberships.first.id, org.id);

    final snapshot = await repos.export.buildSnapshot();
    expect(snapshot.version, 37);
    expect(snapshot.personOrganizationLinks, hasLength(1));
    expect(snapshot.personOrganizationLinks.first.role, 'colega');

    await repos.organizations.unlinkPerson(
      personId: person.id,
      organizationId: org.id,
    );
    expect(await repos.organizations.watchMembers(org.id).first, isEmpty);
  });

  test('category budget save updates limit and records event', () async {
    final budgetDb = ColonyDatabase.inMemory();
    addTearDown(budgetDb.close);
    final budgetRepos = ColonyRepositories.create(
      budgetDb,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'budget-1',
        'event-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 15, 12),
    );

    final profile = await budgetRepos.profiles.create(
      colonyName: 'Budget',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final created = await budgetRepos.finance.createBudget(
      profileId: profile.id,
      categoryId: TransactionCategoryPolicy.categoryIdFor(
        TransactionCategory.food,
      ),
      currency: 'BRL',
      limitAmountMinor: 10000,
    );

    final updated = await budgetRepos.finance.saveBudget(
      created.copyWith(limitAmountMinor: 25000),
    );
    expect(updated.limitAmountMinor, 25000);

    final listed = await budgetRepos.finance.listBudgets(profile.id);
    expect(listed.single.limitAmountMinor, 25000);

    final events = await budgetRepos.events.listTimeline();
    expect(
      events.any((e) => e.eventType == EventType.categoryBudgetUpdated),
      isTrue,
    );
  });

  test('friendship overlay, circle membership and rhythm export', () async {
    final friendsDb = ColonyDatabase.inMemory();
    addTearDown(friendsDb.close);
    final friendsRepos = ColonyRepositories.create(
      friendsDb,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 20; i++) 'friend-rt-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 23, 12),
    );
    final profile = await friendsRepos.profiles.create(
      colonyName: 'Friends',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final person = await friendsRepos.people.create(
      profileId: profile.id,
      displayName: 'Ana',
    );
    final friendship = await friendsRepos.friendships.create(
      profileId: profile.id,
      personId: person.id,
      kind: FriendshipKind.close,
      howWeMet: 'faculdade',
    );
    expect(friendship.cadence, FriendshipCadence.fortnightly);
    final again = await friendsRepos.friendships.ensureForPerson(
      profileId: profile.id,
      personId: person.id,
      kind: FriendshipKind.casual,
    );
    expect(again.id, friendship.id);
    expect(again.kind, FriendshipKind.close);

    final circle = await friendsRepos.friendships.createCircle(
      profileId: profile.id,
      name: 'RPG',
      defaultCadence: FriendshipCadence.monthly,
    );
    await friendsRepos.friendships.linkPersonToCircle(
      personId: person.id,
      circleId: circle.id,
    );
    await friendsRepos.people.logInteraction(
      profileId: profile.id,
      person: person,
      kind: InteractionKind.meeting,
      occurredAt: DateTime.utc(2026, 8, 1),
    );

    final snapshot = await friendsRepos.export.buildSnapshot();
    expect(snapshot.version, 37);
    expect(snapshot.friendships, hasLength(1));
    expect(snapshot.friendshipCircles, hasLength(1));
    expect(snapshot.friendshipCircleMemberships, hasLength(1));

    final overviews = FriendshipOverview.assemble(
      people: snapshot.people,
      friendships: snapshot.friendships,
      circles: snapshot.friendshipCircles,
      memberships: snapshot.friendshipCircleMemberships,
      interactions: snapshot.personInteractions,
      now: DateTime.utc(2026, 8, 23, 12),
    );
    expect(overviews.single.circles.single.name, 'RPG');
    expect(overviews.single.rhythm.daysSinceLastEncounter, 22);
    expect(overviews.single.rhythm.attention, FriendshipAttention.overdue);
  });
}
