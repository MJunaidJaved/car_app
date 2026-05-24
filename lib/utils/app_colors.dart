import 'package:flutter/material.dart';

class AppColors {
  // Core palette
  static const cream     = Color(0xFFF2F4EE); // bg, light surfaces
  static const sage      = Color(0xFFA1B09A); // muted text, borders
  static const olive     = Color(0xFF8A9B6E); // secondary icons, chips
  static const moss      = Color(0xFF5F6F4A); // primary actions, active
  static const bark      = Color(0xFF2F3A23); // headers, dark text

  // Semantic aliases
  static const bg        = cream;
  static const white     = Color(0xFFFFFFFF);
  static const primary   = moss;
  static const dark      = bark;
  static const accent    = olive;
  static const light     = sage;
  static const textDark  = bark;
  static const textMuted = sage;

  // Status colors — never change these
  static const success   = moss;
  static const warning   = Color(0xFFE9A84C);
  static const error     = Color(0xFFC0392B);
  static const sos       = Color(0xFFC0392B);
}
