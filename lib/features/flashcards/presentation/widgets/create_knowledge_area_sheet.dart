import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_providers.dart';

class CreateKnowledgeAreaSheet extends ConsumerStatefulWidget {
  const CreateKnowledgeAreaSheet({super.key, this.parentId, this.existing});

  final EntityId? parentId;
  final KnowledgeArea? existing;

  static Future<void> show(
    BuildContext context, {
    EntityId? parentId,
    KnowledgeArea? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateKnowledgeAreaSheet(
        parentId: parentId,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<CreateKnowledgeAreaSheet> createState() =>
      _CreateKnowledgeAreaSheetState();
}

class _CreateKnowledgeAreaSheetState
    extends ConsumerState<CreateKnowledgeAreaSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  EntityId? _parentId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _parentId = existing?.parentId ?? widget.parentId;
    if (existing != null) {
      _title.text = existing.title;
      _description.text = existing.description ?? '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + ColonySpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null
                ? AppStrings.flashcardsNewArea
                : AppStrings.flashcardsEditArea,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: AppStrings.flashcardsAreaTitle,
            ),
          ),
          const SizedBox(height: ColonySpacing.sm),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _parentId?.value,
            decoration: const InputDecoration(
              labelText: AppStrings.flashcardsParentArea,
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
              _parentId = value == null ? null : EntityId(value);
            }),
          ),
          const SizedBox(height: ColonySpacing.sm),
          TextField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: AppStrings.researchDescriptionOptional,
            ),
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: () async {
              if (_title.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.flashcardsAreaTitleRequired),
                  ),
                );
                return;
              }
              final existing = widget.existing;
              if (existing == null) {
                await ref.read(flashcardControllerProvider.notifier).createArea(
                      title: _title.text,
                      parentId: _parentId,
                      description: _description.text,
                    );
              } else {
                await ref.read(flashcardControllerProvider.notifier).updateArea(
                      existing.copyWith(
                        title: _title.text,
                        parentId: _parentId,
                        description: _description.text,
                        clearParent: _parentId == null,
                        clearDescription: _description.text.trim().isEmpty,
                      ),
                    );
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
