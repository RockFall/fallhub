import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('every protocol seed has a visual journey', () {
    final keys = {for (final spec in ActivationProtocolSeeds.catalog) spec.key};
    final visual = {for (final spec in ActivationVisualCatalog.catalog) spec.seedKey};
    expect(visual, keys);
    for (final spec in ActivationVisualCatalog.catalog) {
      expect(spec.stations, isNotEmpty);
      expect(spec.artAsset, startsWith('assets/activation/'));
      expect(spec.journeyLabel, isNotEmpty);
    }
  });

  test('canonical waypoints cover morning desk door and docks', () {
    final keys = {for (final spec in ActivationWaypointSeeds.catalog) spec.key};
    expect(
      keys,
      containsAll([
        'bed',
        'bathroom_dock',
        'kitchen_light',
        'desk_dock',
        'front_door',
        'piano_bench',
        'exercise_mat',
      ]),
    );
    expect(ActivationWaypointSeeds.catalog.length, 7);
  });

  test('station index follows destination then run progress', () {
    final spec = ActivationVisualCatalog.bySeedKey('morning_launch_standard')!;
    expect(
      ActivationVisualCatalog.stationIndex(
        spec: spec,
        destinationRef: 'desk',
      ),
      spec.stations.indexWhere((s) => s.key == 'desk'),
    );
    expect(
      ActivationVisualCatalog.stationIndex(
        spec: spec,
        runIndex: 0,
        runCount: spec.stations.length,
      ),
      0,
    );
  });
}
