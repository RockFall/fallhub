import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/flashcard_controllers.dart';
import '../application/flashcard_providers.dart';
import 'widgets/create_flashcard_deck_sheet.dart';
import 'widgets/flashcard_editor_sheet.dart';

class FlashcardDeckScreen extends ConsumerStatefulWidget {
  const FlashcardDeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<FlashcardDeckScreen> createState() =>
      _FlashcardDeckScreenState();
}

class _FlashcardDeckScreenState extends ConsumerState<FlashcardDeckScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(flashcardDeckProvider(widget.deckId));
    final cards = (ref.watch(flashcardsProvider).asData?.value ?? const [])
        .where((c) => c.deckId.value == widget.deckId)
        .toList();
    final srs = ref.watch(flashcardSrsProvider).asData?.value ?? const {};

    if (deck == null) {
      return Center(child: Text(AppStrings.flashcardsNotFound));
    }

    final visible =
        cards.where((c) => FlashcardSearch.matches(c, _query)).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => FlashcardEditorSheet.show(
          context,
          deckId: deck.id,
          areaId: deck.areaId,
        ),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.flashcardsNewCard),
      ),
      body: ListView(
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
                  deck.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: AppStrings.flashcardsMoreActions,
                onSelected: (value) async {
                  if (value == 'edit') {
                    await CreateFlashcardDeckSheet.show(
                      context,
                      existing: deck,
                    );
                  } else if (value == 'archive') {
                    await ref
                        .read(flashcardControllerProvider.notifier)
                        .updateDeck(
                          deck.isArchived
                              ? deck.copyWith(clearArchived: true)
                              : deck.copyWith(
                                  archivedAt: DateTime.now().toUtc(),
                                ),
                        );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text(AppStrings.flashcardsEditDeck),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(
                      deck.isArchived
                          ? AppStrings.flashcardsUnarchiveDeck
                          : AppStrings.flashcardsArchiveDeck,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (deck.description != null) Text(deck.description!),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            '${cards.length} ${AppStrings.flashcardsCards.toLowerCase()} · '
            '${AppStrings.flashcardsNewLimit} ${deck.newLimitPerDay} · '
            '${AppStrings.flashcardsReviewLimit} ${deck.reviewLimitPerDay}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton.icon(
            onPressed: () =>
                context.go('/flashcards/study?deckId=${widget.deckId}'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(AppStrings.flashcardsStudyDeck),
          ),
          const SizedBox(height: ColonySpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.go(
              '/flashcards/study?deckId=${widget.deckId}&mode=practice',
            ),
            icon: const Icon(Icons.bolt_outlined),
            label: const Text(AppStrings.flashcardsPracticeDeck),
          ),
          const SizedBox(height: ColonySpacing.lg),
          SearchBar(
            hintText: AppStrings.flashcardsSearchDecksHint,
            leading: const Icon(Icons.search),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: ColonySpacing.md),
          if (visible.isEmpty)
            Text(
              cards.isEmpty
                  ? AppStrings.flashcardsNoCards
                  : AppStrings.flashcardsNoResults,
            )
          else
            for (final card in visible)
              _CardTile(
                card: card,
                srs: srs[card.id],
                onOpen: () => FlashcardEditorSheet.show(
                  context,
                  deckId: deck.id,
                  areaId: deck.areaId,
                  existing: card,
                ),
              ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({
    required this.card,
    required this.srs,
    required this.onOpen,
  });

  final Flashcard card;
  final FlashcardSrsState? srs;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(card.front, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          AppStrings.flashcardKindLabel(card.kind),
          if (card.scheduleMode == FlashcardScheduleMode.unscheduled)
            AppStrings.flashcardsUnscheduled
          else
            AppStrings.flashcardsScheduled,
          if (card.suspended) AppStrings.flashcardsSuspended,
          if (srs?.leech == true) AppStrings.flashcardsLeechBadge,
        ].join(' · '),
      ),
      onTap: onOpen,
      trailing: PopupMenuButton<String>(
        tooltip: AppStrings.flashcardsMoreActions,
        onSelected: (value) {
          final controller = ref.read(flashcardControllerProvider.notifier);
          switch (value) {
            case 'edit':
              onOpen();
            case 'suspend':
              controller.setSuspended(card, !card.suspended);
            case 'schedule':
              if (card.scheduleMode == FlashcardScheduleMode.scheduled) {
                controller.unscheduleCard(card);
              } else {
                controller.scheduleCard(card);
              }
            case 'practice':
              context.go(
                '/flashcards/study?mode=practice&cardId=${card.id.value}',
              );
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text(AppStrings.flashcardsEditCard),
          ),
          PopupMenuItem(
            value: 'schedule',
            child: Text(
              card.scheduleMode == FlashcardScheduleMode.scheduled
                  ? AppStrings.flashcardsSaveOnly
                  : AppStrings.flashcardsSchedule,
            ),
          ),
          const PopupMenuItem(
            value: 'practice',
            child: Text(AppStrings.flashcardsPracticeNow),
          ),
          PopupMenuItem(
            value: 'suspend',
            child: Text(
              card.suspended
                  ? AppStrings.flashcardsUnsuspend
                  : AppStrings.flashcardsSuspend,
            ),
          ),
        ],
      ),
    );
  }
}
