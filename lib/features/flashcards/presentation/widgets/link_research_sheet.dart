import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../research/application/research_providers.dart';
import '../../application/flashcard_controllers.dart';

class LinkResearchSheet extends ConsumerStatefulWidget {
  const LinkResearchSheet({super.key, required this.area});

  final KnowledgeArea area;

  static Future<void> show(
    BuildContext context, {
    required KnowledgeArea area,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LinkResearchSheet(area: area),
    );
  }

  @override
  ConsumerState<LinkResearchSheet> createState() => _LinkResearchSheetState();
}

class _LinkResearchSheetState extends ConsumerState<LinkResearchSheet> {
  EntityId? _nodeId;
  var _kind = ResearchKnowledgeLinkKind.related;

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(researchNodesProvider).asData?.value ?? const [];
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
            AppStrings.flashcardsLinkResearch,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _nodeId?.value,
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
              _nodeId = value == null ? null : EntityId(value);
            }),
          ),
          const SizedBox(height: ColonySpacing.sm),
          DropdownButtonFormField<ResearchKnowledgeLinkKind>(
            // ignore: deprecated_member_use
            value: _kind,
            decoration: const InputDecoration(labelText: AppStrings.flashcardsKind),
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
            onPressed: _nodeId == null
                ? null
                : () async {
                    await ref
                        .read(flashcardControllerProvider.notifier)
                        .linkResearch(
                          researchNodeId: _nodeId!,
                          areaId: widget.area.id,
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
