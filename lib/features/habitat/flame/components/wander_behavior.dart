import 'dart:math' as math;

import '../habitat_map.dart';
import 'living_pawn_component.dart';

enum _WanderPhase { idle, walking }

/// Spec §07 V0: idle 1–3s → pick walkable target → step neighbor-by-neighbor.
class WanderBehavior {
  WanderBehavior({
    required this.pawn,
    required this.map,
    required this.rng,
  });

  final LivingPawnComponent pawn;
  HabitatMap map;
  final math.Random rng;

  _WanderPhase _phase = _WanderPhase.idle;
  double _idleLeft = 0.5;
  final List<(int, int)> _path = [];
  bool _paused = false;

  /// Optional darkness field — lower = brighter preferred (V9.11).
  List<double>? preferBright;

  /// Restrict wander targets (V9.13).
  Set<(int, int)>? allowedZone;

  /// Condition presentation speed scale (M7).
  double speedScale = 1;

  void pause() {
    _paused = true;
    _path.clear();
    _phase = _WanderPhase.idle;
  }

  void resume() {
    _paused = false;
    _idleLeft = 0.4 + rng.nextDouble();
    _phase = _WanderPhase.idle;
  }

  /// Next / remaining wander steps include the doorway.
  bool willTraverseDoor((int, int) doorCell) {
    if (_phase != _WanderPhase.walking) return false;
    return _path.contains(doorCell);
  }

  void update(double dt) {
    if (_paused) return;
    final scaled = dt * speedScale.clamp(0.7, 1.2);
    switch (_phase) {
      case _WanderPhase.idle:
        _idleLeft -= scaled;
        if (_idleLeft <= 0) _beginWalk();
      case _WanderPhase.walking:
        if (pawn.isMoving) return;
        if (_path.isEmpty) {
          _enterIdle();
          return;
        }
        final next = _path.removeAt(0);
        final dx = next.$1 - pawn.cellX;
        final dy = next.$2 - pawn.cellY;
        if (!pawn.tryStep(dx, dy)) {
          // Waiting for a sliding door — keep the step and hold the door open.
          if (map.doorBlocksStep(next.$1, next.$2)) {
            map.door.requestOpen();
            _path.insert(0, next);
            return;
          }
          // Blocked mid-path — replan or idle.
          _enterIdle();
        }
    }
  }

  void _enterIdle() {
    _phase = _WanderPhase.idle;
    _idleLeft = 1.0 + rng.nextDouble() * 2.0;
    _path.clear();
  }

  void _beginWalk() {
    final from = (pawn.cellX, pawn.cellY);
    final target = pickWanderTarget(
      map: map,
      from: from,
      rng: rng,
      preferBright: preferBright,
      allowed: allowedZone,
    );
    if (target == null) {
      _enterIdle();
      return;
    }
    _path
      ..clear()
      ..addAll(_greedyPath(from, target));
    if (_path.isEmpty) {
      _enterIdle();
      return;
    }
    _phase = _WanderPhase.walking;
  }

  /// Neighbor-only greedy path (no A*). Good enough on open rooms.
  List<(int, int)> _greedyPath((int, int) from, (int, int) to) {
    final steps = <(int, int)>[];
    var cx = from.$1;
    var cy = from.$2;
    var guard = 0;
    while ((cx != to.$1 || cy != to.$2) && guard++ < 64) {
      final dx = (to.$1 - cx).sign;
      final dy = (to.$2 - cy).sign;
      var moved = false;
      // Prefer axis with larger remaining distance.
      final tryOrder = (to.$1 - cx).abs() >= (to.$2 - cy).abs()
          ? [(dx, 0), (0, dy), (dx, dy), (-dx, 0), (0, -dy)]
          : [(0, dy), (dx, 0), (dx, dy), (0, -dy), (-dx, 0)];
      for (final (sx, sy) in tryOrder) {
        if (sx == 0 && sy == 0) continue;
        // Only orthogonal steps for clean facing.
        if (sx != 0 && sy != 0) continue;
        final nx = cx + sx;
        final ny = cy + sy;
        if (map.isWalkable(nx, ny)) {
          if (allowedZone != null && !allowedZone!.contains((nx, ny))) continue;
          cx = nx;
          cy = ny;
          steps.add((cx, cy));
          moved = true;
          break;
        }
      }
      if (!moved) break;
    }
    return steps;
  }
}
