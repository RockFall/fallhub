import 'research_node.dart';

class ActiveResearchException implements Exception {
  ActiveResearchException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ActiveResearchPolicy {
  const ActiveResearchPolicy._();

  static const maxActiveFocus = 1;

  static bool canStartFocus({
    required ResearchNode node,
    required List<ResearchNode> allNodes,
  }) {
    if (node.status != ResearchNodeStatus.available) {
      return true;
    }
    final activeCount = allNodes
        .where((n) => n.status == ResearchNodeStatus.inResearch)
        .length;
    return activeCount < maxActiveFocus;
  }

  static ResearchNode? currentFocus(List<ResearchNode> allNodes) {
    for (final node in allNodes) {
      if (node.status == ResearchNodeStatus.inResearch) return node;
    }
    return null;
  }
}
