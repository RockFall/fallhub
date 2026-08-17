import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_providers.dart';

class LinkAreaToResearchSheet extends ConsumerStatefulWidget {
  const LinkAreaToResearchSheet({super.key, required this.nodeId});

  final EntityId nodeId;

  static Future<void> show(
    BuildContext context, {
    required EntityId nodeId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LinkAreaToResearchSheet(nodeId: nodeId),
    );
  }

  @override
  ConsumerState<LinkAreaToResearchSheet> createState() =>
      _LinkAreaToResearchSheetState();
}

class _LinkAreaToResearchSheetState
    extends ConsumerState<LinkAreaToResearchSheet> {
  EntityId? _areaId;
  var _kind = ResearchKnowledgeLinkKind.related;

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
            AppStrings.flashcardsLinkShelf,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
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
                  child: Text(
                    KnowledgeAreaPolicy.pathLabel(
                      areaId: area.id,
                      areas: areas,
                    ),
                  ),
                ),
            ],
            onChanged: (value) => setState(() {
              _areaId = value == null ? null : EntityId(value);
            }),
          ),
          const SizedBox(height: ColonySpacing.sm),
          DropdownButtonFormField<ResearchKnowledgeLinkKind>(
            // ignore: deprecated_member_use
            value: _kind,
            items: [
              for (final kind in ResearchKnowledgeLinkKind.values)
                DropdownMenuItem(
                  value: kind,
                  child: Text(AppStrings.researchKnowledgeLinkLabel(kind)),
                ),
            ],
            onChanged: (value) => setState(() => _kind = value ?? _kind),
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: _areaId == null
                ? null
                : () async {
                    await ref
                        .read(flashcardControllerProvider.notifier)
                        .linkResearch(
                          researchNodeId: widget.nodeId,
                          areaId: _areaId!,
                          kind: _kind,
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
