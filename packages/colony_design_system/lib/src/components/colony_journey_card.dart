import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// Illustrated journey tile for launcher-style lists.
class ColonyJourneyCard extends StatelessWidget {
  const ColonyJourneyCard({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.assetPath,
    this.onTap,
    this.action,
    this.height = 132,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final String? assetPath;
  final VoidCallback? onTap;
  final Widget? action;
  final double height;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(ColonyRadii.soft),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            const Positioned.fill(
              child: ColoredBox(color: ColonyColors.panel),
            ),
            if (assetPath != null)
              Positioned.fill(
                child: Image.asset(
                  assetPath!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: ColonyColors.panel,
                  ),
                ),
              ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF2080C10),
                      Color(0x66080C10),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ColonySpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (eyebrow != null)
                    Text(
                      eyebrow!,
                      style: text.labelSmall?.copyWith(
                        color: ColonyMiniAppColors.activation,
                        letterSpacing: 0.4,
                      ),
                    ),
                  if (eyebrow != null) const SizedBox(height: ColonySpacing.sm),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: ColonySpacing.xs),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: ColonySpacing.sm),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ColonyRadii.soft),
        child: card,
      ),
    );
  }
}
