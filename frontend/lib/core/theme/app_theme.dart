
import 'package:flutter/material.dart';

class AppTheme {
  // ==========================================
  // JOMIN BRAND COLOURS
  // Change these values to update the theme.
  // ==========================================

  // Primary brand colour (logo burgundy)
  static const Color primaryColor = Color(0xFF7C2140);

  // Darker version of the primary colour
  static const Color primaryDarkColor = Color(0xFF670E27);

  // Main application background
  static const Color backgroundColor = Color(0xFF171316);

  // Cards, dialogs and other surfaces
  static const Color surfaceColor = Color(0xFF251D22);

  // Main text colour
  static const Color textColor = Color(0xFFFFFFFF);

  // Secondary text colour
  static const Color secondaryTextColor = Color(0xFFBDB3B8);

  // ==========================================
  // DARK THEME CONFIGURATION
  // ==========================================

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    // Generate complementary Material colours
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: surfaceColor,
      primary: primaryColor,
      onPrimary: textColor,
    ),

    // Main screen background
    scaffoldBackgroundColor: backgroundColor,

    // App bar styling
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
    ),

    // Button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textColor,
      ),
    ),
  );
}
