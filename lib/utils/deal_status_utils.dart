import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

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

Color dealStatusColor(String? status) {
  switch (status) {
    case 'confirmed':
      return AppColors.moss;
    case 'started':
      return AppColors.primary;
    case 'completed':
      return AppColors.bark;
    case 'cancelled':
      return Colors.red;
    default:
      return AppColors.sage;
  }
}

bool canTrackDeal(String? status) =>
    status == 'confirmed' || status == 'started';

bool canCancelDeal(String? status) =>
    status == 'pending' || status == 'confirmed';
