import 'attention_target.dart';
import 'habitat_rng.dart';

/// Brief perception when crossing into a room (MD 10 R18).
class RoomEntryScan {
  const RoomEntryScan({
    required this.roomId,
    required this.startedAt,
    required this.endsAt,
    this.attention,
    this.skipped = false,
  });

  final String roomId;
  final double startedAt;
  final double endsAt;
  final AttentionTarget? attention;
  final bool skipped;

  bool isActive(double now) => !skipped && now < endsAt && now >= startedAt;
}

class RoomSalienceCue {
  const RoomSalienceCue({
    required this.cell,
    required this.score,
    this.entityId,
    this.label = '',
  });

  final (int, int) cell;
  final double score;
  final String? entityId;
  final String label;
}

abstract final class RoomEntryScanner {
  static const holdMin = 0.10;
  static const holdMax = 0.50;

  /// Start a scan unless urgent / transit-only.
  static RoomEntryScan? begin({
    required String pawnId,
    required String roomId,
    required double now,
    required List<RoomSalienceCue> cues,
    bool urgent = false,
    bool transitOnly = false,
  }) {
    if (urgent || transitOnly) {
      return RoomEntryScan(
        roomId: roomId,
        startedAt: now,
        endsAt: now,
        skipped: true,
      );
    }
    RoomSalienceCue? best;
    for (final c in cues) {
      if (best == null || c.score > best.score) best = c;
    }
    final hold = HabitatRng.range(
      holdMin,
      holdMax,
      a: pawnId,
      b: 'roomScan',
      c: roomId,
    );
    AttentionTarget? att;
    if (best != null && best.score >= 0.35) {
      att = AttentionTarget(
        entityId: best.entityId,
        cellX: best.cell.$1,
        cellY: best.cell.$2,
        reason: AttentionReason.interestingEvent,
        priority: AttentionPriority.forReason(AttentionReason.interestingEvent),
        expiresAt: now + hold + 0.4,
      );
    }
    return RoomEntryScan(
      roomId: roomId,
      startedAt: now,
      endsAt: now + hold,
      attention: att,
    );
  }
}
