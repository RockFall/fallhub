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

/// Cosmetic locale presets — distinct floors/props/walkable, no travel sim.
abstract final class HabitatLocations {
  static bool isOutdoor(String id) => id == HabitatLocationIds.terrace;

  static String label(String id) => switch (id) {
        HabitatLocationIds.bedroom => 'Quarto',
        HabitatLocationIds.office => 'Escritório',
        HabitatLocationIds.kitchen => 'Cozinha',
        HabitatLocationIds.terrace => 'Terraço',
        _ => id,
      };

  /// Preferred spawn (top-left bias); game snaps to nearest walkable.
  static (int, int) spawn(String id) => switch (id) {
        HabitatLocationIds.bedroom => (5, 6),
        HabitatLocationIds.office => (4, 5),
        HabitatLocationIds.kitchen => (3, 6),
        HabitatLocationIds.terrace => (6, 5),
        _ => (4, 4),
      };

  static HabitatMap create(String id) => switch (id) {
        HabitatLocationIds.bedroom => HabitatMap.demoRoom(),
        HabitatLocationIds.office => _office(),
        HabitatLocationIds.kitchen => _kitchen(),
        HabitatLocationIds.terrace => _terrace(),
        _ => HabitatMap.demoRoom(),
      };

  static HabitatMap _office() {
    const w = 14;
    const h = 10;
    final floors = List<HabitatFloor>.generate(w * h, (i) {
      final x = i % w;
      final y = i ~/ w;
      if (y <= 1) return HabitatFloor.carpet;
      if (x >= w - 3) return HabitatFloor.concrete;
      return HabitatFloor.wood;
    });
    return HabitatMap(
      width: w,
      height: h,
      floors: floors,
      doorCell: (w ~/ 2, h - 1),
      props: [
        HabitatPropCatalog.spawn(
          HabitatPropKinds.table,
          (5, 3),
          id: 'desk',
          tint: StuffPalettes.woodDark,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (5, 5),
          id: 'office_chair',
          tint: StuffPalettes.steel,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.lamp,
          (10, 2),
          id: 'office_lamp',
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (8, 3),
          id: 'guest_chair',
          tint: StuffPalettes.clothBlue,
        ),
      ],
    );
  }

  static HabitatMap _kitchen() {
    const w = 12;
    const h = 10;
    final floors = List<HabitatFloor>.generate(w * h, (_) => HabitatFloor.wood);
    // Work strip of concrete along north interior.
    for (var x = 1; x < w - 1; x++) {
      floors[1 * w + x] = HabitatFloor.concrete;
      floors[2 * w + x] = HabitatFloor.concrete;
    }
    return HabitatMap(
      width: w,
      height: h,
      floors: floors,
      doorCell: (2, h - 1),
      props: [
        HabitatPropCatalog.spawn(
          HabitatPropKinds.table,
          (4, 4),
          id: 'kitchen_table',
          tint: StuffPalettes.wood,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (4, 6),
          id: 'kitchen_chair_a',
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (5, 6),
          id: 'kitchen_chair_b',
          tint: StuffPalettes.woodDark,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.lamp,
          (9, 2),
          id: 'kitchen_lamp',
          tint: StuffPalettes.gold,
        ),
      ],
    );
  }

  static HabitatMap _terrace() {
    const w = 16;
    const h = 12;
    final floors = List<HabitatFloor>.generate(
      w * h,
      (_) => HabitatFloor.concrete,
    );
    // Wooden deck patch in the middle.
    for (var y = 3; y <= 7; y++) {
      for (var x = 4; x <= 11; x++) {
        floors[y * w + x] = HabitatFloor.wood;
      }
    }
    return HabitatMap(
      width: w,
      height: h,
      floors: floors,
      doorCell: (w ~/ 2, 0), // north “exit” to the open
      props: [
        HabitatPropCatalog.spawn(
          HabitatPropKinds.table,
          (7, 4),
          id: 'terrace_table',
          tint: StuffPalettes.woodDark,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (7, 6),
          id: 'terrace_chair_a',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (9, 6),
          id: 'terrace_chair_b',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.lamp,
          (12, 3),
          id: 'terrace_lamp',
          tint: StuffPalettes.steel,
        ),
      ],
    );
  }
}
