import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/research_providers.dart';

class ResearchNodePickerSheet extends ConsumerStatefulWidget {
  const ResearchNodePickerSheet({
    super.key,
    required this.selectedNodeIds,
  });

  final List<EntityId> selectedNodeIds;

  static Future<List<EntityId>?> show(
    BuildContext context, {
    required List<EntityId> selectedNodeIds,
  }) {
    return showModalBottomSheet<List<EntityId>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ResearchNodePickerSheet(selectedNodeIds: selectedNodeIds),
    );
  }

  @override
  ConsumerState<ResearchNodePickerSheet> createState() =>
      _ResearchNodePickerSheetState();
}

class _ResearchNodePickerSheetState
    extends ConsumerState<ResearchNodePickerSheet> {
  late Set<EntityId> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedNodeIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(researchNodesProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.questLinkResearch,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          Flexible(
            child: nodesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (nodes) {
                final available =
                    nodes.where((n) => !n.status.isTerminal).toList();
                if (available.isEmpty) {
                  return Text(
                    AppStrings.researchNodePickerEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  children: available
                      .map(
                        (node) => CheckboxListTile(
                          value: _selected.contains(node.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selected.add(node.id);
                              } else {
                                _selected.remove(node.id);
                              }
                            });
                          },
                          title: Text(node.title),
                          subtitle: node.description == null
                              ? null
                              : Text(node.description!, maxLines: 2),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
