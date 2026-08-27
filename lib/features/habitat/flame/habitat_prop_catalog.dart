import 'dart:ui';

import 'package:living_habitat_assets/living_habitat_assets.dart';

import 'furniture/furniture.dart';
import 'habitat_map.dart';
import 'habitat_tint.dart';

/// Legacy / procedural blueprint ids still referenced by saves and UI.
abstract final class HabitatPropKinds {
  static const bed = 'bed';
  static const table = 'table';
  static const chair = 'chair';
  static const lamp = 'lamp';
  static const plant = 'plant';
  static const painting = 'painting';
  static const rug = 'rug';
  static const vase = 'vase';
  static const boardgame = 'boardgame';
  static const tv = 'tv';
  static const instrument = 'instrument';
  static const heater = 'heater';
  static const cooler = 'cooler';
  static const gatheringSpot = 'gatheringSpot';

  /// Editor chips: registry furniture first, then procedural leftovers.
  static List<String> get furniture => [
        for (final d in FurnitureRegistry.all)
          if (!d.hasTag(FurnitureTag.beauty) ||
              d.hasTag(FurnitureTag.sit) ||
              d.hasTag(FurnitureTag.sleep) ||
              d.hasTag(FurnitureTag.table) ||
              d.hasTag(FurnitureTag.light) ||
              d.hasTag(FurnitureTag.storage) ||
              d.hasTag(FurnitureTag.plant))
            d.id,
      ];

  static const decor = <String>[
    painting,
    rug,
    vase,
    boardgame,
    instrument,
    gatheringSpot,
  ];

  static List<String> get joy => [
        for (final d in FurnitureRegistry.withTag(FurnitureTag.joy)) d.id,
        boardgame,
        tv,
        instrument,
      ];

  static List<String> get all => FurnitureRegistry.placeableIds;

  static bool isProcedural(String kind) {
    if (FurnitureRegistry.tryGet(kind) != null) return false;
    return switch (kind) {
      painting ||
      rug ||
      vase ||
      boardgame ||
      instrument ||
      heater ||
      cooler ||
      gatheringSpot ||
      plant =>
        true,
      _ => false,
    };
  }

  static bool isJoy(String kind) =>
      FurnitureInteractions.isJoy(kind) ||
      kind == boardgame ||
      kind == tv ||
      kind == instrument;

  static bool isRecreateTarget(String kind) => isJoy(kind);
}

/// Spawns unique prop instances from the furniture registry + procedural decor.
abstract final class HabitatPropCatalog {
  static int _seq = 0;

  /// Sentinel path for Canvas-drawn decor (no PNG).
  static const proceduralAsset = 'procedural';

  static String label(String kind) {
    final def = FurnitureRegistry.tryGet(kind);
    if (def != null) return def.label;
    return switch (kind) {
      HabitatPropKinds.plant => 'Planta',
      HabitatPropKinds.painting => 'Quadro',
      HabitatPropKinds.rug => 'Tapete',
      HabitatPropKinds.vase => 'Vaso',
      HabitatPropKinds.boardgame => 'Jogo',
      HabitatPropKinds.tv => 'TV',
      HabitatPropKinds.instrument => 'Instrumento',
      HabitatPropKinds.heater => 'Aquecedor',
      HabitatPropKinds.cooler => 'Resfriador',
      HabitatPropKinds.gatheringSpot => 'Ponto de encontro',
      HabitatPropKinds.chair => 'Cadeira',
      HabitatPropKinds.table => 'Mesa',
      HabitatPropKinds.lamp => 'Lâmpada',
      HabitatPropKinds.bed => 'Cama',
      _ => kind,
    };
  }

  static String qualityLabel(HabitatPropQuality q) => switch (q) {
        HabitatPropQuality.normal => 'Normal',
        HabitatPropQuality.good => 'Bom',
        HabitatPropQuality.excellent => 'Excelente',
      };

  static String assetPath(
    String kind, {
    HabitatPropFacing facing = HabitatPropFacing.south,
  }) {
    final def = FurnitureRegistry.tryGet(kind);
    if (def != null) return def.assetPath(facing.spriteKey);
    return switch (kind) {
      HabitatPropKinds.tv => HabitatAssets.tvSouth,
      HabitatPropKinds.bed => HabitatAssets.bedSouth,
      HabitatPropKinds.table => HabitatAssets.tableSouth,
      HabitatPropKinds.chair => HabitatAssets.chairSouth,
      HabitatPropKinds.lamp => HabitatAssets.lamp,
      _ => proceduralAsset,
    };
  }

  /// Pixel crop `(x, y, w, h)` — only legacy atlases need this.
  static (double, double, double, double)? srcRect(String kind) => null;

  static HabitatProp spawn(
    String kind,
    (int, int) origin, {
    Color? tint,
    String? id,
    HabitatPropQuality quality = HabitatPropQuality.normal,
    HabitatPropFacing facing = HabitatPropFacing.south,
    bool poweredOn = true,
  }) {
    final resolvedId = id ?? '${kind}_${++_seq}';
    final def = FurnitureRegistry.tryGet(kind);
    if (def != null) {
      final size = def.footprintFor(facing);
      final draw = def.visualSizeFor(facing);
      return HabitatProp(
        id: resolvedId,
        kind: def.id,
        name: def.label,
        assetPath: def.assetPath(facing.spriteKey),
        origin: origin,
        size: size,
        blocksWalk: def.blocksWalk,
        drawSize: draw,
        drawAlign: def.drawAlign,
        tint: tint ?? def.defaultTint ?? StuffPalettes.natural,
        quality: quality,
        facing: facing,
        poweredOn: poweredOn,
      );
    }

    // Legacy alias ids (chair/table/lamp) — resolve then spawn.
    final aliased = FurnitureRegistry.aliases[kind];
    if (aliased != null) {
      return spawn(
        aliased,
        origin,
        tint: tint,
        id: resolvedId,
        quality: quality,
        facing: facing,
        poweredOn: poweredOn,
      );
    }

    return switch (kind) {
      HabitatPropKinds.tv => HabitatProp(
          id: resolvedId,
          kind: HabitatPropKinds.tv,
          name: label(kind),
          assetPath: HabitatAssets.tvSouth,
          origin: origin,
          size: (1, 1),
          blocksWalk: false,
          drawSize: (1.2, 0.9),
          drawAlign: HabitatPropAlign.south,
          tint: tint ?? StuffPalettes.steel,
          quality: quality,
          facing: facing,
          poweredOn: poweredOn,
        ),
      HabitatPropKinds.plant => HabitatProp(
          id: resolvedId,
          kind: 'plant_pot',
          name: FurnitureRegistry.get('plant_pot').label,
          assetPath: FurnitureRegistry.get('plant_pot').assetPath(),
          origin: origin,
          size: (1, 1),
          blocksWalk: false,
          drawSize: (1.0, 1.15),
          tint: tint ?? StuffPalettes.clothGreen,
          quality: quality,
          facing: facing,
        ),
      HabitatPropKinds.painting => HabitatProp(
          id: resolvedId,
          kind: kind,
          name: label(kind),
          assetPath: proceduralAsset,
          origin: origin,
          size: (1, 1),
          blocksWalk: false,
          drawSize: (1.0, 1.0),
          drawAlign: HabitatPropAlign.center,
          tint: tint ?? StuffPalettes.clothBlue,
          quality: quality,
        ),
      HabitatPropKinds.rug => HabitatProp(
          id: resolvedId,
          kind: kind,
          name: label(kind),
          assetPath: proceduralAsset,
          origin: origin,
          size: (2, 2),
          blocksWalk: false,
          drawSize: (2.0, 2.0),
          drawAlign: HabitatPropAlign.center,
          tint: tint ?? StuffPalettes.clothRed,
          quality: quality,
        ),
      HabitatPropKinds.vase => HabitatProp(
          id: resolvedId,
          kind: kind,
          name: label(kind),
          assetPath: proceduralAsset,
          origin: origin,
          size: (1, 1),
          blocksWalk: false,
          drawSize: (0.7, 0.9),
          tint: tint ?? StuffPalettes.gold,
          quality: quality,
        ),
      HabitatPropKinds.boardgame => HabitatProp(
          id: resolvedId,
          kind: kind,
          name: label(kind),
          assetPath: proceduralAsset,
          origin: origin,
          size: (1, 1),
          blocksWalk: false,
          drawSize: (1.0, 0.8),
          drawAlign: HabitatPropAlign.center,
          tint: tint ?? StuffPalettes.wood,
          quality: quality,
        ),
      HabitatPropKinds.instrument => HabitatProp(
          id: resolvedId,
          kind: kind,
          name: label(kind),
          assetPath: proceduralAsset,
          origin: origin,
          size: (1, 1),
          blocksWalk: false,
          drawSize: (0.9, 1.1),
          tint: tint ?? StuffPalettes.gold,
          quality: quality,
        ),
      HabitatPropKinds.heater => HabitatProp(
          id: resolvedId,
          kind: kind,
          name: label(kind),
          assetPath: proceduralAsset,
          origin: origin,
          size: (1, 1),
          blocksWalk: false,
          drawSize: (0.9, 1.0),
          tint: tint ?? StuffPalettes.clothRed,
          quality: quality,
        ),
      HabitatPropKinds.cooler => HabitatProp(
          id: resolvedId,
          kind: kind,
          name: label(kind),
          assetPath: proceduralAsset,
          origin: origin,
          size: (1, 1),
          blocksWalk: false,
          drawSize: (0.9, 1.0),
          tint: tint ?? StuffPalettes.clothBlue,
          quality: quality,
        ),
      HabitatPropKinds.gatheringSpot => HabitatProp(
          id: resolvedId,
          kind: kind,
          name: label(kind),
          assetPath: proceduralAsset,
          origin: origin,
          size: (1, 1),
          blocksWalk: false,
          drawSize: (1.0, 1.0),
          drawAlign: HabitatPropAlign.center,
          tint: tint ?? const Color(0xFF44CCAA),
          quality: quality,
        ),
      _ => HabitatProp(
          id: resolvedId,
          kind: kind,
          name: label(kind),
          assetPath: assetPath(kind, facing: facing),
          origin: origin,
          tint: tint ?? StuffPalettes.natural,
          quality: quality,
          facing: facing,
          poweredOn: poweredOn,
        ),
    };
  }

  static HabitatProp copyOf(HabitatProp src, {(int, int)? origin}) {
    return HabitatProp(
      id: src.id,
      kind: src.kind,
      name: src.name,
      assetPath: src.assetPath,
      origin: origin ?? src.origin,
      size: src.size,
      blocksWalk: src.blocksWalk,
      drawScale: src.drawScale,
      drawSize: src.drawSize,
      drawAlign: src.drawAlign,
      tint: src.tint,
      quality: src.quality,
      facing: src.facing,
      poweredOn: src.poweredOn,
    );
  }
}
