import 'package:fallhub/features/habitat/application/habitat_map_store.dart';
import 'package:fallhub/features/habitat/flame/habitat_locations.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_prop_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('round-trips placed props and floors', () async {
    final map = HabitatLocations.create(HabitatLocationIds.bedroom);
    map.placeProp(
      HabitatPropCatalog.spawn(HabitatPropKinds.plant, (4, 4)),
    );
    map.setFloor(5, 5, HabitatFloor.carpet);

    final world = HabitatWorldSave(
      locationId: HabitatLocationIds.bedroom,
      maps: {HabitatLocationIds.bedroom: map},
    );
    await HabitatMapStore.save(world);

    final loaded = await HabitatMapStore.load();
    expect(loaded, isNotNull);
    expect(loaded!.locationId, HabitatLocationIds.bedroom);
    final restored = loaded.maps[HabitatLocationIds.bedroom]!;
    expect(restored.props.any((p) => p.kind == HabitatPropKinds.plant), isTrue);
    expect(restored.floorAt(5, 5), HabitatFloor.carpet);
  });

  test('preserves quality and custom walls', () async {
    final map = HabitatLocations.create(HabitatLocationIds.bedroom);
    final cells = map.walkableCells();
    final origin = cells.firstWhere(
      (c) => map.propAt(c.$1, c.$2) == null,
    );
    final lamp = HabitatPropCatalog.spawn(
      HabitatPropKinds.lamp,
      origin,
      id: 'lamp_excellent_test',
      quality: HabitatPropQuality.excellent,
    );
    expect(map.placeProp(lamp), isTrue);
    final wallCell = cells.firstWhere(
      (c) =>
          !map.isPerimeter(c.$1, c.$2) &&
          map.propAt(c.$1, c.$2) == null &&
          !map.isWallCell(c.$1, c.$2),
    );
    map.toggleCustomWall(wallCell.$1, wallCell.$2);
    expect(map.customWalls.contains(wallCell), isTrue);

    await HabitatMapStore.save(
      HabitatWorldSave(
        locationId: HabitatLocationIds.bedroom,
        maps: {HabitatLocationIds.bedroom: map},
      ),
    );

    final loaded = await HabitatMapStore.load();
    final restored = loaded!.maps[HabitatLocationIds.bedroom]!;
    final again =
        restored.props.firstWhere((p) => p.id == 'lamp_excellent_test');
    expect(again.quality, HabitatPropQuality.excellent);
    expect(restored.customWalls.contains(wallCell), isTrue);
  });
}
