import 'package:flutter/material.dart';

/// Fallhub Terminal tokens (ADR-049). Original industrial pixel chrome.
abstract final class ColonyColors {
  // Surfaces
  static const void_ = Color(0xFF0C1014);
  static const window = Color(0xFF121619);
  static const panel = Color(0xFF1A1E22);
  static const raised = Color(0xFF22262A);
  static const tab = Color(0xFF080A0E);
  static const tabActive = Color(0xFFC4A46A);
  static const subtle = Color(0xFF161A1E);
  static const optionUnselected = Color(0xFF2A2C2E);
  static const optionSelected = Color(0xFF4A3C28);
  static const hoverOverlay = Color(0x14FFFFFF);
  static const lightHighlight = Color(0x12FFFFFF);
  static const scrim = Color(0xB3000000);

  static const base = window;
  static const hover = Color(0xFF2A3238);

  // Borders
  static const borderOuter = Color(0xFF050608);
  static const borderDark = Color(0xFF0C1014);
  static const borderStandard = Color(0xFF4A525A);
  static const borderHighlight = Color(0xFF7A848C);
  static const borderSelected = Color(0xFFD2B06A);
  static const borderFocus = Color(0xFF6AD4EC);
  static const borderSeparator = Color(0xFF2A3034);
  static const borderSubtle = borderDark;
  static const borderStrong = borderHighlight;
  static const rivet = Color(0xFF9AA2AA);
  static const rivetCore = Color(0xFF6A727A);

  // Text
  static const textPrimary = Color(0xFFE8E0D4);
  static const textSecondary = Color(0xFFC8C4B8);
  static const textMuted = Color(0xFF8A8E90);
  static const textDisabled = Color(0x995E5E5E);
  static const textInverse = Color(0xFF101316);
  static const textOption = Color(0xFFD2B06A);
  static const textMouseover = Color(0xFFF0D090);
  static const textButton = Color(0xFFECE4D4);
  static const textSeparator = Color(0xFFD2B06A);
  static const textGold = Color(0xFFD2B06A);
  static const textGoldHi = Color(0xFFE8C86A);
  static const textInscribed = Color(0xFF24140C);

  // Copper action
  static const actionBase = Color(0xFF6B4532);
  static const actionHover = Color(0xFF82553C);
  static const actionPressed = Color(0xFF4E3224);
  static const actionBorder = Color(0xFF8A6248);
  static const actionDisabled = Color(0xFF2B2D2D);

  // Accents
  static const accentCyan = Color(0xFF5AD4EC);
  static const accentSand = Color(0xFFC4A46A);
  static const accentMoss = Color(0xFF6AB06E);
  static const accentViolet = Color(0xFFA878C4);
  static const accentOrange = Color(0xFFC47B48);
  static const brass = Color(0xFFC4A46A);

  static const statusGood = Color(0xFF6AB06E);
  static const statusAttention = Color(0xFFD2B06A);
  static const statusRisk = Color(0xFFD27B5F);
  static const statusCritical = Color(0xFFD45A5A);
  static const statusInfo = Color(0xFF5AA8C4);
  static const statusUnknown = Color(0xFF7A8288);
  static const needsFill = accentCyan;

  static const selected = Color(0xFF3B434A);

  // Schedule (legacy aliases)
  static const scheduleAnything = Color(0xFF808080);
  static const scheduleWork = Color(0xFF1A3324);
  static const scheduleSleep = Color(0xFF152238);
  static const scheduleRecreation = Color(0xFF3A2414);
  static const scheduleMeditate = Color(0xFF1A3434);
}

/// Tinted fills for compact day-agenda blocks (home terminal).
abstract final class ColonyAgendaColors {
  static const sleep = Color(0xFF152238);
  static const focus = Color(0xFF1A3324);
  static const meeting = Color(0xFF2A1A38);
  static const meal = Color(0xFF3A2414);
  static const free = Color(0xFF242628);
  static const exercise = Color(0xFF1A3028);
  static const commute = Color(0xFF243040);
  static const social = Color(0xFF2A2430);
  static const recovery = Color(0xFF1A2438);
  static const routine = Color(0xFF2A2A20);
  static const flexible = Color(0xFF2A2824);
  static const unavailable = Color(0xFF2A1818);
}

abstract final class ColonySpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const windowMargin = 12.0;
  static const footerRow = 64.0;
  static const listSeparator = 25.0;
  static const page = 12.0;
  static const section = 8.0;
}

abstract final class ColonyRadii {
  static const none = 0.0;
  static const sm = 4.0;
  static const md = 6.0;
  static const lg = 6.0;
  static const tile = 6.0;
  static const soft = 6.0;
}

/// Saturated fills for leftover mini-app tiles (overflow / Mais).
abstract final class ColonyMiniAppColors {
  static const habitat = Color(0xFF3A8AA8);
  static const pawn = Color(0xFFC4A35A);
  static const work = Color(0xFF8B8F3A);
  static const quests = Color(0xFFC4A46A);
  static const flashcards = Color(0xFF2BB7C4);
  static const musicAtlas = Color(0xFFC45A8A);
  static const research = Color(0xFF7B5EA7);
  static const finance = Color(0xFFD4A017);
  static const health = Color(0xFF6AB06E);
  static const inventory = Color(0xFFA67C52);
  static const travel = Color(0xFF4A90C8);
  static const home = Color(0xFFC47A5A);
  static const zones = Color(0xFF3D9AA8);
  static const people = Color(0xFF5BA86A);
  static const friendships = Color(0xFFC4A35A);
  static const organizations = Color(0xFF5A7A9A);
  static const commitments = Color(0xFF6BA56A);
  static const inbox = Color(0xFFE07050);
  static const tasks = Color(0xFF6B8F71);
  static const chronicle = Color(0xFF8A6A48);
  static const projects = Color(0xFF3D7A8C);
  static const decisions = Color(0xFFA8884A);
  static const schedule = Color(0xFF5B7FBF);
  static const sync = Color(0xFF4A8B9A);
  static const integrations = Color(0xFF8A5A8A);
  static const settings = Color(0xFF5A6A78);
  static const more = Color(0xFF4A5560);
  static const activation = Color(0xFF3D8B7A);
  static const planDay = Color(0xFFC9A24A);
}

abstract final class ColonySizes {
  static const closeButton = Size(120, 40);
  static const quickSearch = Size(240, 24);
  static const gizmo = Size(75, 75);
  static const iconTiny = 16.0;
  static const iconSmall = 24.0;
  static const iconLarge = 40.0;
  static const smallFontHeight = 18.0;
  static const pawnPortrait = 64.0;
  static const navTileMin = 84.0;
  static const workButtonWidth = 92.0;
}

abstract final class ColonyDurations {
  static const fast = Duration(milliseconds: 80);
  static const normal = Duration(milliseconds: 140);
  static const slow = Duration(milliseconds: 220);
}

abstract final class ColonyFonts {
  static const familyPrimary = 'Pixelify Sans';
  static const familyReadable = 'Arimo';
  static const familyTiny = 'Pixelify Sans';
}
