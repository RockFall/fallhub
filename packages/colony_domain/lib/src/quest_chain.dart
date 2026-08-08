import 'id_generator.dart';
import 'quest.dart';
import 'quest_prerequisite.dart';

class QuestChainNode {
  const QuestChainNode({
    required this.quest,
    required this.isCurrent,
  });

  final Quest quest;
  final bool isCurrent;
}

/// Builds the connected prerequisite component containing [focusQuestId],
/// ordered topologically (prerequisites first).
List<QuestChainNode> buildQuestChain({
  required EntityId focusQuestId,
  required List<Quest> quests,
  required List<QuestPrerequisiteLink> links,
}) {
  if (quests.isEmpty) return const [];

  final questById = {for (final q in quests) q.id.value: q};

  final prerequisitesOf = <String, Set<String>>{};
  final dependentsOf = <String, Set<String>>{};
  for (final link in links) {
    final quest = link.questId.value;
    final prereq = link.prerequisiteQuestId.value;
    prerequisitesOf.putIfAbsent(quest, () => {}).add(prereq);
    dependentsOf.putIfAbsent(prereq, () => {}).add(quest);
  }

  final component = <String>{};
  final stack = [focusQuestId.value];
  while (stack.isNotEmpty) {
    final current = stack.removeLast();
    if (!component.add(current)) continue;
    for (final prereq in prerequisitesOf[current] ?? const {}) {
      stack.add(prereq);
    }
    for (final dependent in dependentsOf[current] ?? const {}) {
      stack.add(dependent);
    }
  }

  if (component.length <= 1) {
    final hasEdge = links.any(
      (l) =>
          component.contains(l.questId.value) ||
          component.contains(l.prerequisiteQuestId.value),
    );
    if (!hasEdge) return const [];
  }

  final inDegree = <String, int>{for (final id in component) id: 0};
  final adjacency = <String, List<String>>{};
  for (final link in links) {
    final quest = link.questId.value;
    final prereq = link.prerequisiteQuestId.value;
    if (!component.contains(quest) || !component.contains(prereq)) continue;
    adjacency.putIfAbsent(prereq, () => []).add(quest);
    inDegree[quest] = (inDegree[quest] ?? 0) + 1;
  }

  final queue = inDegree.entries
      .where((e) => e.value == 0)
      .map((e) => e.key)
      .toList()
    ..sort();
  final ordered = <String>[];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    ordered.add(current);
    for (final next in adjacency[current] ?? const []) {
      inDegree[next] = inDegree[next]! - 1;
      if (inDegree[next] == 0) {
        queue.add(next);
        queue.sort();
      }
    }
  }

  if (ordered.length != component.length) {
    final remaining = component.difference(ordered.toSet()).toList()..sort();
    ordered.addAll(remaining);
  }

  return ordered
      .map((id) => questById[id])
      .whereType<Quest>()
      .map(
        (quest) => QuestChainNode(
          quest: quest,
          isCurrent: quest.id == focusQuestId,
        ),
      )
      .toList();
}
