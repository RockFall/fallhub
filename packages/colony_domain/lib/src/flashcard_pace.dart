import 'package:equatable/equatable.dart';

import 'flashcard.dart';
import 'flashcard_srs.dart';
import 'id_generator.dart';

class FlashcardPaceMetrics extends Equatable {
  const FlashcardPaceMetrics({
    required this.windowDays,
    required this.durationSampleCount,
    this.meanDurationMs,
    required this.meanCardsPerActiveDay,
    required this.meanReviewsPerActiveDay,
    required this.cardsPerDayLast7,
    required this.reviewsPerDayLast7,
    required this.remainingNew,
    required this.remainingToGraduate,
    required this.reviewsRemaining,
    required this.scheduledCount,
    required this.meanRepetitions,
    required this.meanLapses,
    required this.reviewsPerCard,
    required this.againRate,
    required this.distinctCardsReviewed,
    required this.srsReviewCount,
    required this.typicalNewReviews,
  });

  final int windowDays;
  final int durationSampleCount;
  final int? meanDurationMs;
  final double meanCardsPerActiveDay;
  final double meanReviewsPerActiveDay;
  final List<int> cardsPerDayLast7;
  final List<int> reviewsPerDayLast7;
  final int remainingNew;
  final int remainingToGraduate;
  final int reviewsRemaining;
  final int scheduledCount;
  final double meanRepetitions;
  final double meanLapses;
  final double reviewsPerCard;
  final double againRate;
  final int distinctCardsReviewed;
  final int srsReviewCount;
  final int typicalNewReviews;

  bool get hasDurationSample => durationSampleCount > 0;
  bool get hasPaceSample => meanCardsPerActiveDay > 0;

  int get suggestedCardsPerDay {
    if (meanCardsPerActiveDay <= 0) return 0;
    return meanCardsPerActiveDay.round().clamp(1, 999);
  }

  @override
  List<Object?> get props => [
        windowDays,
        durationSampleCount,
        meanDurationMs,
        meanCardsPerActiveDay,
        meanReviewsPerActiveDay,
        cardsPerDayLast7,
        reviewsPerDayLast7,
        remainingNew,
        remainingToGraduate,
        reviewsRemaining,
        scheduledCount,
        meanRepetitions,
        meanLapses,
        reviewsPerCard,
        againRate,
        distinctCardsReviewed,
        srsReviewCount,
        typicalNewReviews,
      ];
}

class FlashcardFinishForecast extends Equatable {
  const FlashcardFinishForecast({
    required this.cardsPerDay,
    required this.reviewsRemaining,
    required this.remainingToGraduate,
    this.days,
    this.finishOn,
    required this.estimatedMinutesPerDay,
  });

  final int cardsPerDay;
  final int reviewsRemaining;
  final int remainingToGraduate;
  final int? days;
  final DateTime? finishOn;
  final int estimatedMinutesPerDay;

  @override
  List<Object?> get props => [
        cardsPerDay,
        reviewsRemaining,
        remainingToGraduate,
        days,
        finishOn,
        estimatedMinutesPerDay,
      ];
}

abstract final class FlashcardPacePolicy {
  static const windowDays = 14;
  static const minDurationMs = 400;
  static const maxDurationMs = 5 * 60 * 1000;
  static const fallbackDurationMs = 30 * 1000;

  static DateTime localDay(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool sameLocalDay(DateTime a, DateTime b) =>
      localDay(a) == localDay(b);

  static int? meanDurationMs(Iterable<FlashcardReviewLog> logs) {
    final samples = [
      for (final log in logs)
        if (log.reviewKind == FlashcardReviewKind.srs &&
            log.durationMs != null &&
            log.durationMs! >= minDurationMs &&
            log.durationMs! <= maxDurationMs)
          log.durationMs!,
    ];
    if (samples.isEmpty) return null;
    return samples.reduce((a, b) => a + b) ~/ samples.length;
  }

  static int estimatedSessionMinutes({
    required int cardCount,
    required Iterable<FlashcardReviewLog> logs,
  }) {
    if (cardCount < 1) return 0;
    final mean = meanDurationMs(logs) ?? fallbackDurationMs;
    return ((cardCount * mean) / 60000).ceil().clamp(1, 180);
  }

  static String formatDurationMs(int ms) {
    final seconds = (ms / 1000).round();
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    if (rest == 0) return '$minutes min';
    return '$minutes min ${rest}s';
  }

  static int reviewsToGraduate({
    required FlashcardSrsState srs,
    Sm2Config config = const Sm2Config(),
    int typicalNewReviews = 2,
  }) {
    switch (srs.status) {
      case FlashcardSrsStatus.newCard:
        return typicalNewReviews.clamp(1, 12);
      case FlashcardSrsStatus.learning:
        return (config.learningSteps.length - srs.learningStepIndex)
            .clamp(1, 12);
      case FlashcardSrsStatus.relearning:
        return 1;
      case FlashcardSrsStatus.review:
        return 0;
    }
  }

  static FlashcardPaceMetrics metrics({
    required List<Flashcard> cards,
    required Map<EntityId, FlashcardSrsState> srsByCard,
    required List<FlashcardReviewLog> logs,
    required DateTime now,
    Sm2Config config = const Sm2Config(),
    int windowDays = FlashcardPacePolicy.windowDays,
  }) {
    final start = localDay(now).subtract(Duration(days: windowDays - 1));
    final srsLogs = [
      for (final log in logs)
        if (log.reviewKind == FlashcardReviewKind.srs) log,
    ];
    final windowLogs = [
      for (final log in srsLogs)
        if (!localDay(log.reviewedAt).isBefore(start)) log,
    ];

    final durations = [
      for (final log in windowLogs)
        if (log.durationMs != null &&
            log.durationMs! >= minDurationMs &&
            log.durationMs! <= maxDurationMs)
          log.durationMs!,
    ];
    final meanDuration =
        durations.isEmpty ? null : durations.reduce((a, b) => a + b) ~/ durations.length;

    final cardsByDay = <DateTime, Set<EntityId>>{};
    final reviewsByDay = <DateTime, int>{};
    for (final log in windowLogs) {
      final day = localDay(log.reviewedAt);
      cardsByDay.putIfAbsent(day, () => {}).add(log.cardId);
      reviewsByDay[day] = (reviewsByDay[day] ?? 0) + 1;
    }
    final activeCardCounts = [
      for (final set in cardsByDay.values) set.length,
    ];
    final activeReviewCounts = reviewsByDay.values.toList();
    final meanCards = activeCardCounts.isEmpty
        ? 0.0
        : activeCardCounts.reduce((a, b) => a + b) / activeCardCounts.length;
    final meanReviews = activeReviewCounts.isEmpty
        ? 0.0
        : activeReviewCounts.reduce((a, b) => a + b) / activeReviewCounts.length;

    final last7Cards = List<int>.filled(7, 0);
    final last7Reviews = List<int>.filled(7, 0);
    final today = localDay(now);
    for (var i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: 6 - i));
      last7Cards[i] = cardsByDay[day]?.length ?? 0;
      last7Reviews[i] = reviewsByDay[day] ?? 0;
    }

    var remainingNew = 0;
    var remainingToGraduate = 0;
    final reviewed = <FlashcardSrsState>[];
    for (final card in cards) {
      if (card.suspended ||
          card.scheduleMode != FlashcardScheduleMode.scheduled) {
        continue;
      }
      final srs = srsByCard[card.id] ??
          FlashcardSrsState.fresh(cardId: card.id, createdAt: card.createdAt);
      if (srs.status == FlashcardSrsStatus.newCard &&
          srs.lastReviewedAt == null) {
        remainingNew += 1;
      }
      if (srs.status != FlashcardSrsStatus.review) {
        remainingToGraduate += 1;
      }
      if (srs.lastReviewedAt != null) reviewed.add(srs);
    }

    final typicalNew = _typicalNewReviews(
      cards: cards,
      srsByCard: srsByCard,
      logs: srsLogs,
      config: config,
    );
    var reviewsRemaining = 0;
    for (final card in cards) {
      if (card.suspended ||
          card.scheduleMode != FlashcardScheduleMode.scheduled) {
        continue;
      }
      final srs = srsByCard[card.id] ??
          FlashcardSrsState.fresh(cardId: card.id, createdAt: card.createdAt);
      reviewsRemaining += reviewsToGraduate(
        srs: srs,
        config: config,
        typicalNewReviews: typicalNew,
      );
    }

    final meanReps = reviewed.isEmpty
        ? 0.0
        : reviewed.fold<int>(0, (sum, srs) => sum + srs.repetitions) /
            reviewed.length;
    final meanLapses = reviewed.isEmpty
        ? 0.0
        : reviewed.fold<int>(0, (sum, srs) => sum + srs.lapses) /
            reviewed.length;

    final byCard = <EntityId, int>{};
    var again = 0;
    for (final log in srsLogs) {
      byCard[log.cardId] = (byCard[log.cardId] ?? 0) + 1;
      if (log.rating == FlashcardRating.again) again += 1;
    }
    final reviewsPerCard = byCard.isEmpty
        ? 0.0
        : byCard.values.reduce((a, b) => a + b) / byCard.length;
    final againRate = srsLogs.isEmpty ? 0.0 : again / srsLogs.length;

    return FlashcardPaceMetrics(
      windowDays: windowDays,
      durationSampleCount: durations.length,
      meanDurationMs: meanDuration,
      meanCardsPerActiveDay: meanCards,
      meanReviewsPerActiveDay: meanReviews,
      cardsPerDayLast7: last7Cards,
      reviewsPerDayLast7: last7Reviews,
      remainingNew: remainingNew,
      remainingToGraduate: remainingToGraduate,
      reviewsRemaining: reviewsRemaining,
      scheduledCount: cards
          .where(
            (card) =>
                !card.suspended &&
                card.scheduleMode == FlashcardScheduleMode.scheduled,
          )
          .length,
      meanRepetitions: meanReps,
      meanLapses: meanLapses,
      reviewsPerCard: reviewsPerCard,
      againRate: againRate,
      distinctCardsReviewed: byCard.length,
      srsReviewCount: srsLogs.length,
      typicalNewReviews: typicalNew,
    );
  }

  static FlashcardFinishForecast forecast({
    required FlashcardPaceMetrics metrics,
    required int cardsPerDay,
    required DateTime now,
    Iterable<FlashcardReviewLog> logs = const [],
  }) {
    final pace = cardsPerDay < 0 ? 0 : cardsPerDay;
    int? days;
    DateTime? finishOn;
    if (metrics.reviewsRemaining == 0) {
      days = 0;
      finishOn = localDay(now);
    } else if (pace >= 1) {
      days = (metrics.reviewsRemaining / pace).ceil();
      finishOn = localDay(now).add(Duration(days: days));
    }
    return FlashcardFinishForecast(
      cardsPerDay: pace,
      reviewsRemaining: metrics.reviewsRemaining,
      remainingToGraduate: metrics.remainingToGraduate,
      days: days,
      finishOn: finishOn,
      estimatedMinutesPerDay: estimatedSessionMinutes(
        cardCount: pace,
        logs: logs,
      ),
    );
  }

  static int recommendCardsPerDay({
    required int reviewsRemaining,
    required int targetDays,
  }) {
    if (reviewsRemaining <= 0 || targetDays < 1) return 0;
    return (reviewsRemaining / targetDays).ceil();
  }

  static int _typicalNewReviews({
    required List<Flashcard> cards,
    required Map<EntityId, FlashcardSrsState> srsByCard,
    required List<FlashcardReviewLog> logs,
    required Sm2Config config,
  }) {
    final learningByCard = <EntityId, int>{};
    for (final log in logs) {
      if (log.intervalDaysBefore >= 1) continue;
      learningByCard[log.cardId] = (learningByCard[log.cardId] ?? 0) + 1;
    }
    final graduated = <int>[];
    for (final card in cards) {
      final srs = srsByCard[card.id];
      if (srs == null || srs.status != FlashcardSrsStatus.review) continue;
      final count = learningByCard[card.id];
      if (count == null || count < 1) continue;
      graduated.add(count);
    }
    if (graduated.length < 5) return config.learningSteps.length;
    final mean = graduated.reduce((a, b) => a + b) / graduated.length;
    return mean.round().clamp(1, 12);
  }
}
