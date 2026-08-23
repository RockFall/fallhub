import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/activation_controllers.dart';
import '../application/activation_providers.dart';

class ExperimentInspectScreen extends ConsumerWidget {
  const ExperimentInspectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experiments = ref.watch(activationExperimentsProvider);
    final insights = ref.watch(activationInsightsProvider);
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: ListView(
        children: [
          Text(
            AppStrings.activationExperiments,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(AppStrings.activationInsightDisclaimer),
          const SizedBox(height: ColonySpacing.md),
          FilledButton(
            onPressed: () => ref
                .read(activationControllerProvider.notifier)
                .analyzeExperiments(),
            child: const Text(AppStrings.activationAnalyze),
          ),
          const SizedBox(height: ColonySpacing.lg),
          experiments.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(AppStrings.errorGeneric),
            data: (items) {
              if (items.isEmpty) {
                return Text(AppStrings.activationNoExperiments);
              }
              return Column(
                children: [
                  for (final experiment in items)
                    ListTile(
                      title: Text(experiment.name),
                      subtitle: Text(experiment.hypothesis),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: ColonySpacing.lg),
          insights.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) {
              return Column(
                children: [
                  for (final insight in items)
                    Card(
                      child: ListTile(
                        title: Text(insight.title),
                        subtitle: Text(insight.body),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
