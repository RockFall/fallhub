import 'dart:math' as math;
import 'dart:ui' show Canvas, Color, Offset, Path, Rect;

import 'package:flutter/painting.dart';

import 'habitat_locations.dart';
import 'habitat_map.dart';
import 'habitat_prop_catalog.dart';

/// Per-cell darkness for gameplay + soft radial lamp rendering (V9.11).
///
/// `darkness` 0 = daytime full color, 1 = pitch black.
/// Lamps reduce darkness toward 0 (restore normal day colors).
abstract final class HabitatLightField {
  /// Base lamp radius in tiles (soft falloff extends to the edge).
  static const double lampRadius = 8.0;

  /// Cell is *really* dark (near pitch-black indoor night), not outdoor
  /// moonlight penumbra (~0.40–0.48) or mild dusk dimness.
  static const double tooDarkThreshold = 0.78;

  /// Ambient darkness from wall-clock phase (0–1 day fraction).
  static double ambientDarkness(double phase, {required bool outdoor}) {
    final h = (phase % 1.0) * 24.0;
    // Madrugada 0–5, Amanhecer 5–7, Dia 7–17, Entardecer 17–18, Noite 18–24.
    if (h >= 7 && h < 17) return outdoor ? 0.02 : 0.04;
    if (h >= 5 && h < 7) {
      final t = (h - 5) / 2;
      return outdoor ? _lerp(0.42, 0.06, t) : _lerp(0.90, 0.10, t);
    }
    if (h >= 17 && h < 18) {
      final t = h - 17;
      return outdoor ? _lerp(0.06, 0.40, t) : _lerp(0.10, 0.88, t);
    }
    // Noite / madrugada.
    if (outdoor) {
      if (h < 5) return _lerp(0.48, 0.42, h / 5);
      return _lerp(0.40, 0.48, (h - 18) / 6);
    }
    if (h < 5) return _lerp(0.95, 0.88, h / 5);
    return _lerp(0.88, 0.95, (h - 18) / 6);
  }

  static double lampRadiusFor(HabitatProp lamp) =>
      lampRadius + lamp.quality.lightBonus * 2.2;

  /// Soft illumination 0–1 at tile distance [dist] from a lamp.
  static double lampIllumination(double dist, double radius, double bonus) {
    if (dist >= radius) return 0;
    final t = (1.0 - dist / radius).clamp(0.0, 1.0);
    // Smoothstep² — wide core, diffuse rim (no hard tile steps).
    final soft = t * t * (3 - 2 * t);
    final core = soft * soft;
    return ((0.72 + bonus * 0.12) * core).clamp(0.0, 1.0);
  }

  /// Flat list `width * height` — darkness after ambient + lamps (for AI / HUD).
  static List<double> compute(
    HabitatMap map, {
    required double phase,
    required String locationId,
    bool lineOfSight = true,
  }) {
    final outdoor = HabitatLocations.isOutdoor(locationId);
    final ambient = ambientDarkness(phase, outdoor: outdoor);
    final n = map.width * map.height;
    final out = List<double>.filled(n, ambient);

    for (final p in map.props) {
      if (p.kind != HabitatPropKinds.lamp) continue;
      final bonus = p.quality.lightBonus;
      final radius = lampRadiusFor(p);
      final (ox, oy) = p.origin;
      final rCeil = radius.ceil();
      for (var dy = -rCeil; dy <= rCeil; dy++) {
        for (var dx = -rCeil; dx <= rCeil; dx++) {
          final x = ox + dx;
          final y = oy + dy;
          if (!map.inBounds(x, y) || map.isWallCell(x, y)) continue;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist > radius) continue;
          if (lineOfSight && !_lineOfSight(map, ox, oy, x, y)) continue;
          final illum = lampIllumination(dist, radius, bonus);
          final i = y * map.width + x;
          out[i] *= (1 - illum).clamp(0.0, 1.0);
        }
      }
    }

    for (var i = 0; i < n; i++) {
      out[i] = out[i].clamp(0.0, 1.0);
    }
    return out;
  }

  static double at(List<double> field, HabitatMap map, int x, int y) {
    if (!map.inBounds(x, y)) return 1.0;
    return field[y * map.width + x];
  }

  /// Soft ambient darkness + radial lamp cutouts (diffuse edges, not a grid).
  ///
  /// Walls receive **only** global ambient — never lamp cutouts.
  static void paintSoftDarkness(
    Canvas canvas, {
    required HabitatMap map,
    required double tileSize,
    required double phase,
    required String locationId,
  }) {
    final outdoor = HabitatLocations.isOutdoor(locationId);
    final ambient = ambientDarkness(phase, outdoor: outdoor);
    if (ambient < 0.015) return;

    final mapW = map.width * tileSize;
    final mapH = map.height * tileSize;
    final bounds = Rect.fromLTWH(0, 0, mapW, mapH);
    final ambientColor = Color.fromRGBO(0, 0, 0, ambient.clamp(0.0, 0.98));
    final ambientPaint = Paint()..color = ambientColor;

    canvas.saveLayer(bounds, Paint());

    // Floors only — lamps may punch these. Walls are painted later, untouched
    // by local light.
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.isWallCell(x, y)) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
          ambientPaint,
        );
      }
    }

    for (final p in map.props) {
      if (p.kind != HabitatPropKinds.lamp) continue;
      final (ox, oy) = p.origin;
      final radius = lampRadiusFor(p);
      final rPx = radius * tileSize;
      final center = Offset(
        (ox + 0.5) * tileSize,
        (oy + 0.5) * tileSize,
      );

      // Clip strictly to floor cells (no inflate into walls).
      final clip = Path();
      var any = false;
      final rCeil = radius.ceil();
      for (var dy = -rCeil; dy <= rCeil; dy++) {
        for (var dx = -rCeil; dx <= rCeil; dx++) {
          final x = ox + dx;
          final y = oy + dy;
          if (!map.inBounds(x, y) || map.isWallCell(x, y)) continue;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist > radius) continue;
          if (!_lineOfSight(map, ox, oy, x, y)) continue;
          any = true;
          clip.addRect(
            Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
          );
        }
      }
      if (!any) continue;

      canvas.save();
      canvas.clipPath(clip);
      final shader = RadialGradient(
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xE6FFFFFF),
          Color(0x66FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: const [0.0, 0.28, 0.62, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: rPx));
      canvas.drawCircle(
        center,
        rPx,
        Paint()
          ..shader = shader
          ..blendMode = BlendMode.dstOut,
      );
      canvas.restore();
    }

    // Walls: global ambient only (replace any accidental bleed).
    final wallPaint = Paint()
      ..color = ambientColor
      ..blendMode = BlendMode.src;
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (!map.isWallCell(x, y)) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
          wallPaint,
        );
      }
    }

    canvas.restore();
  }

  static bool _lineOfSight(HabitatMap map, int x0, int y0, int x1, int y1) {
    var x = x0;
    var y = y0;
    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx - dy;
    while (true) {
      if (x == x1 && y == y1) return true;
      if (x != x0 || y != y0) {
        if (map.isWallCell(x, y)) return false;
      }
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
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
