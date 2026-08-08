import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preloaded HabitatGame mounts under GameWidget with children', (
    tester,
  ) async {
    final live = HabitatGame();

    // Widget-test image decode only completes outside the fake async zone.
    await tester.runAsync(() async {
      await live.onLoad();
    });

    expect(live.loadError, isNull, reason: '${live.loadError}');
    expect(live.sceneReady, isTrue);
    expect(live.isLoaded || live.sceneReady, isTrue);
    expect(live.world.children.length, greaterThan(0));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: GameWidget(game: live),
          ),
        ),
      ),
    );

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(live.grid, isNotNull);
    expect(live.pawn, isNotNull);
    expect(live.world.children.length, greaterThan(0));
    live.dispose();
  });
}
