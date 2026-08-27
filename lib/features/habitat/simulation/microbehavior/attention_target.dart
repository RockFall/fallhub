/// Why a pawn is momentarily looking at something (MD 10 R0).
enum AttentionReason {
  conversationPartner,
  interactionTarget,
  interestingEvent,
  passingPawn,
  soundSource,
  ambientObject,
  manualInspect,
}

/// Lightweight gaze focus — does not interrupt locomotion by itself.
class AttentionTarget {
  const AttentionTarget({
    this.entityId,
    this.worldX,
    this.worldY,
    this.cellX,
    this.cellY,
    required this.reason,
    required this.priority,
    required this.expiresAt,
  });

  final String? entityId;

  /// Optional world pixel focus (renderer may prefer over cell).
  final double? worldX;
  final double? worldY;

  /// Grid cell focus when world coords unavailable.
  final int? cellX;
  final int? cellY;

  final AttentionReason reason;
  final double priority;

  /// Absolute sim/session seconds when this focus ends.
  final double expiresAt;

  bool isExpired(double now) => now >= expiresAt;

  AttentionTarget copyWith({
    String? entityId,
    double? worldX,
    double? worldY,
    int? cellX,
    int? cellY,
    AttentionReason? reason,
    double? priority,
    double? expiresAt,
  }) =>
      AttentionTarget(
        entityId: entityId ?? this.entityId,
        worldX: worldX ?? this.worldX,
        worldY: worldY ?? this.worldY,
        cellX: cellX ?? this.cellX,
        cellY: cellY ?? this.cellY,
        reason: reason ?? this.reason,
        priority: priority ?? this.priority,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  @override
  String toString() =>
      'Attention(${reason.name} p=${priority.toStringAsFixed(2)}'
      '${entityId != null ? ' →$entityId' : ''}'
      '${cellX != null ? ' @$cellX,$cellY' : ''})';
}

/// Base priority ranks — higher wins. Rare events may temporarily exceed.
abstract final class AttentionPriority {
  static double forReason(AttentionReason reason) => switch (reason) {
        AttentionReason.manualInspect => 1.0,
        AttentionReason.conversationPartner => 0.92,
        AttentionReason.interactionTarget => 0.85,
        AttentionReason.interestingEvent => 0.78,
        AttentionReason.passingPawn => 0.55,
        AttentionReason.soundSource => 0.5,
        AttentionReason.ambientObject => 0.35,
      };

  /// Typical hold duration (seconds) before natural expiry.
  static double holdSeconds(AttentionReason reason) => switch (reason) {
        AttentionReason.manualInspect => 2.4,
        AttentionReason.conversationPartner => 4.0,
        AttentionReason.interactionTarget => 2.2,
        AttentionReason.interestingEvent => 1.1,
        AttentionReason.passingPawn => 0.7,
        AttentionReason.soundSource => 0.9,
        AttentionReason.ambientObject => 1.4,
      };
}

/// Manages competing gaze targets with cooldown against oscillation (R0).
class AttentionController {
  AttentionController({
    this.switchCooldownSeconds = 0.45,
    this.minPriorityDelta = 0.08,
  });

  /// Floor time between accepted target switches (same pawn).
  final double switchCooldownSeconds;

  /// Challenger must beat current by at least this, unless current expired.
  final double minPriorityDelta;

  AttentionTarget? _current;
  double _lastSwitchAt = -999;
  AttentionReason? _lastReason;

  AttentionTarget? get current => _current;

  /// Clears focus immediately (draft cancel, teleport, etc.).
  void clear() {
    _current = null;
  }

  /// Tick expiry. Returns true if focus just ended.
  bool tick(double now) {
    final cur = _current;
    if (cur == null) return false;
    if (!cur.isExpired(now)) return false;
    _current = null;
    return true;
  }

  /// Propose a new focus. Returns whether it became current.
  bool propose({
    required AttentionTarget candidate,
    required double now,
  }) {
    final cur = _current;
    if (cur != null && !cur.isExpired(now)) {
      // Same entity / same reason: refresh expiry if priority is similar+.
      final sameEntity = candidate.entityId != null &&
          candidate.entityId == cur.entityId &&
          candidate.reason == cur.reason;
      if (sameEntity) {
        if (candidate.priority + 0.001 >= cur.priority) {
          _current = candidate;
          return true;
        }
        return false;
      }

      final delta = candidate.priority - cur.priority;
      if (delta < minPriorityDelta) return false;

      // Cooldown: only rare high-salience events may steal early.
      final since = now - _lastSwitchAt;
      final stealEarly = candidate.reason == AttentionReason.interestingEvent &&
          candidate.priority >= 0.85 &&
          delta >= 0.2;
      if (since < switchCooldownSeconds && !stealEarly) return false;
    }

    _current = candidate;
    _lastSwitchAt = now;
    _lastReason = candidate.reason;
    return true;
  }

  /// Convenience: build + propose from reason + optional cell/entity.
  bool lookAt({
    required AttentionReason reason,
    required double now,
    String? entityId,
    int? cellX,
    int? cellY,
    double? worldX,
    double? worldY,
    double? priorityOverride,
    double? holdOverride,
  }) {
    final priority = priorityOverride ?? AttentionPriority.forReason(reason);
    final hold = holdOverride ?? AttentionPriority.holdSeconds(reason);
    return propose(
      candidate: AttentionTarget(
        entityId: entityId,
        cellX: cellX,
        cellY: cellY,
        worldX: worldX,
        worldY: worldY,
        reason: reason,
        priority: priority,
        expiresAt: now + hold,
      ),
      now: now,
    );
  }

  AttentionReason? get lastReason => _lastReason;

  String get debugLabel {
    final c = _current;
    if (c == null) return 'none';
    return c.toString();
  }
}
