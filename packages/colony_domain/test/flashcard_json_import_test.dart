import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 12);
  final profile = EntityId('p1');

  KnowledgeArea area({
    required String id,
    required String title,
    String? parent,
    String? catalogKey,
  }) {
    return KnowledgeArea.create(
      id: EntityId(id),
      profileId: profile,
      title: title,
      parentId: parent == null ? null : EntityId(parent),
      catalogKey: catalogKey,
      createdAt: now,
    );
  }

  test('parse accepts fenced JSON, areaPath string and Portuguese kind', () {
    const source = '''
Aqui está o lote:
```json
{
  "cards": [{
    "front": "ii-V-I",
    "back": "Progressão tônica",
    "tipo": "básico",
    "deck": "Harmonia",
    "areaPath": "Artes / Música / Harmonia",
    "schedule": "guardado"
  }]
}
```
''';
    final doc = FlashcardJsonCodec.parse(source);
    expect(doc.cards, hasLength(1));
    expect(doc.cards.single.kind, FlashcardKind.basic);
    expect(doc.cards.single.areaPath, ['Artes', 'Música', 'Harmonia']);
    expect(doc.cards.single.scheduleMode, FlashcardScheduleMode.unscheduled);
  });

  test('plan creates missing shelves and skips identical cards', () {
    final arts = area(id: 'arts', title: 'Artes', catalogKey: 'arts');
    final music = area(
      id: 'music',
      title: 'Música',
      parent: 'arts',
      catalogKey: 'arts.music',
    );
    final deck = FlashcardDeck.create(
      id: EntityId('d1'),
      profileId: profile,
      title: 'Harmonia',
      createdAt: now,
    );
    final existing = Flashcard.create(
      id: EntityId('c1'),
      profileId: profile,
      deckId: deck.id,
      front: 'ii-V-I',
      back: 'Progressão tônica',
      createdAt: now,
    );
    final doc = FlashcardJsonCodec.parse('''
{
  "cards": [
    {
      "front": "ii-V-I",
      "back": "Progressão tônica",
      "deck": "harmonia",
      "areaPath": ["Artes", "Música", "Harmonia"]
    },
    {
      "front": "Dominante",
      "back": "V7",
      "deck": "Harmonia",
      "areaPath": ["Artes", "Música", "Harmonia"]
    }
  ]
}
''');
    final plan = FlashcardJsonImportPolicy.plan(
      document: doc,
      areas: [arts, music],
      decks: [deck],
      cards: [existing],
    );
    expect(plan.skipCount, 1);
    expect(plan.createCount, 1);
    expect(
      plan.areas.map((s) => s.path.join('>')),
      contains('Artes>Música>Harmonia'),
    );
    expect(
      plan.areas.singleWhere((s) => s.title == 'Harmonia').existingId,
      isNull,
    );
    expect(
      plan.areas.singleWhere((s) => s.title == 'Artes').existingId,
      arts.id,
    );
  });

  test('plan overwrites when the answer changed', () {
    final deck = FlashcardDeck.create(
      id: EntityId('d1'),
      profileId: profile,
      title: 'Fila',
      createdAt: now,
    );
    final existing = Flashcard.create(
      id: EntityId('c1'),
      profileId: profile,
      deckId: deck.id,
      front: 'ODD',
      back: 'errado',
      createdAt: now,
    );
    final doc = FlashcardJsonCodec.parse('''
{"cards":[{"front":"ODD","back":"Operational Design Domain","deck":"Fila"}]}
''');
    final plan = FlashcardJsonImportPolicy.plan(
      document: doc,
      areas: const [],
      decks: [deck],
      cards: [existing],
    );
    expect(plan.overwriteCount, 1);
    expect(plan.cards.single.existingIds, [existing.id]);
  });

  test('plan skips in-batch clones and keeps the latest answer', () {
    final doc = FlashcardJsonCodec.parse('''
{
  "cards": [
    {"front": "ODD", "back": "v1", "deck": "AV"},
    {"front": "ODD", "back": "v1", "deck": "AV"},
    {"front": "ODD", "back": "Operational Design Domain", "deck": "AV"}
  ]
}
''');
    final plan = FlashcardJsonImportPolicy.plan(
      document: doc,
      areas: const [],
      decks: const [],
      cards: const [],
    );
    expect(plan.createCount, 1);
    expect(plan.skipCount, 2);
    expect(plan.cards.first.card.back, 'Operational Design Domain');
  });

  test('prompt lists live areas and mentions freedom to create', () {
    final arts = area(id: 'arts', title: 'Artes', catalogKey: 'arts');
    final trop = area(id: 'trop', title: 'Tropicalismo', parent: 'arts');
    final empty = FlashcardJsonPromptBuilder.build(areas: const []);
    expect(empty, contains('ainda não há categorias'));
    expect(empty, contains('areaPath'));
    expect(empty, contains('Linguagens > Português'));

    final filled = FlashcardJsonPromptBuilder.build(
      areas: [arts, trop],
      decks: [
        FlashcardDeck.create(
          id: EntityId('d1'),
          profileId: profile,
          title: 'Bossa',
          createdAt: now,
        ),
      ],
    );
    expect(filled, contains('Tropicalismo'));
    expect(filled, contains('Artes'));
    expect(filled, contains('Bossa'));
    expect(filled, contains('inventar ramos novos'));
    expect(filled.contains('ainda não há categorias'), isFalse);
  });

  test('catalog childNamed walks the suggested map', () {
    final arts = KnowledgeAreaCatalog.childNamed(null, 'Artes');
    expect(arts?.key, 'arts');
    expect(
      KnowledgeAreaCatalog.childNamed(arts, 'Música')?.key,
      'arts.music',
    );
  });
}
