import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/research_controllers.dart';
import '../../application/research_providers.dart';
import 'quest_picker_sheet.dart';

class ResearchLinkedQuestsPanel extends ConsumerWidget {
  const ResearchLinkedQuestsPanel({super.key, required this.node});

  final ResearchNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedQuests = ref.watch(researchLinkedQuestsProvider(node.id.value));

    return ColonyPanel(
      title: AppStrings.researchLinkedQuests,
      icon: Icons.flag_outlined,
      actions: [
        IconButton(
          tooltip: AppStrings.researchLinkQuest,
          icon: const Icon(Icons.link, size: 20),
          onPressed: () async {
            final current = linkedQuests.maybeWhen(
              data: (quests) => quests,
              orElse: () => const <Quest>[],
            );
            final selected = await QuestPickerSheet.show(
              context,
              selectedQuestIds: current.map((q) => q.id).toList(),
            );
            if (selected == null) return;
            await ref
                .read(researchControllerProvider.notifier)
                .setLinkedQuests(node, selected);
          },
        ),
      ],
      child: linkedQuests.when(
        loading: () => Text(AppStrings.loading),
        error: (_, __) => Text(AppStrings.errorGeneric),
        data: (quests) {
          if (quests.isEmpty) {
            return Text(
              AppStrings.researchNoLinkedQuests,
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }
          return Column(
            children: quests
                .map(
                  (quest) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(quest.title),
                    subtitle: Text(AppStrings.questStatusLabel(quest.status)),
                    trailing: IconButton(
                      tooltip: AppStrings.researchUnlinkQuest,
                      icon: const Icon(Icons.link_off, size: 20),
                      onPressed: () => ref
                          .read(researchControllerProvider.notifier)
                          .unlinkQuest(node: node, questId: quest.id),
                    ),
                    onTap: () => context.go('/quests/${quest.id.value}'),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
