import 'dart:math' as math;
import 'dart:ui';

import 'furniture/furniture_def.dart';
import 'furniture/furniture_interactions.dart';
import 'furniture/furniture_registry.dart';
import 'habitat_door.dart';
import 'habitat_prop_catalog.dart';
import 'habitat_tint.dart';

export 'furniture/furniture_def.dart' show HabitatPropAlign, HabitatPropFacing;

/// Floor material for a single cell.
enum HabitatFloor { wood, carpet, concrete }

/// Facing used by pawn sprites (west = flip east).
enum HabitatFacing { south, east, north, west }

/// Visual / stat quality tier (V9.11).
enum HabitatPropQuality {
  normal,
  good,
  excellent;

  double get beautyScale => switch (this) {
        HabitatPropQuality.normal => 1.0,
        HabitatPropQuality.good => 1.25,
        HabitatPropQuality.excellent => 1.5,
      };

  int get comfortBonus => switch (this) {
        HabitatPropQuality.normal => 0,
        HabitatPropQuality.good => 4,
        HabitatPropQuality.excellent => 8,
      };

  double get lightBonus => switch (this) {
        HabitatPropQuality.normal => 0,
        HabitatPropQuality.good => 0.35,
        HabitatPropQuality.excellent => 0.65,
      };

  double get climateScale => switch (this) {
        HabitatPropQuality.normal => 1.0,
        HabitatPropQuality.good => 1.25,
        HabitatPropQuality.excellent => 1.5,
      };

  String get badge => switch (this) {
        HabitatPropQuality.normal => 'N',
        HabitatPropQuality.good => 'B',
        HabitatPropQuality.excellent => 'E',
      };

  HabitatPropQuality next() => switch (this) {
        HabitatPropQuality.normal => HabitatPropQuality.good,
        HabitatPropQuality.good => HabitatPropQuality.excellent,
        HabitatPropQuality.excellent => HabitatPropQuality.normal,
      };
}

/// Furniture / prop on the grid (tint + origin are mutable for the editor).
class HabitatProp {
  HabitatProp({
    required this.id,
    required this.kind,
    required this.name,
    required this.assetPath,
    required this.origin,
    this.size = const (1, 1),
    this.blocksWalk = true,
    this.drawScale = 1.0,
    this.drawSize,
    this.drawAlign = HabitatPropAlign.south,
    this.tint = StuffPalettes.natural,
    this.quality = HabitatPropQuality.normal,
    this.facing = HabitatPropFacing.south,
    this.poweredOn = true,
  });

  final String id;

  /// Catalog kind (`bed`, `dining_chair`, …) — stable for jobs even when [id] is unique.
  final String kind;
  final String name;
  final String assetPath;

  /// Top-left cell of the prop footprint.
  (int, int) origin;

  /// Collision / walk footprint in cells (width, height).
  final (int, int) size;
  final bool blocksWalk;

  /// Legacy uniform scale in tiles when [drawSize] is null.
  final double drawScale;

  /// Visual size in tiles (width, height). May differ from [size] (e.g. bed).
  final (double, double)? drawSize;

  /// Placement of [visualSize] over the collision footprint.
  final HabitatPropAlign drawAlign;

  /// Stuff color multiplied onto the grayscale sprite.
  Color tint;

  /// Normal / Bom / Excelente (V9.11).
  HabitatPropQuality quality;

  /// Sprite facing (west mirrors east).
  HabitatPropFacing facing;

  /// Lights / devices — off dims lamp contribution and TV glow hooks.
  bool poweredOn;

  /// Resolved draw size in tiles.
  (double, double) get visualSize => drawSize ?? (drawScale, drawScale);

  bool covers(int x, int y) {
    final (ox, oy) = origin;
    final (w, h) = size;
    return x >= ox && x < ox + w && y >= oy && y < oy + h;
  }
}

/// Session snapshot for editor undo (V7).
class HabitatMapSnapshot {
  HabitatMapSnapshot({
    required List<HabitatFloor> floors,
    required List<HabitatProp> props,
    required List<double> filth,
    required this.doorCell,
    required Set<(int, int)> customWalls,
    Set<(int, int)>? windowCells,
  })  : floors = List<HabitatFloor>.from(floors),
        props = [
          for (final p in props) HabitatPropCatalog.copyOf(p),
        ],
        filth = List<double>.from(filth),
        customWalls = Set<(int, int)>.from(customWalls),
        windowCells = Set<(int, int)>.from(windowCells ?? const {});

  final List<HabitatFloor> floors;
  final List<HabitatProp> props;
  final List<double> filth;
  final (int, int) doorCell;
  final Set<(int, int)> customWalls;
  final Set<(int, int)> windowCells;
}

/// Room layout — floors, walls, door, furniture (mutable for V7 editor).
class HabitatMap {
  HabitatMap({
    required this.width,
    required this.height,
    required List<HabitatFloor> floors,
    required List<HabitatProp> props,
    (int, int)? doorCell,
    Set<(int, int)>? customWalls,
    Set<(int, int)>? windowCells,
    List<double>? filth,
  })  : floors = List<HabitatFloor>.from(floors),
        props = List<HabitatProp>.from(props),
        filth = filth ?? List<double>.filled(width * height, 0),
        doorCell = doorCell ?? (width ~/ 2, height - 1),
        customWalls = {...?customWalls},
        windowCells = {...?windowCells} {
    assert(floors.length == width * height);
    assert(this.filth.length == width * height);
    door = HabitatDoor(
      cell: this.doorCell,
      slideAxis: HabitatDoorSlideAxis.horizontal,
    );
    door.slideAxis = HabitatDoor.axisAt(this, this.doorCell.$1, this.doorCell.$2);
    rebuildBlocked();
  }

  final int width;
  final int height;
  final List<HabitatFloor> floors;
  final List<HabitatProp> props;

  /// Traffic filth 0..1 per cell (V9.9).
  final List<double> filth;

  /// South-wall doorway cell (walkable gap for pathfinding).
  (int, int) doorCell;

  /// Dual-leaf animated door on [doorCell].
  late final HabitatDoor door;

  /// Extra interior wall cells (perimeter is always wall except [doorCell]).
  final Set<(int, int)> customWalls;

  /// Wall cells marked as windows (still non-walkable; light cue) — M26.
  final Set<(int, int)> windowCells;

  late Set<(int, int)> _blocked;

  HabitatFloor floorAt(int x, int y) => floors[y * width + x];

  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;

  bool isPerimeter(int x, int y) =>
      x == 0 || y == 0 || x == width - 1 || y == height - 1;

  bool isWallCell(int x, int y) {
    if (!inBounds(x, y)) return false;
    if (doorCell == (x, y)) return false;
    if (isPerimeter(x, y)) return true;
    return customWalls.contains((x, y));
  }

  bool isWalkable(int x, int y) => inBounds(x, y) && !_blocked.contains((x, y));

  bool isDoorCell(int x, int y) => doorCell == (x, y);

  /// True when a pawn may not yet step onto [x],[y] because the door is shut.
  bool doorBlocksStep(int x, int y) =>
      isDoorCell(x, y) && door.blocksPassage;

  /// Geometry walkable AND door fully open if this is the doorway.
  bool canStepOnto(int x, int y) =>
      isWalkable(x, y) && !doorBlocksStep(x, y);

  void rebuildBlocked() {
    final next = <(int, int)>{};
    for (var x = 0; x < width; x++) {
      next.add((x, 0));
      next.add((x, height - 1));
    }
    for (var y = 0; y < height; y++) {
      next.add((0, y));
      next.add((width - 1, y));
    }
    next.addAll(customWalls);
    next.remove(doorCell);
    for (final p in props) {
      if (!p.blocksWalk) continue;
      for (var dy = 0; dy < p.size.$2; dy++) {
        for (var dx = 0; dx < p.size.$1; dx++) {
          next.add((p.origin.$1 + dx, p.origin.$2 + dy));
        }
      }
    }
    _blocked = next;
  }

  HabitatMapSnapshot snapshot() => HabitatMapSnapshot(
        floors: floors,
        props: props,
        filth: filth,
        doorCell: doorCell,
        customWalls: customWalls,
        windowCells: windowCells,
      );

  void restore(HabitatMapSnapshot snap) {
    for (var i = 0; i < floors.length && i < snap.floors.length; i++) {
      floors[i] = snap.floors[i];
    }
    for (var i = 0; i < filth.length && i < snap.filth.length; i++) {
      filth[i] = snap.filth[i];
    }
    props
      ..clear()
      ..addAll(snap.props.map(HabitatPropCatalog.copyOf));
    doorCell = snap.doorCell;
    door.reseat(
      doorCell,
      HabitatDoor.axisAt(this, doorCell.$1, doorCell.$2),
    );
    customWalls
      ..clear()
      ..addAll(snap.customWalls);
    windowCells
      ..clear()
      ..addAll(snap.windowCells);
    rebuildBlocked();
  }

  double filthAt(int x, int y) {
    if (!inBounds(x, y)) return 0;
    return filth[y * width + x];
  }

  /// Per successful step deposit (very light — rooms stay clean for a long time).
  static const double trafficFilthPerStep = 0.004;

  /// Chance a step deposits any filth at all.
  static const double trafficFilthChance = 0.18;

  void addTrafficFilth(int x, int y, [double amount = trafficFilthPerStep]) {
    if (!inBounds(x, y) || isWallCell(x, y)) return;
    final i = y * width + x;
    filth[i] = (filth[i] + amount).clamp(0.0, 1.0);
  }

  void cleanCell(int x, int y) {
    if (!inBounds(x, y)) return;
    filth[y * width + x] = 0;
  }

  /// Wipe all traffic filth (play-mode broom / sweep-clean).
  void cleanAll() {
    for (var i = 0; i < filth.length; i++) {
      filth[i] = 0;
    }
  }

  double get averageFilth {
    var sum = 0.0;
    var count = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (isWallCell(x, y)) continue;
        sum += filth[y * width + x];
        count++;
      }
    }
    if (count == 0) return 0;
    return sum / count;
  }

  void setFloor(int x, int y, HabitatFloor floor) {
    if (!inBounds(x, y) || isWallCell(x, y)) return;
    floors[y * width + x] = floor;
  }

  void setDoor((int, int) cell) {
    if (!inBounds(cell.$1, cell.$2)) return;
    // Door only on the outer ring.
    if (!isPerimeter(cell.$1, cell.$2)) return;
    doorCell = cell;
    customWalls.remove(cell);
    door.reseat(cell, HabitatDoor.axisAt(this, cell.$1, cell.$2));
    rebuildBlocked();
  }

  void toggleCustomWall(int x, int y) {
    if (!inBounds(x, y) || isPerimeter(x, y)) return;
    if (doorCell == (x, y)) return;
    final key = (x, y);
    if (customWalls.contains(key)) {
      customWalls.remove(key);
      windowCells.remove(key);
    } else {
      // Don't wall over props — remove prop first or refuse.
      if (propAt(x, y) != null) return;
      customWalls.add(key);
    }
    rebuildBlocked();
  }

  bool canPlace(HabitatProp footprint, (int, int) origin, {String? ignoreId}) {
    final (w, h) = footprint.size;
    for (var dy = 0; dy < h; dy++) {
      for (var dx = 0; dx < w; dx++) {
        final x = origin.$1 + dx;
        final y = origin.$2 + dy;
        if (!inBounds(x, y)) return false;
        if (isWallCell(x, y)) return false;
        final hit = propAt(x, y);
        if (hit != null && hit.id != ignoreId) return false;
      }
    }
    return true;
  }

  bool placeProp(HabitatProp prop) {
    if (!canPlace(prop, prop.origin)) return false;
    props.add(prop);
    rebuildBlocked();
    return true;
  }

  bool moveProp(HabitatProp prop, (int, int) origin) {
    if (!props.contains(prop)) return false;
    if (!canPlace(prop, origin, ignoreId: prop.id)) return false;
    prop.origin = origin;
    rebuildBlocked();
    return true;
  }

  bool removeProp(HabitatProp prop) {
    final ok = props.remove(prop);
    if (ok) rebuildBlocked();
    return ok;
  }

  List<(int, int)> walkableCells() {
    final out = <(int, int)>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (isWalkable(x, y)) out.add((x, y));
      }
    }
    return out;
  }

  HabitatProp? propAt(int x, int y) {
    for (final p in props) {
      if (p.covers(x, y)) return p;
    }
    return null;
  }

  HabitatProp? propByKind(String kind) {
    final resolved = FurnitureRegistry.resolveId(kind);
    for (final p in props) {
      if (p.kind == kind || FurnitureRegistry.resolveId(p.kind) == resolved) {
        return p;
      }
    }
    // Job helpers still ask for legacy 'bed' / 'chair' / 'table'.
    if (kind == 'bed' || kind == HabitatPropKinds.bed) {
      for (final p in props) {
        if (FurnitureInteractions.isSleep(p.kind)) return p;
      }
    }
    if (kind == 'chair' || kind == HabitatPropKinds.chair) {
      for (final p in props) {
        if (FurnitureInteractions.isSit(p.kind)) return p;
      }
    }
    if (kind == 'table' || kind == HabitatPropKinds.table) {
      for (final p in props) {
        if (FurnitureInteractions.isTable(p.kind)) return p;
      }
    }
    return null;
  }

  /// Default living suite — used by tests + bedroom locale.
  factory HabitatMap.demoRoom() => HabitatMap.bedroomPreset();

  /// Quarto + estar + varanda sul (área externa).
  ///
  /// ```
  ///  # sleep (carpet) | living (wood) #
  ///  # bed + lamp     | TV + chairs   #
  ///  #----------------|---------------#
  ///  # hall                             #
  ///  #=========== door to balcony =====#
  ///  # balcony deck + plants (concrete) #
  /// ```
  factory HabitatMap.bedroomPreset() {
    const w = 18;
    const h = 13;
    final floors = List<HabitatFloor>.filled(w * h, HabitatFloor.wood);

    void fill(int x0, int y0, int x1, int y1, HabitatFloor f) {
      for (var y = y0; y <= y1; y++) {
        for (var x = x0; x <= x1; x++) {
          if (x > 0 && x < w - 1 && y > 0 && y < h - 1) {
            floors[y * w + x] = f;
          }
        }
      }
    }

    // Sleeping alcove — soft carpet.
    fill(1, 1, 7, 6, HabitatFloor.carpet);
    // Living / TV zone.
    fill(9, 1, 16, 6, HabitatFloor.wood);
    // Hall.
    fill(1, 7, 16, 8, HabitatFloor.wood);
    // Outdoor balcony.
    fill(1, 9, 16, 11, HabitatFloor.concrete);

    // Partition between sleep and living (opening at y=3..4).
    final walls = <(int, int)>{
      for (var y = 1; y <= 6; y++)
        if (y < 3 || y > 4) (8, y),
    };
    // Wall between hall and balcony with a wide door opening.
    for (var x = 1; x <= 16; x++) {
      if (x < 7 || x > 10) walls.add((x, 8));
    }

    final windows = <(int, int)>{
      (8, 2),
      (8, 5),
      (3, 8),
      (14, 8),
      (1, 10), // balcony side light
      (16, 10),
    };

    return HabitatMap(
      width: w,
      height: h,
      floors: floors,
      doorCell: (w ~/ 2, h - 1),
      customWalls: walls,
      windowCells: windows,
      props: [
        HabitatPropCatalog.spawn(
          'bed',
          (3, 2),
          id: 'bed',
          tint: StuffPalettes.clothBlue,
          quality: HabitatPropQuality.good,
        ),
        HabitatPropCatalog.spawn(
          'end_table',
          (5, 2),
          id: 'nightstand',
          tint: StuffPalettes.woodDark,
        ),
        HabitatPropCatalog.spawn(
          'lamp_standing',
          (6, 2),
          id: 'bed_lamp',
          tint: StuffPalettes.gold,
        ),
        HabitatPropCatalog.spawn(
          'dresser',
          (1, 4),
          id: 'dresser',
          tint: StuffPalettes.wood,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.painting,
          (2, 1),
          id: 'bed_art',
          tint: StuffPalettes.clothRed,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.rug,
          (4, 5),
          id: 'bed_rug',
          tint: StuffPalettes.clothBlue,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.tv,
          (14, 2),
          id: 'tv',
          tint: StuffPalettes.steel,
        ),
        HabitatPropCatalog.spawn(
          'couch',
          (12, 4),
          id: 'sofa',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          'armchair',
          (15, 3),
          id: 'lounge_chair',
          tint: StuffPalettes.clothBlue,
        ),
        HabitatPropCatalog.spawn(
          'end_table',
          (11, 4),
          id: 'coffee_table',
          tint: StuffPalettes.woodDark,
        ),
        HabitatPropCatalog.spawn(
          'bookcase',
          (10, 1),
          id: 'bookcase',
          tint: StuffPalettes.woodDark,
        ),
        HabitatPropCatalog.spawn(
          'lamp_standing',
          (15, 5),
          id: 'living_lamp',
        ),
        HabitatPropCatalog.spawn(
          'plant_pot',
          (16, 1),
          id: 'living_plant',
          tint: StuffPalettes.clothGreen,
        ),
        // Balcony (outdoor strip).
        HabitatPropCatalog.spawn(
          'stool',
          (8, 10),
          id: 'balcony_chair',
          tint: StuffPalettes.wood,
        ),
        HabitatPropCatalog.spawn(
          'plant_pot',
          (3, 10),
          id: 'balcony_plant_a',
          tint: StuffPalettes.clothGreen,
          quality: HabitatPropQuality.good,
        ),
        HabitatPropCatalog.spawn(
          'plant_pot',
          (5, 9),
          id: 'balcony_plant_b',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          'plant_pot',
          (14, 10),
          id: 'balcony_plant_c',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.vase,
          (12, 9),
          id: 'balcony_vase',
          tint: StuffPalettes.woodDark,
        ),
        HabitatPropCatalog.spawn(
          'flood_light',
          (2, 9),
          id: 'balcony_light',
          tint: StuffPalettes.steel,
        ),
      ],
    );
  }

  /// Escritório com luz de pátio interno a leste.
  factory HabitatMap.officePreset() {
    const w = 16;
    const h = 12;
    final floors = List<HabitatFloor>.filled(w * h, HabitatFloor.wood);

    void fill(int x0, int y0, int x1, int y1, HabitatFloor f) {
      for (var y = y0; y <= y1; y++) {
        for (var x = x0; x <= x1; x++) {
          if (x > 0 && x < w - 1 && y > 0 && y < h - 1) {
            floors[y * w + x] = f;
          }
        }
      }
    }

    fill(1, 1, 10, 10, HabitatFloor.carpet);
    // East light-court / outdoor strip.
    fill(12, 1, 14, 10, HabitatFloor.concrete);

    final walls = <(int, int)>{
      for (var y = 1; y <= 10; y++)
        if (y < 4 || y > 6) (11, y),
    };
    final windows = <(int, int)>{
      (11, 3),
      (11, 5),
      (11, 7),
      (14, 2),
      (14, 8),
    };

    return HabitatMap(
      width: w,
      height: h,
      floors: floors,
      doorCell: (5, h - 1),
      customWalls: walls,
      windowCells: windows,
      props: [
        HabitatPropCatalog.spawn(
          HabitatPropKinds.table,
          (3, 3),
          id: 'desk',
          tint: StuffPalettes.woodDark,
          quality: HabitatPropQuality.good,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (3, 5),
          id: 'office_chair',
          tint: StuffPalettes.steel,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.lamp,
          (6, 2),
          id: 'office_lamp',
          tint: StuffPalettes.gold,
          quality: HabitatPropQuality.good,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (7, 4),
          id: 'guest_chair',
          tint: StuffPalettes.clothBlue,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.painting,
          (2, 1),
          id: 'office_art',
          tint: StuffPalettes.clothBlue,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (9, 2),
          id: 'office_plant',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.boardgame,
          (8, 7),
          id: 'shelf_game',
          tint: StuffPalettes.wood,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.heater,
          (2, 8),
          id: 'office_heater',
          tint: StuffPalettes.steel,
        ),
        // Light court (outdoor feel).
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (13, 3),
          id: 'court_plant_a',
          tint: StuffPalettes.clothGreen,
          quality: HabitatPropQuality.excellent,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (12, 7),
          id: 'court_plant_b',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.rug,
          (12, 5),
          id: 'court_mat',
          tint: StuffPalettes.plastic,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.cooler,
          (13, 9),
          id: 'court_breeze',
          tint: StuffPalettes.steel,
        ),
      ],
    );
  }

  /// Cozinha em L + jantar + pátio de serviço a leste.
  factory HabitatMap.kitchenPreset() {
    const w = 16;
    const h = 12;
    final floors = List<HabitatFloor>.filled(w * h, HabitatFloor.wood);

    void fill(int x0, int y0, int x1, int y1, HabitatFloor f) {
      for (var y = y0; y <= y1; y++) {
        for (var x = x0; x <= x1; x++) {
          if (x > 0 && x < w - 1 && y > 0 && y < h - 1) {
            floors[y * w + x] = f;
          }
        }
      }
    }

    // Work counters — concrete L.
    fill(1, 1, 10, 2, HabitatFloor.concrete);
    fill(9, 1, 10, 7, HabitatFloor.concrete);
    // Dining wood.
    fill(1, 3, 7, 8, HabitatFloor.wood);
    // Service patio outdoors.
    fill(12, 1, 14, 10, HabitatFloor.concrete);

    final walls = <(int, int)>{
      for (var y = 1; y <= 10; y++)
        if (y < 5 || y > 7) (11, y),
    };
    final windows = <(int, int)>{
      (11, 5),
      (11, 6),
      (5, 1),
      (14, 4),
    };

    return HabitatMap(
      width: w,
      height: h,
      floors: floors,
      doorCell: (4, h - 1),
      customWalls: walls,
      windowCells: windows,
      props: [
        HabitatPropCatalog.spawn(
          HabitatPropKinds.table,
          (3, 4),
          id: 'kitchen_table',
          tint: StuffPalettes.wood,
          quality: HabitatPropQuality.good,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (3, 6),
          id: 'kitchen_chair_a',
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (5, 6),
          id: 'kitchen_chair_b',
          tint: StuffPalettes.woodDark,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (2, 5),
          id: 'kitchen_chair_c',
          tint: StuffPalettes.clothBlue,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.lamp,
          (7, 3),
          id: 'kitchen_lamp',
          tint: StuffPalettes.gold,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.cooler,
          (9, 3),
          id: 'fridge_zone',
          tint: StuffPalettes.steel,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.heater,
          (9, 6),
          id: 'stove_zone',
          tint: StuffPalettes.steel,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.vase,
          (1, 3),
          id: 'kitchen_vase',
          tint: StuffPalettes.plastic,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (8, 8),
          id: 'kitchen_herb',
          tint: StuffPalettes.clothGreen,
        ),
        // Service patio.
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (13, 2),
          id: 'patio_herb_a',
          tint: StuffPalettes.clothGreen,
          quality: HabitatPropQuality.good,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (12, 4),
          id: 'patio_herb_b',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (13, 7),
          id: 'patio_herb_c',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.chair,
          (12, 8),
          id: 'patio_stool',
          tint: StuffPalettes.wood,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.cooler,
          (13, 9),
          id: 'patio_ice',
          tint: StuffPalettes.steel,
        ),
      ],
    );
  }

  /// Terraço pleno — deck, jardim e caminho.
  factory HabitatMap.terracePreset() {
    const w = 18;
    const h = 14;
    final floors = List<HabitatFloor>.filled(w * h, HabitatFloor.concrete);

    void fill(int x0, int y0, int x1, int y1, HabitatFloor f) {
      for (var y = y0; y <= y1; y++) {
        for (var x = x0; x <= x1; x++) {
          if (x > 0 && x < w - 1 && y > 0 && y < h - 1) {
            floors[y * w + x] = f;
          }
        }
      }
    }

    // Main wooden deck.
    fill(4, 3, 13, 9, HabitatFloor.wood);
    // Soft rug-like carpet island for lounge.
    fill(6, 5, 10, 7, HabitatFloor.carpet);
    // Path from apartment door (north).
    fill(7, 1, 10, 2, HabitatFloor.wood);

    final windows = <(int, int)>{
      (2, 1),
      (15, 1),
      (1, 6),
      (16, 6),
    };

    return HabitatMap(
      width: w,
      height: h,
      floors: floors,
      doorCell: (w ~/ 2, 0), // from apartment
      windowCells: windows,
      props: [
        HabitatPropCatalog.spawn(
          HabitatPropKinds.table,
          (7, 4),
          id: 'terrace_table',
          tint: StuffPalettes.woodDark,
          quality: HabitatPropQuality.good,
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
          HabitatPropKinds.chair,
          (6, 5),
          id: 'terrace_chair_c',
          tint: StuffPalettes.wood,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.lamp,
          (12, 3),
          id: 'terrace_lamp',
          tint: StuffPalettes.steel,
          quality: HabitatPropQuality.good,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.lamp,
          (5, 8),
          id: 'terrace_lamp_b',
          tint: StuffPalettes.gold,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.gatheringSpot,
          (8, 8),
          id: 'terrace_gather',
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (2, 3),
          id: 'garden_a',
          tint: StuffPalettes.clothGreen,
          quality: HabitatPropQuality.excellent,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (2, 5),
          id: 'garden_b',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (2, 8),
          id: 'garden_c',
          tint: StuffPalettes.clothGreen,
          quality: HabitatPropQuality.good,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (15, 3),
          id: 'garden_d',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (15, 6),
          id: 'garden_e',
          tint: StuffPalettes.clothGreen,
          quality: HabitatPropQuality.good,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (15, 9),
          id: 'garden_f',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (4, 11),
          id: 'garden_g',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.plant,
          (12, 11),
          id: 'garden_h',
          tint: StuffPalettes.clothGreen,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.vase,
          (10, 3),
          id: 'terrace_vase',
          tint: StuffPalettes.woodDark,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.instrument,
          (4, 4),
          id: 'terrace_music',
          tint: StuffPalettes.wood,
        ),
        HabitatPropCatalog.spawn(
          HabitatPropKinds.cooler,
          (13, 8),
          id: 'terrace_cooler',
          tint: StuffPalettes.steel,
        ),
      ],
    );
  }
}

extension HabitatFacingX on HabitatFacing {
  String get spriteKey => switch (this) {
        HabitatFacing.south => 'south',
        HabitatFacing.east => 'east',
        HabitatFacing.north => 'north',
        HabitatFacing.west => 'east',
      };

  bool get flipX => this == HabitatFacing.west;
}

HabitatFacing facingFromDelta(int dx, int dy) {
  if (dx.abs() >= dy.abs()) {
    if (dx > 0) return HabitatFacing.east;
    if (dx < 0) return HabitatFacing.west;
  }
  if (dy > 0) return HabitatFacing.south;
  if (dy < 0) return HabitatFacing.north;
  return HabitatFacing.south;
}

/// Chebyshev / Manhattan helpers for wander targeting.
(int, int)? pickWanderTarget({
  required HabitatMap map,
  required (int, int) from,
  required math.Random rng,
  int minDist = 2,
  int maxDist = 6,
  /// Lower values = brighter / more preferred (V9.11 darkness field).
  List<double>? preferBright,
  /// When set, only these cells are valid targets (V9.13).
  Set<(int, int)>? allowed,
}) {
  final cells = map.walkableCells();
  cells.removeWhere((c) {
    if (allowed != null && !allowed.contains(c)) return true;
    final d = (c.$1 - from.$1).abs() + (c.$2 - from.$2).abs();
    return d < minDist || d > maxDist;
  });
  if (cells.isEmpty) return null;
  if (preferBright == null || preferBright.length != map.width * map.height) {
    return cells[rng.nextInt(cells.length)];
  }
  // Weighted pick — prefer lower darkness / comfortable temp when provided.
  var total = 0.0;
  final weights = <double>[];
  for (final c in cells) {
    final w = 1.0 / (0.08 + preferBright[c.$2 * map.width + c.$1]);
    weights.add(w);
    total += w;
  }
  var roll = rng.nextDouble() * total;
  for (var i = 0; i < cells.length; i++) {
    roll -= weights[i];
    if (roll <= 0) return cells[i];
  }
  return cells.last;
}
