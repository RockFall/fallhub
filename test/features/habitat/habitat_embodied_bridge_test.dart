import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:fallhub/features/habitat/simulation/embodied/embodied.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HabitatGame publishes embodied state outside Flame component', () async {
    final game = HabitatGame(tileSize: 48);
    await game.onLoad();
    expect(game.pawn, isNotNull);
    final id = game.pawn!.memberId;
    final state = game.embodiedFor(id);
    expect(state, isNotNull);
    expect(state!.needs.length, greaterThanOrEqualTo(3));
    expect(state.capacities.length, greaterThanOrEqualTo(3));
    // Conditions start empty; engines apply them at runtime.
    expect(state.conditions, isA<List<PawnCondition>>());
    // Not stored on the component itself:
    expect(game.pawn, isA<Object>());
    expect(identical(game.embodied[id], state), isTrue);
    expect(game.indoorTemperatureSignal, isNotNull);
    expect(game.indoorTemperatureEffective, isNotNull);
    game.dispose();
  });
}
