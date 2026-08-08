import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../research/application/research_providers.dart';
import '../../../research/presentation/widgets/research_node_picker_sheet.dart';
import '../../application/quest_controllers.dart';

class QuestLinkedResearchSection extends ConsumerWidget {
  const QuestLinkedResearchSection({super.key, required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedResearch =
        ref.watch(questLinkedResearchProvider(quest.id.value));

    return Padding(
      padding: const EdgeInsets.only(top: ColonySpacing.md),
      child: ColonyPanel(
        title: AppStrings.questLinkedResearch,
        icon: Icons.science_outlined,
        actions: [
          if (!quest.status.isTerminal)
            IconButton(
              tooltip: AppStrings.questLinkResearch,
              icon: const Icon(Icons.link, size: 20),
              onPressed: () async {
                final current = linkedResearch.maybeWhen(
                  data: (nodes) => nodes,
                  orElse: () => const <ResearchNode>[],
                );
                final selected = await ResearchNodePickerSheet.show(
                  context,
                  selectedNodeIds: current.map((n) => n.id).toList(),
                );
                if (selected == null) return;
                await ref
                    .read(questControllerProvider.notifier)
                    .setLinkedResearch(quest, selected);
              },
            ),
        ],
        child: linkedResearch.when(
          loading: () => Text(AppStrings.loading),
          error: (_, __) => Text(AppStrings.errorGeneric),
          data: (nodes) {
            if (nodes.isEmpty) {
              return Text(
                AppStrings.questNoLinkedResearch,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: nodes
                  .map(
                    (node) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(node.title),
                      subtitle: node.description == null
                          ? null
                          : Text(node.description!, maxLines: 2),
                      trailing: quest.status.isTerminal
                          ? null
                          : IconButton(
                              tooltip: AppStrings.questUnlinkResearch,
                              icon: const Icon(Icons.link_off, size: 20),
                              onPressed: () => ref
                                  .read(questControllerProvider.notifier)
                                  .unlinkResearch(quest, node.id),
                            ),
                      onTap: () => context.go('/research/${node.id.value}'),
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
