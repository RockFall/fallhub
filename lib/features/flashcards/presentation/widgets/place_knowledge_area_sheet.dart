import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_providers.dart';
import 'knowledge_area_typeahead.dart';

class PlaceKnowledgeAreaSheet extends ConsumerStatefulWidget {
  const PlaceKnowledgeAreaSheet({super.key, required this.area});

  final KnowledgeArea area;

  static Future<void> show(
    BuildContext context, {
    required KnowledgeArea area,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlaceKnowledgeAreaSheet(area: area),
    );
  }

  @override
  ConsumerState<PlaceKnowledgeAreaSheet> createState() =>
      _PlaceKnowledgeAreaSheetState();
}

class _PlaceKnowledgeAreaSheetState
    extends ConsumerState<PlaceKnowledgeAreaSheet> {
  EntityId? _parentId;

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
    final placements =
        ref.watch(knowledgePlacementsProvider).asData?.value ?? const [];
    final taken = {
      widget.area.id,
      if (widget.area.parentId != null) widget.area.parentId!,
      for (final placement in placements)
        if (placement.areaId == widget.area.id) placement.parentAreaId,
    };
    final candidates = areas.where((a) => !taken.contains(a.id)).toList();
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
            AppStrings.flashcardsAddPlacement,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.flashcardsPlacementHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColonyColors.textMuted,
                ),
          ),
          const SizedBox(height: ColonySpacing.md),
          KnowledgeAreaTypeahead(
            areas: candidates,
            placements: placements,
            selectedId: _parentId,
            allowNone: false,
            label: AppStrings.flashcardsPlacementParent,
            onSelected: (id) => setState(() => _parentId = id),
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: _parentId == null
                ? null
                : () async {
                    await ref
                        .read(flashcardControllerProvider.notifier)
                        .addPlacement(
                          areaId: widget.area.id,
                          parentAreaId: _parentId!,
                        );
                    if (context.mounted) Navigator.of(context).pop();
                  },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
