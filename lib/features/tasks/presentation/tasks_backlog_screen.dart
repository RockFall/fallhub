import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/task_providers.dart';
import 'widgets/task_composer.dart';
import 'widgets/task_list_row.dart';

class TasksBacklogScreen extends ConsumerWidget {
  const TasksBacklogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(taskBacklogViewProvider);
    final sectionsAsync = ref.watch(taskBacklogSectionsProvider);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ColonySpacing.lg,
            ColonySpacing.lg,
            ColonySpacing.lg,
            ColonySpacing.sm,
          ),
          child: Text(AppStrings.tasksTitle, style: text.headlineMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ColonySpacing.md),
          child: Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.sm,
            children: [
              _FilterChip(
                label: AppStrings.tasksFilterOpen,
                selected: view.filter == TaskBacklogFilter.open,
                onSelected: () => ref
                    .read(taskBacklogViewProvider.notifier)
                    .setFilter(TaskBacklogFilter.open),
              ),
              _FilterChip(
                label: AppStrings.tasksFilterDeadline,
                selected: view.filter == TaskBacklogFilter.deadline,
                onSelected: () => ref
                    .read(taskBacklogViewProvider.notifier)
                    .setFilter(TaskBacklogFilter.deadline),
              ),
              _FilterChip(
                label: AppStrings.tasksFilterNoDate,
                selected: view.filter == TaskBacklogFilter.noDate,
                onSelected: () => ref
                    .read(taskBacklogViewProvider.notifier)
                    .setFilter(TaskBacklogFilter.noDate),
              ),
              _FilterChip(
                label: AppStrings.tasksFilterDone,
                selected: view.filter == TaskBacklogFilter.done,
                onSelected: () => ref
                    .read(taskBacklogViewProvider.notifier)
                    .setFilter(TaskBacklogFilter.done),
              ),
              _FilterChip(
                label: AppStrings.tasksGroupByProject,
                selected: view.groupByProject,
                onSelected: () => ref
                    .read(taskBacklogViewProvider.notifier)
                    .toggleGroupByProject(),
              ),
            ],
          ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Expanded(
          child: sectionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
            data: (sections) {
              final isEmpty = sections.every((section) => section.tasks.isEmpty);
              if (isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(ColonySpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        view.filter == TaskBacklogFilter.done
                            ? AppStrings.tasksEmptyDone
                            : AppStrings.tasksEmpty,
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          color: ColonyColors.textMuted,
                        ),
                      ),
                      if (view.filter != TaskBacklogFilter.done) ...[
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.tasksEmptyHint,
                          textAlign: TextAlign.center,
                          style: text.bodySmall?.copyWith(
                            color: ColonyColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: ColonySpacing.sm,
                ),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  if (section.title.isEmpty) {
                    return Column(
                      children: [
                        for (final task in section.tasks) TaskListRow(task: task),
                      ],
                    );
                  }
                  return ColonyPanel(
                    title: section.title,
                    child: Column(
                      children: [
                        for (final task in section.tasks) TaskListRow(task: task),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (view.filter != TaskBacklogFilter.done) const TaskComposer(),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}
