import 'dart:io';

import 'package:flutter/material.dart';

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
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
    ),
    dividerColor: Colors.grey.shade200,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
          fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.blue,
      textTheme: ButtonTextTheme.primary,
    ),
  );

  /// 暗黑主题
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Color(0xFF1E1E1E),
    colorScheme: ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Color(0xFF2D2D2D),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF2D2D2D),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Color(0xFF2D2D2D),
      elevation: 1,
    ),
    dividerColor: Colors.grey.shade800,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
          fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white70),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.blue,
      textTheme: ButtonTextTheme.primary,
    ),
  );
}
