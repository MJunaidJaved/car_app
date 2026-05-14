import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Earthy Premium Palette
  static const Color ebony         = Color(0xFF414833); // Primary dark
  static const Color deepEbony     = Color(0xFF2E3323); // Gradient depth / Pressed state
  static const Color resedaGreen   = Color(0xFF737A5D); // Secondary mid
  static const Color sage          = Color(0xFFA4AC86); // Accent light
  static const Color dun           = Color(0xFFCCBFA3); // Warm neutral
  static const Color linen         = Color(0xFFF5E3D2); // Base cream (Scaffold)
  static const Color offWhite      = Color(0xFFEDE8DF); // Input fill
  
  // Semantic Colors
  static const Color successOlive  = Color(0xFF4A7C59);
  static const Color warningAmber  = Color(0xFFD4882A);
  static const Color errorRed      = Color(0xFFB71C1C); // Safety critical red
  
  // Theme Aliases
  static const Color primaryColor   = ebony;
  static const Color secondaryColor = resedaGreen;
  static const Color backgroundColor = linen;
  static const Color surfaceColor    = Colors.white;
  static const Color textPrimary     = ebony;
  static const Color textSecondary   = resedaGreen;
  static const Color textHint        = sage;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: linen,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ebony,
      primary: ebony,
      secondary: resedaGreen,
      surface: Colors.white,
      background: linen,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: ebony,
      onSurface: ebony,
    ),
    
    // Typography
    textTheme: TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: ebony),
      titleTextStyle: TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ebony,
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      shadowColor: ebony.withOpacity(0.08),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ebony,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.pressed)) return deepEbony;
          if (states.contains(MaterialState.disabled)) return sage;
          return ebony;
        }),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return Colors.white.withOpacity(0.6);
          return Colors.white;
        }),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ebony,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: const BorderSide(color: ebony, width: 1.5),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.pressed)) return sage.withOpacity(0.2);
          return Colors.transparent;
        }),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: offWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ebony, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: GoogleFonts.inter(color: sage, fontWeight: FontWeight.w400),
      labelStyle: GoogleFonts.inter(color: resedaGreen, fontWeight: FontWeight.w500),
      prefixIconColor: resedaGreen,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: dun,
      labelStyle: GoogleFonts.inter(
        color: resedaGreen,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      selectedColor: ebony,
      secondaryLabelStyle: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide.none,
      showCheckmark: false,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: ebony.withOpacity(0.1),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return const IconThemeData(color: ebony);
        return const IconThemeData(color: sage);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return GoogleFonts.inter(color: ebony, fontWeight: FontWeight.w600, fontSize: 12);
        }
        return GoogleFonts.inter(color: sage, fontWeight: FontWeight.w500, fontSize: 12);
      }),
    ),
  );
}





