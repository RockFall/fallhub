import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('QuestLifecyclePolicy', () {
    test('allows draft to active', () {
      expect(
        QuestLifecyclePolicy.canTransition(QuestStatus.draft, QuestStatus.active),
        isTrue,
      );
    });

    test('allows active to paused, completed, abandoned', () {
      expect(
        QuestLifecyclePolicy.canTransition(QuestStatus.active, QuestStatus.paused),
        isTrue,
      );
      expect(
        QuestLifecyclePolicy.canTransition(QuestStatus.active, QuestStatus.completed),
        isTrue,
      );
      expect(
        QuestLifecyclePolicy.canTransition(QuestStatus.active, QuestStatus.abandoned),
        isTrue,
      );
    });

    test('allows paused back to active', () {
      expect(
        QuestLifecyclePolicy.canTransition(QuestStatus.paused, QuestStatus.active),
        isTrue,
      );
    });

    test('blocks invalid transitions', () {
      expect(
        QuestLifecyclePolicy.canTransition(QuestStatus.draft, QuestStatus.completed),
        isFalse,
      );
      expect(
        QuestLifecyclePolicy.canTransition(QuestStatus.completed, QuestStatus.active),
        isFalse,
      );
      expect(
        QuestLifecyclePolicy.canTransition(QuestStatus.abandoned, QuestStatus.active),
        isFalse,
      );
    });
  });

  group('Quest acceptance fields', () {
    test('copyWith updates acceptance fields', () {
      const id = EntityId('quest-1');
      const profileId = EntityId('profile-1');
      final createdAt = DateTime.utc(2026, 8, 1);
      final quest = Quest.create(
        id: id,
        profileId: profileId,
        title: 'T',
        purpose: 'P',
        createdAt: createdAt,
      );

      final acceptedAt = DateTime.utc(2026, 8, 2);
      final updated = quest.copyWith(
        acceptedAt: acceptedAt,
        acceptanceAssumptions: const ['Premissa'],
        acceptanceDeadline: DateTime.utc(2026, 9, 1),
      );

      expect(updated.acceptedAt, acceptedAt);
      expect(updated.acceptanceAssumptions, ['Premissa']);
      expect(updated.acceptanceDeadline, DateTime.utc(2026, 9, 1));
    });
  });
}
