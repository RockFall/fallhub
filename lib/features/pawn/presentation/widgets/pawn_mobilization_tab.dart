import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../activation/application/activation_providers.dart';
import '../../../activation/presentation/widgets/stuck_now_sheet.dart';
import 'pawn_tab_chrome.dart';

class PawnMobilizationTab extends ConsumerWidget {
  const PawnMobilizationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openActivationEpisodeProvider);
    final episodes = ref.watch(activationEpisodesProvider);
    final schedule = ref.watch(activationScheduleContextProvider);
    final now = ref.watch(clockProvider)();
    final suggested = ActivationStuckNowPolicy.choices(
      now: now,
      hasUpcomingFocus: schedule.asData?.value.hasUpcomingFocus ?? false,
    ).first;

    return PawnPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PawnSectionLabel(AppStrings.pawnOrder),
          const SizedBox(height: 8),
          Expanded(
            flex: 5,
            child: open.when(
              loading: () =>
                  const Center(child: PawnMutedText(AppStrings.loading)),
              error: (_, _) => const PawnMutedText(AppStrings.errorGeneric),
              data: (episode) =>
                  _OrderWell(episode: episode, suggested: suggested),
            ),
          ),
          const NeedInspectGroupRule(),
          const PawnSectionLabel(AppStrings.pawnEpisodeLog),
          const SizedBox(height: 4),
          Expanded(
            flex: 4,
            child: episodes.when(
              loading: () => const PawnMutedText(AppStrings.loading),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) {
                if (items.isEmpty) {
                  return const PawnMutedText(AppStrings.pawnNoEpisodes);
                }
                return ListView(
                  children: [
                    for (final episode in items.take(6))
                      PawnLogRow(
                        title: AppStrings.activationStatus(episode.status),
                        detail: episode.targetState.label,
                        onTap: () => context.go(
                          '/activation/episodes/${episode.id.value}?inspect=1',
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          const PawnMutedText(AppStrings.activationNoMoralScore, tiny: true),
        ],
      ),
    );
  }
}

class _OrderWell extends StatelessWidget {
  const _OrderWell({required this.episode, required this.suggested});

  final ActivationEpisode? episode;
  final ActivationStuckChoice suggested;

  @override
  Widget build(BuildContext context) {
    final inRoute = episode != null;
    return ColonyFrame(
      variant: ColonyFrameVariant.inset,
      grain: false,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (inRoute
                    ? AppStrings.activationInRoute
                    : AppStrings.activationAvailable)
                .toUpperCase(),
            style: TextStyle(
              fontFamily: ColonyFonts.familyTiny,
              color: inRoute ? ColonyColors.needsFill : ColonyColors.textGoldHi,
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (inRoute ? episode!.targetState.label : suggested.label)
                .toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: ColonyFonts.familyTiny,
              color: ColonyColors.textPrimary,
              fontSize: 16,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            inRoute
                ? AppStrings.activationStatus(episode!.status)
                : AppStrings.activationSubtitle,
            style: const TextStyle(
              fontFamily: ColonyFonts.familyTiny,
              color: ColonyColors.textMuted,
              fontSize: 11,
              letterSpacing: 0.3,
              height: 1.35,
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (inRoute)
                ColonyButton(
                  height: 30,
                  onPressed: () =>
                      context.go('/activation/episodes/${episode!.id.value}'),
                  child: const Text(AppStrings.activationResume),
                ),
              ColonyButton(
                height: 30,
                onPressed: () => StuckNowSheet.show(context),
                child: const Text(AppStrings.activationStuckNow),
              ),
              ColonyButton(
                variant: ColonyButtonVariant.subtle,
                height: 30,
                onPressed: () => context.go('/activation'),
                child: const Text(AppStrings.pawnOpenRoutes),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
