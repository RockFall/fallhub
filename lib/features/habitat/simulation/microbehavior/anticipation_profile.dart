import '../embodied/affordance_catalog.dart';

/// Data-driven anticipation before an interaction starts (MD 10 R8).
class AnticipationProfile {
  const AnticipationProfile({
    required this.id,
    this.holdMinSeconds = 0.12,
    this.holdMaxSeconds = 0.40,
    this.lookAtTarget = true,
    this.bodyLean = 0,
    this.repeatInActivityLoop = false,
    this.tags = const {},
  });

  final String id;

  /// Typical 100–500 ms band (R8).
  final double holdMinSeconds;
  final double holdMaxSeconds;

  /// Glance at prop / partner during anticipation.
  final bool lookAtTarget;

  /// 0..1 soft lean toward target (presentation).
  final double bodyLean;

  /// Internal activity beats must not re-run anticipation.
  final bool repeatInActivityLoop;

  final Set<String> tags;

  double holdSecondsFor(double unit) {
    final u = unit.clamp(0.0, 1.0);
    return holdMinSeconds + (holdMaxSeconds - holdMinSeconds) * u;
  }
}

/// Affordance → anticipation map (alterable without touching directors).
abstract final class AnticipationCatalog {
  static const lookApproach = AnticipationProfile(
    id: 'look_approach',
    holdMinSeconds: 0.14,
    holdMaxSeconds: 0.38,
    lookAtTarget: true,
    bodyLean: 0.25,
    tags: {'generic'},
  );

  static const sitPrep = AnticipationProfile(
    id: 'sit_prep',
    holdMinSeconds: 0.12,
    holdMaxSeconds: 0.32,
    lookAtTarget: true,
    bodyLean: 0.35,
    tags: {'seat'},
  );

  static const bedPrep = AnticipationProfile(
    id: 'bed_prep',
    holdMinSeconds: 0.18,
    holdMaxSeconds: 0.48,
    lookAtTarget: true,
    bodyLean: 0.4,
    tags: {'sleep'},
  );

  static const recreatePrep = AnticipationProfile(
    id: 'recreate_prep',
    holdMinSeconds: 0.16,
    holdMaxSeconds: 0.45,
    lookAtTarget: true,
    bodyLean: 0.3,
    tags: {'joy', 'device'},
  );

  static const socialPrep = AnticipationProfile(
    id: 'social_prep',
    holdMinSeconds: 0.15,
    holdMaxSeconds: 0.42,
    lookAtTarget: true,
    bodyLean: 0.2,
    tags: {'social'},
  );

  static const tablePrep = AnticipationProfile(
    id: 'table_prep',
    holdMinSeconds: 0.12,
    holdMaxSeconds: 0.36,
    lookAtTarget: true,
    bodyLean: 0.28,
    tags: {'table', 'meal'},
  );

  static const cleanPrep = AnticipationProfile(
    id: 'clean_prep',
    holdMinSeconds: 0.10,
    holdMaxSeconds: 0.28,
    lookAtTarget: true,
    bodyLean: 0.22,
    tags: {'chore'},
  );

  static const windowGaze = AnticipationProfile(
    id: 'window_gaze',
    holdMinSeconds: 0.20,
    holdMaxSeconds: 0.50,
    lookAtTarget: true,
    bodyLean: 0.15,
    tags: {'window', 'ambient'},
  );

  static const none = AnticipationProfile(
    id: 'none',
    holdMinSeconds: 0.0,
    holdMaxSeconds: 0.05,
    lookAtTarget: false,
  );

  static final Map<String, AnticipationProfile> byAffordance = {
    HabitatAffordances.sit: sitPrep,
    HabitatAffordances.sleep: bedPrep,
    HabitatAffordances.goToTable: tablePrep,
    HabitatAffordances.recreate: recreatePrep,
    HabitatAffordances.watchTv: recreatePrep,
    HabitatAffordances.listenMusic: recreatePrep,
    HabitatAffordances.socialChat: socialPrep,
    HabitatAffordances.clean: cleanPrep,
    HabitatAffordances.rest: sitPrep,
    HabitatAffordances.creativeShort: recreatePrep,
    HabitatAffordances.stretch: lookApproach,
    HabitatAffordances.terraceWalk: lookApproach,
    HabitatAffordances.wander: none,
  };

  static AnticipationProfile forAffordance(String affordanceId) =>
      byAffordance[affordanceId] ?? lookApproach;

  /// At least six named profiles for acceptance (R8).
  static List<AnticipationProfile> get distinctProfiles => [
        lookApproach,
        sitPrep,
        bedPrep,
        recreatePrep,
        socialPrep,
        tablePrep,
        cleanPrep,
        windowGaze,
      ];
}

/// Extension point on affordance definitions without breaking const maps.
extension AffordanceAnticipationX on AffordanceDefinition {
  AnticipationProfile get anticipationProfile =>
      AnticipationCatalog.forAffordance(id);
}
