import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Colors.greenAccent,
      secondary: Colors.tealAccent,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    cardColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111111),
      elevation: 0,
    ),
  );
}
