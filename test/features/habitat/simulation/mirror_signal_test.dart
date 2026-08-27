import 'package:fallhub/features/habitat/simulation/mirror/mirror.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 8, 12);

  group('MirrorSignal', () {
    test('clamps confidence outside 0..1', () {
      final low = MirrorSignal<double>(
        id: 'x',
        value: 1,
        source: MirrorSignalSource.simulated,
        observedAt: t0,
        confidence: -0.5,
      );
      expect(low.confidence, 0);

      final high = MirrorSignal<double>(
        id: 'x',
        value: 1,
        source: MirrorSignalSource.simulated,
        observedAt: t0,
        confidence: 1.5,
      );
      expect(high.confidence, 1);

      final nan = MirrorSignal<double>(
        id: 'x',
        value: 1,
        source: MirrorSignalSource.simulated,
        observedAt: t0,
        confidence: double.nan,
      );
      expect(nan.confidence, 0);
    });

    test('simulated never becomes externalObserved via copyWith alone', () {
      final s = MirrorSignal<double>(
        id: HabitatMirrorIds.indoorTemperatureC,
        value: 22.4,
        source: MirrorSignalSource.simulated,
        observedAt: t0,
        confidence: 1,
      );
      expect(s.source, MirrorSignalSource.simulated);
      // Explicit source change is allowed for adapters; provenance stays honest.
      final observed = s.copyWith(source: MirrorSignalSource.externalObserved);
      expect(observed.source, MirrorSignalSource.externalObserved);
      expect(s.source, MirrorSignalSource.simulated);
    });

    test('transformation chain is preserved and immutable', () {
      final base = MirrorSignal<double>(
        id: 'a',
        value: 1,
        source: MirrorSignalSource.simulated,
        observedAt: t0,
        confidence: 1,
        transformationChain: const ['seed'],
      );
      expect(() => base.transformationChain.add('nope'), throwsUnsupportedError);

      final derived = base.derive<double>(
        id: 'b',
        value: 2,
        source: MirrorSignalSource.systemDerived,
        observedAt: t0,
        confidence: 0.9,
        step: 'scale',
      );
      expect(derived.transformationChain, ['seed', 'scale']);
      expect(base.transformationChain, ['seed']);
    });
  });

  group('MirrorFreshness', () {
    test('fresh → aging → stale by age', () {
      final signal = MirrorSignal<double>(
        id: 't',
        value: 20,
        source: MirrorSignalSource.simulated,
        observedAt: t0,
        confidence: 1,
      );
      expect(
        MirrorValueQuality.freshness(signal, now: t0),
        MirrorFreshness.fresh,
      );
      expect(
        MirrorValueQuality.freshness(
          signal,
          now: t0.add(const Duration(minutes: 6)),
        ),
        MirrorFreshness.aging,
      );
      expect(
        MirrorValueQuality.freshness(
          signal,
          now: t0.add(const Duration(minutes: 31)),
        ),
        MirrorFreshness.stale,
      );
    });

    test('expired when past validUntil', () {
      final signal = MirrorSignal<double>(
        id: 't',
        value: 20,
        source: MirrorSignalSource.simulated,
        observedAt: t0,
        validUntil: t0.add(const Duration(minutes: 10)),
        confidence: 1,
      );
      expect(
        MirrorValueQuality.freshness(
          signal,
          now: t0.add(const Duration(minutes: 9)),
        ),
        isNot(MirrorFreshness.expired),
      );
      expect(
        MirrorValueQuality.freshness(
          signal,
          now: t0.add(const Duration(minutes: 10)),
        ),
        MirrorFreshness.expired,
      );
      expect(
        MirrorValueQuality.isCurrent(
          signal,
          now: t0.add(const Duration(minutes: 10)),
        ),
        isFalse,
      );
    });
  });

  group('MirrorProvenance', () {
    test('debug line includes source', () {
      final signal = MirrorSignal<double>(
        id: HabitatMirrorIds.indoorTemperatureC,
        value: 22.4,
        source: MirrorSignalSource.simulated,
        observedAt: t0,
        confidence: 1,
      );
      final line = MirrorProvenance.debugLine(signal, now: t0);
      expect(line, contains('source=simulated'));
      expect(line, contains(HabitatMirrorIds.indoorTemperatureC));
      expect(line, contains('22.4'));
    });

    test('sensitive values are redacted in log', () {
      final signal = MirrorSignal<String>(
        id: 'secret',
        value: 'should-not-appear',
        source: MirrorSignalSource.userDeclared,
        observedAt: t0,
        confidence: 1,
        isSensitive: true,
      );
      final log = MirrorProvenance.logLine(signal);
      expect(log, contains('<sensitive>'));
      expect(log, isNot(contains('should-not-appear')));
      expect(MirrorProvenance.debugLine(signal, now: t0), contains('<redacted>'));
    });
  });
}
