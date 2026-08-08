enum CalculationMode {
  manual,
  ruleBased,
  imported,
  hybrid,
}

enum RefreshPolicy {
  event,
  hourly,
  daily,
  onOpen,
}

enum NeedPrivacyClass {
  standard,
  sensitive,
  highlySensitive,
}

enum MoodScale {
  five,
  seven,
}

enum MoodFactorKind {
  userConfirmed,
  suggested,
}
