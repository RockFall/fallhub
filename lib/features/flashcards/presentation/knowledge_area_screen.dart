import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../research/application/research_providers.dart';
import '../application/flashcard_controllers.dart';
import '../application/flashcard_providers.dart';
import 'widgets/create_flashcard_deck_sheet.dart';
import 'widgets/create_knowledge_area_sheet.dart';
import 'widgets/flashcard_retention_chip.dart';
import 'widgets/link_research_sheet.dart';
import 'widgets/place_knowledge_area_sheet.dart';

class KnowledgeAreaScreen extends ConsumerWidget {
  const KnowledgeAreaScreen({
    super.key,
    required this.areaId,
    this.viaAreaId,
  });

  final String areaId;
  final String? viaAreaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(knowledgeAreaProvider(areaId));
    final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
    final placements =
        ref.watch(knowledgePlacementsProvider).asData?.value ?? const [];
    final decks = ref.watch(flashcardDecksProvider).asData?.value ?? const [];
    final heat = ref.watch(flashcardHeatProvider)[area?.id];
    final links =
        ref.watch(researchKnowledgeLinksProvider).asData?.value ?? const [];
    final nodes = ref.watch(researchNodesProvider).asData?.value ?? const [];

    if (area == null) {
      return Center(child: Text(AppStrings.flashcardsNotFound));
    }

    final children = KnowledgeAreaPolicy.childrenOf(
      parentId: area.id,
      areas: areas,
      placements: placements,
    )..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    final descendantIds = KnowledgeAreaPolicy.descendantIds(
      rootId: area.id,
      areas: areas,
      placements: placements,
    );
    final areaDecks = decks
        .where(
          (d) =>
              !d.isArchived &&
              d.areaId != null &&
              descendantIds.contains(d.areaId),
        )
        .toList();
    final viaAlias = viaAreaId != null &&
        KnowledgeAreaPolicy.isAliasUnder(
          areaId: area.id,
          parentId: EntityId(viaAreaId!),
          areas: areas,
          placements: placements,
        );
    final ancestors = [
      ...KnowledgeAreaPolicy.ancestorsOf(
        areaId: viaAlias ? EntityId(viaAreaId!) : area.id,
        byId: {for (final item in areas) item.id: item},
      ).reversed,
      if (viaAlias) area,
    ];
    final extraParents = KnowledgeAreaPolicy.extraParentsOf(
      areaId: area.id,
      areas: areas,
      placements: placements,
    );
    final linked = links.where((l) => l.areaId == area.id).toList();

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (viaAreaId != null) {
                  context.go('/flashcards/areas/$viaAreaId');
                } else if (area.parentId != null) {
                  context.go('/flashcards/areas/${area.parentId!.value}');
                } else {
                  context.go('/flashcards');
                }
              },
            ),
            Expanded(
              child: Text(
                area.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: AppStrings.flashcardsEditArea,
              onPressed: () => CreateKnowledgeAreaSheet.show(
                context,
                existing: area,
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        if (ancestors.isNotEmpty)
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < ancestors.length; i++) ...[
                if (i > 0)
                  Text(
                    '·',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ColonyColors.textMuted,
                        ),
                  ),
                InkWell(
                  onTap: ancestors[i].id == area.id
                      ? null
                      : () => context.go(
                            '/flashcards/areas/${ancestors[i].id.value}',
                          ),
                  child: Text(
                    ancestors[i].title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ancestors[i].id == area.id
                              ? ColonyColors.textPrimary
                              : ColonyColors.accentCyan,
                        ),
                  ),
                ),
              ],
            ],
          ),
        if (area.description != null) ...[
          const SizedBox(height: ColonySpacing.sm),
          Text(area.description!),
        ],
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.flashcardsHeroToday,
          icon: Icons.insights_outlined,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${heat?.cardCount ?? 0} ${AppStrings.flashcardsCards.toLowerCase()}'
                  ' · ${heat?.dueCount ?? 0} ${AppStrings.flashcardsDue.toLowerCase()}',
                ),
              ),
              FlashcardRetentionChip(retention: heat?.retention),
            ],
          ),
        ),
        const SizedBox(height: ColonySpacing.md),
        FilledButton.icon(
          onPressed: () => context.go('/flashcards/study?areaId=$areaId'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(AppStrings.flashcardsStudyArea),
        ),
        const SizedBox(height: ColonySpacing.sm),
        OutlinedButton.icon(
          onPressed: () =>
              context.go('/flashcards/study?areaId=$areaId&mode=practice'),
          icon: const Icon(Icons.bolt_outlined),
          label: const Text(AppStrings.flashcardsPracticeArea),
        ),
        if (extraParents.isNotEmpty) ...[
          const SizedBox(height: ColonySpacing.md),
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                AppStrings.flashcardsAlsoIn,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              for (final parent in extraParents)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => context.go(
                        '/flashcards/areas/${parent.id.value}',
                      ),
                      child: Text(
                        KnowledgeAreaPolicy.pathLabel(
                          areaId: parent.id,
                          areas: areas,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.flashcardsRemovePlacement,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => ref
                          .read(flashcardControllerProvider.notifier)
                          .removePlacement(
                            areaId: area.id,
                            parentAreaId: parent.id,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        const SizedBox(height: ColonySpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => PlaceKnowledgeAreaSheet.show(context, area: area),
            icon: const Icon(Icons.account_tree_outlined, size: 18),
            label: const Text(AppStrings.flashcardsAddPlacement),
          ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.flashcardsSubareas,
          icon: Icons.account_tree_outlined,
          actions: [
            TextButton(
              onPressed: () =>
                  CreateKnowledgeAreaSheet.show(context, parentId: area.id),
              child: const Text(AppStrings.flashcardsNewLeafHere),
            ),
            IconButton(
              onPressed: () =>
                  CreateKnowledgeAreaSheet.show(context, parentId: area.id),
              icon: const Icon(Icons.add),
            ),
          ],
          child: children.isEmpty
              ? const Text(AppStrings.flashcardsSubareasEmpty)
              : Column(
                  children: [
                    for (final child in children)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(child.title),
                        subtitle: KnowledgeAreaPolicy.isAliasUnder(
                          areaId: child.id,
                          parentId: area.id,
                          areas: areas,
                          placements: placements,
                        )
                            ? const Text(AppStrings.flashcardsAliasShortcut)
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final alias = KnowledgeAreaPolicy.isAliasUnder(
                            areaId: child.id,
                            parentId: area.id,
                            areas: areas,
                            placements: placements,
                          );
                          final via = alias ? '?via=$areaId' : '';
                          context.go(
                            '/flashcards/areas/${child.id.value}$via',
                          );
                        },
                      ),
                  ],
                ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.flashcardsDecksTitle,
          icon: Icons.style_outlined,
          actions: [
            TextButton(
              onPressed: () =>
                  CreateFlashcardDeckSheet.show(context, areaId: area.id),
              child: const Text(AppStrings.flashcardsNewDeck),
            ),
          ],
          child: areaDecks.isEmpty
              ? const Text(AppStrings.flashcardsNoDecks)
              : Column(
                  children: [
                    for (final deck in areaDecks)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(deck.title),
                        onTap: () =>
                            context.go('/flashcards/decks/${deck.id.value}'),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.flashcardsLinkedResearch,
          icon: Icons.science_outlined,
          actions: [
            TextButton(
              onPressed: () => LinkResearchSheet.show(context, area: area),
              child: const Text(AppStrings.flashcardsLinkResearch),
            ),
          ],
          child: linked.isEmpty
              ? const Text(AppStrings.flashcardsLinkedResearchEmpty)
              : Column(
                  children: [
                    for (final kind in ResearchKnowledgeLinkKind.values) ...[
                      if (linked.any((l) => l.kind == kind))
                        Padding(
                          padding: const EdgeInsets.only(bottom: ColonySpacing.xs),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppStrings.researchKnowledgeLinkLabel(kind),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                      for (final link in linked.where((l) => l.kind == kind))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            nodes
                                .where((n) => n.id == link.researchNodeId)
                                .map((n) => n.title)
                                .firstOrNull ??
                                link.researchNodeId.value,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => ref
                                .read(flashcardControllerProvider.notifier)
                                .unlinkResearch(
                                  researchNodeId: link.researchNodeId,
                                  areaId: area.id,
                                ),
                          ),
                          onTap: () => context.go(
                            '/research/${link.researchNodeId.value}',
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
