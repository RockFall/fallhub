import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 12);
  final profile = EntityId('p1');

  FlashcardTag tag({
    required String id,
    required String title,
    String? parent,
  }) {
    return FlashcardTag.create(
      id: EntityId(id),
      profileId: profile,
      title: title,
      parentId: parent == null ? null : EntityId(parent),
      createdAt: now,
    );
  }

  test('forest nests subtags and pathLabel walks to the root', () {
    final music = tag(id: 'm', title: 'Música');
    final harmony = tag(id: 'h', title: 'Harmonia', parent: 'm');
    final forest = FlashcardTagPolicy.buildForest([harmony, music]);
    expect(forest, hasLength(1));
    expect(forest.single.tag.id, music.id);
    expect(forest.single.children.single.tag.id, harmony.id);
    expect(
      FlashcardTagPolicy.pathLabel(
        tagId: harmony.id,
        tags: [music, harmony],
      ),
      'Música · Harmonia',
    );
  });

  test('studying a parent tag includes cards on subtags', () {
    final music = tag(id: 'm', title: 'Música');
    final harmony = tag(id: 'h', title: 'Harmonia', parent: 'm');
    final card = Flashcard.create(
      id: EntityId('c1'),
      profileId: profile,
      deckId: EntityId('d1'),
      front: 'ii-V-I',
      back: 'Progressão',
      createdAt: now,
    );
    final other = Flashcard.create(
      id: EntityId('c2'),
      profileId: profile,
      deckId: EntityId('d1'),
      front: 'ODD',
      back: 'domínio',
      createdAt: now,
    );
    final hits = FlashcardTagPolicy.cardsWithTag(
      cards: [card, other],
      links: [
        FlashcardTagLink(cardId: card.id, tagId: harmony.id, linkedAt: now),
      ],
      tags: [music, harmony],
      rootId: music.id,
    );
    expect(hits.map((c) => c.id), [card.id]);
  });

  test('parsePath accepts list or slash-delimited string', () {
    expect(FlashcardTagPolicy.parsePath('Música / Harmonia'), ['Música', 'Harmonia']);
    expect(FlashcardTagPolicy.parsePath(['Artes', 'Piano']), ['Artes', 'Piano']);
  });

  test('cycle in parent chain is rejected', () {
    expect(
      () => FlashcardTagPolicy.assertAcyclic(
        tagId: EntityId('a'),
        parentId: EntityId('b'),
        parentById: {
          EntityId('b'): EntityId('a'),
        },
      ),
      throwsA(isA<FlashcardTagCycleException>()),
    );
  });
}
