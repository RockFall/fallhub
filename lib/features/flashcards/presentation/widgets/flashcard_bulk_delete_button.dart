import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_controllers.dart';

class FlashcardBulkDeleteButton extends ConsumerWidget {
  const FlashcardBulkDeleteButton({
    super.key,
    required this.cards,
    required this.label,
    required this.confirmBody,
  });

  final List<Flashcard> cards;
  final String label;
  final String confirmBody;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = cards.isNotEmpty;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColonyColors.statusCritical,
      ),
      onPressed: enabled ? () => _run(context, ref) : null,
      icon: const Icon(Icons.delete_outline),
      label: Text(label),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.flashcardsDeleteCategoryTitle),
        content: Text(confirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ColonyColors.statusCritical,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.flashcardsDeleteCategoryTitle),
        content: const Text(AppStrings.flashcardsDeleteCategoryAgain),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ColonyColors.statusCritical,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (second != true || !context.mounted) return;

    try {
      final count =
          await ref
              .read(flashcardControllerProvider.notifier)
              .deleteCards(cards) ??
          0;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.flashcardsDeleteCategoryDone(count))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
    }
  }
}
