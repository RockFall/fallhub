import 'package:drift/drift.dart';

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get colonyName => text()();
  TextColumn get displayName => text()();
  TextColumn get timezone => text()();
  TextColumn get locale => text()();
  TextColumn get baseCurrency => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DomainEvents extends Table {
  TextColumn get id => text()();
  TextColumn get aggregateType => text()();
  TextColumn get aggregateId => text()();
  TextColumn get eventType => text()();
  IntColumn get occurredAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get sourceType => text()();
  IntColumn get payloadVersion => integer()();
  TextColumn get payloadJson => text()();
  TextColumn get correlationId => text().nullable()();
  TextColumn get causationId => text().nullable()();
  TextColumn get privacyClass => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text()();
  TextColumn get sourceType => text()();
  IntColumn get dueAt => integer().nullable()();
  IntColumn get scheduledStart => integer().nullable()();
  IntColumn get estimatedMinutes => integer().nullable()();
  IntColumn get actualMinutes => integer().nullable()();
  TextColumn get energyRequirement =>
      text().withDefault(const Constant('unknown'))();
  TextColumn get blockedReason => text().nullable()();
  TextColumn get questId => text().nullable()();
  TextColumn get projectId => text().nullable()();
  TextColumn get parentTaskId => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('none'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Preferences extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get densityMode => text()();
  TextColumn get themeMode => text()();
  BoolColumn get weekStartsOnMonday => boolean()();
  BoolColumn get use24HourFormat => boolean()();
  TextColumn get sectorsEnabledJson => text()();
  BoolColumn get onboardingCompleted => boolean()();
  BoolColumn get biometricLockEnabled => boolean()();
  IntColumn get sessionTimeoutMinutes => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class NeedDefinitions extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get slug => text()();
  TextColumn get calculationMode => text()();
  RealColumn get preferredMin => real().withDefault(const Constant(0.5))();
  RealColumn get preferredMax => real().withDefault(const Constant(0.85))();
  IntColumn get validitySeconds => integer().withDefault(const Constant(86400))();
  TextColumn get privacyClass => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isSubjective => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class NeedReadings extends Table {
  TextColumn get id => text()();
  TextColumn get needId => text().references(NeedDefinitions, #id)();
  IntColumn get observedAt => integer()();
  RealColumn get normalizedValue => real().nullable()();
  RealColumn get rawValue => real().nullable()();
  TextColumn get rawUnit => text().nullable()();
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text().nullable()();
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CheckIns extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  IntColumn get observedAt => integer()();
  IntColumn get createdAt => integer()();
  RealColumn get mood => real()();
  RealColumn get energy => real()();
  RealColumn get tension => real()();
  RealColumn get focus => real()();
  TextColumn get note => text().nullable()();
  TextColumn get contextTagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get moodScale => text().withDefault(const Constant('five'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MoodFactors extends Table {
  TextColumn get id => text()();
  TextColumn get checkInId => text().references(CheckIns, #id)();
  TextColumn get label => text()();
  TextColumn get kind => text()();
  IntColumn get impact => integer().nullable()();
  BoolColumn get uncertain => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DailyReviews extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  IntColumn get reviewDate => integer()();
  IntColumn get createdAt => integer()();
  TextColumn get whatHappened => text().nullable()();
  TextColumn get currentState => text().nullable()();
  TextColumn get tomorrowCommitments => text().nullable()();
  TextColumn get routeCorrection => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WeeklyReviews extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  IntColumn get weekStartDate => integer()();
  IntColumn get createdAt => integer()();
  TextColumn get facts => text().nullable()();
  TextColumn get wins => text().nullable()();
  TextColumn get problems => text().nullable()();
  TextColumn get projects => text().nullable()();
  TextColumn get learning => text().nullable()();
  TextColumn get nextWeek => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WorkPriorities extends Table {
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get workType => text()();
  TextColumn get level => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {profileId, workType};
}

class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get repeatMode => text()();
  TextColumn get target => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ScheduleBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer()();
  TextColumn get mode => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Quests extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get purpose => text()();
  TextColumn get successCriteriaJson => text().withDefault(const Constant('[]'))();
  TextColumn get risksJson => text().withDefault(const Constant('[]'))();
  IntColumn get deadline => integer().nullable()();
  TextColumn get status => text()();
  TextColumn get exitReason => text().nullable()();
  TextColumn get pauseReason => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get acceptedAt => integer().nullable()();
  IntColumn get acceptanceDeadline => integer().nullable()();
  TextColumn get acceptanceAssumptionsJson =>
      text().withDefault(const Constant('[]'))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get purpose => text().nullable()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class QuestProjects extends Table {
  TextColumn get questId => text().references(Quests, #id)();
  TextColumn get projectId => text().references(Projects, #id)();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {questId, projectId};
}

class DecisionRecords extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get context => text()();
  TextColumn get decision => text()();
  TextColumn get alternativesJson => text().withDefault(const Constant('[]'))();
  TextColumn get criteriaJson => text().withDefault(const Constant('[]'))();
  TextColumn get assumptionsJson => text().withDefault(const Constant('[]'))();
  TextColumn get expectedOutcomesJson => text().withDefault(const Constant('[]'))();
  TextColumn get risksJson => text().withDefault(const Constant('[]'))();
  TextColumn get reversibility => text()();
  IntColumn get decidedAt => integer()();
  IntColumn get reviewAt => integer().nullable()();
  TextColumn get outcomeReview => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class QuestDecisions extends Table {
  TextColumn get questId => text().references(Quests, #id)();
  TextColumn get decisionId => text().references(DecisionRecords, #id)();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {questId, decisionId};
}

class QuestPrerequisites extends Table {
  TextColumn get questId => text().references(Quests, #id)();
  TextColumn get prerequisiteQuestId => text().references(Quests, #id)();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {questId, prerequisiteQuestId};
}

class ResearchNodes extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get demonstratedNote => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ResearchPrerequisites extends Table {
  TextColumn get nodeId => text().references(ResearchNodes, #id)();
  TextColumn get prerequisiteNodeId => text().references(ResearchNodes, #id)();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {nodeId, prerequisiteNodeId};
}

class QuestResearch extends Table {
  TextColumn get questId => text().references(Quests, #id)();
  TextColumn get researchNodeId => text().references(ResearchNodes, #id)();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {questId, researchNodeId};
}

@DataClassName('LearningSessionRow')
class LearningSessions extends Table {
  @override
  String get tableName => 'learning_sessions';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get nodeId => text().references(ResearchNodes, #id)();
  IntColumn get startedAt => integer()();
  IntColumn get durationMinutes => integer()();
  TextColumn get mode => text()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ResearchEvidenceRow')
class ResearchEvidenceItems extends Table {
  @override
  String get tableName => 'research_evidence';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get nodeId => text().references(ResearchNodes, #id)();
  TextColumn get sessionId =>
      text().nullable().references(LearningSessions, #id)();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FinancialEntityRow')
class FinancialEntities extends Table {
  @override
  String get tableName => 'financial_entities';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FinancialAccountRow')
class FinancialAccounts extends Table {
  @override
  String get tableName => 'financial_accounts';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get entityId => text().references(FinancialEntities, #id)();
  TextColumn get institution => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get currency => text()();
  IntColumn get currentBalanceMinor => integer()();
  IntColumn get balanceAsOf => integer().nullable()();
  BoolColumn get includeInNetWorth => boolean().withDefault(const Constant(true))();
  TextColumn get sensitiveDisplayMode => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LedgerTransactionRow')
class LedgerTransactions extends Table {
  @override
  String get tableName => 'ledger_transactions';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get accountId => text().references(FinancialAccounts, #id)();
  IntColumn get occurredAt => integer()();
  TextColumn get descriptionOriginal => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get direction => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get fingerprint => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HealthConditionRow')
class HealthConditions extends Table {
  @override
  String get tableName => 'health_conditions';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get type => text()();
  TextColumn get status => text()();
  IntColumn get onsetAt => integer().nullable()();
  IntColumn get resolvedAt => integer().nullable()();
  IntColumn get severityUserReported => integer().nullable()();
  TextColumn get bodyRegionsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get clinicianConfirmed =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SymptomEntryRow')
class SymptomEntries extends Table {
  @override
  String get tableName => 'symptom_entries';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get conditionId =>
      text().nullable().references(HealthConditions, #id)();
  IntColumn get occurredAt => integer()();
  IntColumn get intensity => integer()();
  TextColumn get note => text().nullable()();
  TextColumn get bodyRegion => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HealthAppointmentRow')
class HealthAppointments extends Table {
  @override
  String get tableName => 'health_appointments';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  IntColumn get scheduledAt => integer()();
  TextColumn get locationLabel => text().nullable()();
  TextColumn get clinicianLabel => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SleepSessionRow')
class SleepSessions extends Table {
  @override
  String get tableName => 'sleep_sessions';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();
  TextColumn get source => text()();
  TextColumn get confidence => text()();
  TextColumn get externalId => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('InventoryItemRow')
class InventoryItems extends Table {
  @override
  String get tableName => 'inventory_items';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get status => text()();
  TextColumn get locationLabel => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  IntColumn get purchaseDate => integer().nullable()();
  IntColumn get purchasePriceMinor => integer().nullable()();
  TextColumn get purchaseCurrency => text().nullable()();
  IntColumn get warrantyEnd => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PersonRow')
class People extends Table {
  @override
  String get tableName => 'people';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get displayName => text()();
  TextColumn get preferredName => text().nullable()();
  TextColumn get relationshipTypesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  IntColumn get birthday => integer().nullable()();
  IntColumn get lastInteractionAt => integer().nullable()();
  IntColumn get nextFollowUpAt => integer().nullable()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CategoryBudgetRow')
class CategoryBudgets extends Table {
  @override
  String get tableName => 'category_budgets';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get categoryId => text()();
  TextColumn get currency => text()();
  IntColumn get limitAmountMinor => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PersonInteractionRow')
class PersonInteractions extends Table {
  @override
  String get tableName => 'person_interactions';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get personId => text().references(People, #id)();
  TextColumn get kind => text()();
  IntColumn get occurredAt => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TripRow')
class Trips extends Table {
  @override
  String get tableName => 'trips';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get destinationsJson =>
      text().withDefault(const Constant('[]'))();
  IntColumn get startAt => integer().nullable()();
  IntColumn get endAt => integer().nullable()();
  TextColumn get purpose => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OrganizationRow')
class Organizations extends Table {
  @override
  String get tableName => 'organizations';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PersonOrganizationRow')
class PersonOrganizations extends Table {
  @override
  String get tableName => 'person_organizations';

  TextColumn get personId => text().references(People, #id)();
  TextColumn get organizationId => text().references(Organizations, #id)();
  TextColumn get role => text().nullable()();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {personId, organizationId};
}

class QuestInventory extends Table {
  TextColumn get questId => text().references(Quests, #id)();
  TextColumn get inventoryItemId => text().references(InventoryItems, #id)();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {questId, inventoryItemId};
}

@DataClassName('HomeMaintenanceTaskRow')
class HomeMaintenanceTasks extends Table {
  @override
  String get tableName => 'home_maintenance_tasks';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get systemOrItem => text()();
  IntColumn get cadenceDays => integer().nullable()();
  IntColumn get nextDueAt => integer().nullable()();
  IntColumn get lastDoneAt => integer().nullable()();
  TextColumn get vendorLabel => text().nullable()();
  IntColumn get estimatedCostMinor => integer().nullable()();
  TextColumn get currency => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get linkedInventoryItemId =>
      text().nullable().references(InventoryItems, #id)();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CommitmentRow')
class Commitments extends Table {
  @override
  String get tableName => 'commitments';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get description => text()();
  TextColumn get madeByLabel => text()();
  TextColumn get madeToPersonId =>
      text().nullable().references(People, #id)();
  TextColumn get madeToOrganizationId =>
      text().nullable().references(Organizations, #id)();
  TextColumn get madeToLabel => text().nullable()();
  IntColumn get dueAt => integer().nullable()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get linkedQuestId =>
      text().nullable().references(Quests, #id)();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DeviceIdentityRow')
class DeviceIdentities extends Table {
  @override
  String get tableName => 'device_identities';

  TextColumn get id => text()();
  TextColumn get label => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastSeenAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SyncOperationRow')
class SyncOperations extends Table {
  @override
  String get tableName => 'sync_operations';

  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  IntColumn get baseVersion => integer().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ContextZoneRow')
class ContextZones extends Table {
  @override
  String get tableName => 'context_zones';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get locationLabel => text().nullable()();
  TextColumn get capabilitiesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get unavailableWorkTypesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get connectivity => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ZoneTrips extends Table {
  TextColumn get zoneId => text().references(ContextZones, #id)();
  TextColumn get tripId => text().references(Trips, #id)();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {zoneId, tripId};
}

class TripInventory extends Table {
  TextColumn get tripId => text().references(Trips, #id)();
  TextColumn get inventoryItemId => text().references(InventoryItems, #id)();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {tripId, inventoryItemId};
}

@DataClassName('IntegrationConsentRow')
class IntegrationConsents extends Table {
  @override
  String get tableName => 'integration_consents';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get kind => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  IntColumn get grantedAt => integer().nullable()();
  IntColumn get revokedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExternalCalendarEventRow')
class ExternalCalendarEvents extends Table {
  @override
  String get tableName => 'external_calendar_events';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get externalUid => text().nullable()();
  TextColumn get title => text()();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer()();
  TextColumn get sourceType => text()();
  IntColumn get importedAt => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('KnowledgeAreaRow')
class KnowledgeAreas extends Table {
  @override
  String get tableName => 'knowledge_areas';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get parentId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get slug => text()();
  TextColumn get description => text().nullable()();
  TextColumn get iconKey => text().nullable()();
  TextColumn get catalogKey => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FlashcardDeckRow')
class FlashcardDecks extends Table {
  @override
  String get tableName => 'flashcard_decks';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get areaId => text().nullable()();
  TextColumn get researchNodeId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get newLimitPerDay => integer().withDefault(const Constant(20))();
  IntColumn get reviewLimitPerDay =>
      integer().withDefault(const Constant(200))();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FlashcardRow')
class Flashcards extends Table {
  @override
  String get tableName => 'flashcards';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get deckId => text().references(FlashcardDecks, #id)();
  TextColumn get areaId => text().nullable()();
  TextColumn get kind => text()();
  TextColumn get front => text()();
  TextColumn get back => text().withDefault(const Constant(''))();
  TextColumn get extra => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  IntColumn get clozeIndex => integer().nullable()();
  TextColumn get reverseOfId => text().nullable()();
  TextColumn get scheduleMode =>
      text().withDefault(const Constant('scheduled'))();
  IntColumn get priority => integer().withDefault(const Constant(5))();
  BoolColumn get suspended => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FlashcardSrsRow')
class FlashcardSrs extends Table {
  @override
  String get tableName => 'flashcard_srs';

  TextColumn get cardId => text().references(Flashcards, #id)();
  TextColumn get status => text()();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  RealColumn get intervalDays => real().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get learningStepIndex => integer().withDefault(const Constant(0))();
  BoolColumn get leech => boolean().withDefault(const Constant(false))();
  IntColumn get dueAt => integer()();
  IntColumn get lastReviewedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {cardId};
}

@DataClassName('FlashcardReviewLogRow')
class FlashcardReviewLogs extends Table {
  @override
  String get tableName => 'flashcard_review_logs';

  TextColumn get id => text()();
  TextColumn get cardId => text().references(Flashcards, #id)();
  IntColumn get reviewedAt => integer()();
  TextColumn get rating => text()();
  RealColumn get intervalDaysBefore => real()();
  RealColumn get intervalDaysAfter => real()();
  RealColumn get easeBefore => real()();
  RealColumn get easeAfter => real()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get reviewKind => text().withDefault(const Constant('srs'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('KnowledgeAreaPlacementRow')
class KnowledgeAreaPlacements extends Table {
  @override
  String get tableName => 'knowledge_area_placements';

  TextColumn get areaId => text().references(KnowledgeAreas, #id)();
  TextColumn get parentAreaId => text().references(KnowledgeAreas, #id)();
  IntColumn get linkedAt => integer()();
  TextColumn get catalogKey => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {areaId, parentAreaId};
}

@DataClassName('ResearchKnowledgeLinkRow')
class ResearchKnowledgeLinks extends Table {
  @override
  String get tableName => 'research_knowledge_links';

  TextColumn get researchNodeId => text().references(ResearchNodes, #id)();
  TextColumn get areaId => text().references(KnowledgeAreas, #id)();
  TextColumn get kind => text()();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {researchNodeId, areaId};
}

@DataClassName('FlashcardTagRow')
class FlashcardTags extends Table {
  @override
  String get tableName => 'flashcard_tags';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get parentId => text().nullable()();
  TextColumn get title => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FlashcardTagLinkRow')
class FlashcardTagLinks extends Table {
  @override
  String get tableName => 'flashcard_tag_links';

  TextColumn get cardId => text().references(Flashcards, #id)();
  TextColumn get tagId => text().references(FlashcardTags, #id)();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {cardId, tagId};
}

@DataClassName('CapturedNotificationRow')
class CapturedNotifications extends Table {
  @override
  String get tableName => 'captured_notifications';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get packageName => text()();
  TextColumn get appLabel => text().nullable()();
  TextColumn get title => text()();
  TextColumn get bodyText => text()();
  IntColumn get postedAt => integer()();
  TextColumn get nativeKey => text()();
  TextColumn get extractorKind => text()();
  TextColumn get ledgerTransactionId =>
      text().nullable().references(LedgerTransactions, #id)();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {profileId, nativeKey},
      ];
}

@DataClassName('GoogleTimelineImportRow')
class GoogleTimelineImports extends Table {
  @override
  String get tableName => 'google_timeline_imports';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get fileName => text()();
  IntColumn get importedAt => integer()();
  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GoogleTimelinePlaceLabelRow')
class GoogleTimelinePlaceLabels extends Table {
  @override
  String get tableName => 'google_timeline_place_labels';

  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get placeId => text()();
  TextColumn get category => text()();
  TextColumn get customName => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {profileId, placeId};
}

@DataClassName('MusicNodeRow')
class MusicNodes extends Table {
  @override
  String get tableName => 'music_nodes';

  TextColumn get id => text()();
  TextColumn get nodeType => text()();
  TextColumn get canonicalName => text()();
  TextColumn get sortName => text()();
  TextColumn get description => text().nullable()();
  IntColumn get beginYear => integer().nullable()();
  IntColumn get endYear => integer().nullable()();
  RealColumn get metadataQuality => real().withDefault(const Constant(0))();
  TextColumn get provenanceJson => text().withDefault(const Constant('{}'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MusicExternalIdentityRow')
class MusicExternalIdentities extends Table {
  @override
  String get tableName => 'music_external_identities';

  TextColumn get id => text()();
  TextColumn get nodeId => text().references(MusicNodes, #id)();
  TextColumn get provider => text()();
  TextColumn get entityType => text()();
  TextColumn get externalId => text()();
  TextColumn get externalUrl => text().nullable()();
  RealColumn get confidence => real().withDefault(const Constant(1))();
  BoolColumn get reviewedByUser =>
      boolean().withDefault(const Constant(false))();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {provider, entityType, externalId},
      ];
}

@DataClassName('PersonalMusicNodeStateRow')
class PersonalMusicNodeStates extends Table {
  @override
  String get tableName => 'personal_music_node_states';

  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get nodeId => text().references(MusicNodes, #id)();
  TextColumn get discoveryState => text()();
  IntColumn get resonance => integer().nullable()();
  IntColumn get firstEncounterAt => integer().nullable()();
  IntColumn get lastEncounterAt => integer().nullable()();
  IntColumn get encounterCount => integer().withDefault(const Constant(0))();
  TextColumn get personalSummary => text().nullable()();
  TextColumn get nextAction => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {profileId, nodeId};
}

@DataClassName('MusicEncounterRow')
class MusicEncounters extends Table {
  @override
  String get tableName => 'music_encounters';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get nodeId => text().references(MusicNodes, #id)();
  TextColumn get encounterType => text()();
  IntColumn get occurredAt => integer()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get attentionQuality => integer().nullable()();
  IntColumn get resonance => integer().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get sourceType => text()();
  TextColumn get provenanceJson => text().withDefault(const Constant('{}'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MusicRelationClaimRow')
class MusicRelationClaims extends Table {
  @override
  String get tableName => 'music_relation_claims';

  TextColumn get id => text()();
  TextColumn get fromNodeId => text().references(MusicNodes, #id)();
  TextColumn get toNodeId => text().references(MusicNodes, #id)();
  TextColumn get relationType => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text()();
  RealColumn get confidence => real().nullable()();
  TextColumn get validFrom => text().nullable()();
  TextColumn get validTo => text().nullable()();
  TextColumn get provenanceJson => text().withDefault(const Constant('{}'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MusicExpeditionRow')
class MusicExpeditions extends Table {
  @override
  String get tableName => 'music_expeditions';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get question => text()();
  TextColumn get status => text()();
  TextColumn get purpose => text().nullable()();
  TextColumn get questId => text().nullable()();
  IntColumn get startedAt => integer().nullable()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get abandonedAt => integer().nullable()();
  TextColumn get abandonmentReason => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MusicExpeditionStopRow')
class MusicExpeditionStops extends Table {
  @override
  String get tableName => 'music_expedition_stops';

  TextColumn get id => text()();
  TextColumn get expeditionId => text().references(MusicExpeditions, #id)();
  TextColumn get nodeId => text().references(MusicNodes, #id)();
  IntColumn get displayOrder => integer()();
  TextColumn get role => text()();
  TextColumn get reason => text().nullable()();
  TextColumn get cuesJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isOptional => boolean().withDefault(const Constant(true))();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MusicImportRunRow')
class MusicImportRuns extends Table {
  @override
  String get tableName => 'music_import_runs';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get sourceKind => text()();
  TextColumn get status => text()();
  IntColumn get documentVersion => integer().nullable()();
  IntColumn get itemCount => integer().withDefault(const Constant(0))();
  IntColumn get createdCount => integer().withDefault(const Constant(0))();
  IntColumn get skippedCount => integer().withDefault(const Constant(0))();
  IntColumn get conflictCount => integer().withDefault(const Constant(0))();
  TextColumn get provenanceJson => text().withDefault(const Constant('{}'))();
  TextColumn get reportJson => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get appliedAt => integer().nullable()();
  IntColumn get rolledBackAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MusicSpotifySyncStateRow')
class MusicSpotifySyncStates extends Table {
  @override
  String get tableName => 'music_spotify_sync_state';

  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get consentId => text()();
  TextColumn get grantedScopesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get libraryCursor => text().nullable()();
  TextColumn get recentCursor => text().nullable()();
  IntColumn get lastLibraryAt => integer().nullable()();
  IntColumn get lastRecentAt => integer().nullable()();
  IntColumn get lastPlaylistAt => integer().nullable()();
  TextColumn get capabilityProbeJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get lastError => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {profileId};
}

@DataClassName('FriendshipRow')
class Friendships extends Table {
  @override
  String get tableName => 'friendships';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get personId => text().references(People, #id)();
  TextColumn get kind => text()();
  TextColumn get cadence => text()();
  TextColumn get howWeMet => text().nullable()();
  IntColumn get startedAt => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {personId},
      ];
}

@DataClassName('FriendshipCircleRow')
class FriendshipCircles extends Table {
  @override
  String get tableName => 'friendship_circles';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get defaultCadence => text().nullable()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FriendshipCircleMembershipRow')
class FriendshipCircleMemberships extends Table {
  @override
  String get tableName => 'friendship_circle_memberships';

  TextColumn get personId => text().references(People, #id)();
  TextColumn get circleId => text().references(FriendshipCircles, #id)();
  IntColumn get linkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {personId, circleId};
}
@DataClassName('ActivationProtocolRow')
class ActivationProtocols extends Table {
  @override
  String get tableName => 'activation_protocols';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get protocolType => text()();
  TextColumn get originStateJson => text()();
  TextColumn get targetStateJson => text()();
  IntColumn get activeVersion => integer().withDefault(const Constant(1))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get seedKey => text().nullable()();
  TextColumn get linkedTaskId => text().nullable()();
  TextColumn get maturity =>
      text().withDefault(const Constant('experimental'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivationProtocolVersionRow')
class ActivationProtocolVersions extends Table {
  @override
  String get tableName => 'activation_protocol_versions';

  TextColumn get protocolId => text().references(ActivationProtocols, #id)();
  IntColumn get version => integer()();
  TextColumn get triggerRulesJson => text()();
  TextColumn get releaseConditionsJson => text()();
  TextColumn get applicableContextsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get shieldProfileId => text().nullable()();
  TextColumn get temptationBundleId => text().nullable()();
  TextColumn get sensorySceneId => text().nullable()();
  TextColumn get fallbackProtocolId => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {protocolId, version};
}

@DataClassName('ActivationCommandTemplateRow')
class ActivationCommandTemplates extends Table {
  @override
  String get tableName => 'activation_command_templates';

  TextColumn get id => text()();
  TextColumn get protocolId => text()();
  IntColumn get protocolVersion => integer()();
  TextColumn get sequenceKey => text()();
  TextColumn get instruction => text()();
  TextColumn get actionVerb => text()();
  TextColumn get objectRef => text().nullable()();
  TextColumn get destinationRef => text().nullable()();
  TextColumn get preconditionsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get proofPolicyJson => text()();
  TextColumn get timeoutPolicyJson => text()();
  TextColumn get fallbackJson => text()();
  BoolColumn get skippable => boolean().withDefault(const Constant(true))();
  IntColumn get estimatedSeconds => integer().nullable()();
  TextColumn get waypointId => text().nullable()();
  TextColumn get opensTaskId => text().nullable()();
  TextColumn get deepLink => text().nullable()();
  BoolColumn get isFirstMeaningfulAction =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get releasesOnConfirm =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivationEpisodeRow')
class ActivationEpisodes extends Table {
  @override
  String get tableName => 'activation_episodes';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get protocolId => text().nullable()();
  IntColumn get protocolVersion => integer().nullable()();
  TextColumn get triggerType => text()();
  TextColumn get hypothesisType => text().nullable()();
  RealColumn get hypothesisConfidence => real().nullable()();
  TextColumn get capacityMode => text()();
  TextColumn get initialStateJson => text()();
  TextColumn get targetStateJson => text()();
  TextColumn get status => text()();
  IntColumn get startedAt => integer()();
  IntColumn get firstMotionAt => integer().nullable()();
  IntColumn get releasedAt => integer().nullable()();
  IntColumn get endedAt => integer().nullable()();
  IntColumn get interventionLevelMax =>
      integer().withDefault(const Constant(0))();
  BoolColumn get shieldUsed => boolean().withDefault(const Constant(false))();
  BoolColumn get bundleUsed => boolean().withDefault(const Constant(false))();
  BoolColumn get escapeUsed => boolean().withDefault(const Constant(false))();
  TextColumn get userCorrection => text().nullable()();
  TextColumn get linkedTaskId => text().nullable()();
  TextColumn get experimentAssignmentId => text().nullable()();
  TextColumn get provenanceJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivationCommandRunRow')
class ActivationCommandRuns extends Table {
  @override
  String get tableName => 'activation_command_runs';

  TextColumn get id => text()();
  TextColumn get episodeId => text().references(ActivationEpisodes, #id)();
  TextColumn get templateId => text().nullable()();
  IntColumn get sequenceIndex => integer()();
  TextColumn get instructionRendered => text()();
  TextColumn get status => text()();
  IntColumn get presentedAt => integer()();
  IntColumn get firstSignalAt => integer().nullable()();
  IntColumn get confirmedAt => integer().nullable()();
  IntColumn get skippedAt => integer().nullable()();
  IntColumn get adaptedAt => integer().nullable()();
  TextColumn get confirmationMode => text().nullable()();
  RealColumn get proofConfidence => real().nullable()();
  TextColumn get adaptationReason => text().nullable()();
  BoolColumn get isFirstMeaningfulAction =>
      boolean().withDefault(const Constant(false))();
  TextColumn get deepLink => text().nullable()();
  TextColumn get opensTaskId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivationProofRow')
class ActivationProofs extends Table {
  @override
  String get tableName => 'activation_proofs';

  TextColumn get id => text()();
  TextColumn get episodeId => text().references(ActivationEpisodes, #id)();
  TextColumn get commandRunId => text().nullable()();
  TextColumn get proofType => text()();
  IntColumn get observedAt => integer()();
  TextColumn get source => text()();
  RealColumn get confidence => real()();
  TextColumn get privacyClass => text()();
  TextColumn get interpretationJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get rawReference => text().nullable()();
  BoolColumn get userConfirmed => boolean().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivationWaypointRow')
class ActivationWaypoints extends Table {
  @override
  String get tableName => 'activation_waypoints';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get waypointType => text()();
  TextColumn get zoneId => text().nullable()();
  TextColumn get equipmentId => text().nullable()();
  TextColumn get token => text().nullable()();
  TextColumn get settingsJson => text().withDefault(const Constant('{}'))();
  RealColumn get reliabilityScore => real().nullable()();
  TextColumn get privacyClass => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('WaypointObservationRow')
class WaypointObservations extends Table {
  @override
  String get tableName => 'waypoint_observations';

  TextColumn get id => text()();
  TextColumn get waypointId => text().references(ActivationWaypoints, #id)();
  TextColumn get episodeId => text().nullable()();
  IntColumn get observedAt => integer()();
  TextColumn get state => text()();
  IntColumn get latencyMs => integer()();
  TextColumn get source => text().withDefault(const Constant('manual'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('InertiaSignalRow')
class InertiaSignals extends Table {
  @override
  String get tableName => 'inertia_signals';

  TextColumn get id => text()();
  TextColumn get episodeId => text().nullable()();
  TextColumn get signalType => text()();
  IntColumn get observedAt => integer()();
  TextColumn get valueJson => text().withDefault(const Constant('{}'))();
  TextColumn get source => text()();
  RealColumn get confidence => real()();
  IntColumn get expiresAt => integer().nullable()();
  TextColumn get privacyClass => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FrictionShieldProfileRow')
class FrictionShieldProfiles extends Table {
  @override
  String get tableName => 'friction_shield_profiles';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get platformMode => text()();
  TextColumn get protectedCategoriesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get allowlistCategoriesJson => text().withDefault(
        const Constant('["emergency","auth","maps","medical"]'),
      )();
  TextColumn get escapePolicyJson => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FrictionShieldSessionRow')
class FrictionShieldSessions extends Table {
  @override
  String get tableName => 'friction_shield_sessions';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get shieldProfileId =>
      text().references(FrictionShieldProfiles, #id)();
  TextColumn get episodeId => text().nullable()();
  TextColumn get state => text()();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();
  IntColumn get escapeCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TemptationBundleRow')
class TemptationBundles extends Table {
  @override
  String get tableName => 'temptation_bundles';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get pleasureLabel => text()();
  TextColumn get requiredTransition => text()();
  TextColumn get audioHint => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivationSceneRow')
class ActivationScenes extends Table {
  @override
  String get tableName => 'activation_scenes';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RescueContractRow')
class RescueContracts extends Table {
  @override
  String get tableName => 'rescue_contracts';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get contactLabel => text()();
  TextColumn get messageTemplate => text()();
  TextColumn get status => text()();
  TextColumn get personId => text().nullable()();
  BoolColumn get requiresConfirmation =>
      boolean().withDefault(const Constant(true))();
  IntColumn get lastConfirmedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivationExperimentRow')
class ActivationExperiments extends Table {
  @override
  String get tableName => 'activation_experiments';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get hypothesis => text()();
  TextColumn get variableKey => text()();
  TextColumn get variantsJson => text()();
  TextColumn get contextFilterJson =>
      text().withDefault(const Constant('{}'))();
  IntColumn get minimumSamples => integer().withDefault(const Constant(6))();
  TextColumn get status => text()();
  IntColumn get startedAt => integer().nullable()();
  IntColumn get endedAt => integer().nullable()();
  TextColumn get resultJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivationExperimentAssignmentRow')
class ActivationExperimentAssignments extends Table {
  @override
  String get tableName => 'activation_experiment_assignments';

  TextColumn get id => text()();
  TextColumn get experimentId =>
      text().references(ActivationExperiments, #id)();
  TextColumn get episodeId => text().references(ActivationEpisodes, #id)();
  TextColumn get variant => text()();
  IntColumn get assignedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivationInsightRow')
class ActivationInsights extends Table {
  @override
  String get tableName => 'activation_insights';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get body => text()();
  IntColumn get createdAt => integer()();
  IntColumn get sampleSize => integer().withDefault(const Constant(0))();
  TextColumn get confidence => text().withDefault(const Constant('low'))();
  BoolColumn get associativeOnly =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DayPlanRow')
class DayPlans extends Table {
  @override
  String get tableName => 'day_plans';

  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get localDate => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {profileId, localDate},
      ];
}

@DataClassName('DayPlanItemRow')
class DayPlanItems extends Table {
  @override
  String get tableName => 'day_plan_items';

  TextColumn get id => text()();
  TextColumn get dayPlanId => text().references(DayPlans, #id)();
  TextColumn get taskId => text().nullable().references(Tasks, #id)();
  TextColumn get title => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();
  TextColumn get carriedFromItemId => text().nullable()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
