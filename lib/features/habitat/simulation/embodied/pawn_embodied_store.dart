import 'pawn_embodied_state.dart';

/// In-memory embodied state by pawn id — lives outside Flame components (M3+).
class PawnEmbodiedStore {
  final Map<String, PawnEmbodiedState> _byId = {};

  PawnEmbodiedState? operator [](String pawnId) => _byId[pawnId];

  Iterable<String> get ids => _byId.keys;

  PawnEmbodiedState ensure(
    String pawnId, {
    EmbodiedPresenceContext? presence,
  }) {
    final existing = _byId[pawnId];
    if (existing != null) return existing;
    final created = PawnEmbodiedState.mock(pawnId, presence: presence);
    _byId[pawnId] = created;
    return created;
  }

  void put(PawnEmbodiedState state) {
    _byId[state.pawnId] = state;
  }

  void remove(String pawnId) => _byId.remove(pawnId);

  void clear() => _byId.clear();

  void updatePresence(String pawnId, EmbodiedPresenceContext presence) {
    final current = ensure(pawnId);
    put(current.copyWith(presence: presence));
  }
}
