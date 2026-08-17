import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 12);
  final cardId = EntityId('card-1');

  FlashcardSrsState fresh() =>
      FlashcardSrsState.fresh(cardId: cardId, createdAt: now);

  test('new + again stays in learning at first step', () {
    final result = Sm2Scheduler.apply(
      state: fresh(),
      rating: FlashcardRating.again,
      now: now,
    );
    expect(result.state.status, FlashcardSrsStatus.learning);
    expect(result.state.learningStepIndex, 0);
    expect(result.state.dueAt, now.add(const Duration(minutes: 1)));
  });

  test('new + good advances to second learning step', () {
    final result = Sm2Scheduler.apply(
      state: fresh(),
      rating: FlashcardRating.good,
      now: now,
    );
    expect(result.state.status, FlashcardSrsStatus.learning);
    expect(result.state.learningStepIndex, 1);
    expect(result.state.dueAt, now.add(const Duration(minutes: 10)));
  });

  test('second good graduates to 1-day review', () {
    final learning = Sm2Scheduler.apply(
      state: fresh(),
      rating: FlashcardRating.good,
      now: now,
    ).state;
    final graduated = Sm2Scheduler.apply(
      state: learning,
      rating: FlashcardRating.good,
      now: now.add(const Duration(minutes: 10)),
    ).state;
    expect(graduated.status, FlashcardSrsStatus.review);
    expect(graduated.intervalDays, 1);
    expect(
      graduated.dueAt,
      now.add(const Duration(minutes: 10, days: 1)),
    );
  });

  test('easy from new graduates with 4-day interval and higher ease', () {
    final result = Sm2Scheduler.apply(
      state: fresh(),
      rating: FlashcardRating.easy,
      now: now,
    );
    expect(result.state.status, FlashcardSrsStatus.review);
    expect(result.state.intervalDays, 4);
    expect(result.state.easeFactor, closeTo(2.65, 0.001));
  });

  test('review again drops to relearning and can become leech', () {
    var state = FlashcardSrsState(
      cardId: cardId,
      status: FlashcardSrsStatus.review,
      easeFactor: 2.5,
      intervalDays: 10,
      repetitions: 4,
      lapses: 7,
      learningStepIndex: 0,
      leech: false,
      dueAt: now,
    );
    final result = Sm2Scheduler.apply(
      state: state,
      rating: FlashcardRating.again,
      now: now,
    );
    expect(result.state.status, FlashcardSrsStatus.relearning);
    expect(result.state.lapses, 8);
    expect(result.state.leech, isTrue);
    expect(result.becameLeech, isTrue);
    expect(result.state.easeFactor, closeTo(2.3, 0.001));
  });

  test('review good multiplies interval by ease', () {
    final state = FlashcardSrsState(
      cardId: cardId,
      status: FlashcardSrsStatus.review,
      easeFactor: 2.5,
      intervalDays: 2,
      repetitions: 1,
      lapses: 0,
      learningStepIndex: 0,
      leech: false,
      dueAt: now,
    );
    final next = Sm2Scheduler.apply(
      state: state,
      rating: FlashcardRating.good,
      now: now,
    ).state;
    expect(next.intervalDays, closeTo(5, 0.01));
    expect(next.repetitions, 2);
  });

  test('preview intervals expose all four ratings', () {
    final preview = Sm2Scheduler.previewIntervals(state: fresh(), now: now);
    expect(preview.keys, FlashcardRating.values);
    expect(preview[FlashcardRating.again]!.inMinutes, 1);
    expect(preview[FlashcardRating.good]!.inMinutes, 10);
  });

  test('formatInterval uses compact labels', () {
    expect(Sm2Scheduler.formatInterval(const Duration(minutes: 10)), '10 min');
    expect(Sm2Scheduler.formatInterval(const Duration(days: 3)), '3 d');
  });
}
