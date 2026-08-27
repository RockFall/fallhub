import 'micro_facing.dart';

/// Stable held-item draw anchors by body facing (MD 10 R21).
enum HeldItemAnchor {
  handPrimary,
  handSecondary,
  frontCarry,
  sideCarry,
}

class HeldItemAnchorOffset {
  const HeldItemAnchorOffset({
    required this.dxTiles,
    required this.dyTiles,
    this.zBias = 0,
  });

  final double dxTiles;
  final double dyTiles;
  final double zBias;
}

abstract final class HeldItemAnchorProfile {
  static HeldItemAnchorOffset resolve({
    required MicroFacing facing,
    HeldItemAnchor anchor = HeldItemAnchor.handPrimary,
  }) {
    // Normalized offsets relative to pawn mesh center.
    final primary = switch (facing) {
      MicroFacing.south => const HeldItemAnchorOffset(dxTiles: 0.28, dyTiles: 0.12),
      MicroFacing.north => const HeldItemAnchorOffset(dxTiles: -0.22, dyTiles: -0.05),
      MicroFacing.east => const HeldItemAnchorOffset(dxTiles: 0.32, dyTiles: 0.05),
      MicroFacing.west => const HeldItemAnchorOffset(dxTiles: -0.32, dyTiles: 0.05),
    };
    return switch (anchor) {
      HeldItemAnchor.handPrimary => primary,
      HeldItemAnchor.handSecondary => HeldItemAnchorOffset(
          dxTiles: -primary.dxTiles * 0.85,
          dyTiles: primary.dyTiles,
        ),
      HeldItemAnchor.frontCarry => HeldItemAnchorOffset(
          dxTiles: primary.dxTiles * 0.35,
          dyTiles: primary.dyTiles + 0.08,
          zBias: 1,
        ),
      HeldItemAnchor.sideCarry => HeldItemAnchorOffset(
          dxTiles: primary.dxTiles * 1.15,
          dyTiles: primary.dyTiles - 0.02,
        ),
    };
  }
}
