import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// Soft card for the home launcher feed. No 9-slice chrome.
class ColonyHomeCard extends StatelessWidget {
  const ColonyHomeCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.action,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? action;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final body = Padding(
      padding: padding ?? const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: ColonyColors.accentCyan),
                  const SizedBox(width: ColonySpacing.sm),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: text.titleSmall?.copyWith(
                      color: ColonyColors.textPrimary,
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

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: ColonyColors.panel,
        borderRadius: BorderRadius.circular(ColonyRadii.soft),
        border: Border.all(color: ColonyColors.borderDark),
      ),
      child: body,
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
