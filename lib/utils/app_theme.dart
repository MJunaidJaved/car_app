import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.olive,
          surface: AppColors.white,
          background: AppColors.bg,
          onPrimary: AppColors.cream,
          onSurface: AppColors.bark,
          error: AppColors.error,
        ),
        fontFamily: GoogleFonts.manrope().fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bark,
          foregroundColor: AppColors.cream,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.cream),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.cream,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.line, width: 1),
          ),
          shadowColor: AppColors.dark.withOpacity(0.08),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: const BorderSide(color: AppColors.line, width: 1.5),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintStyle: const TextStyle(
              color: AppColors.sage, fontWeight: FontWeight.w400),
          labelStyle: const TextStyle(
              color: AppColors.sage, fontWeight: FontWeight.w500),
          prefixIconColor: AppColors.sage,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.sky,
          labelStyle: const TextStyle(
            color: AppColors.bark,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          selectedColor: AppColors.primary,
          secondaryLabelStyle: const TextStyle(
            color: AppColors.cream,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: AppColors.sage.withOpacity(0.5)),
          showCheckmark: false,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.bark,
          behavior: SnackBarBehavior.floating,
          elevation: 12,
          contentTextStyle: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
}
