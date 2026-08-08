import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/research_providers.dart';
import 'research_graph_node_tile.dart';

class ResearchGraphView extends ConsumerWidget {
  const ResearchGraphView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(researchGraphLayoutProvider);
    final showDependencies = ref.watch(researchShowDependenciesProvider);
    final focus = ref.watch(activeResearchFocusProvider);
    final searchQuery = ref.watch(researchSearchQueryProvider);
    final matchIds = ref.watch(researchSearchMatchIdsProvider);
    final hasActiveSearch = searchQuery.trim().isNotEmpty;

    if (layout.nodes.isEmpty) {
      return Center(
        child: Text(
          AppStrings.researchGraphEmpty,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (hasActiveSearch && matchIds.isEmpty) {
      return Center(
        child: Text(
          AppStrings.researchSearchNoResults,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    final focusId = focus?.id.value;
    final positionsById = {
      for (final node in layout.nodes) node.node.id.value: node,
    };

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.researchGraphFocusHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                ),
              ),
              FilterChip(
                label: Text(AppStrings.researchShowDependencies),
                selected: showDependencies,
                onSelected: (value) {
                  ref.read(researchShowDependenciesProvider.notifier).set(value);
                },
              ),
            ],
          ),
          const SizedBox(height: ColonySpacing.sm),
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(ColonySpacing.xl),
              minScale: 0.4,
              maxScale: 2.5,
              child: SizedBox(
                width: layout.width,
                height: layout.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (showDependencies)
                      CustomPaint(
                        size: Size(layout.width, layout.height),
                        painter: _ResearchGraphEdgesPainter(
                          layout: layout,
                          positionsById: positionsById,
                          dimmedNodeIds: hasActiveSearch
                              ? layout.nodes
                                  .map((n) => n.node.id.value)
                                  .where((id) => !matchIds.contains(id))
                                  .toSet()
                              : const {},
                        ),
                      ),
                    for (final graphNode in layout.nodes)
                      Positioned(
                        left: graphNode.position.x,
                        top: graphNode.position.y,
                        child: ResearchGraphNodeTile(
                          graphNode: graphNode,
                          isFocused: graphNode.node.id.value == focusId,
                          isSearchMatch:
                              matchIds.contains(graphNode.node.id.value),
                          hasActiveSearch: hasActiveSearch,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResearchGraphEdgesPainter extends CustomPainter {
  _ResearchGraphEdgesPainter({
    required this.layout,
    required this.positionsById,
    required this.dimmedNodeIds,
  });

  final ResearchGraphLayout layout;
  final Map<String, ResearchGraphNode> positionsById;
  final Set<String> dimmedNodeIds;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ColonyColors.borderSubtle
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = ColonyColors.borderSubtle
      ..style = PaintingStyle.fill;

    for (final edge in layout.edges) {
      final from = positionsById[edge.fromNodeId];
      final to = positionsById[edge.toNodeId];
      if (from == null || to == null) continue;

      final dimmed = dimmedNodeIds.contains(edge.fromNodeId) ||
          dimmedNodeIds.contains(edge.toNodeId);
      paint.color = dimmed
          ? ColonyColors.borderSubtle.withValues(alpha: 0.25)
          : ColonyColors.borderSubtle;
      arrowPaint.color = paint.color;

      final start = Offset(
        from.position.x + researchGraphNodeWidth / 2,
        from.position.y + researchGraphNodeHeight,
      );
      final end = Offset(
        to.position.x + researchGraphNodeWidth / 2,
        to.position.y,
      );

      canvas.drawLine(start, end, paint);

      const arrowSize = 6.0;
      final path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(end.dx - arrowSize, end.dy - arrowSize)
        ..lineTo(end.dx + arrowSize, end.dy - arrowSize)
        ..close();
      canvas.drawPath(path, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ResearchGraphEdgesPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.dimmedNodeIds != dimmedNodeIds;
  }
}
