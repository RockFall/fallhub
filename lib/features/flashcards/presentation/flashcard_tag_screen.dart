import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/flashcard_providers.dart';
import 'widgets/create_flashcard_tag_sheet.dart';
import 'widgets/flashcard_bulk_delete_button.dart';

class FlashcardTagScreen extends ConsumerWidget {
  const FlashcardTagScreen({super.key, required this.tagId});

  final String tagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = ref.watch(flashcardTagProvider(tagId));
    final tags = ref.watch(flashcardTagsProvider).asData?.value ?? const [];
    final links = ref.watch(flashcardTagLinksProvider).asData?.value ?? const [];
    final cards = ref.watch(flashcardsProvider).asData?.value ?? const [];

    if (tag == null) {
      return Center(child: Text(AppStrings.flashcardsNotFound));
    }

    final children = FlashcardTagPolicy.childrenOf(parentId: tag.id, tags: tags);
    final tagged = FlashcardTagPolicy.cardsWithTag(
      cards: cards,
      links: links,
      tags: tags,
      rootId: tag.id,
    );
    final ancestors = FlashcardTagPolicy.ancestorsOf(
      tagId: tag.id,
      byId: {for (final item in tags) item.id: item},
    ).reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (tag.parentId != null) {
                  context.go('/flashcards/tags/${tag.parentId!.value}');
                } else {
                  context.go('/flashcards?tab=tags');
                }
              },
            ),
            Expanded(
              child: Text(
                tag.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: AppStrings.flashcardsEditTag,
              onPressed: () => CreateFlashcardTagSheet.show(
                context,
                existing: tag,
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
                  onTap: ancestors[i].id == tag.id
                      ? null
                      : () => context.go(
                            '/flashcards/tags/${ancestors[i].id.value}',
                          ),
                  child: Text(
                    ancestors[i].title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ancestors[i].id == tag.id
                              ? ColonyColors.textPrimary
                              : ColonyColors.accentCyan,
                        ),
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.flashcardsHeroToday,
          icon: Icons.label_outline,
          child: Text(
            '${tagged.length} ${AppStrings.flashcardsCards.toLowerCase()}',
          ),
        ),
        const SizedBox(height: ColonySpacing.md),
        FilledButton.icon(
          onPressed: () => context.go('/flashcards/study?tagId=$tagId'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(AppStrings.flashcardsStudyTag),
        ),
        const SizedBox(height: ColonySpacing.sm),
        OutlinedButton.icon(
          onPressed: () =>
              context.go('/flashcards/study?tagId=$tagId&mode=practice'),
          icon: const Icon(Icons.bolt_outlined),
          label: const Text(AppStrings.flashcardsPracticeTag),
        ),
        const SizedBox(height: ColonySpacing.sm),
        FlashcardBulkDeleteButton(
          cards: tagged,
          label: AppStrings.flashcardsDeleteTagCards(tagged.length),
          confirmBody: AppStrings.flashcardsDeleteTagConfirmBody,
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.flashcardsSubtags,
          icon: Icons.account_tree_outlined,
          actions: [
            IconButton(
              tooltip: AppStrings.flashcardsNewSubtag,
              onPressed: () => CreateFlashcardTagSheet.show(
                context,
                parentId: tag.id,
              ),
              icon: const Icon(Icons.add),
            ),
          ],
          child: children.isEmpty
              ? Text(AppStrings.flashcardsTagsEmpty)
              : Column(
                  children: [
                    for (final child in children)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(child.title),
                        subtitle: Text(
                          '${FlashcardTagPolicy.cardsWithTag(
                            cards: cards,
                            links: links,
                            tags: tags,
                            rootId: child.id,
                          ).length} ${AppStrings.flashcardsCards.toLowerCase()}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.go('/flashcards/tags/${child.id.value}'),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.flashcardsBrowse,
          icon: Icons.style_outlined,
          child: tagged.isEmpty
              ? Text(AppStrings.flashcardsNoCardsInTag)
              : Column(
                  children: [
                    for (final card in tagged.take(40))
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
    );
  }
}
