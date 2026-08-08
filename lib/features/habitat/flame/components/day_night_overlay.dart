import 'dart:ui';

import 'package:flame/components.dart';

import '../habitat_climate.dart';
import '../habitat_game.dart';
import '../habitat_light.dart';
import '../habitat_locations.dart';

/// Soft ambient darkness + lamp radii; temperature tint (V9.11 / V9.12).
class DayNightOverlayComponent extends Component
    with HasGameReference<HabitatGame> {
  DayNightOverlayComponent() : super(priority: 35);

  @override
  void render(Canvas canvas) {
    final map = game.map;
    final tile = game.tileSize;

    HabitatLightField.paintSoftDarkness(
      canvas,
      map: map,
      tileSize: tile,
      phase: game.presence.phase,
      locationId: game.locationId,
    );

    // Temperature discomfort stays a light cell wash (secondary to lighting).
    final climate = game.climateField;
    if (climate.length != map.width * map.height) return;
    final outdoor = HabitatLocations.isOutdoor(game.locationId);
    // Skip heat/cold wash when nearly pitch-black indoor — lighting dominates.
    final ambient = HabitatLightField.ambientDarkness(
      game.presence.phase,
      outdoor: outdoor,
    );
    if (ambient > 0.85) return;

    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.isWallCell(x, y)) continue;
        final delta = HabitatClimateField.comfortDelta(
          climate[y * map.width + x],
        );
        if (delta.abs() <= 0.5) continue;
        final t = (delta.abs() / 8).clamp(0.0, 0.28);
        final color = delta < 0
            ? Color.fromRGBO(120, 180, 255, t)
            : Color.fromRGBO(255, 140, 60, t);
        canvas.drawRect(
          Rect.fromLTWH(x * tile, y * tile, tile, tile),
          Paint()..color = color,
        );
      }
    }
  }
}
