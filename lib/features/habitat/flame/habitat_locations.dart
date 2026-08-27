import 'habitat_map.dart';
import 'habitat_prop_catalog.dart';
import 'habitat_tint.dart';

/// Preset habitat ids (V8 multi-map).
abstract final class HabitatLocationIds {
  static const bedroom = 'bedroom';
  static const office = 'office';
  static const kitchen = 'kitchen';
  static const terrace = 'terrace';

  static const all = <String>[bedroom, office, kitchen, terrace];
}

/// Thoughtful locale presets — indoor rooms + outdoor strips where it fits.
abstract final class HabitatLocations {
  static bool isOutdoor(String id) => id == HabitatLocationIds.terrace;

  static String label(String id) => switch (id) {
        HabitatLocationIds.bedroom => 'Quarto',
        HabitatLocationIds.office => 'Escritório',
        HabitatLocationIds.kitchen => 'Cozinha',
        HabitatLocationIds.terrace => 'Terraço',
        _ => id,
      };

  /// Preferred spawn; game snaps to nearest walkable.
  static (int, int) spawn(String id) => switch (id) {
        HabitatLocationIds.bedroom => (4, 5),
        HabitatLocationIds.office => (4, 5),
        HabitatLocationIds.kitchen => (5, 5),
        HabitatLocationIds.terrace => (8, 6),
        _ => (4, 4),
      };

  static HabitatMap create(String id) => switch (id) {
        HabitatLocationIds.bedroom => HabitatMap.bedroomPreset(),
        HabitatLocationIds.office => HabitatMap.officePreset(),
        HabitatLocationIds.kitchen => HabitatMap.kitchenPreset(),
        HabitatLocationIds.terrace => HabitatMap.terracePreset(),
        _ => HabitatMap.bedroomPreset(),
      };
}
