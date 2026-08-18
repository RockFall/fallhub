import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 12);
  final profile = EntityId('p1');
  final deck = EntityId('d1');

  Flashcard card(String id) {
    return Flashcard.create(
      id: EntityId(id),
      profileId: profile,
      deckId: deck,
      front: 'Q $id',
      back: 'A $id',
      createdAt: now,
    );
  }

  FlashcardReviewLog log({
    required String id,
    required EntityId cardId,
    required DateTime at,
    int durationMs = 8000,
    FlashcardRating rating = FlashcardRating.good,
    double intervalBefore = 0,
    FlashcardReviewKind kind = FlashcardReviewKind.srs,
  }) {
    return FlashcardReviewLog(
      id: EntityId(id),
      cardId: cardId,
      reviewedAt: at,
      rating: rating,
      intervalDaysBefore: intervalBefore,
      intervalDaysAfter: intervalBefore,
      easeBefore: 2.5,
      easeAfter: 2.5,
      durationMs: durationMs,
      reviewKind: kind,
    );
  }

  test('metrics capture duration, daily pace and remaining reviews', () {
    final unseen = card('n');
    final learning = card('l');
    final reviewed = card('r');
    final srs = {
      unseen.id: FlashcardSrsState.fresh(cardId: unseen.id, createdAt: now),
      learning.id: FlashcardSrsState(
        cardId: learning.id,
        status: FlashcardSrsStatus.learning,
        easeFactor: 2.5,
        intervalDays: 0,
        repetitions: 0,
        lapses: 1,
        learningStepIndex: 1,
        leech: false,
        dueAt: now,
        lastReviewedAt: now.subtract(const Duration(hours: 1)),
      ),
      reviewed.id: FlashcardSrsState(
        cardId: reviewed.id,
        status: FlashcardSrsStatus.review,
        easeFactor: 2.5,
        intervalDays: 4,
        repetitions: 3,
        lapses: 0,
        learningStepIndex: 0,
        leech: false,
        dueAt: now.add(const Duration(days: 2)),
        lastReviewedAt: now.subtract(const Duration(days: 1)),
      ),
    };
    final logs = [
      log(
        id: 'today',
        cardId: reviewed.id,
        at: now,
        durationMs: 10000,
      ),
      log(
        id: 'yesterday',
        cardId: learning.id,
        at: now.subtract(const Duration(days: 1)),
        durationMs: 6000,
        intervalBefore: 0,
      ),
      log(
        id: 'practice',
        cardId: reviewed.id,
        at: now,
        durationMs: 2000,
        kind: FlashcardReviewKind.practice,
      ),
    ];

    final metrics = FlashcardPacePolicy.metrics(
      cards: [unseen, learning, reviewed],
      srsByCard: srs,
      logs: logs,
      now: now,
    );

    expect(metrics.meanDurationMs, 8000);
    expect(metrics.meanCardsPerActiveDay, 1);
    expect(metrics.remainingNew, 1);
    expect(metrics.remainingToGraduate, 2);
    expect(metrics.reviewsRemaining, 3);
    expect(metrics.meanRepetitions, 1.5);
    expect(metrics.meanLapses, 0.5);
    expect(metrics.reviewsPerCard, 1);
    expect(metrics.cardsPerDayLast7.last, 1);
  });

  test('forecast days and inverse recommendation', () {
    final metrics = FlashcardPaceMetrics(
      windowDays: 14,
      durationSampleCount: 2,
      meanDurationMs: 8000,
      meanCardsPerActiveDay: 10,
      meanReviewsPerActiveDay: 12,
      cardsPerDayLast7: const [0, 0, 0, 0, 0, 0, 10],
      reviewsPerDayLast7: const [0, 0, 0, 0, 0, 0, 12],
      remainingNew: 20,
      remainingToGraduate: 20,
      reviewsRemaining: 40,
      scheduledCount: 20,
      meanRepetitions: 0,
      meanLapses: 0,
      reviewsPerCard: 0,
      againRate: 0,
      distinctCardsReviewed: 0,
      srsReviewCount: 0,
      typicalNewReviews: 2,
    );

    final forecast = FlashcardPacePolicy.forecast(
      metrics: metrics,
      cardsPerDay: 10,
      now: now,
      logs: const [],
    );
    expect(forecast.days, 4);
    expect(
      forecast.finishOn,
      FlashcardPacePolicy.localDay(now).add(const Duration(days: 4)),
    );
    expect(
      FlashcardPacePolicy.recommendCardsPerDay(
        reviewsRemaining: 40,
        targetDays: 8,
      ),
      5,
    );
    expect(
      FlashcardPacePolicy.forecast(
        metrics: metrics,
        cardsPerDay: 0,
        now: now,
      ).days,
      isNull,
    );
  });

  test('session minutes uses observed mean duration', () {
    expect(
      FlashcardPacePolicy.estimatedSessionMinutes(cardCount: 0, logs: const []),
      0,
    );
    expect(
      FlashcardPacePolicy.estimatedSessionMinutes(cardCount: 1, logs: const []),
      1,
    );
    final logs = [
      log(id: 'a', cardId: EntityId('c'), at: now, durationMs: 60000),
      log(id: 'b', cardId: EntityId('c'), at: now, durationMs: 60000),
    ];
    expect(
      FlashcardPacePolicy.estimatedSessionMinutes(cardCount: 2, logs: logs),
      2,
    );
  });
}
