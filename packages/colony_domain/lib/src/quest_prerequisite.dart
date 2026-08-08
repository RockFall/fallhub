import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'quest.dart';

/// Directed link: [questId] requires [prerequisiteQuestId] to be completed before activation.
class QuestPrerequisiteLink extends Equatable {
  const QuestPrerequisiteLink({
    required this.questId,
    required this.prerequisiteQuestId,
    required this.linkedAt,
  });

  final EntityId questId;
  final EntityId prerequisiteQuestId;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [questId, prerequisiteQuestId, linkedAt];
}

class QuestPrerequisiteException implements Exception {
  QuestPrerequisiteException(this.message);
  final String message;

  @override
  String toString() => message;
}

class QuestPrerequisitePolicy {
  const QuestPrerequisitePolicy._();

  /// Returns true if adding `questId → prerequisiteQuestId` would create a cycle.
  static bool wouldCreateCycle({
    required List<QuestPrerequisiteLink> existingLinks,
    required EntityId questId,
    required EntityId prerequisiteQuestId,
  }) {
    if (questId == prerequisiteQuestId) return true;

    final adjacency = <String, Set<String>>{};
    for (final link in existingLinks) {
      adjacency
          .putIfAbsent(link.questId.value, () => {})
          .add(link.prerequisiteQuestId.value);
    }
    adjacency
        .putIfAbsent(questId.value, () => {})
        .add(prerequisiteQuestId.value);

    return _hasPath(
      adjacency,
      start: prerequisiteQuestId.value,
      target: questId.value,
    );
  }

  static bool _hasPath(
    Map<String, Set<String>> adjacency, {
    required String start,
    required String target,
  }) {
    if (start == target) return true;
    final visited = <String>{};
    final stack = [start];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (!visited.add(current)) continue;
      for (final next in adjacency[current] ?? const {}) {
        if (next == target) return true;
        stack.add(next);
      }
    }
    return false;
  }

  static void validateLink({
    required List<QuestPrerequisiteLink> existingLinks,
    required EntityId questId,
    required EntityId prerequisiteQuestId,
  }) {
    if (questId == prerequisiteQuestId) {
      throw QuestPrerequisiteException('Missão não pode depender de si mesma');
    }
    if (wouldCreateCycle(
      existingLinks: existingLinks,
      questId: questId,
      prerequisiteQuestId: prerequisiteQuestId,
    )) {
      throw QuestPrerequisiteException(
        'Dependência circular entre missões',
      );
    }
  }

  /// Whether [quest] can transition to active given prerequisite statuses.
  static bool canActivate({
    required Quest quest,
    required List<Quest> prerequisites,
  }) {
    if (quest.status != QuestStatus.draft && quest.status != QuestStatus.paused) {
      return true;
    }
    return prerequisites.every((p) => p.status == QuestStatus.completed);
  }

  /// Prerequisites that block activation (not completed).
  static List<Quest> blockingPrerequisites({
    required List<Quest> prerequisites,
  }) {
    return prerequisites
        .where((p) => p.status != QuestStatus.completed)
        .toList();
  }

  /// True when the quest has incomplete prerequisites and is not terminal.
  static bool isWaitingOnPrerequisites({
    required Quest quest,
    required List<Quest> prerequisites,
  }) {
    if (quest.status.isTerminal) return false;
    return blockingPrerequisites(prerequisites: prerequisites).isNotEmpty;
  }
}
