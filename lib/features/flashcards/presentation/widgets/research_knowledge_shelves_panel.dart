import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_providers.dart';
import 'link_area_to_research_sheet.dart';

class ResearchKnowledgeShelvesPanel extends ConsumerWidget {
  const ResearchKnowledgeShelvesPanel({super.key, required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(researchKnowledgeShelvesProvider(nodeId));
    final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
    return ColonyPanel(
      title: AppStrings.flashcardsLinkedShelves,
      icon: Icons.account_tree_outlined,
      child: linksAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => Text(AppStrings.errorGeneric),
        data: (links) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (links.isEmpty)
                const Text(AppStrings.flashcardsNoLinkedShelves)
              else
                for (final link in links)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      areas
                          .where((a) => a.id == link.areaId)
                          .map((a) => a.title)
                          .firstOrNull ??
                          link.areaId.value,
                    ),
                    subtitle: Text(
                      AppStrings.researchKnowledgeLinkLabel(link.kind),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => ref
                          .read(flashcardControllerProvider.notifier)
                          .unlinkResearch(
                            researchNodeId: EntityId(nodeId),
                            areaId: link.areaId,
                          ),
                    ),
                    onTap: () =>
                        context.go('/flashcards/areas/${link.areaId.value}'),
                  ),
              TextButton(
                onPressed: () => LinkAreaToResearchSheet.show(
                  context,
                  nodeId: EntityId(nodeId),
                ),
                child: const Text(AppStrings.flashcardsLinkShelf),
              ),
            ],
          );
        },
      ),
    );
  }
}
