import 'package:fallhub/features/habitat/simulation/world/context_profile.dart';
import 'package:fallhub/features/habitat/simulation/world/perceived_comfort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two pawns perceive same room differently', () {
    const obj = ObjectiveRoomMetrics(
      beauty: 0.78,
      space: 0.7,
      cleanliness: 0.75,
      light: 0.8,
      temperatureComfort: 0.8,
      quality: 0.7,
    );
    final sys = PerceivedComfortSystem();
    // Force divergent prefs
    sys.prefs['bright'] = const EnvironmentalPreferences(
      lightPreference: 0.95,
      noisePreference: 0.8,
      privacyPreference: 0.85,
      crowdingTolerance: 0.8,
      outdoorPreference: 0.7,
      cozinessPreference: 0.2,
    );
    sys.prefs['cozy'] = const EnvironmentalPreferences(
      lightPreference: 0.2,
      noisePreference: 0.1,
      privacyPreference: 0.1,
      crowdingTolerance: 0.3,
      outdoorPreference: 0.2,
      cozinessPreference: 0.9,
    );
    final a = sys.evaluate(
      pawnId: 'bright',
      roomId: 'bedroom',
      objective: obj,
      context: HabitatContextProfiles.cafe,
    );
    final b = sys.evaluate(
      pawnId: 'cozy',
      roomId: 'bedroom',
      objective: obj,
      context: HabitatContextProfiles.bedroom,
    );
    expect(a.objective, closeTo(b.objective, 0.001));
    expect(a.perceived, isNot(closeTo(b.perceived, 0.02)));
    expect(b.perceived, greaterThan(a.perceived));
  });
}
