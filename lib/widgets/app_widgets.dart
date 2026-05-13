import 'package:flutter/material.dart';

class AppColors {
  static const primary   = Color(0xFF39988E);
  static const dark      = Color(0xFF1F6059);
  static const light     = Color(0xFFB6D7D1);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF0D1F1E);
  static const textMuted = Color(0xFF7A9E9B);
}

class TealField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const TealField({
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
      style: const TextStyle(
        color:      AppColors.textDark,
        fontSize:   15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  const Color(0xFFF0F7F6),
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
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}

class TealButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const TealButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:         AppColors.primary,
          foregroundColor:         AppColors.white,
          disabledBackgroundColor: AppColors.light,
          elevation:               0,
          shadowColor:             Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  color:       AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize:    16,
                  fontWeight:  FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}