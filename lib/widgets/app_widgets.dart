import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const ebony         = Color(0xFF414833);
  static const deepEbony     = Color(0xFF2E3323);
  static const resedaGreen   = Color(0xFF737A5D);
  static const sage          = Color(0xFFA4AC86);
  static const dun           = Color(0xFFCCBFA3);
  static const linen         = Color(0xFFF5E3D2);
  static const offWhite      = Color(0xFFEDE8DF);
  
  static const primary   = ebony;
  static const secondary = resedaGreen;
  static const accent    = sage;
  static const bg        = linen;
  static const textDark  = ebony;
  static const textMuted = resedaGreen;
}

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText  = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscureText,
      keyboardType: keyboardType,
      validator:    validator,
      style: GoogleFonts.inter(
        color:      AppColors.textDark,
        fontSize:   15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: GoogleFonts.inter(color: AppColors.resedaGreen, fontSize: 14, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: AppColors.resedaGreen, size: 20),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  AppColors.offWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.ebony, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 18),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isSecondary;

  const AppButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: isSecondary 
        ? OutlinedButton(
            onPressed: isLoading ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ebony,
              side: const BorderSide(color: AppColors.ebony, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ).copyWith(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.pressed)) return AppColors.sage.withOpacity(0.2);
                return Colors.transparent;
              }),
            ),
            child: isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor:         AppColors.ebony,
              foregroundColor:         Colors.white,
              disabledBackgroundColor: AppColors.sage,
              elevation:               0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ).copyWith(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.pressed)) return AppColors.deepEbony;
                if (states.contains(MaterialState.disabled)) return AppColors.sage;
                return AppColors.ebony;
              }),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      color:       Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize:    16,
                      fontWeight:  FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
    );
  }
}




