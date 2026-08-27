/// Background sim LOD + cadences (MD 08 M48).

enum HabitatSimLod {
  /// Visible room — full movement/presentation.
  lod0,
  /// Same site off-camera.
  lod1,
  /// Inactive site — episode approximation.
  lod2,
  /// Dormant — next-interesting-time only.
  lod3,
}

class HabitatSimCadence {
  static const choiceProbeMin = 0.8;
  static const choiceProbeMax = 2.2;
  static const needsSimSeconds = 8.0;
  static const appointmentSimSeconds = 15.0;
  static const backgroundSiteMin = 30.0;
  static const backgroundSiteMax = 300.0;
}

class BackgroundSimScheduler {
  HabitatSimLod lodFor({
    required bool siteVisible,
    required bool sameSite,
    required bool dormant,
  }) {
    if (dormant) return HabitatSimLod.lod3;
    if (siteVisible) return HabitatSimLod.lod0;
    if (sameSite) return HabitatSimLod.lod1;
    return HabitatSimLod.lod2;
  }

  /// Coarse advance for inactive sites — mathematical interval, not 1Hz loops.
  double advanceCoarse({
    required HabitatSimLod lod,
    required double deltaSim,
  }) {
    return switch (lod) {
      HabitatSimLod.lod0 => deltaSim,
      HabitatSimLod.lod1 => deltaSim,
      HabitatSimLod.lod2 => deltaSim, // still apply needs.advance
      HabitatSimLod.lod3 => 0, // wait for nextInterestingTime
    };
  }

  /// Sleeping pawn in invisible site: schedule wake instead of per-second ticks.
  double? nextInterestingTime({
    required bool isSleeping,
    required double nowSim,
    required double wakeCandidateAt,
  }) {
    if (!isSleeping) return null;
    if (wakeCandidateAt <= nowSim) return nowSim;
    return wakeCandidateAt;
  }

  int decisionsThisSecond = 0;

  void noteDecision() => decisionsThisSecond++;

  void resetSecond() => decisionsThisSecond = 0;

  /// Soft budget: choice probes should stay well under 60/s.
  bool get withinBudget => decisionsThisSecond < 8;
}
