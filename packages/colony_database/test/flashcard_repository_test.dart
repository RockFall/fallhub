import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ColonyDatabase db;
  late ColonyRepositories repos;
  var now = DateTime.utc(2026, 8, 17, 12);

  setUp(() {
    now = DateTime.utc(2026, 8, 17, 12);
    db = ColonyDatabase.inMemory();
    repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 80; i++) 'id-$i',
      ]),
      clock: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<ColonyProfile> profile() {
    return repos.profiles.create(
      colonyName: 'Flash',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
  }

  test('seed catalog, cloze split, reverse pair, review undo and export', () async {
    final created = await profile();
    final seeded = await repos.flashcards.seedCatalog(
      profileId: created.id,
      keys: const ['languages.en'],
    );
    expect(seeded.map((a) => a.catalogKey), containsAll(['languages', 'languages.en']));

    final english = (await repos.flashcards.listAreas(created.id))
        .firstWhere((a) => a.catalogKey == 'languages.en');
    final deck = await repos.flashcards.createDeck(
      profileId: created.id,
      title: 'Inglês',
      areaId: english.id,
    );

    final cloze = await repos.flashcards.createCard(
      profileId: created.id,
      deckId: deck.id,
      areaId: english.id,
      kind: FlashcardKind.cloze,
      front: 'The capital of {{c1::France}} is {{c2::Paris}}',
      back: '',
    );
    expect(cloze, hasLength(2));
    expect(cloze.map((c) => c.clozeIndex), containsAll([1, 2]));

    final pair = await repos.flashcards.createCard(
      profileId: created.id,
      deckId: deck.id,
      areaId: english.id,
      front: 'cat',
      back: 'gato',
      bidirectional: true,
    );
    expect(pair, hasLength(2));
    expect(pair.last.kind, FlashcardKind.reverse);
    expect(pair.last.reverseOfId, pair.first.id);

    final card = pair.first;
    final outcome = await repos.flashcards.review(
      card: card,
      rating: FlashcardRating.good,
    );
    expect(outcome.next.status, FlashcardSrsStatus.learning);
    expect(outcome.next.learningStepIndex, 1);

    await repos.flashcards.undoReview(outcome: outcome);
    final srs = await repos.flashcards.listSrs(created.id);
    final restored = srs.firstWhere((s) => s.cardId == card.id);
    expect(restored.status, FlashcardSrsStatus.newCard);
    expect(await repos.flashcards.listLogs(created.id), isEmpty);

    await repos.flashcards.bury(card);
    final buried = (await repos.flashcards.listSrs(created.id))
        .firstWhere((s) => s.cardId == card.id);
    expect(buried.dueAt.isAfter(now), isTrue);

    final snapshot = await repos.export.buildSnapshot();
    expect(snapshot.version, 31);
    expect(snapshot.knowledgeAreas, isNotEmpty);
    expect(snapshot.flashcardDecks, hasLength(1));
    expect(snapshot.flashcards.length, greaterThanOrEqualTo(4));
    expect(snapshot.flashcardSrs, hasLength(snapshot.flashcards.length));

    await repos.restore.restore(snapshot);
    final restoredAreas = await repos.flashcards.listAreas(created.id);
    expect(
      restoredAreas.any((a) => a.catalogKey == 'languages.en'),
      isTrue,
    );
    expect(await repos.flashcards.listDecks(created.id), hasLength(1));
  });

  test('cycle in knowledge map is rejected', () async {
    final created = await profile();
    final root = await repos.flashcards.createArea(
      profileId: created.id,
      title: 'Raiz',
    );
    final child = await repos.flashcards.createArea(
      profileId: created.id,
      title: 'Filho',
      parentId: root.id,
    );
    expect(
      () => repos.flashcards.updateArea(root.copyWith(parentId: child.id)),
      throwsA(isA<KnowledgeAreaCycleException>()),
    );
  });

  test('unscheduled card has no SRS; practice does not mutate intervals', () async {
    final created = await profile();
    final deck = await repos.flashcards.createDeck(
      profileId: created.id,
      title: 'Pontual',
    );
    final cards = await repos.flashcards.createCard(
      profileId: created.id,
      deckId: deck.id,
      front: 'ODD',
      back: 'Operational Design Domain',
      scheduleMode: FlashcardScheduleMode.unscheduled,
    );
    expect(await repos.flashcards.listSrs(created.id), isEmpty);
    final log = await repos.flashcards.practice(
      card: cards.single,
      rating: FlashcardRating.good,
    );
    expect(log.reviewKind, FlashcardReviewKind.practice);
    expect(await repos.flashcards.listSrs(created.id), isEmpty);
    await repos.flashcards.scheduleCard(cards.single);
    final scheduled = (await repos.flashcards.listCards(created.id)).single;
    expect(scheduled.scheduleMode, FlashcardScheduleMode.scheduled);
    expect(await repos.flashcards.listSrs(created.id), hasLength(1));
  });

  test('catalog seeds Tropicalismo under Music and History of Brazil', () async {
    final created = await profile();
    await repos.flashcards.seedCatalog(
      profileId: created.id,
      keys: const ['arts.music.tropicalismo'],
    );
    final areas = await repos.flashcards.listAreas(created.id);
    final trop = areas.firstWhere(
      (a) => a.catalogKey == 'arts.music.tropicalismo',
    );
    final brazil = areas.firstWhere(
      (a) => a.catalogKey == 'humanities.history.brazil',
    );
    expect(trop.parentId, isNotNull);
    final placements = await repos.flashcards.listPlacements(created.id);
    expect(
      placements.any(
        (p) => p.areaId == trop.id && p.parentAreaId == brazil.id,
      ),
      isTrue,
    );
    expect(
      KnowledgeAreaPolicy.descendantIds(
        rootId: brazil.id,
        areas: areas,
        placements: placements,
      ),
      contains(trop.id),
    );
  });
}
