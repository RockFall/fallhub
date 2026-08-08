import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';

class ResearchHierarchyList extends StatelessWidget {
  const ResearchHierarchyList({
    super.key,
    required this.hierarchy,
  });

  final List<ResearchHierarchyNode> hierarchy;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hierarchy.length,
      separatorBuilder: (_, __) => const SizedBox(height: ColonySpacing.xs),
      itemBuilder: (context, index) {
        final item = hierarchy[index];
        final node = item.node;
        return InkWell(
          onTap: () => context.go('/research/${node.id.value}'),
          borderRadius: BorderRadius.circular(ColonySpacing.sm),
          child: Padding(
            padding: EdgeInsets.only(
              left: item.depth * ColonySpacing.lg.toDouble(),
              top: ColonySpacing.sm,
              bottom: ColonySpacing.sm,
              right: ColonySpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    node.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Chip(
                  label: Text(
                    AppStrings.researchStatusLabel(node.status),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
