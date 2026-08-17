import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_providers.dart';
import 'knowledge_area_typeahead.dart';

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
  EntityId? _areaId;

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
    _areaId = existing?.areaId ?? widget.areaId;
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
    final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
    final placements =
        ref.watch(knowledgePlacementsProvider).asData?.value ?? const [];
    final candidates = FlashcardAreaPolicy.specializationCandidates(
      deckAreaId: deck?.areaId,
      areas: areas,
      placements: placements,
    );
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
            TextField(
              controller: _front,
              minLines: 2,
              maxLines: 6,
              autofocus: widget.existing == null,
              decoration: const InputDecoration(
                labelText: AppStrings.flashcardsFront,
              ),
            ),
            if (_kind == FlashcardKind.cloze) ...[
              const SizedBox(height: ColonySpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    final sel = _front.selection;
                    final text = _front.text;
                    final start = sel.start;
                    final end = sel.end;
                    if (!sel.isValid || start == end) return;
                    final next = ClozeRenderer.wrapSelection(text, start, end);
                    _front.value = TextEditingValue(
                      text: next,
                      selection: TextSelection.collapsed(offset: next.length),
                    );
                  },
                  child: const Text(AppStrings.flashcardsWrapCloze),
                ),
              ),
              Text(
                AppStrings.flashcardsClozeHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: ColonySpacing.sm),
            TextField(
              controller: _back,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: AppStrings.flashcardsBack,
              ),
            ),
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
                  final updated = existing.copyWith(
                    front: _front.text,
                    back: _back.text,
                    extra: _extra.text,
                    tags: _tags.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList(),
                    areaId: _areaId,
                    clearArea: _areaId == null,
                    clearExtra: _extra.text.trim().isEmpty,
                  );
                  await ref
                      .read(flashcardControllerProvider.notifier)
                      .updateCard(updated);
                  if (existing.scheduleMode ==
                      FlashcardScheduleMode.scheduled) {
                    await ref
                        .read(flashcardControllerProvider.notifier)
                        .unscheduleCard(updated);
                  } else {
                    await ref
                        .read(flashcardControllerProvider.notifier)
                        .scheduleCard(updated);
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
            const SizedBox(height: ColonySpacing.md),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(AppStrings.flashcardsAdvanced),
                children: [
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
                  const SizedBox(height: ColonySpacing.sm),
                  KnowledgeAreaTypeahead(
                    areas: candidates,
                    placements: placements,
                    selectedId: _areaId,
                    onSelected: (id) => setState(() => _areaId = id),
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
                          _kind == FlashcardKind.reverse))
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(AppStrings.flashcardsBidirectional),
                      value: _bidirectional || _kind == FlashcardKind.reverse,
                      onChanged: (value) =>
                          setState(() => _bidirectional = value),
                    ),
                ],
              ),
            ),
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
                  areaId: _areaId,
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
                areaId: _areaId,
                clearArea: _areaId == null,
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
