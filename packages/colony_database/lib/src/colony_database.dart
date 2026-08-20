import 'dart:convert';
import 'dart:io';

import 'package:colony_domain/colony_domain.dart' as domain;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/colony_tables.dart';

part 'colony_database.g.dart';

@DriftDatabase(tables: [
  Profiles,
  DomainEvents,
  Tasks,
  Preferences,
  NeedDefinitions,
  NeedReadings,
  CheckIns,
  MoodFactors,
  DailyReviews,
  WeeklyReviews,
  WorkPriorities,
  Bills,
  ScheduleBlocks,
  Quests,
  Projects,
  QuestProjects,
  DecisionRecords,
  QuestDecisions,
  QuestPrerequisites,
  ResearchNodes,
  ResearchPrerequisites,
  QuestResearch,
  LearningSessions,
  ResearchEvidenceItems,
  FinancialEntities,
  FinancialAccounts,
  LedgerTransactions,
  HealthConditions,
  SymptomEntries,
  HealthAppointments,
  InventoryItems,
  People,
  CategoryBudgets,
  PersonInteractions,
  Trips,
  Organizations,
  PersonOrganizations,
  HomeMaintenanceTasks,
  QuestInventory,
  Commitments,
  DeviceIdentities,
  SyncOperations,
  ContextZones,
  ZoneTrips,
  TripInventory,
  IntegrationConsents,
  ExternalCalendarEvents,
  KnowledgeAreas,
  FlashcardDecks,
  Flashcards,
  FlashcardSrs,
  FlashcardReviewLogs,
  KnowledgeAreaPlacements,
  ResearchKnowledgeLinks,
  FlashcardTags,
  FlashcardTagLinks,
])
class ColonyDatabase extends _$ColonyDatabase {
  ColonyDatabase(super.e);

  @override
  int get schemaVersion => 37;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(needDefinitions);
            await m.createTable(needReadings);
            await m.createTable(checkIns);
            await m.createTable(moodFactors);
            await m.createTable(dailyReviews);
          }
          if (from < 3) {
            await m.createTable(workPriorities);
            await m.createTable(bills);
            await m.createTable(scheduleBlocks);
          }
          if (from < 4) {
            await m.createTable(quests);
            await m.addColumn(tasks, tasks.questId);
          }
          if (from < 5) {
            await m.createTable(projects);
            await m.createTable(questProjects);
            if (from >= 4) {
              await m.addColumn(quests, quests.pauseReason);
            }
          }
          if (from < 6) {
            await m.createTable(decisionRecords);
            await m.createTable(questDecisions);
          }
          if (from < 7) {
            await m.createTable(questPrerequisites);
          }
          if (from < 8) {
            await m.createTable(weeklyReviews);
          }
          if (from < 9 && from >= 4) {
            await m.addColumn(quests, quests.acceptedAt);
            await m.addColumn(quests, quests.acceptanceDeadline);
            await m.addColumn(quests, quests.acceptanceAssumptionsJson);
            await _backfillQuestAcceptance(m);
          }
          if (from < 10) {
            await m.createTable(researchNodes);
            await m.createTable(researchPrerequisites);
          }
          if (from < 11) {
            await m.createTable(learningSessions);
            await m.createTable(researchEvidenceItems);
            await _backfillDemonstratedEvidence(m);
          }
          if (from < 12) {
            await m.createTable(financialEntities);
            await m.createTable(financialAccounts);
            await m.createTable(ledgerTransactions);
            await _backfillDefaultFinancialEntity(m);
          }
          if (from < 13) {
            await m.createTable(questResearch);
          }
          if (from < 14) {
            await m.createTable(healthConditions);
          }
          if (from < 15) {
            await m.createTable(symptomEntries);
          }
          // Table created at v12+ already has current columns when from < 12.
          if (from >= 12 && from < 16) {
            await m.addColumn(financialAccounts, financialAccounts.isArchived);
          }
          if (from < 17) {
            await m.createTable(inventoryItems);
          }
          if (from < 18) {
            await m.createTable(people);
          }
          if (from < 19) {
            await m.createTable(categoryBudgets);
          }
          if (from < 20) {
            await m.createTable(personInteractions);
          }
          if (from < 21) {
            await m.createTable(trips);
          }
          if (from < 22) {
            await m.createTable(organizations);
          }
          if (from < 23) {
            await m.createTable(personOrganizations);
          }
          if (from < 24) {
            await m.createTable(homeMaintenanceTasks);
          }
          if (from < 25) {
            await m.createTable(questInventory);
          }
          if (from < 26) {
            // Current table def already includes linked_quest_id (v31).
            await m.createTable(commitments);
          } else if (from < 31) {
            await m.addColumn(commitments, commitments.linkedQuestId);
          }
          if (from < 27) {
            await m.createTable(deviceIdentities);
            await m.createTable(syncOperations);
          }
          if (from < 28) {
            await m.createTable(contextZones);
          }
          if (from < 29) {
            await m.createTable(integrationConsents);
            await m.createTable(externalCalendarEvents);
          }
          if (from < 30) {
            await m.createTable(zoneTrips);
          }
          if (from < 32) {
            await m.createTable(healthAppointments);
          }
          if (from < 33) {
            await m.createTable(tripInventory);
          }
          if (from < 34) {
            await m.createTable(knowledgeAreas);
            await m.createTable(flashcardDecks);
            await m.createTable(flashcards);
            await m.createTable(flashcardSrs);
            await m.createTable(flashcardReviewLogs);
          }
          if (from >= 34 && from < 35) {
            await m.addColumn(flashcards, flashcards.scheduleMode);
            await m.addColumn(flashcardReviewLogs, flashcardReviewLogs.reviewKind);
          }
          if (from < 35) {
            await m.createTable(knowledgeAreaPlacements);
            await m.createTable(researchKnowledgeLinks);
          }
          if (from >= 34 && from < 36) {
            await m.addColumn(flashcards, flashcards.priority);
          }
          if (from < 37) {
            await m.createTable(flashcardTags);
            await m.createTable(flashcardTagLinks);
            await _backfillFlashcardTags(m);
          }
        },
      );

  static Future<void> _backfillFlashcardTags(Migrator m) async {
    final rows = await m.database.customSelect('''
      SELECT id, profile_id, tags_json FROM flashcards
    ''').get();
    final tagIdByKey = <String, String>{};
    var created = 0;
    for (final row in rows) {
      final cardId = row.read<String>('id');
      final profileId = row.read<String>('profile_id');
      final raw = row.read<String>('tags_json');
      List<dynamic> titles;
      try {
        titles = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        continue;
      }
      for (final item in titles) {
        final title = item.toString().trim();
        if (title.isEmpty) continue;
        final key = '$profileId\u0001${title.toLowerCase()}';
        var tagId = tagIdByKey[key];
        if (tagId == null) {
          created += 1;
          tagId = 'tag-backfill-$profileId-$created';
          tagIdByKey[key] = tagId;
          await m.database.customStatement(
            '''
            INSERT INTO flashcard_tags (
              id, profile_id, parent_id, title, sort_order, created_at
            ) VALUES (?, ?, NULL, ?, 0, ?)
            ''',
            [tagId, profileId, title, 1_720_000_000_000],
          );
        }
        await m.database.customStatement(
          '''
          INSERT OR IGNORE INTO flashcard_tag_links (card_id, tag_id, linked_at)
          VALUES (?, ?, ?)
          ''',
          [cardId, tagId, 1_720_000_000_000],
        );
      }
    }
  }

  static Future<void> _backfillQuestAcceptance(Migrator m) async {
    await m.database.customStatement('''
      UPDATE quests
      SET accepted_at = created_at
      WHERE status IN ('active', 'paused', 'completed')
        AND accepted_at IS NULL
    ''');
  }

  static Future<void> _backfillDemonstratedEvidence(Migrator m) async {
    final rows = await m.database.customSelect('''
      SELECT id, profile_id, demonstrated_note, updated_at
      FROM research_nodes
      WHERE status = 'demonstrated'
    ''').get();

    for (final row in rows) {
      final nodeId = row.read<String>('id');
      final profileId = row.read<String>('profile_id');
      final note = row.read<String?>('demonstrated_note');
      final updatedAt = row.read<int>('updated_at');
      final evidenceId = 'migration-evidence-$nodeId';
      final body = (note != null && note.trim().isNotEmpty)
          ? note.trim()
          : 'Registro anterior à exigência de evidência';

      await m.database.customStatement('''
        INSERT INTO research_evidence (
          id, profile_id, node_id, session_id, type, title, body, created_at
        )
        SELECT ?, ?, ?, NULL, 'summary', 'Demonstração (migrado)', ?, ?
        WHERE NOT EXISTS (
          SELECT 1 FROM research_evidence WHERE node_id = ?
        )
      ''', [evidenceId, profileId, nodeId, body, updatedAt, nodeId]);
    }
  }

  static Future<void> _backfillDefaultFinancialEntity(Migrator m) async {
    final profiles = await m.database.customSelect('''
      SELECT id, display_name FROM profiles
    ''').get();

    for (final row in profiles) {
      final profileId = row.read<String>('id');
      final displayName = row.read<String>('display_name');
      final entityId = 'migration-entity-$profileId';
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final name = displayName.trim().isEmpty ? 'Pessoal' : displayName.trim();

      await m.database.customStatement('''
        INSERT INTO financial_entities (id, profile_id, name, kind, created_at, updated_at)
        SELECT ?, ?, ?, 'personal', ?, ?
        WHERE NOT EXISTS (
          SELECT 1 FROM financial_entities WHERE profile_id = ?
        )
      ''', [entityId, profileId, name, now, now, profileId]);
    }
  }

  static Future<ColonyDatabase> open({String? fileName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, fileName ?? 'colony.db'));
    return ColonyDatabase(NativeDatabase(file));
  }

  static ColonyDatabase inMemory() {
    return ColonyDatabase(NativeDatabase.memory());
  }
}

class ColonyMappers {
  static domain.ColonyProfile toProfile(Profile row) {
    return domain.ColonyProfile(
      id: domain.EntityId(row.id),
      colonyName: row.colonyName,
      displayName: row.displayName,
      timezone: row.timezone,
      locale: row.locale,
      baseCurrency: row.baseCurrency,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      version: row.version,
    );
  }

  static ProfilesCompanion fromProfile(domain.ColonyProfile profile) {
    return ProfilesCompanion.insert(
      id: profile.id.value,
      colonyName: profile.colonyName,
      displayName: profile.displayName,
      timezone: profile.timezone,
      locale: profile.locale,
      baseCurrency: profile.baseCurrency,
      createdAt: profile.createdAt.millisecondsSinceEpoch,
      updatedAt: profile.updatedAt.millisecondsSinceEpoch,
      deletedAt: Value(profile.deletedAt?.millisecondsSinceEpoch),
      version: Value(profile.version),
    );
  }

  static domain.ColonyTask toTask(Task row) {
    return domain.ColonyTask(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      description: row.description,
      status: domain.TaskStatus.values.byName(row.status),
      sourceType: domain.SourceType.values.byName(row.sourceType),
      dueAt: row.dueAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.dueAt!, isUtc: true),
      scheduledStart: row.scheduledStart == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.scheduledStart!, isUtc: true),
      estimatedMinutes: row.estimatedMinutes,
      actualMinutes: row.actualMinutes,
      energyRequirement: domain.EnergyRequirement.values.byName(row.energyRequirement),
      blockedReason: row.blockedReason,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      completedAt: row.completedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.completedAt!, isUtc: true),
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
      version: row.version,
      questId: row.questId == null ? null : domain.EntityId(row.questId!),
    );
  }

  static TasksCompanion fromTask(domain.ColonyTask task) {
    return TasksCompanion.insert(
      id: task.id.value,
      profileId: task.profileId.value,
      title: task.title,
      description: Value(task.description),
      status: task.status.name,
      sourceType: task.sourceType.name,
      dueAt: Value(task.dueAt?.millisecondsSinceEpoch),
      scheduledStart: Value(task.scheduledStart?.millisecondsSinceEpoch),
      estimatedMinutes: Value(task.estimatedMinutes),
      actualMinutes: Value(task.actualMinutes),
      energyRequirement: Value(task.energyRequirement.name),
      blockedReason: Value(task.blockedReason),
      questId: Value(task.questId?.value),
      createdAt: task.createdAt.millisecondsSinceEpoch,
      updatedAt: task.updatedAt.millisecondsSinceEpoch,
      completedAt: Value(task.completedAt?.millisecondsSinceEpoch),
      deletedAt: Value(task.deletedAt?.millisecondsSinceEpoch),
      version: Value(task.version),
    );
  }

  static domain.DomainEvent toEvent(DomainEvent row) {
    return domain.DomainEvent(
      id: domain.EntityId(row.id),
      aggregateType: domain.AggregateType.values.byName(row.aggregateType),
      aggregateId: domain.EntityId(row.aggregateId),
      eventType: domain.EventType.values.byName(row.eventType),
      occurredAt:
          DateTime.fromMillisecondsSinceEpoch(row.occurredAt, isUtc: true),
      recordedAt:
          DateTime.fromMillisecondsSinceEpoch(row.recordedAt, isUtc: true),
      sourceType: domain.SourceType.values.byName(row.sourceType),
      payloadVersion: row.payloadVersion,
      payload: jsonDecode(row.payloadJson) as Map<String, Object?>,
      privacyClass: domain.PrivacyClass.values.byName(row.privacyClass),
      correlationId: row.correlationId,
      causationId: row.causationId,
    );
  }

  static DomainEventsCompanion fromEvent(domain.DomainEvent event) {
    return DomainEventsCompanion.insert(
      id: event.id.value,
      aggregateType: event.aggregateType.name,
      aggregateId: event.aggregateId.value,
      eventType: event.eventType.name,
      occurredAt: event.occurredAt.millisecondsSinceEpoch,
      recordedAt: event.recordedAt.millisecondsSinceEpoch,
      sourceType: event.sourceType.name,
      payloadVersion: event.payloadVersion,
      payloadJson: event.payloadJson,
      correlationId: Value(event.correlationId),
      causationId: Value(event.causationId),
      privacyClass: event.privacyClass.name,
    );
  }

  static domain.AppPreferences toPreferences(Preference row) {
    final sectors = (jsonDecode(row.sectorsEnabledJson) as List<dynamic>)
        .cast<String>();
    return domain.AppPreferences(
      densityMode: domain.DensityMode.values.byName(row.densityMode),
      themeMode: domain.ThemeModePreference.values.byName(row.themeMode),
      weekStartsOnMonday: row.weekStartsOnMonday,
      use24HourFormat: row.use24HourFormat,
      sectorsEnabled: sectors,
      onboardingCompleted: row.onboardingCompleted,
      biometricLockEnabled: row.biometricLockEnabled,
      sessionTimeoutMinutes: row.sessionTimeoutMinutes,
    );
  }

  static PreferencesCompanion fromPreferences(domain.AppPreferences prefs) {
    return PreferencesCompanion.insert(
      densityMode: prefs.densityMode.name,
      themeMode: prefs.themeMode.name,
      weekStartsOnMonday: prefs.weekStartsOnMonday,
      use24HourFormat: prefs.use24HourFormat,
      sectorsEnabledJson: jsonEncode(prefs.sectorsEnabled),
      onboardingCompleted: prefs.onboardingCompleted,
      biometricLockEnabled: prefs.biometricLockEnabled,
      sessionTimeoutMinutes: prefs.sessionTimeoutMinutes,
    );
  }

  static domain.NeedDefinition toNeedDefinition(NeedDefinition row) {
    return domain.NeedDefinition(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      slug: row.slug,
      calculationMode: domain.CalculationMode.values.byName(row.calculationMode),
      preferredMin: row.preferredMin,
      preferredMax: row.preferredMax,
      validitySeconds: row.validitySeconds,
      privacyClass: domain.NeedPrivacyClass.values.byName(row.privacyClass),
      isEnabled: row.isEnabled,
      isSubjective: row.isSubjective,
      sortOrder: row.sortOrder,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static NeedDefinitionsCompanion fromNeedDefinition(domain.NeedDefinition def) {
    return NeedDefinitionsCompanion.insert(
      id: def.id.value,
      profileId: def.profileId.value,
      name: def.name,
      slug: def.slug,
      calculationMode: def.calculationMode.name,
      preferredMin: Value(def.preferredMin),
      preferredMax: Value(def.preferredMax),
      validitySeconds: Value(def.validitySeconds),
      privacyClass: def.privacyClass.name,
      isEnabled: Value(def.isEnabled),
      isSubjective: Value(def.isSubjective),
      sortOrder: Value(def.sortOrder),
      createdAt: def.createdAt.millisecondsSinceEpoch,
      updatedAt: def.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.NeedReading toNeedReading(NeedReading row) {
    return domain.NeedReading(
      id: domain.EntityId(row.id),
      needId: domain.EntityId(row.needId),
      observedAt: DateTime.fromMillisecondsSinceEpoch(row.observedAt, isUtc: true),
      normalizedValue: row.normalizedValue,
      rawValue: row.rawValue,
      rawUnit: row.rawUnit,
      sourceType: domain.SourceType.values.byName(row.sourceType),
      sourceId: row.sourceId,
      confidence: row.confidence,
      note: row.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }

  static NeedReadingsCompanion fromNeedReading(domain.NeedReading reading) {
    return NeedReadingsCompanion.insert(
      id: reading.id.value,
      needId: reading.needId.value,
      observedAt: reading.observedAt.millisecondsSinceEpoch,
      normalizedValue: Value(reading.normalizedValue),
      rawValue: Value(reading.rawValue),
      rawUnit: Value(reading.rawUnit),
      sourceType: reading.sourceType.name,
      sourceId: Value(reading.sourceId),
      confidence: Value(reading.confidence),
      note: Value(reading.note),
      createdAt: reading.createdAt.millisecondsSinceEpoch,
    );
  }

  static domain.CheckIn toCheckIn(CheckIn row) {
    final tags = (jsonDecode(row.contextTagsJson) as List<dynamic>).cast<String>();
    return domain.CheckIn(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      observedAt: DateTime.fromMillisecondsSinceEpoch(row.observedAt, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      mood: row.mood,
      energy: row.energy,
      tension: row.tension,
      focus: row.focus,
      note: row.note,
      contextTags: tags,
      moodScale: domain.MoodScale.values.byName(row.moodScale),
    );
  }

  static CheckInsCompanion fromCheckIn(domain.CheckIn checkIn) {
    return CheckInsCompanion.insert(
      id: checkIn.id.value,
      profileId: checkIn.profileId.value,
      observedAt: checkIn.observedAt.millisecondsSinceEpoch,
      createdAt: checkIn.createdAt.millisecondsSinceEpoch,
      mood: checkIn.mood,
      energy: checkIn.energy,
      tension: checkIn.tension,
      focus: checkIn.focus,
      note: Value(checkIn.note),
      contextTagsJson: Value(jsonEncode(checkIn.contextTags)),
      moodScale: Value(checkIn.moodScale.name),
    );
  }

  static domain.MoodFactor toMoodFactor(MoodFactor row) {
    return domain.MoodFactor(
      id: domain.EntityId(row.id),
      checkInId: domain.EntityId(row.checkInId),
      label: row.label,
      kind: domain.MoodFactorKind.values.byName(row.kind),
      impact: row.impact,
      uncertain: row.uncertain,
    );
  }

  static MoodFactorsCompanion fromMoodFactor(domain.MoodFactor factor) {
    return MoodFactorsCompanion.insert(
      id: factor.id.value,
      checkInId: factor.checkInId.value,
      label: factor.label,
      kind: factor.kind.name,
      impact: Value(factor.impact),
      uncertain: Value(factor.uncertain),
    );
  }

  static domain.DailyReview toDailyReview(DailyReview row) {
    return domain.DailyReview(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      reviewDate: DateTime.fromMillisecondsSinceEpoch(row.reviewDate, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      whatHappened: row.whatHappened,
      currentState: row.currentState,
      tomorrowCommitments: row.tomorrowCommitments,
      routeCorrection: row.routeCorrection,
    );
  }

  static DailyReviewsCompanion fromDailyReview(domain.DailyReview review) {
    return DailyReviewsCompanion.insert(
      id: review.id.value,
      profileId: review.profileId.value,
      reviewDate: review.reviewDate.millisecondsSinceEpoch,
      createdAt: review.createdAt.millisecondsSinceEpoch,
      whatHappened: Value(review.whatHappened),
      currentState: Value(review.currentState),
      tomorrowCommitments: Value(review.tomorrowCommitments),
      routeCorrection: Value(review.routeCorrection),
    );
  }

  static domain.WeeklyReview toWeeklyReview(WeeklyReview row) {
    return domain.WeeklyReview(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      weekStartDate:
          DateTime.fromMillisecondsSinceEpoch(row.weekStartDate, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      facts: row.facts,
      wins: row.wins,
      problems: row.problems,
      projects: row.projects,
      learning: row.learning,
      nextWeek: row.nextWeek,
    );
  }

  static WeeklyReviewsCompanion fromWeeklyReview(domain.WeeklyReview review) {
    return WeeklyReviewsCompanion.insert(
      id: review.id.value,
      profileId: review.profileId.value,
      weekStartDate: review.weekStartDate.millisecondsSinceEpoch,
      createdAt: review.createdAt.millisecondsSinceEpoch,
      facts: Value(review.facts),
      wins: Value(review.wins),
      problems: Value(review.problems),
      projects: Value(review.projects),
      learning: Value(review.learning),
      nextWeek: Value(review.nextWeek),
    );
  }

  static domain.WorkPriority toWorkPriority(WorkPriority row) {
    return domain.WorkPriority(
      profileId: domain.EntityId(row.profileId),
      workType: domain.WorkType.values.byName(row.workType),
      level: domain.PriorityLevel.values.byName(row.level),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static WorkPrioritiesCompanion fromWorkPriority(domain.WorkPriority priority) {
    return WorkPrioritiesCompanion.insert(
      profileId: priority.profileId.value,
      workType: priority.workType.name,
      level: priority.level.name,
      updatedAt: priority.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.Bill toBill(Bill row) {
    return domain.Bill(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      repeatMode: domain.BillRepeatMode.values.byName(row.repeatMode),
      target: row.target,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static BillsCompanion fromBill(domain.Bill bill) {
    return BillsCompanion.insert(
      id: bill.id.value,
      profileId: bill.profileId.value,
      title: bill.title,
      repeatMode: bill.repeatMode.name,
      target: bill.target,
      createdAt: bill.createdAt.millisecondsSinceEpoch,
      updatedAt: bill.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.ScheduleBlock toScheduleBlock(ScheduleBlock row) {
    return domain.ScheduleBlock(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      startAt: DateTime.fromMillisecondsSinceEpoch(row.startAt, isUtc: true),
      endAt: DateTime.fromMillisecondsSinceEpoch(row.endAt, isUtc: true),
      mode: domain.ScheduleBlockMode.values.byName(row.mode),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static ScheduleBlocksCompanion fromScheduleBlock(domain.ScheduleBlock block) {
    return ScheduleBlocksCompanion.insert(
      id: block.id.value,
      profileId: block.profileId.value,
      startAt: block.startAt.millisecondsSinceEpoch,
      endAt: block.endAt.millisecondsSinceEpoch,
      mode: block.mode.name,
      createdAt: block.createdAt.millisecondsSinceEpoch,
      updatedAt: block.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.Quest toQuest(Quest row) {
    final criteria =
        (jsonDecode(row.successCriteriaJson) as List<dynamic>).cast<String>();
    final risks = (jsonDecode(row.risksJson) as List<dynamic>).cast<String>();
    final assumptions = (jsonDecode(row.acceptanceAssumptionsJson) as List<dynamic>)
        .cast<String>();
    return domain.Quest(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      purpose: row.purpose,
      successCriteria: criteria,
      risks: risks,
      deadline: row.deadline == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deadline!, isUtc: true),
      status: domain.QuestStatus.values.byName(row.status),
      exitReason: row.exitReason,
      pauseReason: row.pauseReason,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      completedAt: row.completedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.completedAt!, isUtc: true),
      acceptedAt: row.acceptedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.acceptedAt!, isUtc: true),
      acceptanceDeadline: row.acceptanceDeadline == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.acceptanceDeadline!,
              isUtc: true,
            ),
      acceptanceAssumptions: assumptions,
      version: row.version,
    );
  }

  static QuestsCompanion fromQuest(domain.Quest quest) {
    return QuestsCompanion.insert(
      id: quest.id.value,
      profileId: quest.profileId.value,
      title: quest.title,
      purpose: quest.purpose,
      successCriteriaJson: Value(jsonEncode(quest.successCriteria)),
      risksJson: Value(jsonEncode(quest.risks)),
      deadline: Value(quest.deadline?.millisecondsSinceEpoch),
      status: quest.status.name,
      exitReason: Value(quest.exitReason),
      pauseReason: Value(quest.pauseReason),
      createdAt: quest.createdAt.millisecondsSinceEpoch,
      updatedAt: quest.updatedAt.millisecondsSinceEpoch,
      completedAt: Value(quest.completedAt?.millisecondsSinceEpoch),
      acceptedAt: Value(quest.acceptedAt?.millisecondsSinceEpoch),
      acceptanceDeadline: Value(quest.acceptanceDeadline?.millisecondsSinceEpoch),
      acceptanceAssumptionsJson: Value(jsonEncode(quest.acceptanceAssumptions)),
      version: Value(quest.version),
    );
  }

  static domain.Project toProject(Project row) {
    return domain.Project(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      purpose: row.purpose,
      status: domain.ProjectStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      version: row.version,
    );
  }

  static ProjectsCompanion fromProject(domain.Project project) {
    return ProjectsCompanion.insert(
      id: project.id.value,
      profileId: project.profileId.value,
      title: project.title,
      purpose: Value(project.purpose),
      status: project.status.name,
      createdAt: project.createdAt.millisecondsSinceEpoch,
      updatedAt: project.updatedAt.millisecondsSinceEpoch,
      version: Value(project.version),
    );
  }

  static domain.QuestProjectLink toQuestProjectLink(QuestProject row) {
    return domain.QuestProjectLink(
      questId: domain.EntityId(row.questId),
      projectId: domain.EntityId(row.projectId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
    );
  }

  static QuestProjectsCompanion fromQuestProjectLink(domain.QuestProjectLink link) {
    return QuestProjectsCompanion.insert(
      questId: link.questId.value,
      projectId: link.projectId.value,
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }

  static domain.QuestResearchLink toQuestResearchLink(QuestResearchData row) {
    return domain.QuestResearchLink(
      questId: domain.EntityId(row.questId),
      researchNodeId: domain.EntityId(row.researchNodeId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
    );
  }

  static QuestResearchCompanion fromQuestResearchLink(domain.QuestResearchLink link) {
    return QuestResearchCompanion.insert(
      questId: link.questId.value,
      researchNodeId: link.researchNodeId.value,
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }

  static domain.DecisionRecord toDecisionRecord(DecisionRecord row) {
    final alternatives =
        (jsonDecode(row.alternativesJson) as List<dynamic>).cast<String>();
    final criteria =
        (jsonDecode(row.criteriaJson) as List<dynamic>).cast<String>();
    final assumptions =
        (jsonDecode(row.assumptionsJson) as List<dynamic>).cast<String>();
    final expectedOutcomes =
        (jsonDecode(row.expectedOutcomesJson) as List<dynamic>).cast<String>();
    final risks = (jsonDecode(row.risksJson) as List<dynamic>).cast<String>();
    return domain.DecisionRecord(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      context: row.context,
      decision: row.decision,
      alternatives: alternatives,
      criteria: criteria,
      assumptions: assumptions,
      expectedOutcomes: expectedOutcomes,
      risks: risks,
      reversibility: domain.DecisionReversibility.values.byName(row.reversibility),
      decidedAt: DateTime.fromMillisecondsSinceEpoch(row.decidedAt, isUtc: true),
      reviewAt: row.reviewAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.reviewAt!, isUtc: true),
      outcomeReview: row.outcomeReview,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      version: row.version,
    );
  }

  static DecisionRecordsCompanion fromDecisionRecord(domain.DecisionRecord record) {
    return DecisionRecordsCompanion.insert(
      id: record.id.value,
      profileId: record.profileId.value,
      title: record.title,
      context: record.context,
      decision: record.decision,
      alternativesJson: Value(jsonEncode(record.alternatives)),
      criteriaJson: Value(jsonEncode(record.criteria)),
      assumptionsJson: Value(jsonEncode(record.assumptions)),
      expectedOutcomesJson: Value(jsonEncode(record.expectedOutcomes)),
      risksJson: Value(jsonEncode(record.risks)),
      reversibility: record.reversibility.name,
      decidedAt: record.decidedAt.millisecondsSinceEpoch,
      reviewAt: Value(record.reviewAt?.millisecondsSinceEpoch),
      outcomeReview: Value(record.outcomeReview),
      createdAt: record.createdAt.millisecondsSinceEpoch,
      updatedAt: record.updatedAt.millisecondsSinceEpoch,
      version: Value(record.version),
    );
  }

  static domain.QuestDecisionLink toQuestDecisionLink(QuestDecision row) {
    return domain.QuestDecisionLink(
      questId: domain.EntityId(row.questId),
      decisionId: domain.EntityId(row.decisionId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
    );
  }

  static QuestDecisionsCompanion fromQuestDecisionLink(domain.QuestDecisionLink link) {
    return QuestDecisionsCompanion.insert(
      questId: link.questId.value,
      decisionId: link.decisionId.value,
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }

  static domain.QuestPrerequisiteLink toQuestPrerequisiteLink(QuestPrerequisite row) {
    return domain.QuestPrerequisiteLink(
      questId: domain.EntityId(row.questId),
      prerequisiteQuestId: domain.EntityId(row.prerequisiteQuestId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
    );
  }

  static QuestPrerequisitesCompanion fromQuestPrerequisiteLink(
    domain.QuestPrerequisiteLink link,
  ) {
    return QuestPrerequisitesCompanion.insert(
      questId: link.questId.value,
      prerequisiteQuestId: link.prerequisiteQuestId.value,
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }

  static domain.ResearchNode toResearchNode(ResearchNode row) {
    return domain.ResearchNode(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      description: row.description,
      type: domain.ResearchNodeType.values.byName(row.type),
      status: domain.ResearchNodeStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      demonstratedNote: row.demonstratedNote,
      version: row.version,
    );
  }

  static ResearchNodesCompanion fromResearchNode(domain.ResearchNode node) {
    return ResearchNodesCompanion.insert(
      id: node.id.value,
      profileId: node.profileId.value,
      title: node.title,
      description: Value(node.description),
      type: node.type.name,
      status: node.status.name,
      createdAt: node.createdAt.millisecondsSinceEpoch,
      updatedAt: node.updatedAt.millisecondsSinceEpoch,
      demonstratedNote: Value(node.demonstratedNote),
      version: Value(node.version),
    );
  }

  static domain.ResearchPrerequisiteLink toResearchPrerequisiteLink(
    ResearchPrerequisite row,
  ) {
    return domain.ResearchPrerequisiteLink(
      nodeId: domain.EntityId(row.nodeId),
      prerequisiteNodeId: domain.EntityId(row.prerequisiteNodeId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
    );
  }

  static ResearchPrerequisitesCompanion fromResearchPrerequisiteLink(
    domain.ResearchPrerequisiteLink link,
  ) {
    return ResearchPrerequisitesCompanion.insert(
      nodeId: link.nodeId.value,
      prerequisiteNodeId: link.prerequisiteNodeId.value,
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }

  static domain.LearningSession toLearningSession(LearningSessionRow row) {
    return domain.LearningSession(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      nodeId: domain.EntityId(row.nodeId),
      startedAt: DateTime.fromMillisecondsSinceEpoch(row.startedAt, isUtc: true),
      durationMinutes: row.durationMinutes,
      mode: domain.LearningSessionMode.values.byName(row.mode),
      notes: row.notes,
    );
  }

  static LearningSessionsCompanion fromLearningSession(
    domain.LearningSession session,
  ) {
    return LearningSessionsCompanion.insert(
      id: session.id.value,
      profileId: session.profileId.value,
      nodeId: session.nodeId.value,
      startedAt: session.startedAt.millisecondsSinceEpoch,
      durationMinutes: session.durationMinutes,
      mode: session.mode.name,
      notes: Value(session.notes),
    );
  }

  static domain.ResearchEvidence toResearchEvidence(ResearchEvidenceRow row) {
    return domain.ResearchEvidence(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      nodeId: domain.EntityId(row.nodeId),
      sessionId:
          row.sessionId == null ? null : domain.EntityId(row.sessionId!),
      type: domain.ResearchEvidenceType.values.byName(row.type),
      title: row.title,
      body: row.body,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }

  static ResearchEvidenceItemsCompanion fromResearchEvidence(
    domain.ResearchEvidence evidence,
  ) {
    return ResearchEvidenceItemsCompanion.insert(
      id: evidence.id.value,
      profileId: evidence.profileId.value,
      nodeId: evidence.nodeId.value,
      sessionId: Value(evidence.sessionId?.value),
      type: evidence.type.name,
      title: evidence.title,
      body: evidence.body,
      createdAt: evidence.createdAt.millisecondsSinceEpoch,
    );
  }

  static domain.FinancialEntity toFinancialEntity(FinancialEntityRow row) {
    return domain.FinancialEntity(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      kind: domain.FinancialEntityKind.values.byName(row.kind),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static FinancialEntitiesCompanion fromFinancialEntity(
    domain.FinancialEntity entity,
  ) {
    return FinancialEntitiesCompanion.insert(
      id: entity.id.value,
      profileId: entity.profileId.value,
      name: entity.name,
      kind: entity.kind.name,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.FinancialAccount toFinancialAccount(FinancialAccountRow row) {
    return domain.FinancialAccount(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      entityId: domain.EntityId(row.entityId),
      institution: row.institution,
      name: row.name,
      type: domain.FinancialAccountType.values.byName(row.type),
      currency: row.currency,
      currentBalanceMinor: row.currentBalanceMinor,
      balanceAsOf: row.balanceAsOf == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.balanceAsOf!, isUtc: true),
      includeInNetWorth: row.includeInNetWorth,
      sensitiveDisplayMode:
          domain.SensitiveDisplayMode.values.byName(row.sensitiveDisplayMode),
      isArchived: row.isArchived,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static FinancialAccountsCompanion fromFinancialAccount(
    domain.FinancialAccount account,
  ) {
    return FinancialAccountsCompanion.insert(
      id: account.id.value,
      profileId: account.profileId.value,
      entityId: account.entityId.value,
      institution: account.institution,
      name: account.name,
      type: account.type.name,
      currency: account.currency,
      currentBalanceMinor: account.currentBalanceMinor,
      balanceAsOf: Value(account.balanceAsOf?.millisecondsSinceEpoch),
      includeInNetWorth: Value(account.includeInNetWorth),
      sensitiveDisplayMode: account.sensitiveDisplayMode.name,
      isArchived: Value(account.isArchived),
      createdAt: account.createdAt.millisecondsSinceEpoch,
      updatedAt: account.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.LedgerTransaction toLedgerTransaction(LedgerTransactionRow row) {
    return domain.LedgerTransaction(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      accountId: domain.EntityId(row.accountId),
      occurredAt:
          DateTime.fromMillisecondsSinceEpoch(row.occurredAt, isUtc: true),
      descriptionOriginal: row.descriptionOriginal,
      amountMinor: row.amountMinor,
      currency: row.currency,
      direction: domain.TransactionDirection.values.byName(row.direction),
      categoryId:
          row.categoryId == null ? null : domain.EntityId(row.categoryId!),
      notes: row.notes,
      fingerprint: row.fingerprint,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static LedgerTransactionsCompanion fromLedgerTransaction(
    domain.LedgerTransaction transaction,
  ) {
    return LedgerTransactionsCompanion.insert(
      id: transaction.id.value,
      profileId: transaction.profileId.value,
      accountId: transaction.accountId.value,
      occurredAt: transaction.occurredAt.millisecondsSinceEpoch,
      descriptionOriginal: transaction.descriptionOriginal,
      amountMinor: transaction.amountMinor,
      currency: transaction.currency,
      direction: transaction.direction.name,
      categoryId: Value(transaction.categoryId?.value),
      notes: Value(transaction.notes),
      fingerprint: transaction.fingerprint,
      createdAt: transaction.createdAt.millisecondsSinceEpoch,
      updatedAt: transaction.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.HealthCondition toHealthCondition(HealthConditionRow row) {
    final regionsRaw = jsonDecode(row.bodyRegionsJson);
    final regions = regionsRaw is List
        ? regionsRaw.map((e) => e.toString()).toList()
        : <String>[];
    return domain.HealthCondition(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      type: domain.HealthConditionType.values.byName(row.type),
      status: domain.HealthConditionStatus.values.byName(row.status),
      onsetAt: row.onsetAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.onsetAt!, isUtc: true),
      resolvedAt: row.resolvedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.resolvedAt!, isUtc: true),
      severityUserReported: row.severityUserReported,
      bodyRegions: regions,
      clinicianConfirmed: row.clinicianConfirmed,
      notes: row.notes,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static HealthConditionsCompanion fromHealthCondition(
    domain.HealthCondition condition,
  ) {
    return HealthConditionsCompanion.insert(
      id: condition.id.value,
      profileId: condition.profileId.value,
      title: condition.title,
      type: condition.type.name,
      status: condition.status.name,
      onsetAt: Value(condition.onsetAt?.millisecondsSinceEpoch),
      resolvedAt: Value(condition.resolvedAt?.millisecondsSinceEpoch),
      severityUserReported: Value(condition.severityUserReported),
      bodyRegionsJson: Value(jsonEncode(condition.bodyRegions)),
      clinicianConfirmed: Value(condition.clinicianConfirmed),
      notes: Value(condition.notes),
      createdAt: condition.createdAt.millisecondsSinceEpoch,
      updatedAt: condition.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.SymptomEntry toSymptomEntry(SymptomEntryRow row) {
    return domain.SymptomEntry(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      conditionId:
          row.conditionId == null ? null : domain.EntityId(row.conditionId!),
      occurredAt:
          DateTime.fromMillisecondsSinceEpoch(row.occurredAt, isUtc: true),
      intensity: row.intensity,
      note: row.note,
      bodyRegion: row.bodyRegion,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }

  static SymptomEntriesCompanion fromSymptomEntry(domain.SymptomEntry entry) {
    return SymptomEntriesCompanion.insert(
      id: entry.id.value,
      profileId: entry.profileId.value,
      conditionId: Value(entry.conditionId?.value),
      occurredAt: entry.occurredAt.millisecondsSinceEpoch,
      intensity: entry.intensity,
      note: Value(entry.note),
      bodyRegion: Value(entry.bodyRegion),
      createdAt: entry.createdAt.millisecondsSinceEpoch,
    );
  }

  static domain.HealthAppointment toHealthAppointment(
    HealthAppointmentRow row,
  ) {
    return domain.HealthAppointment(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      scheduledAt:
          DateTime.fromMillisecondsSinceEpoch(row.scheduledAt, isUtc: true),
      locationLabel: row.locationLabel,
      clinicianLabel: row.clinicianLabel,
      notes: row.notes,
      status: domain.HealthAppointmentStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static HealthAppointmentsCompanion fromHealthAppointment(
    domain.HealthAppointment a,
  ) {
    return HealthAppointmentsCompanion.insert(
      id: a.id.value,
      profileId: a.profileId.value,
      title: a.title,
      scheduledAt: a.scheduledAt.millisecondsSinceEpoch,
      locationLabel: Value(a.locationLabel),
      clinicianLabel: Value(a.clinicianLabel),
      notes: Value(a.notes),
      status: a.status.name,
      createdAt: a.createdAt.millisecondsSinceEpoch,
      updatedAt: a.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.InventoryItem toInventoryItem(InventoryItemRow row) {
    final tagsRaw = jsonDecode(row.tagsJson);
    final tags = tagsRaw is List
        ? tagsRaw.map((e) => e.toString()).toList()
        : <String>[];
    return domain.InventoryItem(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      category: domain.InventoryCategory.values.byName(row.category),
      status: domain.InventoryItemStatus.values.byName(row.status),
      locationLabel: row.locationLabel,
      notes: row.notes,
      tags: tags,
      purchaseDate: row.purchaseDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.purchaseDate!, isUtc: true),
      purchasePriceMinor: row.purchasePriceMinor,
      purchaseCurrency: row.purchaseCurrency,
      warrantyEnd: row.warrantyEnd == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.warrantyEnd!, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static InventoryItemsCompanion fromInventoryItem(domain.InventoryItem item) {
    return InventoryItemsCompanion.insert(
      id: item.id.value,
      profileId: item.profileId.value,
      name: item.name,
      category: item.category.name,
      status: item.status.name,
      locationLabel: Value(item.locationLabel),
      notes: Value(item.notes),
      tagsJson: Value(jsonEncode(item.tags)),
      purchaseDate: Value(item.purchaseDate?.millisecondsSinceEpoch),
      purchasePriceMinor: Value(item.purchasePriceMinor),
      purchaseCurrency: Value(item.purchaseCurrency),
      warrantyEnd: Value(item.warrantyEnd?.millisecondsSinceEpoch),
      createdAt: item.createdAt.millisecondsSinceEpoch,
      updatedAt: item.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.Person toPerson(PersonRow row) {
    final typesRaw = jsonDecode(row.relationshipTypesJson);
    final types = typesRaw is List
        ? typesRaw.map((e) => e.toString()).toList()
        : <String>[];
    return domain.Person(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      displayName: row.displayName,
      preferredName: row.preferredName,
      relationshipTypes: types,
      notes: row.notes,
      birthday: row.birthday == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.birthday!, isUtc: true),
      lastInteractionAt: row.lastInteractionAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.lastInteractionAt!,
              isUtc: true,
            ),
      nextFollowUpAt: row.nextFollowUpAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.nextFollowUpAt!,
              isUtc: true,
            ),
      archivedAt: row.archivedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static PeopleCompanion fromPerson(domain.Person person) {
    return PeopleCompanion.insert(
      id: person.id.value,
      profileId: person.profileId.value,
      displayName: person.displayName,
      preferredName: Value(person.preferredName),
      relationshipTypesJson: Value(jsonEncode(person.relationshipTypes)),
      notes: Value(person.notes),
      birthday: Value(person.birthday?.millisecondsSinceEpoch),
      lastInteractionAt: Value(person.lastInteractionAt?.millisecondsSinceEpoch),
      nextFollowUpAt: Value(person.nextFollowUpAt?.millisecondsSinceEpoch),
      archivedAt: Value(person.archivedAt?.millisecondsSinceEpoch),
      createdAt: person.createdAt.millisecondsSinceEpoch,
      updatedAt: person.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.CategoryBudget toCategoryBudget(CategoryBudgetRow row) {
    return domain.CategoryBudget(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      categoryId: domain.EntityId(row.categoryId),
      currency: row.currency,
      limitAmountMinor: row.limitAmountMinor,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static CategoryBudgetsCompanion fromCategoryBudget(
    domain.CategoryBudget budget,
  ) {
    return CategoryBudgetsCompanion.insert(
      id: budget.id.value,
      profileId: budget.profileId.value,
      categoryId: budget.categoryId.value,
      currency: budget.currency,
      limitAmountMinor: budget.limitAmountMinor,
      createdAt: budget.createdAt.millisecondsSinceEpoch,
      updatedAt: budget.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.PersonInteraction toPersonInteraction(
    PersonInteractionRow row,
  ) {
    return domain.PersonInteraction(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      personId: domain.EntityId(row.personId),
      kind: domain.InteractionKind.values.byName(row.kind),
      occurredAt: DateTime.fromMillisecondsSinceEpoch(row.occurredAt, isUtc: true),
      note: row.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }

  static PersonInteractionsCompanion fromPersonInteraction(
    domain.PersonInteraction interaction,
  ) {
    return PersonInteractionsCompanion.insert(
      id: interaction.id.value,
      profileId: interaction.profileId.value,
      personId: interaction.personId.value,
      kind: interaction.kind.name,
      occurredAt: interaction.occurredAt.millisecondsSinceEpoch,
      note: Value(interaction.note),
      createdAt: interaction.createdAt.millisecondsSinceEpoch,
    );
  }

  static domain.Trip toTrip(TripRow row) {
    final destRaw = jsonDecode(row.destinationsJson);
    final destinations = destRaw is List
        ? destRaw.map((e) => e.toString()).toList()
        : <String>[];
    return domain.Trip(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      destinations: destinations,
      startAt: row.startAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.startAt!, isUtc: true),
      endAt: row.endAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.endAt!, isUtc: true),
      purpose: row.purpose,
      notes: row.notes,
      status: domain.TripStatus.values.byName(row.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static TripsCompanion fromTrip(domain.Trip trip) {
    return TripsCompanion.insert(
      id: trip.id.value,
      profileId: trip.profileId.value,
      title: trip.title,
      destinationsJson: Value(jsonEncode(trip.destinations)),
      startAt: Value(trip.startAt?.millisecondsSinceEpoch),
      endAt: Value(trip.endAt?.millisecondsSinceEpoch),
      purpose: Value(trip.purpose),
      notes: Value(trip.notes),
      status: trip.status.name,
      createdAt: trip.createdAt.millisecondsSinceEpoch,
      updatedAt: trip.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.Organization toOrganization(OrganizationRow row) {
    return domain.Organization(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      kind: domain.OrganizationKind.values.byName(row.kind),
      notes: row.notes,
      archivedAt: row.archivedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static OrganizationsCompanion fromOrganization(domain.Organization org) {
    return OrganizationsCompanion.insert(
      id: org.id.value,
      profileId: org.profileId.value,
      name: org.name,
      kind: org.kind.name,
      notes: Value(org.notes),
      archivedAt: Value(org.archivedAt?.millisecondsSinceEpoch),
      createdAt: org.createdAt.millisecondsSinceEpoch,
      updatedAt: org.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.PersonOrganizationLink toPersonOrganizationLink(
    PersonOrganizationRow row,
  ) {
    return domain.PersonOrganizationLink(
      personId: domain.EntityId(row.personId),
      organizationId: domain.EntityId(row.organizationId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
      role: row.role,
    );
  }

  static PersonOrganizationsCompanion fromPersonOrganizationLink(
    domain.PersonOrganizationLink link,
  ) {
    return PersonOrganizationsCompanion.insert(
      personId: link.personId.value,
      organizationId: link.organizationId.value,
      role: Value(link.role),
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }

  static domain.HomeMaintenanceTask toHomeMaintenanceTask(
    HomeMaintenanceTaskRow row,
  ) {
    return domain.HomeMaintenanceTask(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      systemOrItem: row.systemOrItem,
      cadenceDays: row.cadenceDays,
      nextDueAt: row.nextDueAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.nextDueAt!, isUtc: true),
      lastDoneAt: row.lastDoneAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastDoneAt!, isUtc: true),
      vendorLabel: row.vendorLabel,
      estimatedCostMinor: row.estimatedCostMinor,
      currency: row.currency,
      notes: row.notes,
      linkedInventoryItemId: row.linkedInventoryItemId == null
          ? null
          : domain.EntityId(row.linkedInventoryItemId!),
      archivedAt: row.archivedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static HomeMaintenanceTasksCompanion fromHomeMaintenanceTask(
    domain.HomeMaintenanceTask task,
  ) {
    return HomeMaintenanceTasksCompanion.insert(
      id: task.id.value,
      profileId: task.profileId.value,
      title: task.title,
      systemOrItem: task.systemOrItem,
      cadenceDays: Value(task.cadenceDays),
      nextDueAt: Value(task.nextDueAt?.millisecondsSinceEpoch),
      lastDoneAt: Value(task.lastDoneAt?.millisecondsSinceEpoch),
      vendorLabel: Value(task.vendorLabel),
      estimatedCostMinor: Value(task.estimatedCostMinor),
      currency: Value(task.currency),
      notes: Value(task.notes),
      linkedInventoryItemId: Value(task.linkedInventoryItemId?.value),
      archivedAt: Value(task.archivedAt?.millisecondsSinceEpoch),
      createdAt: task.createdAt.millisecondsSinceEpoch,
      updatedAt: task.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.QuestInventoryLink toQuestInventoryLink(
    QuestInventoryData row,
  ) {
    return domain.QuestInventoryLink(
      questId: domain.EntityId(row.questId),
      inventoryItemId: domain.EntityId(row.inventoryItemId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
    );
  }

  static QuestInventoryCompanion fromQuestInventoryLink(
    domain.QuestInventoryLink link,
  ) {
    return QuestInventoryCompanion.insert(
      questId: link.questId.value,
      inventoryItemId: link.inventoryItemId.value,
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }

  static domain.ZoneTripLink toZoneTripLink(ZoneTrip row) {
    return domain.ZoneTripLink(
      zoneId: domain.EntityId(row.zoneId),
      tripId: domain.EntityId(row.tripId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
    );
  }

  static ZoneTripsCompanion fromZoneTripLink(domain.ZoneTripLink link) {
    return ZoneTripsCompanion.insert(
      zoneId: link.zoneId.value,
      tripId: link.tripId.value,
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }

  static domain.TripInventoryLink toTripInventoryLink(TripInventoryData row) {
    return domain.TripInventoryLink(
      tripId: domain.EntityId(row.tripId),
      inventoryItemId: domain.EntityId(row.inventoryItemId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
    );
  }

  static TripInventoryCompanion fromTripInventoryLink(
    domain.TripInventoryLink link,
  ) {
    return TripInventoryCompanion.insert(
      tripId: link.tripId.value,
      inventoryItemId: link.inventoryItemId.value,
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }

  static domain.Commitment toCommitment(CommitmentRow row) {
    return domain.Commitment(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      description: row.description,
      madeByLabel: row.madeByLabel,
      madeToPersonId: row.madeToPersonId == null
          ? null
          : domain.EntityId(row.madeToPersonId!),
      madeToOrganizationId: row.madeToOrganizationId == null
          ? null
          : domain.EntityId(row.madeToOrganizationId!),
      madeToLabel: row.madeToLabel,
      dueAt: row.dueAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.dueAt!, isUtc: true),
      status: domain.CommitmentStatus.values.byName(row.status),
      notes: row.notes,
      linkedQuestId: row.linkedQuestId == null
          ? null
          : domain.EntityId(row.linkedQuestId!),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static CommitmentsCompanion fromCommitment(domain.Commitment c) {
    return CommitmentsCompanion.insert(
      id: c.id.value,
      profileId: c.profileId.value,
      description: c.description,
      madeByLabel: c.madeByLabel,
      madeToPersonId: Value(c.madeToPersonId?.value),
      madeToOrganizationId: Value(c.madeToOrganizationId?.value),
      madeToLabel: Value(c.madeToLabel),
      dueAt: Value(c.dueAt?.millisecondsSinceEpoch),
      status: c.status.name,
      notes: Value(c.notes),
      linkedQuestId: Value(c.linkedQuestId?.value),
      createdAt: c.createdAt.millisecondsSinceEpoch,
      updatedAt: c.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.DeviceIdentity toDeviceIdentity(DeviceIdentityRow row) {
    return domain.DeviceIdentity(
      id: domain.EntityId(row.id),
      label: row.label,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      lastSeenAt: row.lastSeenAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastSeenAt!, isUtc: true),
    );
  }

  static DeviceIdentitiesCompanion fromDeviceIdentity(
    domain.DeviceIdentity device,
  ) {
    return DeviceIdentitiesCompanion.insert(
      id: device.id.value,
      label: device.label,
      createdAt: device.createdAt.millisecondsSinceEpoch,
      lastSeenAt: Value(device.lastSeenAt?.millisecondsSinceEpoch),
    );
  }

  static domain.SyncOperation toSyncOperation(SyncOperationRow row) {
    return domain.SyncOperation(
      id: domain.EntityId(row.id),
      entityType: row.entityType,
      entityId: domain.EntityId(row.entityId),
      operation: domain.SyncOpKind.values.byName(row.operation),
      baseVersion: row.baseVersion,
      payloadJson: row.payloadJson,
      status: domain.SyncOpStatus.values.byName(row.status),
      attempts: row.attempts,
      nextAttemptAt: row.nextAttemptAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.nextAttemptAt!,
              isUtc: true,
            ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static SyncOperationsCompanion fromSyncOperation(domain.SyncOperation op) {
    return SyncOperationsCompanion.insert(
      id: op.id.value,
      entityType: op.entityType,
      entityId: op.entityId.value,
      operation: op.operation.name,
      baseVersion: Value(op.baseVersion),
      payloadJson: op.payloadJson,
      status: op.status.name,
      attempts: Value(op.attempts),
      nextAttemptAt: Value(op.nextAttemptAt?.millisecondsSinceEpoch),
      createdAt: op.createdAt.millisecondsSinceEpoch,
      updatedAt: op.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.ContextZone toContextZone(ContextZoneRow row) {
    return domain.ContextZone(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      locationLabel: row.locationLabel,
      capabilities: (jsonDecode(row.capabilitiesJson) as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      unavailableWorkTypes:
          (jsonDecode(row.unavailableWorkTypesJson) as List<dynamic>)
              .map((e) => e.toString())
              .toList(),
      connectivity: domain.ZoneConnectivity.values.byName(row.connectivity),
      notes: row.notes,
      archivedAt: row.archivedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static ContextZonesCompanion fromContextZone(domain.ContextZone zone) {
    return ContextZonesCompanion.insert(
      id: zone.id.value,
      profileId: zone.profileId.value,
      name: zone.name,
      locationLabel: Value(zone.locationLabel),
      capabilitiesJson: Value(jsonEncode(zone.capabilities)),
      unavailableWorkTypesJson: Value(jsonEncode(zone.unavailableWorkTypes)),
      connectivity: zone.connectivity.name,
      notes: Value(zone.notes),
      archivedAt: Value(zone.archivedAt?.millisecondsSinceEpoch),
      createdAt: zone.createdAt.millisecondsSinceEpoch,
      updatedAt: zone.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.IntegrationConsent toIntegrationConsent(
    IntegrationConsentRow row,
  ) {
    return domain.IntegrationConsent(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      kind: domain.IntegrationKind.values.byName(row.kind),
      enabled: row.enabled,
      grantedAt: row.grantedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.grantedAt!, isUtc: true),
      revokedAt: row.revokedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.revokedAt!, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static IntegrationConsentsCompanion fromIntegrationConsent(
    domain.IntegrationConsent consent,
  ) {
    return IntegrationConsentsCompanion.insert(
      id: consent.id.value,
      profileId: consent.profileId.value,
      kind: consent.kind.name,
      enabled: Value(consent.enabled),
      grantedAt: Value(consent.grantedAt?.millisecondsSinceEpoch),
      revokedAt: Value(consent.revokedAt?.millisecondsSinceEpoch),
      createdAt: consent.createdAt.millisecondsSinceEpoch,
      updatedAt: consent.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.ExternalCalendarEvent toExternalCalendarEvent(
    ExternalCalendarEventRow row,
  ) {
    return domain.ExternalCalendarEvent(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      externalUid: row.externalUid,
      title: row.title,
      startAt: DateTime.fromMillisecondsSinceEpoch(row.startAt, isUtc: true),
      endAt: DateTime.fromMillisecondsSinceEpoch(row.endAt, isUtc: true),
      sourceType: domain.SourceType.values.byName(row.sourceType),
      importedAt:
          DateTime.fromMillisecondsSinceEpoch(row.importedAt, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static ExternalCalendarEventsCompanion fromExternalCalendarEvent(
    domain.ExternalCalendarEvent event,
  ) {
    return ExternalCalendarEventsCompanion.insert(
      id: event.id.value,
      profileId: event.profileId.value,
      externalUid: Value(event.externalUid),
      title: event.title,
      startAt: event.startAt.millisecondsSinceEpoch,
      endAt: event.endAt.millisecondsSinceEpoch,
      sourceType: event.sourceType.name,
      importedAt: event.importedAt.millisecondsSinceEpoch,
      createdAt: event.createdAt.millisecondsSinceEpoch,
      updatedAt: event.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.KnowledgeArea toKnowledgeArea(KnowledgeAreaRow row) {
    return domain.KnowledgeArea(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      parentId: row.parentId == null ? null : domain.EntityId(row.parentId!),
      title: row.title,
      slug: row.slug,
      description: row.description,
      iconKey: row.iconKey,
      catalogKey: row.catalogKey,
      sortOrder: row.sortOrder,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  static KnowledgeAreasCompanion fromKnowledgeArea(domain.KnowledgeArea area) {
    return KnowledgeAreasCompanion.insert(
      id: area.id.value,
      profileId: area.profileId.value,
      parentId: Value(area.parentId?.value),
      title: area.title,
      slug: area.slug,
      description: Value(area.description),
      iconKey: Value(area.iconKey),
      catalogKey: Value(area.catalogKey),
      sortOrder: Value(area.sortOrder),
      createdAt: area.createdAt.millisecondsSinceEpoch,
      updatedAt: area.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.FlashcardDeck toFlashcardDeck(FlashcardDeckRow row) {
    return domain.FlashcardDeck(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      areaId: row.areaId == null ? null : domain.EntityId(row.areaId!),
      researchNodeId: row.researchNodeId == null
          ? null
          : domain.EntityId(row.researchNodeId!),
      title: row.title,
      description: row.description,
      newLimitPerDay: row.newLimitPerDay,
      reviewLimitPerDay: row.reviewLimitPerDay,
      archivedAt: row.archivedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      version: row.version,
    );
  }

  static FlashcardDecksCompanion fromFlashcardDeck(domain.FlashcardDeck deck) {
    return FlashcardDecksCompanion.insert(
      id: deck.id.value,
      profileId: deck.profileId.value,
      areaId: Value(deck.areaId?.value),
      researchNodeId: Value(deck.researchNodeId?.value),
      title: deck.title,
      description: Value(deck.description),
      newLimitPerDay: Value(deck.newLimitPerDay),
      reviewLimitPerDay: Value(deck.reviewLimitPerDay),
      archivedAt: Value(deck.archivedAt?.millisecondsSinceEpoch),
      createdAt: deck.createdAt.millisecondsSinceEpoch,
      updatedAt: deck.updatedAt.millisecondsSinceEpoch,
      version: Value(deck.version),
    );
  }

  static domain.Flashcard toFlashcard(FlashcardRow row) {
    final tags = (jsonDecode(row.tagsJson) as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    return domain.Flashcard(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      deckId: domain.EntityId(row.deckId),
      areaId: row.areaId == null ? null : domain.EntityId(row.areaId!),
      kind: domain.FlashcardKind.values.byName(row.kind),
      front: row.front,
      back: row.back,
      extra: row.extra,
      tags: tags,
      clozeIndex: row.clozeIndex,
      reverseOfId:
          row.reverseOfId == null ? null : domain.EntityId(row.reverseOfId!),
      scheduleMode: domain.FlashcardScheduleMode.values.byName(row.scheduleMode),
      priority: domain.FlashcardPolicy.normalizePriority(row.priority),
      suspended: row.suspended,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      version: row.version,
    );
  }

  static FlashcardsCompanion fromFlashcard(domain.Flashcard card) {
    return FlashcardsCompanion.insert(
      id: card.id.value,
      profileId: card.profileId.value,
      deckId: card.deckId.value,
      areaId: Value(card.areaId?.value),
      kind: card.kind.name,
      front: card.front,
      back: Value(card.back),
      extra: Value(card.extra),
      tagsJson: Value(jsonEncode(card.tags)),
      clozeIndex: Value(card.clozeIndex),
      reverseOfId: Value(card.reverseOfId?.value),
      scheduleMode: Value(card.scheduleMode.name),
      priority: Value(card.priority),
      suspended: Value(card.suspended),
      createdAt: card.createdAt.millisecondsSinceEpoch,
      updatedAt: card.updatedAt.millisecondsSinceEpoch,
      version: Value(card.version),
    );
  }

  static domain.FlashcardSrsState toFlashcardSrs(FlashcardSrsRow row) {
    return domain.FlashcardSrsState(
      cardId: domain.EntityId(row.cardId),
      status: domain.FlashcardSrsStatus.values.byName(row.status),
      easeFactor: row.easeFactor,
      intervalDays: row.intervalDays,
      repetitions: row.repetitions,
      lapses: row.lapses,
      learningStepIndex: row.learningStepIndex,
      leech: row.leech,
      dueAt: DateTime.fromMillisecondsSinceEpoch(row.dueAt, isUtc: true),
      lastReviewedAt: row.lastReviewedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.lastReviewedAt!,
              isUtc: true,
            ),
    );
  }

  static FlashcardSrsCompanion fromFlashcardSrs(domain.FlashcardSrsState srs) {
    return FlashcardSrsCompanion.insert(
      cardId: srs.cardId.value,
      status: srs.status.name,
      easeFactor: Value(srs.easeFactor),
      intervalDays: Value(srs.intervalDays),
      repetitions: Value(srs.repetitions),
      lapses: Value(srs.lapses),
      learningStepIndex: Value(srs.learningStepIndex),
      leech: Value(srs.leech),
      dueAt: srs.dueAt.millisecondsSinceEpoch,
      lastReviewedAt: Value(srs.lastReviewedAt?.millisecondsSinceEpoch),
    );
  }

  static domain.FlashcardReviewLog toFlashcardReviewLog(
    FlashcardReviewLogRow row,
  ) {
    return domain.FlashcardReviewLog(
      id: domain.EntityId(row.id),
      cardId: domain.EntityId(row.cardId),
      reviewedAt:
          DateTime.fromMillisecondsSinceEpoch(row.reviewedAt, isUtc: true),
      rating: domain.FlashcardRating.values.byName(row.rating),
      intervalDaysBefore: row.intervalDaysBefore,
      intervalDaysAfter: row.intervalDaysAfter,
      easeBefore: row.easeBefore,
      easeAfter: row.easeAfter,
      durationMs: row.durationMs,
      reviewKind: domain.FlashcardReviewKind.values.byName(row.reviewKind),
    );
  }

  static FlashcardReviewLogsCompanion fromFlashcardReviewLog(
    domain.FlashcardReviewLog log,
  ) {
    return FlashcardReviewLogsCompanion.insert(
      id: log.id.value,
      cardId: log.cardId.value,
      reviewedAt: log.reviewedAt.millisecondsSinceEpoch,
      rating: log.rating.name,
      intervalDaysBefore: log.intervalDaysBefore,
      intervalDaysAfter: log.intervalDaysAfter,
      easeBefore: log.easeBefore,
      easeAfter: log.easeAfter,
      durationMs: Value(log.durationMs),
      reviewKind: Value(log.reviewKind.name),
    );
  }

  static domain.KnowledgeAreaPlacement toKnowledgeAreaPlacement(
    KnowledgeAreaPlacementRow row,
  ) {
    return domain.KnowledgeAreaPlacement(
      areaId: domain.EntityId(row.areaId),
      parentAreaId: domain.EntityId(row.parentAreaId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
      catalogKey: row.catalogKey,
    );
  }

  static KnowledgeAreaPlacementsCompanion fromKnowledgeAreaPlacement(
    domain.KnowledgeAreaPlacement placement,
  ) {
    return KnowledgeAreaPlacementsCompanion.insert(
      areaId: placement.areaId.value,
      parentAreaId: placement.parentAreaId.value,
      linkedAt: placement.linkedAt.millisecondsSinceEpoch,
      catalogKey: Value(placement.catalogKey),
    );
  }

  static domain.ResearchKnowledgeLink toResearchKnowledgeLink(
    ResearchKnowledgeLinkRow row,
  ) {
    return domain.ResearchKnowledgeLink(
      researchNodeId: domain.EntityId(row.researchNodeId),
      areaId: domain.EntityId(row.areaId),
      kind: domain.ResearchKnowledgeLinkKind.values.byName(row.kind),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
    );
  }

  static ResearchKnowledgeLinksCompanion fromResearchKnowledgeLink(
    domain.ResearchKnowledgeLink link,
  ) {
    return ResearchKnowledgeLinksCompanion.insert(
      researchNodeId: link.researchNodeId.value,
      areaId: link.areaId.value,
      kind: link.kind.name,
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }

  static domain.FlashcardTag toFlashcardTag(FlashcardTagRow row) {
    return domain.FlashcardTag(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      parentId: row.parentId == null ? null : domain.EntityId(row.parentId!),
      title: row.title,
      sortOrder: row.sortOrder,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }

  static FlashcardTagsCompanion fromFlashcardTag(domain.FlashcardTag tag) {
    return FlashcardTagsCompanion.insert(
      id: tag.id.value,
      profileId: tag.profileId.value,
      parentId: Value(tag.parentId?.value),
      title: tag.title,
      sortOrder: Value(tag.sortOrder),
      createdAt: tag.createdAt.millisecondsSinceEpoch,
    );
  }

  static domain.FlashcardTagLink toFlashcardTagLink(FlashcardTagLinkRow row) {
    return domain.FlashcardTagLink(
      cardId: domain.EntityId(row.cardId),
      tagId: domain.EntityId(row.tagId),
      linkedAt: DateTime.fromMillisecondsSinceEpoch(row.linkedAt, isUtc: true),
    );
  }

  static FlashcardTagLinksCompanion fromFlashcardTagLink(
    domain.FlashcardTagLink link,
  ) {
    return FlashcardTagLinksCompanion.insert(
      cardId: link.cardId.value,
      tagId: link.tagId.value,
      linkedAt: link.linkedAt.millisecondsSinceEpoch,
    );
  }
}
