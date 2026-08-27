import 'mirror_signal.dart';

/// Confidence helper for [MirrorSignal] (always `0..1`).
abstract final class MirrorConfidence {
  static const double min = 0;
  static const double max = 1;

  static double clamp(double c) => MirrorSignal.clampConfidence(c);

  static bool isValid(double c) => !c.isNaN && c >= min && c <= max;
}

/// Freshness of a signal relative to [now].
enum MirrorFreshness {
  fresh,
  aging,
  stale,
  expired,
}

/// Derives [MirrorFreshness] from timestamps (MD 08 M0).
///
/// Labels are not persisted — compute on read.
abstract final class MirrorValueQuality {
  /// Age thresholds after [MirrorSignal.observedAt] (when no [validUntil]).
  static const Duration agingAfter = Duration(minutes: 5);
  static const Duration staleAfter = Duration(minutes: 30);

  static MirrorFreshness freshness(
    MirrorSignal<Object?> signal, {
    required DateTime now,
    Duration? agingAfter,
    Duration? staleAfter,
  }) {
    final until = signal.validUntil;
    if (until != null && !now.isBefore(until)) {
      return MirrorFreshness.expired;
    }

    final age = now.difference(signal.observedAt);
    if (age.isNegative) return MirrorFreshness.fresh;

    final aging = agingAfter ?? MirrorValueQuality.agingAfter;
    final stale = staleAfter ?? MirrorValueQuality.staleAfter;

    if (age >= stale) return MirrorFreshness.stale;
    if (age >= aging) return MirrorFreshness.aging;
    return MirrorFreshness.fresh;
  }

  /// True when the signal may still win current resolution.
  static bool isCurrent(
    MirrorSignal<Object?> signal, {
    required DateTime now,
  }) {
    final f = freshness(signal, now: now);
    return f != MirrorFreshness.expired;
  }
}
