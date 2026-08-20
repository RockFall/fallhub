import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_providers.dart';

class CreateFlashcardTagSheet extends ConsumerStatefulWidget {
  const CreateFlashcardTagSheet({super.key, this.parentId, this.existing});

  final EntityId? parentId;
  final FlashcardTag? existing;

  static Future<void> show(
    BuildContext context, {
    EntityId? parentId,
    FlashcardTag? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateFlashcardTagSheet(
        parentId: parentId,
        existing: existing,
      ),
    );
  }

  @override
  ConsumerState<CreateFlashcardTagSheet> createState() =>
      _CreateFlashcardTagSheetState();
}

class _CreateFlashcardTagSheetState
    extends ConsumerState<CreateFlashcardTagSheet> {
  final _title = TextEditingController();
  EntityId? _parentId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _parentId = existing?.parentId ?? widget.parentId;
    if (existing != null) {
      _title.text = existing.title;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(flashcardTagsProvider).asData?.value ?? const [];
    final parents = [
      for (final tag in tags)
        if (tag.id != widget.existing?.id) tag,
    ];
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
                ? (widget.parentId == null
                    ? AppStrings.flashcardsNewTag
                    : AppStrings.flashcardsNewSubtag)
                : AppStrings.flashcardsEditTag,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: AppStrings.flashcardsTagTitle,
            ),
          ),
          const SizedBox(height: ColonySpacing.sm),
          DropdownButtonFormField<String?>(
            // ignore: deprecated_member_use
            value: _parentId?.value,
            decoration: const InputDecoration(
              labelText: AppStrings.flashcardsParentTag,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(AppStrings.flashcardsNoParentTag),
              ),
              for (final tag in parents)
                DropdownMenuItem<String?>(
                  value: tag.id.value,
                  child: Text(
                    FlashcardTagPolicy.pathLabel(tagId: tag.id, tags: tags),
                  ),
                ),
            ],
            onChanged: (value) => setState(() {
              _parentId = value == null ? null : EntityId(value);
            }),
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: () async {
              if (_title.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.flashcardsTagTitleRequired),
                  ),
                );
                return;
              }
              final existing = widget.existing;
              if (existing == null) {
                await ref.read(flashcardControllerProvider.notifier).createTag(
                      title: _title.text,
                      parentId: _parentId,
                    );
              } else {
                await ref.read(flashcardControllerProvider.notifier).updateTag(
                      existing.copyWith(
                        title: _title.text,
                        parentId: _parentId,
                        clearParent: _parentId == null,
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
