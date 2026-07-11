import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // ShareWay — Royal Blue + White theme
  // ============================================================
  static const royalBlue = Color(0xFF2563EB); // Primary
  static const darkRoyalBlue = Color(0xFF1D4ED8); // Headers & buttons
  static const lightRoyalBlue = Color(0xFFDBEAFE); // Cards & highlights
  static const veryLightBlue = Color(0xFFEFF6FF); // Background sections
  static const deepRoyalNavy = Color(0xFF1E3A8A); // Gradient depth / pressed

  // Legacy palette names kept so existing widgets continue to compile,
  // now mapped onto the Royal Blue + White system.
  static const midnightBlue = royalBlue;
  static const dustyBlue = Color(0xFF64748B);
  static const ivory = lightRoyalBlue;
  static const deepNavy = Color(0xFF0F172A); // Body/heading text (dark slate)
  static const buttercream = veryLightBlue;
  static const electricBlue = darkRoyalBlue;
  static const skyBlue = Color(0xFF60A5FA);
  static const cyan = Color(0xFF06B6D4);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFE11D48);

  static const white = Color(0xFFFFFFFF);

  // Header gradients, pressed states
  static const spaceCadet = deepRoyalNavy;

  // Semantic aliases
  static const bg = veryLightBlue;
  static const primary = royalBlue;
  static const primaryDark = darkRoyalBlue;
  static const dark = deepNavy;
  static const accent = cyan;
  static const light = skyBlue;
  static const textDark = deepNavy;
  static const textMuted = dustyBlue;
  static const line = lightRoyalBlue;
  static const surfaceBlue = lightRoyalBlue;
  static const softBlue = veryLightBlue;

  // Backward-compatible aliases (legacy names map to new palette)
  static const cream = white;
  static const sage = dustyBlue;
  static const olive = skyBlue;
  static const moss = darkRoyalBlue;
  static const bark = deepNavy;
  static const ink = deepNavy;
  static const sky = lightRoyalBlue;
  static const mint = Color(0xFFE0F7FF);

  // Status colors
  static const success = emerald;
  static const warning = amber;
  static const error = rose;
  static const sos = rose;

  // Status chip backgrounds
  static const chipPendingBg = Color(0xFFFFF7ED);
  static const chipPendingText = amber;
  static const chipConfirmedBg = darkRoyalBlue;
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
  static const infoBlue = royalBlue;

  // Gradient presets
  static const primaryGradient = LinearGradient(
    colors: [darkRoyalBlue, royalBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const heroGradient = LinearGradient(
    colors: [deepRoyalNavy, darkRoyalBlue, royalBlue],
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

  // ============================================================
  // Vehicle category colors — each vehicle type gets its own
  // vivid accent so category boxes / ride cards / badges pop,
  // while the app frame stays Royal Blue + White.
  // ============================================================
  static const vehicleCar = royalBlue; // #2563EB
  static const vehicleBike = Color(0xFFF97316); // Orange
  static const vehicleBus = Color(0xFF7C3AED); // Purple
  static const vehicleTruck = Color(0xFF059669); // Teal green
  static const vehicleShazore = Color(0xFFD97706); // Amber gold
  static const vehicleLadies = ladiesPink; // Pink
  static const vehicleDaily = darkRoyalBlue; // "All / Daily" tab

  static const Map<String, Color> vehicleColors = {
    'all': vehicleDaily,
    'daily': vehicleDaily,
    'car': vehicleCar,
    'bike': vehicleBike,
    'bus': vehicleBus,
    'truck': vehicleTruck,
    'shazore': vehicleShazore,
    'ladies': vehicleLadies,
  };

  /// Returns a vivid, per-vehicle accent color. Falls back to Royal Blue.
  static Color vehicleColor(String? type) {
    if (type == null) return royalBlue;
    return vehicleColors[type.toLowerCase().trim()] ?? royalBlue;
  }

  /// Soft tinted background for a vehicle color, used behind icons/badges.
  static Color vehicleTint(String? type, {double alpha = 0.14}) {
    return vehicleColor(type).withValues(alpha: alpha);
  }

  /// Two-tone gradient built from a vehicle's accent color, for
  /// eye-catching selected category boxes / stat cards.
  static LinearGradient vehicleGradient(String? type) {
    final c = vehicleColor(type);
    return LinearGradient(
      colors: [c, Color.lerp(c, Colors.black, 0.18) ?? c],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
