/// Work types from spec §18.2.
enum WorkType {
  urgentHealth,
  personalAdmin,
  university,
  mainWork,
  projectA,
  projectB,
  finances,
  home,
  relations,
  music,
  generalLearning,
  exercise,
  travelPlanning,
  restRecreation,
  captureOrganization,
}

/// Priority levels from spec §18.3.
enum PriorityLevel {
  blocked,
  immediate,
  high,
  normal,
  low,
  automatic;

  int? get numericValue => switch (this) {
        PriorityLevel.immediate => 1,
        PriorityLevel.high => 2,
        PriorityLevel.normal => 3,
        PriorityLevel.low => 4,
        PriorityLevel.blocked => 0,
        PriorityLevel.automatic => null,
      };
}

/// Schedule block modes from spec §19.1.
enum ScheduleBlockMode {
  sleep,
  routine,
  focus,
  meeting,
  flexible,
  exercise,
  commute,
  social,
  recreation,
  recovery,
  free,
  unavailable,
}

/// Bill repeat modes from spec §20.2.
enum BillRepeatMode {
  fixed,
  untilState,
  maintainStock,
  interval,
  quotaWindow,
}

abstract final class DefaultWorkTypeSeeds {
  static const core = WorkType.values;
}
