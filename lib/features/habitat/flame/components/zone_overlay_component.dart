import 'dart:ui';

import 'package:flame/components.dart';

import '../habitat_editor.dart';
import '../habitat_game.dart';

/// Cyan hatch for allowed cells (V9.13).
class ZoneOverlayComponent extends Component with HasGameReference<HabitatGame> {
  ZoneOverlayComponent() : super(priority: 14);

  double _fade = 0;
  double _paintAnim = 0;

  void bumpPaintAnim() => _paintAnim = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final show = _shouldShow();
    _fade = (_fade + (show ? dt : -dt) / 0.18).clamp(0.0, 1.0);
    if (_paintAnim < 1) _paintAnim = (_paintAnim + dt / 0.35).clamp(0.0, 1.0);
  }

  bool _shouldShow() {
    if (!game.editor.enabled) {
      return game.draftedPawn != null || game.focusedPawn?.drafted == true;
    }
    return game.editor.tool == HabitatEditTool.zone ||
        game.editor.tool == HabitatEditTool.zoneErase;
  }

  Set<(int, int)>? _zoneCells() {
    final pawn = game.draftedPawn ?? game.focusedPawn;
    if (pawn == null) return null;
    return game.allowedZones[pawn.memberId];
  }

  @override
  void render(Canvas canvas) {
    if (_fade <= 0.01) return;
    final zone = _zoneCells();
    if (zone == null || zone.isEmpty) return;

    final tile = game.tileSize;
    final paint = Paint()
      ..color = const Color(0xFF44DDFF).withValues(alpha: 0.22 * _fade)
      ..style = PaintingStyle.fill;

    final cells = zone.toList()..sort((a, b) => (a.$1 + a.$2).compareTo(b.$1 + b.$2));
    for (var i = 0; i < cells.length; i++) {
      final (x, y) = cells[i];
      if (!game.map.inBounds(x, y)) continue;
      final stagger = (i / cells.length) * _paintAnim;
      final alpha = ((_fade * _paintAnim - stagger).clamp(0.0, 1.0)) * 0.22;
      if (alpha <= 0.01) continue;
      final rect = Rect.fromLTWH(x * tile, y * tile, tile, tile);
      canvas.drawRect(rect, paint..color = const Color(0xFF44DDFF).withValues(alpha: alpha));
      _drawHatch(canvas, rect, alpha * 1.4);
    }

    final flash = game.zoneRejectFlash;
    if (flash != null) {
      final (fx, fy, age) = flash;
      final a = (1 - age) * 0.55 * _fade;
      if (a > 0.01) {
        canvas.drawRect(
          Rect.fromLTWH(fx * tile, fy * tile, tile, tile),
          Paint()..color = const Color(0xFFFF4444).withValues(alpha: a),
        );
      }
    }
  }

  void _drawHatch(Canvas canvas, Rect rect, double alpha) {
    final p = Paint()
      ..color = const Color(0xFF88EEFF).withValues(alpha: alpha.clamp(0.0, 0.5))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const step = 6.0;
    for (var d = -rect.height; d < rect.width + rect.height; d += step) {
      canvas.drawLine(
        Offset(rect.left + d, rect.top),
        Offset(rect.left + d + rect.height, rect.bottom),
        p,
      );
    }
  }
}
