import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../habitat_beauty.dart';
import '../habitat_game.dart';

/// Heatmap of cosmetic beauty per cell (V9.8).
class BeautyOverlayComponent extends Component
    with HasGameReference<HabitatGame> {
  BeautyOverlayComponent() : super(priority: 15);

  List<double> _field = const [];
  double _reveal = 0;
  double _fade = 0;
  bool _wantVisible = false;

  /// Ripple after place/remove: (x, y, age 0→1, positive?).
  final List<(int, int, double, bool)> ripples = [];

  void setWantVisible(bool on) {
    _wantVisible = on;
    if (on) {
      _reveal = 0;
      refreshField();
    }
  }

  void refreshField() {
    _field = HabitatBeautyField.compute(game.map);
  }

  void addRipple(int x, int y, {required bool positive}) {
    ripples.add((x, y, 0, positive));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_wantVisible) {
      _reveal = (_reveal + dt / 0.22).clamp(0.0, 1.0);
      _fade = (_fade + dt / 0.12).clamp(0.0, 1.0);
    } else {
      _fade = (_fade - dt / 0.2).clamp(0.0, 1.0);
      if (_fade <= 0) _reveal = 0;
    }

    for (var i = ripples.length - 1; i >= 0; i--) {
      final (x, y, age, pos) = ripples[i];
      final next = age + dt / 0.3;
      if (next >= 1) {
        ripples.removeAt(i);
      } else {
        ripples[i] = (x, y, next, pos);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_fade <= 0.01 && ripples.isEmpty) return;
    final map = game.map;
    final tile = game.tileSize;
    final cam = game.camera.viewfinder.position;
    final z = game.camera.viewfinder.zoom;
    final view = game.canvasSize;
    final centerX = (cam.x + view.x / (2 * z)) / tile;
    final centerY = (cam.y + view.y / (2 * z)) / tile;

    if (_fade > 0.01 && _field.isNotEmpty) {
      final maxDist = math.sqrt(
            map.width * map.width + map.height * map.height,
          ) *
          0.55;
      for (var y = 0; y < map.height; y++) {
        for (var x = 0; x < map.width; x++) {
          if (map.isWallCell(x, y)) continue;
          final dist = math.sqrt(
            (x - centerX) * (x - centerX) + (y - centerY) * (y - centerY),
          );
          final cellReveal = ((_reveal * maxDist - dist) / 3).clamp(0.0, 1.0);
          if (cellReveal <= 0) continue;
          final score = _field[y * map.width + x];
          final color = HabitatBeautyField.colorFor(
            score,
            alpha: 0.4 * _fade * cellReveal,
          );
          if (color.a < 0.02) continue;
          canvas.drawRect(
            Rect.fromLTWH(x * tile, y * tile, tile, tile),
            Paint()..color = color,
          );
        }
      }
    }

    for (final (x, y, age, positive) in ripples) {
      final t = age;
      final r = tile * (0.4 + t * 1.6);
      final a = (1 - t) * 0.55;
      canvas.drawCircle(
        Offset(x * tile + tile / 2, y * tile + tile / 2),
        r,
        Paint()
          ..color = (positive
                  ? const Color(0xFF44FF88)
                  : const Color(0xFFAA6644))
              .withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }
}
