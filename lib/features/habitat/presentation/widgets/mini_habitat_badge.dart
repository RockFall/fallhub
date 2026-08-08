import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/colony_roster.dart';
import '../../flame/habitat_locations.dart';
import '../../flame/habitat_pawn_draw.dart';
import 'pawn_preview.dart';

/// Spec §49-ish: tiny living portrait in the app chrome (V9.5).
class MiniHabitatBadge extends ConsumerWidget {
  const MiniHabitatBadge({
    super.key,
    this.locationId = HabitatLocationIds.bedroom,
    this.phaseLabel,
  });

  final String locationId;
  final String? phaseLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(colonyRosterProvider);
    ColonyMember? player;
    for (final m in roster) {
      if (m.isPlayer) {
        player = m;
        break;
      }
    }
    player ??= roster.isEmpty ? null : roster.first;
    if (player == null) return const SizedBox.shrink();

    final loc = HabitatLocations.label(locationId);
    final phase = phaseLabel;

    return Tooltip(
      message: AppStrings.habitatMiniHint,
      child: InkWell(
        onTap: () => context.go('/colony/habitat'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: ColonyColors.void_,
            border: Border.all(color: ColonyColors.borderStandard),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PawnPreview(
                appearance: player.appearance,
                size: HabitatPawnDraw.chipPx * 0.42,
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.appearance.name,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    phase == null ? loc : '$loc · $phase',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ColonyColors.textMuted,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
