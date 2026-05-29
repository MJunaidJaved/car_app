import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppConstants {
  // Commission rate
  static const double platformCommissionRate = 0.10; // 10%

  // Wallet
  static const double minimumWalletBalance = 500.0;
  static const double lowBalanceThreshold = 200.0;

  // Ride types
  static const List<String> rideTypes = [
    'office',
    'random',
    'delivery',
    'tour',
  ];

  static const Map<String, String> rideTypeLabels = {
    'office': 'Office Commute',
    'random': 'Random Ride',
    'delivery': 'With Delivery',
    'tour': 'Tour/Travel',
  };

  static const Map<String, IconData> rideTypeIcons = {
    'office': Icons.business,
    'random': Icons.directions_car,
    'delivery': Icons.local_shipping,
    'tour': Icons.landscape,
  };

  // Deal statuses
  static const String dealPending = 'pending';
  static const String dealConfirmed = 'confirmed';
  static const String dealCompleted = 'completed';
  static const String dealCancelled = 'cancelled';

  // Ride statuses
  static const String rideActive = 'active';
  static const String rideFilled = 'filled';
  static const String rideCompleted = 'completed';
  static const String rideCancelled = 'cancelled';
}

class AppHelpers {
  // Format currency
  static String formatCurrency(double amount) {
    return 'Rs. ${amount.toStringAsFixed(0)}';
  }

  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Format time
  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  // Format date time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  // Calculate platform fee
  static double calculatePlatformFee(double fare) {
    return fare * AppConstants.platformCommissionRate;
  }

  // Calculate captain earnings
  static double calculateCaptainEarnings(double fare) {
    return fare - calculatePlatformFee(fare);
  }

  // Show snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFB71C1C) : const Color(0xFF2F3A23),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF414833)),
      ),
    );
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Accepts 03XXXXXXXXX, 3XXXXXXXXX, or +92… (spaces allowed).
  static bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('0')) {
      return RegExp(r'^03[0-9]{9}$').hasMatch(digits);
    }
    if (digits.length == 10 && digits.startsWith('3')) {
      return RegExp(r'^3[0-9]{9}$').hasMatch(digits);
    }
    if (digits.length == 12 && digits.startsWith('92')) {
      final rest = digits.substring(2);
      return RegExp(r'^3[0-9]{9}$').hasMatch(rest);
    }
    return false;
  }

  /// Pakistan mobile to E.164 (+92…).
  static String phoneToE164Pk(String phone) {
    var d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('92')) d = d.substring(2);
    if (d.startsWith('0')) d = d.substring(1);
    if (!RegExp(r'^3[0-9]{9}$').hasMatch(d)) {
      throw FormatException(
          'Enter a valid Pakistani mobile (e.g. 03001234567)');
    }
    return '+92$d';
  }

  // Get ride type color
  static Color getRideTypeColor(String rideType) {
    switch (rideType) {
      case 'office':
        return const Color(0xFF414833);
      case 'random':
        return const Color(0xFF737A5D);
      case 'delivery':
        return const Color(0xFFA4AC86);
      case 'tour':
        return const Color(0xFF4A7C59);
      default:
        return const Color(0xFF737A5D);
    }
  }

  // Get status color
  static Color getStatusColor(String status) {
    switch (status) {
      case AppConstants.dealPending:
        return const Color(0xFFD4882A);
      case AppConstants.dealConfirmed:
        return const Color(0xFF414833);
      case AppConstants.dealCompleted:
        return const Color(0xFF4A7C59);
      case AppConstants.dealCancelled:
        return const Color(0xFFB71C1C);
      default:
        return const Color(0xFF737A5D);
    }
  }
}
