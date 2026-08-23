import 'package:flutter/material.dart';

/// RimWorld-parity chrome tokens (Verse.Widgets + sampled atlases).
abstract final class ColonyColors {
  // Surfaces — Widgets.WindowBGFillColor / MenuSectionBGFillColor / samples
  static const void_ = Color(0xFF080C10);
  static const window = Color(0xFF15191D); // ColorInt(21, 25, 29)
  static const panel = Color(0xFF2A2B2C); // ColorInt(42, 43, 44)
  static const raised = Color(0xFF2B2C2D);
  static const tab = Color(0xFF182028);
  static const subtle = Color(0xFF182228); // ButtonSubtleAtlas fill
  static const optionUnselected = Color(0xFF363636);
  static const optionSelected = Color(0xFF524735);
  static const hoverOverlay = Color(0x0DFFFFFF); // ~5% white
  static const lightHighlight = Color(0x0AFFFFFF); // 4% white
  static const scrim = Color(0xA8000000);

  // Legacy aliases used by existing widgets
  static const base = window;
  static const hover = Color(0xFF32383E);
  static const selected = Color(0xFF3B434A);

  // Borders
  static const borderOuter = Color(0xFF05080B);
  static const borderDark = Color(0xFF1B2125);
  static const borderStandard = Color(0xFF616C7A); // WindowBGBorderColor
  static const borderHighlight = Color(0xFF878787); // MenuSectionBGBorderColor
  static const borderSelected = Color(0xFFD5D8D4);
  static const borderFocus = Color(0xFFCCD9FF);
  static const borderSeparator = Color(0xFF4D4D4D);
  static const borderSubtle = borderDark;
  static const borderStrong = borderHighlight;

  // Text
  static const textPrimary = Color(0xFFE6E6E6);
  static const textSecondary = Color(0xFFE1E1E1);
  static const textMuted = Color(0xFFBDBEBE);
  static const textDisabled = Color(0xCC5E5E5E);
  static const textInverse = Color(0xFF101316);
  static const textOption = Color(0xFFCCD9FF); // NormalOptionColor
  static const textMouseover = Color(0xFFFFFF00); // Color.yellow
  static const textButton = Color(0xFFDFDDDB);
  static const textSeparator = Color(0xFFCCCCCC);

  // Action / ButtonBG sampled centers
  static const actionBase = Color(0xFF6A512E); // ButtonBG
  static const actionHover = Color(0xFF886432); // ButtonBGMouseover
  static const actionPressed = Color(0xFF624927); // ButtonBGClick
  static const actionBorder = Color(0xFF8F7C5F);
  static const actionDisabled = Color(0xFF2B2D2D);

  // Legacy accent aliases → mapped to RimWorld language
  static const accentCyan = Color(0xFF33CCD9); // BarFullTexHor / needs
  static const accentSand = actionBase;
  static const accentMoss = Color(0xFF70C46E);
  static const accentViolet = Color(0xFF715A78);
  static const accentOrange = Color(0xFFD47B48);

  // Status
  static const statusGood = Color(0xFF70C46E);
  static const statusAttention = Color(0xFFD6B54A);
  static const statusRisk = Color(0xFFD47B48);
  static const statusCritical = Color(0xFFC83832);
  static const statusInfo = Color(0xFF6FA9C2);
  static const statusUnknown = Color(0xFF7D8383);
  static const needsFill = accentCyan;

  // Schedule
  static const scheduleAnything = Color(0xFF808080);
  static const scheduleWork = Color(0xFF77783A);
  static const scheduleSleep = Color(0xFF33337F);
  static const scheduleRecreation = Color(0xFF715A78);
  static const scheduleMeditate = Color(0xFF1A3434);
}

abstract final class ColonySpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const windowMargin = 18.0; // Window.StandardMargin
  static const footerRow = 55.0;
  static const listSeparator = 25.0;
}

abstract final class ColonyRadii {
  static const none = 0.0;
  static const sm = 1.0;
  static const md = 2.0;
  static const lg = 2.0;

  /// Soft launcher tiles (home mini-apps). Not used by RimWorld-style chrome.
  static const tile = 16.0;
  static const soft = 14.0;
}

/// Saturated fills for the home mini-app launcher (original palette).
abstract final class ColonyMiniAppColors {
  static const habitat = Color(0xFF2AA8A4);
  static const pawn = Color(0xFFC4A35A);
  static const work = Color(0xFF8B8F3A);
  static const quests = Color(0xFFE07A3D);
  static const flashcards = Color(0xFF2BB7C4);
  static const musicAtlas = Color(0xFFC45A8A);
  static const research = Color(0xFF7B5EA7);
  static const finance = Color(0xFFD4A017);
  static const health = Color(0xFFD45B6A);
  static const inventory = Color(0xFFA67C52);
  static const travel = Color(0xFF4A90C8);
  static const home = Color(0xFFC47A5A);
  static const zones = Color(0xFF3D9AA8);
  static const people = Color(0xFF5BA86A);
  static const organizations = Color(0xFF5A7A9A);
  static const commitments = Color(0xFF6BA56A);
  static const inbox = Color(0xFFE07050);
  static const chronicle = Color(0xFF5A6BB8);
  static const projects = Color(0xFF3D7A8C);
  static const decisions = Color(0xFFA8884A);
  static const schedule = Color(0xFF5B7FBF);
  static const sync = Color(0xFF4A8B9A);
  static const integrations = Color(0xFF8A5A8A);
  static const settings = Color(0xFF5A6A78);
  static const more = Color(0xFF4A5560);
  static const activation = Color(0xFF3D8B7A);
}

abstract final class ColonySizes {
  static const closeButton = Size(120, 40);
  static const quickSearch = Size(240, 24);
  static const gizmo = Size(75, 75);
  static const iconTiny = 24.0;
  static const iconSmall = 36.0;
  static const iconLarge = 64.0;
  static const smallFontHeight = 22.0;
}

abstract final class ColonyDurations {
  static const fast = Duration(milliseconds: 70);
  static const normal = Duration(milliseconds: 120);
  static const slow = Duration(milliseconds: 200);
}

abstract final class ColonyFonts {
  /// Metric-compatible with Arial (GameFont.Small / Medium).
  static const familyPrimary = 'Arimo';

  /// Metric-compatible with Calibri (GameFont.Tiny).
  static const familyTiny = 'Carlito';
}
