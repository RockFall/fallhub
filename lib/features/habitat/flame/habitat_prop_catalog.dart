import 'dart:ui';



import 'package:living_habitat_assets/living_habitat_assets.dart';



import 'habitat_map.dart';

import 'habitat_tint.dart';



/// Blueprint ids for placeable furniture + decor (V7 / V9.8+).

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



  static const furniture = <String>[bed, table, chair, lamp, heater, cooler];

  static const decor = <String>[

    plant,

    painting,

    rug,

    vase,

    boardgame,

    tv,

    instrument,

    gatheringSpot,

  ];

  static const joy = <String>[boardgame, tv, instrument, plant];

  static const all = <String>[...furniture, ...decor];



  static bool isProcedural(String kind) => decor.contains(kind);



  static bool isJoy(String kind) => joy.contains(kind);



  static bool isRecreateTarget(String kind) => joy.contains(kind);

}



/// Spawns unique prop instances from the V0+ furniture catalog + procedural decor.

abstract final class HabitatPropCatalog {

  static int _seq = 0;



  /// Sentinel path for Canvas-drawn decor (no PNG).

  static const proceduralAsset = 'procedural';



  static String label(String kind) => switch (kind) {

        HabitatPropKinds.bed => 'Cama',

        HabitatPropKinds.table => 'Mesa',

        HabitatPropKinds.chair => 'Cadeira',

        HabitatPropKinds.lamp => 'Lâmpada',

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

        _ => kind,

      };



  static String qualityLabel(HabitatPropQuality q) => switch (q) {

        HabitatPropQuality.normal => 'Normal',

        HabitatPropQuality.good => 'Bom',

        HabitatPropQuality.excellent => 'Excelente',

      };



  static String assetPath(String kind) => switch (kind) {

        HabitatPropKinds.bed => HabitatAssets.bedSouth,

        HabitatPropKinds.table => HabitatAssets.tableSouth,

        HabitatPropKinds.chair => HabitatAssets.chairSouth,

        HabitatPropKinds.lamp => HabitatAssets.lamp,

        HabitatPropKinds.plant ||

        HabitatPropKinds.painting ||

        HabitatPropKinds.rug ||

        HabitatPropKinds.vase ||

        HabitatPropKinds.boardgame ||

        HabitatPropKinds.tv ||

        HabitatPropKinds.instrument ||

        HabitatPropKinds.heater ||

        HabitatPropKinds.cooler =>

          proceduralAsset,

        _ => HabitatAssets.lamp,

      };



  /// Pixel crop `(x, y, w, h)` of opaque art inside the atlas PNG.

  static (double, double, double, double)? srcRect(String kind) =>

      switch (kind) {

        HabitatPropKinds.bed => (29, 0, 70, 128),

        _ => null,

      };



  static HabitatProp spawn(

    String kind,

    (int, int) origin, {

    Color? tint,

    String? id,

    HabitatPropQuality quality = HabitatPropQuality.normal,

  }) {

    final resolvedId = id ?? '${kind}_${++_seq}';

    return switch (kind) {

      HabitatPropKinds.bed => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.bed,

          name: label(kind),

          assetPath: assetPath(kind),

          origin: origin,

          size: (1, 2),

          drawSize: (1.0, 2.0),

          drawAlign: HabitatPropAlign.south,

          tint: tint ?? StuffPalettes.clothBlue,

          quality: quality,

        ),

      HabitatPropKinds.table => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.table,

          name: label(kind),

          assetPath: assetPath(kind),

          origin: origin,

          size: (2, 2),

          drawSize: (4.4, 4.4),

          drawAlign: HabitatPropAlign.center,

          tint: tint ?? StuffPalettes.wood,

          quality: quality,

        ),

      HabitatPropKinds.chair => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.chair,

          name: label(kind),

          assetPath: assetPath(kind),

          origin: origin,

          size: (1, 1),

          drawSize: (1.35, 1.35),

          drawAlign: HabitatPropAlign.south,

          tint: tint ?? StuffPalettes.woodDark,

          quality: quality,

        ),

      HabitatPropKinds.lamp => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.lamp,

          name: label(kind),

          assetPath: assetPath(kind),

          origin: origin,

          size: (1, 1),

          blocksWalk: false,

          drawSize: (1.25, 1.25),

          drawAlign: HabitatPropAlign.center,

          tint: tint ?? StuffPalettes.steel,

          quality: quality,

        ),

      HabitatPropKinds.plant => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.plant,

          name: label(kind),

          assetPath: proceduralAsset,

          origin: origin,

          size: (1, 1),

          blocksWalk: false,

          drawSize: (1.1, 1.3),

          drawAlign: HabitatPropAlign.south,

          tint: tint ?? StuffPalettes.clothGreen,

          quality: quality,

        ),

      HabitatPropKinds.painting => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.painting,

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

          kind: HabitatPropKinds.rug,

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

          kind: HabitatPropKinds.vase,

          name: label(kind),

          assetPath: proceduralAsset,

          origin: origin,

          size: (1, 1),

          blocksWalk: false,

          drawSize: (0.7, 0.9),

          drawAlign: HabitatPropAlign.south,

          tint: tint ?? StuffPalettes.gold,

          quality: quality,

        ),

      HabitatPropKinds.boardgame => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.boardgame,

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

      HabitatPropKinds.tv => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.tv,

          name: label(kind),

          assetPath: proceduralAsset,

          origin: origin,

          size: (1, 1),

          blocksWalk: false,

          drawSize: (1.2, 0.9),

          drawAlign: HabitatPropAlign.south,

          tint: tint ?? StuffPalettes.steel,

          quality: quality,

        ),

      HabitatPropKinds.instrument => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.instrument,

          name: label(kind),

          assetPath: proceduralAsset,

          origin: origin,

          size: (1, 1),

          blocksWalk: false,

          drawSize: (0.9, 1.1),

          drawAlign: HabitatPropAlign.south,

          tint: tint ?? StuffPalettes.gold,

          quality: quality,

        ),

      HabitatPropKinds.heater => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.heater,

          name: label(kind),

          assetPath: proceduralAsset,

          origin: origin,

          size: (1, 1),

          blocksWalk: false,

          drawSize: (0.9, 1.0),

          drawAlign: HabitatPropAlign.south,

          tint: tint ?? StuffPalettes.clothRed,

          quality: quality,

        ),

      HabitatPropKinds.cooler => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.cooler,

          name: label(kind),

          assetPath: proceduralAsset,

          origin: origin,

          size: (1, 1),

          blocksWalk: false,

          drawSize: (0.9, 1.0),

          drawAlign: HabitatPropAlign.south,

          tint: tint ?? StuffPalettes.clothBlue,

          quality: quality,

        ),

      HabitatPropKinds.gatheringSpot => HabitatProp(

          id: resolvedId,

          kind: HabitatPropKinds.gatheringSpot,

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

          assetPath: assetPath(kind),

          origin: origin,

          tint: tint ?? StuffPalettes.natural,

          quality: quality,

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

    );

  }

}


