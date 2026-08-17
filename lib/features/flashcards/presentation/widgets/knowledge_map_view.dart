import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';

class KnowledgeMapView extends StatelessWidget {
  const KnowledgeMapView({
    super.key,
    required this.forest,
    required this.heat,
  });

  final List<KnowledgeAreaNode> forest;
  final Map<EntityId, KnowledgeAreaHeat> heat;

  @override
  Widget build(BuildContext context) {
    if (forest.isEmpty) {
      return Text(
        AppStrings.flashcardsMapEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final node in forest) _AreaBranch(node: node, heat: heat, depth: 0),
      ],
    );
  }
}

class _AreaBranch extends StatelessWidget {
  const _AreaBranch({
    required this.node,
    required this.heat,
    required this.depth,
  });

  final KnowledgeAreaNode node;
  final Map<EntityId, KnowledgeAreaHeat> heat;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final stats = heat[node.area.id];
    final color = _heatColor(stats?.retention);
    final tile = ListTile(
      contentPadding: EdgeInsets.only(left: depth * 16.0),
      leading: CircleAvatar(
        radius: 8,
        backgroundColor: color.withValues(alpha: 0.22),
        child: Icon(Icons.circle, size: 8, color: color),
      ),
      title: Text(node.area.title),
      subtitle: Text(
        [
          if (node.descendantCount > 0) '${node.descendantCount} sub',
          if (stats != null) '${stats.cardCount} ${AppStrings.flashcardsCards.toLowerCase()}',
          if (stats != null && stats.dueCount > 0)
            '${stats.dueCount} ${AppStrings.flashcardsDue.toLowerCase()}',
          if (stats?.retention != null)
            '${(stats!.retention! * 100).round()}%',
        ].join(' · '),
      ),
      onTap: () => context.go('/flashcards/areas/${node.area.id.value}'),
    );

    if (node.children.isEmpty) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        for (final child in node.children)
          _AreaBranch(node: child, heat: heat, depth: depth + 1),
      ],
    );
  }

  Color _heatColor(double? retention) {
    if (retention == null) return ColonyColors.statusUnknown;
    if (retention >= 0.85) return ColonyColors.statusGood;
    if (retention >= 0.6) return ColonyColors.statusAttention;
    return ColonyColors.statusRisk;
  }
}
