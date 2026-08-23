import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../quests/application/quest_providers.dart';
import '../application/relations_controllers.dart';
import '../application/relations_providers.dart';
import 'relations_shortcut_bar.dart';
import 'widgets/create_commitment_sheet.dart';
import 'widgets/edit_commitment_sheet.dart';

class CommitmentsScreen extends ConsumerWidget {
  const CommitmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commitmentsAsync = ref.watch(commitmentsProvider);
    final questsAsync = ref.watch(questsProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.commitmentsTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.commitmentsDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.md),
          const RelationsShortcutBar(current: RelationsDoor.commitments),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: commitmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  Center(child: Text(AppStrings.errorGeneric)),
              data: (items) {
                final visible = items
                    .where((c) => !c.status.isHiddenFromActiveList)
                    .toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.commitmentsEmpty),
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.commitmentsEmptyHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }
                final questById = {
                  for (final q in questsAsync.maybeWhen(
                    data: (quests) => quests,
                    orElse: () => const <Quest>[],
                  ))
                    q.id: q,
                };
                return ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final c = visible[index];
                    final counterpart = c.madeToLabel ??
                        (c.madeToPersonId != null
                            ? AppStrings.commitmentPersonLinked
                            : AppStrings.commitmentOrgLinked);
                    final linkedQuest = c.linkedQuestId == null
                        ? null
                        : questById[c.linkedQuestId!];
                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(c.description),
                        subtitle: Text(
                          [
                            '${AppStrings.commitmentMadeBy}: ${c.madeByLabel}',
                            counterpart,
                            if (linkedQuest != null)
                              AppStrings.commitmentLinkedQuestTitle(
                                linkedQuest.title,
                              ),
                            if (c.dueAt != null)
                              AppStrings.commitmentDue(c.dueAt!),
                          ].join(' · '),
                        ),
                        onTap: () => EditCommitmentSheet.show(context, c),
                        trailing: IconButton(
                          tooltip: AppStrings.commitmentMarkKept,
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () => ref
                              .read(relationsControllerProvider.notifier)
                              .setCommitmentStatus(
                                c,
                                CommitmentStatus.kept,
                              ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton.icon(
            onPressed: () => CreateCommitmentSheet.show(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.commitmentNew),
          ),
        ],
      ),
    );
  }
}
