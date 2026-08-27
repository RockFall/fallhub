import 'package:fallhub/features/habitat/simulation/embodied/embodied.dart';
import 'package:fallhub/features/habitat/simulation/time/time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NeedEngine M5', () {
    test('needs change over accelerated sim time without NaN', () {
      final engine = NeedEngine(tickIntervalSimSeconds: 10);
      var state = PawnEmbodiedState.mock('p1');
      final startSleep = state.need(NeedKind.sleep)!.pressure;
      final at = DateTime.utc(2026, 8, 8);
      for (var t = 0.0; t <= 4 * 3600; t += 10) {
        state = engine.maybeTick(
          state: state,
          simSeconds: t,
          observedAt: at,
          isSedentary: t > 600,
        );
      }
      for (final n in state.needs.values) {
        expect(n.pressure.isNaN, isFalse);
        expect(n.pressure, inInclusiveRange(0, 1));
      }
      expect(state.need(NeedKind.sleep)!.pressure, greaterThan(startSleep));
      expect(state.need(NeedKind.movement)!.pressure, greaterThan(0.2));
    });

    test('at least 6 needs and 4+ affordance need weights', () {
      expect(NeedKind.values.length, greaterThanOrEqualTo(6));
      final weighted = AffordanceCatalog.byId.values
          .where((d) => d.needWeights.isNotEmpty)
          .length;
      expect(weighted, greaterThanOrEqualTo(4));
    });
  });

  group('CapacityEngine M6', () {
    test('5+ capacities with contributors', () {
      final engine = CapacityEngine();
      final state = engine.recompute(
        PawnEmbodiedState.mock('p1'),
        observedAt: DateTime.utc(2026, 8, 8),
      );
      expect(state.capacities.length, greaterThanOrEqualTo(5));
      expect(
        state.capacity(CapacityKind.energy)!.derivedFrom,
        isNotEmpty,
      );
    });

    test('same need, different capacity changes top affordance', () {
      final scorer = const ChoiceScorer();
      var low = PawnEmbodiedState.mock('a');
      low = CapacityEngine().recompute(low, observedAt: DateTime.utc(2026, 8, 8));
      // Force creative need high, capacity low vs high.
      final needs = Map<NeedKind, NeedReading>.from(low.needs);
      needs[NeedKind.creativeExpression] = needs[NeedKind.creativeExpression]!
          .copyWith(pressure: 0.9);
      low = low.copyWith(needs: needs);
      final lowCap = Map<CapacityKind, CapacityReading>.from(low.capacities);
      lowCap[CapacityKind.creativeCapacity] =
          lowCap[CapacityKind.creativeCapacity]!.copyWith(level: 0.15);
      low = low.copyWith(capacities: lowCap);

      var high = low;
      final highCap = Map<CapacityKind, CapacityReading>.from(high.capacities);
      highCap[CapacityKind.creativeCapacity] =
          highCap[CapacityKind.creativeCapacity]!.copyWith(level: 0.95);
      high = high.copyWith(capacities: highCap);

      final lowScore = scorer.score(
        affordanceId: HabitatAffordances.creativeShort,
        state: low,
      );
      final highScore = scorer.score(
        affordanceId: HabitatAffordances.creativeShort,
        state: high,
      );
      expect(highScore, greaterThan(lowScore));
      // Low capacity prefers lighter creative (listen) relatively more often.
      final listenLow = scorer.score(
        affordanceId: HabitatAffordances.listenMusic,
        state: low,
      );
      expect(listenLow / (lowScore + 1e-6), greaterThan(0.5));
    });
  });

  group('ConditionEngine M7', () {
    test('conditions expire and combine walk speed', () {
      final engine = ConditionEngine();
      var state = PawnEmbodiedState.mock('p1');
      state = engine.upsert(
        state,
        engine.create(
          kind: PawnConditionKind.sleepy,
          intensity: 0.7,
          atSimSeconds: 0,
          durationSeconds: 20,
        ),
      );
      state = engine.upsert(
        state,
        engine.create(
          kind: PawnConditionKind.inspired,
          intensity: 0.5,
          atSimSeconds: 0,
          durationSeconds: 100,
        ),
      );
      expect(state.conditions.length, 2);
      final speed = ConditionEngine.combinedWalkSpeed(state.conditions);
      expect(speed, lessThan(1.0));
      // Force tick past expiry of sleepy.
      engine.maybeTick(state: state, simSeconds: 0);
      state = engine.maybeTick(state: state, simSeconds: 25);
      expect(
        state.conditions.any((c) => c.kind == PawnConditionKind.sleepy),
        isFalse,
      );
    });
  });

  group('SleepSystem M8', () {
    test('16h awake pressure > 2h awake', () {
      final ledger = HabitatEpisodeLedger();
      final sleep = SleepSystem(episodes: ledger);
      var short = PawnEmbodiedState.mock('p');
      short = sleep.tick(
        state: short,
        simSeconds: 2 * 3600,
        sceneHour: 14,
        observedAt: DateTime.utc(2026, 8, 8),
        jobIsSleep: false,
      );
      var long = PawnEmbodiedState.mock('p2');
      // Simulate long awake by ticking at 16h mark with awakeSince defaulting to 0...
      // awakeSince starts at first tick time; force via multiple ticks.
      for (final t in [0.0, 3600.0, 8 * 3600.0, 16 * 3600.0]) {
        long = sleep.tick(
          state: long,
          simSeconds: t,
          sceneHour: 23,
          observedAt: DateTime.utc(2026, 8, 8),
          jobIsSleep: false,
        );
      }
      expect(
        long.circadian.sleepPressure,
        greaterThan(short.circadian.sleepPressure),
      );
    });

    test('sleeping reduces pressure; same seed profiles match', () {
      final a = CircadianProfile.fromSeed('colonist');
      final b = CircadianProfile.fromSeed('colonist');
      expect(a.preferredSleepHour, b.preferredSleepHour);

      final ledger = HabitatEpisodeLedger();
      final sleep = SleepSystem(episodes: ledger);
      var state = PawnEmbodiedState.mock('p');
      state = state.copyWith(
        circadian: state.circadian.copyWith(sleepPressure: 0.85),
        sleepPhase: SleepPhase.sleepy,
      );
      state = sleep.tick(
        state: state,
        simSeconds: 10,
        sceneHour: 23,
        observedAt: DateTime.utc(2026, 8, 8),
        jobIsSleep: true,
      );
      expect(state.sleepPhase, SleepPhase.sleeping);
      expect(state.activeSleepEpisodeId, isNotNull);
      final before = state.circadian.sleepPressure;
      state = sleep.tick(
        state: state,
        simSeconds: 40,
        sceneHour: 23,
        observedAt: DateTime.utc(2026, 8, 8),
        jobIsSleep: true,
      );
      expect(state.circadian.sleepPressure, lessThan(before));
    });
  });

  group('MovementRecovery M9', () {
    test('sedentary raises movement need; exercise raises fatigue', () {
      final sys = MovementRecoverySystem();
      var state = PawnEmbodiedState.mock('p');
      final at = DateTime.utc(2026, 8, 8);
      for (var t = 0.0; t <= 400; t += 5) {
        state = sys.maybeTick(
          state: state,
          simSeconds: t,
          observedAt: at,
          isMoving: false,
          isSedentary: true,
          isSleeping: false,
        );
      }
      expect(state.movement.sedentarySeconds, greaterThan(100));
      final fatigued = sys.maybeTick(
        state: state,
        simSeconds: 500,
        observedAt: at,
        isMoving: true,
        isSedentary: false,
        isSleeping: false,
        activityPhysicalLoad: 0.8,
      );
      expect(
        fatigued.movement.physicalFatigue,
        greaterThan(state.movement.physicalFatigue),
      );
    });
  });
}
