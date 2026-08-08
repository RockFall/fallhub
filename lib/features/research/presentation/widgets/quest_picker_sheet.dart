import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../quests/application/quest_providers.dart';

class QuestPickerSheet extends ConsumerStatefulWidget {
  const QuestPickerSheet({
    super.key,
    required this.selectedQuestIds,
  });

  final List<EntityId> selectedQuestIds;

  static Future<List<EntityId>?> show(
    BuildContext context, {
    required List<EntityId> selectedQuestIds,
  }) {
    return showModalBottomSheet<List<EntityId>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => QuestPickerSheet(selectedQuestIds: selectedQuestIds),
    );
  }

  @override
  ConsumerState<QuestPickerSheet> createState() => _QuestPickerSheetState();
}

class _QuestPickerSheetState extends ConsumerState<QuestPickerSheet> {
  late Set<EntityId> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedQuestIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(questsProvider);
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
            AppStrings.researchLinkQuest,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          Flexible(
            child: questsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (quests) {
                final available =
                    quests.where((q) => !q.status.isTerminal).toList();
                if (available.isEmpty) {
                  return Text(
                    AppStrings.researchQuestPickerEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  children: available
                      .map(
                        (quest) => CheckboxListTile(
                          value: _selected.contains(quest.id),
                          title: Text(quest.title),
                          subtitle: Text(
                            AppStrings.questStatusLabel(quest.status),
                          ),
                          onChanged: (checked) {
                            setState(() {
                              if (checked ?? false) {
                                _selected.add(quest.id);
                              } else {
                                _selected.remove(quest.id);
                              }
                            });
                          },
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
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
