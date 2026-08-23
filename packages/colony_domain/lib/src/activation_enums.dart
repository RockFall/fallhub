/// Motor de Ignição — enums de domínio (spec 03, §9–§15).
/// Sem Flutter. Sem persistência.
library;

/// Rota reutilizável entre um estado inicial e um estado operacional.
enum ActivationProtocolType {
  wakeUp,
  hygiene,
  workStart,
  studyStart,
  exerciseStart,
  departure,
  sleepPreparation,
  antiScroll,
  houseReset,
  creativeStart,
  custom,
}

/// Intervalo entre detecção/início e liberação, adaptação ou encerramento.
enum ActivationEpisodeStatus {
  proposed,
  active,
  mobilizing,
  adapted,
  released,
  paused,
  aborted,
  convertedToRecovery,
  falsePositive,
  expired,
  dismissed;

  bool get isOpen =>
      this == proposed ||
      this == active ||
      this == mobilizing ||
      this == adapted ||
      this == paused;

  bool get isTerminal =>
      this == released ||
      this == aborted ||
      this == convertedToRecovery ||
      this == falsePositive ||
      this == expired ||
      this == dismissed;

  bool get isSuccessfulEnough =>
      this == released || this == convertedToRecovery;
}

enum ActivationTriggerType {
  userRequested,
  scheduled,
  automatic,
  external,
  waypoint,
  restoration,
}

enum ActivationCommandRunStatus {
  pending,
  presented,
  evidencePending,
  uncertain,
  confirmed,
  skipped,
  adapted,
  cancelled;

  bool get isOpen =>
      this == pending ||
      this == presented ||
      this == evidencePending ||
      this == uncertain;

  bool get isClosed =>
      this == confirmed ||
      this == skipped ||
      this == adapted ||
      this == cancelled;
}

enum ActivationCapacityMode {
  standard,
  lowCapacity,
  emergencyMinimum,
  highEnergy,
}

enum ActivationProofType {
  manualTap,
  spokenConfirm,
  waypointQr,
  waypointNfc,
  waypointBle,
  waypointWifi,
  stepDelta,
  deviceMotion,
  firstMeaningfulAction,
  scheduleContact,
  userCorrection,
  environmentScene,
}

enum ActivationConfirmationMode {
  manual,
  passive,
  mixed,
  override,
}

enum ActivationWaypointType {
  zone,
  qr,
  nfc,
  bleDock,
  wifi,
  manual,
}

enum ActivationWaypointListenState {
  unknown,
  listening,
  detected,
  confirmed,
  unreliable,
  unavailable,
}

enum InertiaHypothesisType {
  morningBedInertia,
  preTaskAvoidance,
  departureFreeze,
  showerResistance,
  antiScroll,
  nightStall,
  unknown,
}

enum InertiaSignalType {
  alarmDismissed,
  screenActiveMinutes,
  stepDelta,
  bedZonePresence,
  calendarPressure,
  plannedRest,
  explicitStuck,
  distractingUsage,
  historicalContext,
}

enum FrictionShieldState {
  inactive,
  armed,
  active,
  temporarilyReleased,
  released,
  disabled,
}

enum FrictionShieldPlatformMode {
  policyOnly,
  unavailable,
  iosFamilyControls,
  androidUsageAccess,
}

enum ActivationExperimentStatus {
  draft,
  running,
  paused,
  concluded,
  abandoned,
}

enum ActivationInterventionLevel {
  silent,
  badge,
  letter,
  oneCommand,
  route,
  shield,
}

enum ActivationSceneKind {
  audio,
  light,
  haptics,
  focus,
  none,
}

enum RescueContractStatus {
  inactive,
  armed,
  awaitingConfirmation,
  sent,
  cancelled,
}

enum ActivationRouteMaturity {
  experimental,
  reliable,
  compressible,
  internalized,
}
