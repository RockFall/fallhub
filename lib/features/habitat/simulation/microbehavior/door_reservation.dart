/// Coordinated door transit (MD 10 R14).
class DoorTransitReservation {
  DoorTransitReservation({
    required this.doorId,
    required this.pawnId,
    required this.direction,
    required this.expiresAt,
    this.waitSpot,
  });

  final String doorId;
  final String pawnId;

  /// +1 / -1 along primary axis, or packed as dx/dy intent.
  final (int, int) direction;
  double expiresAt;
  final (int, int)? waitSpot;

  bool isExpired(double now) => now >= expiresAt;

  void refresh(double now, {double holdSeconds = 1.8}) {
    expiresAt = now + holdSeconds;
  }
}

/// Manages exclusive door crossing + wait spots for runners-up.
class DoorReservationBoard {
  DoorReservationBoard({this.defaultHoldSeconds = 1.8});

  final double defaultHoldSeconds;
  final Map<String, DoorTransitReservation> _byDoor = {};

  DoorTransitReservation? reservationFor(String doorId) => _byDoor[doorId];

  DoorTransitReservation? ofPawn(String pawnId) {
    for (final r in _byDoor.values) {
      if (r.pawnId == pawnId) return r;
    }
    return null;
  }

  void tick(double now) {
    _byDoor.removeWhere((_, r) => r.isExpired(now));
  }

  /// Try to claim the door. Returns null if another pawn holds it.
  DoorTransitReservation? tryClaim({
    required String doorId,
    required String pawnId,
    required (int, int) direction,
    required double now,
    (int, int)? waitSpot,
  }) {
    tick(now);
    final cur = _byDoor[doorId];
    if (cur != null && cur.pawnId != pawnId && !cur.isExpired(now)) {
      return null;
    }
    final r = DoorTransitReservation(
      doorId: doorId,
      pawnId: pawnId,
      direction: direction,
      expiresAt: now + defaultHoldSeconds,
      waitSpot: waitSpot,
    );
    _byDoor[doorId] = r;
    return r;
  }

  /// Refresh hold while traversing.
  bool refresh(String doorId, String pawnId, double now) {
    final cur = _byDoor[doorId];
    if (cur == null || cur.pawnId != pawnId) return false;
    cur.refresh(now, holdSeconds: defaultHoldSeconds);
    return true;
  }

  void release(String doorId, {String? pawnId}) {
    final cur = _byDoor[doorId];
    if (cur == null) return;
    if (pawnId != null && cur.pawnId != pawnId) return;
    _byDoor.remove(doorId);
  }

  void releasePawn(String pawnId) {
    _byDoor.removeWhere((_, r) => r.pawnId == pawnId);
  }

  /// Lateral wait cell beside [doorCell] opposite to travel if possible.
  static (int, int)? pickWaitSpot({
    required (int, int) doorCell,
    required (int, int) from,
    required (int, int) toward,
    required bool Function(int x, int y) isWalkable,
    required Set<(int, int)> occupied,
  }) {
    final fdx = (toward.$1 - from.$1).sign;
    final sides = fdx != 0
        ? [
            (doorCell.$1, doorCell.$2 + 1),
            (doorCell.$1, doorCell.$2 - 1),
            (from.$1, from.$2),
          ]
        : [
            (doorCell.$1 + 1, doorCell.$2),
            (doorCell.$1 - 1, doorCell.$2),
            (from.$1, from.$2),
          ];
    // Prefer side that is not the approach lane.
    for (final s in sides) {
      if (s == doorCell) continue;
      if (!isWalkable(s.$1, s.$2)) continue;
      if (occupied.contains(s)) continue;
      return s;
    }
    return null;
  }
}
