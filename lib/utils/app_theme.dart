import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color bgColor = Color(0xFF0A0A0F);
  static const Color surfaceColor = Color(0xFF111118);
  static const Color cardColor = Color(0xFF16161F);
  static const Color accentColor = Color(0xFF00E5FF);
  static const Color accentSecondary = Color(0xFF7C4DFF);
  static const Color errorColor = Color(0xFFFF4757);
  static const Color successColor = Color(0xFF2ED573);
  static const Color textColor = Color(0xFFEEEEF5);
  static const Color subtitleColor = Color(0xFF8888AA);
  static const Color dividerColor = Color(0xFF222233);

  // Text styles
  static const TextStyle headlineStyle = TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 1.5,
  );

  static const TextStyle titleStyle = TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 15,
    color: textColor,
    height: 1.5,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: subtitleColor,
    letterSpacing: 0.3,
  );

  static const TextStyle monoStyle = TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 13,
    color: accentColor,
  );

  // Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: accentSecondary,
        surface: surfaceColor,
        error: errorColor,
      ),
      textTheme: const TextTheme(
        headlineLarge: headlineStyle,
        titleMedium: titleStyle,
        bodyMedium: bodyStyle,
        bodySmall: captionStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor),
        ),
        hintStyle: const TextStyle(color: subtitleColor),
        labelStyle: const TextStyle(color: subtitleColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'SpaceMono',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        titleTextStyle: headlineStyle,
        iconTheme: IconThemeData(color: accentColor),
      ),
    );
  }
}
