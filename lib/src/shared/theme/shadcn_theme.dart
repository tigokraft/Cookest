import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Colors.black;
  static const Color onPrimary = Colors.white;
  static const Color background = Colors.white;
  static const Color onBackground = Colors.black;
  static const Color surface = Colors.white;
  static const Color onSurface = Colors.black;
  static const Color border = Color(0xFFE4E4E7); // Zinc-200
  static const Color inputBorder = Color(0xFFE4E4E7);
  static const Color muted = Color(0xFFF4F4F5); // Zinc-100
  static const Color mutedForeground = Color(0xFF71717A); // Zinc-500
  static const Color destructive = Color(0xFFEF4444); // Red-500

  static const double radius = 6.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: primary, // Use black for secondary too in b&w theme
        onSecondary: onPrimary,
        error: destructive,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
        // background: background, // Deprecated
        // onBackground: onBackground, // Deprecated
        outline: border,
      ),
      // fontFamily: 'Geist', // Removed manual asset
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        // Body text uses Geist via GoogleFonts
        bodyLarge: GoogleFonts.geist(fontSize: 16, color: onBackground),
        bodyMedium: GoogleFonts.geist(fontSize: 14, color: onBackground),
        bodySmall: GoogleFonts.geist(fontSize: 12, color: mutedForeground),
        labelLarge: GoogleFonts.geist(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onBackground,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onBackground,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 2), // Ring effect
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: destructive),
        ),
        hintStyle: const TextStyle(color: mutedForeground),
      ),
    );
  }
}
