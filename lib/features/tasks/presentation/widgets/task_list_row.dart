import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/task_controller.dart';
import '../../application/task_providers.dart';

class TaskListRow extends ConsumerWidget {
  const TaskListRow({super.key, required this.task});

  final ColonyTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();
    final overdue = TaskCapabilityPolicy.isOverdue(task, now);
    final progress = ref.watch(taskChildProgressProvider(task.id.value));
    final done = task.status == TaskStatus.done;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: ColonySpacing.sm),
      leading: Checkbox(
        value: done,
        onChanged: (_) =>
            ref.read(taskBacklogControllerProvider.notifier).toggleDone(task),
      ),
      title: Text(
        task.title,
        style: text.bodyMedium?.copyWith(
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? ColonyColors.textMuted : ColonyColors.textPrimary,
        ),
      ),
      subtitle: _subtitle(overdue, progress) == null
          ? null
          : Text(
              _subtitle(overdue, progress)!,
              style: text.labelSmall?.copyWith(
                color: overdue ? ColonyColors.statusRisk : ColonyColors.textMuted,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.priority != TaskPriority.none)
            Padding(
              padding: const EdgeInsets.only(right: ColonySpacing.sm),
              child: Text(
                AppStrings.taskPriorityLabel(task.priority),
                style: text.labelSmall?.copyWith(
                  color: ColonyColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
      onTap: () => context.go('/tasks/${task.id.value}'),
    );
  }

  String? _subtitle(bool overdue, (int, int) progress) {
    final bits = <String>[];
    if (overdue) bits.add(AppStrings.taskOverdue);
    if (task.dueAt != null) {
      bits.add('${AppStrings.taskDeadline} ${AppStrings.taskDateLabel(task.dueAt!)}');
    } else if (task.scheduledStart != null) {
      bits.add(
        '${AppStrings.taskForDate} ${AppStrings.taskDateLabel(task.scheduledStart!)}',
      );
    }
    if (progress.$2 > 0) {
      bits.add(AppStrings.taskSubtaskProgress(progress.$1, progress.$2));
    }
    if (bits.isEmpty) return null;
    return bits.join(' · ');
  }
}
