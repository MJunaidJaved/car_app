import 'package:flutter/material.dart';

class AppColors {
  // Oxford Blue → YInMn Blue brand palette
  static const midnightBlue = Color(0xFF31487A);
  static const dustyBlue = Color(0xFF64748B);
  static const ivory = Color(0xFFD9E1F1);
  static const deepNavy = Color(0xFF192338);
  static const buttercream = Color(0xFFD9E1F1);
  static const electricBlue = Color(0xFF31487A);
  static const skyBlue = Color(0xFF8FB3E2);
  static const cyan = Color(0xFF06B6D4);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFE11D48);

  static const white = Color(0xFFFFFFFF);

  // New: Space Cadet — header gradients, pressed states
  static const spaceCadet = Color(0xFF1E2E4F);

  // Semantic aliases
  static const bg = buttercream;
  static const primary = midnightBlue;
  static const dark = deepNavy;
  static const accent = cyan;
  static const light = skyBlue;
  static const textDark = deepNavy;
  static const textMuted = dustyBlue;
  static const line = ivory;
  static const surfaceBlue = Color(0xFFD9E1F1);
  static const softBlue = Color(0xFFF8FBFF);

  // Backward-compatible aliases (legacy names map to new palette)
  static const cream = white;
  static const sage = dustyBlue;
  static const olive = skyBlue;
  static const moss = electricBlue;
  static const bark = deepNavy;
  static const ink = deepNavy;
  static const sky = surfaceBlue;
  static const mint = Color(0xFFE0F7FF);

  // Status colors
  static const success = emerald;
  static const warning = amber;
  static const error = rose;
  static const sos = rose;

  // Status chip backgrounds
  static const chipPendingBg = Color(0xFFFFF7ED);
  static const chipPendingText = amber;
  static const chipConfirmedBg = electricBlue;
  static const chipConfirmedText = white;
  static const chipCancelledBg = rose;
  static const chipCancelledText = white;
  static const chipCompletedBg = emerald;
  static const chipCompletedText = white;

  // New semantic colors
  static const onlineGreen = Color(0xFF22C55E);
  static const offlineGray = Color(0xFF94A3B8);
  static const ladiesPink = Color(0xFFEC4899);
  static const goldStar = Color(0xFFFBBF24);
  static const infoBlue = Color(0xFF3B82F6);

  // Gradient presets
  static const primaryGradient = LinearGradient(
    colors: [deepNavy, midnightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const heroGradient = LinearGradient(
    colors: [deepNavy, spaceCadet, midnightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Unified card shadow — replaces ad-hoc BoxShadow definitions across screens
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
