import 'dart:math' as math;
import 'dart:ui';

import 'habitat_map.dart';
import 'habitat_prop_catalog.dart';

/// Per-cell cosmetic beauty field (V9.8). Walls block contribution.
abstract final class HabitatBeautyField {
  /// Beauty emission radius in cells.
  static const int radius = 3;

  /// Score contribution of a prop kind at its origin (before falloff).
  static int emitForKind(String kind) => switch (kind) {
        HabitatPropKinds.plant => 22,
        HabitatPropKinds.painting => 26,
        HabitatPropKinds.vase => 14,
        HabitatPropKinds.rug => 12,
        HabitatPropKinds.bed => 8,
        HabitatPropKinds.table => 6,
        HabitatPropKinds.chair => 4,
        HabitatPropKinds.lamp => 7,
        HabitatPropKinds.boardgame => 10,
        HabitatPropKinds.tv => 8,
        HabitatPropKinds.instrument => 12,
        HabitatPropKinds.heater => 3,
        HabitatPropKinds.cooler => 3,
        _ => 3,
      };

  static int floorBase(HabitatFloor f) => switch (f) {
        HabitatFloor.carpet => 5,
        HabitatFloor.wood => 2,
        HabitatFloor.concrete => 0,
      };

  /// Flat list length `width * height`. Walls stay 0.
  static List<double> compute(HabitatMap map) {
    final n = map.width * map.height;
    final scores = List<double>.filled(n, 0);
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.isWallCell(x, y)) continue;
        final i = y * map.width + x;
        scores[i] = floorBase(map.floorAt(x, y)).toDouble();
      }
    }

    for (final p in map.props) {
      final emit = emitForKind(p.kind).toDouble() * p.quality.beautyScale;
      final (ox, oy) = p.origin;
      final (pw, ph) = p.size;
      // Emit from footprint center.
      final cx = ox + (pw - 1) / 2;
      final cy = oy + (ph - 1) / 2;
      for (var dy = -radius; dy <= radius; dy++) {
        for (var dx = -radius; dx <= radius; dx++) {
          final x = (cx + dx).round();
          final y = (cy + dy).round();
          if (!map.inBounds(x, y) || map.isWallCell(x, y)) continue;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist > radius) continue;
          if (!_lineOfSight(map, ox, oy, x, y)) continue;
          final falloff = 1.0 - dist / (radius + 0.01);
          scores[y * map.width + x] += emit * falloff;
        }
      }
    }

    return scores;
  }

  /// Room-level beauty 0–100 from the field average of walkable cells.
  static int aggregate(HabitatMap map, [List<double>? field]) {
    final scores = field ?? compute(map);
    var sum = 0.0;
    var count = 0;
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.isWallCell(x, y)) continue;
        sum += scores[y * map.width + x];
        count++;
      }
    }
    if (count == 0) return 0;
    // Typical furnished room ~8–25 avg → map into 0–100 gently.
    final avg = sum / count;
    return ((avg / 28) * 100).round().clamp(0, 100);
  }

  /// Heatmap color: brown (low) → clear → green (high).
  static Color colorFor(double score, {double alpha = 0.42}) {
    final t = (score / 32).clamp(0.0, 1.0);
    if (t < 0.45) {
      final u = t / 0.45;
      return Color.lerp(
        const Color(0xFF6B3A1F),
        const Color(0xFF3A3A3A),
        u,
      )!
          .withValues(alpha: alpha * (0.55 + 0.45 * (1 - u)));
    }
    final u = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
    return Color.lerp(
      const Color(0x00000000),
      const Color(0xFF3DB86A),
      u,
    )!
        .withValues(alpha: alpha * u);
  }

  static bool _lineOfSight(HabitatMap map, int x0, int y0, int x1, int y1) {
    // Bresenham — any wall between blocks (endpoints may be non-wall).
    var x = x0;
    var y = y0;
    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx - dy;
    while (true) {
      if ((x != x0 || y != y0) && (x != x1 || y != y1)) {
        if (map.isWallCell(x, y)) return false;
      }
      if (x == x1 && y == y1) break;
      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sx;
      }
      if (e2 < dx) {
        err += dx;
        y += sy;
      }
    }
    return true;
  }
}
