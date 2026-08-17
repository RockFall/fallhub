import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_providers.dart';

class FlashcardEditorSheet extends ConsumerStatefulWidget {
  const FlashcardEditorSheet({
    super.key,
    required this.deckId,
    this.areaId,
    this.existing,
  });

  final EntityId deckId;
  final EntityId? areaId;
  final Flashcard? existing;

  static Future<void> show(
    BuildContext context, {
    required EntityId deckId,
    EntityId? areaId,
    Flashcard? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FlashcardEditorSheet(
        deckId: deckId,
        areaId: areaId,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<FlashcardEditorSheet> createState() =>
      _FlashcardEditorSheetState();
}

class _FlashcardEditorSheetState extends ConsumerState<FlashcardEditorSheet> {
  late final TextEditingController _front;
  late final TextEditingController _back;
  late final TextEditingController _extra;
  late final TextEditingController _tags;
  late FlashcardKind _kind;
  var _bidirectional = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _front = TextEditingController(text: existing?.front ?? '');
    _back = TextEditingController(text: existing?.back ?? '');
    _extra = TextEditingController(text: existing?.extra ?? '');
    _tags = TextEditingController(text: existing?.tags.join(', ') ?? '');
    _kind = existing?.kind ?? FlashcardKind.basic;
    _bidirectional = existing?.kind == FlashcardKind.reverse;
  }

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _extra.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(flashcardDecksProvider).asData?.value ?? const [];
    final deck = decks.where((d) => d.id == widget.deckId).firstOrNull;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + ColonySpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? AppStrings.flashcardsNewCard
                  : AppStrings.flashcardsEditCard,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (deck != null) ...[
              const SizedBox(height: ColonySpacing.xs),
              Text(
                deck.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColonyColors.textMuted,
                    ),
              ),
            ],
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<FlashcardKind>(
              // ignore: deprecated_member_use
              value: _kind,
              decoration: const InputDecoration(
                labelText: AppStrings.flashcardsKind,
              ),
              items: [
                for (final kind in FlashcardKind.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(AppStrings.flashcardKindLabel(kind)),
                  ),
              ],
              onChanged: widget.existing == null
                  ? (value) => setState(() => _kind = value ?? _kind)
                  : null,
            ),
            if (_kind == FlashcardKind.cloze) ...[
              const SizedBox(height: ColonySpacing.sm),
              Text(
                AppStrings.flashcardsClozeHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: ColonySpacing.sm),
            TextField(
              controller: _front,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: AppStrings.flashcardsFront,
              ),
            ),
            const SizedBox(height: ColonySpacing.sm),
            TextField(
              controller: _back,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: AppStrings.flashcardsBack,
              ),
            ),
            const SizedBox(height: ColonySpacing.sm),
            TextField(
              controller: _extra,
              decoration: const InputDecoration(
                labelText: AppStrings.flashcardsExtra,
              ),
            ),
            const SizedBox(height: ColonySpacing.sm),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: AppStrings.flashcardsTags,
              ),
            ),
            if (widget.existing == null &&
                (_kind == FlashcardKind.basic ||
                    _kind == FlashcardKind.reverse)) ...[
              const SizedBox(height: ColonySpacing.sm),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.flashcardsBidirectional),
                value: _bidirectional || _kind == FlashcardKind.reverse,
                onChanged: (value) => setState(() => _bidirectional = value),
              ),
            ],
            const SizedBox(height: ColonySpacing.md),
            Text(
              AppStrings.flashcardsCaptureHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColonyColors.textMuted,
                  ),
            ),
            const SizedBox(height: ColonySpacing.md),
            if (widget.existing == null) ...[
              FilledButton(
                onPressed: () => _save(FlashcardCaptureIntent.schedule),
                child: const Text(AppStrings.flashcardsSchedule),
              ),
              const SizedBox(height: ColonySpacing.sm),
              OutlinedButton(
                onPressed: () => _save(FlashcardCaptureIntent.saveOnly),
                child: const Text(AppStrings.flashcardsSaveOnly),
              ),
              const SizedBox(height: ColonySpacing.sm),
              TextButton(
                onPressed: () => _save(FlashcardCaptureIntent.practiceNow),
                child: const Text(AppStrings.flashcardsPracticeNow),
              ),
            ] else ...[
              FilledButton(
                onPressed: () => _save(FlashcardCaptureIntent.schedule),
                child: const Text(AppStrings.save),
              ),
              const SizedBox(height: ColonySpacing.sm),
              OutlinedButton(
                onPressed: () async {
                  final existing = widget.existing!;
                  if (existing.scheduleMode ==
                      FlashcardScheduleMode.scheduled) {
                    await ref
                        .read(flashcardControllerProvider.notifier)
                        .unscheduleCard(existing);
                  } else {
                    await ref
                        .read(flashcardControllerProvider.notifier)
                        .scheduleCard(existing);
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(
                  widget.existing!.scheduleMode ==
                          FlashcardScheduleMode.scheduled
                      ? AppStrings.flashcardsSaveOnly
                      : AppStrings.flashcardsSchedule,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(FlashcardCaptureIntent intent) async {
    final tags = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final existing = widget.existing;
    final scheduleMode = intent == FlashcardCaptureIntent.schedule
        ? FlashcardScheduleMode.scheduled
        : FlashcardScheduleMode.unscheduled;
    try {
      if (existing == null) {
        final created =
            await ref.read(flashcardControllerProvider.notifier).createCard(
                  deckId: widget.deckId,
                  areaId: widget.areaId,
                  front: _front.text,
                  back: _back.text,
                  kind: _kind,
                  extra: _extra.text,
                  tags: tags,
                  bidirectional: _bidirectional || _kind == FlashcardKind.reverse,
                  scheduleMode: scheduleMode,
                );
        if (!mounted) return;
        Navigator.of(context).pop();
        if (intent == FlashcardCaptureIntent.practiceNow &&
            created != null &&
            created.isNotEmpty) {
          context.go(
            '/flashcards/study?mode=practice&cardId=${created.first.id.value}',
          );
        }
      } else {
        await ref.read(flashcardControllerProvider.notifier).updateCard(
              existing.copyWith(
                front: _front.text,
                back: _back.text,
                extra: _extra.text,
                tags: tags,
                clearExtra: _extra.text.trim().isEmpty,
              ),
            );
        if (mounted) Navigator.of(context).pop();
      }
    } on FlashcardValidationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}
