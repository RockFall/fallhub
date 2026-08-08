import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/quest_providers.dart';

class QuestPrerequisitePickerSheet extends ConsumerStatefulWidget {
  const QuestPrerequisitePickerSheet({
    super.key,
    required this.questId,
    required this.selectedPrerequisiteIds,
  });

  final String questId;
  final List<EntityId> selectedPrerequisiteIds;

  static Future<List<EntityId>?> show(
    BuildContext context, {
    required String questId,
    required List<EntityId> selectedPrerequisiteIds,
  }) {
    return showModalBottomSheet<List<EntityId>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => QuestPrerequisitePickerSheet(
        questId: questId,
        selectedPrerequisiteIds: selectedPrerequisiteIds,
      ),
    );
  }

  @override
  ConsumerState<QuestPrerequisitePickerSheet> createState() =>
      _QuestPrerequisitePickerSheetState();
}

class _QuestPrerequisitePickerSheetState
    extends ConsumerState<QuestPrerequisitePickerSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedPrerequisiteIds.map((id) => id.value).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final questsAsync = ref.watch(questsProvider);

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
            AppStrings.questLinkPrerequisite,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          Flexible(
            child: questsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (quests) {
                final candidates = quests
                    .where((q) => q.id.value != widget.questId)
                    .toList();
                if (candidates.isEmpty) {
                  return Text(AppStrings.questPrerequisitePickerEmpty);
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final quest = candidates[index];
                    final selected = _selected.contains(quest.id.value);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selected.add(quest.id.value);
                          } else {
                            _selected.remove(quest.id.value);
                          }
                        });
                      },
                      title: Text(quest.title),
                      subtitle: Text(
                        quest.purpose,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondary: Chip(
                        label: Text(AppStrings.questStatusLabel(quest.status)),
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
            child: Text(AppStrings.questSelectedPrerequisitesCount(_selected.length)),
          ),
        ],
      ),
    );
  }
}
