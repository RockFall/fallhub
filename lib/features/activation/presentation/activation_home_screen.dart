import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/activation_controllers.dart';
import '../application/activation_providers.dart';
import 'widgets/stuck_now_sheet.dart';

class ActivationHomeScreen extends ConsumerWidget {
  const ActivationHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocols = ref.watch(activationProtocolsProvider);
    final episodes = ref.watch(activationEpisodesProvider);
    final open = ref.watch(openActivationEpisodeProvider);
    final detection = ref.watch(activationDetectionProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: ListView(
        children: [
          Text(
            AppStrings.activationTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.activationSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.activationDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.lg),
          open.maybeWhen(
            data: (episode) {
              if (episode == null) return const SizedBox.shrink();
              return _RestoreCard(episode: episode);
            },
            orElse: () => const SizedBox.shrink(),
          ),
          detection.maybeWhen(
            data: (proposal) {
              if (proposal == null) return const SizedBox.shrink();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.wb_twilight_outlined),
                  title: Text(
                    proposal.mayPropose
                        ? AppStrings.activationDetectionLetter
                        : AppStrings.activationDetectionBlocked,
                  ),
                  subtitle: Text(
                    '${proposal.hypothesis.type.name} · '
                    '${proposal.hypothesis.confidence.toStringAsFixed(2)}',
                  ),
                  trailing: proposal.mayPropose
                      ? TextButton(
                          onPressed: () => context.go('/activation/start'),
                          child: const Text(AppStrings.activationMobilize),
                        )
                      : TextButton(
                          onPressed: () => ref
                              .read(activationControllerProvider.notifier)
                              .declareResting(),
                          child: const Text(AppStrings.activationResting),
                        ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton.icon(
            onPressed: () => StuckNowSheet.show(context),
            icon: const Icon(Icons.bolt_outlined),
            label: const Text(AppStrings.activationStuckNow),
          ),
          const SizedBox(height: ColonySpacing.lg),
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.sm,
            children: [
              _LinkChip(
                label: AppStrings.activationProtocols,
                onTap: () => context.go('/activation/protocols'),
              ),
              _LinkChip(
                label: AppStrings.activationWaypoints,
                onTap: () => context.go('/activation/waypoints'),
              ),
              _LinkChip(
                label: AppStrings.activationShield,
                onTap: () => context.go('/activation/shield'),
              ),
              _LinkChip(
                label: AppStrings.activationExperiments,
                onTap: () => context.go('/activation/experiments'),
              ),
              _LinkChip(
                label: AppStrings.activationEnvironment,
                onTap: () => context.go('/activation/environment'),
              ),
            ],
          ),
          const SizedBox(height: ColonySpacing.xl),
          Text(
            AppStrings.activationProtocols,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          protocols.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(AppStrings.errorGeneric),
            data: (items) {
              if (items.isEmpty) {
                return Text(AppStrings.activationEmpty);
              }
              return Column(
                children: [
                  for (final protocol in items.take(8))
                    Card(
                      child: ListTile(
                        title: Text(protocol.name),
                        subtitle: Text(
                          AppStrings.activationProtocolTypeLabel(
                            protocol.protocolType,
                          ),
                        ),
                        enabled: protocol.isEnabled,
                        onTap: () => context.go(
                          '/activation/start?protocol=${protocol.id.value}',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: ColonySpacing.xl),
          Text(
            AppStrings.activationEpisodes,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          episodes.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) {
              if (items.isEmpty) {
                return Text(AppStrings.activationNoMoralScore);
              }
              return Column(
                children: [
                  for (final episode in items.take(6))
                    ListTile(
                      title: Text(AppStrings.activationStatus(episode.status)),
                      subtitle: Text(episode.targetState.label),
                      onTap: () => context.go(
                        '/activation/episodes/${episode.id.value}?inspect=1',
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

class _RestoreCard extends ConsumerWidget {
  const _RestoreCard({required this.episode});

  final ActivationEpisode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(activationControllerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ColonySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.activationRestoringTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(AppStrings.activationStatus(episode.status)),
            const SizedBox(height: ColonySpacing.sm),
            Wrap(
              spacing: ColonySpacing.sm,
              children: [
                FilledButton(
                  onPressed: () =>
                      context.go('/activation/episodes/${episode.id.value}'),
                  child: const Text(AppStrings.activationResume),
                ),
                OutlinedButton(
                  onPressed: () => controller.alreadyDone(episode.id),
                  child: const Text(AppStrings.activationAlreadyDone),
                ),
                TextButton(
                  onPressed: () => controller.abort(episode.id),
                  child: const Text(AppStrings.activationAbort),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
