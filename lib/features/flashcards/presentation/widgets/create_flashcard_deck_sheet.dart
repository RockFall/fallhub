import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../research/application/research_providers.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_providers.dart';

class CreateFlashcardDeckSheet extends ConsumerStatefulWidget {
  const CreateFlashcardDeckSheet({
    super.key,
    this.areaId,
    this.researchNodeId,
    this.existing,
  });

  final EntityId? areaId;
  final EntityId? researchNodeId;
  final FlashcardDeck? existing;

  static Future<FlashcardDeck?> show(
    BuildContext context, {
    EntityId? areaId,
    EntityId? researchNodeId,
    FlashcardDeck? existing,
  }) {
    return showModalBottomSheet<FlashcardDeck>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateFlashcardDeckSheet(
        areaId: areaId,
        researchNodeId: researchNodeId,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<CreateFlashcardDeckSheet> createState() =>
      _CreateFlashcardDeckSheetState();
}

class _CreateFlashcardDeckSheetState
    extends ConsumerState<CreateFlashcardDeckSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _newLimit = TextEditingController(text: '20');
  final _reviewLimit = TextEditingController(text: '200');
  EntityId? _areaId;
  EntityId? _researchId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _areaId = existing?.areaId ?? widget.areaId;
    _researchId = existing?.researchNodeId ?? widget.researchNodeId;
    if (existing != null) {
      _title.text = existing.title;
      _description.text = existing.description ?? '';
      _newLimit.text = '${existing.newLimitPerDay}';
      _reviewLimit.text = '${existing.reviewLimitPerDay}';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _newLimit.dispose();
    _reviewLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
    final nodes = ref.watch(researchNodesProvider).asData?.value ?? const [];
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
                  ? AppStrings.flashcardsNewDeck
                  : AppStrings.flashcardsEditDeck,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: AppStrings.flashcardsDeckTitle,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(AppStrings.flashcardsAdvanced),
                children: [
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _areaId?.value,
                    decoration: const InputDecoration(
                      labelText: AppStrings.flashcardsMapTitle,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.flashcardsNoParent),
                      ),
                      for (final area in areas)
                        DropdownMenuItem(
                          value: area.id.value,
                          child: Text(area.title),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _areaId = value == null ? null : EntityId(value);
                    }),
                  ),
                  const SizedBox(height: ColonySpacing.sm),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _researchId?.value,
                    decoration: const InputDecoration(
                      labelText: AppStrings.flashcardsLinkedResearch,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.flashcardsNoResearch),
                      ),
                      for (final node in nodes)
                        DropdownMenuItem(
                          value: node.id.value,
                          child: Text(node.title),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _researchId = value == null ? null : EntityId(value);
                    }),
                  ),
                  const SizedBox(height: ColonySpacing.sm),
                  TextField(
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: AppStrings.researchDescriptionOptional,
                    ),
                  ),
                  const SizedBox(height: ColonySpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newLimit,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.flashcardsNewLimit,
                          ),
                        ),
                      ),
                      const SizedBox(width: ColonySpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _reviewLimit,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.flashcardsReviewLimit,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ColonySpacing.xs),
                  Text(
                    AppStrings.flashcardsLimitsHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColonyColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton(
              onPressed: () async {
                if (_title.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.flashcardsDeckTitleRequired),
                    ),
                  );
                  return;
                }
                final newLimit = int.tryParse(_newLimit.text.trim()) ?? 20;
                final reviewLimit = int.tryParse(_reviewLimit.text.trim()) ?? 200;
                final existing = widget.existing;
                if (existing == null) {
                  final deck = await ref
                      .read(flashcardControllerProvider.notifier)
                      .createDeck(
                        title: _title.text,
                        areaId: _areaId,
                        researchNodeId: _researchId,
                        description: _description.text,
                        newLimitPerDay: newLimit,
                        reviewLimitPerDay: reviewLimit,
                      );
                  if (context.mounted) Navigator.of(context).pop(deck);
                  return;
                }
                await ref.read(flashcardControllerProvider.notifier).updateDeck(
                      existing.copyWith(
                        title: _title.text,
                        areaId: _areaId,
                        researchNodeId: _researchId,
                        description: _description.text,
                        newLimitPerDay: newLimit,
                        reviewLimitPerDay: reviewLimit,
                        clearArea: _areaId == null,
                        clearResearch: _researchId == null,
                        clearDescription: _description.text.trim().isEmpty,
                      ),
                    );
                if (context.mounted) Navigator.of(context).pop(existing);
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}
