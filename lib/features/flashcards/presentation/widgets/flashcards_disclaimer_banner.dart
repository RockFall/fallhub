import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class FlashcardsDisclaimerBanner extends StatelessWidget {
  const FlashcardsDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ColonySpacing.md),
      decoration: BoxDecoration(
        color: ColonyColors.panel,
        border: Border.all(color: ColonyColors.borderStandard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: ColonyColors.textMuted,
          ),
          const SizedBox(width: ColonySpacing.sm),
          Expanded(
            child: Text(
              AppStrings.flashcardsDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColonyColors.textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
