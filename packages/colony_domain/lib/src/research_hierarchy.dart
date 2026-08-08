import 'research_node.dart';
import 'research_prerequisite.dart';

class ResearchHierarchyNode {
  const ResearchHierarchyNode({
    required this.node,
    required this.depth,
  });

  final ResearchNode node;
  final int depth;
}

/// All research nodes for a profile, ordered topologically with indent depth.
List<ResearchHierarchyNode> buildResearchHierarchy({
  required List<ResearchNode> nodes,
  required List<ResearchPrerequisiteLink> links,
}) {
  if (nodes.isEmpty) return const [];

  final nodeById = {for (final n in nodes) n.id.value: n};

  final prerequisitesOf = <String, Set<String>>{};
  for (final link in links) {
    if (!nodeById.containsKey(link.nodeId.value) ||
        !nodeById.containsKey(link.prerequisiteNodeId.value)) {
      continue;
    }
    prerequisitesOf
        .putIfAbsent(link.nodeId.value, () => {})
        .add(link.prerequisiteNodeId.value);
  }

  final inDegree = <String, int>{for (final id in nodeById.keys) id: 0};
  final adjacency = <String, List<String>>{};
  for (final link in links) {
    final node = link.nodeId.value;
    final prereq = link.prerequisiteNodeId.value;
    if (!nodeById.containsKey(node) || !nodeById.containsKey(prereq)) continue;
    adjacency.putIfAbsent(prereq, () => []).add(node);
    inDegree[node] = (inDegree[node] ?? 0) + 1;
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

  if (ordered.length != nodeById.length) {
    final remaining =
        nodeById.keys.toSet().difference(ordered.toSet()).toList()..sort();
    ordered.addAll(remaining);
  }

  final depthCache = <String, int>{};

  int depthOf(String id) {
    return depthCache.putIfAbsent(id, () {
      final prereqs = prerequisitesOf[id] ?? const {};
      if (prereqs.isEmpty) return 0;
      return prereqs.map(depthOf).reduce((a, b) => a > b ? a : b) + 1;
    });
  }

  return ordered
      .map((id) => nodeById[id])
      .whereType<ResearchNode>()
      .map(
        (node) => ResearchHierarchyNode(
          node: node,
          depth: depthOf(node.id.value),
        ),
      )
      .toList();
}
