import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HabitatGame onLoad builds walkable scene and wander moves', () async {
    final game = HabitatGame();
    await game.onLoad();

    expect(game.sceneReady, isTrue);
    expect(game.pawn, isNotNull);
    final pawn = game.pawn!;
    expect(game.map.isWalkable(pawn.cellX, pawn.cellY), isTrue);

    final start = (pawn.cellX, pawn.cellY);
    var sawBob = false;
    for (var i = 0; i < 400; i++) {
      pawn.update(0.05);
      if (pawn.walkBob > 0) sawBob = true;
    }
    final end = (pawn.cellX, pawn.cellY);
    expect(game.map.isWalkable(end.$1, end.$2), isTrue);
    expect(start != end || pawn.isMoving, isTrue);
    expect(sawBob, isTrue);
    game.dispose();
  });
}
