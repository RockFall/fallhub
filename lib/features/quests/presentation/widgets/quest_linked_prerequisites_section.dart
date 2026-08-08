import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/quest_controllers.dart';
import '../../application/quest_providers.dart';
import 'quest_prerequisite_picker.dart';

class QuestLinkedPrerequisitesSection extends ConsumerWidget {
  const QuestLinkedPrerequisitesSection({super.key, required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prerequisites = ref.watch(questPrerequisitesProvider(quest.id.value));

    return Padding(
      padding: const EdgeInsets.only(top: ColonySpacing.md),
      child: ColonyPanel(
        title: AppStrings.questLinkedPrerequisites,
        icon: Icons.linear_scale,
        actions: [
          if (!quest.status.isTerminal)
            IconButton(
              tooltip: AppStrings.questLinkPrerequisite,
              icon: const Icon(Icons.link, size: 20),
              onPressed: () async {
                final current = prerequisites.maybeWhen(
                  data: (items) => items,
                  orElse: () => const <Quest>[],
                );
                final selected = await QuestPrerequisitePickerSheet.show(
                  context,
                  questId: quest.id.value,
                  selectedPrerequisiteIds: current.map((q) => q.id).toList(),
                );
                if (selected == null) return;
                await ref
                    .read(questControllerProvider.notifier)
                    .setPrerequisites(quest, selected);
              },
            ),
        ],
        child: prerequisites.when(
          loading: () => Text(AppStrings.loading),
          error: (_, __) => Text(AppStrings.errorGeneric),
          data: (items) {
            if (items.isEmpty) {
              return Text(
                AppStrings.questNoLinkedPrerequisites,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: items
                  .map(
                    (prereq) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(prereq.title),
                      subtitle: Text(
                        AppStrings.questStatusLabel(prereq.status),
                      ),
                      trailing: quest.status.isTerminal
                          ? null
                          : IconButton(
                              tooltip: AppStrings.questUnlinkPrerequisite,
                              icon: const Icon(Icons.link_off, size: 20),
                              onPressed: () => ref
                                  .read(questControllerProvider.notifier)
                                  .unlinkPrerequisite(quest, prereq.id),
                            ),
                      onTap: () => context.go('/quests/${prereq.id.value}'),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
