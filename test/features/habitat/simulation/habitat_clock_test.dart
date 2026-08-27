import 'package:fallhub/features/habitat/simulation/time/time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitatClockBundle', () {
    test('real clock never uses simulation speed', () {
      final fixed = DateTime.utc(2026, 8, 8, 15, 0);
      final real = HabitatRealClock(now: () => fixed);
      final bundle = HabitatClockBundle(real: real);
      bundle.setDebugSpeed(30);
      expect(bundle.real.now(), fixed);
      expect(bundle.simulation.speedMultiplier, 30);
      expect(bundle.scene.speed, 30);
    });

    test('simulation advances with speed; fake tick', () {
      final sim = HabitatSimulationClock();
      sim.setSpeed(5);
      sim.tick(2);
      expect(sim.elapsedSeconds, closeTo(10, 1e-9));
      sim.skip(const Duration(hours: 1));
      expect(sim.elapsedSeconds, closeTo(10 + 3600, 1e-6));
    });

    test('scene advances via tick, not wall clock', () {
      final bundle = HabitatClockBundle();
      bundle.scene.freeze(DateTime(2026, 8, 8, 10, 0));
      bundle.scene.unfreeze();
      bundle.scene.setSceneHour(10);
      bundle.scene.setSpeed(1);
      final before = bundle.scene.now();
      bundle.tick(3600); // 1 real second * speed 1 = 1s scene... wait 3600s
      expect(
        bundle.scene.now().difference(before).inSeconds,
        3600,
      );
    });

    test('scene and simulation can diverge', () {
      final bundle = HabitatClockBundle();
      bundle.scene.setSceneHour(22);
      bundle.simulation.setSpeed(1);
      bundle.simulation.tick(100);
      expect(bundle.scene.now().hour, 22);
      expect(bundle.simulation.elapsedSeconds, closeTo(100, 1e-9));
      expect(bundle.scene.phase * 24, closeTo(22, 0.02));
    });

    test('skipOneHour moves scene hour', () {
      final bundle = HabitatClockBundle();
      bundle.scene.setSceneHour(10);
      final before = bundle.scene.now();
      bundle.skipOneHour();
      expect(
        bundle.scene.now().difference(before),
        const Duration(hours: 1),
      );
    });

    test('siteTimezoneId toSiteLocal local', () {
      final bundle = HabitatClockBundle(siteTimezoneId: 'local');
      final utc = DateTime.utc(2026, 8, 8, 12);
      final local = bundle.toSiteLocal(utc);
      expect(local.isUtc, isFalse);
    });
  });

  group('HabitatEpisode', () {
    test('start and end episode', () {
      final ledger = HabitatEpisodeLedger();
      final ep = ledger.start(
        id: 'sleep-1',
        kind: 'sleep',
        atSimSeconds: 10,
        data: {'pawn': 'player'},
      );
      expect(ep.isOpen, isTrue);
      expect(ledger.openOfKind('sleep').length, 1);
      final ended = ledger.end('sleep-1', 100);
      expect(ended, isNotNull);
      expect(ended!.isOpen, isFalse);
      expect(ended.durationSeconds(100), 90);
      expect(ledger.openOfKind('sleep'), isEmpty);
    });
  });
}
