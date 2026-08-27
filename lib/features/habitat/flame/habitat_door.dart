import 'habitat_map.dart';

/// Axis along which dual door leaves slide apart (RimWorld-style).
enum HabitatDoorSlideAxis {
  /// Leaves move east / west (door sits in an east–west wall run).
  horizontal,

  /// Leaves move north / south (door sits in a north–south wall run).
  vertical,
}

enum HabitatDoorPhase { closed, opening, open, closing }

/// Dual-leaf sliding door built from one `DoorSimple_Mover` sprite × 2 (mirrored).
///
/// Passage is allowed only when [openProgress] reaches 1.0. Pathfinding may still
/// treat [cell] as walkable; movement must wait via [blocksPassage].
class HabitatDoor {
  HabitatDoor({
    required this.cell,
    this.slideAxis = HabitatDoorSlideAxis.horizontal,
  });

  (int, int) cell;
  HabitatDoorSlideAxis slideAxis;

  /// 0 = fully closed (leaves together), 1 = fully open (leaves ±[maxLeafOffsetTiles]).
  double openProgress = 0;

  HabitatDoorPhase phase = HabitatDoorPhase.closed;

  /// Seconds to keep holding open after the last [requestOpen] / occupant leave.
  double _holdLeft = 0;

  static const double openSpeed = 1.7;
  static const double closeSpeed = 1.35;
  static const double holdAfterClearSeconds = 0.4;

  /// RimWorld uses ~0.45 cell per leaf.
  static const double maxLeafOffsetTiles = 0.45;

  bool get isFullyOpen => openProgress >= 1.0 - 1e-9;

  bool get blocksPassage => !isFullyOpen;

  void reseat((int, int) next, HabitatDoorSlideAxis axis) {
    cell = next;
    slideAxis = axis;
    openProgress = 0;
    phase = HabitatDoorPhase.closed;
    _holdLeft = 0;
  }

  /// Keep / start opening (pawn approaching, on cell, or stepping onto door).
  void requestOpen() {
    _holdLeft = holdAfterClearSeconds;
    if (phase == HabitatDoorPhase.closed ||
        phase == HabitatDoorPhase.closing) {
      phase = HabitatDoorPhase.opening;
    }
  }

  void tick(double dt) {
    // Consume hold after deciding this frame — a single large dt must not
    // wipe a fresh [requestOpen] before the leaves move.
    final wantOpen = _holdLeft > 0;
    if (_holdLeft > 0) {
      _holdLeft = (_holdLeft - dt).clamp(0.0, holdAfterClearSeconds);
    }

    if (wantOpen) {
      if (openProgress < 1) {
        phase = HabitatDoorPhase.opening;
        openProgress = (openProgress + openSpeed * dt).clamp(0.0, 1.0);
        if (isFullyOpen) phase = HabitatDoorPhase.open;
      } else {
        phase = HabitatDoorPhase.open;
      }
    } else if (openProgress > 0) {
      phase = HabitatDoorPhase.closing;
      openProgress = (openProgress - closeSpeed * dt).clamp(0.0, 1.0);
      if (openProgress <= 0) phase = HabitatDoorPhase.closed;
    } else {
      phase = HabitatDoorPhase.closed;
    }
  }

  /// Infer slide axis from neighboring walls (RimWorld `DoorRotationAt` idea).
  static HabitatDoorSlideAxis axisAt(HabitatMap map, int x, int y) {
    final ew = _wallish(map, x - 1, y) || _wallish(map, x + 1, y);
    final ns = _wallish(map, x, y - 1) || _wallish(map, x, y + 1);
    if (ew && !ns) return HabitatDoorSlideAxis.horizontal;
    if (ns && !ew) return HabitatDoorSlideAxis.vertical;
    if (y == 0 || y == map.height - 1) {
      return HabitatDoorSlideAxis.horizontal;
    }
    return HabitatDoorSlideAxis.vertical;
  }

  static bool _wallish(HabitatMap map, int x, int y) {
    if (!map.inBounds(x, y)) return true;
    // Treat door cell itself as non-wall; neighbors that are walls count.
    return map.isWallCell(x, y);
  }
}
