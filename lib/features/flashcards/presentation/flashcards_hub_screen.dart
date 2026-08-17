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
import 'widgets/flashcards_disclaimer_banner.dart';
import 'widgets/knowledge_map_view.dart';
import 'widgets/seed_knowledge_catalog_sheet.dart';

class FlashcardsHubScreen extends ConsumerWidget {
  const FlashcardsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digest = ref.watch(flashcardTodayDigestProvider);
    final forest = ref.watch(knowledgeForestProvider);
    final heat = ref.watch(flashcardHeatProvider);
    final decksAsync = ref.watch(flashcardDecksProvider);
    final cardsAsync = ref.watch(flashcardsProvider);
    final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
    final query = ref.watch(flashcardSearchQueryProvider);
    final forecast = ref.watch(flashcardForecastProvider);
    final searching = query.trim().isNotEmpty;
    final decks = decksAsync.asData?.value ?? const [];
    final visibleDecks = decks.where((d) => !d.isArchived).toList();
    final isEmpty = visibleDecks.isEmpty && forest.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: ListView(
        children: [
          Text(
            AppStrings.flashcardsTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.flashcardsSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColonyColors.textMuted,
                ),
          ),
          const SizedBox(height: ColonySpacing.md),
          const FlashcardsDisclaimerBanner(),
          const SizedBox(height: ColonySpacing.md),
          FlashcardDueHero(
            digest: digest,
            onStudy: () => context.go('/flashcards/study'),
            onPractice: () => context.go('/flashcards/study?mode=practice'),
          ),
          const SizedBox(height: ColonySpacing.md),
          SearchBar(
            hintText: AppStrings.flashcardsSearchHint,
            leading: const Icon(Icons.search),
            onChanged: ref.read(flashcardSearchQueryProvider.notifier).set,
          ),
          const SizedBox(height: ColonySpacing.lg),
          if (searching)
            _SearchResults(
              query: query,
              areas: areas,
              decks: visibleDecks,
              cards: cardsAsync.asData?.value ?? const [],
            )
          else if (isEmpty)
            const _EmptyFlashcards()
          else ...[
            ColonyPanel(
              title: AppStrings.flashcardsMapTitle,
              icon: Icons.map_outlined,
              actions: [
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
              child: KnowledgeMapView(forest: forest, heat: heat),
            ),
            const SizedBox(height: ColonySpacing.md),
            ColonyPanel(
              title: AppStrings.flashcardsForecast,
              icon: Icons.calendar_view_week_outlined,
              child: _ForecastBar(values: forecast),
            ),
            const SizedBox(height: ColonySpacing.md),
            ColonyPanel(
              title: AppStrings.flashcardsDecksTitle,
              icon: Icons.style_outlined,
              actions: [
                TextButton(
                  onPressed: () => CreateFlashcardDeckSheet.show(context),
                  child: const Text(AppStrings.flashcardsNewDeck),
                ),
              ],
              child: decksAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(AppStrings.errorGeneric),
                data: (_) {
                  final cards = cardsAsync.asData?.value ?? const [];
                  if (visibleDecks.isEmpty) {
                    return Text(AppStrings.flashcardsEmpty);
                  }
                  return Column(
                    children: [
                      for (final deck in visibleDecks)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(deck.title),
                          subtitle: Text(
                            '${cards.where((c) => c.deckId == deck.id).length} ${AppStrings.flashcardsCards.toLowerCase()}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.go('/flashcards/decks/${deck.id.value}'),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyFlashcards extends StatelessWidget {
  const _EmptyFlashcards();

  @override
  Widget build(BuildContext context) {
    return ColonyPanel(
      title: AppStrings.flashcardsEmptyCta,
      icon: Icons.style_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.flashcardsEmpty,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.flashcardsEmptyHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColonyColors.textMuted,
                ),
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton.icon(
            onPressed: () => SeedKnowledgeCatalogSheet.show(context),
            icon: const Icon(Icons.park_outlined),
            label: const Text(AppStrings.flashcardsSeedMap),
          ),
          const SizedBox(height: ColonySpacing.sm),
          OutlinedButton.icon(
            onPressed: () => CreateFlashcardDeckSheet.show(context),
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.flashcardsNewDeck),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.areas,
    required this.decks,
    required this.cards,
  });

  final String query;
  final List<KnowledgeArea> areas;
  final List<FlashcardDeck> decks;
  final List<Flashcard> cards;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final areaHits = areas
        .where((a) => a.title.toLowerCase().contains(q))
        .toList();
    final deckHits = decks
        .where((d) => d.title.toLowerCase().contains(q))
        .toList();
    final cardHits =
        cards.where((c) => FlashcardSearch.matches(c, query)).take(20).toList();
    if (areaHits.isEmpty && deckHits.isEmpty && cardHits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ColonySpacing.xl),
          child: Text(AppStrings.flashcardsNoResults),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (areaHits.isNotEmpty)
          ColonyPanel(
            title: AppStrings.flashcardsMapTitle,
            icon: Icons.map_outlined,
            child: Column(
              children: [
                for (final area in areaHits)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(area.title),
                    subtitle: Text(
                      KnowledgeAreaPolicy.pathLabel(
                        areaId: area.id,
                        areas: areas,
                      ),
                    ),
                    onTap: () =>
                        context.go('/flashcards/areas/${area.id.value}'),
                  ),
              ],
            ),
          ),
        if (deckHits.isNotEmpty) ...[
          const SizedBox(height: ColonySpacing.md),
          ColonyPanel(
            title: AppStrings.flashcardsDecksTitle,
            icon: Icons.style_outlined,
            child: Column(
              children: [
                for (final deck in deckHits)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(deck.title),
                    onTap: () =>
                        context.go('/flashcards/decks/${deck.id.value}'),
                  ),
              ],
            ),
          ),
        ],
        if (cardHits.isNotEmpty) ...[
          const SizedBox(height: ColonySpacing.md),
          ColonyPanel(
            title: AppStrings.flashcardsBrowse,
            icon: Icons.style_outlined,
            child: Column(
              children: [
                for (final card in cardHits)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(card.front, maxLines: 2),
                    subtitle: Text(AppStrings.flashcardKindLabel(card.kind)),
                    onTap: () =>
                        context.go('/flashcards/decks/${card.deckId.value}'),
                  ),
              ],
            ),
          ),
        ],
      ],
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
                      borderRadius: BorderRadius.circular(ColonyRadii.lg),
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
