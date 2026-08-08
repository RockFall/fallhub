import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/research_providers.dart';

class ResearchPrerequisitePickerSheet extends ConsumerStatefulWidget {
  const ResearchPrerequisitePickerSheet({
    super.key,
    required this.nodeId,
    required this.selectedPrerequisiteIds,
  });

  final String nodeId;
  final List<EntityId> selectedPrerequisiteIds;

  static Future<List<EntityId>?> show(
    BuildContext context, {
    required String nodeId,
    required List<EntityId> selectedPrerequisiteIds,
  }) {
    return showModalBottomSheet<List<EntityId>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ResearchPrerequisitePickerSheet(
        nodeId: nodeId,
        selectedPrerequisiteIds: selectedPrerequisiteIds,
      ),
    );
  }

  @override
  ConsumerState<ResearchPrerequisitePickerSheet> createState() =>
      _ResearchPrerequisitePickerSheetState();
}

class _ResearchPrerequisitePickerSheetState
    extends ConsumerState<ResearchPrerequisitePickerSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedPrerequisiteIds.map((id) => id.value).toSet();
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
            AppStrings.researchLinkPrerequisite,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          Flexible(
            child: nodesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (nodes) {
                final candidates = nodes
                    .where((n) => n.id.value != widget.nodeId)
                    .toList();
                if (candidates.isEmpty) {
                  return Text(AppStrings.researchPrerequisitePickerEmpty);
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final node = candidates[index];
                    return CheckboxListTile(
                      value: _selected.contains(node.id.value),
                      title: Text(node.title),
                      subtitle: Text(AppStrings.researchStatusLabel(node.status)),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selected.add(node.id.value);
                          } else {
                            _selected.remove(node.id.value);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                _selected.map((id) => EntityId(id)).toList(),
              );
            },
            child: Text(
              AppStrings.researchSelectedPrerequisitesCount(_selected.length),
            ),
          ),
        ],
      ),
    );
  }
}
