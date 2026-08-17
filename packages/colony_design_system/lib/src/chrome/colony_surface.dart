import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';
import 'colony_assets.dart';

enum ColonySurfaceKind {
  /// Window / inspect fill (`#15191D`).
  window,

  /// Menu section / panel (`#2A2B2C`).
  panel,

  /// Deep table / empty fill.
  void_,

  /// Flat tab strip without atlas.
  tab,
}

/// RimWorld-style surface: 9-slice atlas when available, solid fallback otherwise.
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
    final atlas = switch (kind) {
      ColonySurfaceKind.window => ColonyAssets.panelBase,
      ColonySurfaceKind.panel => ColonyAssets.menuSection,
      ColonySurfaceKind.void_ || ColonySurfaceKind.tab => null,
    };

    final fill = switch (kind) {
      ColonySurfaceKind.window => ColonyColors.window,
      ColonySurfaceKind.panel =>
        selected ? ColonyColors.optionSelected : ColonyColors.panel,
      ColonySurfaceKind.void_ => ColonyColors.void_,
      ColonySurfaceKind.tab => ColonyColors.tab,
    };

    final borderColor = selected
        ? ColonyColors.borderSelected
        : switch (kind) {
            ColonySurfaceKind.window => ColonyColors.borderStandard,
            ColonySurfaceKind.panel => ColonyColors.borderHighlight,
            ColonySurfaceKind.void_ => ColonyColors.borderDark,
            ColonySurfaceKind.tab => ColonyColors.borderDark,
          };

    Decoration decoration;
    if (atlas != null) {
      decoration = BoxDecoration(
        color: fill,
        image: DecorationImage(
          image: AssetImage(atlas, package: ColonyAssets.package),
          centerSlice: ColonyAssets.nineSliceCenter,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
        ),
        border: selected
            ? Border.all(color: borderColor, width: 1)
            : null,
      );
    } else {
      decoration = BoxDecoration(
        color: fill,
        border: Border.all(color: borderColor, width: 1),
      );
    }

    return Container(
      width: width,
      height: height,
      clipBehavior: clipBehavior,
      decoration: decoration,
      padding: padding,
      // ListTile looks up the nearest Material; without one inside this
      // decorated box, Flutter asserts that ink/background would be hidden.
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}
