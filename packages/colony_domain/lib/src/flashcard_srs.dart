import 'flashcard.dart';

class Sm2Config {
  const Sm2Config({
    this.learningSteps = const [
      Duration(minutes: 1),
      Duration(minutes: 10),
    ],
    this.graduatingInterval = const Duration(days: 1),
    this.easyInterval = const Duration(days: 4),
    this.startingEase = 2.5,
    this.minimumEase = 1.3,
    this.easyBonus = 1.3,
    this.hardMultiplier = 1.2,
    this.againEaseDelta = -0.20,
    this.hardEaseDelta = -0.15,
    this.easyEaseDelta = 0.15,
    this.leechLapses = 8,
  });

  final List<Duration> learningSteps;
  final Duration graduatingInterval;
  final Duration easyInterval;
  final double startingEase;
  final double minimumEase;
  final double easyBonus;
  final double hardMultiplier;
  final double againEaseDelta;
  final double hardEaseDelta;
  final double easyEaseDelta;
  final int leechLapses;
}

class Sm2Result {
  const Sm2Result({
    required this.state,
    required this.becameLeech,
  });

  final FlashcardSrsState state;
  final bool becameLeech;
}

/// Anki-like SM-2 with learning steps. Pure and deterministic.
abstract final class Sm2Scheduler {
  static const defaultConfig = Sm2Config();

  static Map<FlashcardRating, Duration> previewIntervals({
    required FlashcardSrsState state,
    required DateTime now,
    Sm2Config config = defaultConfig,
  }) {
    return {
      for (final rating in FlashcardRating.values)
        rating: apply(
          state: state,
          rating: rating,
          now: now,
          config: config,
        ).state.dueAt.difference(now),
    };
  }

  static Sm2Result apply({
    required FlashcardSrsState state,
    required FlashcardRating rating,
    required DateTime now,
    Sm2Config config = defaultConfig,
  }) {
    final inLearning = state.status == FlashcardSrsStatus.newCard ||
        state.status == FlashcardSrsStatus.learning ||
        state.status == FlashcardSrsStatus.relearning;

    if (inLearning) {
      return _applyLearning(
        state: state,
        rating: rating,
        now: now,
        config: config,
      );
    }
    return _applyReview(
      state: state,
      rating: rating,
      now: now,
      config: config,
    );
  }

  static Sm2Result _applyLearning({
    required FlashcardSrsState state,
    required FlashcardRating rating,
    required DateTime now,
    required Sm2Config config,
  }) {
    switch (rating) {
      case FlashcardRating.again:
        return Sm2Result(
          state: state.copyWith(
            status: state.status == FlashcardSrsStatus.relearning
                ? FlashcardSrsStatus.relearning
                : FlashcardSrsStatus.learning,
            learningStepIndex: 0,
            dueAt: now.add(config.learningSteps.first),
            intervalDays: _days(config.learningSteps.first),
            lastReviewedAt: now,
          ),
          becameLeech: false,
        );
      case FlashcardRating.hard:
        final step = config.learningSteps[
            state.learningStepIndex.clamp(0, config.learningSteps.length - 1)];
        return Sm2Result(
          state: state.copyWith(
            status: FlashcardSrsStatus.learning,
            dueAt: now.add(step),
            intervalDays: _days(step),
            lastReviewedAt: now,
          ),
          becameLeech: false,
        );
      case FlashcardRating.good:
        final next = state.learningStepIndex + 1;
        if (next >= config.learningSteps.length) {
          return _graduate(
            state: state,
            now: now,
            interval: config.graduatingInterval,
            ease: state.easeFactor,
            config: config,
          );
        }
        final step = config.learningSteps[next];
        return Sm2Result(
          state: state.copyWith(
            status: FlashcardSrsStatus.learning,
            learningStepIndex: next,
            dueAt: now.add(step),
            intervalDays: _days(step),
            lastReviewedAt: now,
          ),
          becameLeech: false,
        );
      case FlashcardRating.easy:
        return _graduate(
          state: state,
          now: now,
          interval: config.easyInterval,
          ease: _clampEase(state.easeFactor + config.easyEaseDelta, config),
          config: config,
        );
    }
  }

  static Sm2Result _applyReview({
    required FlashcardSrsState state,
    required FlashcardRating rating,
    required DateTime now,
    required Sm2Config config,
  }) {
    switch (rating) {
      case FlashcardRating.again:
        final lapses = state.lapses + 1;
        final leech = lapses >= config.leechLapses;
        return Sm2Result(
          state: state.copyWith(
            status: FlashcardSrsStatus.relearning,
            easeFactor: _clampEase(
              state.easeFactor + config.againEaseDelta,
              config,
            ),
            intervalDays: _days(config.learningSteps.first),
            repetitions: 0,
            lapses: lapses,
            learningStepIndex: 0,
            leech: leech || state.leech,
            dueAt: now.add(config.learningSteps.first),
            lastReviewedAt: now,
          ),
          becameLeech: leech && !state.leech,
        );
      case FlashcardRating.hard:
        final interval = Duration(
          milliseconds: (state.intervalDays *
                  config.hardMultiplier *
                  Duration.millisecondsPerDay)
              .round()
              .clamp(Duration.millisecondsPerDay, 3650 * Duration.millisecondsPerDay),
        );
        return Sm2Result(
          state: state.copyWith(
            easeFactor: _clampEase(
              state.easeFactor + config.hardEaseDelta,
              config,
            ),
            intervalDays: _days(interval),
            repetitions: state.repetitions + 1,
            dueAt: now.add(interval),
            lastReviewedAt: now,
          ),
          becameLeech: false,
        );
      case FlashcardRating.good:
        final days = (state.intervalDays <= 0 ? 1.0 : state.intervalDays) *
            state.easeFactor;
        final interval = _daysToDuration(days);
        return Sm2Result(
          state: state.copyWith(
            intervalDays: _days(interval),
            repetitions: state.repetitions + 1,
            dueAt: now.add(interval),
            lastReviewedAt: now,
          ),
          becameLeech: false,
        );
      case FlashcardRating.easy:
        final days = (state.intervalDays <= 0 ? 1.0 : state.intervalDays) *
            state.easeFactor *
            config.easyBonus;
        final interval = _daysToDuration(days);
        return Sm2Result(
          state: state.copyWith(
            easeFactor: _clampEase(
              state.easeFactor + config.easyEaseDelta,
              config,
            ),
            intervalDays: _days(interval),
            repetitions: state.repetitions + 1,
            dueAt: now.add(interval),
            lastReviewedAt: now,
          ),
          becameLeech: false,
        );
    }
  }

  static Sm2Result _graduate({
    required FlashcardSrsState state,
    required DateTime now,
    required Duration interval,
    required double ease,
    required Sm2Config config,
  }) {
    return Sm2Result(
      state: state.copyWith(
        status: FlashcardSrsStatus.review,
        easeFactor: _clampEase(ease, config),
        intervalDays: _days(interval),
        repetitions: state.repetitions + 1,
        learningStepIndex: 0,
        dueAt: now.add(interval),
        lastReviewedAt: now,
      ),
      becameLeech: false,
    );
  }

  static double _clampEase(double ease, Sm2Config config) =>
      ease < config.minimumEase ? config.minimumEase : ease;

  static double _days(Duration duration) =>
      duration.inMilliseconds / Duration.millisecondsPerDay;

  static Duration _daysToDuration(double days) {
    final ms = (days * Duration.millisecondsPerDay)
        .round()
        .clamp(Duration.millisecondsPerDay, 3650 * Duration.millisecondsPerDay);
    return Duration(milliseconds: ms);
  }

  static String formatInterval(Duration duration) {
    if (duration.inMinutes < 1) return '<1 min';
    if (duration.inMinutes < 60) return '${duration.inMinutes} min';
    if (duration.inHours < 24) return '${duration.inHours} h';
    final days = duration.inDays;
    if (days < 30) return '$days d';
    if (days < 365) return '${(days / 30).round()} mês';
    return '${(days / 365).toStringAsFixed(1)} a';
  }
}
