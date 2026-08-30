import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';
import 'colony_frame.dart';
import 'colony_pixel_icon.dart';

/// Riveted square glyph button (hamburger, chrome tools). Not a copper CTA.
class ColonyIconButton extends StatelessWidget {
  const ColonyIconButton({
    super.key,
    required this.iconName,
    this.onPressed,
    this.size = 32,
    this.iconSize = 16,
    this.color = ColonyColors.textSecondary,
    this.semanticLabel,
  });

  final String iconName;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? iconName,
      child: ColonyFrame(
        variant: ColonyFrameVariant.tile,
        width: size,
        height: size,
        padding: EdgeInsets.zero,
        onTap: onPressed,
        child: Center(
          child: ColonyPixelIcon(
            iconName,
            size: iconSize,
            mono: true,
            color: color,
          ),
        ),
      ),
    );
  }
}
