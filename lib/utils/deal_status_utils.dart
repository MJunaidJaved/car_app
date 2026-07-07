import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// ==================== STATUS LABELS ====================

/// Human-readable label for deal API status values.
String dealStatusLabel(String? status) {
  switch (status) {
    case 'pending':
      return 'Awaiting captain';
    case 'confirmed':
      return 'Confirmed';
    case 'started':
      return 'In progress';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status ?? 'Unknown';
  }
}

// ==================== STATUS COLORS ====================

Color dealStatusColor(String? status) {
  switch (status) {
    case 'confirmed':
      return AppColors.moss;
    case 'started':
      return AppColors.primary;
    case 'completed':
      return AppColors.bark;
    case 'cancelled':
      return AppColors.error;
    default:
      return AppColors.sage;
  }
}

// ==================== STATUS CHECKS ====================

bool canTrackDeal(String? status) =>
    status == 'confirmed' || status == 'started';

bool canCancelDeal(String? status) =>
    status == 'pending' || status == 'confirmed' || status == 'started';

bool isDealActive(String? status) =>
    status == 'pending' || status == 'confirmed' || status == 'started';

bool isDealCompleted(String? status) => status == 'completed';

bool isDealCancelled(String? status) => status == 'cancelled';

// ==================== 🆕 AUTO-DELETE VISIBILITY ====================

/// ✅ Check if booking should be visible (auto-delete logic)
bool isBookingVisible(Map<String, dynamic> booking) {
  final status = (booking['status'] ?? '').toString().toLowerCase();
  final updatedAt = booking['updatedAt']?.toString();

  // Current time
  final now = DateTime.now();

  // Active bookings - always visible
  if (['pending', 'upcoming', 'started'].contains(status)) {
    return true;
  }

  // Confirmed - visible for 24 hours
  if (status == 'confirmed' && updatedAt != null) {
    try {
      final confirmTime = DateTime.parse(updatedAt);
      return now.difference(confirmTime).inHours < 24;
    } catch (_) {
      return true;
    }
  }

  // Completed - visible for 24 hours
  if (status == 'completed' && updatedAt != null) {
    try {
      final completeTime = DateTime.parse(updatedAt);
      return now.difference(completeTime).inHours < 24;
    } catch (_) {
      return true;
    }
  }

  // Cancelled - visible for 24 hours
  if (status == 'cancelled' && updatedAt != null) {
    try {
      final cancelTime = DateTime.parse(updatedAt);
      return now.difference(cancelTime).inHours < 24;
    } catch (_) {
      return true;
    }
  }

  return false;
}

/// ✅ Check if booking is older than 24 hours
bool isBookingOld(Map<String, dynamic> booking) {
  final status = (booking['status'] ?? '').toString().toLowerCase();

  // Only check completed/cancelled/confirmed
  if (!['confirmed', 'completed', 'cancelled'].contains(status)) {
    return false;
  }

  final updatedAt = booking['updatedAt']?.toString();
  if (updatedAt == null) return false;

  try {
    final date = DateTime.parse(updatedAt);
    return DateTime.now().difference(date).inHours >= 24;
  } catch (_) {
    return false;
  }
}

/// ✅ Get days/hours remaining before auto-delete
String getTimeRemaining(Map<String, dynamic> booking) {
  final status = (booking['status'] ?? '').toString().toLowerCase();

  // Only for confirmed/completed/cancelled
  if (!['confirmed', 'completed', 'cancelled'].contains(status)) {
    return 'Active';
  }

  final updatedAt = booking['updatedAt']?.toString();
  if (updatedAt == null) return 'N/A';

  try {
    final date = DateTime.parse(updatedAt);
    final diff = DateTime.now().difference(date);
    final hoursRemaining = 24 - diff.inHours;

    if (hoursRemaining <= 0) return 'Expired';
    if (hoursRemaining < 1) return 'Less than 1 hour';
    if (hoursRemaining < 24) return '${hoursRemaining}h remaining';
    return '${(hoursRemaining / 24).floor()}d ${hoursRemaining % 24}h remaining';
  } catch (_) {
    return 'N/A';
  }
}

// ==================== EXTENSION (Easy Usage) ====================

/// ✅ Extension for booking visibility checks
extension BookingVisibilityExt on Map<String, dynamic> {
  bool get isVisible => isBookingVisible(this);

  bool get canCancel => canCancelDeal(this['status']?.toString());

  bool get canTrack => canTrackDeal(this['status']?.toString());

  bool get isCompleted => isDealCompleted(this['status']?.toString());

  bool get isCancelled => isDealCancelled(this['status']?.toString());

  bool get isActive => isDealActive(this['status']?.toString());

  Color get statusColor => dealStatusColor(this['status']?.toString());

  String get statusLabel => dealStatusLabel(this['status']?.toString());

  bool get isOld => isBookingOld(this);

  String get timeRemaining => getTimeRemaining(this);
}
