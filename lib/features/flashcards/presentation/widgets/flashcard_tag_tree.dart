import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';

class FlashcardTagTree extends StatelessWidget {
  const FlashcardTagTree({
    super.key,
    required this.forest,
    required this.cardCountByTag,
  });

  final List<FlashcardTagNode> forest;
  final Map<EntityId, int> cardCountByTag;

  @override
  Widget build(BuildContext context) {
    if (forest.isEmpty) {
      return Text(
        AppStrings.flashcardsTagsEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final node in forest)
          _TagBranch(
            node: node,
            cardCountByTag: cardCountByTag,
            depth: 0,
          ),
      ],
    );
  }
}

class _TagBranch extends StatelessWidget {
  const _TagBranch({
    required this.node,
    required this.cardCountByTag,
    required this.depth,
  });

  final FlashcardTagNode node;
  final Map<EntityId, int> cardCountByTag;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final count = cardCountByTag[node.tag.id] ?? 0;
    final tile = ListTile(
      contentPadding: EdgeInsets.only(left: depth * 12.0),
      leading: const Icon(Icons.label_outline),
      title: Text(node.tag.title),
      subtitle: Text(
        [
          '$count ${AppStrings.flashcardsCards.toLowerCase()}',
          if (node.descendantCount > 0)
            '${node.descendantCount} ${AppStrings.flashcardsSubtags.toLowerCase()}',
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/flashcards/tags/${node.tag.id.value}'),
    );
    if (node.children.isEmpty) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        for (final child in node.children)
          _TagBranch(
            node: child,
            cardCountByTag: cardCountByTag,
            depth: depth + 1,
          ),
      ],
    );
  }
}
