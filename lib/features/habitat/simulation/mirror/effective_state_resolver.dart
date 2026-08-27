import 'mirror_signal.dart';
import 'mirror_value_quality.dart';

/// Why a particular signal won resolution.
enum ResolutionReason {
  soleCandidate,
  higherPrecedence,
  overrideActive,
  fallbackUnknown,
  expiredSkipped,
}

/// Precedence policy for choosing among [MirrorSignal]s of the same dimension.
class ResolutionPolicy {
  const ResolutionPolicy({
    this.sourceRank = defaultSourceRank,
  });

  /// Lower rank number = higher precedence.
  final Map<MirrorSignalSource, int> sourceRank;

  static const Map<MirrorSignalSource, int> defaultSourceRank = {
    MirrorSignalSource.manual: 0,
    MirrorSignalSource.userDeclared: 1,
    MirrorSignalSource.externalObserved: 2,
    MirrorSignalSource.externalDerived: 3,
    MirrorSignalSource.systemDerived: 4,
    MirrorSignalSource.simulated: 5,
    MirrorSignalSource.unknown: 6,
  };

  int rankOf(MirrorSignalSource source) =>
      sourceRank[source] ?? defaultSourceRank[source] ?? 99;

  /// True when two strong sources disagree enough to flag a conflict
  /// (same precedence band, different values — no silent average).
  bool isStrongConflict(MirrorSignalSource a, MirrorSignalSource b) {
    final ra = rankOf(a);
    final rb = rankOf(b);
    // Manual / declared / observed are "strong".
    return ra <= 2 && rb <= 2 && a != b;
  }
}

/// Resolved value plus explainability for inspect / debug.
class EffectiveValue<T> {
  const EffectiveValue({
    required this.value,
    required this.winningSignal,
    required this.considered,
    required this.explanation,
    required this.reason,
    this.hasConflict = false,
  });

  final T value;
  final MirrorSignal<T> winningSignal;
  final List<MirrorSignal<T>> considered;
  final String explanation;
  final ResolutionReason reason;
  final bool hasConflict;

  MirrorSignalSource get source => winningSignal.source;
}

/// Temporary manual override for a Habitat dimension (MD 08 M1).
class HabitatStateOverride<T> {
  const HabitatStateOverride({
    required this.dimensionId,
    required this.value,
    required this.startedAt,
    required this.reason,
    this.expiresAt,
  });

  final String dimensionId;
  final T value;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final String reason;

  bool isActiveAt(DateTime now) {
    if (expiresAt == null) return true;
    return now.isBefore(expiresAt!);
  }

  MirrorSignal<T> asSignal({required DateTime now}) {
    return MirrorSignal<T>(
      id: dimensionId,
      value: value,
      source: MirrorSignalSource.manual,
      observedAt: startedAt,
      validUntil: expiresAt,
      confidence: 1,
      sourceRef: 'override:$reason',
      transformationChain: const ['manual_override'],
    );
  }
}

/// Picks the effective value among competing signals + optional override.
class EffectiveStateResolver<T> {
  EffectiveStateResolver({
    this.policy = const ResolutionPolicy(),
  });

  final ResolutionPolicy policy;

  EffectiveValue<T> resolve({
    required List<MirrorSignal<T>> signals,
    HabitatStateOverride<T>? override,
    required DateTime now,
    T? fallback,
  }) {
    final considered = <MirrorSignal<T>>[];

    if (override != null && override.isActiveAt(now)) {
      final o = override.asSignal(now: now);
      considered.add(o);
      for (final s in signals) {
        if (MirrorValueQuality.isCurrent(s, now: now)) {
          considered.add(s);
        }
      }
      final conflict = signals.any(
        (s) =>
            MirrorValueQuality.isCurrent(s, now: now) &&
            policy.isStrongConflict(MirrorSignalSource.manual, s.source) &&
            s.value != override.value,
      );
      return EffectiveValue<T>(
        value: override.value,
        winningSignal: o,
        considered: List.unmodifiable(considered),
        explanation:
            'Manual override (${override.reason}) wins over ${signals.length} '
            'other source(s).',
        reason: ResolutionReason.overrideActive,
        hasConflict: conflict,
      );
    }

    MirrorSignal<T>? best;
    var bestRank = 999;
    var skippedExpired = 0;
    final current = <MirrorSignal<T>>[];

    for (final s in signals) {
      considered.add(s);
      if (!MirrorValueQuality.isCurrent(s, now: now)) {
        skippedExpired++;
        continue;
      }
      current.add(s);
      final r = policy.rankOf(s.source);
      if (best == null || r < bestRank) {
        best = s;
        bestRank = r;
      } else if (r == bestRank && best.value != s.value) {
        // Same rank, different value — keep first winner, flag conflict later.
      }
    }

    if (best == null) {
      if (fallback == null) {
        throw StateError('No current signals and no fallback for resolve');
      }
      final unknown = MirrorSignal<T>(
        id: 'fallback',
        value: fallback,
        source: MirrorSignalSource.unknown,
        observedAt: now,
        confidence: 0,
      );
      return EffectiveValue<T>(
        value: fallback,
        winningSignal: unknown,
        considered: List.unmodifiable(considered),
        explanation: skippedExpired > 0
            ? 'All signals expired; using fallback.'
            : 'No signals; using fallback.',
        reason: ResolutionReason.fallbackUnknown,
      );
    }

    var conflict = false;
    for (final s in current) {
      if (identical(s, best)) continue;
      if (s.value == best.value) continue;
      if (policy.rankOf(s.source) == bestRank ||
          policy.isStrongConflict(best.source, s.source)) {
        conflict = true;
        break;
      }
    }

    final reason = skippedExpired > 0 && current.length == 1
        ? ResolutionReason.expiredSkipped
        : current.length == 1
            ? ResolutionReason.soleCandidate
            : ResolutionReason.higherPrecedence;

    final losers = current
        .where((s) => !identical(s, best))
        .map((s) => s.source.name)
        .join(', ');

    final skipNote =
        skippedExpired > 0 ? ' Skipped $skippedExpired expired.' : '';

    return EffectiveValue<T>(
      value: best.value,
      winningSignal: best,
      considered: List.unmodifiable(considered),
      explanation: losers.isEmpty
          ? 'Sole current source: ${best.source.name}.$skipNote'
          : 'Chose ${best.source.name} (rank $bestRank) over $losers.$skipNote',
      reason: reason,
      hasConflict: conflict,
    );
  }
}
