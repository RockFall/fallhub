import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../habitat_game.dart';
import 'living_pawn_component.dart';
import 'pawn_job_controller.dart';

/// Full-map broom sweep: wave clears filth + pawn bob (play-mode clean-all).
class SweepCleanOverlayComponent extends Component
    with HasGameReference<HabitatGame> {
  SweepCleanOverlayComponent() : super(priority: 18);

  bool _active = false;
  double _t = 0;
  static const double _duration = 1.15;
  LivingPawnComponent? _sweeper;
  final List<(int, int, double)> _sparks = [];

  bool get active => _active;

  void start() {
    if (_active) return;
    _active = true;
    _t = 0;
    _sparks.clear();
    _sweeper = _pickSweeper();
    if (_sweeper != null &&
        _sweeper!.jobs.kind == HabitatJobKind.wander &&
        !_sweeper!.drafted) {
      _sweeper!.jobs.wander.pause();
    }
  }

  LivingPawnComponent? _pickSweeper() {
    final idle = [
      for (final p in game.pawns)
        if (!p.drafted &&
            !p.isMoving &&
            p.jobs.kind == HabitatJobKind.wander)
          p,
    ];
    if (idle.isNotEmpty) return idle.first;
    return game.focusedPawn ?? (game.pawns.isEmpty ? null : game.pawns.first);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    final prev = _t;
    _t = (_t + dt / _duration).clamp(0.0, 1.0);
    _clearFilthAlongWave(prev, _t);

    final sweeper = _sweeper;
    if (sweeper != null && !sweeper.drafted) {
      sweeper.poseOffsetX = math.sin(_t * math.pi * 8) * 5;
    }

    for (var i = _sparks.length - 1; i >= 0; i--) {
      final (x, y, age) = _sparks[i];
      final next = age + dt;
      if (next > 0.45) {
        _sparks.removeAt(i);
      } else {
        _sparks[i] = (x, y, next);
      }
    }

    if (_t >= 1) {
      game.map.cleanAll();
      final s = _sweeper;
      if (s != null) {
        s.poseOffsetX = 0;
        if (s.jobs.kind == HabitatJobKind.wander) {
          s.jobs.wander.resume();
        }
      }
      _sweeper = null;
      _active = false;
      _t = 0;
      game.notifyMapVisualChanged(positive: true);
      game.onSweepCleanFinished?.call();
    }
  }

  void _clearFilthAlongWave(double fromT, double toT) {
    final map = game.map;
    final maxDiag = (map.width + map.height - 2).clamp(1, 1000);
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.isWallCell(x, y)) continue;
        final cellT = (x + y) / maxDiag;
        if (cellT < fromT || cellT > toT) continue;
        if (map.filthAt(x, y) > 0.01) {
          _sparks.add((x, y, 0));
        }
        map.cleanCell(x, y);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active && _sparks.isEmpty) return;
    final tile = game.tileSize;
    final map = game.map;
    final maxDiag = (map.width + map.height - 2).clamp(1, 1000).toDouble();
    final wave = _t * maxDiag;

    if (_active) {
      // Soft diagonal broom band.
      final band = Paint()
        ..shader = Gradient.linear(
          Offset((wave - 1.2) * tile, 0),
          Offset((wave + 1.2) * tile, map.height * tile),
          [
            const Color(0x00000000),
            const Color(0x66E8F4FF),
            const Color(0xAAFFFFFF),
            const Color(0x66E8F4FF),
            const Color(0x00000000),
          ],
          const [0, 0.35, 0.5, 0.65, 1],
        );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, map.width * tile, map.height * tile),
        band,
      );

      // Thin leading edge stroke.
      final edge = Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(wave * tile, 0)
        ..lineTo((wave - map.height) * tile, map.height * tile);
      canvas.drawPath(path, edge);
    }

    for (final (x, y, age) in _sparks) {
      final a = (1 - age / 0.45).clamp(0.0, 1.0);
      final cx = x * tile + tile / 2;
      final cy = y * tile + tile / 2;
      final r = tile * (0.12 + age * 0.35);
      canvas.drawCircle(
        Offset(cx, cy - age * 8),
        r,
        Paint()..color = Color.fromRGBO(230, 240, 255, 0.55 * a),
      );
      canvas.drawCircle(
        Offset(cx + 3, cy - age * 12),
        r * 0.55,
        Paint()..color = Color.fromRGBO(255, 255, 255, 0.4 * a),
      );
    }
  }
}
