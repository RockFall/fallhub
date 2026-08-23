import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../application/activation_controllers.dart';
import '../application/activation_providers.dart';
import 'widgets/stuck_now_sheet.dart';
import 'widgets/waypoint_route_map.dart';

class ActivationHomeScreen extends ConsumerWidget {
  const ActivationHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocols = ref.watch(activationProtocolsProvider);
    final episodes = ref.watch(activationEpisodesProvider);
    final open = ref.watch(openActivationEpisodeProvider);
    final detection = ref.watch(activationDetectionProvider);
    final waypoints = ref.watch(activationWaypointsProvider);
    final schedule = ref.watch(activationScheduleContextProvider);
    final now = ref.watch(clockProvider)();
    final suggested = ActivationStuckNowPolicy.choices(
      now: now,
      hasUpcomingFocus: schedule.asData?.value.hasUpcomingFocus ?? false,
    ).first;

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: ListView(
        children: [
          ColonyHeroBanner(
            assetPath: ActivationArtAssets.hero,
            height: 188,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.activationTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: ColonySpacing.sm),
                Text(
                  AppStrings.activationHeroCaption,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  AppStrings.activationNoMoralScore,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                ),
              ],
            ),
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
          _SuggestedNowCard(choice: suggested),
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
            AppStrings.activationRouteMap,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          waypoints.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) {
              if (items.isEmpty) {
                return Text(AppStrings.activationWaypointEmpty);
              }
              return WaypointRouteMap(
                waypoints: items,
                onSelect: (waypoint) =>
                    context.go('/activation/waypoints?token=${waypoint.token ?? ''}'),
              );
            },
          ),
          const SizedBox(height: ColonySpacing.xl),
          Text(
            AppStrings.activationJourneys,
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
              return _JourneySections(protocols: items);
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
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timeline),
                      title: Text(AppStrings.activationStatus(episode.status)),
                      subtitle: Text(
                        '${episode.initialState.label} → ${episode.targetState.label}',
                      ),
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

class _SuggestedNowCard extends ConsumerWidget {
  const _SuggestedNowCard({required this.choice});

  final ActivationStuckChoice choice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = ActivationVisualCatalog.forType(choice.protocolType);
    return ColonyJourneyCard(
      assetPath: spec.artAsset,
      eyebrow: AppStrings.activationSuggestedNow,
      title: choice.label,
      subtitle: spec.journeyLabel,
      height: 118,
      onTap: () async {
        final episode = await ref
            .read(activationControllerProvider.notifier)
            .startPreferred(type: choice.protocolType);
        if (!context.mounted || episode == null) return;
        context.go('/activation/episodes/${episode.id.value}');
      },
    );
  }
}

class _JourneySections extends StatelessWidget {
  const _JourneySections({required this.protocols});

  final List<ActivationProtocol> protocols;

  @override
  Widget build(BuildContext context) {
    final grouped = <ActivationDaypart, List<ActivationProtocol>>{};
    for (final protocol in protocols) {
      final daypart = ActivationVisualCatalog.forProtocol(protocol).daypart;
      grouped.putIfAbsent(daypart, () => []).add(protocol);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final daypart in ActivationDaypart.values)
          if (grouped[daypart]?.isNotEmpty ?? false) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: ColonySpacing.md,
                bottom: ColonySpacing.sm,
              ),
              child: Text(
                AppStrings.activationDaypartLabel(daypart),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final protocol in grouped[daypart]!)
              Padding(
                padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
                child: _ProtocolJourneyTile(protocol: protocol),
              ),
          ],
      ],
    );
  }
}

class _ProtocolJourneyTile extends StatelessWidget {
  const _ProtocolJourneyTile({required this.protocol});

  final ActivationProtocol protocol;

  @override
  Widget build(BuildContext context) {
    final spec = ActivationVisualCatalog.forProtocol(protocol);
    return ColonyJourneyCard(
      assetPath: spec.artAsset,
      eyebrow: AppStrings.activationProtocolTypeLabel(protocol.protocolType),
      title: protocol.name,
      subtitle: spec.journeyLabel,
      height: 124,
      onTap: protocol.isEnabled
          ? () => context.go(
                '/activation/start?protocol=${protocol.id.value}',
              )
          : null,
    );
  }
}

class _RestoreCard extends ConsumerWidget {
  const _RestoreCard({required this.episode});

  final ActivationEpisode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(activationControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: ColonySpacing.md),
      child: ColonyJourneyCard(
        assetPath: ActivationArtAssets.map,
        eyebrow: AppStrings.activationRestoringTitle,
        title: AppStrings.activationContinueJourney,
        subtitle:
            '${AppStrings.activationStatus(episode.status)} · ${episode.targetState.label}',
        height: 148,
        action: Wrap(
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
