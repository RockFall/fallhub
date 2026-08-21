import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// Colorful mini-program tile: generated/asset icon or tinted fallback glyph.
class ColonyMiniAppTile extends StatelessWidget {
  const ColonyMiniAppTile({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAsset,
    this.iconAssetPackage,
    this.backgroundColor = ColonyMiniAppColors.more,
    this.badgeCount,
    this.iconSize = 52,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final String? iconAsset;
  final String? iconAssetPackage;
  final Color backgroundColor;
  final int? badgeCount;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(ColonyRadii.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ColonySpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: _iconFace()),
                    if (badgeCount != null && badgeCount! > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: _Badge(count: badgeCount!),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: ColonySpacing.xs),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(
                  color: ColonyColors.textSecondary,
                  height: 1.15,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconFace() {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ColonyRadii.tile),
      ),
      child: Center(
        child: Icon(
          icon ?? Icons.apps,
          color: Colors.white,
          size: iconSize * 0.46,
        ),
      ),
    );

    final asset = iconAsset;
    if (asset == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(ColonyRadii.tile),
      child: Image.asset(
        asset,
        package: iconAssetPackage,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: ColonyColors.statusCritical,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColonyColors.void_, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
