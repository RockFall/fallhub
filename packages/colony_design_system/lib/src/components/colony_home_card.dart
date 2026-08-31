import 'package:flutter/material.dart';

import '../chrome/colony_frame.dart';
import '../chrome/colony_pixel_icon.dart';
import '../tokens/colony_tokens.dart';

/// Terminal card for feeds (home digest, other screens).
class ColonyHomeCard extends StatelessWidget {
  const ColonyHomeCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.iconName,
    this.action,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final String? iconName;
  final Widget? action;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final body = Padding(
      padding: padding ?? const EdgeInsets.all(ColonySpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (iconName != null) ...[
                  ColonyPixelIcon(
                    iconName!,
                    size: 16,
                    mono: true,
                    color: ColonyColors.accentCyan,
                  ),
                  const SizedBox(width: ColonySpacing.sm),
                ] else if (icon != null) ...[
                  Icon(icon, size: 16, color: ColonyColors.accentCyan),
                  const SizedBox(width: ColonySpacing.sm),
                ],
                Expanded(
                  child: Text(
                    title!.toUpperCase(),
                    style: text.titleSmall?.copyWith(
                      color: ColonyColors.textGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: ColonySpacing.md),
          ],
          child,
        ],
      ),
    );

    return ColonyFrame(
      variant: ColonyFrameVariant.panel,
      onTap: onTap,
      child: body,
    );
  }
}
