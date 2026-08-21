import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';
import 'colony_mini_app_tile.dart';

class ColonyQuickAction {
  const ColonyQuickAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAsset,
    this.iconAssetPackage,
    this.backgroundColor = ColonyMiniAppColors.more,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final String? iconAsset;
  final String? iconAssetPackage;
  final Color backgroundColor;
}

/// Four equal primary shortcuts, Alipay-style pay-bar analog.
class ColonyQuickActionBar extends StatelessWidget {
  const ColonyQuickActionBar({
    super.key,
    required this.actions,
  });

  final List<ColonyQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColonyColors.panel,
        borderRadius: BorderRadius.circular(ColonyRadii.soft),
        border: Border.all(color: ColonyColors.borderDark),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ColonySpacing.sm,
          ColonySpacing.md,
          ColonySpacing.sm,
          ColonySpacing.sm,
        ),
        child: Row(
          children: [
            for (final action in actions)
              Expanded(
                child: ColonyMiniAppTile(
                  label: action.label,
                  onPressed: action.onPressed,
                  icon: action.icon,
                  iconAsset: action.iconAsset,
                  iconAssetPackage: action.iconAssetPackage,
                  backgroundColor: action.backgroundColor,
                  iconSize: 56,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
