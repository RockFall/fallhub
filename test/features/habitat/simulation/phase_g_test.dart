import 'package:fallhub/features/habitat/simulation/content/habitat_devices.dart';
import 'package:fallhub/features/habitat/simulation/content/habitat_inventory.dart';
import 'package:fallhub/features/habitat/simulation/embodied/behavior_routine.dart';
import 'package:fallhub/features/habitat/simulation/embodied/embodied_runtime.dart';
import 'package:fallhub/features/habitat/simulation/embodied/pawn_embodied_store.dart';
import 'package:fallhub/features/habitat/simulation/identity/habitat_loadout.dart';
import 'package:fallhub/features/habitat/simulation/time/habitat_episode.dart';
import 'package:fallhub/features/habitat/simulation/world/context_profile.dart';
import 'package:fallhub/features/habitat/simulation/world/scene_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EmbodiedRuntime runtime() => EmbodiedRuntime(
        store: PawnEmbodiedStore(),
        episodes: HabitatEpisodeLedger(),
      );

  group('M30 scene presets', () {
    test('4+ presets alter light and props; state persists', () {
      final scenes = ScenePresetDirector();
      expect(scenes.presets.length, greaterThanOrEqualTo(4));
      scenes.apply('movieNight', nowSim: 10);
      expect(scenes.activePresetId, 'movieNight');
      expect(scenes.environment[HabitatEnvSwitch.tvOn], isTrue);
      expect(scenes.environment[HabitatEnvSwitch.lampOn], isFalse);
      scenes.markAftermath('movie');
      expect(scenes.environment.vestiges, isNotEmpty);
      scenes.apply('sleepMode', nowSim: 20);
      expect(scenes.environment[HabitatEnvSwitch.tvOn], isFalse);
      // vestiges survive preset change
      expect(scenes.environment.vestiges, isNotEmpty);
      expect(scenes.affordanceBoost('sleep'), greaterThan(0));
    });
  });

  group('M31 loadouts', () {
    test('catalog has 5+; bedtime suggests sleep; identity untouched', () {
      expect(HabitatLoadoutResolver.catalog.length, greaterThanOrEqualTo(5));
      final r = HabitatLoadoutResolver();
      final sleep = r.suggest(
        mapLocationId: 'bedroom',
        context: HabitatContextProfiles.forMapLocation('bedroom'),
        jobIsSleep: true,
        isOutdoor: false,
      );
      expect(sleep.id, 'sleep');
      final travel = r.suggest(
        mapLocationId: 'bedroom',
        context: HabitatContextProfiles.forMapLocation('bedroom'),
        jobIsSleep: false,
        isOutdoor: false,
        inTransit: true,
      );
      expect(travel.id, 'travel');
      var applied = '';
      r.maybeApply(
        pawnId: 'p1',
        loadout: sleep,
        force: true,
        applyVisual: (top, hat) => applied = top,
      );
      expect(applied, isNotEmpty);
      expect(r.currentByPawn['p1'], 'sleep');
    });
  });

  group('M32 inventory', () {
    test('shelf → hand → table → bag without duplicates', () {
      final inv = HabitatInventory()..seedDemo();
      expect(inv.items.containsKey('book.dune'), isTrue);
      inv.pickUp(itemId: 'book.dune', pawnId: 'p1');
      expect(
        inv.items['book.dune']!.location.kind,
        HabitatItemLocationKind.heldByPawn,
      );
      expect(inv.placeOnTable('book.dune'), isTrue);
      expect(
        inv.items['book.dune']!.location.kind,
        HabitatItemLocationKind.surfaceSlot,
      );
      inv.pickUp(itemId: 'book.dune', pawnId: 'p1');
      expect(inv.putInBag('book.dune'), isTrue);
      expect(inv.locationsConsistent, isTrue);
      expect(inv.items.length, 3);
    });
  });

  group('M33 devices + interrupt/resume', () {
    test('reading interrupts on call and resumes', () {
      final rt = runtime();
      final a = rt.startReadingDemo('p1', nowSim: 0)!;
      expect(a.phase, SustainedActivityPhase.active);
      rt.interruptActivities('p1', nowSim: 30);
      expect(a.phase, SustainedActivityPhase.resumable);
      expect(rt.resumeActivity(a.id, nowSim: 40), isTrue);
      expect(a.phase, SustainedActivityPhase.active);
      final tv = rt.devices.devices['tv']!;
      tv.use(mode: 'watch', mediaId: 'x', userId: 'p1');
      expect(tv.activeMode, 'watch');
      expect(tv.powered, isTrue);
    });
  });

  group('M34 behavior routines', () {
    test('prepareSleep runs 5+ steps; wakeUp branches; pause/resume', () {
      final engine = BehaviorRoutineEngine();
      final run = engine.start(definitionId: 'prepareSleep', pawnId: 'p1')!;
      final applied = <String>[];
      for (var i = 0; i < 12; i++) {
        engine.tick(
          pawnId: 'p1',
          nowSim: i * 10.0,
          effects: (node) {
            applied.add('${node.kind.name}:${node.id}');
            if (node.kind == RoutineNodeKind.wait) {
              return (node.params['seconds'] as num?)?.toDouble() ?? 0;
            }
            return 0;
          },
        );
        if (run.status == RoutineRunStatus.completed) break;
      }
      expect(run.executed.length, greaterThanOrEqualTo(5));
      expect(run.status, RoutineRunStatus.completed);

      final wake = engine.start(
        definitionId: 'wakeUp',
        pawnId: 'p2',
        nowSim: 100,
      )!;
      for (var i = 0; i < 40; i++) {
        engine.tick(
          pawnId: 'p2',
          nowSim: 100 + i * 5.0,
          effects: (node) {
            if (node.kind == RoutineNodeKind.wait) return 1;
            return 0;
          },
          branch: (_) => 'fail',
        );
        if (wake.status == RoutineRunStatus.completed) break;
      }
      expect(wake.executed.contains('wash_face'), isTrue);
      expect(wake.executed.contains('shower'), isFalse);

      final pauseRun = engine.start(
        definitionId: 'leaveHome',
        pawnId: 'p3',
        nowSim: 500,
      )!;
      engine.pause('p3');
      expect(pauseRun.status, RoutineRunStatus.paused);
      engine.tick(
        pawnId: 'p3',
        nowSim: 500,
        effects: (_) => 0,
      );
      expect(pauseRun.executed, isEmpty);
      engine.resume('p3');
      expect(pauseRun.status, RoutineRunStatus.running);
    });
  });

  group('M30–M34 runtime wiring', () {
    test('EmbodiedRuntime exposes directors', () {
      final rt = runtime();
      expect(rt.scenes.presets, isNotEmpty);
      expect(rt.loadouts.catalogOrEmpty, isNotEmpty);
      expect(rt.inventory.items, isNotEmpty);
      expect(rt.devices.devices, isNotEmpty);
      expect(rt.routines.definitions, isNotEmpty);
      rt.applyScenePreset('guests');
      expect(rt.scenes.activePresetId, 'guests');
    });
  });
}

extension on HabitatLoadoutResolver {
  List<HabitatLoadout> get catalogOrEmpty => HabitatLoadoutResolver.catalog;
}
