import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../pawn/presentation/widgets/check_in_sheet.dart';
import 'colony_mini_apps.dart';
import 'widgets/colony_home_digest.dart';
import 'widgets/colony_home_header.dart';
import 'widgets/colony_mini_app_grid.dart';

class ColonyScreen extends ConsumerWidget {
  const ColonyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final inbox = ref.watch(inboxTasksProvider);

    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(AppStrings.errorGeneric)),
      data: (p) {
        if (p == null) return const SizedBox.shrink();
        return Semantics(
          container: true,
          identifier: 'colony.home',
          label: AppStrings.colony,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              final now = DateTime.now().toLocal();
              final launcher = _LauncherColumn(
                profile: p,
                greeting: AppStrings.homeGreeting(now, p.displayName),
                inboxCount: inbox.asData?.value.length ?? 0,
              );
              final digest = const ColonyHomeDigest();
              return SingleChildScrollView(
                padding: const EdgeInsets.all(ColonySpacing.lg),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 420, child: launcher),
                          const SizedBox(width: ColonySpacing.xl),
                          Expanded(child: digest),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          launcher,
                          const SizedBox(height: ColonySpacing.xl),
                          digest,
                        ],
                      ),
              );
            },
          ),
        );
      },
    );
  }
}

class _LauncherColumn extends StatelessWidget {
  const _LauncherColumn({
    required this.profile,
    required this.greeting,
    required this.inboxCount,
  });

  final ColonyProfile profile;
  final String greeting;
  final int inboxCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColonyHomeHeader(
          greeting: greeting,
          colonyName: profile.colonyName,
        ),
        const SizedBox(height: ColonySpacing.lg),
        Semantics(
          container: true,
          identifier: 'colony.home.quick_actions',
          child: ColonyQuickActionBar(
            actions: [
              ColonyQuickAction(
                label: AppStrings.homeQuickCheckIn,
                icon: Icons.favorite_outline,
                iconAsset: ColonyMiniAppAssets.health,
                backgroundColor: ColonyMiniAppColors.health,
                onPressed: () => CheckInSheet.show(context),
              ),
              ColonyQuickAction(
                label: AppStrings.homeQuickStudy,
                icon: Icons.style_outlined,
                iconAsset: ColonyMiniAppAssets.flashcards,
                backgroundColor: ColonyMiniAppColors.flashcards,
                onPressed: () => context.go('/flashcards/study'),
              ),
              ColonyQuickAction(
                label: AppStrings.homeQuickInbox,
                icon: Icons.inbox_outlined,
                iconAsset: ColonyMiniAppAssets.inbox,
                backgroundColor: ColonyMiniAppColors.inbox,
                onPressed: () => context.go('/inbox'),
              ),
              ColonyQuickAction(
                label: AppStrings.homeQuickHabitat,
                icon: Icons.cottage_outlined,
                iconAsset: ColonyMiniAppAssets.habitat,
                backgroundColor: ColonyMiniAppColors.habitat,
                onPressed: () => context.go('/colony/habitat'),
              ),
            ],
          ),
        ),
        const SizedBox(height: ColonySpacing.lg),
        ColonyMiniAppGrid(inboxBadge: inboxCount),
      ],
    );
  }
}
