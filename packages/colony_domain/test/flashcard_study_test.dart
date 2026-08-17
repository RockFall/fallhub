import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 12);
  final profile = EntityId('p1');
  final deck = EntityId('d1');

  Flashcard card(String id, {EntityId? area, bool suspended = false}) {
    return Flashcard.create(
      id: EntityId(id),
      profileId: profile,
      deckId: deck,
      areaId: area,
      front: 'Q $id',
      back: 'A $id',
      createdAt: now,
      suspended: suspended,
    );
  }

  test('cloze prompt hides only the selected deletion', () {
    const source = 'A capital de {{c1::França}} é {{c2::Paris}}';
    expect(ClozeRenderer.indicesIn(source), {1, 2});
    expect(ClozeRenderer.prompt(source, 1), 'A capital de […] é Paris');
    expect(ClozeRenderer.answer(source), 'A capital de França é Paris');
  });

  test('queue prefers learning, then due reviews, then new with limits', () {
    final learning = card('l');
    final review = card('r');
    final newer = card('n');
    final suspended = card('s', suspended: true);
    final srs = {
      learning.id: FlashcardSrsState(
        cardId: learning.id,
        status: FlashcardSrsStatus.learning,
        easeFactor: 2.5,
        intervalDays: 0,
        repetitions: 0,
        lapses: 0,
        learningStepIndex: 0,
        leech: false,
        dueAt: now.subtract(const Duration(minutes: 1)),
      ),
      review.id: FlashcardSrsState(
        cardId: review.id,
        status: FlashcardSrsStatus.review,
        easeFactor: 2.5,
        intervalDays: 1,
        repetitions: 1,
        lapses: 0,
        learningStepIndex: 0,
        leech: false,
        dueAt: now.subtract(const Duration(hours: 1)),
      ),
      newer.id: FlashcardSrsState.fresh(cardId: newer.id, createdAt: now),
      suspended.id: FlashcardSrsState.fresh(
        cardId: suspended.id,
        createdAt: now,
      ),
    };

    final queue = StudyQueuePolicy.buildQueue(
      cards: [newer, review, learning, suspended],
      srsByCard: srs,
      now: now,
      newRemaining: 1,
      reviewRemaining: 1,
      interleaveByArea: false,
    );

    expect(queue.map((c) => c.card.id.value), ['l', 'r', 'n']);
  });

  test('interleave alternates areas', () {
    final a = EntityId('area-a');
    final b = EntityId('area-b');
    final cards = [
      card('a1', area: a),
      card('a2', area: a),
      card('b1', area: b),
    ];
    final srs = {
      for (final c in cards)
        c.id: FlashcardSrsState.fresh(cardId: c.id, createdAt: now),
    };
    final queue = StudyQueuePolicy.buildQueue(
      cards: cards,
      srsByCard: srs,
      now: now,
      newRemaining: 10,
      reviewRemaining: 10,
    );
    expect(queue.map((c) => c.card.id.value).toList(), ['a1', 'b1', 'a2']);
  });

  test('retention ignores empty window and counts good/easy', () {
    expect(StudyQueuePolicy.retention(const []), isNull);
    final logs = [
      FlashcardReviewLog(
        id: EntityId('1'),
        cardId: EntityId('c'),
        reviewedAt: now,
        rating: FlashcardRating.good,
        intervalDaysBefore: 1,
        intervalDaysAfter: 2,
        easeBefore: 2.5,
        easeAfter: 2.5,
      ),
      FlashcardReviewLog(
        id: EntityId('2'),
        cardId: EntityId('c'),
        reviewedAt: now,
        rating: FlashcardRating.again,
        intervalDaysBefore: 1,
        intervalDaysAfter: 0,
        easeBefore: 2.5,
        easeAfter: 2.3,
      ),
    ];
    expect(StudyQueuePolicy.retention(logs), 0.5);
  });

  test('knowledge forest sorts and nests children', () {
    final root = KnowledgeArea.create(
      id: EntityId('lang'),
      profileId: profile,
      title: 'Linguagens',
      createdAt: now,
      sortOrder: 0,
    );
    final child = KnowledgeArea.create(
      id: EntityId('en'),
      profileId: profile,
      parentId: root.id,
      title: 'Inglês',
      createdAt: now,
    );
    final forest = KnowledgeAreaPolicy.buildForest([child, root]);
    expect(forest, hasLength(1));
    expect(forest.single.area.id, root.id);
    expect(forest.single.children.single.area.id, child.id);
    expect(forest.single.descendantCount, 1);
    expect(
      KnowledgeAreaPolicy.pathLabel(areaId: child.id, areas: [child, root]),
      'Linguagens · Inglês',
    );
  });

  test('catalog has unique keys and suggested domains', () {
    final keys = KnowledgeAreaCatalog.flattenKeys();
    expect(keys.toSet().length, keys.length);
    expect(keys, contains('computing.flutter'));
    expect(KnowledgeAreaCatalog.byKey('arts.piano')?.title, 'Piano');
  });

  test('flashcard policy rejects empty front and cloze without tokens', () {
    expect(
      () => FlashcardPolicy.validateCard(
        card('x').copyWith(front: '   '),
      ),
      throwsA(isA<FlashcardValidationException>()),
    );
    expect(
      () => FlashcardPolicy.validateCard(
        card('y').copyWith(kind: FlashcardKind.cloze, front: 'sem token'),
      ),
      throwsA(isA<FlashcardValidationException>()),
    );
  });
}
