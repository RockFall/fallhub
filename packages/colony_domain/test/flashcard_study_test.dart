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
    expect(keys, contains('arts.music.tropicalismo'));
    expect(keys, contains('engineering.automotive.autonomous.odd'));
    expect(keys, contains('humanities.history.brazil'));
    expect(KnowledgeAreaCatalog.byKey('arts.piano')?.title, 'Piano');
    expect(
      KnowledgeAreaCatalog.byKey('arts.music.tropicalismo')?.catalogPlacements,
      ['humanities.history.brazil'],
    );
    expect(
      KnowledgeAreaCatalog.expandKeys(['arts.music.tropicalismo']),
      containsAll(['arts.music.tropicalismo', 'humanities.history.brazil']),
    );
  });

  test('unscheduled cards stay out of the due queue', () {
    final scheduled = card('s');
    final saved = card('u').copyWith(
      scheduleMode: FlashcardScheduleMode.unscheduled,
    );
    final srs = {
      scheduled.id: FlashcardSrsState.fresh(
        cardId: scheduled.id,
        createdAt: now,
      ),
      saved.id: FlashcardSrsState.fresh(cardId: saved.id, createdAt: now),
    };
    final queue = StudyQueuePolicy.buildQueue(
      cards: [scheduled, saved],
      srsByCard: srs,
      now: now,
      newRemaining: 10,
      reviewRemaining: 10,
      interleaveByArea: false,
    );
    expect(queue.map((c) => c.card.id.value), ['s']);
    expect(
      StudyQueuePolicy.counts(
        cards: [scheduled, saved],
        srsByCard: srs,
        now: now,
      ).dueTotal,
      1,
    );
  });

  test('practice queue includes scheduled cards and skips suspended', () {
    final scheduled = card('s');
    final saved = card('u').copyWith(
      scheduleMode: FlashcardScheduleMode.unscheduled,
    );
    final frozen = card('x', suspended: true);
    final queue = StudyQueuePolicy.buildPracticeQueue(
      cards: [scheduled, saved, frozen],
      srsByCard: const {},
      limit: 10,
    );
    expect(queue.map((c) => c.card.id.value), ['s', 'u']);
    expect(queue.first.sessionMode, FlashcardStudySessionMode.practice);
  });

  test('heat counts a card whose area lives only on the deck', () {
    final area = KnowledgeArea.create(
      id: EntityId('area'),
      profileId: profile,
      title: 'Folha',
      createdAt: now,
    );
    final deckEntity = FlashcardDeck.create(
      id: deck,
      profileId: profile,
      title: 'Folha',
      createdAt: now,
      areaId: area.id,
    );
    final orphan = card('orphan');
    final heat = StudyQueuePolicy.heatByArea(
      cards: [orphan],
      srsByCard: {
        orphan.id: FlashcardSrsState.fresh(cardId: orphan.id, createdAt: now),
      },
      logs: const [],
      now: now,
      areas: [area],
      decks: [deckEntity],
    );
    expect(heat[area.id]?.cardCount, 1);
    expect(heat[area.id]?.dueCount, 1);
  });

  test('cloze wrapSelection inserts the next index', () {
    expect(
      ClozeRenderer.wrapSelection('A capital de França', 13, 19),
      'A capital de {{c1::França}}',
    );
    expect(
      ClozeRenderer.wrapSelection('A capital de {{c1::França}} é Paris', 30, 35),
      'A capital de {{c1::França}} é {{c2::Paris}}',
    );
  });

  test('effective area falls back to the deck and stays visible in ancestors', () {
    final music = KnowledgeArea.create(
      id: EntityId('music'),
      profileId: profile,
      title: 'Música',
      createdAt: now,
    );
    final theory = KnowledgeArea.create(
      id: EntityId('theory'),
      profileId: profile,
      parentId: music.id,
      title: 'Teoria',
      createdAt: now,
    );
    final deckEntity = FlashcardDeck.create(
      id: deck,
      profileId: profile,
      title: 'Música',
      createdAt: now,
      areaId: music.id,
    );
    final orphan = card('orphan');
    expect(
      FlashcardAreaPolicy.effectiveAreaId(orphan, deck: deckEntity),
      music.id,
    );
    expect(
      FlashcardAreaPolicy.isVisibleInArea(
        card: orphan,
        rootId: music.id,
        areas: [music, theory],
        deck: deckEntity,
      ),
      isTrue,
    );
    expect(
      FlashcardAreaPolicy.canSpecialize(
        deckAreaId: music.id,
        cardAreaId: theory.id,
        areas: [music, theory],
      ),
      isTrue,
    );
    expect(
      FlashcardAreaPolicy.canSpecialize(
        deckAreaId: theory.id,
        cardAreaId: music.id,
        areas: [music, theory],
      ),
      isFalse,
    );
  });

  test('today digest caps the session and separates later / unscheduled', () {
    final deckA = FlashcardDeck.create(
      id: deck,
      profileId: profile,
      title: 'A',
      createdAt: now,
      newLimitPerDay: 1,
      reviewLimitPerDay: 1,
    );
    final n1 = card('n1');
    final n2 = card('n2');
    final later = card('later');
    final saved = card('saved').copyWith(
      scheduleMode: FlashcardScheduleMode.unscheduled,
    );
    final srs = {
      n1.id: FlashcardSrsState.fresh(cardId: n1.id, createdAt: now),
      n2.id: FlashcardSrsState.fresh(cardId: n2.id, createdAt: now),
      later.id: FlashcardSrsState.fresh(cardId: later.id, createdAt: now)
          .copyWith(
        status: FlashcardSrsStatus.learning,
        dueAt: now.add(const Duration(hours: 3)),
      ),
      saved.id: FlashcardSrsState.fresh(cardId: saved.id, createdAt: now),
    };
    final digest = FlashcardTodayDigestPolicy.build(
      cards: [n1, n2, later, saved],
      srsByCard: srs,
      decks: [deckA],
      logs: const [],
      now: now,
    );
    expect(digest.dueNowTotal, 2);
    expect(digest.cappedForSession, 1);
    expect(digest.sessionByBucket.newCount, 1);
    expect(digest.sessionByBucket.learningCount, 0);
    expect(digest.limitDeferred, 1);
    expect(digest.dueLaterToday, 1);
    expect(digest.unscheduledCount, 1);
    expect(digest.estimatedMinutes, 1);
  });

  test('daily usage ignores practice logs and learning-step reps', () {
    final reviewCard = card('r');
    final logs = [
      FlashcardReviewLog(
        id: EntityId('p'),
        cardId: reviewCard.id,
        reviewedAt: now,
        rating: FlashcardRating.good,
        intervalDaysBefore: 2,
        intervalDaysAfter: 2,
        easeBefore: 2.5,
        easeAfter: 2.5,
        reviewKind: FlashcardReviewKind.practice,
      ),
      FlashcardReviewLog(
        id: EntityId('l'),
        cardId: reviewCard.id,
        reviewedAt: now,
        rating: FlashcardRating.good,
        intervalDaysBefore: 0,
        intervalDaysAfter: 0,
        easeBefore: 2.5,
        easeAfter: 2.5,
      ),
    ];
    expect(
      FlashcardDailyUsagePolicy.reviewRepsByDeck(
        cards: [reviewCard],
        logs: logs,
        now: now,
      ),
      isEmpty,
    );
  });

  test('Tropicalismo cards are visible from Music and from Brazil', () {
    final music = KnowledgeArea.create(
      id: EntityId('music'),
      profileId: profile,
      title: 'Música',
      createdAt: now,
    );
    final trop = KnowledgeArea.create(
      id: EntityId('trop'),
      profileId: profile,
      parentId: music.id,
      title: 'Tropicalismo',
      createdAt: now,
    );
    final brazil = KnowledgeArea.create(
      id: EntityId('br'),
      profileId: profile,
      title: 'História do Brasil',
      createdAt: now,
    );
    final areas = [music, trop, brazil];
    final placements = [
      KnowledgeAreaPlacement(
        areaId: trop.id,
        parentAreaId: brazil.id,
        linkedAt: now,
      ),
    ];
    final tropCard = card('trop', area: trop.id);
    expect(
      StudyQueuePolicy.cardsInArea(
        cards: [tropCard],
        rootId: music.id,
        areas: areas,
        placements: placements,
      ),
      [tropCard],
    );
    expect(
      StudyQueuePolicy.cardsInArea(
        cards: [tropCard],
        rootId: brazil.id,
        areas: areas,
        placements: placements,
      ),
      [tropCard],
    );
  });

  test('nextDuePhrase and forecast labels stay human', () {
    expect(StudyQueuePolicy.nextDuePhrase(null, now), isNull);
    expect(
      StudyQueuePolicy.nextDuePhrase(
        FlashcardSrsState.fresh(cardId: EntityId('n'), createdAt: now),
        now,
      ),
      isNull,
    );
    expect(
      StudyQueuePolicy.formatDueAt(now.add(const Duration(days: 3)), now),
      '3 d',
    );
    expect(StudyQueuePolicy.formatDueAt(now, now), 'agora');
    expect(
      StudyQueuePolicy.forecastDayLabels(DateTime.utc(2026, 8, 17, 12)),
      ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'],
    );
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
