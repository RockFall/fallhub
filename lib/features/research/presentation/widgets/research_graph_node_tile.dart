import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/research_providers.dart';

class ResearchGraphNodeTile extends ConsumerWidget {
  const ResearchGraphNodeTile({
    super.key,
    required this.graphNode,
    required this.isFocused,
    required this.isSearchMatch,
    required this.hasActiveSearch,
  });

  final ResearchGraphNode graphNode;
  final bool isFocused;
  final bool isSearchMatch;
  final bool hasActiveSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = graphNode.node;
    final activity = ref.watch(researchNodeActivityProvider(node.id.value));
    final dimmed = hasActiveSearch && !isSearchMatch;
    final statusColor = _statusColor(node.status);

    return Opacity(
      opacity: dimmed ? 0.35 : 1,
      child: Material(
        color: isFocused ? ColonyColors.selected : ColonyColors.raised,
        elevation: isFocused ? 4 : 1,
        borderRadius: BorderRadius.circular(ColonySpacing.sm),
        child: InkWell(
          onTap: () => context.go('/research/${node.id.value}'),
          borderRadius: BorderRadius.circular(ColonySpacing.sm),
          child: Container(
            width: researchGraphNodeWidth,
            height: researchGraphNodeHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: ColonySpacing.sm,
              vertical: ColonySpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ColonySpacing.sm),
              border: Border.all(
                color: isFocused ? ColonyColors.accentCyan : statusColor,
                width: isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (isFocused) ...[
                  Icon(Icons.science, size: 16, color: ColonyColors.accentCyan),
                  const SizedBox(width: ColonySpacing.xs),
                ],
                Expanded(
                  child: Text(
                    node.title,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (activity.evidenceCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: ColonySpacing.xs),
                    child: Tooltip(
                      message: AppStrings.researchEvidence,
                      child: Badge(
                        label: Text('${activity.evidenceCount}'),
                        child: const Icon(Icons.fact_check_outlined, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(ResearchNodeStatus status) {
    return switch (status) {
      ResearchNodeStatus.available => ColonyColors.borderSubtle,
      ResearchNodeStatus.inResearch => ColonyColors.accentCyan,
      ResearchNodeStatus.demonstrated => ColonyColors.statusGood,
      ResearchNodeStatus.archived => ColonyColors.textMuted,
    };
  }
}
