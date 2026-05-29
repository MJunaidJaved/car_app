import 'package:flutter/material.dart';

class AppColors {
  // Core palette
  static const cream = Color(0xFFF4F7FB); // bg, light surfaces
  static const sage = Color(0xFF6B7A90); // muted text, borders
  static const olive = Color(0xFF0EA5A4); // secondary icons, chips
  static const moss = Color(0xFF2563EB); // primary actions, active
  static const bark = Color(0xFF102033); // headers, dark text
  static const ink = Color(0xFF0B1220);
  static const sky = Color(0xFFE8F1FF);
  static const mint = Color(0xFFE7FAF7);
  static const line = Color(0xFFD8E2EF);

  // Semantic aliases
  static const bg = cream;
  static const white = Color(0xFFFFFFFF);
  static const primary = moss;
  static const dark = ink;
  static const accent = olive;
  static const light = sage;
  static const textDark = bark;
  static const textMuted = sage;

  // Status colors — never change these
  static const success = moss;
  static const warning = Color(0xFFE9A84C);
  static const error = Color(0xFFC0392B);
  static const sos = Color(0xFFC0392B);
}
