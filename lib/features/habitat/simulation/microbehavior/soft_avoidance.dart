/// Soft local avoidance without replacing A* (MD 10 R13 / R15).
enum AvoidanceAction {
  none,
  wait,
  sideStep,
  shortReplan,
}

class AvoidanceConflict {
  const AvoidanceConflict({
    required this.selfNext,
    required this.otherId,
    required this.otherNext,
    required this.otherCell,
    this.headOn = false,
  });

  final (int, int) selfNext;
  final String otherId;
  final (int, int)? otherNext;
  final (int, int) otherCell;
  final bool headOn;
}

class AvoidanceDecision {
  const AvoidanceDecision({
    required this.action,
    this.sideStepCell,
    this.waitSeconds = 0,
    this.yieldPriority = 0,
  });

  final AvoidanceAction action;
  final (int, int)? sideStepCell;
  final double waitSeconds;
  final double yieldPriority;
}

class AvoidanceAgentSnapshot {
  const AvoidanceAgentSnapshot({
    required this.pawnId,
    required this.cell,
    this.nextCell,
    this.urgency = 0,
    this.carrying = false,
    this.remainingPathLength = 0,
  });

  final String pawnId;
  final (int, int) cell;
  final (int, int)? nextCell;
  final double urgency;
  final bool carrying;
  final int remainingPathLength;
}

/// Resolve next-cell conflicts with yield / side-step / short wait (R13+R15).
abstract final class SoftLocalAvoidance {
  static const maxOscillationFlips = 3;
  static const waitMin = 0.12;
  static const waitMax = 0.45;
  static const progressTimeout = 2.8;

  /// Technical priority — higher keeps going; lower yields (not social status).
  static double priority(AvoidanceAgentSnapshot a) {
    var p = a.urgency * 2.0;
    if (a.carrying) p += 0.6;
    // Closer to destination keeps priority (less total disruption).
    p += (1.0 / (1 + a.remainingPathLength * 0.08));
    return p;
  }

  static AvoidanceConflict? detect({
    required AvoidanceAgentSnapshot self,
    required List<AvoidanceAgentSnapshot> others,
  }) {
    final next = self.nextCell;
    if (next == null) return null;
    for (final o in others) {
      if (o.pawnId == self.pawnId) continue;
      // Same next cell, or swapping cells (head-on).
      final sameNext = o.nextCell == next || o.cell == next;
      final headOn = o.nextCell == self.cell && next == o.cell;
      if (sameNext || headOn) {
        return AvoidanceConflict(
          selfNext: next,
          otherId: o.pawnId,
          otherNext: o.nextCell,
          otherCell: o.cell,
          headOn: headOn,
        );
      }
    }
    return null;
  }

  static AvoidanceDecision resolve({
    required AvoidanceAgentSnapshot self,
    required AvoidanceAgentSnapshot other,
    required AvoidanceConflict conflict,
    required bool Function(int x, int y) isWalkable,
    required Set<(int, int)> blockedByPawns,
    int oscillationCount = 0,
    double unitNoise = 0.5,
  }) {
    final selfP = priority(self);
    final otherP = priority(other);
    final iYield = selfP < otherP - 0.05 ||
        (selfP - otherP).abs() < 0.05 && self.pawnId.compareTo(other.pawnId) > 0;

    if (!iYield) {
      return const AvoidanceDecision(action: AvoidanceAction.none);
    }

    if (oscillationCount >= maxOscillationFlips) {
      // Force wait to break left/right oscillation.
      return AvoidanceDecision(
        action: AvoidanceAction.wait,
        waitSeconds: waitMax,
        yieldPriority: selfP,
      );
    }

    final side = _pickSideStep(
      from: self.cell,
      forward: conflict.selfNext,
      isWalkable: isWalkable,
      blockedByPawns: blockedByPawns,
      preferPositive: unitNoise >= 0.5,
    );
    if (side != null && conflict.headOn) {
      return AvoidanceDecision(
        action: AvoidanceAction.sideStep,
        sideStepCell: side,
        yieldPriority: selfP,
      );
    }

    final wait = waitMin + (waitMax - waitMin) * unitNoise.clamp(0.0, 1.0);
    if (side != null && unitNoise > 0.55) {
      return AvoidanceDecision(
        action: AvoidanceAction.sideStep,
        sideStepCell: side,
        yieldPriority: selfP,
      );
    }
    return AvoidanceDecision(
      action: AvoidanceAction.wait,
      waitSeconds: wait,
      yieldPriority: selfP,
    );
  }

  static (int, int)? _pickSideStep({
    required (int, int) from,
    required (int, int) forward,
    required bool Function(int x, int y) isWalkable,
    required Set<(int, int)> blockedByPawns,
    required bool preferPositive,
  }) {
    final fdx = forward.$1 - from.$1;
    // Perpendicular cells.
    final sides = fdx != 0
        ? [(from.$1, from.$2 + 1), (from.$1, from.$2 - 1)]
        : [(from.$1 + 1, from.$2), (from.$1 - 1, from.$2)];
    final ordered = preferPositive ? sides : sides.reversed.toList();
    for (final s in ordered) {
      if (!isWalkable(s.$1, s.$2)) continue;
      if (blockedByPawns.contains(s)) continue;
      if (s == forward) continue;
      return s;
    }
    return null;
  }
}
