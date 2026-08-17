import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_providers.dart';

class SeedKnowledgeCatalogSheet extends ConsumerStatefulWidget {
  const SeedKnowledgeCatalogSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SeedKnowledgeCatalogSheet(),
    );
  }

  @override
  ConsumerState<SeedKnowledgeCatalogSheet> createState() =>
      _SeedKnowledgeCatalogSheetState();
}

class _SeedKnowledgeCatalogSheetState
    extends ConsumerState<SeedKnowledgeCatalogSheet> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final existing = <String>{
      for (final area
          in ref.watch(knowledgeAreasProvider).asData?.value ?? const [])
        if (area.catalogKey != null) area.catalogKey!,
    };
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.flashcardsSeedMap,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.flashcardsSeedMapHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.md),
          SizedBox(
            height: 360,
            child: ListView(
              children: [
                for (final root in KnowledgeAreaCatalog.entries)
                  _CatalogNode(
                    entry: root,
                    depth: 0,
                    existing: existing,
                    selected: _selected,
                    onToggle: (key, value) => setState(() {
                      if (value) {
                        _selected.add(key);
                      } else {
                        _selected.remove(key);
                      }
                    }),
                  ),
              ],
            ),
          ),
          FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () async {
                    await ref
                        .read(flashcardControllerProvider.notifier)
                        .seedCatalog(_selected);
                    if (context.mounted) Navigator.of(context).pop();
                  },
            child: const Text(AppStrings.flashcardsSeedApply),
          ),
        ],
      ),
    );
  }
}

class _CatalogNode extends StatelessWidget {
  const _CatalogNode({
    required this.entry,
    required this.depth,
    required this.existing,
    required this.selected,
    required this.onToggle,
  });

  final KnowledgeCatalogEntry entry;
  final int depth;
  final Set<String> existing;
  final Set<String> selected;
  final void Function(String key, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final already = existing.contains(entry.key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.only(left: depth * 16.0),
          title: Text(entry.title),
          value: already || selected.contains(entry.key),
          onChanged: already
              ? null
              : (value) => onToggle(entry.key, value ?? false),
        ),
        for (final child in entry.children)
          _CatalogNode(
            entry: child,
            depth: depth + 1,
            existing: existing,
            selected: selected,
            onToggle: onToggle,
          ),
      ],
    );
  }
}
