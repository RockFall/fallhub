import 'dart:math' as math;

import 'research_hierarchy.dart';
import 'research_node.dart';
import 'research_prerequisite.dart';

/// Fixed layout constants for the research graph canvas (ADR-021).
const researchGraphNodeWidth = 160.0;
const researchGraphNodeHeight = 56.0;
const researchGraphLayerSpacing = 120.0;
const researchGraphNodeSpacing = 16.0;
const researchGraphPadding = 32.0;

class ResearchGraphPosition {
  const ResearchGraphPosition({required this.x, required this.y});

  final double x;
  final double y;
}

class ResearchGraphNode {
  const ResearchGraphNode({
    required this.node,
    required this.layer,
    required this.indexInLayer,
    required this.position,
  });

  final ResearchNode node;
  final int layer;
  final int indexInLayer;
  final ResearchGraphPosition position;
}

class ResearchGraphEdge {
  const ResearchGraphEdge({
    required this.fromNodeId,
    required this.toNodeId,
  });

  /// Prerequisite node id (source of the edge).
  final String fromNodeId;

  /// Dependent node id (target of the edge).
  final String toNodeId;
}

class ResearchGraphLayout {
  const ResearchGraphLayout({
    required this.nodes,
    required this.edges,
    required this.width,
    required this.height,
  });

  final List<ResearchGraphNode> nodes;
  final List<ResearchGraphEdge> edges;
  final double width;
  final double height;

  static const empty = ResearchGraphLayout(
    nodes: [],
    edges: [],
    width: 0,
    height: 0,
  );
}

/// Computes a layered DAG layout from research nodes and prerequisite links.
///
/// Orphan links (missing endpoint) are ignored. Layer order follows
/// [buildResearchHierarchy] topological order within each depth band.
ResearchGraphLayout buildResearchGraphLayout({
  required List<ResearchNode> nodes,
  required List<ResearchPrerequisiteLink> links,
}) {
  if (nodes.isEmpty) return ResearchGraphLayout.empty;

  final hierarchy = buildResearchHierarchy(nodes: nodes, links: links);
  final nodeIds = {for (final n in nodes) n.id.value};

  final layers = <int, List<ResearchNode>>{};
  final seenInLayer = <int, Set<String>>{};
  for (final item in hierarchy) {
    final depth = item.depth;
    seenInLayer.putIfAbsent(depth, () => {});
    if (seenInLayer[depth]!.add(item.node.id.value)) {
      layers.putIfAbsent(depth, () => []).add(item.node);
    }
  }

  final edges = <ResearchGraphEdge>[];
  for (final link in links) {
    final from = link.prerequisiteNodeId.value;
    final to = link.nodeId.value;
    if (nodeIds.contains(from) && nodeIds.contains(to)) {
      edges.add(ResearchGraphEdge(fromNodeId: from, toNodeId: to));
    }
  }

  final sortedLayers = layers.keys.toList()..sort();
  final graphNodes = <ResearchGraphNode>[];
  var maxLayerWidth = 0.0;
  var maxBottom = 0.0;

  for (final layer in sortedLayers) {
    final layerNodes = layers[layer]!;
    final layerWidth = layerNodes.length * researchGraphNodeWidth +
        math.max(0, layerNodes.length - 1) * researchGraphNodeSpacing;
    maxLayerWidth = math.max(maxLayerWidth, layerWidth);

    for (var i = 0; i < layerNodes.length; i++) {
      final x = researchGraphPadding +
          i * (researchGraphNodeWidth + researchGraphNodeSpacing);
      final y = researchGraphPadding +
          layer * (researchGraphNodeHeight + researchGraphLayerSpacing);
      graphNodes.add(
        ResearchGraphNode(
          node: layerNodes[i],
          layer: layer,
          indexInLayer: i,
          position: ResearchGraphPosition(x: x, y: y),
        ),
      );
      maxBottom = math.max(maxBottom, y + researchGraphNodeHeight);
    }
  }

  return ResearchGraphLayout(
    nodes: graphNodes,
    edges: edges,
    width: maxLayerWidth + researchGraphPadding * 2,
    height: maxBottom + researchGraphPadding,
  );
}
