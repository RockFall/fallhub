import 'package:fallhub/features/habitat/flame/furniture/furniture.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_prop_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FurnitureRegistry', () {
    test('exports every Furniture/ dump id', () {
      final ids = FurnitureRegistry.all.map((d) => d.id).toSet();
      expect(ids, containsAll([
        'armchair',
        'dining_chair',
        'couch',
        'bed',
        'double_bed',
        'table_2x2',
        'bookcase',
        'lamp_standing',
        'flood_light',
        'plant_pot',
        'wall_lamp',
      ]));
    });

    test('aliases resolve legacy kinds', () {
      expect(FurnitureRegistry.resolveId('chair'), 'dining_chair');
      expect(FurnitureRegistry.resolveId('table'), 'table_2x2');
      expect(FurnitureRegistry.resolveId('lamp'), 'lamp_standing');
      expect(FurnitureRegistry.tryGet('chair')?.id, 'dining_chair');
    });

    test('tags drive interactions', () {
      expect(FurnitureInteractions.isSit('armchair'), isTrue);
      expect(FurnitureInteractions.isSleep('royal_bed'), isTrue);
      expect(FurnitureInteractions.isLight('flood_light'), isTrue);
      expect(FurnitureInteractions.isJoy('bookcase'), isTrue);
      expect(FurnitureInteractions.jobForUse('dining_chair'), isNotNull);
      expect(FurnitureInteractions.lightRadius('lamp_standing'), greaterThan(0));
    });

    test('spawn uses registry footprint and facing swap', () {
      final south = HabitatPropCatalog.spawn('bed', (2, 2));
      expect(south.size, (1, 2));
      expect(south.kind, 'bed');
      expect(south.assetPath, contains('bed/south.png'));

      final east = HabitatPropCatalog.spawn(
        'bed',
        (2, 2),
        facing: HabitatPropFacing.east,
      );
      expect(east.size, (2, 1));
      expect(east.assetPath, contains('bed/east.png'));
    });

    test('bedroom preset uses new furniture kinds', () {
      final map = HabitatMap.bedroomPreset();
      expect(map.propByKind('bed'), isNotNull);
      expect(map.propByKind('couch'), isNotNull);
      expect(map.propByKind('bookcase'), isNotNull);
      expect(map.propByKind('lamp'), isNotNull); // alias → lamp_standing
      expect(map.props.any((p) => p.kind == 'flood_light'), isTrue);
    });
  });
}
