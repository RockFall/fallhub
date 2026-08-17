import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class FlashcardRetentionChip extends StatelessWidget {
  const FlashcardRetentionChip({super.key, required this.retention});

  final double? retention;

  @override
  Widget build(BuildContext context) {
    final color = switch (retention) {
      null => ColonyColors.statusUnknown,
      >= 0.85 => ColonyColors.statusGood,
      >= 0.6 => ColonyColors.statusAttention,
      _ => ColonyColors.statusRisk,
    };
    final label = switch (retention) {
      null => AppStrings.flashcardsRetentionUnknown,
      >= 0.85 => AppStrings.flashcardsRetentionFirm,
      >= 0.6 => AppStrings.flashcardsRetentionWarm,
      _ => AppStrings.flashcardsRetentionFragile,
    };
    final percent =
        retention == null ? '' : ' ${(retention! * 100).round()}%';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ColonySpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label$percent',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
