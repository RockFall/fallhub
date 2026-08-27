import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('SleepDetectionEngine', () {
    // Wide window so tests are timezone-independent.
    final config = SleepDetectionConfig(
      stillVarianceThreshold: 0.02,
      activeVarianceThreshold: 0.08,
      onsetStillDuration: const Duration(minutes: 20),
      wakeActiveDuration: const Duration(minutes: 5),
      minNightSession: const Duration(minutes: 60),
      minNapSession: const Duration(minutes: 20),
      napStillDuration: const Duration(minutes: 35),
      interruptMergeGap: const Duration(minutes: 15),
      sleepWindowStartHour: 0,
      sleepWindowEndHour: 24,
    );

    SleepSignalSample still(DateTime at, {bool charging = true}) =>
        SleepSignalSample(
          at: at,
          motionVariance: 0.005,
          screenOn: false,
          isCharging: charging,
        );

    SleepSignalSample active(DateTime at, {bool screen = true}) =>
        SleepSignalSample(
          at: at,
          motionVariance: 0.2,
          screenOn: screen,
          isCharging: false,
        );

    test('detects onset after sustained stillness', () {
      final engine = SleepDetectionEngine(config: config);
      final base = DateTime.utc(2026, 8, 8, 23);

      SleepOnsetDetected? onset;
      for (var m = 0; m <= 25; m += 5) {
        final event = engine.ingest(still(base.add(Duration(minutes: m))));
        if (event is SleepOnsetDetected) onset = event;
      }
      expect(onset, isNotNull);
      expect(onset!.onsetAt, base);
      expect(engine.phase, SleepDetectorPhase.asleep);
    });

    test('detects wake after sustained activity and keeps duration', () {
      final engine = SleepDetectionEngine(config: config);
      final start = DateTime.utc(2026, 8, 8, 23);

      for (var m = 0; m <= 25; m += 5) {
        engine.ingest(still(start.add(Duration(minutes: m))));
      }
      expect(engine.phase, SleepDetectorPhase.asleep);

      engine.ingest(still(start.add(const Duration(hours: 7))));

      final wakeStart = start.add(const Duration(hours: 7, minutes: 30));
      SleepWakeDetected? wake;
      for (var m = 0; m <= 8; m += 2) {
        final event = engine.ingest(active(wakeStart.add(Duration(minutes: m))));
        if (event is SleepWakeDetected) wake = event;
      }
      expect(wake, isNotNull);
      expect(wake!.onsetAt, start);
      expect(
        wake.wakeAt.difference(wake.onsetAt).inHours,
        greaterThanOrEqualTo(7),
      );
      expect(engine.phase, SleepDetectorPhase.awake);
    });

    test('screen on aborts settling', () {
      final engine = SleepDetectionEngine(config: config);
      final start = DateTime.utc(2026, 8, 8, 23);
      engine.ingest(still(start));
      expect(engine.phase, SleepDetectorPhase.settling);
      engine.ingest(active(start.add(const Duration(minutes: 5))));
      expect(engine.phase, SleepDetectorPhase.awake);
    });

    test('round-trips engine state json', () {
      final engine = SleepDetectionEngine(config: config);
      final start = DateTime.utc(2026, 8, 8, 23);
      for (var m = 0; m <= 25; m += 5) {
        engine.ingest(still(start.add(Duration(minutes: m))));
      }
      final restored =
          SleepDetectionEngine.fromJson(engine.toJson(), config: config);
      expect(restored.phase, engine.phase);
      expect(restored.asleepSince, engine.asleepSince);
    });
  });

  group('SleepSessionMergePolicy', () {
    const policy = SleepSessionMergePolicy();
    final now = DateTime.utc(2026, 8, 8);

    SleepSession session({
      required SleepSessionSource source,
      required DateTime start,
      required DateTime end,
      String id = 's1',
    }) {
      return SleepSession.create(
        id: EntityId(id),
        profileId: const EntityId('p1'),
        startedAt: start,
        endedAt: end,
        source: source,
        createdAt: now,
      );
    }

    test('HC supersedes overlapping detection', () {
      final detected = session(
        source: SleepSessionSource.detected,
        start: DateTime.utc(2026, 8, 7, 23),
        end: DateTime.utc(2026, 8, 8, 7),
      );
      final hc = session(
        id: 'hc',
        source: SleepSessionSource.healthConnect,
        start: DateTime.utc(2026, 8, 7, 23, 10),
        end: DateTime.utc(2026, 8, 8, 6, 50),
      );
      expect(
        policy.isSupersededByExisting(candidate: detected, existing: [hc]),
        isTrue,
      );
      expect(
        policy.isSupersededByExisting(candidate: hc, existing: [detected]),
        isFalse,
      );
    });
  });

  group('SleepSession', () {
    test('rejects endedAt before startedAt', () {
      expect(
        () => SleepSession.create(
          id: const EntityId('s'),
          profileId: const EntityId('p'),
          startedAt: DateTime.utc(2026, 8, 8, 8),
          endedAt: DateTime.utc(2026, 8, 8, 7),
          source: SleepSessionSource.manual,
          createdAt: DateTime.utc(2026, 8, 8),
        ),
        throwsArgumentError,
      );
    });
  });
}
