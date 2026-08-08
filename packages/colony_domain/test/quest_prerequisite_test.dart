import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 6);
  final questA = EntityId('a');
  final questB = EntityId('b');
  final questC = EntityId('c');

  group('QuestPrerequisitePolicy', () {
    test('allows link without cycle', () {
      expect(
        QuestPrerequisitePolicy.wouldCreateCycle(
          existingLinks: const [],
          questId: questB,
          prerequisiteQuestId: questA,
        ),
        isFalse,
      );
    });

    test('rejects direct cycle', () {
      final links = [
        QuestPrerequisiteLink(
          questId: questA,
          prerequisiteQuestId: questB,
          linkedAt: now,
        ),
      ];
      expect(
        () => QuestPrerequisitePolicy.validateLink(
          existingLinks: links,
          questId: questB,
          prerequisiteQuestId: questA,
        ),
        throwsA(isA<QuestPrerequisiteException>()),
      );
    });

    test('rejects indirect cycle', () {
      final links = [
        QuestPrerequisiteLink(
          questId: questA,
          prerequisiteQuestId: questB,
          linkedAt: now,
        ),
        QuestPrerequisiteLink(
          questId: questB,
          prerequisiteQuestId: questC,
          linkedAt: now,
        ),
      ];
      expect(
        () => QuestPrerequisitePolicy.validateLink(
          existingLinks: links,
          questId: questC,
          prerequisiteQuestId: questA,
        ),
        throwsA(isA<QuestPrerequisiteException>()),
      );
    });

    test('canActivate when all prerequisites completed', () {
      final quest = Quest.create(
        id: questC,
        profileId: EntityId('profile'),
        title: 'Main',
        purpose: 'P',
        createdAt: now,
        status: QuestStatus.draft,
      );
      final prereq = Quest.create(
        id: questA,
        profileId: EntityId('profile'),
        title: 'Prereq',
        purpose: 'P',
        createdAt: now,
        status: QuestStatus.completed,
      );
      expect(
        QuestPrerequisitePolicy.canActivate(
          quest: quest,
          prerequisites: [prereq],
        ),
        isTrue,
      );
    });

    test('blocks activate when prerequisite not completed', () {
      final quest = Quest.create(
        id: questC,
        profileId: EntityId('profile'),
        title: 'Main',
        purpose: 'P',
        createdAt: now,
        status: QuestStatus.draft,
      );
      final prereq = Quest.create(
        id: questA,
        profileId: EntityId('profile'),
        title: 'Prereq',
        purpose: 'P',
        createdAt: now,
        status: QuestStatus.active,
      );
      expect(
        QuestPrerequisitePolicy.canActivate(
          quest: quest,
          prerequisites: [prereq],
        ),
        isFalse,
      );
    });
  });
}
