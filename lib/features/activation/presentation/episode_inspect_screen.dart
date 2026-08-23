import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/activation_providers.dart';
import 'widgets/activation_art.dart';

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
        final spec = ActivationVisualResolver.specFor(data.bundle?.protocol);
        final station = ActivationVisualResolver.currentStation(
          spec: spec,
          current: data.current,
          runs: data.runs,
        );
        return Padding(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          child: ListView(
            children: [
              ColonyHeroBanner(
                assetPath: spec.artAsset,
                height: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.activationStatus(episode.status),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    Text(spec.journeyLabel),
                  ],
                ),
              ),
              const SizedBox(height: ColonySpacing.sm),
              Text(AppStrings.activationNoMoralScore),
              const SizedBox(height: ColonySpacing.md),
              ColonyRouteRibbon(
                labels: [for (final item in spec.stations) item.label],
                currentIndex: station,
              ),
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
              if (episode.linkedTaskId != null) ...[
                const SizedBox(height: ColonySpacing.sm),
                TextButton(
                  onPressed: () =>
                      context.go('/tasks/${episode.linkedTaskId!.value}'),
                  child: const Text(AppStrings.activationOpenTask),
                ),
              ],
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
                  leading: Icon(
                    run.status == ActivationCommandRunStatus.confirmed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: run.status == ActivationCommandRunStatus.confirmed
                        ? ColonyMiniAppColors.activation
                        : ColonyColors.textMuted,
                  ),
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
