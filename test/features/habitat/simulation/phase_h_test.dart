import 'package:fallhub/features/habitat/simulation/content/habitat_food.dart';
import 'package:fallhub/features/habitat/simulation/content/habitat_preparation.dart';
import 'package:fallhub/features/habitat/simulation/content/habitat_workpiece.dart';
import 'package:fallhub/features/habitat/simulation/embodied/behavior_routine.dart';
import 'package:fallhub/features/habitat/simulation/embodied/embodied_runtime.dart';
import 'package:fallhub/features/habitat/simulation/embodied/pawn_embodied_state.dart';
import 'package:fallhub/features/habitat/simulation/embodied/pawn_embodied_store.dart';
import 'package:fallhub/features/habitat/simulation/time/habitat_episode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EmbodiedRuntime runtime() => EmbodiedRuntime(
        store: PawnEmbodiedStore(),
        episodes: HabitatEpisodeLedger(),
      );

  group('M35 morning/bedtime', () {
    test('morning and bedtime routines complete end-to-end', () {
      final engine = BehaviorRoutineEngine();
      expect(engine.definitions.containsKey('morning'), isTrue);
      expect(engine.definitions.containsKey('bedtime'), isTrue);
      final morning = engine.start(
        definitionId: 'morning',
        pawnId: 'p1',
        nowSim: 0,
      )!;
      for (var i = 0; i < 40; i++) {
        engine.tick(
          pawnId: 'p1',
          nowSim: i * 5.0,
          effects: (n) => n.kind == RoutineNodeKind.wait ? 1.0 : 0.0,
          branch: (_) => 'fail',
        );
        if (morning.status == RoutineRunStatus.completed) break;
      }
      expect(morning.status, RoutineRunStatus.completed);
      expect(morning.executed.contains('wash_face'), isTrue);

      final bed = engine.start(
        definitionId: 'bedtime',
        pawnId: 'p1',
        nowSim: 200,
      )!;
      for (var i = 0; i < 20; i++) {
        engine.tick(
          pawnId: 'p1',
          nowSim: 200 + i * 5.0,
          effects: (n) => n.kind == RoutineNodeKind.wait ? 1.0 : 0.0,
        );
        if (bed.status == RoutineRunStatus.completed) break;
      }
      expect(bed.status, RoutineRunStatus.completed);
      expect(bed.executed.contains('bed'), isTrue);
    });
  });

  group('M36 leave/arrive', () {
    test('prepareToLeave and arriveHome routines exist and run', () {
      final rt = runtime();
      final leave = rt.routines.start(
        definitionId: 'prepareToLeave',
        pawnId: 'p1',
        nowSim: 0,
      )!;
      for (var i = 0; i < 12; i++) {
        rt.routines.tick(
          pawnId: 'p1',
          nowSim: i * 5.0,
          effects: (_) => 0,
        );
        if (leave.status == RoutineRunStatus.completed) break;
      }
      expect(leave.status, RoutineRunStatus.completed);

      final arrive = rt.routines.start(
        definitionId: 'arriveHome',
        pawnId: 'p1',
        nowSim: 100,
      )!;
      for (var i = 0; i < 12; i++) {
        rt.routines.tick(
          pawnId: 'p1',
          nowSim: 100 + i * 5.0,
          effects: (n) => n.kind == RoutineNodeKind.wait ? 1.0 : 0.0,
        );
        if (arrive.status == RoutineRunStatus.completed) break;
      }
      expect(arrive.status, RoutineRunStatus.completed);
    });
  });

  group('M37 kitchen', () {
    test('two dishes + shared meal reduces food need', () {
      final rt = runtime();
      rt.store.ensure('cook');
      rt.store.ensure('guest');
      // Raise food pressure first.
      final cook = rt.store['cook']!;
      final food = cook.need(NeedKind.food)!;
      rt.store.put(
        cook.copyWith(
          needs: {
            ...cook.needs,
            NeedKind.food: food.copyWith(
              pressure: 0.9,
              observedAt: DateTime.now().toUtc(),
            ),
          },
        ),
      );
      rt.kitchen.demoTwoDishes('cook');
      expect(
        rt.kitchen.sessions.values
            .where((s) => s.phase == CookingPhase.done)
            .length,
        greaterThanOrEqualTo(2),
      );
      final meal = rt.demoSharedMeal(
        cookId: 'cook',
        guests: ['guest'],
      );
      expect(meal.finished, isTrue);
      expect(rt.kitchen.aftermath, isNotEmpty);
      final after = rt.store['cook']!.need(NeedKind.food)!.pressure;
      expect(after, lessThan(0.9));
    });
  });

  group('M38 workpieces', () {
    test('progress survives sessions and finishes with chronicle', () {
      final dir = HabitatWorkpieceDirector();
      final w = dir.ensurePainting('p1');
      dir.workOn(w.id, delta: 0.3);
      final stage1 = w.stage;
      dir.abandon(w.id);
      expect(w.abandoned, isTrue);
      dir.workOn(w.id, delta: 0.3);
      expect(w.abandoned, isFalse);
      expect(w.visualProgress, greaterThan(0));
      // Finish.
      while (!w.finished) {
        dir.workOn(w.id, delta: 0.25);
      }
      expect(w.stage, 'finished');
      expect(w.chronicleCandidate, isNotNull);
      expect(stage1, isNot(equals('finished')));
    });
  });

  group('M39 preparation', () {
    test('work context collects laptop into bag', () {
      final rt = runtime();
      final r = rt.prepareForContext('work', 'p1');
      expect(r.satisfied, isTrue);
      expect(r.collectedItemIds, isNotEmpty);
      final laptop = rt.inventory.items['laptop.demo']!;
      expect(laptop.location.containerId, 'bag');

      final travel = rt.prepareForContext('travel', 'p1');
      // suitcase missing → required fail; passport may collect
      expect(travel.missingRequired, contains('suitcase'));
      expect(travel.satisfied, isFalse);
    });
  });
}
