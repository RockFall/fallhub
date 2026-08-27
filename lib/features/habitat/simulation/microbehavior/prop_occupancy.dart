/// Soft occupancy for seats / approach slots (Block A fix + Block B).
class PropOccupancyBoard {
  final Map<String, String> _propToPawn = {};
  final Map<String, String> _cellToPawn = {};

  String? occupantOfProp(String propId) => _propToPawn[propId];
  String? occupantOfCell((int, int) cell) => _cellToPawn['${cell.$1},${cell.$2}'];

  bool isPropFree(String propId, {String? forPawn}) {
    final o = _propToPawn[propId];
    return o == null || o == forPawn;
  }

  bool tryClaimProp(String propId, String pawnId) {
    final o = _propToPawn[propId];
    if (o != null && o != pawnId) return false;
    _propToPawn[propId] = pawnId;
    return true;
  }

  void releaseProp(String propId, {String? pawnId}) {
    final o = _propToPawn[propId];
    if (o == null) return;
    if (pawnId != null && o != pawnId) return;
    _propToPawn.remove(propId);
  }

  bool tryClaimCell((int, int) cell, String pawnId) {
    final key = '${cell.$1},${cell.$2}';
    final o = _cellToPawn[key];
    if (o != null && o != pawnId) return false;
    _cellToPawn[key] = pawnId;
    return true;
  }

  void releaseCell((int, int) cell, {String? pawnId}) {
    final key = '${cell.$1},${cell.$2}';
    final o = _cellToPawn[key];
    if (o == null) return;
    if (pawnId != null && o != pawnId) return;
    _cellToPawn.remove(key);
  }

  void releasePawn(String pawnId) {
    _propToPawn.removeWhere((_, v) => v == pawnId);
    _cellToPawn.removeWhere((_, v) => v == pawnId);
  }

  Set<(int, int)> occupiedCells({String? exceptPawn}) {
    final out = <(int, int)>{};
    for (final e in _cellToPawn.entries) {
      if (exceptPawn != null && e.value == exceptPawn) continue;
      final parts = e.key.split(',');
      out.add((int.parse(parts[0]), int.parse(parts[1])));
    }
    return out;
  }
}
