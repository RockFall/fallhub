import 'habitat_beauty.dart';
import 'habitat_locations.dart';
import 'habitat_map.dart';
import 'habitat_prop_catalog.dart';

/// Cosmetic room role derived from props / locale (V9.7).
enum HabitatRoomRole {
  bedroom,
  dining,
  office,
  exterior,
  generic,
}

/// Impressiveness ladder from aggregate meters.
enum HabitatImpressiveness {
  mediocre,
  pleasant,
  nice,
  glorious,
}

/// One line in the expanded strip breakdown.
class HabitatRoomStatLine {
  const HabitatRoomStatLine(this.label, this.delta);

  final String label;
  final int delta;
}

/// Snapshot of cosmetic room stats for the current map.
class HabitatRoomStats {
  const HabitatRoomStats({
    required this.role,
    required this.beauty,
    required this.space,
    required this.cleanliness,
    required this.wealth,
    required this.comfort,
    required this.impressiveness,
    required this.breakdown,
  });

  final HabitatRoomRole role;
  final int beauty;
  final int space;
  final int cleanliness;
  final int wealth;
  final int comfort;
  final HabitatImpressiveness impressiveness;
  final List<HabitatRoomStatLine> breakdown;

  int get average =>
      ((beauty + space + cleanliness + wealth + comfort) / 5)
          .round()
          .clamp(0, 100);

  bool get spaceTight => space < 40;
  bool get beautyHigh => beauty >= 65;

  static HabitatRoomStats empty = const HabitatRoomStats(
    role: HabitatRoomRole.generic,
    beauty: 0,
    space: 0,
    cleanliness: 0,
    wealth: 0,
    comfort: 0,
    impressiveness: HabitatImpressiveness.mediocre,
    breakdown: [],
  );
}

/// Pure heuristics over [HabitatMap] (+ optional locale id).
abstract final class HabitatRoomAnalyzer {
  static HabitatRoomStats analyze(HabitatMap map, {String? locationId}) {
    final kinds = <String, int>{};
    for (final p in map.props) {
      kinds[p.kind] = (kinds[p.kind] ?? 0) + 1;
    }
    final beds = kinds[HabitatPropKinds.bed] ?? 0;
    final tables = kinds[HabitatPropKinds.table] ?? 0;
    final chairs = kinds[HabitatPropKinds.chair] ?? 0;
    final lamps = kinds[HabitatPropKinds.lamp] ?? 0;
    final plants = kinds[HabitatPropKinds.plant] ?? 0;
    final paintings = kinds[HabitatPropKinds.painting] ?? 0;
    final rugs = kinds[HabitatPropKinds.rug] ?? 0;
    final vases = kinds[HabitatPropKinds.vase] ?? 0;

    final role = _role(
      locationId: locationId,
      beds: beds,
      tables: tables,
      chairs: chairs,
      lamps: lamps,
    );

    final breakdown = <HabitatRoomStatLine>[];
    var wealth = 18;
    // Meter beauty comes from the V9.8 field (floors + props + LOS).
    var beauty = HabitatBeautyField.aggregate(map);

    void noteBeauty(String label, int d) {
      if (d == 0) return;
      breakdown.add(HabitatRoomStatLine(label, d));
    }

    void addWealth(String label, int d) {
      if (d == 0) return;
      wealth += d;
      if (!breakdown.any((b) => b.label == label)) {
        breakdown.add(HabitatRoomStatLine(label, d));
      }
    }

    var wood = 0, carpet = 0;
    for (var i = 0; i < map.floors.length; i++) {
      final x = i % map.width;
      final y = i ~/ map.width;
      if (map.isPerimeter(x, y) && (x, y) != map.doorCell) continue;
      switch (map.floors[i]) {
        case HabitatFloor.wood:
          wood++;
        case HabitatFloor.carpet:
          carpet++;
        case HabitatFloor.concrete:
          break;
      }
    }
    noteBeauty('Carpete', (carpet * 0.35).round().clamp(0, 22));
    noteBeauty('Madeira', (wood * 0.18).round().clamp(0, 14));
    addWealth('Piso', ((carpet * 0.2) + (wood * 0.12)).round().clamp(0, 16));

    if (beds > 0) {
      noteBeauty('Cama', HabitatBeautyField.emitForKind(HabitatPropKinds.bed));
      addWealth('Cama', 14 + (beds - 1) * 5);
    }
    if (tables > 0) {
      noteBeauty('Mesa', HabitatBeautyField.emitForKind(HabitatPropKinds.table));
      addWealth('Mesa', 12 + (tables - 1) * 4);
    }
    if (chairs > 0) {
      noteBeauty(
        'Cadeira',
        HabitatBeautyField.emitForKind(HabitatPropKinds.chair) * chairs,
      );
      addWealth('Cadeira', 5 + (chairs - 1) * 2);
    }
    if (lamps > 0) {
      noteBeauty(
        'Lâmpada',
        HabitatBeautyField.emitForKind(HabitatPropKinds.lamp),
      );
      addWealth('Lâmpada', 8 + (lamps - 1) * 3);
    }
    if (plants > 0) {
      noteBeauty(
        'Planta',
        HabitatBeautyField.emitForKind(HabitatPropKinds.plant) * plants,
      );
      addWealth('Planta', 6 * plants);
    }
    if (paintings > 0) {
      noteBeauty(
        'Quadro',
        HabitatBeautyField.emitForKind(HabitatPropKinds.painting) * paintings,
      );
      addWealth('Quadro', 10 * paintings);
    }
    if (rugs > 0) {
      noteBeauty(
        'Tapete',
        HabitatBeautyField.emitForKind(HabitatPropKinds.rug) * rugs,
      );
      addWealth('Tapete', 7 * rugs);
    }
    if (vases > 0) {
      noteBeauty(
        'Vaso',
        HabitatBeautyField.emitForKind(HabitatPropKinds.vase) * vases,
      );
      addWealth('Vaso', 5 * vases);
    }

    final walkable = map.walkableCells().length;
    final interior = map.width * map.height -
        _perimeterCellCount(map.width, map.height) +
        1; // door gap
    final spaceRaw = interior <= 0
        ? 50
        : (walkable / interior * 100);
    // Extra furniture crowding penalty.
    final footprint = map.props.fold<int>(
      0,
      (n, p) => n + p.size.$1 * p.size.$2,
    );
    final crowding = (footprint / (walkable + 1) * 35).clamp(0.0, 40.0);
    final space = (spaceRaw - crowding).round().clamp(0, 100);

    // V9.9 — filth drives cleanliness.
    final avgFilth = map.averageFilth;
    var cleanliness =
        (100 - avgFilth * 90).round() - (map.props.length * 2) - (carpet * 0.05).round();
    cleanliness = cleanliness.clamp(20, 98);
    if (avgFilth > 0.08) {
      breakdown.add(
        HabitatRoomStatLine('Sujeira', -(avgFilth * 90).round()),
      );
    }

    // V9.11 — comfort from seating, beds, lamps, quality.
    var comfort = 42;
    for (final p in map.props) {
      comfort += switch (p.kind) {
        HabitatPropKinds.chair => 8,
        HabitatPropKinds.bed => 12,
        HabitatPropKinds.lamp => 5,
        HabitatPropKinds.rug => 4,
        _ => 0,
      };
      comfort += p.quality.comfortBonus;
    }
    comfort = comfort.clamp(0, 100);

    beauty = beauty.clamp(0, 100);
    wealth = wealth.clamp(0, 100);

    final avg = ((beauty + space + cleanliness + wealth + comfort) / 5).round();
    final impressiveness = switch (avg) {
      < 35 => HabitatImpressiveness.mediocre,
      < 55 => HabitatImpressiveness.pleasant,
      < 75 => HabitatImpressiveness.nice,
      _ => HabitatImpressiveness.glorious,
    };

    // Keep breakdown short for the strip.
    breakdown.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    final top = breakdown.take(5).toList(growable: false);

    return HabitatRoomStats(
      role: role,
      beauty: beauty,
      space: space,
      cleanliness: cleanliness,
      wealth: wealth,
      comfort: comfort,
      impressiveness: impressiveness,
      breakdown: top,
    );
  }

  static HabitatRoomRole _role({
    required String? locationId,
    required int beds,
    required int tables,
    required int chairs,
    required int lamps,
  }) {
    // Locale presets win when known (terrace stays exterior even with furniture).
    if (locationId == HabitatLocationIds.terrace) {
      return HabitatRoomRole.exterior;
    }
    if (beds > 0 || locationId == HabitatLocationIds.bedroom) {
      return HabitatRoomRole.bedroom;
    }
    if (locationId == HabitatLocationIds.kitchen) {
      return HabitatRoomRole.dining;
    }
    if (locationId == HabitatLocationIds.office) {
      return HabitatRoomRole.office;
    }
    // Prop-only heuristics (edited maps / unknown locale).
    if (tables > 0 && chairs >= 2) return HabitatRoomRole.dining;
    if (tables > 0 && lamps > 0) return HabitatRoomRole.office;
    if (lamps > 0 && chairs > 0) return HabitatRoomRole.office;
    if (tables > 0 && chairs > 0) return HabitatRoomRole.dining;
    return HabitatRoomRole.generic;
  }

  static int _perimeterCellCount(int w, int h) {
    if (w < 2 || h < 2) return w * h;
    return 2 * (w + h) - 4;
  }
}
