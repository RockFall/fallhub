import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/flashcard_providers.dart';
import 'widgets/create_flashcard_deck_sheet.dart';
import 'widgets/create_knowledge_area_sheet.dart';
import 'widgets/flashcard_due_hero.dart';
import 'widgets/knowledge_map_view.dart';
import 'widgets/seed_knowledge_catalog_sheet.dart';

class FlashcardsHubScreen extends ConsumerWidget {
  const FlashcardsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(flashcardQueueCountsProvider);
    final forest = ref.watch(knowledgeForestProvider);
    final heat = ref.watch(flashcardHeatProvider);
    final decksAsync = ref.watch(flashcardDecksProvider);
    final cardsAsync = ref.watch(flashcardsProvider);
    final query = ref.watch(flashcardSearchQueryProvider);
    final forecast = ref.watch(flashcardForecastProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: ListView(
        children: [
          FlashcardDueHero(
            counts: counts,
            onStudy: () => context.go('/flashcards/study'),
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.flashcardsDisclaimer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColonyColors.textMuted,
                ),
          ),
          const SizedBox(height: ColonySpacing.lg),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: AppStrings.flashcardsSearchHint,
            ),
            onChanged: ref.read(flashcardSearchQueryProvider.notifier).set,
          ),
          const SizedBox(height: ColonySpacing.lg),
          Row(
            children: [
              Text(
                AppStrings.flashcardsMapTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => SeedKnowledgeCatalogSheet.show(context),
                child: const Text(AppStrings.flashcardsSeedMap),
              ),
              IconButton(
                tooltip: AppStrings.flashcardsNewArea,
                onPressed: () => CreateKnowledgeAreaSheet.show(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          KnowledgeMapView(forest: forest, heat: heat),
          const SizedBox(height: ColonySpacing.lg),
          Text(
            AppStrings.flashcardsForecast,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          _ForecastBar(values: forecast),
          const SizedBox(height: ColonySpacing.lg),
          Row(
            children: [
              Text(
                AppStrings.flashcardsDecksTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => CreateFlashcardDeckSheet.show(context),
                child: const Text(AppStrings.flashcardsNewDeck),
              ),
            ],
          ),
          decksAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(AppStrings.errorGeneric),
            data: (decks) {
              final visible = decks.where((d) => !d.isArchived).toList();
              final cards = cardsAsync.asData?.value ?? const [];
              if (visible.isEmpty && forest.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: ColonySpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.flashcardsEmpty,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: ColonySpacing.xs),
                      Text(
                        AppStrings.flashcardsEmptyHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColonyColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                );
              }
              if (visible.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: ColonySpacing.sm),
                  child: Text(
                    AppStrings.flashcardsEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return Column(
                children: [
                  for (final deck in visible)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(deck.title),
                      subtitle: Text(
                        [
                          '${cards.where((c) => c.deckId == deck.id).length} ${AppStrings.flashcardsCards.toLowerCase()}',
                          if (deck.description != null) deck.description!,
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.go('/flashcards/decks/${deck.id.value}'),
                    ),
                ],
              );
            },
          ),
          if (query.trim().isNotEmpty) ...[
            const SizedBox(height: ColonySpacing.lg),
            Text(
              AppStrings.flashcardsBrowse,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            cardsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (cards) {
                final matches =
                    cards.where((c) => FlashcardSearch.matches(c, query)).toList();
                if (matches.isEmpty) {
                  return Text(AppStrings.flashcardsNoResults);
                }
                return Column(
                  children: [
                    for (final card in matches.take(20))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(card.front, maxLines: 2),
                        subtitle: Text(AppStrings.flashcardKindLabel(card.kind)),
                        onTap: () =>
                            context.go('/flashcards/decks/${card.deckId.value}'),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ForecastBar extends StatelessWidget {
  const _ForecastBar({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(1, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final value in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8 + (36 * value / max),
                    decoration: BoxDecoration(
                      color: ColonyColors.accentCyan.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
