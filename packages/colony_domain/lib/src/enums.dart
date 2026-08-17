enum SourceType {
  manual,
  import,
  integration,
  derived,
  ai,
  system,
}

enum PrivacyClass {
  public,
  personal,
  sensitive,
  health,
  financial,
}

enum DensityMode {
  focus,
  management,
  analysis,
}

enum ThemeModePreference {
  dark,
  light,
  system,
}

enum DataFreshness {
  current,
  recent,
  stale,
  unknown,
}

enum ProvenanceKind {
  manual,
  imported,
  integration,
  inferred,
  ai,
  corrected,
  conflicted,
}

enum ConfidenceLevel {
  high,
  medium,
  low,
  insufficient,
}

enum TaskStatus {
  inbox,
  next,
  scheduled,
  doing,
  blocked,
  waiting,
  done,
  cancelled,
  archived;

  bool get isActive =>
      this == inbox ||
      this == next ||
      this == scheduled ||
      this == doing ||
      this == blocked ||
      this == waiting;

  bool get isTerminal =>
      this == done || this == cancelled || this == archived;
}

enum EnergyRequirement {
  low,
  medium,
  high,
  unknown,
}

enum AggregateType {
  profile,
  task,
  need,
  checkIn,
  work,
  bill,
  schedule,
  quest,
  project,
  decision,
  research,
  transaction,
  budget,
  health,
  inventory,
  person,
  personInteraction,
  trip,
  organization,
  homeMaintenance,
  commitment,
  syncOperation,
  deviceIdentity,
  contextZone,
  integrationConsent,
  externalCalendarEvent,
  knowledgeArea,
  flashcardDeck,
  flashcard,
  domainEvent,
}

enum EventType {
  profileCreated,
  profileUpdated,
  taskCreated,
  taskUpdated,
  taskStatusChanged,
  taskArchived,
  taskRestored,
  captureCreated,
  exportCompleted,
  exportRestored,
  checkInRecorded,
  needReadingRecorded,
  dailyReviewCompleted,
  weeklyReviewCompleted,
  settingsUpdated,
  workPriorityChanged,
  billCreated,
  billUpdated,
  scheduleBlockCreated,
  scheduleBlockUpdated,
  scheduleBlockDeleted,
  questCreated,
  questUpdated,
  questAccepted,
  questStatusChanged,
  projectCreated,
  projectUpdated,
  decisionCreated,
  decisionUpdated,
  decisionDeleted,
  researchNodeCreated,
  researchStatusChanged,
  researchSessionLogged,
  researchEvidenceCreated,
  financialAccountCreated,
  financialAccountUpdated,
  transactionCreated,
  transactionUpdated,
  transactionDeleted,
  categoryBudgetCreated,
  categoryBudgetUpdated,
  categoryBudgetDeleted,
  healthConditionCreated,
  healthConditionUpdated,
  healthConditionStatusChanged,
  symptomEntryLogged,
  healthAppointmentCreated,
  healthAppointmentUpdated,
  inventoryItemCreated,
  inventoryItemUpdated,
  inventoryItemStatusChanged,
  personCreated,
  personUpdated,
  personArchived,
  personInteractionLogged,
  tripCreated,
  tripUpdated,
  tripStatusChanged,
  organizationCreated,
  organizationUpdated,
  organizationArchived,
  homeMaintenanceCreated,
  homeMaintenanceUpdated,
  homeMaintenanceCompleted,
  homeMaintenanceArchived,
  commitmentCreated,
  commitmentUpdated,
  commitmentStatusChanged,
  syncOperationEnqueued,
  syncOperationAcked,
  deviceIdentityEnsured,
  contextZoneCreated,
  contextZoneUpdated,
  contextZoneArchived,
  integrationConsentGranted,
  integrationConsentRevoked,
  externalCalendarEventsImported,
  knowledgeAreaCreated,
  knowledgeAreaUpdated,
  flashcardDeckCreated,
  flashcardDeckUpdated,
  flashcardCreated,
  flashcardUpdated,
  flashcardReviewed,
  flashcardCatalogSeeded,
}

enum UndoActionType {
  taskCreated,
  taskArchived,
  taskUpdated,
}

enum TimelineSeverity {
  info,
  attention,
  risk,
  critical,
}
