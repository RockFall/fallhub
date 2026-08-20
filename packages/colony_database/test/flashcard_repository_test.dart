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
    expect(snapshot.version, 33);
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

  test('importJson creates shelves, skips clones and overwrites answers', () async {
    final created = await profile();
    const source = '''
{
  "cards": [
    {
      "front": "ODD",
      "back": "Operational Design Domain",
      "deck": "AV",
      "areaPath": ["Engenharia", "Automotiva", "Carros autônomos", "ODD"]
    }
  ]
}
''';
    final first = await repos.flashcards.importJson(
      profileId: created.id,
      source: source,
    );
    expect(first.createdCards, 1);
    expect(first.createdDecks, 1);
    expect(first.createdAreas, greaterThanOrEqualTo(4));

    final second = await repos.flashcards.importJson(
      profileId: created.id,
      source: source,
    );
    expect(second.skippedCards, 1);
    expect(second.createdCards, 0);
    expect(await repos.flashcards.listCards(created.id), hasLength(1));

    final third = await repos.flashcards.importJson(
      profileId: created.id,
      source: '''
{"cards":[{"front":"ODD","back":"Domínio operacional de desenho","deck":"AV"}]}
''',
    );
    expect(third.overwrittenCards, 1);
    expect((await repos.flashcards.listCards(created.id)).single.back,
        'Domínio operacional de desenho');
    final odd = (await repos.flashcards.listAreas(created.id)).firstWhere(
      (a) => a.title.startsWith('ODD'),
    );
    expect(odd.catalogKey, 'engineering.automotive.autonomous.odd');
  });

  test('deleteCard removes the card, reverse pair, srs and logs', () async {
    final created = await profile();
    final deck = await repos.flashcards.createDeck(
      profileId: created.id,
      title: 'Pares',
    );
    final pair = await repos.flashcards.createCard(
      profileId: created.id,
      deckId: deck.id,
      front: 'cat',
      back: 'gato',
      bidirectional: true,
    );
    expect(pair, hasLength(2));
    await repos.flashcards.review(
      card: pair.first,
      rating: FlashcardRating.good,
    );
    await repos.flashcards.deleteCard(pair.first);
    expect(await repos.flashcards.listCards(created.id), isEmpty);
    expect(await repos.flashcards.listSrs(created.id), isEmpty);
    expect(await repos.flashcards.listLogs(created.id), isEmpty);

    final leftover = await repos.flashcards.createCard(
      profileId: created.id,
      deckId: deck.id,
      front: 'keep',
      back: 'ficar',
    );
    final cloze = await repos.flashcards.createCard(
      profileId: created.id,
      deckId: deck.id,
      kind: FlashcardKind.cloze,
      front: 'The capital of {{c1::France}} is {{c2::Paris}}',
      back: '',
    );
    expect(cloze, hasLength(2));
    await repos.flashcards.deleteCard(cloze.first);
    final remaining = await repos.flashcards.listCards(created.id);
    expect(remaining.map((c) => c.id), containsAll([leftover.single.id, cloze.last.id]));
    expect(remaining, hasLength(2));
  });

  test('new cards default to priority 5 and update persists 1', () async {
    final created = await profile();
    final deck = await repos.flashcards.createDeck(
      profileId: created.id,
      title: 'Prioridade',
    );
    final cards = await repos.flashcards.createCard(
      profileId: created.id,
      deckId: deck.id,
      front: 'Baixa',
      back: '5',
    );
    expect(cards.single.priority, 5);

    await repos.flashcards.updateCard(cards.single.copyWith(priority: 1));
    final stored = (await repos.flashcards.listCards(created.id)).single;
    expect(stored.priority, 1);

    final snapshot = await repos.export.buildSnapshot();
    expect(snapshot.version, 33);
    expect(snapshot.flashcards.single.priority, 1);

    await repos.restore.restore(snapshot);
    final restored = (await repos.flashcards.listCards(created.id)).single;
    expect(restored.priority, 1);
  });

  test('hierarchical tags link N cards and parent study includes subtags', () async {
    final created = await profile();
    final deck = await repos.flashcards.createDeck(
      profileId: created.id,
      title: 'Teoria',
    );
    final music = await repos.flashcards.createTag(
      profileId: created.id,
      title: 'Música',
    );
    final harmony = await repos.flashcards.createTag(
      profileId: created.id,
      title: 'Harmonia',
      parentId: music.id,
    );
    final cards = await repos.flashcards.createCard(
      profileId: created.id,
      deckId: deck.id,
      front: 'ii-V-I',
      back: 'Progressão',
      tags: const ['Música / Harmonia', 'Jazz'],
    );
    final other = await repos.flashcards.createCard(
      profileId: created.id,
      deckId: deck.id,
      front: 'ODD',
      back: 'domínio',
    );
    final tags = await repos.flashcards.listTags(created.id);
    expect(tags.map((t) => t.title), containsAll(['Música', 'Harmonia', 'Jazz']));
    final jazz = tags.firstWhere((t) => t.title == 'Jazz');
    expect(jazz.parentId, isNull);
    expect(harmony.parentId, music.id);

    final listed = await repos.flashcards.listCards(created.id);
    final tagged = listed.firstWhere((c) => c.id == cards.single.id);
    expect(tagged.tags, containsAll(['harmonia', 'jazz']));

    final links = await repos.flashcards.listTagLinks(created.id);
    final hits = FlashcardTagPolicy.cardsWithTag(
      cards: listed,
      links: links,
      tags: tags,
      rootId: music.id,
    );
    expect(hits.map((c) => c.id), [cards.single.id]);
    expect(hits.map((c) => c.id), isNot(contains(other.single.id)));

    final snapshot = await repos.export.buildSnapshot();
    expect(snapshot.flashcardTags, hasLength(3));
    expect(snapshot.flashcardTagLinks, hasLength(2));
    await repos.restore.restore(snapshot);
    expect(await repos.flashcards.listTags(created.id), hasLength(3));
    expect(await repos.flashcards.listTagLinks(created.id), hasLength(2));
  });

  test('deleteCard also removes tag links', () async {
    final created = await profile();
    final deck = await repos.flashcards.createDeck(
      profileId: created.id,
      title: 'Pares',
    );
    final cards = await repos.flashcards.createCard(
      profileId: created.id,
      deckId: deck.id,
      front: 'keep',
      back: 'ficar',
      tags: const ['Jazz'],
    );
    await repos.flashcards.deleteCard(cards.single);
    expect(await repos.flashcards.listTagLinks(created.id), isEmpty);
    expect(await repos.flashcards.listTags(created.id), hasLength(1));
  });
}
