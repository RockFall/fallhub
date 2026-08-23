import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/activation_providers.dart';
import 'stuck_now_sheet.dart';

class AgoraReadinessCard extends ConsumerWidget {
  const AgoraReadinessCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openActivationEpisodeProvider);
    final schedule = ref.watch(activationScheduleContextProvider);
    final now = ref.watch(clockProvider)();
    final suggested = ActivationStuckNowPolicy.choices(
      now: now,
      hasUpcomingFocus: schedule.asData?.value.hasUpcomingFocus ?? false,
    ).first;
    final spec = ActivationVisualCatalog.forType(suggested.protocolType);

    return open.when(
      loading: () => const ColonyHomeCard(
        icon: Icons.directions_walk_outlined,
        title: AppStrings.activationTitle,
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => ColonyHomeCard(
        icon: Icons.directions_walk_outlined,
        title: AppStrings.activationTitle,
        child: Text(AppStrings.errorGeneric),
      ),
      data: (episode) {
        if (episode != null) {
          return ColonyJourneyCard(
            assetPath: ActivationArtAssets.map,
            eyebrow: AppStrings.activationInRoute,
            title: AppStrings.activationContinueJourney,
            subtitle:
                '${AppStrings.activationStatus(episode.status)} · ${episode.targetState.label}',
            height: 140,
            onTap: () =>
                context.go('/activation/episodes/${episode.id.value}'),
            action: FilledButton(
              onPressed: () =>
                  context.go('/activation/episodes/${episode.id.value}'),
              child: const Text(AppStrings.activationResume),
            ),
          );
        }
        return ColonyJourneyCard(
          assetPath: spec.artAsset,
          eyebrow: AppStrings.activationAvailable,
          title: suggested.label,
          subtitle: spec.journeyLabel,
          height: 148,
          onTap: () => context.go('/activation'),
          action: Wrap(
            spacing: ColonySpacing.sm,
            children: [
              FilledButton(
                onPressed: () => StuckNowSheet.show(context),
                child: const Text(AppStrings.activationStuckNow),
              ),
              TextButton(
                onPressed: () => context.go('/activation/start'),
                child: const Text(AppStrings.activationStartMorning),
              ),
            ],
          ),
        );
      },
    );
  }
}
