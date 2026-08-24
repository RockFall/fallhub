import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/feature_controllers.dart';
import '../../activation/application/activation_controllers.dart';
import '../../plan_day/application/plan_day_controller.dart';
import '../../plan_day/application/plan_day_providers.dart';
import '../../plan_day/presentation/widgets/plan_day_feedback.dart';

class TaskInspectScreen extends ConsumerWidget {
  const TaskInspectScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repos = ref.watch(repositoriesProvider);

    return FutureBuilder<ColonyTask?>(
      future: repos.tasks.getById(EntityId(taskId)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final task = snapshot.data;
        if (task == null) {
          return Center(child: Text(AppStrings.errorGeneric));
        }

        final onPlan =
            ref.watch(todayPlanTaskIdsProvider).contains(task.id.value);
        return Padding(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          child: InspectPane(
            title: task.title,
            subtitle: '${AppStrings.status}: ${AppStrings.taskStatusLabel(task.status)}',
            icon: Icons.task_alt_outlined,
            footer: DataProvenanceBadge(
              kind: switch (task.sourceType) {
                SourceType.manual => ProvenanceDisplay.manual,
                SourceType.import => ProvenanceDisplay.imported,
                SourceType.integration => ProvenanceDisplay.integration,
                SourceType.derived => ProvenanceDisplay.inferred,
                SourceType.ai => ProvenanceDisplay.ai,
                SourceType.system => ProvenanceDisplay.manual,
              },
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (task.description != null) Text(task.description!),
                const SizedBox(height: ColonySpacing.lg),
                Wrap(
                  spacing: ColonySpacing.sm,
                  children: [
                    FilledButton.tonal(
                      onPressed: onPlan || !task.status.isTerminal
                          ? () async {
                              await ref
                                  .read(planDayControllerProvider.notifier)
                                  .toggleTaskOnToday(task);
                              if (!context.mounted) return;
                              showPlanDayOpenSnack(
                                context,
                                onPlan
                                    ? AppStrings.planDayRemovedSnack
                                    : AppStrings.planDayAddedSnack,
                              );
                            }
                          : null,
                      child: Text(
                        onPlan
                            ? AppStrings.planDayOnPlanChip
                            : AppStrings.planDayAddToToday,
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        final episode = await ref
                            .read(activationControllerProvider.notifier)
                            .startForTask(taskId: task.id);
                        if (!context.mounted || episode == null) return;
                        context.go(
                          '/activation/episodes/${episode.id.value}',
                        );
                      },
                      child: const Text(AppStrings.activationMobilizeTask),
                    ),
                    FilledButton(
                      onPressed: () => ref
                          .read(taskActionsControllerProvider.notifier)
                          .updateStatus(task, TaskStatus.next),
                      child: const Text(AppStrings.markNext),
                    ),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(taskActionsControllerProvider.notifier)
                          .archive(task),
                      child: const Text(AppStrings.archive),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/inbox'),
                      child: const Text(AppStrings.cancel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
