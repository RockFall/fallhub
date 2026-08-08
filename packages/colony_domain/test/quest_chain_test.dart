import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 6);
  final profileId = EntityId('profile');

  Quest quest(String id, String title, {QuestStatus status = QuestStatus.draft}) {
    return Quest.create(
      id: EntityId(id),
      profileId: profileId,
      title: title,
      purpose: title,
      createdAt: now,
      status: status,
    );
  }

  test('linear chain orders prerequisites first', () {
    final quests = [
      quest('c', 'Reservas'),
      quest('a', 'Documentos', status: QuestStatus.completed),
      quest('b', 'Seguro', status: QuestStatus.active),
    ];
    final links = [
      QuestPrerequisiteLink(
        questId: EntityId('b'),
        prerequisiteQuestId: EntityId('a'),
        linkedAt: now,
      ),
      QuestPrerequisiteLink(
        questId: EntityId('c'),
        prerequisiteQuestId: EntityId('b'),
        linkedAt: now,
      ),
    ];

    final chain = buildQuestChain(
      focusQuestId: EntityId('c'),
      quests: quests,
      links: links,
    );

    expect(chain, hasLength(3));
    expect(chain.map((n) => n.quest.id.value), ['a', 'b', 'c']);
    expect(chain.last.isCurrent, isTrue);
  });

  test('isolated quest returns empty chain', () {
    final chain = buildQuestChain(
      focusQuestId: EntityId('solo'),
      quests: [quest('solo', 'Solo')],
      links: const [],
    );
    expect(chain, isEmpty);
  });

  test('diamond DAG topological order', () {
    final quests = [
      quest('d', 'Execução'),
      quest('a', 'Docs', status: QuestStatus.completed),
      quest('b', 'Seguro'),
      quest('c', 'Pagamentos'),
    ];
    final links = [
      QuestPrerequisiteLink(
        questId: EntityId('b'),
        prerequisiteQuestId: EntityId('a'),
        linkedAt: now,
      ),
      QuestPrerequisiteLink(
        questId: EntityId('c'),
        prerequisiteQuestId: EntityId('a'),
        linkedAt: now,
      ),
      QuestPrerequisiteLink(
        questId: EntityId('d'),
        prerequisiteQuestId: EntityId('b'),
        linkedAt: now,
      ),
      QuestPrerequisiteLink(
        questId: EntityId('d'),
        prerequisiteQuestId: EntityId('c'),
        linkedAt: now,
      ),
    ];

    final chain = buildQuestChain(
      focusQuestId: EntityId('d'),
      quests: quests,
      links: links,
    );

    expect(chain, hasLength(4));
    expect(chain.first.quest.id.value, 'a');
    expect(chain.indexWhere((n) => n.quest.id.value == 'b'), lessThan(
      chain.indexWhere((n) => n.quest.id.value == 'd'),
    ));
    expect(chain.indexWhere((n) => n.quest.id.value == 'c'), lessThan(
      chain.indexWhere((n) => n.quest.id.value == 'd'),
    ));
  });
}
