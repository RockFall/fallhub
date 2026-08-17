import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/flashcard_providers.dart';
import 'widgets/create_flashcard_deck_sheet.dart';
import 'widgets/create_knowledge_area_sheet.dart';

class KnowledgeAreaScreen extends ConsumerWidget {
  const KnowledgeAreaScreen({super.key, required this.areaId});

  final String areaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(knowledgeAreaProvider(areaId));
    final forest = ref.watch(knowledgeForestProvider);
    final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
    final decks = ref.watch(flashcardDecksProvider).asData?.value ?? const [];
    final heat = ref.watch(flashcardHeatProvider)[area?.id];

    if (area == null) {
      return Center(child: Text(AppStrings.flashcardsNotFound));
    }

    final node = _findNode(forest, area.id);
    final children = node?.children.map((c) => c.area).toList() ?? const [];
    final areaDecks =
        decks.where((d) => !d.isArchived && d.areaId == area.id).toList();
    final path = KnowledgeAreaPolicy.pathLabel(areaId: area.id, areas: areas);

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/flashcards'),
            ),
            Expanded(
              child: Text(
                area.title,
                style: Theme.of(context).textTheme.headlineSmall,
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
        if (path.isNotEmpty)
          Text(
            path,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ColonyColors.textMuted,
                ),
          ),
        if (area.description != null)
          Text(
            area.description!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        const SizedBox(height: ColonySpacing.md),
        if (heat != null)
          Text(
            '${AppStrings.flashcardsCards}: ${heat.cardCount} · '
            '${AppStrings.flashcardsDue}: ${heat.dueCount}'
            '${heat.retention == null ? '' : ' · ${(heat.retention! * 100).round()}%'}',
          ),
        const SizedBox(height: ColonySpacing.md),
        FilledButton.icon(
          onPressed: () => context.go('/flashcards/study?areaId=$areaId'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(AppStrings.flashcardsStudyArea),
        ),
        const SizedBox(height: ColonySpacing.lg),
        Row(
          children: [
            Text(
              AppStrings.flashcardsSubareas,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              onPressed: () =>
                  CreateKnowledgeAreaSheet.show(context, parentId: area.id),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (children.isEmpty)
          Text(AppStrings.flashcardsMapEmpty)
        else
          for (final child in children)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(child.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/flashcards/areas/${child.id.value}'),
            ),
        const SizedBox(height: ColonySpacing.lg),
        Row(
          children: [
            Text(
              AppStrings.flashcardsDecksTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  CreateFlashcardDeckSheet.show(context, areaId: area.id),
              child: const Text(AppStrings.flashcardsNewDeck),
            ),
          ],
        ),
        if (areaDecks.isEmpty)
          Text(AppStrings.flashcardsNoDecks)
        else
          for (final deck in areaDecks)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(deck.title),
              onTap: () => context.go('/flashcards/decks/${deck.id.value}'),
            ),
      ],
    );
  }

  KnowledgeAreaNode? _findNode(List<KnowledgeAreaNode> nodes, EntityId id) {
    for (final node in nodes) {
      if (node.area.id == id) return node;
      final found = _findNode(node.children, id);
      if (found != null) return found;
    }
    return null;
  }
}
