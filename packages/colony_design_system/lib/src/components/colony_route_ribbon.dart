import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// Horizontal station path. Display only — does not jump the user.
class ColonyRouteRibbon extends StatelessWidget {
  const ColonyRouteRibbon({
    super.key,
    required this.labels,
    this.currentIndex = 0,
    this.compact = false,
  });

  final List<String> labels;
  final int currentIndex;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ColonySpacing.xs),
                child: Icon(
                  Icons.chevron_right,
                  size: compact ? 14 : 16,
                  color: ColonyColors.textMuted,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: i == currentIndex
                    ? ColonyMiniAppColors.activation.withValues(alpha: 0.28)
                    : i < currentIndex
                        ? ColonyColors.raised
                        : ColonyColors.panel,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: i == currentIndex
                      ? ColonyMiniAppColors.activation
                      : ColonyColors.borderDark,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? ColonySpacing.sm : ColonySpacing.md,
                  vertical: compact ? 4 : 6,
                ),
                child: Text(
                  labels[i],
                  style: (compact ? text.labelSmall : text.labelMedium)
                      ?.copyWith(
                    color: i == currentIndex
                        ? ColonyColors.textPrimary
                        : ColonyColors.textMuted,
                    fontWeight:
                        i == currentIndex ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
