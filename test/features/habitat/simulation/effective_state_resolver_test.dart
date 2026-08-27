import 'package:fallhub/features/habitat/simulation/mirror/mirror.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 8, 12);
  final resolver = EffectiveStateResolver<double>();

  MirrorSignal<double> sig(
    MirrorSignalSource source,
    double value, {
    String id = HabitatMirrorIds.indoorTemperatureC,
    DateTime? validUntil,
  }) {
    return MirrorSignal<double>(
      id: id,
      value: value,
      source: source,
      observedAt: t0,
      validUntil: validUntil,
      confidence: 1,
    );
  }

  group('EffectiveStateResolver', () {
    test('manual override beats simulated', () {
      final result = resolver.resolve(
        signals: [sig(MirrorSignalSource.simulated, 22)],
        override: HabitatStateOverride<double>(
          dimensionId: HabitatMirrorIds.indoorTemperatureC,
          value: 28,
          startedAt: t0,
          reason: 'debug heater',
          expiresAt: t0.add(const Duration(minutes: 5)),
        ),
        now: t0,
      );
      expect(result.value, 28);
      expect(result.source, MirrorSignalSource.manual);
      expect(result.reason, ResolutionReason.overrideActive);
      expect(result.explanation, contains('override'));
    });

    test('expired override falls back to simulated', () {
      final result = resolver.resolve(
        signals: [sig(MirrorSignalSource.simulated, 22)],
        override: HabitatStateOverride<double>(
          dimensionId: HabitatMirrorIds.indoorTemperatureC,
          value: 28,
          startedAt: t0.subtract(const Duration(minutes: 10)),
          reason: 'debug heater',
          expiresAt: t0.subtract(const Duration(minutes: 1)),
        ),
        now: t0,
      );
      expect(result.value, 22);
      expect(result.source, MirrorSignalSource.simulated);
    });

    test('userDeclared beats simulated', () {
      final result = resolver.resolve(
        signals: [
          sig(MirrorSignalSource.simulated, 22),
          sig(MirrorSignalSource.userDeclared, 24),
        ],
        now: t0,
      );
      expect(result.value, 24);
      expect(result.source, MirrorSignalSource.userDeclared);
      expect(result.reason, ResolutionReason.higherPrecedence);
    });

    test('expired signal skipped', () {
      final result = resolver.resolve(
        signals: [
          sig(
            MirrorSignalSource.userDeclared,
            30,
            validUntil: t0.subtract(const Duration(seconds: 1)),
          ),
          sig(MirrorSignalSource.simulated, 21),
        ],
        now: t0,
      );
      expect(result.value, 21);
      expect(result.source, MirrorSignalSource.simulated);
    });

    test('strong conflict flagged without averaging', () {
      final result = resolver.resolve(
        signals: [
          sig(MirrorSignalSource.userDeclared, 20),
          sig(MirrorSignalSource.externalObserved, 26),
        ],
        now: t0,
      );
      expect(result.value, 20); // declared wins
      expect(result.hasConflict, isTrue);
      expect(result.value, isNot(23)); // no silent average
    });

    test('sole candidate', () {
      final result = resolver.resolve(
        signals: [sig(MirrorSignalSource.simulated, 22.4)],
        now: t0,
      );
      expect(result.reason, ResolutionReason.soleCandidate);
      expect(result.explanation, contains('Sole'));
    });
  });
}
