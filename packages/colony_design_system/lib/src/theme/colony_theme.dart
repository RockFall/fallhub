import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/colony_tokens.dart';

abstract final class ColonyTheme {
  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: ColonyColors.actionBase,
      onPrimary: ColonyColors.textButton,
      secondary: ColonyColors.needsFill,
      onSecondary: ColonyColors.textInverse,
      error: ColonyColors.statusCritical,
      onError: ColonyColors.textPrimary,
      surface: ColonyColors.window,
      onSurface: ColonyColors.textPrimary,
      surfaceContainerHighest: ColonyColors.panel,
      surfaceContainerHigh: ColonyColors.raised,
      surfaceContainer: ColonyColors.window,
      surfaceContainerLow: ColonyColors.void_,
      surfaceContainerLowest: ColonyColors.void_,
      onSurfaceVariant: ColonyColors.textMuted,
      outline: ColonyColors.borderStandard,
      outlineVariant: ColonyColors.borderDark,
      tertiary: ColonyColors.textOption,
      onTertiary: ColonyColors.textInverse,
    );

    final textTheme = _textTheme(
      ColonyColors.textPrimary,
      ColonyColors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: ColonyFonts.familyPrimary,
      scaffoldBackgroundColor: ColonyColors.void_,
      canvasColor: ColonyColors.window,
      dividerColor: ColonyColors.borderSeparator,
      splashFactory: NoSplash.splashFactory,
      highlightColor: ColonyColors.lightHighlight,
      hoverColor: ColonyColors.hoverOverlay,
      focusColor: ColonyColors.borderFocus.withValues(alpha: 0.25),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(
        color: ColonyColors.textSecondary,
        size: 20,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ColonyColors.panel,
        foregroundColor: ColonyColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const Border(
          bottom: BorderSide(color: ColonyColors.borderStandard, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: ColonyColors.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.md),
          side: const BorderSide(color: ColonyColors.borderHighlight),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColonyColors.optionUnselected,
        disabledColor: ColonyColors.actionDisabled,
        selectedColor: ColonyColors.optionSelected,
        secondarySelectedColor: ColonyColors.optionSelected,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelStyle: textTheme.bodySmall!,
        secondaryLabelStyle: textTheme.bodySmall!,
        brightness: Brightness.dark,
        side: const BorderSide(color: ColonyColors.borderStandard),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.sm),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: ColonyColors.lightHighlight,
        iconColor: ColonyColors.textSecondary,
        textColor: ColonyColors.textPrimary,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.sm),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ColonyColors.borderSeparator,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColonyColors.window,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.md),
          side: const BorderSide(color: ColonyColors.borderStandard),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColonyColors.window,
        modalBackgroundColor: ColonyColors.window,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ColonyRadii.md),
          ),
          side: BorderSide(color: ColonyColors.borderStandard),
        ),
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColonyColors.panel,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: ColonyColors.textMouseover,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.md),
          side: const BorderSide(color: ColonyColors.borderStandard),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: ColonyColors.borderSelected,
        labelColor: ColonyColors.textPrimary,
        unselectedLabelColor: ColonyColors.textMuted,
        dividerColor: ColonyColors.borderSeparator,
        overlayColor: WidgetStateProperty.all(ColonyColors.hoverOverlay),
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(style: _actionButtonStyle()),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _actionButtonStyle()),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _subtleButtonStyle()),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColonyColors.textOption,
          textStyle: textTheme.labelLarge,
          overlayColor: ColonyColors.hoverOverlay,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColonyColors.actionBase,
        foregroundColor: ColonyColors.textButton,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ColonyRadii.md)),
          side: BorderSide(color: ColonyColors.actionBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColonyColors.void_,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ColonySpacing.md,
          vertical: ColonySpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.md),
          borderSide: const BorderSide(color: ColonyColors.borderStandard),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.md),
          borderSide: const BorderSide(color: ColonyColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.md),
          borderSide: const BorderSide(color: ColonyColors.borderFocus),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(color: ColonyColors.textMuted),
        hintStyle: textTheme.bodySmall?.copyWith(color: ColonyColors.textMuted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColonyColors.actionBase;
          }
          return ColonyColors.void_;
        }),
        checkColor: WidgetStateProperty.all(ColonyColors.textButton),
        side: const BorderSide(color: ColonyColors.borderStandard),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.sm),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ColonyColors.window,
          border: Border.all(color: ColonyColors.borderStandard),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: ColonyColors.textPrimary),
        waitDuration: const Duration(milliseconds: 350),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ColonyColors.needsFill,
        linearTrackColor: ColonyColors.void_,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColonyColors.tab,
        indicatorColor: ColonyColors.raised,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? ColonyColors.textPrimary
                : ColonyColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? ColonyColors.textPrimary
                : ColonyColors.textMuted,
            size: 20,
          );
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: ColonyColors.tab,
        selectedIconTheme: IconThemeData(color: ColonyColors.textPrimary),
        unselectedIconTheme: IconThemeData(color: ColonyColors.textMuted),
        selectedLabelTextStyle: TextStyle(color: ColonyColors.textPrimary),
        unselectedLabelTextStyle: TextStyle(color: ColonyColors.textMuted),
        indicatorColor: ColonyColors.raised,
      ),
    );
  }

  /// Light is not a RimWorld target — keep dark chrome.
  static ThemeData light() => dark();

  static ButtonStyle _actionButtonStyle() {
    return ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return ColonyColors.actionDisabled;
        }
        if (states.contains(WidgetState.pressed)) {
          return ColonyColors.actionPressed;
        }
        if (states.contains(WidgetState.hovered)) {
          return ColonyColors.actionHover;
        }
        return ColonyColors.actionBase;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return ColonyColors.textDisabled;
        }
        return ColonyColors.textButton;
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(120, 40)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.md),
          side: const BorderSide(color: ColonyColors.actionBorder),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: ColonyFonts.familyPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ButtonStyle _subtleButtonStyle() {
    return ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return ColonyColors.optionSelected;
        }
        if (states.contains(WidgetState.hovered)) {
          return ColonyColors.raised;
        }
        return ColonyColors.subtle;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return ColonyColors.textMouseover;
        }
        return ColonyColors.textPrimary;
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      side: const WidgetStatePropertyAll(
        BorderSide(color: ColonyColors.borderStandard),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(88, 36)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ColonyRadii.md),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    TextStyle tiny(Color c) => TextStyle(
          fontFamily: ColonyFonts.familyTiny,
          color: c,
          fontSize: 11,
          height: 1.10,
          fontWeight: FontWeight.w400,
        );
    TextStyle small(Color c) => TextStyle(
          fontFamily: ColonyFonts.familyPrimary,
          color: c,
          fontSize: 14,
          height: ColonySizes.smallFontHeight / 14,
          fontWeight: FontWeight.w400,
        );
    TextStyle medium(Color c) => TextStyle(
          fontFamily: ColonyFonts.familyPrimary,
          color: c,
          fontSize: 18,
          height: 1.14,
          fontWeight: FontWeight.w500,
        );

    return TextTheme(
      headlineMedium: medium(primary).copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.08,
      ),
      titleLarge: medium(primary).copyWith(fontWeight: FontWeight.w600),
      titleMedium: small(primary).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: small(primary).copyWith(fontSize: 16),
      bodyMedium: small(primary),
      bodySmall: tiny(secondary),
      labelLarge: small(primary).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: tiny(secondary),
    );
  }
}
