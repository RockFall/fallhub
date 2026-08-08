import 'dart:math' as math;

import 'habitat_locations.dart';
import 'habitat_map.dart';
import 'habitat_prop_catalog.dart';

/// Cosmetic temperature field (V9.12). °C per walkable cell.
abstract final class HabitatClimateField {
  static const double comfortMin = 18;
  static const double comfortMax = 26;
  static const double placeholderOutdoor = 22;

  /// Indoor base °C by locale.
  static double indoorBase(String locationId) => switch (locationId) {
        HabitatLocationIds.bedroom => 22,
        HabitatLocationIds.office => 21,
        HabitatLocationIds.kitchen => 23,
        HabitatLocationIds.terrace => placeholderOutdoor,
        _ => 22,
      };

  /// Outdoor influence on closed rooms (0–1).
  static double outdoorInfluence(String locationId) =>
      HabitatLocations.isOutdoor(locationId) ? 1.0 : 0.30;

  /// Effective outdoor °C (weather + night dip).
  static double effectiveOutdoor(
    double? outdoorC, {
    required double phase,
  }) {
    final base = outdoorC ?? placeholderOutdoor;
    final h = (phase % 1.0) * 24.0;
    final night = h < 5 || h >= 18;
    return night ? base - 3 : base;
  }

  /// Per-cell temperature °C.
  static List<double> compute(
    HabitatMap map, {
    required String locationId,
    required double phase,
    double? outdoorC,
  }) {
    final outdoor = effectiveOutdoor(outdoorC, phase: phase);
    final n = map.width * map.height;
    final out = List<double>.filled(n, outdoor);
    final base = indoorBase(locationId);
    final influence = outdoorInfluence(locationId);

    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.isWallCell(x, y)) continue;
        final i = y * map.width + x;
        if (HabitatLocations.isOutdoor(locationId)) {
          out[i] = outdoor;
        } else {
          out[i] = base + (outdoor - base) * influence;
        }
      }
    }

    for (final p in map.props) {
      final delta = switch (p.kind) {
        HabitatPropKinds.heater => 4.0 * p.quality.climateScale,
        HabitatPropKinds.cooler => -4.0 * p.quality.climateScale,
        _ => 0.0,
      };
      if (delta == 0) continue;
      final (ox, oy) = p.origin;
      const radius = 2.8;
      for (var dy = -radius.ceil(); dy <= radius.ceil(); dy++) {
        for (var dx = -radius.ceil(); dx <= radius.ceil(); dx++) {
          final x = ox + dx;
          final y = oy + dy;
          if (!map.inBounds(x, y) || map.isWallCell(x, y)) continue;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist > radius) continue;
          final falloff = 1.0 - dist / (radius + 0.01);
          out[y * map.width + x] += delta * falloff;
        }
      }
    }
    return out;
  }

  static double at(List<double> field, HabitatMap map, int x, int y) {
    if (!map.inBounds(x, y)) return placeholderOutdoor;
    return field[y * map.width + x];
  }

  /// Deviation from comfort band (positive = hot, negative = cold).
  static double comfortDelta(double c) {
    if (c < comfortMin) return c - comfortMin;
    if (c > comfortMax) return c - comfortMax;
    return 0;
  }

  /// Representative indoor °C (walkable average).
  static double indoorAverage(
    HabitatMap map,
    List<double> field, {
    required String locationId,
  }) {
    var sum = 0.0;
    var count = 0;
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (!map.isWalkable(x, y)) continue;
        sum += field[y * map.width + x];
        count++;
      }
    }
    if (count == 0) return indoorBase(locationId);
    return sum / count;
  }
}
