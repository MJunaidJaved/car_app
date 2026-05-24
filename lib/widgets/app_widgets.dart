import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  final String? hintText;
  final int maxLines;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText  = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscureText,
      keyboardType: keyboardType,
      validator:    validator,
      maxLines:     maxLines,
      style: GoogleFonts.inter(
        color:      AppColors.textDark,
        fontSize:   15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hintText,
        labelStyle: GoogleFonts.inter(color: AppColors.sage, fontSize: 14, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: AppColors.sage, size: 20),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:   BorderSide(color: AppColors.sage.withOpacity(0.3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:   BorderSide(color: AppColors.sage.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:   const BorderSide(color: AppColors.moss, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:   const BorderSide(color: AppColors.error, width: 1.5),
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
              foregroundColor: AppColors.bark,
              side: const BorderSide(color: AppColors.bark, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                : Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor:         AppColors.moss,
              foregroundColor:         AppColors.cream,
              disabledBackgroundColor: AppColors.sage,
              elevation:               0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ).copyWith(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.pressed)) return AppColors.bark;
                if (states.contains(MaterialState.disabled)) return AppColors.sage;
                return AppColors.moss;
              }),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      color:       AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize:    16,
                      fontWeight:  FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
    );
  }
}

class VehicleInfoChip extends StatelessWidget {
  final String vehicleText;

  const VehicleInfoChip({super.key, required this.vehicleText});

  @override
  Widget build(BuildContext context) {
    if (vehicleText.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.moss.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car_filled_rounded, color: AppColors.moss, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              vehicleText,
              style: const TextStyle(color: AppColors.bark, fontSize: 12, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}




