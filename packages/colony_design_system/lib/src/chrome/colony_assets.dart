import 'dart:ui' show Rect;

/// Asset paths inside `colony_design_system` (use with [package]).
abstract final class ColonyGfx {
  static const package = 'colony_design_system';

  static const metalGrain = 'assets/ui/terminal/textures/metal_grain.png';
  static const hullPlates = 'assets/ui/terminal/textures/hull_plates.png';
  static const portraitDefault =
      'assets/ui/terminal/portraits/pawn_default.png';
  static const panelRivet = 'assets/ui/terminal/chrome/panel_rivet.png';
  static const panelInset = 'assets/ui/terminal/chrome/panel_inset.png';
  static const buttonCopper = 'assets/ui/terminal/chrome/button_copper.png';
  static const buttonCopperPressed =
      'assets/ui/terminal/chrome/button_copper_pressed.png';

  static String icon(String name) => 'assets/ui/terminal/icons/$name.png';

  static String iconMono(String name) =>
      'assets/ui/terminal/icons/${name}_mono.png';
}

/// Asset paths inside `colony_design_system` (use with `package:`).
abstract final class ColonyAssets {
  static const package = ColonyGfx.package;

  static const panelBase = 'assets/ui/chrome/panel_base.9.png';
  static const menuSection = 'assets/ui/chrome/menu_section.9.png';
  static const buttonNormal = 'assets/ui/chrome/button_text_normal.9.png';
  static const buttonHover = 'assets/ui/chrome/button_text_hover.9.png';
  static const buttonPressed = 'assets/ui/chrome/button_text_pressed.9.png';
  static const buttonDisabled = 'assets/ui/chrome/button_text_disabled.9.png';
  static const voidFill = 'assets/ui/chrome/void_fill.png';
  static const altRow = 'assets/ui/chrome/alt_row.png';
  static const lightHighlight = 'assets/ui/chrome/light_highlight.png';
  static const needsBarFill = 'assets/ui/chrome/needs_bar_fill.png';

  /// Center slice for 36×36 atlases with ~10 px corners (rivets stay put).
  static const nineSliceCenter = Rect.fromLTWH(10, 10, 16, 16);
}
