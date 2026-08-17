import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_providers.dart';
import 'create_flashcard_deck_sheet.dart';

class ResearchFlashcardDecksPanel extends ConsumerWidget {
  const ResearchFlashcardDecksPanel({super.key, required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(researchFlashcardDecksProvider(nodeId));
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
              if (decks.isEmpty)
                Text(AppStrings.flashcardsNoLinkedDecks)
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
            ],
          );
        },
      ),
    );
  }
}
