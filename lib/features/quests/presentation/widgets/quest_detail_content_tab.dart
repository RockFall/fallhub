import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/quest_providers.dart';
import 'quest_lifecycle_actions.dart';
import 'quest_link_task_sheet.dart';

class QuestDetailContentTab extends ConsumerWidget {
  const QuestDetailContentTab({super.key, required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedTasks = ref.watch(questLinkedTasksProvider(quest.id.value));
    final dateFormat = DateFormat('dd/MM/yyyy');
    final nextTask = linkedTasks.maybeWhen(
      data: (tasks) => tasks.where((t) => t.status.isActive).firstOrNull,
      orElse: () => null,
    );

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        ColonyPanel(
          title: AppStrings.questPurpose,
          icon: Icons.lightbulb_outline,
          child: Text(quest.purpose),
        ),
        const SizedBox(height: ColonySpacing.md),
        if (quest.successCriteria.isNotEmpty)
          ColonyPanel(
            title: AppStrings.questSuccessCriteria,
            icon: Icons.checklist_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: quest.successCriteria
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: ColonySpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(c)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        if (quest.risks.isNotEmpty) ...[
          const SizedBox(height: ColonySpacing.md),
          ColonyPanel(
            title: AppStrings.questRisks,
            icon: Icons.warning_amber_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: quest.risks
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: ColonySpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(r)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        if (quest.deadline != null) ...[
          const SizedBox(height: ColonySpacing.md),
          ColonyPanel(
            title: AppStrings.questDeadline,
            icon: Icons.event_outlined,
            child: Text(dateFormat.format(scheduleCalendarDay(quest.deadline!))),
          ),
        ],
        if (quest.acceptedAt != null) ...[
          const SizedBox(height: ColonySpacing.md),
          ColonyPanel(
            title: AppStrings.questAcceptedAt,
            icon: Icons.verified_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateFormat.format(quest.acceptedAt!.toLocal())),
                if (quest.acceptanceDeadline != null) ...[
                  const SizedBox(height: ColonySpacing.xs),
                  Text(
                    AppStrings.questAcceptanceDeadlineValue(
                      dateFormat.format(
                        scheduleCalendarDay(quest.acceptanceDeadline!),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
        if (quest.acceptanceAssumptions.isNotEmpty) ...[
          const SizedBox(height: ColonySpacing.md),
          ColonyPanel(
            title: AppStrings.questAcceptanceAssumptions,
            icon: Icons.fact_check_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: quest.acceptanceAssumptions
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: ColonySpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(a)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.questNextAction,
          icon: Icons.play_arrow_outlined,
          actions: [
            if (!quest.status.isTerminal)
              IconButton(
                tooltip: AppStrings.questLinkTask,
                icon: const Icon(Icons.link, size: 20),
                onPressed: () => _linkTask(context, ref, quest),
              ),
          ],
          child: nextTask == null
              ? Text(
                  AppStrings.questNoNextAction,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(nextTask.title),
                  subtitle: Text(AppStrings.taskStatusLabel(nextTask.status)),
                  onTap: () => context.go('/tasks/${nextTask.id.value}'),
                ),
        ),
        if (!quest.status.isTerminal) ...[
          const SizedBox(height: ColonySpacing.lg),
          QuestLifecycleActions(quest: quest),
        ],
        if (quest.exitReason != null) ...[
          const SizedBox(height: ColonySpacing.md),
          ColonyPanel(
            title: AppStrings.questExitReason,
            icon: Icons.info_outline,
            child: Text(quest.exitReason!),
          ),
        ],
        if (quest.pauseReason != null && quest.status == QuestStatus.paused) ...[
          const SizedBox(height: ColonySpacing.md),
          ColonyPanel(
            title: AppStrings.questPauseReason,
            icon: Icons.pause_circle_outline,
            child: Text(quest.pauseReason!),
          ),
        ],
      ],
    );
  }

  Future<void> _linkTask(BuildContext context, WidgetRef ref, Quest quest) async {
    final activeTasks = await ref.read(activeTasksProvider.future);
    final unlinked = activeTasks
        .where((t) => t.questId == null || t.questId == quest.id)
        .toList();

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => QuestLinkTaskSheet(
        quest: quest,
        tasks: unlinked,
      ),
    );
  }
}
