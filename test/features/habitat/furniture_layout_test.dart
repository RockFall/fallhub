import 'package:fallhub/features/habitat/flame/furniture/furniture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('furnitureDrawSizePx', () {
    test('lamp stays sub-tile at 64ppt (not full-cell cover)', () {
      const tile = 48.0;
      final (w, h) = furnitureDrawSizePx(
        srcW: 30,
        srcH: 43,
        tileSize: tile,
        footW: tile,
        footH: tile,
      );
      expect(w, closeTo(30 / 64 * tile, 0.01));
      expect(h, closeTo(43 / 64 * tile, 0.01));
      expect(w, lessThan(tile * 0.6));
      expect(h, lessThan(tile * 0.8));
    });

    test('trimmed bed fills ~1x2 at 64ppt', () {
      const tile = 48.0;
      final (w, h) = furnitureDrawSizePx(
        srcW: 68,
        srcH: 128,
        tileSize: tile,
        footW: tile,
        footH: tile * 2,
      );
      expect(h, closeTo(tile * 2, 0.01));
      expect(w, closeTo(68 / 64 * tile, 0.01));
    });

    test('couch fills ~2x1 at 64ppt', () {
      const tile = 48.0;
      final (w, h) = furnitureDrawSizePx(
        srcW: 134,
        srcH: 73,
        tileSize: tile,
        footW: tile * 2,
        footH: tile,
      );
      expect(w, closeTo(134 / 64 * tile, 0.01));
      expect(h, closeTo(73 / 64 * tile, 0.01));
    });

    test('oversized atlas clamps toward footprint', () {
      const tile = 48.0;
      final (w, h) = furnitureDrawSizePx(
        srcW: 294,
        srcH: 369,
        tileSize: tile,
        footW: tile * 2,
        footH: tile * 2,
      );
      expect(w, lessThanOrEqualTo(tile * 2 * 1.25 + 0.01));
      expect(h, lessThanOrEqualTo(tile * 2 * 1.25 + 0.01));
      expect(w, lessThan(294 / 64 * tile));
    });
  });

  group('furnitureCoverUpscale', () {
    test('fit-cover would heavily upscale a lamp', () {
      const tile = 48.0;
      final u = furnitureCoverUpscale(
        srcW: 30,
        srcH: 43,
        footW: tile,
        footH: tile,
        tileSize: tile,
      );
      expect(u, greaterThan(1.5));
    });
  });

  group('footprintAspectMatch', () {
    test('square vs 1x2 is poor', () {
      expect(
        footprintAspectMatch(footprint: (1, 2), spriteAspect: 1.0),
        closeTo(0.5, 0.01),
      );
    });

    test('trimmed bed vs 1x2 is good', () {
      expect(
        footprintAspectMatch(footprint: (1, 2), spriteAspect: 0.53),
        greaterThan(0.9),
      );
    });
  });
}
