import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../decisions/application/decision_controllers.dart';
import '../../../decisions/application/decision_providers.dart';
import '../../../decisions/presentation/widgets/create_decision_sheet.dart';
import '../../../decisions/presentation/widgets/decision_picker_sheet.dart';
import '../../../decisions/presentation/widgets/decision_summary_tile.dart';
import '../../../decisions/presentation/widgets/edit_decision_sheet.dart';

class QuestLinkedDecisionsSection extends ConsumerWidget {
  const QuestLinkedDecisionsSection({super.key, required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedDecisions = ref.watch(questLinkedDecisionsProvider(quest.id.value));

    return Padding(
      padding: const EdgeInsets.only(top: ColonySpacing.md),
      child: ColonyPanel(
        title: AppStrings.questLinkedDecisions,
        icon: Icons.gavel_outlined,
        actions: [
          if (!quest.status.isTerminal) ...[
            IconButton(
              tooltip: AppStrings.decisionCreateLinked,
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => CreateDecisionSheet.show(
                context,
                questId: quest.id.value,
              ),
            ),
            IconButton(
              tooltip: AppStrings.decisionLinkExisting,
              icon: const Icon(Icons.link, size: 20),
              onPressed: () async {
                final current = linkedDecisions.maybeWhen(
                  data: (decisions) => decisions,
                  orElse: () => const <DecisionRecord>[],
                );
                final selected = await DecisionPickerSheet.show(
                  context,
                  selectedDecisionIds: current.map((d) => d.id).toList(),
                );
                if (selected == null) return;
                await ref
                    .read(decisionControllerProvider.notifier)
                    .setLinkedDecisions(quest.id, selected);
              },
            ),
          ],
        ],
        child: linkedDecisions.when(
          loading: () => Text(AppStrings.loading),
          error: (_, __) => Text(AppStrings.errorGeneric),
          data: (decisions) {
            if (decisions.isEmpty) {
              return Text(
                AppStrings.questNoLinkedDecisions,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: decisions
                  .map(
                    (decision) => DecisionSummaryTile(
                      decision: decision,
                      onTap: () => EditDecisionSheet.show(context, decision),
                      trailing: quest.status.isTerminal
                          ? null
                          : PopupMenuButton<String>(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'unlink',
                                  child: Text(AppStrings.decisionUnlinkQuest),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(AppStrings.decisionDelete),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'unlink') {
                                  await ref
                                      .read(decisionControllerProvider.notifier)
                                      .unlinkQuest(
                                        questId: quest.id,
                                        decisionId: decision.id,
                                      );
                                  return;
                                }
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text(AppStrings.decisionDelete),
                                    content: const Text(
                                      AppStrings.decisionDeleteConfirm,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text(AppStrings.cancel),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          AppStrings.decisionDelete,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && context.mounted) {
                                  await ref
                                      .read(decisionControllerProvider.notifier)
                                      .delete(decision.id);
                                }
                              },
                            ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
