import 'package:flutter/material.dart';

import '../chrome/colony_button.dart';
import '../chrome/colony_pixel_icon.dart';
import '../tokens/colony_tokens.dart';

class ColonyWorkRow extends StatelessWidget {
  const ColonyWorkRow({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onPressed,
    this.iconName,
    this.showDivider = true,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onPressed;
  final String? iconName;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              if (iconName != null) ...[
                ColonyPixelIcon(iconName!, size: 24),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColonyColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ColonyButton(
                      onPressed: onPressed,
                      variant: ColonyButtonVariant.inscribed,
                      height: 28,
                      minWidth: ColonySizes.workButtonWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(actionLabel.toUpperCase()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: ColonyColors.borderSeparator),
      ],
    );
  }
}
