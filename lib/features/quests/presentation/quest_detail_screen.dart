import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/quest_controllers.dart';
import '../application/quest_providers.dart';
import 'widgets/edit_quest_sheet.dart';
import 'widgets/quest_detail_content_tab.dart';
import 'widgets/quest_detail_relations_tab.dart';

String questControllerErrorMessage(Object error) {
  if (error is QuestPrerequisiteException) {
    if (error.message.contains('circular')) {
      return AppStrings.questPrerequisiteCycle;
    }
    if (error.message.contains('si mesma')) {
      return AppStrings.questPrerequisiteSelfLink;
    }
    return AppStrings.questActivateBlockedPrerequisites;
  }
  return AppStrings.errorGeneric;
}

class QuestDetailScreen extends ConsumerStatefulWidget {
  const QuestDetailScreen({super.key, required this.questId});

  final String questId;

  @override
  ConsumerState<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends ConsumerState<QuestDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      animationDuration: Duration.zero,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(questControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(questControllerErrorMessage(next.error!))),
        );
      }
    });

    final questAsync = ref.watch(questProvider(widget.questId));
    final chain = ref.watch(questChainProvider(widget.questId));

    return questAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
      data: (quest) {
        if (quest == null) {
          return Center(child: Text(AppStrings.questNotFound));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ColonySpacing.sm,
                ColonySpacing.lg,
                ColonySpacing.lg,
                ColonySpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/quests'),
                  ),
                  Expanded(
                    child: Text(
                      quest.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Chip(label: Text(AppStrings.questStatusLabel(quest.status))),
                  if (!quest.status.isTerminal)
                    IconButton(
                      tooltip: AppStrings.questEdit,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => EditQuestSheet.show(context, quest),
                    ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: AppStrings.questDetailTabContent),
                Tab(text: AppStrings.questDetailTabRelations),
              ],
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _tabs,
                builder: (context, _) {
                  return switch (_tabs.index) {
                    0 => QuestDetailContentTab(quest: quest),
                    _ => QuestDetailRelationsTab(quest: quest, chain: chain),
                  };
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
