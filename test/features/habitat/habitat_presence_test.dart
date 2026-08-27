import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:fallhub/features/habitat/flame/habitat_presence.dart';
import 'package:fallhub/features/habitat/simulation/time/time.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HabitatPresence', () {
    test('follows scene clock periods', () {
      final scene = HabitatSceneClock();
      scene.freeze(DateTime(2026, 8, 7, 12, 0, 0));
      final p = HabitatPresence(sceneClock: scene);
      expect(p.phase, closeTo(0.5, 0.01));
      expect(p.phaseLabel, 'Dia');
      expect(p.overlayColor.a, lessThan(0.1));

      p.syncFromClock(DateTime(2026, 8, 7, 2, 0));
      expect(p.phaseLabel, 'Madrugada');

      p.syncFromClock(DateTime(2026, 8, 7, 6, 15));
      expect(p.phaseLabel, 'Amanhecer');

      p.syncFromClock(DateTime(2026, 8, 7, 17, 30));
      expect(p.phaseLabel, 'Entardecer');

      p.syncFromClock(DateTime(2026, 8, 7, 18, 0));
      expect(p.phaseLabel, 'Noite');
      expect(p.overlayColor.a, greaterThan(0.30));

      p.syncFromClock(DateTime(2026, 8, 7, 23, 30));
      expect(p.phaseLabel, 'Noite');
    });

    test('overlay alpha eases between period keyframes', () {
      final noonA = HabitatPresence.overlayColorForPhase(12 / 24).a;
      final duskA = HabitatPresence.overlayColorForPhase(17.5 / 24).a;
      final nightA = HabitatPresence.overlayColorForPhase(21 / 24).a;
      expect(noonA, lessThan(duskA));
      expect(duskA, lessThan(nightA));
    });

    test('audio stub respects mute default', () {
      final scene = HabitatSceneClock();
      scene.freeze(DateTime(2026, 8, 7, 12));
      final p = HabitatPresence(sceneClock: scene);
      expect(p.muted, isTrue);
      p.playStub('tap');
      expect(p.stubPlayCount, 0);
      p.muted = false;
      p.playStub('tap');
      expect(p.stubPlayCount, 1);
    });
  });

  group('HabitatGame camera', () {
    test('zoom and reset keep scene usable', () async {
      final game = HabitatGame(tileSize: 48);
      await game.onLoad();
      game.onGameResize(Vector2(800, 600));
      final z0 = game.camera.viewfinder.zoom;
      game.zoomBy(0.2);
      expect(game.userCamera, isTrue);
      expect(game.camera.viewfinder.zoom, greaterThan(z0));

      final mapW = game.map.width * game.tileSize;
      final mapH = game.map.height * game.tileSize;
      final z = game.camera.viewfinder.zoom;
      final viewW = 800 / z;
      final viewH = 600 / z;
      expect(
        game.camera.viewfinder.position.x,
        closeTo((mapW - viewW) / 2, 0.5),
      );
      expect(
        game.camera.viewfinder.position.y,
        closeTo((mapH - viewH) / 2, 0.5),
      );

      // Zoom in until pan is possible, then move within clamp.
      while (!game.canPanCamera && game.camera.viewfinder.zoom < 3.2) {
        game.zoomBy(0.25);
      }
      expect(game.canPanCamera, isTrue);
      final before = game.camera.viewfinder.position.clone();
      game.panByScreen(const Offset(-80, 0));
      expect(game.camera.viewfinder.position.x, isNot(closeTo(before.x, 0.01)));

      game.resetCamera();
      expect(game.userCamera, isFalse);
      expect(game.presence.phaseLabel, isNotEmpty);
      game.dispose();
    });
  });
}
