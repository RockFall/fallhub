import 'package:flutter/material.dart';

import '../chrome/colony_surface.dart';
import '../tokens/colony_tokens.dart';

class ColonyPanel extends StatelessWidget {
  const ColonyPanel({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.actions = const [],
    this.selected = false,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.helpText,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final List<Widget> actions;
  final bool selected;
  final bool collapsible;
  final bool initiallyExpanded;
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: ColonyColors.textSeparator),
          const SizedBox(width: ColonySpacing.sm),
        ],
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ColonyColors.textSeparator,
                  letterSpacing: 0.4,
                ),
          ),
        ),
        if (helpText != null)
          Tooltip(
            message: helpText!,
            child: const Icon(
              Icons.help_outline,
              size: 14,
              color: ColonyColors.textMuted,
            ),
          ),
        ...actions,
      ],
    );

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(
        ColonySpacing.windowMargin,
        ColonySpacing.md,
        ColonySpacing.windowMargin,
        ColonySpacing.windowMargin,
      ),
      child: child,
    );

    return ColonySurface(
      kind: ColonySurfaceKind.panel,
      selected: selected,
      child: collapsible
          ? Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: initiallyExpanded,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: ColonySpacing.windowMargin,
                  vertical: ColonySpacing.xs,
                ),
                childrenPadding: EdgeInsets.zero,
                iconColor: ColonyColors.textMuted,
                collapsedIconColor: ColonyColors.textMuted,
                title: header,
                children: [body],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ColonySpacing.windowMargin,
                    ColonySpacing.md,
                    ColonySpacing.windowMargin,
                    0,
                  ),
                  child: header,
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(top: ColonySpacing.sm),
                  color: ColonyColors.borderSeparator,
                ),
                body,
              ],
            ),
    );
  }
}
