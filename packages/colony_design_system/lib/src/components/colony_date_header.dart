import 'package:flutter/material.dart';

import '../chrome/colony_frame.dart';
import '../chrome/colony_icon_button.dart';
import '../chrome/colony_pixel_icon.dart';
import '../tokens/colony_tokens.dart';

class ColonyDateHeader extends StatelessWidget {
  const ColonyDateHeader({
    super.key,
    required this.label,
    this.onMenu,
    this.onLeading,
    this.menuSemanticLabel,
    this.leadingSemanticLabel,
  });

  final String label;
  final VoidCallback? onMenu;
  final VoidCallback? onLeading;
  final String? menuSemanticLabel;
  final String? leadingSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return ColonyFrame(
      variant: ColonyFrameVariant.panel,
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Semantics(
              button: onLeading != null,
              label: leadingSemanticLabel,
              child: InkWell(
                onTap: onLeading,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: ColonyPixelIcon(
                    'grid',
                    size: 16,
                    mono: true,
                    color: ColonyColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColonyColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.9,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ColonyIconButton(
              iconName: 'menu',
              size: 32,
              iconSize: 16,
              color: ColonyColors.textSecondary,
              semanticLabel: menuSemanticLabel ?? 'Menu',
              onPressed: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}
