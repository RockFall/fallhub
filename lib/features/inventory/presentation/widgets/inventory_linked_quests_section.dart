import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../quests/application/quest_providers.dart';
import '../../application/inventory_controllers.dart';
import '../../application/inventory_providers.dart';

class InventoryLinkedQuestsSection extends ConsumerWidget {
  const InventoryLinkedQuestsSection({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = ref.watch(inventoryLinkedQuestsProvider(item.id.value));
    final allQuests = ref.watch(questsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: ColonySpacing.md),
      child: ColonyPanel(
        title: AppStrings.inventoryLinkedQuests,
        icon: Icons.flag_outlined,
        actions: [
          IconButton(
            tooltip: AppStrings.inventoryLinkQuest,
            icon: const Icon(Icons.link, size: 20),
            onPressed: () async {
              final current = linked.maybeWhen(
                data: (quests) => quests,
                orElse: () => const <Quest>[],
              );
              final available = allQuests.maybeWhen(
                data: (quests) => quests
                    .where(
                      (q) =>
                          !q.status.isTerminal &&
                          !current.any((c) => c.id == q.id),
                    )
                    .toList(),
                orElse: () => const <Quest>[],
              );
              if (available.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.inventoryQuestPickerEmpty),
                  ),
                );
                return;
              }
              final selected = await showDialog<Quest>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text(AppStrings.inventoryLinkQuest),
                  children: available
                      .map(
                        (quest) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, quest),
                          child: Text(quest.title),
                        ),
                      )
                      .toList(),
                ),
              );
              if (selected == null) return;
              await ref.read(inventoryControllerProvider.notifier).linkQuest(
                    inventoryItemId: item.id,
                    questId: selected.id,
                  );
            },
          ),
        ],
        child: linked.when(
          loading: () => const Text(AppStrings.loading),
          error: (_, __) => const Text(AppStrings.errorGeneric),
          data: (quests) {
            if (quests.isEmpty) {
              return Text(
                AppStrings.inventoryNoLinkedQuests,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: quests
                  .map(
                    (quest) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(quest.title),
                      trailing: IconButton(
                        tooltip: AppStrings.inventoryUnlinkQuest,
                        icon: const Icon(Icons.link_off, size: 20),
                        onPressed: () => ref
                            .read(inventoryControllerProvider.notifier)
                            .unlinkQuest(
                              inventoryItemId: item.id,
                              questId: quest.id,
                            ),
                      ),
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
