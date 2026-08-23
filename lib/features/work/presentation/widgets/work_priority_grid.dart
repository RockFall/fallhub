import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';

class WorkPriorityGrid extends StatelessWidget {
  const WorkPriorityGrid({
    super.key,
    required this.priorities,
    required this.onCycle,
  });

  final List<WorkPriority> priorities;
  final ValueChanged<WorkPriority> onCycle;

  @override
  Widget build(BuildContext context) {
    final sorted = List<WorkPriority>.from(priorities)
      ..sort((a, b) => a.workType.index.compareTo(b.workType.index));

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              flex: 3,
              child: SizedBox.shrink(),
            ),
            Expanded(
              child: Text(
                AppStrings.priorityLevelLabel(PriorityLevel.immediate),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: ColonySpacing.sm),
        ...sorted.map((priority) {
          return Padding(
            padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: priority.workType == WorkType.music
                        ? () => context.go('/research/music-atlas')
                        : null,
                    child: Text(
                      AppStrings.workTypeLabel(priority.workType),
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Expanded(
                  child: PriorityCell(
                    label: AppStrings.priorityLevelLabel(priority.level),
                    selected: priority.level == PriorityLevel.immediate ||
                        priority.level == PriorityLevel.high,
                    onTap: () => onCycle(priority),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
