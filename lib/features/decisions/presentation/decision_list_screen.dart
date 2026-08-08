import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/decision_controllers.dart';
import '../application/decision_providers.dart';
import 'widgets/create_decision_sheet.dart';
import 'widgets/decision_summary_tile.dart';
import 'widgets/edit_decision_sheet.dart';

class DecisionListScreen extends ConsumerWidget {
  const DecisionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(decisionControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorGeneric)),
        );
      }
    });

    final decisionsAsync = ref.watch(decisionsProvider);

    return decisionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
      data: (decisions) {
        if (decisions.isEmpty) {
          return _EmptyList(
            onCreate: () => CreateDecisionSheet.show(context),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.decisions,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => CreateDecisionSheet.show(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(AppStrings.newDecision),
                ),
              ],
            ),
            const SizedBox(height: ColonySpacing.lg),
            ColonyPanel(
              title: AppStrings.decisions,
              icon: Icons.gavel_outlined,
              child: Column(
                children: decisions
                    .map(
                      (decision) => DecisionSummaryTile(
                        decision: decision,
                        onTap: () => EditDecisionSheet.show(context, decision),
                        trailing: IconButton(
                          tooltip: AppStrings.decisionDelete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, ref, decision),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DecisionRecord decision,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.decisionDelete),
        content: const Text(AppStrings.decisionDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.decisionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(decisionControllerProvider.notifier).delete(decision.id);
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ColonySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gavel_outlined,
              size: 48,
              color: ColonyColors.borderStandard,
            ),
            const SizedBox(height: ColonySpacing.lg),
            Text(
              AppStrings.decisionListEmpty,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ColonySpacing.sm),
            Text(
              AppStrings.decisionListEmptyHint,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.newDecision),
            ),
          ],
        ),
      ),
    );
  }
}
