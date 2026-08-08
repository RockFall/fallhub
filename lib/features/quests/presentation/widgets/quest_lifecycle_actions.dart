import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/quest_controllers.dart';
import 'accept_quest_sheet.dart';

class QuestLifecycleActions extends ConsumerWidget {
  const QuestLifecycleActions({super.key, required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(questControllerProvider.notifier);

    return Wrap(
      spacing: ColonySpacing.sm,
      runSpacing: ColonySpacing.sm,
      children: [
        if (quest.status == QuestStatus.draft)
          FilledButton(
            onPressed: () => _acceptAndActivate(context, ref, quest),
            child: const Text(AppStrings.questAcceptAndActivate),
          ),
        if (quest.status == QuestStatus.active) ...[
          OutlinedButton(
            onPressed: () => _pause(context, ref, quest),
            child: const Text(AppStrings.questPause),
          ),
          FilledButton(
            onPressed: () => _complete(context, ref, quest),
            child: const Text(AppStrings.questComplete),
          ),
        ],
        if (quest.status == QuestStatus.paused) ...[
          FilledButton(
            onPressed: () => controller.activate(quest),
            child: const Text(AppStrings.questResume),
          ),
          OutlinedButton(
            onPressed: () => _complete(context, ref, quest),
            child: const Text(AppStrings.questComplete),
          ),
        ],
        if (quest.status == QuestStatus.active || quest.status == QuestStatus.paused)
          TextButton(
            onPressed: () => _abandon(context, ref, quest),
            child: const Text(AppStrings.questAbandon),
          ),
      ],
    );
  }

  Future<void> _acceptAndActivate(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
  ) async {
    final prerequisites = await ref
        .read(repositoriesProvider)
        .quests
        .listPrerequisites(quest.id);
    if (!QuestPrerequisitePolicy.canActivate(
      quest: quest,
      prerequisites: prerequisites,
    )) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.questActivateBlockedPrerequisites),
          ),
        );
      }
      return;
    }

    final acceptance = await AcceptQuestSheet.show(
      context,
      initialPurpose: quest.purpose,
    );
    if (acceptance == null || !context.mounted) return;

    await ref.read(questControllerProvider.notifier).acceptAndActivate(
          quest,
          acceptanceAssumptions: acceptance.assumptions,
          acceptanceDeadline: acceptance.deadline,
        );
  }

  Future<void> _pause(BuildContext context, WidgetRef ref, Quest quest) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.questPause),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: AppStrings.questPauseReasonOptional,
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.questPause),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final reason = reasonController.text.trim();
      await ref.read(questControllerProvider.notifier).pause(
            quest,
            reason: reason.isEmpty ? null : reason,
          );
    }
    reasonController.dispose();
  }

  Future<void> _complete(BuildContext context, WidgetRef ref, Quest quest) async {
    if (quest.successCriteria.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.questComplete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.questCompleteCriteriaPrompt),
              const SizedBox(height: ColonySpacing.md),
              ...quest.successCriteria.map((c) => Text('• $c')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.questCompleteConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.questComplete),
          content: const Text(AppStrings.questCompleteNoCriteriaPrompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.questCompleteConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await ref.read(questControllerProvider.notifier).complete(quest);
  }

  Future<void> _abandon(BuildContext context, WidgetRef ref, Quest quest) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.questAbandon),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: AppStrings.questAbandonReasonOptional,
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.questAbandon),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final reason = reasonController.text.trim();
      await ref.read(questControllerProvider.notifier).abandon(
            quest,
            reason: reason.isEmpty ? null : reason,
          );
    }
    reasonController.dispose();
  }
}
