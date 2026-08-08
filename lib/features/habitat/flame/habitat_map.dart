import 'dart:math' as math;
import 'dart:ui';

import 'habitat_prop_catalog.dart';
import 'habitat_tint.dart';

/// Floor material for a single cell.
enum HabitatFloor { wood, carpet, concrete }

/// Facing used by pawn sprites (west = flip east).
enum HabitatFacing { south, east, north, west }

/// How a prop sprite is placed relative to its footprint.
enum HabitatPropAlign {
  /// Centered on the footprint (tables, lamps).
  center,

  /// South / feet edge (beds, chairs that “sit” on the cell).
  south,
}

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
  });

  final String id;

  /// Catalog kind (`bed`, `table`, …) — stable for jobs even when [id] is unique.
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
  })  : floors = List<HabitatFloor>.from(floors),
        props = [
          for (final p in props) HabitatPropCatalog.copyOf(p),
        ],
        filth = List<double>.from(filth),
        customWalls = Set<(int, int)>.from(customWalls);

  final List<HabitatFloor> floors;
  final List<HabitatProp> props;
  final List<double> filth;
  final (int, int) doorCell;
  final Set<(int, int)> customWalls;
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
    List<double>? filth,
  })  : floors = List<HabitatFloor>.from(floors),
        props = List<HabitatProp>.from(props),
        filth = filth ?? List<double>.filled(width * height, 0),
        doorCell = doorCell ?? (width ~/ 2, height - 1),
        customWalls = {...?customWalls} {
    assert(floors.length == width * height);
    assert(this.filth.length == width * height);
    rebuildBlocked();
  }

  final int width;
  final int height;
  final List<HabitatFloor> floors;
  final List<HabitatProp> props;

  /// Traffic filth 0..1 per cell (V9.9).
  final List<double> filth;

  /// South-wall doorway cell (walkable gap).
  (int, int) doorCell;

  /// Extra interior wall cells (perimeter is always wall except [doorCell]).
  final Set<(int, int)> customWalls;

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
    customWalls
      ..clear()
      ..addAll(snap.customWalls);
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
    rebuildBlocked();
  }

  void toggleCustomWall(int x, int y) {
    if (!inBounds(x, y) || isPerimeter(x, y)) return;
    if (doorCell == (x, y)) return;
    final key = (x, y);
    if (customWalls.contains(key)) {
      customWalls.remove(key);
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
    for (final p in props) {
      if (p.kind == kind) return p;
    }
    return null;
  }

  /// Default 16×11 living room for V0/V1.
  factory HabitatMap.demoRoom() {
    const w = 16;
    const h = 11;
    final floors = List<HabitatFloor>.generate(w * h, (i) {
      final x = i % w;
      final y = i ~/ w;
      if (y <= 3) return HabitatFloor.carpet;
      if (x >= 11) return HabitatFloor.concrete;
      return HabitatFloor.wood;
    });

    final props = <HabitatProp>[
      HabitatPropCatalog.spawn(HabitatPropKinds.bed, (2, 2), id: 'bed'),
      HabitatPropCatalog.spawn(HabitatPropKinds.table, (7, 5), id: 'table'),
      HabitatPropCatalog.spawn(HabitatPropKinds.chair, (7, 7), id: 'chair'),
      HabitatPropCatalog.spawn(HabitatPropKinds.lamp, (12, 3), id: 'lamp'),
    ];

    return HabitatMap(width: w, height: h, floors: floors, props: props);
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
