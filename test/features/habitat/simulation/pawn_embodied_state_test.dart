import 'package:fallhub/features/habitat/simulation/embodied/embodied.dart';
import 'package:fallhub/features/habitat/simulation/mirror/mirror.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PawnEmbodiedState', () {
    test('mock seeds ≥3 needs, ≥3 capacities', () {
      final state = PawnEmbodiedState.mock('player');
      expect(state.needs.length, greaterThanOrEqualTo(3));
      expect(state.capacities.length, greaterThanOrEqualTo(3));
      expect(state.need(NeedKind.sleep)?.source, MirrorSignalSource.simulated);
      expect(
        state.capacity(CapacityKind.energy)?.derivedFrom,
        isNotEmpty,
      );
    });

    test('maps are independent per pawn', () {
      final a = PawnEmbodiedState.mock('a');
      final b = PawnEmbodiedState.mock('b');
      expect(identical(a.needs, b.needs), isFalse);
      expect(a.pawnId, isNot(b.pawnId));
    });
  });

  group('PawnEmbodiedStore', () {
    test('ensure creates once and reuses', () {
      final store = PawnEmbodiedStore();
      final first = store.ensure('player');
      final second = store.ensure('player');
      expect(identical(first, second), isTrue);
      expect(store['player'], isNotNull);
    });

    test('updatePresence preserves needs', () {
      final store = PawnEmbodiedStore();
      store.ensure('player');
      store.updatePresence(
        'player',
        const EmbodiedPresenceContext(roomRole: 'bedroom'),
      );
      final s = store['player']!;
      expect(s.presence.roomRole, 'bedroom');
      expect(s.needs.containsKey(NeedKind.sleep), isTrue);
    });
  });
}
