import 'dart:math' as math;

import 'furniture_def.dart';

/// RimWorld-ish: most Building graphics are authored against a 64px cell.
const double kDefaultFurniturePixelsPerTile = 64;

/// Pixel size that covers [boxW]×[boxH] while keeping [aspect] (width/height).
///
/// Prefer [furnitureDrawSizePx] for placed props — cover fills the cell and
/// upscales small lamps/plants.
(double, double) furnitureFitCover({
  required double boxW,
  required double boxH,
  required double aspect,
}) {
  assert(aspect > 0 && boxW > 0 && boxH > 0);
  final boxAspect = boxW / boxH;
  if (boxAspect > aspect) {
    final drawW = boxW;
    return (drawW, drawW / aspect);
  }
  final drawH = boxH;
  return (drawH * aspect, drawH);
}

/// Native sprite scale: `srcPx / pixelsPerTile` tiles.
///
/// - Lamp ~30×43 @ 64ppt → ~0.47×0.67 tiles (small, sharp)
/// - Bed ~68×128 @ 64ppt → ~1.06×2.0 tiles (fills 1×2; slight width OK)
/// - Only clamps when the sprite would dwarf the footprint (bad/huge atlas)
(double, double) furnitureDrawSizePx({
  required double srcW,
  required double srcH,
  required double tileSize,
  required double footW,
  required double footH,
  double pixelsPerTile = kDefaultFurniturePixelsPerTile,
  double maxFootprintScale = 1.25,
}) {
  assert(srcW > 0 && srcH > 0 && tileSize > 0 && pixelsPerTile > 0);
  var drawW = srcW / pixelsPerTile * tileSize;
  var drawH = srcH / pixelsPerTile * tileSize;
  final maxW = footW * maxFootprintScale;
  final maxH = footH * maxFootprintScale;
  if (drawW > maxW || drawH > maxH) {
    final s = math.min(maxW / drawW, maxH / drawH);
    drawW *= s;
    drawH *= s;
  }
  return (drawW, drawH);
}

/// Upscale factor if we naively fit-covered into the footprint (1 = no upscale).
double furnitureCoverUpscale({
  required double srcW,
  required double srcH,
  required double footW,
  required double footH,
  required double tileSize,
  double pixelsPerTile = kDefaultFurniturePixelsPerTile,
}) {
  final aspect = srcW / srcH;
  final (cw, ch) = furnitureFitCover(boxW: footW, boxH: footH, aspect: aspect);
  final (nw, nh) = furnitureDrawSizePx(
    srcW: srcW,
    srcH: srcH,
    tileSize: tileSize,
    footW: footW,
    footH: footH,
    pixelsPerTile: pixelsPerTile,
  );
  final coverArea = cw * ch;
  final nativeArea = nw * nh;
  if (nativeArea <= 0) return 1;
  return math.sqrt(coverArea / nativeArea);
}

/// How well a sprite aspect matches a south-facing footprint (1 = perfect).
double footprintAspectMatch({
  required (int, int) footprint,
  required double spriteAspect,
  HabitatPropFacing facing = HabitatPropFacing.south,
}) {
  final (w, h) = switch (facing) {
    HabitatPropFacing.south || HabitatPropFacing.north => footprint,
    HabitatPropFacing.east || HabitatPropFacing.west => (
        footprint.$2,
        footprint.$1,
      ),
  };
  final footAspect = w / h;
  final lo = footAspect < spriteAspect ? footAspect : spriteAspect;
  final hi = footAspect < spriteAspect ? spriteAspect : footAspect;
  return lo / hi;
}
