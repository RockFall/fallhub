import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/widgets/command_palette.dart';

class ColonyHomeHeader extends StatelessWidget {
  const ColonyHomeHeader({
    super.key,
    required this.greeting,
    required this.colonyName,
  });

  final String greeting;
  final String colonyName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          greeting,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: ColonySpacing.xs),
        Text(
          colonyName,
          style: text.titleMedium?.copyWith(color: ColonyColors.accentCyan),
        ),
        const SizedBox(height: ColonySpacing.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => CommandPalette.show(context),
            borderRadius: BorderRadius.circular(ColonyRadii.soft),
            child: Ink(
              decoration: BoxDecoration(
                color: ColonyColors.panel,
                borderRadius: BorderRadius.circular(ColonyRadii.soft),
                border: Border.all(color: ColonyColors.borderDark),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ColonySpacing.md,
                  vertical: ColonySpacing.md,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: ColonyColors.textMuted),
                    const SizedBox(width: ColonySpacing.sm),
                    Expanded(
                      child: Text(
                        AppStrings.homeSearchHint,
                        style: text.bodyMedium?.copyWith(
                          color: ColonyColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
