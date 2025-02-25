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

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      color: Colors.blue,
      iconTheme: IconThemeData(color: Colors.white),
    ),
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
}
