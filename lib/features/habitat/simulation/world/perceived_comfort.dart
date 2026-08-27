import '../world/context_profile.dart';

/// Environmental taste axes for perceived comfort (MD 08 M25).
class EnvironmentalPreferences {
  const EnvironmentalPreferences({
    this.lightPreference = 0.5,
    this.noisePreference = 0.5,
    this.privacyPreference = 0.5,
    this.crowdingTolerance = 0.5,
    this.outdoorPreference = 0.4,
    this.warmthPreference = 0.5,
    this.orderPreference = 0.5,
    this.cozinessPreference = 0.5,
  });

  /// 0 = prefers dim, 1 = prefers bright.
  final double lightPreference;

  /// 0 = needs quiet, 1 = enjoys busy/loud.
  final double noisePreference;

  /// 0 = needs private, 1 = ok with public.
  final double privacyPreference;
  final double crowdingTolerance;
  final double outdoorPreference;
  final double warmthPreference;
  final double orderPreference;
  final double cozinessPreference;

  factory EnvironmentalPreferences.fromSeed(String pawnId) {
    final h = Object.hash(pawnId, 25);
    double axis(int shift) => ((h >> shift) & 0xff) / 255.0;
    return EnvironmentalPreferences(
      lightPreference: axis(0),
      noisePreference: axis(3),
      privacyPreference: axis(6),
      crowdingTolerance: axis(9),
      outdoorPreference: axis(12),
      warmthPreference: 0.35 + 0.4 * axis(15),
      orderPreference: axis(18),
      cozinessPreference: axis(21),
    );
  }
}

/// Objective room metrics already available / derived (M25).
class ObjectiveRoomMetrics {
  const ObjectiveRoomMetrics({
    this.beauty = 0.6,
    this.space = 0.7,
    this.cleanliness = 0.7,
    this.light = 0.65,
    this.temperatureComfort = 0.8,
    this.quality = 0.65,
  });

  final double beauty;
  final double space;
  final double cleanliness;
  final double light;
  final double temperatureComfort;
  final double quality;

  double get composite =>
      (beauty * 0.2 +
              space * 0.15 +
              cleanliness * 0.15 +
              light * 0.15 +
              temperatureComfort * 0.2 +
              quality * 0.15)
          .clamp(0.0, 1.0);
}

/// How a specific pawn experiences a room (M25).
class PerceivedEnvironmentFit {
  const PerceivedEnvironmentFit({
    required this.pawnId,
    required this.roomId,
    required this.objective,
    required this.perceived,
    required this.delta,
    this.notes = const [],
  });

  final String pawnId;
  final String roomId;
  final double objective;
  final double perceived;
  final double delta;
  final List<String> notes;
}

/// Computes per-pawn perceived comfort without replacing beauty (M25).
class PerceivedComfortSystem {
  final Map<String, EnvironmentalPreferences> prefs = {};

  EnvironmentalPreferences prefsFor(String pawnId) =>
      prefs.putIfAbsent(pawnId, () => EnvironmentalPreferences.fromSeed(pawnId));

  PerceivedEnvironmentFit evaluate({
    required String pawnId,
    required String roomId,
    required ObjectiveRoomMetrics objective,
    required HabitatContextProfile context,
    bool isOutdoor = false,
  }) {
    final p = prefsFor(pawnId);
    final obj = objective.composite;
    final notes = <String>[];
    var perceived = obj;

    final lightGap = (objective.light - p.lightPreference).abs();
    perceived -= lightGap * 0.18;
    if (lightGap > 0.35) notes.add('light mismatch');

    final noiseLevel = switch (context.noise) {
      NoiseProfile.silent => 0.05,
      NoiseProfile.quiet => 0.25,
      NoiseProfile.normal => 0.5,
      NoiseProfile.busy => 0.75,
      NoiseProfile.loud => 0.95,
    };
    final noiseGap = (noiseLevel - p.noisePreference).abs();
    perceived -= noiseGap * 0.22;
    if (noiseGap > 0.4) notes.add('noise mismatch');

    final privacyLevel = switch (context.privacy) {
      PrivacyProfile.private => 0.1,
      PrivacyProfile.semiPrivate => 0.4,
      PrivacyProfile.shared => 0.7,
      PrivacyProfile.public => 0.95,
    };
    final privacyGap = (privacyLevel - p.privacyPreference).abs();
    perceived -= privacyGap * 0.2;
    if (privacyGap > 0.4) notes.add('privacy mismatch');

    final crowd = switch (context.socialDensity) {
      SocialDensityProfile.empty => 0.05,
      SocialDensityProfile.sparse => 0.25,
      SocialDensityProfile.normal => 0.5,
      SocialDensityProfile.crowded => 0.9,
    };
    if (crowd > p.crowdingTolerance) {
      perceived -= (crowd - p.crowdingTolerance) * 0.15;
      notes.add('crowded');
    }

    if (isOutdoor) {
      perceived += (p.outdoorPreference - 0.5) * 0.2;
      if (p.outdoorPreference > 0.65) notes.add('likes outdoors');
    }

    final cozySignal = (1 - noiseLevel) * 0.4 +
        (1 - privacyLevel) * 0.3 +
        objective.beauty * 0.3;
    perceived += (p.cozinessPreference - 0.5) * cozySignal * 0.25;

    perceived = perceived.clamp(0.05, 0.98);
    return PerceivedEnvironmentFit(
      pawnId: pawnId,
      roomId: roomId,
      objective: obj,
      perceived: perceived,
      delta: perceived - obj,
      notes: notes,
    );
  }
}
