import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/decision_providers.dart';

class DecisionPickerSheet extends ConsumerStatefulWidget {
  const DecisionPickerSheet({
    super.key,
    required this.selectedDecisionIds,
  });

  final List<EntityId> selectedDecisionIds;

  static Future<List<EntityId>?> show(
    BuildContext context, {
    required List<EntityId> selectedDecisionIds,
  }) {
    return showModalBottomSheet<List<EntityId>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DecisionPickerSheet(selectedDecisionIds: selectedDecisionIds),
    );
  }

  @override
  ConsumerState<DecisionPickerSheet> createState() => _DecisionPickerSheetState();
}

class _DecisionPickerSheetState extends ConsumerState<DecisionPickerSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedDecisionIds.map((id) => id.value).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final decisionsAsync = ref.watch(decisionsProvider);

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
            AppStrings.decisionLinkExisting,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          Flexible(
            child: decisionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (decisions) {
                if (decisions.isEmpty) {
                  return Text(AppStrings.decisionPickerEmpty);
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: decisions.length,
                  itemBuilder: (context, index) {
                    final decision = decisions[index];
                    final selected = _selected.contains(decision.id.value);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selected.add(decision.id.value);
                          } else {
                            _selected.remove(decision.id.value);
                          }
                        });
                      },
                      title: Text(decision.title),
                      subtitle: Text(
                        decision.decision,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondary: Chip(
                        label: Text(
                          AppStrings.decisionReversibilityLabel(decision.reversibility),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
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
                _selected.map(EntityId.new).toList(),
              );
            },
            child: Text(AppStrings.decisionSelectedCount(_selected.length)),
          ),
        ],
      ),
    );
  }
}
