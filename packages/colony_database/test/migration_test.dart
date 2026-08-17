import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'migration_fixtures.dart';

void main() {
  group('schema migrations', () {
    test('v3 to v4 adds quests table and tasks.quest_id', () async {
      final db = await openMigratedFrom(
        3,
        seed: (sqlite) {
          seedProfile(sqlite);
          seedTask(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator(['quest-1', 'event-1', 'event-2']),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final quest = await repos.quests.create(
        profileId: profile.id,
        title: 'Nova missão',
        purpose: 'Propósito',
        status: QuestStatus.active,
      );
      final task = (await repos.tasks.listAll(profile.id)).single;
      await repos.tasks.linkToQuest(task, quest.id);

      final linked = await repos.tasks.listByQuest(quest.id);
      expect(linked, hasLength(1));
      expect(linked.first.questId, quest.id);
    });

    test('v4 to v5 adds projects, links and pause_reason', () async {
      final db = await openMigratedFrom(
        4,
        seed: (sqlite) {
          seedProfile(sqlite);
          seedQuestV4(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'project-1',
          'event-1',
          'event-2',
        ]),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final quest = (await repos.quests.listAll(profile.id)).single;

      final project = await repos.projects.create(
        profileId: profile.id,
        title: 'Viagem 2026',
        purpose: 'Planejamento geral',
      );
      await repos.projects.linkQuest(
        questId: quest.id,
        projectId: project.id,
      );

      final paused = await repos.quests.updateStatus(
        quest,
        QuestStatus.paused,
        pauseReason: 'Aguardando documentos',
      );
      expect(paused.pauseReason, 'Aguardando documentos');

      final links = await repos.projects.listLinks(profile.id);
      expect(links, hasLength(1));
      expect(links.first.projectId, project.id);
    });

    test('v5 to v6 adds decision_records and quest_decisions', () async {
      final db = await openMigratedFrom(
        5,
        seed: (sqlite) {
          seedProfile(sqlite);
          seedQuestV4(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'decision-1',
          'event-1',
          'event-2',
        ]),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final quest = (await repos.quests.listAll(profile.id)).single;

      final decision = await repos.decisions.create(
        profileId: profile.id,
        title: 'Aceitar oferta',
        context: 'Nova proposta',
        decision: 'Aceitar',
      );
      await repos.decisions.linkQuest(
        questId: quest.id,
        decisionId: decision.id,
      );

      final linked = await repos.decisions.watchByQuest(quest.id).first;
      expect(linked, hasLength(1));
      expect(linked.first.id, decision.id);
    });

    test('v6 to v7 adds quest_prerequisites', () async {
      final db = await openMigratedFrom(
        6,
        seed: (sqlite) {
          seedProfile(sqlite);
          seedQuestV4(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'quest-2',
          'event-1',
        ]),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final quests = await repos.quests.listAll(profile.id);
      expect(quests, hasLength(1));

      final prereq = await repos.quests.create(
        profileId: profile.id,
        title: 'Pré-requisito',
        purpose: 'Antes',
        status: QuestStatus.completed,
      );
      final main = quests.single;
      await repos.quests.linkPrerequisite(
        questId: main.id,
        prerequisiteQuestId: prereq.id,
      );

      final links = await repos.quests.listPrerequisiteLinks(profile.id);
      expect(links, hasLength(1));
    });

    test('v7 to v8 adds weekly_reviews', () async {
      final db = await openMigratedFrom(
        7,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator(['weekly-1', 'event-1']),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      await repos.weeklyReviews.save(
        profileId: profile.id,
        weekStartDate: DateTime.utc(2026, 8, 3),
        facts: 'Semana de migrations',
      );

      final review = await repos.weeklyReviews.getForWeek(
        profile.id,
        DateTime.utc(2026, 8, 3),
      );
      expect(review, isNotNull);
      expect(review!.facts, 'Semana de migrations');
    });

    test('v8 to v9 adds quest acceptance columns with backfill', () async {
      const createdAt = 1_720_000_000_000;
      final db = await openMigratedFrom(
        8,
        seed: (sqlite) {
          seedProfile(sqlite);
          seedQuestV8(
            sqlite,
            id: 'quest-active',
            status: 'active',
            createdAt: createdAt,
          );
          seedQuestV8(
            sqlite,
            id: 'quest-draft',
            status: 'draft',
            createdAt: createdAt,
          );
          seedQuestV8(
            sqlite,
            id: 'quest-paused',
            status: 'paused',
            createdAt: createdAt,
          );
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator(['event-1']),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final quests = await repos.quests.listAll(profile.id);
      final byId = {for (final q in quests) q.id.value: q};

      expect(byId['quest-active']!.acceptedAt?.millisecondsSinceEpoch, createdAt);
      expect(byId['quest-paused']!.acceptedAt?.millisecondsSinceEpoch, createdAt);
      expect(byId['quest-draft']!.acceptedAt, isNull);
      expect(byId['quest-active']!.acceptanceAssumptions, isEmpty);
    });

    test('v9 to v10 adds research tables', () async {
      final db = await openMigratedFrom(9, seed: seedProfile);
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator(['node-1', 'event-1']),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final node = await repos.research.create(
        profileId: profile.id,
        title: 'Novo nó',
        type: ResearchNodeType.knowledge,
      );

      expect(node.title, 'Novo nó');
      expect(await repos.research.listAll(profile.id), hasLength(1));
    });

    test('v10 to v11 adds sessions/evidence tables with demonstrated backfill',
        () async {
      const updatedAt = 1_720_000_000_000;
      final db = await openMigratedFrom(
        10,
        seed: (sqlite) {
          seedProfile(sqlite);
          seedResearchNodeV10(
            sqlite,
            id: 'node-demonstrated',
            status: 'demonstrated',
            demonstratedNote: 'Nota antiga',
            updatedAt: updatedAt,
          );
          seedResearchNodeV10(
            sqlite,
            id: 'node-available',
            status: 'available',
          );
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'session-1',
          'evidence-1',
          'event-1',
          'event-2',
          'event-3',
          'event-4',
        ]),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final evidence = await repos.research.listEvidence(
        const EntityId('node-demonstrated'),
      );
      expect(evidence, hasLength(1));
      expect(evidence.first.title, 'Demonstração (migrado)');
      expect(evidence.first.body, 'Nota antiga');

      expect(
        await repos.research.listEvidence(const EntityId('node-available')),
        isEmpty,
      );

      final node = (await repos.research.getById(
        const EntityId('node-available'),
      ))!;
      await repos.research.updateStatus(node, ResearchNodeStatus.inResearch);
      await repos.research.addEvidence(
        profileId: profile.id,
        nodeId: node.id,
        type: ResearchEvidenceType.note,
        title: 'Prova',
        body: 'Conteúdo',
      );
      await repos.research.logSession(
        profileId: profile.id,
        nodeId: node.id,
        startedAt: DateTime.utc(2026, 8, 6, 10),
        durationMinutes: 30,
        mode: LearningSessionMode.read,
      );

      expect(await repos.research.listSessions(node.id), hasLength(1));
      expect(await repos.research.countEvidence(node.id), 1);
    });

    test('v11 to v12 adds finance tables with default personal entity backfill',
        () async {
      final db = await openMigratedFrom(
        11,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'account-1',
          'tx-1',
          'event-1',
          'event-2',
        ]),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final entities = await repos.finance.listEntities(profile.id);
      expect(entities, hasLength(1));
      expect(entities.first.kind, FinancialEntityKind.personal);

      final account = await repos.finance.createAccount(
        profileId: profile.id,
        entityId: entities.first.id,
        institution: 'Banco',
        name: 'Corrente',
        type: FinancialAccountType.checking,
        currency: 'BRL',
      );

      await repos.finance.createTransaction(
        profileId: profile.id,
        accountId: account.id,
        occurredAt: DateTime.utc(2026, 8, 6),
        descriptionOriginal: 'Teste',
        amountMinor: 1000,
        currency: 'BRL',
        direction: TransactionDirection.inflow,
      );

      expect(await repos.finance.listAccounts(profile.id), hasLength(1));
      expect(await repos.finance.listTransactions(profile.id), hasLength(1));
    });

    test('v12 to v13 adds quest_research table', () async {
      final db = await openMigratedFrom(
        12,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'quest-1',
          'event-1',
          'research-1',
          'event-2',
        ]),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final quest = await repos.quests.create(
        profileId: profile.id,
        title: 'Missão',
        purpose: 'Propósito',
        status: QuestStatus.active,
      );
      final node = await repos.research.create(
        profileId: profile.id,
        title: 'Nó',
        type: ResearchNodeType.knowledge,
      );
      await repos.research.linkQuest(
        questId: quest.id,
        researchNodeId: node.id,
      );

      final linked = await repos.research.watchLinkedToQuest(quest.id).first;
      expect(linked, hasLength(1));
      expect(linked.first.title, 'Nó');
    });

    test('v17 to v18 adds people table', () async {
      final db = await openMigratedFrom(
        17,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'person-1',
          'event-1',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final person = await repos.people.create(
        profileId: profile.id,
        displayName: 'Ana Silva',
        preferredName: 'Aninha',
        relationshipTypes: const ['amiga'],
      );

      final listed = await repos.people.listAll(profile.id);
      expect(listed, hasLength(1));
      expect(listed.first.id, person.id);
      expect(listed.first.displayName, 'Ana Silva');
    });

    test('v18 to v19 adds category_budgets table', () async {
      final db = await openMigratedFrom(
        18,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'budget-1',
          'event-1',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final budget = await repos.finance.createBudget(
        profileId: profile.id,
        categoryId: TransactionCategoryPolicy.categoryIdFor(
          TransactionCategory.food,
        ),
        currency: 'BRL',
        limitAmountMinor: 50000,
      );

      final listed = await repos.finance.listBudgets(profile.id);
      expect(listed, hasLength(1));
      expect(listed.first.id, budget.id);
      expect(listed.first.limitAmountMinor, 50000);
    });

    test('v19 to v20 adds person_interactions table', () async {
      final db = await openMigratedFrom(
        19,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'person-1',
          'event-1',
          'ix-1',
          'event-2',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final person = await repos.people.create(
        profileId: profile.id,
        displayName: 'Ana',
      );
      final ix = await repos.people.logInteraction(
        profileId: profile.id,
        person: person,
        kind: InteractionKind.meeting,
        occurredAt: DateTime.utc(2026, 8, 6, 15),
        note: 'café',
      );

      final listed = await repos.people.listAllInteractions(profile.id);
      expect(listed, hasLength(1));
      expect(listed.first.id, ix.id);
      final refreshed = (await repos.people.listAll(profile.id)).first;
      expect(refreshed.lastInteractionAt, DateTime.utc(2026, 8, 6, 15));
    });

    test('v20 to v21 adds trips table', () async {
      final db = await openMigratedFrom(
        20,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'trip-1',
          'event-1',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final trip = await repos.trips.create(
        profileId: profile.id,
        title: 'Férias SP',
        destinations: ['São Paulo'],
        purpose: 'descanso',
      );

      final listed = await repos.trips.listAll(profile.id);
      expect(listed, hasLength(1));
      expect(listed.first.id, trip.id);
      expect(listed.first.title, 'Férias SP');
      expect(listed.first.status, TripStatus.planned);
    });

    test('v21 to v22 adds organizations table', () async {
      final db = await openMigratedFrom(
        21,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'org-1',
          'event-1',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final org = await repos.organizations.create(
        profileId: profile.id,
        name: 'Acme Ltd',
        kind: OrganizationKind.company,
        notes: 'cliente',
      );

      final listed = await repos.organizations.listAll(profile.id);
      expect(listed, hasLength(1));
      expect(listed.first.id, org.id);
      expect(listed.first.name, 'Acme Ltd');
      expect(listed.first.kind, OrganizationKind.company);
    });

    test('v27 to v28 adds context_zones table', () async {
      final db = await openMigratedFrom(
        27,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'zone-1',
          'event-1',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final created = await repos.contextZones.create(
        profileId: profile.id,
        name: 'Avião',
        capabilities: const ['read', 'notes'],
        connectivity: ZoneConnectivity.offline,
      );
      expect(created.name, 'Avião');
      expect(created.connectivity, ZoneConnectivity.offline);
      final listed = await repos.contextZones.listAll(profile.id);
      expect(listed, hasLength(1));
    });

    test('v32 to v33 adds trip_inventory packing table', () async {
      final db = await openMigratedFrom(
        32,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'trip-1',
          'event-1',
          'device-1',
          'event-2',
          'op-1',
          'event-3',
          'inv-1',
          'event-4',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final trip = await repos.trips.create(
        profileId: profile.id,
        title: 'Lisboa',
      );
      final item = await repos.inventory.create(
        profileId: profile.id,
        name: 'Mochila',
        category: InventoryCategory.clothing,
      );
      await repos.trips.linkInventoryItem(
        tripId: trip.id,
        inventoryItemId: item.id,
      );
      final linked = await repos.trips.watchLinkedInventory(trip.id).first;
      expect(linked, hasLength(1));
      expect(linked.single.name, 'Mochila');
      final listed = await repos.trips.listInventoryLinks(profile.id);
      expect(listed, hasLength(1));
    });

    test('v33 to v34 adds flashcard and knowledge map tables', () async {
      final db = await openMigratedFrom(
        33,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'area-1',
          'event-1',
          'deck-1',
          'event-2',
          'card-1',
          'event-3',
          'log-1',
          'event-4',
        ]),
        clock: () => DateTime.utc(2026, 8, 17, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final area = await repos.flashcards.createArea(
        profileId: profile.id,
        title: 'Linguagens',
      );
      final deck = await repos.flashcards.createDeck(
        profileId: profile.id,
        title: 'Vocabulário',
        areaId: area.id,
      );
      final cards = await repos.flashcards.createCard(
        profileId: profile.id,
        deckId: deck.id,
        areaId: area.id,
        front: 'Bonjour',
        back: 'Olá',
      );
      expect(cards, hasLength(1));
      final listed = await repos.flashcards.listCards(profile.id);
      expect(listed.single.front, 'Bonjour');
      final srs = await repos.flashcards.listSrs(profile.id);
      expect(srs, hasLength(1));
      expect(srs.single.status, FlashcardSrsStatus.newCard);
    });

    test('v34 to v35 adds schedule mode, placements and research links', () async {
      final db = await openMigratedFrom(
        34,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'area-1',
          'event-1',
          'area-2',
          'event-2',
          'deck-1',
          'event-3',
          'card-1',
          'event-4',
          'event-5',
          'log-1',
          'event-6',
        ]),
        clock: () => DateTime.utc(2026, 8, 17, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final music = await repos.flashcards.createArea(
        profileId: profile.id,
        title: 'Música',
      );
      final brazil = await repos.flashcards.createArea(
        profileId: profile.id,
        title: 'Brasil',
      );
      await repos.flashcards.addPlacement(
        areaId: music.id,
        parentAreaId: brazil.id,
      );
      final deck = await repos.flashcards.createDeck(
        profileId: profile.id,
        title: 'Teoria',
        areaId: music.id,
      );
      final cards = await repos.flashcards.createCard(
        profileId: profile.id,
        deckId: deck.id,
        areaId: music.id,
        front: 'Dominante',
        back: 'V',
        scheduleMode: FlashcardScheduleMode.unscheduled,
      );
      expect(cards.single.scheduleMode, FlashcardScheduleMode.unscheduled);
      expect(await repos.flashcards.listSrs(profile.id), isEmpty);
      final placements = await repos.flashcards.listPlacements(profile.id);
      expect(placements, hasLength(1));
    });

    test('v31 to v32 adds health_appointments table', () async {
      final db = await openMigratedFrom(
        31,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'appt-1',
          'event-1',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final created = await repos.health.createAppointment(
        profileId: profile.id,
        title: 'Check-up anual',
        scheduledAt: DateTime.utc(2026, 9, 1, 10),
        locationLabel: 'Clínica',
      );
      expect(created.title, 'Check-up anual');
      expect(created.status, HealthAppointmentStatus.scheduled);
      final listed = await repos.health.listAppointments(profile.id);
      expect(listed, hasLength(1));
      expect(listed.single.locationLabel, 'Clínica');
    });

    test('v30 to v31 adds commitments.linked_quest_id', () async {
      final db = await openMigratedFrom(
        30,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'quest-1',
          'event-q',
          'cmt-1',
          'event-c',
          'device-1',
          'event-d',
          'op-1',
          'event-o',
          'event-save',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final quest = await repos.quests.create(
        profileId: profile.id,
        title: 'Missão link',
        purpose: 'Testar vínculo',
      );
      final created = await repos.commitments.create(
        profileId: profile.id,
        description: 'Entregar relatório',
        madeToLabel: 'chefe',
        linkedQuestId: quest.id,
      );
      expect(created.linkedQuestId, quest.id);
      final listed = await repos.commitments.listAll(profile.id);
      expect(listed.single.linkedQuestId, quest.id);

      final cleared = await repos.commitments.save(
        created.copyWith(clearLinkedQuestId: true),
      );
      expect(cleared.linkedQuestId, isNull);
    });

    test('v29 to v30 adds zone_trips link table', () async {
      final db = await openMigratedFrom(
        29,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'zone-1',
          'event-1',
          'device-1',
          'event-2',
          'op-1',
          'event-3',
          'trip-1',
          'event-4',
          'op-2',
          'event-5',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
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
      final linked = await repos.contextZones.watchLinkedTrips(zone.id).first;
      expect(linked, hasLength(1));
      expect(linked.single.title, 'Lisboa');
      final links = await repos.contextZones.listTripLinks(profile.id);
      expect(links, hasLength(1));
    });

    test('v28 to v29 adds integration ICS tables', () async {
      final db = await openMigratedFrom(
        28,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'consent-1',
          'event-1',
          'cal-1',
          'event-2',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final consent = await repos.integrations.setConsentEnabled(
        profileId: profile.id,
        kind: IntegrationKind.calendarIcs,
        enabled: true,
      );
      expect(consent.enabled, isTrue);
      final imported = await repos.integrations.importCalendarPreviews(
        profileId: profile.id,
        previews: [
          IcsEventPreview(
            uid: 'u1',
            summary: 'Standup',
            startAt: DateTime.utc(2026, 8, 7, 14),
            endAt: DateTime.utc(2026, 8, 7, 15),
          ),
        ],
      );
      expect(imported, hasLength(1));
      expect(imported.first.sourceType, SourceType.integration);
      final listed = await repos.integrations.listCalendarEvents(profile.id);
      expect(listed, hasLength(1));
    });

    test('v26 to v27 adds sync outbox tables', () async {
      final db = await openMigratedFrom(
        26,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'device-1',
          'event-1',
          'op-1',
          'event-2',
          'event-3',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final device = await repos.sync.ensureLocalDevice();
      expect(device.label, 'Este dispositivo');
      final op = await repos.sync.enqueue(
        entityType: 'commitment',
        entityId: const EntityId('cmt-1'),
        payloadJson: '{"id":"cmt-1"}',
      );
      expect(op.status, SyncOpStatus.pending);
      final processed = await repos.sync.processLocalNoop();
      expect(processed, 1);
      final pending = await repos.sync.listPending();
      expect(pending, isEmpty);
    });

    test('v25 to v26 adds commitments table', () async {
      final db = await openMigratedFrom(
        25,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'cmt-1',
          'event-1',
          'device-1',
          'event-2',
          'op-1',
          'event-3',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final created = await repos.commitments.create(
        profileId: profile.id,
        description: 'Ligar amanhã',
        madeToLabel: 'Ana',
      );
      expect(created.description, 'Ligar amanhã');
      expect(created.status, CommitmentStatus.open);

      final listed = await repos.commitments.listAll(profile.id);
      expect(listed, hasLength(1));
      expect(listed.first.madeToLabel, 'Ana');
      final pending = await repos.sync.listPending();
      expect(pending, hasLength(1));
      expect(pending.first.entityType, 'commitment');
    });

    test('v24 to v25 adds quest_inventory table', () async {
      final db = await openMigratedFrom(
        24,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'item-1',
          'event-1',
          'quest-1',
          'event-2',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final item = await repos.inventory.create(
        profileId: profile.id,
        name: 'Notebook',
        category: InventoryCategory.electronics,
      );
      final quest = await repos.quests.create(
        profileId: profile.id,
        title: 'Setup',
        purpose: 'Prep',
        status: QuestStatus.active,
      );
      await repos.inventory.linkQuest(
        questId: quest.id,
        inventoryItemId: item.id,
      );

      final linked = await repos.inventory.watchLinkedQuests(item.id).first;
      expect(linked, hasLength(1));
      expect(linked.first.title, 'Setup');
    });

    test('v23 to v24 adds home_maintenance_tasks table', () async {
      final db = await openMigratedFrom(
        23,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'hm-1',
          'event-1',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final task = await repos.homeMaintenance.create(
        profileId: profile.id,
        title: 'Filtro ar',
        systemOrItem: 'HVAC',
        cadenceDays: 90,
      );

      final listed = await repos.homeMaintenance.listAll(profile.id);
      expect(listed, hasLength(1));
      expect(listed.first.id, task.id);
      expect(listed.first.title, 'Filtro ar');
    });

    test('v22 to v23 adds person_organizations table', () async {
      final db = await openMigratedFrom(
        22,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'person-1',
          'event-1',
          'org-1',
          'event-2',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final person = await repos.people.create(
        profileId: profile.id,
        displayName: 'Ana',
      );
      final org = await repos.organizations.create(
        profileId: profile.id,
        name: 'Acme Ltd',
        kind: OrganizationKind.company,
      );
      await repos.organizations.linkPerson(
        personId: person.id,
        organizationId: org.id,
        role: 'membro',
      );

      final links = await repos.organizations.listMemberships(profile.id);
      expect(links, hasLength(1));
      expect(links.first.role, 'membro');

      final members = await repos.organizations.watchMembers(org.id).first;
      expect(members.single.displayName, 'Ana');
    });

    test('v16 to v17 adds inventory_items table', () async {
      final db = await openMigratedFrom(
        16,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'inv-1',
          'event-1',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final item = await repos.inventory.create(
        profileId: profile.id,
        name: 'Notebook',
        category: InventoryCategory.electronics,
        locationLabel: 'mesa',
      );

      final listed = await repos.inventory.listAll(profile.id);
      expect(listed, hasLength(1));
      expect(listed.first.id, item.id);
      expect(listed.first.name, 'Notebook');
      expect(listed.first.category, InventoryCategory.electronics);
    });

    test('v15 to v16 adds financial_accounts.is_archived', () async {
      final db = await openMigratedFrom(
        15,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'entity-1',
          'account-1',
          'event-1',
          'event-2',
          'event-3',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      await repos.finance.seedDefaults(profile.id);
      final entity = (await repos.finance.listEntities(profile.id)).first;
      final account = await repos.finance.createAccount(
        profileId: profile.id,
        entityId: entity.id,
        institution: 'Banco',
        name: 'Antiga',
        type: FinancialAccountType.checking,
        currency: 'BRL',
      );
      expect(account.isArchived, isFalse);

      final archived = await repos.finance.archiveAccount(account);
      expect(archived.isArchived, isTrue);
      expect(archived.includeInNetWorth, isFalse);
    });

    test('v14 to v15 adds symptom_entries table', () async {
      final db = await openMigratedFrom(
        14,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'health-1',
          'event-1',
          'sym-1',
          'event-2',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final condition = await repos.health.create(
        profileId: profile.id,
        title: 'Dor',
        type: HealthConditionType.symptom,
      );
      final entry = await repos.health.logSymptomEntry(
        profileId: profile.id,
        conditionId: condition.id,
        intensity: 3,
        note: 'tarde',
      );

      final listed = await repos.health.listAllSymptomEntries(profile.id);
      expect(listed, hasLength(1));
      expect(listed.first.id, entry.id);
      expect(listed.first.intensity, 3);
    });

    test('v13 to v14 adds health_conditions table', () async {
      final db = await openMigratedFrom(
        13,
        seed: (sqlite) {
          seedProfile(sqlite);
        },
      );
      addTearDown(() async {
        await db.close();
      });

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'health-1',
          'event-1',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = (await repos.profiles.getActive())!;
      final condition = await repos.health.create(
        profileId: profile.id,
        title: 'Dor',
        type: HealthConditionType.symptom,
        severityUserReported: 2,
      );

      final listed = await repos.health.listAll(profile.id);
      expect(listed, hasLength(1));
      expect(listed.first.id, condition.id);
      expect(listed.first.title, 'Dor');
    });
  });

  group('FinanceRepository transaction edit/delete', () {
    test('save and delete persist categoryId', () async {
      final db = ColonyDatabase.inMemory();
      addTearDown(db.close);

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'profile-1',
          'entity-1',
          'account-1',
          'tx-1',
          'event-1',
          'event-2',
          'event-3',
          'event-4',
        ]),
        clock: () => DateTime.utc(2026, 8, 6, 12),
      );

      final profile = await repos.profiles.create(
        colonyName: 'Test',
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
        name: 'Corrente',
        type: FinancialAccountType.checking,
        currency: 'BRL',
      );

      final created = await repos.finance.createTransaction(
        profileId: profile.id,
        accountId: account.id,
        occurredAt: DateTime.utc(2026, 8, 6),
        descriptionOriginal: 'Mercado',
        amountMinor: 5000,
        currency: 'BRL',
        direction: TransactionDirection.outflow,
        categoryId: TransactionCategoryPolicy.categoryIdFor(
          TransactionCategory.food,
        ),
      );
      expect(created.categoryId?.value, 'cat_food');

      final updated = await repos.finance.saveTransaction(
        created.copyWith(
          descriptionOriginal: 'Feira',
          categoryId: TransactionCategoryPolicy.categoryIdFor(
            TransactionCategory.shopping,
          ),
          updatedAt: DateTime.utc(2026, 8, 7),
        ),
      );
      expect(updated.descriptionOriginal, 'Feira');
      expect(updated.categoryId?.value, 'cat_shopping');

      await repos.finance.deleteTransaction(created.id);
      expect(await repos.finance.listTransactions(profile.id), isEmpty);
    });
  });

  group('FinanceRepository CSV import dedup', () {
    test('importCsvPreview skips existing fingerprints', () async {
      final db = ColonyDatabase.inMemory();
      addTearDown(db.close);

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'profile-1',
          'entity-1',
          'account-1',
          'tx-1',
          'event-1',
          'event-2',
          'tx-2',
          'event-3',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = await repos.profiles.create(
        colonyName: 'Test',
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
        name: 'Corrente',
        type: FinancialAccountType.checking,
        currency: 'BRL',
      );

      final first = await repos.finance.createTransaction(
        profileId: profile.id,
        accountId: account.id,
        occurredAt: DateTime.utc(2026, 8, 6),
        descriptionOriginal: 'Mercado',
        amountMinor: 5000,
        currency: 'BRL',
        direction: TransactionDirection.outflow,
      );

      final csv = FinanceCsvCodec.encodeTransactions([
        first,
        LedgerTransaction.create(
          id: EntityId('tx-new'),
          profileId: profile.id,
          accountId: account.id,
          occurredAt: DateTime.utc(2026, 8, 7),
          descriptionOriginal: 'Padaria',
          amountMinor: 1200,
          currency: 'BRL',
          direction: TransactionDirection.outflow,
          createdAt: DateTime.utc(2026, 8, 7),
        ),
      ]);
      final preview = FinanceCsvCodec.parsePreview(csv);
      final plan = await repos.finance.importCsvPreview(
        profileId: profile.id,
        preview: preview,
      );

      expect(plan.importCount, 1);
      expect(plan.duplicateCount, 1);
      final listed = await repos.finance.listTransactions(profile.id);
      expect(listed, hasLength(2));
      expect(listed.map((t) => t.descriptionOriginal), contains('Padaria'));
    });

    test('planCsvImport does not write; apply preserves fingerprint', () async {
      final db = ColonyDatabase.inMemory();
      addTearDown(db.close);

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'profile-1',
          'entity-1',
          'account-1',
          'event-acc',
          'tx-1',
          'event-tx',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = await repos.profiles.create(
        colonyName: 'Test',
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
        name: 'Corrente',
        type: FinancialAccountType.checking,
        currency: 'BRL',
      );

      const externalFp = 'bank-ext-fp-999';
      final preview = [
        FinanceCsvPreviewRow(
          accountId: account.id.value,
          occurredAt: DateTime.utc(2026, 8, 7),
          descriptionOriginal: 'PIX loja',
          amountMinor: 3300,
          currency: 'BRL',
          direction: TransactionDirection.outflow,
          fingerprint: externalFp,
        ),
      ];

      final planned = await repos.finance.planCsvImport(
        profileId: profile.id,
        preview: preview,
      );
      expect(planned.importCount, 1);
      expect(await repos.finance.listTransactions(profile.id), isEmpty);

      final applied = await repos.finance.applyCsvImport(
        profileId: profile.id,
        plan: planned,
      );
      expect(applied.importCount, 1);
      final listed = await repos.finance.listTransactions(profile.id);
      expect(listed, hasLength(1));
      expect(listed.single.fingerprint, externalFp);

      final again = await repos.finance.planCsvImport(
        profileId: profile.id,
        preview: preview,
      );
      expect(again.importCount, 0);
      expect(again.duplicateCount, 1);
    });

    test('planCsvImport accountOverride remaps destination account', () async {
      final db = ColonyDatabase.inMemory();
      addTearDown(db.close);

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([
          'profile-1',
          'entity-1',
          'account-1',
          'event-acc-1',
          'account-2',
          'event-acc-2',
          'tx-1',
          'event-tx',
        ]),
        clock: () => DateTime.utc(2026, 8, 7, 12),
      );

      final profile = await repos.profiles.create(
        colonyName: 'Test',
        displayName: 'Caio',
        timezone: 'UTC',
        locale: 'pt_BR',
        baseCurrency: 'BRL',
      );
      await repos.finance.seedDefaults(profile.id);
      final entity = (await repos.finance.listEntities(profile.id)).first;
      final accountA = await repos.finance.createAccount(
        profileId: profile.id,
        entityId: entity.id,
        institution: 'Banco',
        name: 'A',
        type: FinancialAccountType.checking,
        currency: 'BRL',
      );
      final accountB = await repos.finance.createAccount(
        profileId: profile.id,
        entityId: entity.id,
        institution: 'Banco',
        name: 'B',
        type: FinancialAccountType.savings,
        currency: 'BRL',
      );

      final preview = [
        FinanceCsvPreviewRow(
          accountId: accountA.id.value,
          occurredAt: DateTime.utc(2026, 8, 7),
          descriptionOriginal: 'Remap',
          amountMinor: 100,
          currency: 'BRL',
          direction: TransactionDirection.outflow,
          fingerprint: 'fp-remap-1',
        ),
      ];
      final plan = await repos.finance.planCsvImport(
        profileId: profile.id,
        preview: preview,
        accountOverride: accountB.id,
      );
      await repos.finance.applyCsvImport(profileId: profile.id, plan: plan);
      final listed = await repos.finance.listTransactions(profile.id);
      expect(listed.single.accountId, accountB.id);
      expect(listed.single.fingerprint, 'fp-remap-1');
    });
  });
}
