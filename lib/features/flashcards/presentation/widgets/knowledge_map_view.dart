import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import 'knowledge_area_icons.dart';

enum KnowledgeMapFilter { all, due, fragile }

class KnowledgeMapView extends StatefulWidget {
  const KnowledgeMapView({
    super.key,
    required this.forest,
    required this.heat,
    this.placements = const [],
    this.filter = KnowledgeMapFilter.all,
  });

  final List<KnowledgeAreaNode> forest;
  final Map<EntityId, KnowledgeAreaHeat> heat;
  final List<KnowledgeAreaPlacement> placements;
  final KnowledgeMapFilter filter;

  @override
  State<KnowledgeMapView> createState() => _KnowledgeMapViewState();
}

class _KnowledgeMapViewState extends State<KnowledgeMapView> {
  final _collapsedRoots = <EntityId>{};
  final _expanded = <EntityId>{};

  bool _matches(KnowledgeAreaNode node) {
    final stats = widget.heat[node.area.id];
    final self = switch (widget.filter) {
      KnowledgeMapFilter.all => true,
      KnowledgeMapFilter.due => (stats?.dueCount ?? 0) > 0,
      KnowledgeMapFilter.fragile =>
        stats?.retention != null && stats!.retention! < 0.6,
    };
    if (self) return true;
    return node.children.any(_matches);
  }

  bool _isExpanded(KnowledgeAreaNode node, int depth) {
    if (widget.filter != KnowledgeMapFilter.all) return true;
    if (depth == 0) return !_collapsedRoots.contains(node.area.id);
    return _expanded.contains(node.area.id);
  }

  void _toggle(KnowledgeAreaNode node, int depth) {
    setState(() {
      if (depth == 0) {
        if (!_collapsedRoots.add(node.area.id)) {
          _collapsedRoots.remove(node.area.id);
        }
      } else if (!_expanded.add(node.area.id)) {
        _expanded.remove(node.area.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forest.isEmpty) {
      return Text(
        AppStrings.flashcardsMapEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final roots = widget.forest.where(_matches).toList();
    if (roots.isEmpty) {
      return Text(
        AppStrings.flashcardsNoResults,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final node in roots)
          _AreaBranch(
            node: node,
            heat: widget.heat,
            placements: widget.placements,
            depth: 0,
            matches: _matches,
            isExpanded: _isExpanded,
            onToggle: _toggle,
          ),
      ],
    );
  }
}

class _AreaBranch extends StatelessWidget {
  const _AreaBranch({
    required this.node,
    required this.heat,
    required this.placements,
    required this.depth,
    required this.matches,
    required this.isExpanded,
    required this.onToggle,
  });

  final KnowledgeAreaNode node;
  final Map<EntityId, KnowledgeAreaHeat> heat;
  final List<KnowledgeAreaPlacement> placements;
  final int depth;
  final bool Function(KnowledgeAreaNode node) matches;
  final bool Function(KnowledgeAreaNode node, int depth) isExpanded;
  final void Function(KnowledgeAreaNode node, int depth) onToggle;

  @override
  Widget build(BuildContext context) {
    final stats = heat[node.area.id];
    final visibleChildren = node.children.where(matches).toList();
    final expanded = isExpanded(node, depth);
    final bridged = KnowledgeAreaPolicy.hasSecondaryPlacement(
      areaId: node.area.id,
      placements: placements,
    );
    final tile = ListTile(
      contentPadding: EdgeInsets.only(left: depth * 12.0),
      leading: ColonyHeatDot(retention: stats?.retention),
      title: Row(
        children: [
          Icon(KnowledgeAreaIcons.of(node.area.iconKey), size: 16),
          const SizedBox(width: ColonySpacing.sm),
          Expanded(child: Text(node.area.title)),
        ],
      ),
      subtitle: Text(
        [
          if (node.descendantCount > 0) '${node.descendantCount} sub',
          if (stats != null)
            '${stats.cardCount} ${AppStrings.flashcardsCards.toLowerCase()}',
          if (stats != null && stats.dueCount > 0)
            '${stats.dueCount} ${AppStrings.flashcardsDue.toLowerCase()}',
          if (stats?.retention != null)
            '${(stats!.retention! * 100).round()}%',
          if (bridged) AppStrings.flashcardsHasBridge,
        ].join(' · '),
      ),
      trailing: visibleChildren.isEmpty
          ? const Icon(Icons.chevron_right)
          : IconButton(
              tooltip: expanded
                  ? AppStrings.flashcardsMapCollapse
                  : AppStrings.flashcardsMapExpand,
              onPressed: () => onToggle(node, depth),
              icon: Icon(expanded ? Icons.expand_more : Icons.chevron_right),
            ),
      onTap: () => context.go('/flashcards/areas/${node.area.id.value}'),
    );

    if (visibleChildren.isEmpty || !expanded) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        for (final child in visibleChildren)
          _AreaBranch(
            node: child,
            heat: heat,
            placements: placements,
            depth: depth + 1,
            matches: matches,
            isExpanded: isExpanded,
            onToggle: onToggle,
          ),
      ],
    );
  }
}
