import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.buttercream,
        primaryColor: AppColors.midnightBlue,
        colorScheme: const ColorScheme.light(
          primary: AppColors.midnightBlue,
          secondary: AppColors.cyan,
          surface: AppColors.white,
          surfaceContainerHighest: AppColors.surfaceBlue,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: AppColors.deepNavy,
          error: AppColors.error,
        ),
        fontFamily: GoogleFonts.manrope().fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.white),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.ivory, width: 1),
          ),
          shadowColor: AppColors.primary.withValues(alpha:0.12),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.ivory,
          thickness: 1,
          space: 1,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titleTextStyle: const TextStyle(
            color: AppColors.deepNavy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.primary.withValues(alpha:0.12),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.moss,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.ivory,
            disabledForegroundColor: AppColors.dark.withValues(alpha:0.4),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha:0.18),
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.midnightBlue,
            backgroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: const BorderSide(color: AppColors.skyBlue, width: 1.4),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.ivory, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.ivory, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.moss, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(
            color: AppColors.dustyBlue,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            height: 1.4,
          ),
          labelStyle: const TextStyle(
            color: AppColors.dustyBlue,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          prefixIconColor: AppColors.dustyBlue,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.white,
          labelStyle: const TextStyle(
            color: AppColors.deepNavy,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          selectedColor: AppColors.moss,
          secondaryLabelStyle: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: AppColors.ivory, width: 1),
          showCheckmark: false,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.deepNavy,
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          contentTextStyle: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.deepNavy,
            letterSpacing: -0.5,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.deepNavy,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.deepNavy,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: AppColors.midnightBlue,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.dustyBlue,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.moss,
          unselectedItemColor: AppColors.dustyBlue,
          type: BottomNavigationBarType.fixed,
          elevation: 12,
        ),
      );
}

