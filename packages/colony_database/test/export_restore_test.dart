import 'dart:convert';
import 'dart:io';

import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late ColonyDatabase db;
  late ColonyRepositories repos;

  setUp(() {
    db = ColonyDatabase.inMemory();
    repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'quest-1',
        'event-1',
        'task-1',
        'decision-1',
        'event-2',
        'event-3',
        'restore-event-1',
        'weekly-1',
        'event-4',
        'event-5',
        for (var i = 0; i < 30; i++) 'export-spare-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 14),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<ExportSnapshot> loadFixture(String name) async {
    final scriptPath = Platform.script.toFilePath();
    final candidates = [
      p.join(p.dirname(scriptPath), 'fixtures', name),
      p.join(Directory.current.path, 'test', 'fixtures', name),
      p.join(
        Directory.current.path,
        'packages',
        'colony_database',
        'test',
        'fixtures',
        name,
      ),
    ];
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) {
        return ExportSnapshot.fromJsonString(await file.readAsString());
      }
    }
    throw StateError('Fixture not found: $name');
  }

  test('restore v4 fixture into empty database', () async {
    final snapshot = await loadFixture('export_v4.json');
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.id.value, 'profile-fixture-v4');
    expect(profile.colonyName, 'Fixture V4');

    final quests = await repos.quests.listAll(profile.id);
    expect(quests, hasLength(1));

    final tasks = await repos.tasks.listAll(profile.id);
    expect(tasks.first.questId?.value, 'quest-v4-1');

    final decisions = await repos.decisions.listAll(profile.id);
    expect(decisions, hasLength(1));

    final links = await repos.decisions.listLinks(profile.id);
    expect(links, hasLength(1));

    final events = await repos.events.listTimeline();
    expect(events.any((e) => e.eventType == EventType.exportRestored), isTrue);
  });

  test('restore v2 and v3 fixtures preserve links', () async {
    final v2 = await loadFixture('export_v2.json');
    await repos.restore.restore(v2);

    var profile = await repos.profiles.getActive();
    var quests = await repos.quests.listAll(profile!.id);
    expect(quests.first.title, 'Miss\u00e3o fixture');

    final v3 = await loadFixture('export_v3.json');
    await repos.restore.restore(v3);

    profile = await repos.profiles.getActive();
    final projects = await repos.projects.listAll(profile!.id);
    expect(projects, hasLength(1));

    final projectLinks = await repos.projects.listLinks(profile.id);
    expect(projectLinks, hasLength(1));
  });

  test('export restore re-export round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Round Trip',
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
      title: 'Miss\u00e3o RT',
      purpose: 'Testar restore',
      status: QuestStatus.active,
    );
    await repos.tasks.capture(
      profileId: profile.id,
      title: 'A\u00e7\u00e3o RT',
    );
    final decision = await repos.decisions.create(
      profileId: profile.id,
      title: 'Decis\u00e3o RT',
      context: 'Ctx',
      decision: 'Sim',
    );
    await repos.decisions.linkQuest(questId: quest.id, decisionId: decision.id);

    final before = await repos.export.buildSnapshot();
    final beforeJson = jsonEncode(before.toJson());

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    final afterJson = jsonEncode(after.toJson());

    expect(after.profile.id, before.profile.id);
    expect(after.tasks.length, before.tasks.length);
    expect(after.quests.length, before.quests.length);
    expect(after.decisionRecords.length, before.decisionRecords.length);
    expect(after.questDecisionLinks.length, before.questDecisionLinks.length);

    final beforeMap = jsonDecode(beforeJson) as Map<String, dynamic>;
    final afterMap = jsonDecode(afterJson) as Map<String, dynamic>;
    expect(afterMap['profile'], beforeMap['profile']);
    expect(afterMap['tasks'], beforeMap['tasks']);
    expect(afterMap['quests'], beforeMap['quests']);
    expect(afterMap['decision_records'], beforeMap['decision_records']);
  });

  test('restore v5 fixture preserves prerequisite links', () async {
    final snapshot = await loadFixture('export_v5.json');
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    final links = await repos.quests.listPrerequisiteLinks(profile!.id);
    expect(links, hasLength(1));
    expect(links.first.questId.value, 'quest-v5-main');
    expect(links.first.prerequisiteQuestId.value, 'quest-v5-prereq');
  });

  test('export v5 round-trip includes prerequisite links', () async {
    final profile = await repos.profiles.create(
      colonyName: 'V5 RT',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    final prereq = await repos.quests.create(
      profileId: profile.id,
      title: 'Docs',
      purpose: 'Passaporte',
      status: QuestStatus.completed,
    );
    final main = await repos.quests.create(
      profileId: profile.id,
      title: 'Reservas',
      purpose: 'Hot\u00e9is',
      status: QuestStatus.draft,
    );
    await repos.quests.linkPrerequisite(
      questId: main.id,
      prerequisiteQuestId: prereq.id,
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.questPrerequisiteLinks, hasLength(1));

    await repos.restore.restore(before);
    final after = await repos.export.buildSnapshot();
    expect(after.questPrerequisiteLinks, before.questPrerequisiteLinks);
  });

  test('restore v6 fixture preserves pawn data', () async {
    final snapshot = await loadFixture('export_v6.json');
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V6');

    final checkIns = await repos.checkIns.listAll(profile.id);
    expect(checkIns, hasLength(1));
    expect(checkIns.first.note, 'Manh\u00e3 produtiva');

    final factors = await repos.checkIns.getFactors(checkIns.first.id);
    expect(factors, hasLength(2));
    expect(factors.map((f) => f.label), contains('Avan\u00e7o significativo'));

    final reviews = await repos.dailyReviews.listAll(profile.id);
    expect(reviews, hasLength(1));
    expect(reviews.first.whatHappened, 'Reuni\u00f5es e foco');
  });

  test('export v6 pawn round-trip preserves daily reviews and mood factors', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Pawn RT',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    final checkIn = await repos.checkIns.save(
      profileId: profile.id,
      mood: 0.8,
      energy: 0.6,
      tension: 0.2,
      focus: 0.7,
      note: 'Bom dia',
      factors: [
        (label: 'Intera\u00e7\u00e3o positiva', impact: 4, uncertain: false),
        (label: 'Preocupa\u00e7\u00e3o com prazo', impact: 2, uncertain: true),
      ],
    );
    await repos.dailyReviews.save(
      profileId: profile.id,
      reviewDate: DateTime.utc(2026, 8, 5),
      whatHappened: 'Entreguei MVP',
      currentState: 'Focado',
      tomorrowCommitments: 'Testes',
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.checkIns, hasLength(1));
    expect(before.dailyReviews, hasLength(1));
    expect(before.moodFactors, hasLength(2));

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.checkIns.length, before.checkIns.length);
    expect(after.dailyReviews.length, before.dailyReviews.length);
    expect(after.moodFactors.length, before.moodFactors.length);
    expect(after.dailyReviews.first.whatHappened, 'Entreguei MVP');

    final restoredFactors = await repos.checkIns.getFactors(checkIn.id);
    expect(restoredFactors, hasLength(2));
    expect(restoredFactors.map((f) => f.label), contains('Intera\u00e7\u00e3o positiva'));
  });

  test('restore v7 fixture preserves weekly reviews', () async {
    final snapshot = await loadFixture('export_v7.json');
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V7');

    final reviews = await repos.weeklyReviews.listAll(profile.id);
    expect(reviews, hasLength(1));
    expect(reviews.first.facts, 'Entregamos export v6');
    expect(reviews.first.nextWeek, 'Weekly review MVP');
  });

  test('export v7 weekly review round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Weekly RT',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
      weekStartsOnMonday: true,
    ));

    await repos.weeklyReviews.save(
      profileId: profile.id,
      weekStartDate: DateTime.utc(2026, 8, 3),
      facts: 'Fatos',
      wins: 'Vit\u00f3rias',
      nextWeek: 'Pr\u00f3xima',
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.weeklyReviews, hasLength(1));

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.weeklyReviews.length, before.weeklyReviews.length);
    expect(after.weeklyReviews.first.wins, 'Vit\u00f3rias');
  });

  test('restore v8 fixture preserves quest acceptance fields', () async {
    final snapshot = await loadFixture('export_v8.json');
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V8');

    final quests = await repos.quests.listAll(profile.id);
    expect(quests, hasLength(1));
    expect(quests.first.title, 'Miss\u00e3o aceita');
    expect(quests.first.acceptedAt, DateTime.utc(2026, 8, 2, 14));
    expect(
      quests.first.acceptanceDeadline,
      DateTime.utc(2026, 9, 1),
    );
    expect(
      quests.first.acceptanceAssumptions,
      ['Tenho tempo nas pr\u00f3ximas semanas', 'Documentos em ordem'],
    );
  });

  test('export v8 quest acceptance round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Acceptance RT',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final draft = await repos.quests.create(
      profileId: profile.id,
      title: 'Aceite RT',
      purpose: 'Testar export',
    );
    final accepted = await repos.quests.acceptAndActivate(
      draft,
      acceptanceAssumptions: ['Premissa A'],
      acceptanceDeadline: DateTime.utc(2026, 9, 15),
    );
    expect(accepted.acceptedAt, isNotNull);

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.quests.single.acceptanceAssumptions, ['Premissa A']);

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.quests.single.acceptanceAssumptions, ['Premissa A']);
    expect(after.quests.single.acceptanceDeadline, DateTime.utc(2026, 9, 15));
  });

  test('restore v9 fixture preserves research nodes and links', () async {
    final snapshot = await loadFixture('export_v9.json');
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V9');

    final nodes = await repos.research.listAll(profile.id);
    expect(nodes, hasLength(2));
    expect(nodes.any((n) => n.title == 'Fundamentos'), isTrue);

    final links = await repos.research.listPrerequisiteLinks(profile.id);
    expect(links, hasLength(1));
    expect(links.first.nodeId.value, 'research-advanced');
  });

  test('restore v8 backfills empty research arrays', () async {
    final snapshot = await loadFixture('export_v8.json');
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    final nodes = await repos.research.listAll(profile!.id);
    expect(nodes, isEmpty);
  });

  test('export v9 research round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Research RT',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    await repos.research.create(
      profileId: profile.id,
      title: 'Node RT',
      type: ResearchNodeType.practice,
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.researchNodes, hasLength(1));

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.researchNodes.single.title, 'Node RT');
  });

  test('restore v10 fixture preserves sessions and evidence', () async {
    final snapshot = await loadFixture('export_v10.json');
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V10');

    final sessions = await repos.research.listSessions(
      const EntityId('research-focus'),
    );
    expect(sessions, hasLength(1));
    expect(sessions.first.durationMinutes, 45);

    final evidence = await repos.research.listEvidence(
      const EntityId('research-focus'),
    );
    expect(evidence, hasLength(1));
    expect(evidence.first.sessionId?.value, 'session-1');
  });

  test('export v10 sessions and evidence round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Research V10',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final node = await repos.research.create(
      profileId: profile.id,
      title: 'Node V10',
      type: ResearchNodeType.knowledge,
    );
    await repos.research.updateStatus(node, ResearchNodeStatus.inResearch);
    await repos.research.logSession(
      profileId: profile.id,
      nodeId: node.id,
      startedAt: DateTime.utc(2026, 8, 6, 9),
      durationMinutes: 60,
      mode: LearningSessionMode.practice,
    );
    await repos.research.addEvidence(
      profileId: profile.id,
      nodeId: node.id,
      type: ResearchEvidenceType.note,
      title: 'Evid\u00eancia RT',
      body: 'Corpo',
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.learningSessions, hasLength(1));
    expect(before.researchEvidence, hasLength(1));

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.learningSessions.single.mode, LearningSessionMode.practice);
    expect(after.researchEvidence.single.title, 'Evid\u00eancia RT');
  });

  test('restore v10 fixture yields empty finance on re-export', () async {
    final snapshot = await loadFixture('export_v10.json');
    await repos.restore.restore(snapshot);

    final after = await repos.export.buildSnapshot();
    expect(after.version, 37);
    expect(after.financialEntities, isEmpty);
    expect(after.financialAccounts, isEmpty);
    expect(after.transactions, isEmpty);
  });

  test('restore v11 fixture preserves finance entities accounts transactions', () async {
    final snapshot = await loadFixture('export_v11.json');
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V11');

    final entities = await repos.finance.listEntities(profile.id);
    expect(entities, hasLength(1));
    expect(entities.first.name, 'Pessoal');

    final accounts = await repos.finance.listAccounts(profile.id);
    expect(accounts, hasLength(1));
    expect(accounts.first.name, 'Corrente');

    final transactions = await repos.finance.listTransactions(profile.id);
    expect(transactions, hasLength(1));
    expect(transactions.first.descriptionOriginal, 'Mercado');
  });

  test('export v11 finance round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Finance V11',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    await repos.finance.seedDefaults(profile.id);
    final entity = (await repos.finance.listEntities(profile.id)).first;
    final account = await repos.finance.createAccount(
      profileId: profile.id,
      entityId: entity.id,
      institution: 'Banco',
      name: 'Poupan\u00e7a',
      type: FinancialAccountType.savings,
      currency: 'BRL',
      currentBalanceMinor: 100000,
    );
    await repos.finance.createTransaction(
      profileId: profile.id,
      accountId: account.id,
      occurredAt: DateTime.utc(2026, 8, 6),
      descriptionOriginal: 'Dep\u00f3sito',
      amountMinor: 50000,
      currency: 'BRL',
      direction: TransactionDirection.inflow,
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.financialEntities, hasLength(1));
    expect(before.financialAccounts, hasLength(1));
    expect(before.transactions, hasLength(1));

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.financialAccounts.single.name, 'Poupan\u00e7a');
    expect(after.transactions.single.descriptionOriginal, 'Dep\u00f3sito');
  });

  test('restore v12 fixture preserves quest research links and finance', () async {
    final snapshot = await loadFixture('export_v12.json');
    expect(snapshot.version, 12);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V12');

    final quests = await repos.quests.listAll(profile.id);
    expect(quests, hasLength(1));
    final nodes = await repos.research.listAll(profile.id);
    expect(nodes, hasLength(1));
    final linked = await repos.research.watchLinkedToQuest(quests.first.id).first;
    expect(linked.single.title, 'Flutter basics');

    final entities = await repos.finance.listEntities(profile.id);
    expect(entities, hasLength(1));
    final transactions = await repos.finance.listTransactions(profile.id);
    expect(transactions.single.descriptionOriginal, 'Mercado');
  });

  test('restore v13 fixture preserves health conditions without symptoms', () async {
    final snapshot = await loadFixture('export_v13.json');
    expect(snapshot.version, 13);
    expect(snapshot.symptomEntries, isEmpty);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V13');

    final conditions = await repos.health.listAll(profile.id);
    expect(conditions, hasLength(1));
    expect(conditions.single.title, 'Dor lombar');
    expect(conditions.single.status, HealthConditionStatus.monitoring);

    final after = await repos.export.buildSnapshot();
    expect(after.version, 37);
    expect(after.symptomEntries, isEmpty);
  });

  test('restore v14 fixture preserves health symptoms and finance', () async {
    final snapshot = await loadFixture('export_v14.json');
    expect(snapshot.version, 14);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V14');

    final conditions = await repos.health.listAll(profile.id);
    expect(conditions.single.title, 'Enxaqueca');
    final entries = await repos.health.listAllSymptomEntries(profile.id);
    expect(entries, hasLength(1));
    expect(entries.single.intensity, 4);
    expect(entries.single.note, 'ap\u00f3s almo\u00e7o');

    final transactions = await repos.finance.listTransactions(profile.id);
    expect(transactions.single.descriptionOriginal, 'Mercado');

    final linked = await repos.research
        .watchLinkedToQuest(const EntityId('quest-1'))
        .first;
    expect(linked.single.title, 'Flutter basics');
    expect(snapshot.inventoryItems, isEmpty);
  });

  test('restore v15 fixture preserves inventory items', () async {
    final snapshot = await loadFixture('export_v15.json');
    expect(snapshot.version, 15);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V15');

    final items = await repos.inventory.listAll(profile.id);
    expect(items, hasLength(1));
    expect(items.single.name, 'Notebook');
    expect(items.single.category, InventoryCategory.electronics);
    expect(items.single.locationLabel, 'mesa');
    expect(items.single.tags, ['casa', 'tech']);
    expect(snapshot.people, isEmpty);
  });

  test('restore v16 fixture preserves people', () async {
    final snapshot = await loadFixture('export_v16.json');
    expect(snapshot.version, 16);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V16');

    final people = await repos.people.listAll(profile.id);
    expect(people, hasLength(1));
    expect(people.single.displayName, 'Ana Silva');
    expect(people.single.preferredName, 'Aninha');
    expect(people.single.relationshipTypes, ['amiga', 'colegas']);
    expect(snapshot.categoryBudgets, isEmpty);
  });

  test('restore v17 fixture preserves category budgets', () async {
    final snapshot = await loadFixture('export_v17.json');
    expect(snapshot.version, 17);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V17');

    final budgets = await repos.finance.listBudgets(profile.id);
    expect(budgets, hasLength(1));
    expect(budgets.single.categoryId.value, 'cat_food');
    expect(budgets.single.limitAmountMinor, 50000);
    expect(budgets.single.currency, 'BRL');
    expect(snapshot.personInteractions, isEmpty);
  });

  test('restore v18 fixture preserves person interactions', () async {
    final snapshot = await loadFixture('export_v18.json');
    expect(snapshot.version, 18);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V18');

    final interactions = await repos.people.listAllInteractions(profile.id);
    expect(interactions, hasLength(1));
    expect(interactions.single.kind, InteractionKind.meeting);
    expect(interactions.single.note, 'caf\u00e9');
  });


  test('restore v19 fixture preserves trips', () async {
    final snapshot = await loadFixture('export_v19.json');
    expect(snapshot.version, 19);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V19');

    final trips = await repos.trips.listAll(profile.id);
    expect(trips, hasLength(1));
    expect(trips.single.title, 'F\u00e9rias SP');
    expect(trips.single.destinations, ['S\u00e3o Paulo', 'Campinas']);
    expect(trips.single.status, TripStatus.planned);
  });
  test('restore v20 fixture preserves organizations', () async {
    final snapshot = await loadFixture('export_v20.json');
    expect(snapshot.version, 20);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V20');

    final orgs = await repos.organizations.listAll(profile.id);
    expect(orgs, hasLength(1));
    expect(orgs.single.name, 'Acme Ltd');
    expect(orgs.single.kind, OrganizationKind.company);
  });

  test('restore v21 fixture preserves person-organization memberships', () async {
    final snapshot = await loadFixture('export_v21.json');
    expect(snapshot.version, 21);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V21');

    final links = await repos.organizations.listMemberships(profile.id);
    expect(links, hasLength(1));
    expect(links.single.personId.value, 'person-1');
    expect(links.single.organizationId.value, 'org-1');
    expect(links.single.role, 'membro');

    final members = await repos.organizations
        .watchMembers(const EntityId('org-1'))
        .first;
    expect(members, hasLength(1));
    expect(members.single.displayName, 'Ana');
  });

  test('restore v22 fixture preserves home maintenance tasks', () async {
    final snapshot = await loadFixture('export_v22.json');
    expect(snapshot.version, 22);
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V22');

    final tasks = await repos.homeMaintenance.listAll(profile.id);
    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'Filtro ar');
    expect(tasks.single.systemOrItem, 'HVAC');
    expect(tasks.single.cadenceDays, 90);
    expect(tasks.single.vendorLabel, 'TechCool');
  });

  test('restore v23 fixture preserves quest-inventory links', () async {
    final snapshot = await loadFixture('export_v23.json');
    expect(snapshot.version, 23);
    expect(snapshot.questInventoryLinks, hasLength(1));
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V23');

    final quests = await repos.quests.listAll(profile.id);
    expect(quests, hasLength(1));
    expect(quests.single.title, 'Organizar oficina');

    final items = await repos.inventory.listAll(profile.id);
    expect(items, hasLength(1));
    expect(items.single.name, 'Furadeira');

    final links = await repos.inventory.listQuestLinks(profile.id);
    expect(links, hasLength(1));
    expect(links.single.questId.value, 'quest-1');
    expect(links.single.inventoryItemId.value, 'inv-1');
  });

  test('restore v24 fixture preserves commitments', () async {
    final snapshot = await loadFixture('export_v24.json');
    expect(snapshot.version, 24);
    expect(snapshot.commitments, hasLength(1));
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V24');

    final commitments = await repos.commitments.listAll(profile.id);
    expect(commitments, hasLength(1));
    expect(commitments.single.description, 'Devolver livro');
    expect(commitments.single.madeToLabel, 'biblioteca');
    expect(commitments.single.status, CommitmentStatus.open);
  });

  test('restore v25 fixture preserves context zones', () async {
    final snapshot = await loadFixture('export_v25.json');
    expect(snapshot.version, 25);
    expect(snapshot.contextZones, hasLength(1));
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V25');

    final zones = await repos.contextZones.listAll(profile.id);
    expect(zones, hasLength(1));
    expect(zones.single.name, 'Caf\u00e9');
    expect(zones.single.connectivity, ZoneConnectivity.online);
    expect(zones.single.capabilities, contains('leitura'));
  });

  test('restore v26 fixture preserves zones, commitments and ICS', () async {
    final snapshot = await loadFixture('export_v26.json');
    expect(snapshot.version, 26);
    expect(snapshot.contextZones, hasLength(1));
    expect(snapshot.commitments, hasLength(1));
    expect(snapshot.integrationConsents, hasLength(1));
    expect(snapshot.externalCalendarEvents, hasLength(1));
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V26');

    final zones = await repos.contextZones.listAll(profile.id);
    expect(zones, hasLength(1));
    expect(zones.single.name, 'Avi\u00e3o');
    expect(zones.single.connectivity, ZoneConnectivity.limited);

    final commitments = await repos.commitments.listAll(profile.id);
    expect(commitments, hasLength(1));
    expect(commitments.single.description, 'Enviar relatório');

    final consents = await repos.integrations.listConsents(profile.id);
    expect(consents, hasLength(1));
    expect(consents.single.kind, IntegrationKind.calendarIcs);
    expect(consents.single.enabled, isTrue);

    final events = await repos.integrations.listCalendarEvents(profile.id);
    expect(events, hasLength(1));
    expect(events.single.title, 'Standup');
    expect(events.single.externalUid, 'uid-standup-1');

    final trips = await repos.trips.listAll(profile.id);
    expect(trips, hasLength(1));
    expect(trips.single.title, 'Lisboa');
  });

  test('restore v27 fixture preserves zone_trip_links', () async {
    final snapshot = await loadFixture('export_v27.json');
    expect(snapshot.version, 27);
    expect(snapshot.zoneTripLinks, hasLength(1));
    expect(snapshot.contextZones, hasLength(1));
    expect(snapshot.trips, hasLength(1));
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V27');

    final zones = await repos.contextZones.listAll(profile.id);
    expect(zones, hasLength(1));
    expect(zones.single.name, 'Aviao');

    final linked = await repos.contextZones.watchLinkedTrips(zones.single.id).first;
    expect(linked, hasLength(1));
    expect(linked.single.title, 'Lisboa');

    final links = await repos.contextZones.listTripLinks(profile.id);
    expect(links, hasLength(1));
    expect(links.single.zoneId, zones.single.id);
    expect(links.single.tripId, linked.single.id);
  });

  test('restore v28 fixture preserves health_appointments', () async {
    final snapshot = await loadFixture('export_v28.json');
    expect(snapshot.version, 28);
    expect(snapshot.healthAppointments, hasLength(1));
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V28');

    final appts = await repos.health.listAppointments(profile.id);
    expect(appts, hasLength(1));
    expect(appts.single.title, 'Check-up anual');
    expect(appts.single.status, HealthAppointmentStatus.scheduled);
    expect(appts.single.locationLabel, 'Clinica Central');
  });

  test('restore v29 fixture preserves trip_inventory_links', () async {
    final snapshot = await loadFixture('export_v29.json');
    expect(snapshot.version, 29);
    expect(snapshot.tripInventoryLinks, hasLength(1));
    expect(snapshot.trips, hasLength(1));
    expect(snapshot.inventoryItems, hasLength(1));
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V29');

    final trips = await repos.trips.listAll(profile.id);
    expect(trips, hasLength(1));
    expect(trips.single.title, 'Lisboa');

    final linked = await repos.trips.watchLinkedInventory(trips.single.id).first;
    expect(linked, hasLength(1));
    expect(linked.single.name, 'Mochila');

    final links = await repos.trips.listInventoryLinks(profile.id);
    expect(links, hasLength(1));
    expect(links.single.tripId, trips.single.id);
    expect(links.single.inventoryItemId, linked.single.id);
  });

  test('export v13 quest research links round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Research Links V12',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Aprender Flutter',
      purpose: 'Dominar UI',
      status: QuestStatus.active,
    );
    final node = await repos.research.create(
      profileId: profile.id,
      title: 'Flutter basics',
      type: ResearchNodeType.knowledge,
    );
    await repos.research.linkQuest(
      questId: quest.id,
      researchNodeId: node.id,
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.questResearchLinks, hasLength(1));
    expect(before.questResearchLinks.first.questId, quest.id);
    expect(before.questResearchLinks.first.researchNodeId, node.id);

    await repos.restore.restore(before);

    final linked = await repos.research.watchLinkedToQuest(quest.id).first;
    expect(linked, hasLength(1));
    expect(linked.first.title, 'Flutter basics');

    final after = await repos.export.buildSnapshot();
    expect(after.questResearchLinks, hasLength(1));
  });

  test('health symptom entry export restore round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Health RT',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final condition = await repos.health.create(
      profileId: profile.id,
      title: 'Enxaqueca',
      type: HealthConditionType.symptom,
    );
    await repos.health.logSymptomEntry(
      profileId: profile.id,
      conditionId: condition.id,
      intensity: 4,
      note: 'ap\u00f3s almo\u00e7o',
      bodyRegion: 'cabe\u00e7a',
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.symptomEntries, hasLength(1));

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.symptomEntries, hasLength(1));
    expect(after.symptomEntries.single.intensity, 4);
    expect(after.symptomEntries.single.note, 'ap\u00f3s almo\u00e7o');
    expect(after.symptomEntries.single.conditionId, condition.id);
  });

  test('inventory item export restore round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Inventory RT',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final item = await repos.inventory.create(
      profileId: profile.id,
      name: 'Passaporte',
      category: InventoryCategory.document,
      locationLabel: 'gaveta',
      notes: 'vence 2030',
      tags: const ['docs'],
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.inventoryItems, hasLength(1));

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.inventoryItems, hasLength(1));
    expect(after.inventoryItems.single.id, item.id);
    expect(after.inventoryItems.single.name, 'Passaporte');
    expect(after.inventoryItems.single.category, InventoryCategory.document);
    expect(after.inventoryItems.single.locationLabel, 'gaveta');
  });

  test('person export restore round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'People RT',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final person = await repos.people.create(
      profileId: profile.id,
      displayName: 'Bruno',
      preferredName: 'Bru',
      relationshipTypes: const ['familia'],
      notes: 'irm\u00e3o',
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.people, hasLength(1));

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.people, hasLength(1));
    expect(after.people.single.id, person.id);
    expect(after.people.single.displayName, 'Bruno');
    expect(after.people.single.preferredName, 'Bru');
  });

  test('category budget export restore round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Budget RT',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final budget = await repos.finance.createBudget(
      profileId: profile.id,
      categoryId: TransactionCategoryPolicy.categoryIdFor(
        TransactionCategory.food,
      ),
      currency: 'BRL',
      limitAmountMinor: 30000,
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.categoryBudgets, hasLength(1));

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.categoryBudgets, hasLength(1));
    expect(after.categoryBudgets.single.id, budget.id);
    expect(after.categoryBudgets.single.limitAmountMinor, 30000);
  });

  test('weekly review upserts same week', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Upsert',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final weekStart = DateTime.utc(2026, 8, 3);
    await repos.weeklyReviews.save(
      profileId: profile.id,
      weekStartDate: weekStart,
      facts: 'Primeiro rascunho',
    );
    await repos.weeklyReviews.save(
      profileId: profile.id,
      weekStartDate: weekStart,
      facts: 'Vers\u00e3o final',
      wins: 'Ship',
    );

    final reviews = await repos.weeklyReviews.listAll(profile.id);
    expect(reviews, hasLength(1));
    expect(reviews.first.facts, 'Vers\u00e3o final');
    expect(reviews.first.wins, 'Ship');
  });

  test('restore replaces prior profile data', () async {
    await repos.profiles.create(
      colonyName: 'Old',
      displayName: 'Old',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final snapshot = await loadFixture('export_v4.json');
    await repos.restore.restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'Fixture V4');

    final allProfiles = await db.select(db.profiles).get();
    expect(allProfiles, hasLength(1));
  });

  test('friendship export restore round-trip', () async {
    final profile = await repos.profiles.create(
      colonyName: 'Friends RT',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final person = await repos.people.create(
      profileId: profile.id,
      displayName: 'Ana',
    );
    await repos.friendships.create(
      profileId: profile.id,
      personId: person.id,
      kind: FriendshipKind.regular,
      cadence: FriendshipCadence.monthly,
      howWeMet: 'trabalho',
    );
    final circle = await repos.friendships.createCircle(
      profileId: profile.id,
      name: 'Faculdade',
    );
    await repos.friendships.linkPersonToCircle(
      personId: person.id,
      circleId: circle.id,
    );

    final before = await repos.export.buildSnapshot();
    expect(before.version, 37);
    expect(before.friendships, hasLength(1));
    expect(before.friendshipCircles, hasLength(1));
    expect(before.friendshipCircleMemberships, hasLength(1));

    await repos.restore.restore(before);

    final after = await repos.export.buildSnapshot();
    expect(after.friendships.single.howWeMet, 'trabalho');
    expect(after.friendshipCircles.single.name, 'Faculdade');
    expect(after.friendshipCircleMemberships, hasLength(1));
  });
}
