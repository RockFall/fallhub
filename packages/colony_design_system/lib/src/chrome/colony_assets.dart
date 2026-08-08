import 'dart:ui' show Rect;

/// Asset paths inside `colony_design_system` (use with `package:`).
abstract final class ColonyAssets {
  static const package = 'colony_design_system';

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

  /// Center slice for 36×36 atlases with ~12 px borders.
  static const nineSliceCenter = Rect.fromLTWH(12, 12, 12, 12);
}
