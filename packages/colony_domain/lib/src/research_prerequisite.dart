import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'research_node.dart';

/// Directed link: [nodeId] requires [prerequisiteNodeId] to be demonstrated
/// before entering `inResearch`.
class ResearchPrerequisiteLink extends Equatable {
  const ResearchPrerequisiteLink({
    required this.nodeId,
    required this.prerequisiteNodeId,
    required this.linkedAt,
  });

  final EntityId nodeId;
  final EntityId prerequisiteNodeId;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [nodeId, prerequisiteNodeId, linkedAt];
}

class ResearchPrerequisiteException implements Exception {
  ResearchPrerequisiteException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ResearchPrerequisitePolicy {
  const ResearchPrerequisitePolicy._();

  static bool wouldCreateCycle({
    required List<ResearchPrerequisiteLink> existingLinks,
    required EntityId nodeId,
    required EntityId prerequisiteNodeId,
  }) {
    if (nodeId == prerequisiteNodeId) return true;

    final adjacency = <String, Set<String>>{};
    for (final link in existingLinks) {
      adjacency
          .putIfAbsent(link.nodeId.value, () => {})
          .add(link.prerequisiteNodeId.value);
    }
    adjacency
        .putIfAbsent(nodeId.value, () => {})
        .add(prerequisiteNodeId.value);

    return _hasPath(
      adjacency,
      start: prerequisiteNodeId.value,
      target: nodeId.value,
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
    required List<ResearchPrerequisiteLink> existingLinks,
    required EntityId nodeId,
    required EntityId prerequisiteNodeId,
  }) {
    if (nodeId == prerequisiteNodeId) {
      throw ResearchPrerequisiteException(
        'Nó de pesquisa não pode depender de si mesmo',
      );
    }
    if (wouldCreateCycle(
      existingLinks: existingLinks,
      nodeId: nodeId,
      prerequisiteNodeId: prerequisiteNodeId,
    )) {
      throw ResearchPrerequisiteException(
        'Dependência circular entre nós de pesquisa',
      );
    }
  }

  static bool canSetInResearch({
    required ResearchNode node,
    required List<ResearchNode> prerequisites,
  }) {
    if (node.status != ResearchNodeStatus.available) {
      return true;
    }
    return prerequisites.every(
      (p) => p.status == ResearchNodeStatus.demonstrated,
    );
  }

  static List<ResearchNode> blockingPrerequisites({
    required List<ResearchNode> prerequisites,
  }) {
    return prerequisites
        .where((p) => p.status != ResearchNodeStatus.demonstrated)
        .toList();
  }

  static bool isWaitingOnPrerequisites({
    required ResearchNode node,
    required List<ResearchNode> prerequisites,
  }) {
    if (node.status.isTerminal) return false;
    return blockingPrerequisites(prerequisites: prerequisites).isNotEmpty;
  }
}
