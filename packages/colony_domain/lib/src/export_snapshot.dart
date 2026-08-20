import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'bill.dart';
import 'check_in.dart';
import 'colony_profile.dart';
import 'domain_event.dart';
import 'need.dart';
import 'preferences.dart';
import 'project.dart';
import 'quest.dart';
import 'quest_prerequisite.dart';
import 'decision_record.dart';
import 'enums.dart';
import 'id_generator.dart';
import 'research_node.dart';
import 'research_prerequisite.dart';
import 'learning_session.dart';
import 'research_evidence.dart';
import 'financial_entity.dart';
import 'financial_account.dart';
import 'ledger_transaction.dart';
import 'health_condition.dart';
import 'health_appointment.dart';
import 'symptom_entry.dart';
import 'inventory_item.dart';
import 'person.dart';
import 'category_budget.dart';
import 'person_interaction.dart';
import 'person_organization.dart';
import 'commitment.dart';
import 'context_zone.dart';
import 'zone_trip.dart';
import 'integration.dart';
import 'trip.dart';
import 'organization.dart';
import 'home_maintenance.dart';
import 'quest_inventory.dart';
import 'trip_inventory.dart';
import 'knowledge_area.dart';
import 'knowledge_area_placement.dart';
import 'flashcard.dart';
import 'google_timeline.dart';
import 'schedule_block.dart';
import 'task.dart';
import 'weekly_review.dart';
import 'work_enums.dart';
import 'work_priority.dart';

import 'need_enums.dart';

/// Thrown when export JSON is invalid or unsupported.
class ExportSnapshotException implements Exception {
  ExportSnapshotException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ExportSnapshot extends Equatable {
  const ExportSnapshot({
    required this.exportedAt,
    required this.version,
    required this.profile,
    required this.preferences,
    required this.tasks,
    required this.events,
    this.quests = const [],
    this.projects = const [],
    this.questProjectLinks = const [],
    this.decisionRecords = const [],
    this.questDecisionLinks = const [],
    this.questPrerequisiteLinks = const [],
    this.workPriorities = const [],
    this.bills = const [],
    this.scheduleBlocks = const [],
    this.needDefinitions = const [],
    this.needReadings = const [],
    this.checkIns = const [],
    this.dailyReviews = const [],
    this.moodFactors = const [],
    this.weeklyReviews = const [],
    this.researchNodes = const [],
    this.researchPrerequisiteLinks = const [],
    this.questResearchLinks = const [],
    this.learningSessions = const [],
    this.researchEvidence = const [],
    this.financialEntities = const [],
    this.financialAccounts = const [],
    this.transactions = const [],
    this.healthConditions = const [],
    this.symptomEntries = const [],
    this.inventoryItems = const [],
    this.people = const [],
    this.categoryBudgets = const [],
    this.personInteractions = const [],
    this.trips = const [],
    this.organizations = const [],
    this.personOrganizationLinks = const [],
    this.homeMaintenanceTasks = const [],
    this.questInventoryLinks = const [],
    this.commitments = const [],
    this.contextZones = const [],
    this.integrationConsents = const [],
    this.externalCalendarEvents = const [],
    this.zoneTripLinks = const [],
    this.healthAppointments = const [],
    this.tripInventoryLinks = const [],
    this.knowledgeAreas = const [],
    this.flashcardDecks = const [],
    this.flashcards = const [],
    this.flashcardSrs = const [],
    this.flashcardReviewLogs = const [],
    this.knowledgeAreaPlacements = const [],
    this.researchKnowledgeLinks = const [],
    this.googleTimelineImport,
    this.googleTimelinePlaceLabels = const [],
  });

  final DateTime exportedAt;
  final int version;
  final ColonyProfile profile;
  final AppPreferences preferences;
  final List<ColonyTask> tasks;
  final List<DomainEvent> events;
  final List<Quest> quests;
  final List<Project> projects;
  final List<QuestProjectLink> questProjectLinks;
  final List<DecisionRecord> decisionRecords;
  final List<QuestDecisionLink> questDecisionLinks;
  final List<QuestPrerequisiteLink> questPrerequisiteLinks;
  final List<WorkPriority> workPriorities;
  final List<Bill> bills;
  final List<ScheduleBlock> scheduleBlocks;
  final List<NeedDefinition> needDefinitions;
  final List<NeedReading> needReadings;
  final List<CheckIn> checkIns;
  final List<DailyReview> dailyReviews;
  final List<MoodFactor> moodFactors;
  final List<WeeklyReview> weeklyReviews;
  final List<ResearchNode> researchNodes;
  final List<ResearchPrerequisiteLink> researchPrerequisiteLinks;
  final List<QuestResearchLink> questResearchLinks;
  final List<LearningSession> learningSessions;
  final List<ResearchEvidence> researchEvidence;
  final List<FinancialEntity> financialEntities;
  final List<FinancialAccount> financialAccounts;
  final List<LedgerTransaction> transactions;
  final List<HealthCondition> healthConditions;
  final List<SymptomEntry> symptomEntries;
  final List<InventoryItem> inventoryItems;
  final List<Person> people;
  final List<CategoryBudget> categoryBudgets;
  final List<PersonInteraction> personInteractions;
  final List<Trip> trips;
  final List<Organization> organizations;
  final List<PersonOrganizationLink> personOrganizationLinks;
  final List<HomeMaintenanceTask> homeMaintenanceTasks;
  final List<QuestInventoryLink> questInventoryLinks;
  final List<Commitment> commitments;
  final List<ContextZone> contextZones;
  final List<IntegrationConsent> integrationConsents;
  final List<ExternalCalendarEvent> externalCalendarEvents;
  final List<ZoneTripLink> zoneTripLinks;
  final List<HealthAppointment> healthAppointments;
  final List<TripInventoryLink> tripInventoryLinks;
  final List<KnowledgeArea> knowledgeAreas;
  final List<FlashcardDeck> flashcardDecks;
  final List<Flashcard> flashcards;
  final List<FlashcardSrsState> flashcardSrs;
  final List<FlashcardReviewLog> flashcardReviewLogs;
  final List<KnowledgeAreaPlacement> knowledgeAreaPlacements;
  final List<ResearchKnowledgeLink> researchKnowledgeLinks;
  final GoogleTimelineImport? googleTimelineImport;
  final List<TimelinePlaceLabel> googleTimelinePlaceLabels;

  Map<String, int> get entityCounts => {
        'tasks': tasks.length,
        'events': events.length,
        'quests': quests.length,
        'projects': projects.length,
        'decisions': decisionRecords.length,
        'schedule_blocks': scheduleBlocks.length,
        'bills': bills.length,
        'check_ins': checkIns.length,
        'need_definitions': needDefinitions.length,
        'daily_reviews': dailyReviews.length,
        'mood_factors': moodFactors.length,
        'weekly_reviews': weeklyReviews.length,
        'research_nodes': researchNodes.length,
        'learning_sessions': learningSessions.length,
        'research_evidence': researchEvidence.length,
        'financial_entities': financialEntities.length,
        'financial_accounts': financialAccounts.length,
        'transactions': transactions.length,
        'health_conditions': healthConditions.length,
        'symptom_entries': symptomEntries.length,
        'inventory_items': inventoryItems.length,
        'people': people.length,
        'category_budgets': categoryBudgets.length,
        'person_interactions': personInteractions.length,
        'trips': trips.length,
        'organizations': organizations.length,
        'person_organization_links': personOrganizationLinks.length,
        'home_maintenance_tasks': homeMaintenanceTasks.length,
        'quest_inventory_links': questInventoryLinks.length,
        'commitments': commitments.length,
        'context_zones': contextZones.length,
        'integration_consents': integrationConsents.length,
        'external_calendar_events': externalCalendarEvents.length,
        'zone_trip_links': zoneTripLinks.length,
        'health_appointments': healthAppointments.length,
        'trip_inventory_links': tripInventoryLinks.length,
        'knowledge_areas': knowledgeAreas.length,
        'flashcard_decks': flashcardDecks.length,
        'flashcards': flashcards.length,
        'flashcard_srs': flashcardSrs.length,
        'flashcard_review_logs': flashcardReviewLogs.length,
        'knowledge_area_placements': knowledgeAreaPlacements.length,
        'research_knowledge_links': researchKnowledgeLinks.length,
        'google_timeline_import': googleTimelineImport == null ? 0 : 1,
        'google_timeline_place_labels': googleTimelinePlaceLabels.length,
      };

  static ExportSnapshot fromJsonString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw ExportSnapshotException('JSON raiz deve ser um objeto');
      }
      return fromJson(decoded);
    } on ExportSnapshotException {
      rethrow;
    } on FormatException catch (e) {
      throw ExportSnapshotException('JSON inválido: ${e.message}');
    }
  }

  static ExportSnapshot fromJson(Map<String, dynamic> json) {
    final version = _requireInt(json, 'version');
    if (version < 1 || version > 33) {
      throw ExportSnapshotException('Versão de export não suportada: $version');
    }

    final exportedAt = _parseDateTime(_requireString(json, 'exported_at'));
    final profileJson = _requireMap(json, 'profile');
    final prefsJson = _requireMap(json, 'preferences');

    final profileId = EntityId(_requireString(profileJson, 'id'));
    final profile = ColonyProfile(
      id: profileId,
      colonyName: _requireString(profileJson, 'colony_name'),
      displayName: _requireString(profileJson, 'display_name'),
      timezone: _requireString(profileJson, 'timezone'),
      locale: _requireString(profileJson, 'locale'),
      baseCurrency: _requireString(profileJson, 'base_currency'),
      createdAt: _parseDateTime(_requireString(profileJson, 'created_at')),
      updatedAt: _parseDateTime(_requireString(profileJson, 'updated_at')),
    );

    final preferences = AppPreferences(
      densityMode: DensityMode.values.byName(
        _requireString(prefsJson, 'density_mode'),
      ),
      themeMode: ThemeModePreference.values.byName(
        _requireString(prefsJson, 'theme_mode'),
      ),
      weekStartsOnMonday: _requireBool(prefsJson, 'week_starts_on_monday'),
      use24HourFormat: _requireBool(prefsJson, 'use_24_hour_format'),
      sectorsEnabled: _parseStringList(prefsJson['sectors_enabled']),
      onboardingCompleted: _requireBool(prefsJson, 'onboarding_completed'),
      biometricLockEnabled: false,
      sessionTimeoutMinutes: 0,
    );

    final tasks = _parseList(json['tasks'], _parseTask(profileId));
    final events = _parseList(json['events'], _parseEvent);
    final quests = version >= 2
        ? _parseList(json['quests'], _parseQuest(profileId))
        : <Quest>[];
    final projects = version >= 3
        ? _parseList(json['projects'], _parseProject(profileId))
        : <Project>[];
    final questProjectLinks = version >= 3
        ? _parseList(json['quest_project_links'], _parseQuestProjectLink)
        : <QuestProjectLink>[];
    final decisionRecords = version >= 4
        ? _parseList(json['decision_records'], _parseDecisionRecord(profileId))
        : <DecisionRecord>[];
    final questDecisionLinks = version >= 4
        ? _parseList(json['quest_decision_links'], _parseQuestDecisionLink)
        : <QuestDecisionLink>[];
    final questPrerequisiteLinks = version >= 5
        ? _parseList(
            json['quest_prerequisite_links'],
            _parseQuestPrerequisiteLink,
          )
        : <QuestPrerequisiteLink>[];

    return ExportSnapshot(
      exportedAt: exportedAt,
      version: version,
      profile: profile,
      preferences: preferences,
      tasks: tasks,
      events: events,
      quests: quests,
      projects: projects,
      questProjectLinks: questProjectLinks,
      decisionRecords: decisionRecords,
      questDecisionLinks: questDecisionLinks,
      questPrerequisiteLinks: questPrerequisiteLinks,
      workPriorities:
          _parseList(json['work_priorities'], _parseWorkPriority(profileId)),
      bills: _parseList(json['bills'], _parseBill(profileId)),
      scheduleBlocks:
          _parseList(json['schedule_blocks'], _parseScheduleBlock(profileId)),
      needDefinitions:
          _parseList(json['need_definitions'], _parseNeedDefinition(profileId)),
      needReadings: _parseList(json['need_readings'], _parseNeedReading),
      checkIns: _parseList(json['check_ins'], _parseCheckIn(profileId)),
      dailyReviews: version >= 6
          ? _parseList(json['daily_reviews'], _parseDailyReview(profileId))
          : <DailyReview>[],
      moodFactors: version >= 6
          ? _parseList(json['mood_factors'], _parseMoodFactor)
          : <MoodFactor>[],
      weeklyReviews: version >= 7
          ? _parseList(json['weekly_reviews'], _parseWeeklyReview(profileId))
          : <WeeklyReview>[],
      researchNodes: version >= 9
          ? _parseList(json['research_nodes'], _parseResearchNode(profileId))
          : <ResearchNode>[],
      researchPrerequisiteLinks: version >= 9
          ? _parseList(
              json['research_prerequisite_links'],
              _parseResearchPrerequisiteLink,
            )
          : <ResearchPrerequisiteLink>[],
      questResearchLinks: version >= 12
          ? _parseList(json['quest_research_links'], _parseQuestResearchLink)
          : <QuestResearchLink>[],
      learningSessions: version >= 10
          ? _parseList(json['learning_sessions'], _parseLearningSession(profileId))
          : <LearningSession>[],
      researchEvidence: version >= 10
          ? _parseList(json['research_evidence'], _parseResearchEvidence(profileId))
          : <ResearchEvidence>[],
      financialEntities: version >= 11
          ? _parseList(json['financial_entities'], _parseFinancialEntity(profileId))
          : <FinancialEntity>[],
      financialAccounts: version >= 11
          ? _parseList(json['financial_accounts'], _parseFinancialAccount(profileId))
          : <FinancialAccount>[],
      transactions: version >= 11
          ? _parseList(json['transactions'], _parseLedgerTransaction(profileId))
          : <LedgerTransaction>[],
      healthConditions: version >= 13
          ? _parseList(json['health_conditions'], _parseHealthCondition(profileId))
          : <HealthCondition>[],
      symptomEntries: version >= 14
          ? _parseList(json['symptom_entries'], _parseSymptomEntry(profileId))
          : <SymptomEntry>[],
      inventoryItems: version >= 15
          ? _parseList(json['inventory_items'], _parseInventoryItem(profileId))
          : <InventoryItem>[],
      people: version >= 16
          ? _parseList(json['people'], _parsePerson(profileId))
          : <Person>[],
      categoryBudgets: version >= 17
          ? _parseList(json['category_budgets'], _parseCategoryBudget(profileId))
          : <CategoryBudget>[],
      personInteractions: version >= 18
          ? _parseList(
              json['person_interactions'],
              _parsePersonInteraction(profileId),
            )
          : <PersonInteraction>[],
      trips: version >= 19
          ? _parseList(json['trips'], _parseTrip(profileId))
          : <Trip>[],
      organizations: version >= 20
          ? _parseList(json['organizations'], _parseOrganization(profileId))
          : <Organization>[],
      personOrganizationLinks: version >= 21
          ? _parseList(
              json['person_organization_links'],
              _parsePersonOrganizationLink,
            )
          : <PersonOrganizationLink>[],
      homeMaintenanceTasks: version >= 22
          ? _parseList(
              json['home_maintenance_tasks'],
              _parseHomeMaintenanceTask(profileId),
            )
          : <HomeMaintenanceTask>[],
      questInventoryLinks: version >= 23
          ? _parseList(json['quest_inventory_links'], _parseQuestInventoryLink)
          : <QuestInventoryLink>[],
      commitments: version >= 24
          ? _parseList(json['commitments'], _parseCommitment(profileId))
          : <Commitment>[],
      contextZones: version >= 25
          ? _parseList(json['context_zones'], _parseContextZone(profileId))
          : <ContextZone>[],
      integrationConsents: version >= 26
          ? _parseList(
              json['integration_consents'],
              _parseIntegrationConsent(profileId),
            )
          : <IntegrationConsent>[],
      externalCalendarEvents: version >= 26
          ? _parseList(
              json['external_calendar_events'],
              _parseExternalCalendarEvent(profileId),
            )
          : <ExternalCalendarEvent>[],
      zoneTripLinks: version >= 27
          ? _parseList(json['zone_trip_links'], _parseZoneTripLink)
          : <ZoneTripLink>[],
      healthAppointments: version >= 28
          ? _parseList(
              json['health_appointments'],
              _parseHealthAppointment(profileId),
            )
          : <HealthAppointment>[],
      tripInventoryLinks: version >= 29
          ? _parseList(json['trip_inventory_links'], _parseTripInventoryLink)
          : <TripInventoryLink>[],
      knowledgeAreas: version >= 30
          ? _parseList(json['knowledge_areas'], _parseKnowledgeArea(profileId))
          : <KnowledgeArea>[],
      flashcardDecks: version >= 30
          ? _parseList(json['flashcard_decks'], _parseFlashcardDeck(profileId))
          : <FlashcardDeck>[],
      flashcards: version >= 30
          ? _parseList(json['flashcards'], _parseFlashcard(profileId))
          : <Flashcard>[],
      flashcardSrs: version >= 30
          ? _parseList(json['flashcard_srs'], _parseFlashcardSrs)
          : <FlashcardSrsState>[],
      flashcardReviewLogs: version >= 30
          ? _parseList(
              json['flashcard_review_logs'],
              _parseFlashcardReviewLog,
            )
          : <FlashcardReviewLog>[],
      knowledgeAreaPlacements: version >= 31
          ? _parseList(
              json['knowledge_area_placements'],
              _parseKnowledgeAreaPlacement,
            )
          : <KnowledgeAreaPlacement>[],
      researchKnowledgeLinks: version >= 31
          ? _parseList(
              json['research_knowledge_links'],
              _parseResearchKnowledgeLink,
            )
          : <ResearchKnowledgeLink>[],
      googleTimelineImport: version >= 33
          ? _parseGoogleTimelineImport(json['google_timeline_import'])
          : null,
      googleTimelinePlaceLabels: version >= 33
          ? _parseList(
              json['google_timeline_place_labels'],
              _parseTimelinePlaceLabel,
            )
          : <TimelinePlaceLabel>[],
    );
  }

  static List<T> _parseList<T>(
    Object? raw,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (raw == null) return [];
    if (raw is! List) {
      throw ExportSnapshotException('Esperada lista JSON');
    }
    return raw.map((item) {
      if (item is! Map<String, dynamic>) {
        throw ExportSnapshotException('Item de lista deve ser objeto');
      }
      return parse(item);
    }).toList();
  }

  static List<String> _parseStringList(Object? raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }

  static DateTime _parseDateTime(String value) {
    return DateTime.parse(value).toUtc();
  }

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw ExportSnapshotException('Campo obrigatório ausente: $key');
    }
    return value;
  }

  static int _requireInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ExportSnapshotException('Campo numérico inválido: $key');
  }

  static int? _optionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _requireBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw ExportSnapshotException('Campo booleano inválido: $key');
    }
    return value;
  }

  static Map<String, dynamic> _requireMap(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! Map<String, dynamic>) {
      throw ExportSnapshotException('Objeto obrigatório ausente: $key');
    }
    return value;
  }

  static ColonyTask Function(Map<String, dynamic>) _parseTask(EntityId profileId) {
    return (json) {
      return ColonyTask(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        title: _requireString(json, 'title'),
        description: json['description'] as String?,
        status: TaskStatus.values.byName(_requireString(json, 'status')),
        sourceType: SourceType.values.byName(_requireString(json, 'source_type')),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
        completedAt: json['completed_at'] == null
            ? null
            : _parseDateTime(json['completed_at'] as String),
        questId: json['quest_id'] == null
            ? null
            : EntityId(json['quest_id'] as String),
      );
    };
  }

  static DomainEvent _parseEvent(Map<String, dynamic> json) {
    return DomainEvent(
      id: EntityId(_requireString(json, 'id')),
      aggregateType:
          AggregateType.values.byName(_requireString(json, 'aggregate_type')),
      aggregateId: EntityId(_requireString(json, 'aggregate_id')),
      eventType: EventType.values.byName(_requireString(json, 'event_type')),
      occurredAt: _parseDateTime(_requireString(json, 'occurred_at')),
      recordedAt: _parseDateTime(_requireString(json, 'occurred_at')),
      sourceType: SourceType.system,
      payloadVersion: 1,
      payload: (json['payload'] as Map?)?.cast<String, Object?>() ?? const {},
      privacyClass: PrivacyClass.personal,
    );
  }

  static Quest Function(Map<String, dynamic>) _parseQuest(EntityId profileId) {
    return (json) {
      return Quest(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        title: _requireString(json, 'title'),
        purpose: _requireString(json, 'purpose'),
        successCriteria: _parseStringList(json['success_criteria']),
        risks: _parseStringList(json['risks']),
        deadline: json['deadline'] == null
            ? null
            : _parseDateTime(json['deadline'] as String),
        status: QuestStatus.values.byName(_requireString(json, 'status')),
        exitReason: json['exit_reason'] as String?,
        pauseReason: json['pause_reason'] as String?,
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
        completedAt: json['completed_at'] == null
            ? null
            : _parseDateTime(json['completed_at'] as String),
        acceptedAt: json['accepted_at'] == null
            ? null
            : _parseDateTime(json['accepted_at'] as String),
        acceptanceDeadline: json['acceptance_deadline'] == null
            ? null
            : _parseDateTime(json['acceptance_deadline'] as String),
        acceptanceAssumptions:
            _parseStringList(json['acceptance_assumptions']),
      );
    };
  }

  static Project Function(Map<String, dynamic>) _parseProject(EntityId profileId) {
    return (json) {
      return Project(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        title: _requireString(json, 'title'),
        purpose: json['purpose'] as String?,
        status: ProjectStatus.values.byName(_requireString(json, 'status')),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static QuestProjectLink _parseQuestProjectLink(Map<String, dynamic> json) {
    return QuestProjectLink(
      questId: EntityId(_requireString(json, 'quest_id')),
      projectId: EntityId(_requireString(json, 'project_id')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
    );
  }

  static QuestResearchLink _parseQuestResearchLink(Map<String, dynamic> json) {
    return QuestResearchLink(
      questId: EntityId(_requireString(json, 'quest_id')),
      researchNodeId: EntityId(_requireString(json, 'research_node_id')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
    );
  }

  static DecisionRecord Function(Map<String, dynamic>) _parseDecisionRecord(
    EntityId profileId,
  ) {
    return (json) {
      return DecisionRecord(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        title: _requireString(json, 'title'),
        context: _requireString(json, 'context'),
        decision: _requireString(json, 'decision'),
        alternatives: _parseStringList(json['alternatives']),
        criteria: _parseStringList(json['criteria']),
        assumptions: _parseStringList(json['assumptions']),
        expectedOutcomes: _parseStringList(json['expected_outcomes']),
        risks: _parseStringList(json['risks']),
        reversibility: DecisionReversibility.values
            .byName(_requireString(json, 'reversibility')),
        decidedAt: _parseDateTime(_requireString(json, 'decided_at')),
        reviewAt: json['review_at'] == null
            ? null
            : _parseDateTime(json['review_at'] as String),
        outcomeReview: json['outcome_review'] as String?,
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static QuestDecisionLink _parseQuestDecisionLink(Map<String, dynamic> json) {
    return QuestDecisionLink(
      questId: EntityId(_requireString(json, 'quest_id')),
      decisionId: EntityId(_requireString(json, 'decision_id')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
    );
  }

  static QuestPrerequisiteLink _parseQuestPrerequisiteLink(
    Map<String, dynamic> json,
  ) {
    return QuestPrerequisiteLink(
      questId: EntityId(_requireString(json, 'quest_id')),
      prerequisiteQuestId: EntityId(_requireString(json, 'prerequisite_quest_id')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
    );
  }

  static ResearchPrerequisiteLink _parseResearchPrerequisiteLink(
    Map<String, dynamic> json,
  ) {
    return ResearchPrerequisiteLink(
      nodeId: EntityId(_requireString(json, 'node_id')),
      prerequisiteNodeId:
          EntityId(_requireString(json, 'prerequisite_node_id')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
    );
  }

  static ResearchNode Function(Map<String, dynamic>) _parseResearchNode(
    EntityId profileId,
  ) {
    return (json) {
      return ResearchNode(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        title: _requireString(json, 'title'),
        description: json['description'] as String?,
        type: ResearchNodeType.values.byName(_requireString(json, 'type')),
        status: ResearchNodeStatus.values.byName(_requireString(json, 'status')),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
        demonstratedNote: json['demonstrated_note'] as String?,
        version: json['version'] as int? ?? 1,
      );
    };
  }

  static LearningSession Function(Map<String, dynamic>) _parseLearningSession(
    EntityId profileId,
  ) {
    return (json) {
      return LearningSession(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        nodeId: EntityId(_requireString(json, 'node_id')),
        startedAt: _parseDateTime(_requireString(json, 'started_at')),
        durationMinutes: _requireInt(json, 'duration_minutes'),
        mode: LearningSessionMode.values.byName(_requireString(json, 'mode')),
        notes: json['notes'] as String?,
      );
    };
  }

  static ResearchEvidence Function(Map<String, dynamic>) _parseResearchEvidence(
    EntityId profileId,
  ) {
    return (json) {
      return ResearchEvidence(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        nodeId: EntityId(_requireString(json, 'node_id')),
        sessionId: json['session_id'] == null
            ? null
            : EntityId(json['session_id'] as String),
        type: ResearchEvidenceType.values.byName(_requireString(json, 'type')),
        title: _requireString(json, 'title'),
        body: _requireString(json, 'body'),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
      );
    };
  }

  static FinancialEntity Function(Map<String, dynamic>) _parseFinancialEntity(
    EntityId profileId,
  ) {
    return (json) {
      return FinancialEntity(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        name: _requireString(json, 'name'),
        kind: FinancialEntityKind.values.byName(_requireString(json, 'kind')),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static FinancialAccount Function(Map<String, dynamic>) _parseFinancialAccount(
    EntityId profileId,
  ) {
    return (json) {
      return FinancialAccount(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        entityId: EntityId(_requireString(json, 'entity_id')),
        institution: _requireString(json, 'institution'),
        name: _requireString(json, 'name'),
        type: FinancialAccountType.values.byName(_requireString(json, 'type')),
        currency: _requireString(json, 'currency'),
        currentBalanceMinor: _requireInt(json, 'current_balance_minor'),
        balanceAsOf: json['balance_as_of'] == null
            ? null
            : _parseDateTime(json['balance_as_of'] as String),
        includeInNetWorth: json['include_in_net_worth'] as bool? ?? true,
        sensitiveDisplayMode: SensitiveDisplayMode.values.byName(
          _requireString(json, 'sensitive_display_mode'),
        ),
        isArchived: json['is_archived'] as bool? ?? false,
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static LedgerTransaction Function(Map<String, dynamic>) _parseLedgerTransaction(
    EntityId profileId,
  ) {
    return (json) {
      return LedgerTransaction(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        accountId: EntityId(_requireString(json, 'account_id')),
        occurredAt: _parseDateTime(_requireString(json, 'occurred_at')),
        descriptionOriginal: _requireString(json, 'description_original'),
        amountMinor: _requireInt(json, 'amount_minor'),
        currency: _requireString(json, 'currency'),
        direction:
            TransactionDirection.values.byName(_requireString(json, 'direction')),
        categoryId: json['category_id'] == null
            ? null
            : EntityId(json['category_id'] as String),
        notes: json['notes'] as String?,
        fingerprint: _requireString(json, 'fingerprint'),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static HealthCondition Function(Map<String, dynamic>) _parseHealthCondition(
    EntityId profileId,
  ) {
    return (json) {
      return HealthCondition(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        title: _requireString(json, 'title'),
        type: HealthConditionType.values.byName(_requireString(json, 'type')),
        status:
            HealthConditionStatus.values.byName(_requireString(json, 'status')),
        onsetAt: json['onset_at'] == null
            ? null
            : _parseDateTime(json['onset_at'] as String),
        resolvedAt: json['resolved_at'] == null
            ? null
            : _parseDateTime(json['resolved_at'] as String),
        severityUserReported: json['severity_user_reported'] as int?,
        bodyRegions: _parseStringList(json['body_regions']),
        clinicianConfirmed: json['clinician_confirmed'] as bool? ?? false,
        notes: json['notes'] as String?,
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static SymptomEntry Function(Map<String, dynamic>) _parseSymptomEntry(
    EntityId profileId,
  ) {
    return (json) {
      return SymptomEntry(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        conditionId: json['condition_id'] == null
            ? null
            : EntityId(json['condition_id'] as String),
        occurredAt: _parseDateTime(_requireString(json, 'occurred_at')),
        intensity: _requireInt(json, 'intensity'),
        note: json['note'] as String?,
        bodyRegion: json['body_region'] as String?,
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
      );
    };
  }

  static InventoryItem Function(Map<String, dynamic>) _parseInventoryItem(
    EntityId profileId,
  ) {
    return (json) {
      return InventoryItem(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        name: _requireString(json, 'name'),
        category:
            InventoryCategory.values.byName(_requireString(json, 'category')),
        status:
            InventoryItemStatus.values.byName(_requireString(json, 'status')),
        locationLabel: json['location_label'] as String?,
        notes: json['notes'] as String?,
        tags: _parseStringList(json['tags']),
        purchaseDate: json['purchase_date'] == null
            ? null
            : _parseDateTime(json['purchase_date'] as String),
        purchasePriceMinor: json['purchase_price_minor'] as int?,
        purchaseCurrency: json['purchase_currency'] as String?,
        warrantyEnd: json['warranty_end'] == null
            ? null
            : _parseDateTime(json['warranty_end'] as String),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static Person Function(Map<String, dynamic>) _parsePerson(EntityId profileId) {
    return (json) {
      return Person(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        displayName: _requireString(json, 'display_name'),
        preferredName: json['preferred_name'] as String?,
        relationshipTypes: _parseStringList(json['relationship_types']),
        notes: json['notes'] as String?,
        birthday: json['birthday'] == null
            ? null
            : _parseDateTime(json['birthday'] as String),
        lastInteractionAt: json['last_interaction_at'] == null
            ? null
            : _parseDateTime(json['last_interaction_at'] as String),
        nextFollowUpAt: json['next_follow_up_at'] == null
            ? null
            : _parseDateTime(json['next_follow_up_at'] as String),
        archivedAt: json['archived_at'] == null
            ? null
            : _parseDateTime(json['archived_at'] as String),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static CategoryBudget Function(Map<String, dynamic>) _parseCategoryBudget(
    EntityId profileId,
  ) {
    return (json) {
      return CategoryBudget(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        categoryId: EntityId(_requireString(json, 'category_id')),
        currency: _requireString(json, 'currency'),
        limitAmountMinor: _requireInt(json, 'limit_amount_minor'),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static PersonInteraction Function(Map<String, dynamic>)
      _parsePersonInteraction(EntityId profileId) {
    return (json) {
      return PersonInteraction(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        personId: EntityId(_requireString(json, 'person_id')),
        kind: InteractionKind.values.byName(_requireString(json, 'kind')),
        occurredAt: _parseDateTime(_requireString(json, 'occurred_at')),
        note: json['note'] as String?,
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
      );
    };
  }

  static Trip Function(Map<String, dynamic>) _parseTrip(EntityId profileId) {
    return (json) {
      return Trip(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        title: _requireString(json, 'title'),
        destinations: _parseStringList(json['destinations']),
        startAt: json['start_at'] == null
            ? null
            : _parseDateTime(json['start_at'] as String),
        endAt: json['end_at'] == null
            ? null
            : _parseDateTime(json['end_at'] as String),
        purpose: json['purpose'] as String?,
        notes: json['notes'] as String?,
        status: TripStatus.values.byName(_requireString(json, 'status')),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static Organization Function(Map<String, dynamic>) _parseOrganization(
    EntityId profileId,
  ) {
    return (json) {
      return Organization(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        name: _requireString(json, 'name'),
        kind: OrganizationKind.values.byName(_requireString(json, 'kind')),
        notes: json['notes'] as String?,
        archivedAt: json['archived_at'] == null
            ? null
            : _parseDateTime(json['archived_at'] as String),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static PersonOrganizationLink _parsePersonOrganizationLink(
    Map<String, dynamic> json,
  ) {
    final role = json['role'] as String?;
    return PersonOrganizationLink(
      personId: EntityId(_requireString(json, 'person_id')),
      organizationId: EntityId(_requireString(json, 'organization_id')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
      role: (role == null || role.trim().isEmpty) ? null : role.trim(),
    );
  }

  static HomeMaintenanceTask Function(Map<String, dynamic>)
      _parseHomeMaintenanceTask(EntityId profileId) {
    return (json) {
      return HomeMaintenanceTask(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        title: _requireString(json, 'title'),
        systemOrItem: _requireString(json, 'system_or_item'),
        cadenceDays: json['cadence_days'] as int?,
        nextDueAt: json['next_due_at'] == null
            ? null
            : _parseDateTime(json['next_due_at'] as String),
        lastDoneAt: json['last_done_at'] == null
            ? null
            : _parseDateTime(json['last_done_at'] as String),
        vendorLabel: json['vendor_label'] as String?,
        estimatedCostMinor: json['estimated_cost_minor'] as int?,
        currency: json['currency'] as String?,
        notes: json['notes'] as String?,
        linkedInventoryItemId: json['linked_inventory_item_id'] == null
            ? null
            : EntityId(json['linked_inventory_item_id'] as String),
        archivedAt: json['archived_at'] == null
            ? null
            : _parseDateTime(json['archived_at'] as String),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static Commitment Function(Map<String, dynamic>) _parseCommitment(
    EntityId profileId,
  ) {
    return (json) {
      return Commitment(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        description: _requireString(json, 'description'),
        madeByLabel: _requireString(json, 'made_by_label'),
        madeToPersonId: json['made_to_person_id'] == null
            ? null
            : EntityId(json['made_to_person_id'] as String),
        madeToOrganizationId: json['made_to_organization_id'] == null
            ? null
            : EntityId(json['made_to_organization_id'] as String),
        madeToLabel: json['made_to_label'] as String?,
        dueAt: json['due_at'] == null
            ? null
            : _parseDateTime(json['due_at'] as String),
        status: CommitmentStatus.values.byName(_requireString(json, 'status')),
        notes: json['notes'] as String?,
        linkedQuestId: json['linked_quest_id'] == null
            ? null
            : EntityId(json['linked_quest_id'] as String),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static ContextZone Function(Map<String, dynamic>) _parseContextZone(
    EntityId profileId,
  ) {
    return (json) {
      return ContextZone(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        name: _requireString(json, 'name'),
        locationLabel: json['location_label'] as String?,
        capabilities: _parseStringList(json['capabilities']),
        unavailableWorkTypes: _parseStringList(json['unavailable_work_types']),
        connectivity: ZoneConnectivity.values
            .byName(_requireString(json, 'connectivity')),
        notes: json['notes'] as String?,
        archivedAt: json['archived_at'] == null
            ? null
            : _parseDateTime(json['archived_at'] as String),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static IntegrationConsent Function(Map<String, dynamic>)
      _parseIntegrationConsent(EntityId profileId) {
    return (json) {
      return IntegrationConsent(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        kind: IntegrationKind.values.byName(_requireString(json, 'kind')),
        enabled: json['enabled'] == true,
        grantedAt: json['granted_at'] == null
            ? null
            : _parseDateTime(json['granted_at'] as String),
        revokedAt: json['revoked_at'] == null
            ? null
            : _parseDateTime(json['revoked_at'] as String),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static ExternalCalendarEvent Function(Map<String, dynamic>)
      _parseExternalCalendarEvent(EntityId profileId) {
    return (json) {
      return ExternalCalendarEvent(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        externalUid: json['external_uid'] as String?,
        title: _requireString(json, 'title'),
        startAt: _parseDateTime(_requireString(json, 'start_at')),
        endAt: _parseDateTime(_requireString(json, 'end_at')),
        sourceType: SourceType.values.byName(
          _requireString(json, 'source_type'),
        ),
        importedAt: _parseDateTime(_requireString(json, 'imported_at')),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static QuestInventoryLink _parseQuestInventoryLink(Map<String, dynamic> json) {
    return QuestInventoryLink(
      questId: EntityId(_requireString(json, 'quest_id')),
      inventoryItemId: EntityId(_requireString(json, 'inventory_item_id')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
    );
  }

  static ZoneTripLink _parseZoneTripLink(Map<String, dynamic> json) {
    return ZoneTripLink(
      zoneId: EntityId(_requireString(json, 'zone_id')),
      tripId: EntityId(_requireString(json, 'trip_id')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
    );
  }

  static TripInventoryLink _parseTripInventoryLink(Map<String, dynamic> json) {
    return TripInventoryLink(
      tripId: EntityId(_requireString(json, 'trip_id')),
      inventoryItemId: EntityId(_requireString(json, 'inventory_item_id')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
    );
  }

  static KnowledgeArea Function(Map<String, dynamic>) _parseKnowledgeArea(
    EntityId profileId,
  ) {
    return (json) {
      return KnowledgeArea(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        parentId: json['parent_id'] == null
            ? null
            : EntityId(_requireString(json, 'parent_id')),
        title: _requireString(json, 'title'),
        slug: _requireString(json, 'slug'),
        description: json['description'] as String?,
        iconKey: json['icon_key'] as String?,
        catalogKey: json['catalog_key'] as String?,
        sortOrder: _requireInt(json, 'sort_order'),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static FlashcardDeck Function(Map<String, dynamic>) _parseFlashcardDeck(
    EntityId profileId,
  ) {
    return (json) {
      return FlashcardDeck(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        areaId: json['area_id'] == null
            ? null
            : EntityId(_requireString(json, 'area_id')),
        researchNodeId: json['research_node_id'] == null
            ? null
            : EntityId(_requireString(json, 'research_node_id')),
        title: _requireString(json, 'title'),
        description: json['description'] as String?,
        newLimitPerDay: _requireInt(json, 'new_limit_per_day'),
        reviewLimitPerDay: _requireInt(json, 'review_limit_per_day'),
        archivedAt: json['archived_at'] == null
            ? null
            : _parseDateTime(json['archived_at'] as String),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
        version: json['version'] as int? ?? 1,
      );
    };
  }

  static Flashcard Function(Map<String, dynamic>) _parseFlashcard(
    EntityId profileId,
  ) {
    return (json) {
      return Flashcard(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        deckId: EntityId(_requireString(json, 'deck_id')),
        areaId: json['area_id'] == null
            ? null
            : EntityId(_requireString(json, 'area_id')),
        kind: FlashcardKind.values.byName(_requireString(json, 'kind')),
        front: _requireString(json, 'front'),
        back: json['back'] as String? ?? '',
        extra: json['extra'] as String?,
        tags: _parseStringList(json['tags']),
        clozeIndex: json['cloze_index'] as int?,
        reverseOfId: json['reverse_of_id'] == null
            ? null
            : EntityId(_requireString(json, 'reverse_of_id')),
        scheduleMode: FlashcardScheduleMode.values.byName(
          json['schedule_mode'] as String? ?? 'scheduled',
        ),
        priority: FlashcardPolicy.normalizePriority(
          _optionalInt(json, 'priority'),
        ),
        suspended: json['suspended'] as bool? ?? false,
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
        version: json['version'] as int? ?? 1,
      );
    };
  }

  static FlashcardSrsState _parseFlashcardSrs(Map<String, dynamic> json) {
    return FlashcardSrsState(
      cardId: EntityId(_requireString(json, 'card_id')),
      status: FlashcardSrsStatus.values.byName(_requireString(json, 'status')),
      easeFactor: (json['ease_factor'] as num).toDouble(),
      intervalDays: (json['interval_days'] as num).toDouble(),
      repetitions: _requireInt(json, 'repetitions'),
      lapses: _requireInt(json, 'lapses'),
      learningStepIndex: _requireInt(json, 'learning_step_index'),
      leech: json['leech'] as bool? ?? false,
      dueAt: _parseDateTime(_requireString(json, 'due_at')),
      lastReviewedAt: json['last_reviewed_at'] == null
          ? null
          : _parseDateTime(json['last_reviewed_at'] as String),
    );
  }

  static FlashcardReviewLog _parseFlashcardReviewLog(Map<String, dynamic> json) {
    return FlashcardReviewLog(
      id: EntityId(_requireString(json, 'id')),
      cardId: EntityId(_requireString(json, 'card_id')),
      reviewedAt: _parseDateTime(_requireString(json, 'reviewed_at')),
      rating: FlashcardRating.values.byName(_requireString(json, 'rating')),
      intervalDaysBefore: (json['interval_days_before'] as num).toDouble(),
      intervalDaysAfter: (json['interval_days_after'] as num).toDouble(),
      easeBefore: (json['ease_before'] as num).toDouble(),
      easeAfter: (json['ease_after'] as num).toDouble(),
      durationMs: json['duration_ms'] as int?,
      reviewKind: FlashcardReviewKind.values.byName(
        json['review_kind'] as String? ?? 'srs',
      ),
    );
  }

  static KnowledgeAreaPlacement _parseKnowledgeAreaPlacement(
    Map<String, dynamic> json,
  ) {
    return KnowledgeAreaPlacement(
      areaId: EntityId(_requireString(json, 'area_id')),
      parentAreaId: EntityId(_requireString(json, 'parent_area_id')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
      catalogKey: json['catalog_key'] as String?,
    );
  }

  static ResearchKnowledgeLink _parseResearchKnowledgeLink(
    Map<String, dynamic> json,
  ) {
    return ResearchKnowledgeLink(
      researchNodeId: EntityId(_requireString(json, 'research_node_id')),
      areaId: EntityId(_requireString(json, 'area_id')),
      kind: ResearchKnowledgeLinkKind.values.byName(_requireString(json, 'kind')),
      linkedAt: _parseDateTime(_requireString(json, 'linked_at')),
    );
  }

  static GoogleTimelineImport? _parseGoogleTimelineImport(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      throw ExportSnapshotException(
        'google_timeline_import deve ser um objeto',
      );
    }
    final documentRaw = raw['document'];
    if (documentRaw is! Map<String, dynamic>) {
      throw ExportSnapshotException(
        'google_timeline_import.document deve ser um objeto',
      );
    }
    return GoogleTimelineImport(
      id: EntityId(_requireString(raw, 'id')),
      profileId: EntityId(_requireString(raw, 'profile_id')),
      fileName: _requireString(raw, 'file_name'),
      importedAt: _parseDateTime(_requireString(raw, 'imported_at')),
      document: GoogleTimelineDocument.fromJson(documentRaw),
    );
  }

  static TimelinePlaceLabel _parseTimelinePlaceLabel(Map<String, dynamic> json) {
    return TimelinePlaceLabel(
      placeId: _requireString(json, 'place_id'),
      category: TimelinePlaceCategory.values.byName(
        _requireString(json, 'category'),
      ),
      customName: json['custom_name'] as String?,
    );
  }

  static HealthAppointment Function(Map<String, dynamic>)
      _parseHealthAppointment(EntityId profileId) {
    return (json) {
      return HealthAppointment(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        title: _requireString(json, 'title'),
        scheduledAt: _parseDateTime(_requireString(json, 'scheduled_at')),
        locationLabel: json['location_label'] as String?,
        clinicianLabel: json['clinician_label'] as String?,
        notes: json['notes'] as String?,
        status: HealthAppointmentStatus.values
            .byName(_requireString(json, 'status')),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static WorkPriority Function(Map<String, dynamic>) _parseWorkPriority(
    EntityId profileId,
  ) {
    return (json) {
      return WorkPriority(
        profileId: profileId,
        workType: WorkType.values.byName(_requireString(json, 'work_type')),
        level: PriorityLevel.values.byName(_requireString(json, 'level')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static Bill Function(Map<String, dynamic>) _parseBill(EntityId profileId) {
    return (json) {
      return Bill(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        title: _requireString(json, 'title'),
        repeatMode: BillRepeatMode.values.byName(_requireString(json, 'repeat_mode')),
        target: _requireString(json, 'target'),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static ScheduleBlock Function(Map<String, dynamic>) _parseScheduleBlock(
    EntityId profileId,
  ) {
    return (json) {
      return ScheduleBlock(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        startAt: _parseDateTime(_requireString(json, 'start_at')),
        endAt: _parseDateTime(_requireString(json, 'end_at')),
        mode: ScheduleBlockMode.values.byName(_requireString(json, 'mode')),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        updatedAt: _parseDateTime(_requireString(json, 'updated_at')),
      );
    };
  }

  static NeedDefinition Function(Map<String, dynamic>) _parseNeedDefinition(
    EntityId profileId,
  ) {
    return (json) {
      final now = DateTime.utc(2026, 1, 1);
      return NeedDefinition(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        name: _requireString(json, 'name'),
        slug: _requireString(json, 'slug'),
        calculationMode: CalculationMode.values
            .byName(_requireString(json, 'calculation_mode')),
        privacyClass: NeedPrivacyClass.standard,
        isEnabled: json['is_enabled'] as bool? ?? true,
        sortOrder: json['sort_order'] as int? ?? 0,
        createdAt: now,
        updatedAt: now,
      );
    };
  }

  static NeedReading _parseNeedReading(Map<String, dynamic> json) {
    return NeedReading.manual(
      id: EntityId(_requireString(json, 'id')),
      needId: EntityId(_requireString(json, 'need_id')),
      normalizedValue: (json['normalized_value'] as num?)?.toDouble() ?? 0.5,
      observedAt: _parseDateTime(_requireString(json, 'observed_at')),
      createdAt: _parseDateTime(_requireString(json, 'observed_at')),
      note: json['note'] as String?,
    );
  }

  static CheckIn Function(Map<String, dynamic>) _parseCheckIn(EntityId profileId) {
    return (json) {
      final observedAt = _parseDateTime(_requireString(json, 'observed_at'));
      return CheckIn(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        observedAt: observedAt,
        createdAt: observedAt,
        mood: (json['mood'] as num).toDouble(),
        energy: (json['energy'] as num).toDouble(),
        tension: (json['tension'] as num).toDouble(),
        focus: (json['focus'] as num).toDouble(),
        note: json['note'] as String?,
      );
    };
  }

  static DailyReview Function(Map<String, dynamic>) _parseDailyReview(
    EntityId profileId,
  ) {
    return (json) {
      return DailyReview(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        reviewDate: _parseDateTime(_requireString(json, 'review_date')),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        whatHappened: json['what_happened'] as String?,
        currentState: json['current_state'] as String?,
        tomorrowCommitments: json['tomorrow_commitments'] as String?,
        routeCorrection: json['route_correction'] as String?,
      );
    };
  }

  static MoodFactor _parseMoodFactor(Map<String, dynamic> json) {
    return MoodFactor(
      id: EntityId(_requireString(json, 'id')),
      checkInId: EntityId(_requireString(json, 'check_in_id')),
      label: _requireString(json, 'label'),
      kind: MoodFactorKind.values.byName(_requireString(json, 'kind')),
      impact: json['impact'] as int?,
      uncertain: json['uncertain'] as bool? ?? false,
    );
  }

  static WeeklyReview Function(Map<String, dynamic>) _parseWeeklyReview(
    EntityId profileId,
  ) {
    return (json) {
      return WeeklyReview(
        id: EntityId(_requireString(json, 'id')),
        profileId: profileId,
        weekStartDate: _parseDateTime(_requireString(json, 'week_start_date')),
        createdAt: _parseDateTime(_requireString(json, 'created_at')),
        facts: json['facts'] as String?,
        wins: json['wins'] as String?,
        problems: json['problems'] as String?,
        projects: json['projects'] as String?,
        learning: json['learning'] as String?,
        nextWeek: json['next_week'] as String?,
      );
    };
  }

  Map<String, Object?> toJson() {
    return {
      'exported_at': exportedAt.toUtc().toIso8601String(),
      'version': version,
      'profile': {
        'id': profile.id.value,
        'colony_name': profile.colonyName,
        'display_name': profile.displayName,
        'timezone': profile.timezone,
        'locale': profile.locale,
        'base_currency': profile.baseCurrency,
        'created_at': profile.createdAt.toUtc().toIso8601String(),
        'updated_at': profile.updatedAt.toUtc().toIso8601String(),
      },
      'preferences': {
        'density_mode': preferences.densityMode.name,
        'theme_mode': preferences.themeMode.name,
        'week_starts_on_monday': preferences.weekStartsOnMonday,
        'use_24_hour_format': preferences.use24HourFormat,
        'sectors_enabled': preferences.sectorsEnabled,
        'onboarding_completed': preferences.onboardingCompleted,
      },
      'tasks': tasks.map(_taskJson).toList(),
      'events': events.map(_eventJson).toList(),
      'quests': quests.map(_questJson).toList(),
      'projects': projects.map(_projectJson).toList(),
      'quest_project_links': questProjectLinks.map(_questProjectLinkJson).toList(),
      'decision_records': decisionRecords.map(_decisionRecordJson).toList(),
      'quest_decision_links': questDecisionLinks.map(_questDecisionLinkJson).toList(),
      'quest_prerequisite_links':
          questPrerequisiteLinks.map(_questPrerequisiteLinkJson).toList(),
      'work_priorities': workPriorities.map(_workPriorityJson).toList(),
      'bills': bills.map(_billJson).toList(),
      'schedule_blocks': scheduleBlocks.map(_scheduleBlockJson).toList(),
      'need_definitions': needDefinitions.map(_needDefinitionJson).toList(),
      'need_readings': needReadings.map(_needReadingJson).toList(),
      'check_ins': checkIns.map(_checkInJson).toList(),
      'daily_reviews': dailyReviews.map(_dailyReviewJson).toList(),
      'mood_factors': moodFactors.map(_moodFactorJson).toList(),
      'weekly_reviews': weeklyReviews.map(_weeklyReviewJson).toList(),
      'research_nodes': researchNodes.map(_researchNodeJson).toList(),
      'research_prerequisite_links':
          researchPrerequisiteLinks.map(_researchPrerequisiteLinkJson).toList(),
      'quest_research_links':
          questResearchLinks.map(_questResearchLinkJson).toList(),
      'learning_sessions': learningSessions.map(_learningSessionJson).toList(),
      'research_evidence': researchEvidence.map(_researchEvidenceJson).toList(),
      'financial_entities': financialEntities.map(_financialEntityJson).toList(),
      'financial_accounts': financialAccounts.map(_financialAccountJson).toList(),
      'transactions': transactions.map(_ledgerTransactionJson).toList(),
      'health_conditions': healthConditions.map(_healthConditionJson).toList(),
      'symptom_entries': symptomEntries.map(_symptomEntryJson).toList(),
      'inventory_items': inventoryItems.map(_inventoryItemJson).toList(),
      'people': people.map(_personJson).toList(),
      'category_budgets': categoryBudgets.map(_categoryBudgetJson).toList(),
      'person_interactions':
          personInteractions.map(_personInteractionJson).toList(),
      'trips': trips.map(_tripJson).toList(),
      'organizations': organizations.map(_organizationJson).toList(),
      'person_organization_links':
          personOrganizationLinks.map(_personOrganizationLinkJson).toList(),
      'home_maintenance_tasks':
          homeMaintenanceTasks.map(_homeMaintenanceTaskJson).toList(),
      'quest_inventory_links':
          questInventoryLinks.map(_questInventoryLinkJson).toList(),
      'commitments': commitments.map(_commitmentJson).toList(),
      'context_zones': contextZones.map(_contextZoneJson).toList(),
      'integration_consents':
          integrationConsents.map(_integrationConsentJson).toList(),
      'external_calendar_events':
          externalCalendarEvents.map(_externalCalendarEventJson).toList(),
      'zone_trip_links': zoneTripLinks.map(_zoneTripLinkJson).toList(),
      'health_appointments':
          healthAppointments.map(_healthAppointmentJson).toList(),
      'trip_inventory_links':
          tripInventoryLinks.map(_tripInventoryLinkJson).toList(),
      'knowledge_areas': knowledgeAreas.map(_knowledgeAreaJson).toList(),
      'flashcard_decks': flashcardDecks.map(_flashcardDeckJson).toList(),
      'flashcards': flashcards.map(_flashcardJson).toList(),
      'flashcard_srs': flashcardSrs.map(_flashcardSrsJson).toList(),
      'flashcard_review_logs':
          flashcardReviewLogs.map(_flashcardReviewLogJson).toList(),
      'knowledge_area_placements':
          knowledgeAreaPlacements.map(_knowledgeAreaPlacementJson).toList(),
      'research_knowledge_links':
          researchKnowledgeLinks.map(_researchKnowledgeLinkJson).toList(),
      if (version >= 33 && googleTimelineImport != null)
        'google_timeline_import':
            _googleTimelineImportJson(googleTimelineImport!),
      if (version >= 33)
        'google_timeline_place_labels': [
          for (final label in googleTimelinePlaceLabels)
            {
              'place_id': label.placeId,
              'category': label.category.name,
              if (label.customName != null) 'custom_name': label.customName,
            },
        ],
    };
  }

  static Map<String, Object?> _taskJson(ColonyTask task) => {
        'id': task.id.value,
        'title': task.title,
        'description': task.description,
        'status': task.status.name,
        'source_type': task.sourceType.name,
        'quest_id': task.questId?.value,
        'created_at': task.createdAt.toUtc().toIso8601String(),
        'updated_at': task.updatedAt.toUtc().toIso8601String(),
        if (task.completedAt != null)
          'completed_at': task.completedAt!.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _eventJson(DomainEvent event) => {
        'id': event.id.value,
        'aggregate_type': event.aggregateType.name,
        'aggregate_id': event.aggregateId.value,
        'event_type': event.eventType.name,
        'occurred_at': event.occurredAt.toUtc().toIso8601String(),
        'payload': event.payload,
      };

  static Map<String, Object?> _questJson(Quest quest) => {
        'id': quest.id.value,
        'title': quest.title,
        'purpose': quest.purpose,
        'success_criteria': quest.successCriteria,
        'risks': quest.risks,
        'status': quest.status.name,
        if (quest.deadline != null)
          'deadline': quest.deadline!.toUtc().toIso8601String(),
        if (quest.exitReason != null) 'exit_reason': quest.exitReason,
        if (quest.pauseReason != null) 'pause_reason': quest.pauseReason,
        'created_at': quest.createdAt.toUtc().toIso8601String(),
        'updated_at': quest.updatedAt.toUtc().toIso8601String(),
        if (quest.completedAt != null)
          'completed_at': quest.completedAt!.toUtc().toIso8601String(),
        if (quest.acceptedAt != null)
          'accepted_at': quest.acceptedAt!.toUtc().toIso8601String(),
        if (quest.acceptanceDeadline != null)
          'acceptance_deadline':
              quest.acceptanceDeadline!.toUtc().toIso8601String(),
        if (quest.acceptanceAssumptions.isNotEmpty)
          'acceptance_assumptions': quest.acceptanceAssumptions,
      };

  static Map<String, Object?> _projectJson(Project project) => {
        'id': project.id.value,
        'title': project.title,
        if (project.purpose != null) 'purpose': project.purpose,
        'status': project.status.name,
        'created_at': project.createdAt.toUtc().toIso8601String(),
        'updated_at': project.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _questProjectLinkJson(QuestProjectLink link) => {
        'quest_id': link.questId.value,
        'project_id': link.projectId.value,
        'linked_at': link.linkedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _questResearchLinkJson(QuestResearchLink link) => {
        'quest_id': link.questId.value,
        'research_node_id': link.researchNodeId.value,
        'linked_at': link.linkedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _decisionRecordJson(DecisionRecord record) => {
        'id': record.id.value,
        'title': record.title,
        'context': record.context,
        'decision': record.decision,
        'alternatives': record.alternatives,
        'criteria': record.criteria,
        'assumptions': record.assumptions,
        'expected_outcomes': record.expectedOutcomes,
        'risks': record.risks,
        'reversibility': record.reversibility.name,
        'decided_at': record.decidedAt.toUtc().toIso8601String(),
        if (record.reviewAt != null)
          'review_at': record.reviewAt!.toUtc().toIso8601String(),
        if (record.outcomeReview != null) 'outcome_review': record.outcomeReview,
        'created_at': record.createdAt.toUtc().toIso8601String(),
        'updated_at': record.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _questDecisionLinkJson(QuestDecisionLink link) => {
        'quest_id': link.questId.value,
        'decision_id': link.decisionId.value,
        'linked_at': link.linkedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _questPrerequisiteLinkJson(
    QuestPrerequisiteLink link,
  ) =>
      {
        'quest_id': link.questId.value,
        'prerequisite_quest_id': link.prerequisiteQuestId.value,
        'linked_at': link.linkedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _workPriorityJson(WorkPriority priority) => {
        'work_type': priority.workType.name,
        'level': priority.level.name,
        'updated_at': priority.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _billJson(Bill bill) => {
        'id': bill.id.value,
        'title': bill.title,
        'repeat_mode': bill.repeatMode.name,
        'target': bill.target,
        'created_at': bill.createdAt.toUtc().toIso8601String(),
        'updated_at': bill.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _scheduleBlockJson(ScheduleBlock block) => {
        'id': block.id.value,
        'start_at': block.startAt.toUtc().toIso8601String(),
        'end_at': block.endAt.toUtc().toIso8601String(),
        'mode': block.mode.name,
        'created_at': block.createdAt.toUtc().toIso8601String(),
        'updated_at': block.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _needDefinitionJson(NeedDefinition def) => {
        'id': def.id.value,
        'name': def.name,
        'slug': def.slug,
        'calculation_mode': def.calculationMode.name,
        'is_enabled': def.isEnabled,
        'sort_order': def.sortOrder,
      };

  static Map<String, Object?> _needReadingJson(NeedReading reading) => {
        'id': reading.id.value,
        'need_id': reading.needId.value,
        'observed_at': reading.observedAt.toUtc().toIso8601String(),
        'normalized_value': reading.normalizedValue,
        if (reading.note != null) 'note': reading.note,
      };

  static Map<String, Object?> _checkInJson(CheckIn checkIn) => {
        'id': checkIn.id.value,
        'observed_at': checkIn.observedAt.toUtc().toIso8601String(),
        'mood': checkIn.mood,
        'energy': checkIn.energy,
        'tension': checkIn.tension,
        'focus': checkIn.focus,
        if (checkIn.note != null) 'note': checkIn.note,
      };

  static Map<String, Object?> _dailyReviewJson(DailyReview review) => {
        'id': review.id.value,
        'review_date': review.reviewDate.toUtc().toIso8601String(),
        'created_at': review.createdAt.toUtc().toIso8601String(),
        if (review.whatHappened != null) 'what_happened': review.whatHappened,
        if (review.currentState != null) 'current_state': review.currentState,
        if (review.tomorrowCommitments != null)
          'tomorrow_commitments': review.tomorrowCommitments,
        if (review.routeCorrection != null)
          'route_correction': review.routeCorrection,
      };

  static Map<String, Object?> _moodFactorJson(MoodFactor factor) => {
        'id': factor.id.value,
        'check_in_id': factor.checkInId.value,
        'label': factor.label,
        'kind': factor.kind.name,
        if (factor.impact != null) 'impact': factor.impact,
        'uncertain': factor.uncertain,
      };

  static Map<String, Object?> _weeklyReviewJson(WeeklyReview review) => {
        'id': review.id.value,
        'week_start_date': review.weekStartDate.toUtc().toIso8601String(),
        'created_at': review.createdAt.toUtc().toIso8601String(),
        if (review.facts != null) 'facts': review.facts,
        if (review.wins != null) 'wins': review.wins,
        if (review.problems != null) 'problems': review.problems,
        if (review.projects != null) 'projects': review.projects,
        if (review.learning != null) 'learning': review.learning,
        if (review.nextWeek != null) 'next_week': review.nextWeek,
      };

  static Map<String, Object?> _researchNodeJson(ResearchNode node) => {
        'id': node.id.value,
        'title': node.title,
        if (node.description != null) 'description': node.description,
        'type': node.type.name,
        'status': node.status.name,
        'created_at': node.createdAt.toUtc().toIso8601String(),
        'updated_at': node.updatedAt.toUtc().toIso8601String(),
        if (node.demonstratedNote != null)
          'demonstrated_note': node.demonstratedNote,
        'version': node.version,
      };

  static Map<String, Object?> _researchPrerequisiteLinkJson(
    ResearchPrerequisiteLink link,
  ) =>
      {
        'node_id': link.nodeId.value,
        'prerequisite_node_id': link.prerequisiteNodeId.value,
        'linked_at': link.linkedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _learningSessionJson(LearningSession session) => {
        'id': session.id.value,
        'node_id': session.nodeId.value,
        'started_at': session.startedAt.toUtc().toIso8601String(),
        'duration_minutes': session.durationMinutes,
        'mode': session.mode.name,
        if (session.notes != null) 'notes': session.notes,
      };

  static Map<String, Object?> _researchEvidenceJson(ResearchEvidence evidence) =>
      {
        'id': evidence.id.value,
        'node_id': evidence.nodeId.value,
        if (evidence.sessionId != null) 'session_id': evidence.sessionId!.value,
        'type': evidence.type.name,
        'title': evidence.title,
        'body': evidence.body,
        'created_at': evidence.createdAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _financialEntityJson(FinancialEntity entity) => {
        'id': entity.id.value,
        'name': entity.name,
        'kind': entity.kind.name,
        'created_at': entity.createdAt.toUtc().toIso8601String(),
        'updated_at': entity.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _financialAccountJson(FinancialAccount account) =>
      {
        'id': account.id.value,
        'entity_id': account.entityId.value,
        'institution': account.institution,
        'name': account.name,
        'type': account.type.name,
        'currency': account.currency,
        'current_balance_minor': account.currentBalanceMinor,
        if (account.balanceAsOf != null)
          'balance_as_of': account.balanceAsOf!.toUtc().toIso8601String(),
        'include_in_net_worth': account.includeInNetWorth,
        'sensitive_display_mode': account.sensitiveDisplayMode.name,
        'is_archived': account.isArchived,
        'created_at': account.createdAt.toUtc().toIso8601String(),
        'updated_at': account.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _ledgerTransactionJson(LedgerTransaction tx) => {
        'id': tx.id.value,
        'account_id': tx.accountId.value,
        'occurred_at': tx.occurredAt.toUtc().toIso8601String(),
        'description_original': tx.descriptionOriginal,
        'amount_minor': tx.amountMinor,
        'currency': tx.currency,
        'direction': tx.direction.name,
        if (tx.categoryId != null) 'category_id': tx.categoryId!.value,
        if (tx.notes != null) 'notes': tx.notes,
        'fingerprint': tx.fingerprint,
        'created_at': tx.createdAt.toUtc().toIso8601String(),
        'updated_at': tx.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _healthConditionJson(HealthCondition condition) =>
      {
        'id': condition.id.value,
        'title': condition.title,
        'type': condition.type.name,
        'status': condition.status.name,
        if (condition.onsetAt != null)
          'onset_at': condition.onsetAt!.toUtc().toIso8601String(),
        if (condition.resolvedAt != null)
          'resolved_at': condition.resolvedAt!.toUtc().toIso8601String(),
        if (condition.severityUserReported != null)
          'severity_user_reported': condition.severityUserReported,
        'body_regions': condition.bodyRegions,
        'clinician_confirmed': condition.clinicianConfirmed,
        if (condition.notes != null) 'notes': condition.notes,
        'created_at': condition.createdAt.toUtc().toIso8601String(),
        'updated_at': condition.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _symptomEntryJson(SymptomEntry entry) => {
        'id': entry.id.value,
        if (entry.conditionId != null) 'condition_id': entry.conditionId!.value,
        'occurred_at': entry.occurredAt.toUtc().toIso8601String(),
        'intensity': entry.intensity,
        if (entry.note != null) 'note': entry.note,
        if (entry.bodyRegion != null) 'body_region': entry.bodyRegion,
        'created_at': entry.createdAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _inventoryItemJson(InventoryItem item) => {
        'id': item.id.value,
        'name': item.name,
        'category': item.category.name,
        'status': item.status.name,
        if (item.locationLabel != null) 'location_label': item.locationLabel,
        if (item.notes != null) 'notes': item.notes,
        'tags': item.tags,
        if (item.purchaseDate != null)
          'purchase_date': item.purchaseDate!.toUtc().toIso8601String(),
        if (item.purchasePriceMinor != null)
          'purchase_price_minor': item.purchasePriceMinor,
        if (item.purchaseCurrency != null)
          'purchase_currency': item.purchaseCurrency,
        if (item.warrantyEnd != null)
          'warranty_end': item.warrantyEnd!.toUtc().toIso8601String(),
        'created_at': item.createdAt.toUtc().toIso8601String(),
        'updated_at': item.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _personJson(Person person) => {
        'id': person.id.value,
        'display_name': person.displayName,
        if (person.preferredName != null)
          'preferred_name': person.preferredName,
        'relationship_types': person.relationshipTypes,
        if (person.notes != null) 'notes': person.notes,
        if (person.birthday != null)
          'birthday': person.birthday!.toUtc().toIso8601String(),
        if (person.lastInteractionAt != null)
          'last_interaction_at':
              person.lastInteractionAt!.toUtc().toIso8601String(),
        if (person.nextFollowUpAt != null)
          'next_follow_up_at':
              person.nextFollowUpAt!.toUtc().toIso8601String(),
        if (person.archivedAt != null)
          'archived_at': person.archivedAt!.toUtc().toIso8601String(),
        'created_at': person.createdAt.toUtc().toIso8601String(),
        'updated_at': person.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _categoryBudgetJson(CategoryBudget budget) => {
        'id': budget.id.value,
        'category_id': budget.categoryId.value,
        'currency': budget.currency,
        'limit_amount_minor': budget.limitAmountMinor,
        'created_at': budget.createdAt.toUtc().toIso8601String(),
        'updated_at': budget.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _personInteractionJson(
    PersonInteraction interaction,
  ) =>
      {
        'id': interaction.id.value,
        'person_id': interaction.personId.value,
        'kind': interaction.kind.name,
        'occurred_at': interaction.occurredAt.toUtc().toIso8601String(),
        if (interaction.note != null) 'note': interaction.note,
        'created_at': interaction.createdAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _tripJson(Trip trip) => {
        'id': trip.id.value,
        'title': trip.title,
        'destinations': trip.destinations,
        if (trip.startAt != null)
          'start_at': trip.startAt!.toUtc().toIso8601String(),
        if (trip.endAt != null)
          'end_at': trip.endAt!.toUtc().toIso8601String(),
        if (trip.purpose != null) 'purpose': trip.purpose,
        if (trip.notes != null) 'notes': trip.notes,
        'status': trip.status.name,
        'created_at': trip.createdAt.toUtc().toIso8601String(),
        'updated_at': trip.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _organizationJson(Organization org) => {
        'id': org.id.value,
        'name': org.name,
        'kind': org.kind.name,
        if (org.notes != null) 'notes': org.notes,
        if (org.archivedAt != null)
          'archived_at': org.archivedAt!.toUtc().toIso8601String(),
        'created_at': org.createdAt.toUtc().toIso8601String(),
        'updated_at': org.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _personOrganizationLinkJson(
    PersonOrganizationLink link,
  ) =>
      {
        'person_id': link.personId.value,
        'organization_id': link.organizationId.value,
        'linked_at': link.linkedAt.toUtc().toIso8601String(),
        if (link.role != null) 'role': link.role,
      };

  static Map<String, Object?> _homeMaintenanceTaskJson(
    HomeMaintenanceTask task,
  ) =>
      {
        'id': task.id.value,
        'title': task.title,
        'system_or_item': task.systemOrItem,
        if (task.cadenceDays != null) 'cadence_days': task.cadenceDays,
        if (task.nextDueAt != null)
          'next_due_at': task.nextDueAt!.toUtc().toIso8601String(),
        if (task.lastDoneAt != null)
          'last_done_at': task.lastDoneAt!.toUtc().toIso8601String(),
        if (task.vendorLabel != null) 'vendor_label': task.vendorLabel,
        if (task.estimatedCostMinor != null)
          'estimated_cost_minor': task.estimatedCostMinor,
        if (task.currency != null) 'currency': task.currency,
        if (task.notes != null) 'notes': task.notes,
        if (task.linkedInventoryItemId != null)
          'linked_inventory_item_id': task.linkedInventoryItemId!.value,
        if (task.archivedAt != null)
          'archived_at': task.archivedAt!.toUtc().toIso8601String(),
        'created_at': task.createdAt.toUtc().toIso8601String(),
        'updated_at': task.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _questInventoryLinkJson(QuestInventoryLink link) =>
      {
        'quest_id': link.questId.value,
        'inventory_item_id': link.inventoryItemId.value,
        'linked_at': link.linkedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _zoneTripLinkJson(ZoneTripLink link) => {
        'zone_id': link.zoneId.value,
        'trip_id': link.tripId.value,
        'linked_at': link.linkedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _tripInventoryLinkJson(TripInventoryLink link) => {
        'trip_id': link.tripId.value,
        'inventory_item_id': link.inventoryItemId.value,
        'linked_at': link.linkedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _knowledgeAreaJson(KnowledgeArea area) => {
        'id': area.id.value,
        if (area.parentId != null) 'parent_id': area.parentId!.value,
        'title': area.title,
        'slug': area.slug,
        if (area.description != null) 'description': area.description,
        if (area.iconKey != null) 'icon_key': area.iconKey,
        if (area.catalogKey != null) 'catalog_key': area.catalogKey,
        'sort_order': area.sortOrder,
        'created_at': area.createdAt.toUtc().toIso8601String(),
        'updated_at': area.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _flashcardDeckJson(FlashcardDeck deck) => {
        'id': deck.id.value,
        if (deck.areaId != null) 'area_id': deck.areaId!.value,
        if (deck.researchNodeId != null)
          'research_node_id': deck.researchNodeId!.value,
        'title': deck.title,
        if (deck.description != null) 'description': deck.description,
        'new_limit_per_day': deck.newLimitPerDay,
        'review_limit_per_day': deck.reviewLimitPerDay,
        if (deck.archivedAt != null)
          'archived_at': deck.archivedAt!.toUtc().toIso8601String(),
        'created_at': deck.createdAt.toUtc().toIso8601String(),
        'updated_at': deck.updatedAt.toUtc().toIso8601String(),
        'version': deck.version,
      };

  static Map<String, Object?> _flashcardJson(Flashcard card) => {
        'id': card.id.value,
        'deck_id': card.deckId.value,
        if (card.areaId != null) 'area_id': card.areaId!.value,
        'kind': card.kind.name,
        'front': card.front,
        'back': card.back,
        if (card.extra != null) 'extra': card.extra,
        'tags': card.tags,
        if (card.clozeIndex != null) 'cloze_index': card.clozeIndex,
        if (card.reverseOfId != null) 'reverse_of_id': card.reverseOfId!.value,
        'schedule_mode': card.scheduleMode.name,
        'priority': card.priority,
        'suspended': card.suspended,
        'created_at': card.createdAt.toUtc().toIso8601String(),
        'updated_at': card.updatedAt.toUtc().toIso8601String(),
        'version': card.version,
      };

  static Map<String, Object?> _flashcardSrsJson(FlashcardSrsState srs) => {
        'card_id': srs.cardId.value,
        'status': srs.status.name,
        'ease_factor': srs.easeFactor,
        'interval_days': srs.intervalDays,
        'repetitions': srs.repetitions,
        'lapses': srs.lapses,
        'learning_step_index': srs.learningStepIndex,
        'leech': srs.leech,
        'due_at': srs.dueAt.toUtc().toIso8601String(),
        if (srs.lastReviewedAt != null)
          'last_reviewed_at': srs.lastReviewedAt!.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _flashcardReviewLogJson(FlashcardReviewLog log) =>
      {
        'id': log.id.value,
        'card_id': log.cardId.value,
        'reviewed_at': log.reviewedAt.toUtc().toIso8601String(),
        'rating': log.rating.name,
        'interval_days_before': log.intervalDaysBefore,
        'interval_days_after': log.intervalDaysAfter,
        'ease_before': log.easeBefore,
        'ease_after': log.easeAfter,
        if (log.durationMs != null) 'duration_ms': log.durationMs,
        'review_kind': log.reviewKind.name,
      };

  static Map<String, Object?> _knowledgeAreaPlacementJson(
    KnowledgeAreaPlacement placement,
  ) =>
      {
        'area_id': placement.areaId.value,
        'parent_area_id': placement.parentAreaId.value,
        'linked_at': placement.linkedAt.toUtc().toIso8601String(),
        if (placement.catalogKey != null) 'catalog_key': placement.catalogKey,
      };

  static Map<String, Object?> _researchKnowledgeLinkJson(
    ResearchKnowledgeLink link,
  ) =>
      {
        'research_node_id': link.researchNodeId.value,
        'area_id': link.areaId.value,
        'kind': link.kind.name,
        'linked_at': link.linkedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _googleTimelineImportJson(
    GoogleTimelineImport import,
  ) =>
      {
        'id': import.id.value,
        'profile_id': import.profileId.value,
        'file_name': import.fileName,
        'imported_at': import.importedAt.toUtc().toIso8601String(),
        'document': import.document.toJson(),
      };

  static Map<String, Object?> _healthAppointmentJson(HealthAppointment a) => {
        'id': a.id.value,
        'title': a.title,
        'scheduled_at': a.scheduledAt.toUtc().toIso8601String(),
        if (a.locationLabel != null) 'location_label': a.locationLabel,
        if (a.clinicianLabel != null) 'clinician_label': a.clinicianLabel,
        if (a.notes != null) 'notes': a.notes,
        'status': a.status.name,
        'created_at': a.createdAt.toUtc().toIso8601String(),
        'updated_at': a.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _commitmentJson(Commitment c) => {
        'id': c.id.value,
        'description': c.description,
        'made_by_label': c.madeByLabel,
        if (c.madeToPersonId != null)
          'made_to_person_id': c.madeToPersonId!.value,
        if (c.madeToOrganizationId != null)
          'made_to_organization_id': c.madeToOrganizationId!.value,
        if (c.madeToLabel != null) 'made_to_label': c.madeToLabel,
        if (c.dueAt != null) 'due_at': c.dueAt!.toUtc().toIso8601String(),
        'status': c.status.name,
        if (c.notes != null) 'notes': c.notes,
        if (c.linkedQuestId != null) 'linked_quest_id': c.linkedQuestId!.value,
        'created_at': c.createdAt.toUtc().toIso8601String(),
        'updated_at': c.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _contextZoneJson(ContextZone z) => {
        'id': z.id.value,
        'name': z.name,
        if (z.locationLabel != null) 'location_label': z.locationLabel,
        'capabilities': z.capabilities,
        'unavailable_work_types': z.unavailableWorkTypes,
        'connectivity': z.connectivity.name,
        if (z.notes != null) 'notes': z.notes,
        if (z.archivedAt != null)
          'archived_at': z.archivedAt!.toUtc().toIso8601String(),
        'created_at': z.createdAt.toUtc().toIso8601String(),
        'updated_at': z.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _integrationConsentJson(IntegrationConsent c) => {
        'id': c.id.value,
        'kind': c.kind.name,
        'enabled': c.enabled,
        if (c.grantedAt != null)
          'granted_at': c.grantedAt!.toUtc().toIso8601String(),
        if (c.revokedAt != null)
          'revoked_at': c.revokedAt!.toUtc().toIso8601String(),
        'created_at': c.createdAt.toUtc().toIso8601String(),
        'updated_at': c.updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _externalCalendarEventJson(
    ExternalCalendarEvent e,
  ) =>
      {
        'id': e.id.value,
        if (e.externalUid != null) 'external_uid': e.externalUid,
        'title': e.title,
        'start_at': e.startAt.toUtc().toIso8601String(),
        'end_at': e.endAt.toUtc().toIso8601String(),
        'source_type': e.sourceType.name,
        'imported_at': e.importedAt.toUtc().toIso8601String(),
        'created_at': e.createdAt.toUtc().toIso8601String(),
        'updated_at': e.updatedAt.toUtc().toIso8601String(),
      };

  @override
  List<Object?> get props => [
        exportedAt,
        version,
        profile,
        preferences,
        tasks,
        events,
        quests,
        projects,
        questProjectLinks,
        decisionRecords,
        questDecisionLinks,
        questPrerequisiteLinks,
        workPriorities,
        bills,
        scheduleBlocks,
        needDefinitions,
        needReadings,
        checkIns,
        dailyReviews,
        moodFactors,
        weeklyReviews,
        researchNodes,
        researchPrerequisiteLinks,
        questResearchLinks,
        learningSessions,
        researchEvidence,
        financialEntities,
        financialAccounts,
        transactions,
        healthConditions,
        symptomEntries,
        inventoryItems,
        people,
        categoryBudgets,
        personInteractions,
        trips,
        organizations,
        personOrganizationLinks,
        homeMaintenanceTasks,
        questInventoryLinks,
        commitments,
        contextZones,
        integrationConsents,
        externalCalendarEvents,
        zoneTripLinks,
        healthAppointments,
        tripInventoryLinks,
        knowledgeAreas,
        flashcardDecks,
        flashcards,
        flashcardSrs,
        flashcardReviewLogs,
        knowledgeAreaPlacements,
        researchKnowledgeLinks,
        googleTimelineImport,
        googleTimelinePlaceLabels,
      ];
}
