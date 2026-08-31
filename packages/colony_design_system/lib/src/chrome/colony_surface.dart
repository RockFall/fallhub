import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';
import 'colony_frame.dart';

enum ColonySurfaceKind { window, panel, void_, tab }

/// Terminal surface: riveted frame when available, solid fallback otherwise.
class ColonySurface extends StatelessWidget {
  const ColonySurface({
    super.key,
    required this.child,
    this.kind = ColonySurfaceKind.window,
    this.padding,
    this.width,
    this.height,
    this.selected = false,
    this.clipBehavior = Clip.hardEdge,
  });

  final Widget child;
  final ColonySurfaceKind kind;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool selected;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    if (kind == ColonySurfaceKind.tab) {
      return Container(
        width: width,
        height: height,
        color: ColonyColors.tab,
        padding: padding,
        child: Material(type: MaterialType.transparency, child: child),
      );
    }

    final variant = kind == ColonySurfaceKind.void_
        ? ColonyFrameVariant.inset
        : ColonyFrameVariant.panel;

    return ColonyFrame(
      variant: variant,
      selected: selected,
      padding: padding,
      width: width,
      height: height,
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
}
