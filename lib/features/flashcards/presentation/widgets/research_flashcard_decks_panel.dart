import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../research/application/research_providers.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_providers.dart';
import 'create_flashcard_deck_sheet.dart';
import 'flashcard_editor_sheet.dart';

class ResearchFlashcardDecksPanel extends ConsumerWidget {
  const ResearchFlashcardDecksPanel({super.key, required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(researchFlashcardDecksProvider(nodeId));
    final node = ref.watch(researchNodeProvider(nodeId)).asData?.value;
    return ColonyPanel(
      title: AppStrings.flashcardsLinkedDecks,
      icon: Icons.style_outlined,
      child: decksAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => Text(AppStrings.errorGeneric),
        data: (decks) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.flashcardsSrsNotEvidence,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColonyColors.textMuted,
                    ),
              ),
              const SizedBox(height: ColonySpacing.sm),
              FilledButton.icon(
                onPressed: () =>
                    context.go('/flashcards/study?researchId=$nodeId'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(AppStrings.flashcardsStudyResearch),
              ),
              const SizedBox(height: ColonySpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.go(
                  '/flashcards/study?researchId=$nodeId&mode=practice',
                ),
                icon: const Icon(Icons.bolt_outlined),
                label: const Text(AppStrings.flashcardsPracticeNoQueue),
              ),
              if (decks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: ColonySpacing.sm),
                  child: Text(AppStrings.flashcardsNoLinkedDecks),
                )
              else
                for (final deck in decks)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(deck.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.go('/flashcards/decks/${deck.id.value}'),
                  ),
              TextButton(
                onPressed: () => CreateFlashcardDeckSheet.show(
                  context,
                  researchNodeId: EntityId(nodeId),
                ),
                child: const Text(AppStrings.flashcardsCreateLinkedDeck),
              ),
              TextButton(
                onPressed: () async {
                  var deck = decks.where((d) => !d.isArchived).firstOrNull;
                  deck ??= await ref
                      .read(flashcardControllerProvider.notifier)
                      .createDeck(
                        title: node?.title ?? AppStrings.flashcardsQuickDeck,
                        researchNodeId: EntityId(nodeId),
                      );
                  if (deck == null || !context.mounted) return;
                  await FlashcardEditorSheet.show(
                    context,
                    deckId: deck.id,
                    areaId: deck.areaId,
                  );
                },
                child: const Text(AppStrings.flashcardsNewCardFromResearch),
              ),
            ],
          );
        },
      ),
    );
  }
}
