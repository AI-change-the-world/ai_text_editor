import 'dart:io';

import 'package:flutter/material.dart';

import 'app_theme.dart';

class Styles {
  Styles._();

  static double menuBarIconSize = 15;

  static double structureWidth = 200;
  static double toolbarMinSize = 110;

  static Color textButtonColor = Colors.blue;

  static final Size _macOSSize = Size(800, 600);
  static final Size _windowsSize = Size(1280, 720);
  static final Size _linuxSize = Size(1280, 720);

  static Size get size => Platform.isMacOS
      ? _macOSSize
      : Platform.isWindows
          ? _windowsSize
          : _linuxSize;

  /// 根据字体名称获取实际字体
  static String? getFontFamily(String fontFamily) {
    if (fontFamily == 'System') return null;
    if (fontFamily == 'SourceHanSansCN') return 'SourceHanSansCN-Regular';
    return fontFamily;
  }

  /// 浅色主题
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.light.primary,
    scaffoldBackgroundColor: AppColors.light.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.light.primary,
      secondary: AppColors.light.primaryDark,
      surface: AppColors.light.surface,
      error: AppColors.light.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.light.background,
      foregroundColor: AppColors.light.textPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.light.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.light.card,
      elevation: 1,
    ),
    dividerColor: AppColors.light.divider,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: AppColors.light.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        color: AppColors.light.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        color: AppColors.light.textSecondary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.light.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.light.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.light.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.light.inputFocusBorder),
      ),
    ),
    extensions: [AppColors.light],
  );

  /// 暗黑主题
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.dark.primary,
    scaffoldBackgroundColor: AppColors.dark.background,
    colorScheme: ColorScheme.dark(
      primary: AppColors.dark.primary,
      secondary: AppColors.dark.primaryDark,
      surface: AppColors.dark.surface,
      error: AppColors.dark.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.dark.surface,
      foregroundColor: AppColors.dark.textPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.dark.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.dark.card,
      elevation: 1,
    ),
    dividerColor: AppColors.dark.divider,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: AppColors.dark.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        color: AppColors.dark.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        color: AppColors.dark.textSecondary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.dark.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.dark.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.dark.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.dark.inputFocusBorder),
      ),
    ),
    extensions: [AppColors.dark],
  );
}
