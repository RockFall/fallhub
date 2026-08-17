import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../application/flashcard_controllers.dart';
import '../application/flashcard_providers.dart';
import 'widgets/create_flashcard_deck_sheet.dart';
import 'widgets/create_flashcard_tag_sheet.dart';
import 'widgets/create_knowledge_area_sheet.dart';
import 'widgets/flashcard_due_hero.dart';
import 'widgets/flashcard_editor_sheet.dart';
import 'widgets/flashcard_tag_tree.dart';
import 'widgets/flashcards_disclaimer_banner.dart';
import 'widgets/import_flashcards_json_sheet.dart';
import 'widgets/knowledge_map_view.dart';
import 'widgets/seed_knowledge_catalog_sheet.dart';

enum _HubBrowse { map, decks, tags }

class FlashcardsHubScreen extends ConsumerStatefulWidget {
  const FlashcardsHubScreen({
    super.key,
    this.openCapture = false,
    this.openImport = false,
    this.openTags = false,
  });

  final bool openCapture;
  final bool openImport;
  final bool openTags;

  @override
  ConsumerState<FlashcardsHubScreen> createState() =>
      _FlashcardsHubScreenState();
}

class _FlashcardsHubScreenState extends ConsumerState<FlashcardsHubScreen> {
  var _filter = KnowledgeMapFilter.all;
  var _browse = _HubBrowse.map;
  var _captureOpened = false;
  var _importOpened = false;

  @override
  void initState() {
    super.initState();
    if (widget.openCapture) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _captureOpened) return;
        _captureOpened = true;
        _capture();
      });
    }
    if (widget.openImport) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _importOpened) return;
        _importOpened = true;
        ImportFlashcardsJsonSheet.show(context);
      });
    }
    if (widget.openTags) {
      _browse = _HubBrowse.tags;
    }
  }

  Future<void> _capture() async {
    final decks = ref.read(flashcardDecksProvider).asData?.value ?? const [];
    var deck = mostRecentFlashcardDeck(decks);
    deck ??= await ref.read(flashcardControllerProvider.notifier).createDeck(
          title: AppStrings.flashcardsQuickDeck,
        );
    if (deck == null || !mounted) return;
    await FlashcardEditorSheet.show(
      context,
      deckId: deck.id,
      areaId: deck.areaId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final digest = ref.watch(flashcardTodayDigestProvider);
    final forest = ref.watch(knowledgeForestProvider);
    final heat = ref.watch(flashcardHeatProvider);
    final decksAsync = ref.watch(flashcardDecksProvider);
    final cardsAsync = ref.watch(flashcardsProvider);
    final srs = ref.watch(flashcardSrsProvider).asData?.value ?? const {};
    final now = ref.watch(clockProvider)();
    final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
    final placements =
        ref.watch(knowledgePlacementsProvider).asData?.value ?? const [];
    final query = ref.watch(flashcardSearchQueryProvider);
    final forecast = ref.watch(flashcardForecastProvider);
    final searching = query.trim().isNotEmpty;
    final decks = decksAsync.asData?.value ?? const [];
    final visibleDecks = decks.where((d) => !d.isArchived).toList();
    final tagForest = ref.watch(flashcardTagForestProvider);
    final tags = ref.watch(flashcardTagsProvider).asData?.value ?? const [];
    final tagLinks =
        ref.watch(flashcardTagLinksProvider).asData?.value ?? const [];
    final cards = cardsAsync.asData?.value ?? const [];
    final tagCounts = {
      for (final tag in tags)
        tag.id: FlashcardTagPolicy.cardsWithTag(
          cards: cards,
          links: tagLinks,
          tags: tags,
          rootId: tag.id,
        ).length,
    };
    final isEmpty =
        visibleDecks.isEmpty && forest.isEmpty && tagForest.isEmpty;
    final labels = StudyQueuePolicy.forecastDayLabels(now);

    return Semantics(
      container: true,
      identifier: 'flashcards.hub',
      label: AppStrings.flashcardsTitle,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _capture,
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.flashcardsNewCard),
        ),
        body: Padding(
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
              if (!searching)
                ColonyPanel(
                  title: AppStrings.flashcardsImportJson,
                  icon: Icons.upload_file_outlined,
                  collapsible: true,
                  initiallyExpanded: true,
                  helpText: AppStrings.flashcardsImportJsonHint,
                  child: const ImportFlashcardsJsonPanel(),
                ),
              if (!searching) const SizedBox(height: ColonySpacing.md),
              FlashcardDueHero(
                digest: digest,
                onStudy: () => context.go('/flashcards/study'),
                onPractice: () =>
                    context.go('/flashcards/study?mode=practice&saved=1'),
                onLater: () => context.go('/flashcards/study?later=1'),
                onTimebox: (minutes) =>
                    context.go('/flashcards/study?minutes=$minutes'),
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
                  placements: placements,
                  decks: visibleDecks,
                  cards: cards,
                  tags: tags,
                )
              else if (isEmpty)
                const _EmptyFlashcards()
              else ...[
                Wrap(
                  spacing: ColonySpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text(AppStrings.flashcardsBrowseMap),
                      selected: _browse == _HubBrowse.map,
                      onSelected: (_) =>
                          setState(() => _browse = _HubBrowse.map),
                    ),
                    ChoiceChip(
                      label: const Text(AppStrings.flashcardsBrowseDecks),
                      selected: _browse == _HubBrowse.decks,
                      onSelected: (_) =>
                          setState(() => _browse = _HubBrowse.decks),
                    ),
                    ChoiceChip(
                      label: const Text(AppStrings.flashcardsBrowseTags),
                      selected: _browse == _HubBrowse.tags,
                      onSelected: (_) =>
                          setState(() => _browse = _HubBrowse.tags),
                    ),
                  ],
                ),
                const SizedBox(height: ColonySpacing.md),
                if (_browse == _HubBrowse.map) ...[
                  ColonyPanel(
                    title: AppStrings.flashcardsMapTitle,
                    icon: Icons.map_outlined,
                    actions: [
                      TextButton(
                        onPressed: () =>
                            SeedKnowledgeCatalogSheet.show(context),
                        child: const Text(AppStrings.flashcardsSeedMap),
                      ),
                      IconButton(
                        tooltip: AppStrings.flashcardsNewArea,
                        onPressed: () =>
                            CreateKnowledgeAreaSheet.show(context),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: ColonySpacing.sm,
                          children: [
                            ChoiceChip(
                              label: const Text(AppStrings.flashcardsFilterAll),
                              selected: _filter == KnowledgeMapFilter.all,
                              onSelected: (_) => setState(
                                () => _filter = KnowledgeMapFilter.all,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text(AppStrings.flashcardsFilterDue),
                              selected: _filter == KnowledgeMapFilter.due,
                              onSelected: (_) => setState(
                                () => _filter = KnowledgeMapFilter.due,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text(
                                AppStrings.flashcardsFilterFragile,
                              ),
                              selected: _filter == KnowledgeMapFilter.fragile,
                              onSelected: (_) => setState(
                                () => _filter = KnowledgeMapFilter.fragile,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: ColonySpacing.sm),
                        KnowledgeMapView(
                          forest: forest,
                          heat: heat,
                          placements: placements,
                          filter: _filter,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ColonySpacing.md),
                  ColonyPanel(
                    title: AppStrings.flashcardsForecast,
                    icon: Icons.calendar_view_week_outlined,
                    child: _ForecastBar(values: forecast, labels: labels),
                  ),
                ] else if (_browse == _HubBrowse.decks)
                  ColonyPanel(
                    title: AppStrings.flashcardsDecksTitle,
                    icon: Icons.style_outlined,
                    actions: [
                      TextButton(
                        onPressed: () =>
                            CreateFlashcardDeckSheet.show(context),
                        child: const Text(AppStrings.flashcardsNewDeck),
                      ),
                    ],
                    child: decksAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => Text(AppStrings.errorGeneric),
                      data: (_) {
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
                                  _deckSubtitle(
                                    deck: deck,
                                    cards: cards,
                                    srs: srs,
                                    now: now,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context
                                    .go('/flashcards/decks/${deck.id.value}'),
                              ),
                          ],
                        );
                      },
                    ),
                  )
                else
                  ColonyPanel(
                    title: AppStrings.flashcardsTagsTitle,
                    icon: Icons.label_outline,
                    actions: [
                      IconButton(
                        tooltip: AppStrings.flashcardsNewTag,
                        onPressed: () =>
                            CreateFlashcardTagSheet.show(context),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                    child: tagForest.isEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(AppStrings.flashcardsTagsEmpty),
                              const SizedBox(height: ColonySpacing.sm),
                              Text(
                                AppStrings.flashcardsTagsEmptyHint,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: ColonyColors.textMuted),
                              ),
                              const SizedBox(height: ColonySpacing.md),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    CreateFlashcardTagSheet.show(context),
                                icon: const Icon(Icons.add),
                                label: const Text(AppStrings.flashcardsNewTag),
                              ),
                            ],
                          )
                        : FlashcardTagTree(
                            forest: tagForest,
                            cardCountByTag: tagCounts,
                          ),
                  ),
                const SizedBox(height: 72),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _deckSubtitle({
  required FlashcardDeck deck,
  required List<Flashcard> cards,
  required Map<EntityId, FlashcardSrsState> srs,
  required DateTime now,
}) {
  final inDeck = cards.where((c) => c.deckId == deck.id).toList();
  final count =
      '${inDeck.length} ${AppStrings.flashcardsCards.toLowerCase()}';
  DateTime? nextDue;
  var hasLeech = false;
  var saved = 0;
  for (final card in inDeck) {
    if (card.scheduleMode == FlashcardScheduleMode.unscheduled) {
      saved += 1;
      continue;
    }
    final state = srs[card.id];
    if (state?.leech == true) hasLeech = true;
    final due = state?.dueAt;
    if (due != null && (nextDue == null || due.isBefore(nextDue))) {
      nextDue = due;
    }
  }
  final extra = <String>[
    if (nextDue != null)
      AppStrings.flashcardsNextDueIn(
        StudyQueuePolicy.formatDueAt(nextDue, now),
      ),
    if (saved > 0) AppStrings.flashcardsUnscheduled,
    if (hasLeech) AppStrings.flashcardsLeechBadge,
  ];
  if (extra.isEmpty) return count;
  return '$count · ${extra.join(' · ')}';
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
          const SizedBox(height: ColonySpacing.sm),
          OutlinedButton.icon(
            onPressed: () => ImportFlashcardsJsonSheet.show(context),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text(AppStrings.flashcardsImportJson),
          ),
          const SizedBox(height: ColonySpacing.sm),
          OutlinedButton.icon(
            onPressed: () => CreateFlashcardTagSheet.show(context),
            icon: const Icon(Icons.label_outline),
            label: const Text(AppStrings.flashcardsNewTag),
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
    required this.placements,
    required this.decks,
    required this.cards,
    required this.tags,
  });

  final String query;
  final List<KnowledgeArea> areas;
  final List<KnowledgeAreaPlacement> placements;
  final List<FlashcardDeck> decks;
  final List<Flashcard> cards;
  final List<FlashcardTag> tags;

  @override
  Widget build(BuildContext context) {
    final areaHits = areas
        .where(
          (a) => KnowledgeAreaPolicy.matchesQuery(
            area: a,
            query: query,
            areas: areas,
            placements: placements,
          ),
        )
        .toList();
    final deckHits = decks
        .where((d) => d.title.toLowerCase().contains(query.trim().toLowerCase()))
        .toList();
    final cardHits =
        cards.where((c) => FlashcardSearch.matches(c, query)).take(20).toList();
    final needle = query.trim().toLowerCase();
    final tagHits = tags
        .where(
          (t) =>
              t.title.toLowerCase().contains(needle) ||
              FlashcardTagPolicy.pathLabel(tagId: t.id, tags: tags)
                  .toLowerCase()
                  .contains(needle),
        )
        .toList();
    if (areaHits.isEmpty &&
        deckHits.isEmpty &&
        cardHits.isEmpty &&
        tagHits.isEmpty) {
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
        if (tagHits.isNotEmpty) ...[
          const SizedBox(height: ColonySpacing.md),
          ColonyPanel(
            title: AppStrings.flashcardsTagsTitle,
            icon: Icons.label_outline,
            child: Column(
              children: [
                for (final tag in tagHits)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tag.title),
                    subtitle: Text(
                      FlashcardTagPolicy.pathLabel(tagId: tag.id, tags: tags),
                    ),
                    onTap: () =>
                        context.go('/flashcards/tags/${tag.id.value}'),
                  ),
              ],
            ),
          ),
        ],
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
                    onTap: () => context.go(
                      '/flashcards/study?mode=practice&cardId=${card.id.value}',
                    ),
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
  const _ForecastBar({required this.values, required this.labels});

  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(1, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  Text(
                    '${values[i]}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8 + (36 * values[i] / max),
                    decoration: BoxDecoration(
                      color: ColonyColors.accentCyan.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(ColonyRadii.lg),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i < labels.length ? labels[i] : '',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ColonyColors.textMuted,
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
