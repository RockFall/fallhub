import 'dart:ui';

import 'furniture_tags.dart';

/// How a prop sprite is placed relative to its footprint.
enum HabitatPropAlign {
  /// Centered on the footprint (tables, lamps).
  center,

  /// South / feet edge (beds, chairs that “sit” on the cell).
  south,
}

/// How many directional sprites a def ships.
enum FurnitureFacingMode {
  /// One sprite (usually treated as south).
  single,

  /// south / east / north (west = flip east).
  cardinal,
}

/// Primary pawn interaction for this furniture family.
enum FurnitureUse {
  none,
  sit,
  sleep,
  sitAtTable,
  recreate,
  toggleLight,
  admire,
}

/// Facing stored on placed props (west mirrors east sprite).
enum HabitatPropFacing {
  south,
  east,
  north,
  west;

  String get spriteKey => switch (this) {
        HabitatPropFacing.south => 'south',
        HabitatPropFacing.east || HabitatPropFacing.west => 'east',
        HabitatPropFacing.north => 'north',
      };

  bool get flipX => this == HabitatPropFacing.west;

  HabitatPropFacing get next => switch (this) {
        HabitatPropFacing.south => HabitatPropFacing.east,
        HabitatPropFacing.east => HabitatPropFacing.north,
        HabitatPropFacing.north => HabitatPropFacing.west,
        HabitatPropFacing.west => HabitatPropFacing.south,
      };
}

/// Immutable blueprint for a placeable furniture piece.
///
/// New pieces = new [FurnitureDef] in the registry + assets under
/// `assets/v0/furniture/<id>/`. Call sites should query tags/use — not switch
/// on every id.
class FurnitureDef {
  const FurnitureDef({
    required this.id,
    required this.label,
    required this.footprint,
    this.blocksWalk = true,
    this.drawAlign = HabitatPropAlign.south,
    this.drawSize,
    this.pixelsPerTile,
    this.facingMode = FurnitureFacingMode.single,
    this.tags = const {},
    this.use = FurnitureUse.none,
    this.lightRadius,
    this.beauty = 0,
    this.defaultTint,
    this.hasBeddingMask = false,
  });

  final String id;
  final String label;

  /// Footprint when facing south (east/west swaps width/height).
  final (int, int) footprint;
  final bool blocksWalk;
  final HabitatPropAlign drawAlign;

  /// Optional explicit visual size in tiles (procedural / rare overrides).
  /// Sprite props prefer [pixelsPerTile] scaling — see [furnitureDrawSizePx].
  final (double, double)? drawSize;

  /// Source pixels that map to one world tile (RimWorld-style).
  ///
  /// Default [kDefaultFurniturePixelsPerTile] (64). Use 128 only when the
  /// atlas was authored at double resolution per cell.
  final double? pixelsPerTile;
  final FurnitureFacingMode facingMode;
  final Set<FurnitureTag> tags;
  final FurnitureUse use;

  /// Soft lamp radius in tiles (only when [FurnitureTag.light]).
  final double? lightRadius;

  /// Base beauty contribution (scaled by quality later).
  final double beauty;
  final Color? defaultTint;

  /// RimWorld-style bedding overlay (`south_mask.png`, …) for sleep layering.
  final bool hasBeddingMask;

  bool hasTag(FurnitureTag tag) => tags.contains(tag);

  (int, int) footprintFor(HabitatPropFacing facing) {
    final (w, h) = footprint;
    return switch (facing) {
      HabitatPropFacing.south || HabitatPropFacing.north => (w, h),
      HabitatPropFacing.east || HabitatPropFacing.west => (h, w),
    };
  }

  (double, double) visualSizeFor(HabitatPropFacing facing) {
    final base = drawSize ?? (footprint.$1.toDouble(), footprint.$2.toDouble());
    return switch (facing) {
      HabitatPropFacing.south || HabitatPropFacing.north => base,
      HabitatPropFacing.east || HabitatPropFacing.west => (base.$2, base.$1),
    };
  }

  /// Package-relative asset path for a facing key (`south`, `east`, `north`).
  String assetPath([String facing = 'south']) {
    final key = facingMode == FurnitureFacingMode.single ? 'south' : facing;
    return 'assets/v0/furniture/$id/$key.png';
  }

  String? maskPath([String facing = 'south']) {
    if (!hasBeddingMask) return null;
    final key = facingMode == FurnitureFacingMode.single ? 'south' : facing;
    return 'assets/v0/furniture/$id/${key}_mask.png';
  }
}
