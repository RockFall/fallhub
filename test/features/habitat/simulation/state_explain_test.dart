import 'package:fallhub/features/habitat/simulation/debug/state_explain.dart';
import 'package:fallhub/features/habitat/simulation/embodied/embodied.dart';
import 'package:fallhub/features/habitat/simulation/mirror/mirror.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StateExplain', () {
    test('need and capacity lines include source', () {
      final state = PawnEmbodiedState.mock('player');
      final sleep = state.need(NeedKind.sleep)!;
      expect(StateExplain.needLine(sleep), contains('simulated'));
      expect(StateExplain.needExplain(sleep), contains('source: simulated'));

      final energy = state.capacity(CapacityKind.energy)!;
      expect(StateExplain.capacityExplain(energy), contains('derived from:'));
      expect(StateExplain.capacityExplain(energy), contains('need.sleep'));
    });

    test('sensitive signal redacted', () {
      final signal = MirrorSignal<String>(
        id: 'secret',
        value: 'hidden-value',
        source: MirrorSignalSource.userDeclared,
        observedAt: DateTime.utc(2026, 8, 8),
        confidence: 1,
        isSensitive: true,
      );
      final line = StateExplain.signalLine(signal);
      expect(line, contains('<redacted>'));
      expect(line, isNot(contains('hidden-value')));
    });
  });
}
