import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';
import 'colony_assets.dart';

enum ColonyButtonVariant {
  /// Ocre ButtonBG (confirmações / ações decisivas).
  action,

  /// Grafite ButtonSubtle (ações comuns).
  subtle,
}

/// Textured RimWorld-style button (atlas 9-slice + estados).
class ColonyButton extends StatefulWidget {
  const ColonyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ColonyButtonVariant.action,
    this.expanded = false,
    this.height = 40,
    this.minWidth = 120,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ColonyButtonVariant variant;
  final bool expanded;
  final double height;
  final double minWidth;
  final EdgeInsetsGeometry padding;

  @override
  State<ColonyButton> createState() => _ColonyButtonState();
}

class _ColonyButtonState extends State<ColonyButton> {
  bool _hover = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  String get _atlas {
    if (!_enabled) return ColonyAssets.buttonDisabled;
    if (_pressed) return ColonyAssets.buttonPressed;
    if (_hover) return ColonyAssets.buttonHover;
    return widget.variant == ColonyButtonVariant.action
        ? ColonyAssets.buttonNormal
        : ColonyAssets.menuSection;
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _enabled
              ? (widget.variant == ColonyButtonVariant.action
                  ? ColonyColors.textButton
                  : ColonyColors.textPrimary)
              : ColonyColors.textDisabled,
          fontWeight: FontWeight.w600,
        );

    final button = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: ColonyDurations.fast,
          height: widget.height,
          constraints: BoxConstraints(minWidth: widget.minWidth),
          padding: widget.padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.variant == ColonyButtonVariant.subtle
                ? ColonyColors.subtle
                : ColonyColors.actionBase,
            image: DecorationImage(
              image: AssetImage(_atlas, package: ColonyAssets.package),
              centerSlice: ColonyAssets.nineSliceCenter,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
          child: DefaultTextStyle.merge(
            style: labelStyle ?? const TextStyle(),
            child: IconTheme.merge(
              data: IconThemeData(
                color: labelStyle?.color,
                size: 18,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
