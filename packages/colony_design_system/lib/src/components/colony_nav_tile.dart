import 'package:flutter/material.dart';

import '../chrome/colony_frame.dart';
import '../chrome/colony_pixel_icon.dart';
import '../tokens/colony_tokens.dart';

class ColonyNavTile extends StatelessWidget {
  const ColonyNavTile({
    super.key,
    required this.label,
    required this.onPressed,
    required this.iconName,
    this.badgeCount,
  });

  final String label;
  final VoidCallback onPressed;
  final String iconName;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ColonyFrame(
        variant: ColonyFrameVariant.tile,
        onTap: onPressed,
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ColonyPixelIcon(iconName, size: 34),
                  const SizedBox(height: 8),
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ColonyColors.textGold,
                      fontSize: 10,
                      letterSpacing: 0.8,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(top: -2, right: 0, child: _Badge(count: badgeCount!)),
          ],
        ),
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
