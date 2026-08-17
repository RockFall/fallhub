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

class FlashcardDeckScreen extends ConsumerWidget {
  const FlashcardDeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(flashcardDeckProvider(deckId));
    final cards = (ref.watch(flashcardsProvider).asData?.value ?? const [])
        .where((c) => c.deckId.value == deckId)
        .toList();
    final srs = ref.watch(flashcardSrsProvider).asData?.value ?? const {};
    final query = ref.watch(flashcardSearchQueryProvider);

    if (deck == null) {
      return Center(child: Text(AppStrings.flashcardsNotFound));
    }

    final visible = cards.where((c) => FlashcardSearch.matches(c, query)).toList();

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
                deck.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: AppStrings.flashcardsEditDeck,
              onPressed: () => CreateFlashcardDeckSheet.show(
                context,
                existing: deck,
              ),
              icon: const Icon(Icons.tune_outlined),
            ),
            IconButton(
              tooltip: deck.isArchived
                  ? AppStrings.flashcardsUnarchiveDeck
                  : AppStrings.flashcardsArchiveDeck,
              onPressed: () => ref
                  .read(flashcardControllerProvider.notifier)
                  .updateDeck(
                    deck.isArchived
                        ? deck.copyWith(clearArchived: true)
                        : deck.copyWith(archivedAt: DateTime.now().toUtc()),
                  ),
              icon: Icon(
                deck.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
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
          onPressed: () => context.go('/flashcards/study?deckId=$deckId'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(AppStrings.flashcardsStudyDeck),
        ),
        const SizedBox(height: ColonySpacing.sm),
        OutlinedButton.icon(
          onPressed: () => FlashcardEditorSheet.show(
            context,
            deckId: deck.id,
            areaId: deck.areaId,
          ),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.flashcardsNewCard),
        ),
        const SizedBox(height: ColonySpacing.lg),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: AppStrings.flashcardsSearchHint,
          ),
          onChanged: ref.read(flashcardSearchQueryProvider.notifier).set,
        ),
        const SizedBox(height: ColonySpacing.md),
        if (visible.isEmpty)
          Text(AppStrings.flashcardsNoCards)
        else
          for (final card in visible)
            _CardTile(
              card: card,
              srs: srs[card.id],
              onEdit: () => FlashcardEditorSheet.show(
                context,
                deckId: deck.id,
                areaId: deck.areaId,
                existing: card,
              ),
              onToggleSuspend: () => ref
                  .read(flashcardControllerProvider.notifier)
                  .setSuspended(card, !card.suspended),
            ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.srs,
    required this.onEdit,
    required this.onToggleSuspend,
  });

  final Flashcard card;
  final FlashcardSrsState? srs;
  final VoidCallback onEdit;
  final VoidCallback onToggleSuspend;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(card.front, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          AppStrings.flashcardKindLabel(card.kind),
          if (card.suspended) AppStrings.flashcardsSuspended,
          if (srs?.leech == true) AppStrings.flashcardsLeechBadge,
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: card.suspended
                ? AppStrings.flashcardsUnsuspend
                : AppStrings.flashcardsSuspend,
            onPressed: onToggleSuspend,
            icon: Icon(
              card.suspended
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
          IconButton(
            tooltip: AppStrings.flashcardsEditCard,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}
