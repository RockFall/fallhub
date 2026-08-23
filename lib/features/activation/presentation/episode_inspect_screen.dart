import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/activation_providers.dart';

class EpisodeInspectScreen extends ConsumerWidget {
  const EpisodeInspectScreen({super.key, required this.episodeId});

  final String episodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(activationSnapshotProvider(episodeId));
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(AppStrings.errorGeneric)),
      data: (data) {
        if (data == null) {
          return Center(child: Text(AppStrings.activationEmpty));
        }
        final episode = data.episode;
        return Padding(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          child: ListView(
            children: [
              Text(
                AppStrings.activationStatus(episode.status),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: ColonySpacing.sm),
              Text(AppStrings.activationNoMoralScore),
              const SizedBox(height: ColonySpacing.md),
              Text('${AppStrings.activationSignal}: ${episode.triggerType.name}'),
              if (episode.hypothesisType != null)
                Text(
                  '${AppStrings.activationHypothesis}: ${episode.hypothesisType!.name} · ${episode.hypothesisConfidence ?? 0}',
                ),
              Text(
                '${AppStrings.activationCapacity}: ${AppStrings.activationCapacityLabel(episode.capacityMode)}',
              ),
              Text('${AppStrings.activationFrom}: ${episode.initialState.label}'),
              Text('${AppStrings.activationTo}: ${episode.targetState.label}'),
              const SizedBox(height: ColonySpacing.lg),
              Text(
                AppStrings.activationProofSource,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final proof in data.proofs)
                ListTile(
                  title: Text(proof.proofType.name),
                  subtitle: Text(
                    '${proof.source} · ${proof.confidence.toStringAsFixed(2)}',
                  ),
                ),
              const SizedBox(height: ColonySpacing.md),
              Text(
                AppStrings.activationCommands,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final run in data.runs)
                ListTile(
                  title: Text(run.instructionRendered),
                  subtitle: Text(run.status.name),
                ),
            ],
          ),
        );
      },
    );
  }
}
