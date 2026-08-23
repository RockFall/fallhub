import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/activation_providers.dart';
import 'stuck_now_sheet.dart';

class AgoraReadinessCard extends ConsumerWidget {
  const AgoraReadinessCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openActivationEpisodeProvider);
    return ColonyHomeCard(
      icon: Icons.directions_walk_outlined,
      title: AppStrings.activationTitle,
      onTap: () => context.go('/activation'),
      child: open.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => Text(AppStrings.errorGeneric),
        data: (episode) {
          if (episode != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.activationInRoute} · ${AppStrings.activationStatus(episode.status)}',
                ),
                const SizedBox(height: ColonySpacing.sm),
                FilledButton(
                  onPressed: () =>
                      context.go('/activation/episodes/${episode.id.value}'),
                  child: const Text(AppStrings.activationResume),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppStrings.activationOperational} · ${AppStrings.activationAvailable}',
              ),
              const SizedBox(height: ColonySpacing.sm),
              Wrap(
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
            ],
          );
        },
      ),
    );
  }
}
