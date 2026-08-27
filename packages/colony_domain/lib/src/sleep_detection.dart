import 'enums.dart';
import 'sleep_session.dart';

/// One sensor snapshot for the sleep detector (ADR-035).
class SleepSignalSample {
  const SleepSignalSample({
    required this.at,
    required this.motionVariance,
    required this.screenOn,
    required this.isCharging,
  });

  final DateTime at;

  /// Variance of accelerometer magnitude over the sample window.
  /// Lower = more still (typical bedside phone).
  final double motionVariance;

  final bool screenOn;
  final bool isCharging;
}

/// Tunable thresholds for on-device sleep detection.
class SleepDetectionConfig {
  const SleepDetectionConfig({
    this.stillVarianceThreshold = 0.018,
    this.activeVarianceThreshold = 0.08,
    this.onsetStillDuration = const Duration(minutes: 22),
    this.wakeActiveDuration = const Duration(minutes: 7),
    this.minNightSession = const Duration(minutes: 90),
    this.minNapSession = const Duration(minutes: 25),
    this.maxSession = const Duration(hours: 14),
    this.interruptMergeGap = const Duration(minutes: 18),
    this.sleepWindowStartHour = 20,
    this.sleepWindowEndHour = 12,
    this.napStillDuration = const Duration(minutes: 40),
  });

  final double stillVarianceThreshold;
  final double activeVarianceThreshold;
  final Duration onsetStillDuration;
  final Duration wakeActiveDuration;
  final Duration minNightSession;
  final Duration minNapSession;
  final Duration maxSession;
  final Duration interruptMergeGap;
  final int sleepWindowStartHour;
  final int sleepWindowEndHour;
  final Duration napStillDuration;

  bool inSleepWindow(DateTime local) {
    final h = local.hour;
    if (sleepWindowStartHour <= sleepWindowEndHour) {
      return h >= sleepWindowStartHour && h < sleepWindowEndHour;
    }
    // Crosses midnight, e.g. 20 → 12.
    return h >= sleepWindowStartHour || h < sleepWindowEndHour;
  }
}

sealed class SleepDetectionEvent {
  const SleepDetectionEvent();
}

class SleepOnsetDetected extends SleepDetectionEvent {
  const SleepOnsetDetected({
    required this.onsetAt,
    required this.confidence,
  });

  final DateTime onsetAt;
  final ConfidenceLevel confidence;
}

class SleepWakeDetected extends SleepDetectionEvent {
  const SleepWakeDetected({
    required this.onsetAt,
    required this.wakeAt,
    required this.confidence,
  });

  final DateTime onsetAt;
  final DateTime wakeAt;
  final ConfidenceLevel confidence;
}

enum SleepDetectorPhase {
  awake,
  settling,
  asleep,
}

/// Pure sensor-fusion state machine (ADR-035).
///
/// Mimics phone-based trackers (Samsung Health phone mode): prolonged
/// stillness + screen off (+ charging boost) during the night window → sleep
/// onset; sustained motion or screen use → wake. Short interruptions are
/// merged into the same session.
class SleepDetectionEngine {
  SleepDetectionEngine({
    SleepDetectionConfig config = const SleepDetectionConfig(),
    SleepDetectorPhase phase = SleepDetectorPhase.awake,
    DateTime? stillSince,
    DateTime? activeSince,
    DateTime? asleepSince,
  })  : config = config,
        phase = phase,
        stillSince = stillSince,
        activeSince = activeSince,
        asleepSince = asleepSince;

  final SleepDetectionConfig config;

  SleepDetectorPhase phase;
  DateTime? stillSince;
  DateTime? activeSince;
  DateTime? asleepSince;

  /// Last closed session end — used to merge brief wake gaps.
  DateTime? lastClosedEndedAt;
  DateTime? lastClosedStartedAt;
  ConfidenceLevel? lastClosedConfidence;

  Map<String, Object?> toJson() => {
        'phase': phase.name,
        'still_since': stillSince?.toUtc().toIso8601String(),
        'active_since': activeSince?.toUtc().toIso8601String(),
        'asleep_since': asleepSince?.toUtc().toIso8601String(),
        'last_closed_ended_at': lastClosedEndedAt?.toUtc().toIso8601String(),
        'last_closed_started_at':
            lastClosedStartedAt?.toUtc().toIso8601String(),
        'last_closed_confidence': lastClosedConfidence?.name,
      };

  factory SleepDetectionEngine.fromJson(
    Map<String, dynamic> json, {
    SleepDetectionConfig config = const SleepDetectionConfig(),
  }) {
    DateTime? parse(String key) {
      final v = json[key];
      if (v is! String || v.isEmpty) return null;
      return DateTime.parse(v).toUtc();
    }

    final engine = SleepDetectionEngine(
      config: config,
      phase: SleepDetectorPhase.values.byName(
        json['phase'] as String? ?? 'awake',
      ),
      stillSince: parse('still_since'),
      activeSince: parse('active_since'),
      asleepSince: parse('asleep_since'),
    );
    engine.lastClosedEndedAt = parse('last_closed_ended_at');
    engine.lastClosedStartedAt = parse('last_closed_started_at');
    final conf = json['last_closed_confidence'] as String?;
    if (conf != null) {
      engine.lastClosedConfidence = ConfidenceLevel.values.byName(conf);
    }
    return engine;
  }

  SleepDetectionEvent? ingest(SleepSignalSample sample) {
    final at = sample.at.toUtc();
    final local = sample.at.toLocal();
    final still = _isStill(sample);
    final active = _isActive(sample);

    if (still) {
      stillSince ??= at;
      activeSince = null;
    } else if (active) {
      activeSince ??= at;
      stillSince = null;
    } else {
      // Ambiguous motion — freeze timers (don't accumulate either side).
      return null;
    }

    switch (phase) {
      case SleepDetectorPhase.awake:
        return _handleAwake(at: at, local: local, sample: sample, still: still);
      case SleepDetectorPhase.settling:
        return _handleSettling(
          at: at,
          local: local,
          sample: sample,
          still: still,
          active: active,
        );
      case SleepDetectorPhase.asleep:
        return _handleAsleep(at: at, sample: sample, still: still, active: active);
    }
  }

  bool _isStill(SleepSignalSample sample) {
    if (sample.screenOn) return false;
    return sample.motionVariance <= config.stillVarianceThreshold;
  }

  bool _isActive(SleepSignalSample sample) {
    if (sample.screenOn) return true;
    return sample.motionVariance >= config.activeVarianceThreshold;
  }

  Duration _requiredStill(DateTime local) {
    return config.inSleepWindow(local)
        ? config.onsetStillDuration
        : config.napStillDuration;
  }

  ConfidenceLevel _confidence({
    required SleepSignalSample sample,
    required DateTime local,
    required Duration length,
  }) {
    var score = 0;
    if (config.inSleepWindow(local)) score += 2;
    if (sample.isCharging) score += 1;
    if (length >= config.minNightSession) score += 1;
    if (sample.motionVariance <= config.stillVarianceThreshold * 0.5) {
      score += 1;
    }
    if (score >= 4) return ConfidenceLevel.high;
    if (score >= 2) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  SleepDetectionEvent? _handleAwake({
    required DateTime at,
    required DateTime local,
    required SleepSignalSample sample,
    required bool still,
  }) {
    if (!still) return null;
    stillSince ??= at;

    // Resume previous session if wake gap was short (Samsung-like continuity).
    final lastEnd = lastClosedEndedAt;
    final lastStart = lastClosedStartedAt;
    if (lastEnd != null &&
        lastStart != null &&
        at.difference(lastEnd) <= config.interruptMergeGap &&
        at.difference(stillSince!) >= _requiredStill(local)) {
      phase = SleepDetectorPhase.asleep;
      asleepSince = lastStart;
      lastClosedEndedAt = null;
      lastClosedStartedAt = null;
      return SleepOnsetDetected(
        onsetAt: lastStart,
        confidence: lastClosedConfidence ?? ConfidenceLevel.medium,
      );
    }

    // Enter settling as soon as the phone is still (confirm after duration).
    phase = SleepDetectorPhase.settling;
    return null;
  }

  SleepDetectionEvent? _handleSettling({
    required DateTime at,
    required DateTime local,
    required SleepSignalSample sample,
    required bool still,
    required bool active,
  }) {
    if (active) {
      phase = SleepDetectorPhase.awake;
      stillSince = null;
      return null;
    }
    if (!still) return null;
    final since = stillSince;
    if (since == null) return null;
    final needed = _requiredStill(local);
    if (at.difference(since) < needed) return null;

    final onset = since;
    phase = SleepDetectorPhase.asleep;
    asleepSince = onset;
    final confidence = _confidence(
      sample: sample,
      local: local,
      length: at.difference(onset),
    );
    return SleepOnsetDetected(onsetAt: onset, confidence: confidence);
  }

  SleepDetectionEvent? _handleAsleep({
    required DateTime at,
    required SleepSignalSample sample,
    required bool still,
    required bool active,
  }) {
    final onset = asleepSince;
    if (onset == null) {
      phase = SleepDetectorPhase.awake;
      return null;
    }

    // Cap runaway sessions (forgot phone on bed).
    if (at.difference(onset) > config.maxSession) {
      return _close(
        onset: onset,
        wakeAt: onset.add(config.maxSession),
        sample: sample,
        forceLow: true,
      );
    }

    if (!active) {
      if (still) activeSince = null;
      return null;
    }

    final activeFrom = activeSince ?? at;
    if (at.difference(activeFrom) < config.wakeActiveDuration) {
      return null;
    }

    final length = activeFrom.difference(onset);
    final minLen = config.inSleepWindow(onset.toLocal())
        ? config.minNightSession
        : config.minNapSession;
    if (length < minLen) {
      // False start — discard.
      phase = SleepDetectorPhase.awake;
      asleepSince = null;
      stillSince = null;
      activeSince = null;
      return null;
    }

    return _close(onset: onset, wakeAt: activeFrom, sample: sample);
  }

  SleepWakeDetected _close({
    required DateTime onset,
    required DateTime wakeAt,
    required SleepSignalSample sample,
    bool forceLow = false,
  }) {
    final confidence = forceLow
        ? ConfidenceLevel.low
        : _confidence(
            sample: sample,
            local: onset.toLocal(),
            length: wakeAt.difference(onset),
          );
    lastClosedStartedAt = onset;
    lastClosedEndedAt = wakeAt;
    lastClosedConfidence = confidence;
    phase = SleepDetectorPhase.awake;
    asleepSince = null;
    stillSince = null;
    activeSince = null;
    return SleepWakeDetected(
      onsetAt: onset,
      wakeAt: wakeAt,
      confidence: confidence,
    );
  }
}

/// Prefer Health Connect over overlapping on-device detections (ADR-035).
class SleepSessionMergePolicy {
  const SleepSessionMergePolicy();

  /// Returns true when [candidate] should be skipped because an existing
  /// higher-priority session already covers the same night.
  bool isSupersededByExisting({
    required SleepSession candidate,
    required List<SleepSession> existing,
  }) {
    final cEnd = candidate.endedAt;
    if (cEnd == null) return false;
    for (final other in existing) {
      final oEnd = other.endedAt;
      if (oEnd == null) continue;
      if (!_overlaps(
        candidate.startedAt,
        cEnd,
        other.startedAt,
        oEnd,
      )) {
        continue;
      }
      if (_priority(other.source) > _priority(candidate.source)) {
        return true;
      }
      if (_priority(other.source) == _priority(candidate.source) &&
          _overlapRatio(candidate.startedAt, cEnd, other.startedAt, oEnd) >=
              0.5) {
        return true;
      }
    }
    return false;
  }

  int _priority(SleepSessionSource source) => switch (source) {
        SleepSessionSource.healthConnect => 3,
        SleepSessionSource.manual => 2,
        SleepSessionSource.detected => 1,
      };

  bool _overlaps(DateTime a0, DateTime a1, DateTime b0, DateTime b1) {
    return a0.isBefore(b1) && b0.isBefore(a1);
  }

  double _overlapRatio(DateTime a0, DateTime a1, DateTime b0, DateTime b1) {
    final start = a0.isAfter(b0) ? a0 : b0;
    final end = a1.isBefore(b1) ? a1 : b1;
    if (!end.isAfter(start)) return 0;
    final overlap = end.difference(start).inSeconds;
    final shorter = a1.difference(a0).inSeconds < b1.difference(b0).inSeconds
        ? a1.difference(a0).inSeconds
        : b1.difference(b0).inSeconds;
    if (shorter <= 0) return 0;
    return overlap / shorter;
  }
}
