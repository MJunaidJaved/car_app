import 'api_service.dart';
import '../models/ride_model.dart';
import 'package:flutter/material.dart';

/// API facade for deals (legacy name kept for minimal call-site churn).
class FirestoreService {
  // ==================== DEAL CRUD ====================

  Future<String> createDeal({
    required String rideId,
    required double agreedFare,
    String customerMessage = '',
    required double passengerPickupLat,
    required double passengerPickupLng,
    required String passengerPickupAddress,
    double? passengerDropLat,
    double? passengerDropLng,
    String? passengerDropAddress,
  }) async {
    final response = await ApiService.post('/deals', {
      'rideId': rideId,
      'agreedFare': agreedFare,
      'customerMessage': customerMessage,
      'passengerPickupLat': passengerPickupLat,
      'passengerPickupLng': passengerPickupLng,
      'passengerPickupAddress': passengerPickupAddress,
      if (passengerDropLat != null) 'passengerDropLat': passengerDropLat,
      if (passengerDropLng != null) 'passengerDropLng': passengerDropLng,
      if (passengerDropAddress != null)
        'passengerDropAddress': passengerDropAddress,
    });
    final dealId = response['dealId'] as String?;
    if (dealId == null) throw Exception('No dealId in response');
    return dealId;
  }

  // ==================== DEAL ACTIONS ====================

  Future<void> confirmDeal(String dealId) async {
    await ApiService.patch('/deals/$dealId/confirm', {});
  }

  Future<void> cancelDeal(String dealId) async {
    await ApiService.patch('/deals/$dealId/cancel', {});
  }

  Future<void> counterDeal(String dealId, double counterFare,
      {String? message}) async {
    await ApiService.patch('/deals/$dealId/counter', {
      'counterFare': counterFare,
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
    });
  }

  Future<void> startDeal(String dealId) async {
    await ApiService.patch('/deals/$dealId/start', {});
  }

  Future<void> updateBoardingStatus({
    required String dealId,
    required String boardingStatus,
  }) async {
    await ApiService.patch('/deals/$dealId/boarding', {
      'boardingStatus': boardingStatus,
    });
  }

  Future<void> completeDeal(String dealId) async {
    await ApiService.patch('/deals/$dealId/complete', {});
  }

  // ==================== GET DEALS ====================

  Future<Map<String, dynamic>> getDeal(String dealId) async {
    final response = await ApiService.get('/deals/$dealId');
    return response['deal'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMyBookings() async {
    final response = await ApiService.get('/deals/my-bookings');
    return List<Map<String, dynamic>>.from(response['bookings'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getRideDeals(String rideId) async {
    final response = await ApiService.get('/deals/ride/$rideId');
    return List<Map<String, dynamic>>.from(response['deals'] ?? []);
  }

  Future<Map<String, dynamic>> getConfirmedPassengers(String rideId) async {
    return ApiService.get('/deals/ride/$rideId/confirmed');
  }

  // ==================== RATE & REVIEW ====================

  Future<void> rateDeal(String dealId, int rating, String review) async {
    await ApiService.patch('/deals/$dealId/rate', {
      'rating': rating,
      'review': review,
    });
  }

  // ==================== PROFILES ====================

  Future<Map<String, dynamic>> getCaptainProfile(String captainId) async {
    final response = await ApiService.get('/captain/$captainId/profile');
    return response['captain'] as Map<String, dynamic>;
  }

  // ==================== RIDES ====================

  Future<RideModel?> getRideById(String rideId) async {
    try {
      final response = await ApiService.get('/rides/$rideId');
      if (response['ride'] != null) {
        return RideModel.fromMap(
            response['ride'] as Map<String, dynamic>, rideId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== 🆕 AUTO-DELETE FEATURES ====================

  /// ✅ Check if booking should be visible (auto-delete logic)
  static bool isBookingVisible(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toLowerCase();
    final createdAt = booking['createdAt']?.toString();
    final updatedAt = booking['updatedAt']?.toString();

    // Current time
    final now = DateTime.now();

    // ✅ Active bookings - always visible
    if (['pending', 'upcoming', 'started'].contains(status)) {
      return true;
    }

    // ✅ Confirmed - visible for 24 hours
    if (status == 'confirmed' && updatedAt != null) {
      try {
        final confirmTime = DateTime.parse(updatedAt);
        return now.difference(confirmTime).inHours < 24;
      } catch (_) {
        return true;
      }
    }

    // ✅ Completed - visible for 24 hours
    if (status == 'completed' && updatedAt != null) {
      try {
        final completeTime = DateTime.parse(updatedAt);
        return now.difference(completeTime).inHours < 24;
      } catch (_) {
        return true;
      }
    }

    // ✅ Cancelled - visible for 24 hours
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

  /// ✅ Get visible bookings only (auto-filtered)
  Future<List<Map<String, dynamic>>> getVisibleBookings() async {
    final allBookings = await getMyBookings();
    return allBookings
        .where((b) => FirestoreService.isBookingVisible(b))
        .toList();
  }

  /// ✅ Delete a booking permanently
  Future<void> deleteBooking(String dealId) async {
    await ApiService.delete('/deals/$dealId');
  }

  /// ✅ Delete multiple bookings
  Future<void> deleteBookings(List<String> dealIds) async {
    for (final id in dealIds) {
      await deleteBooking(id);
    }
  }

  /// ✅ Auto-cleanup old bookings (run periodically)
  Future<int> cleanupOldBookings() async {
    try {
      final allBookings = await getMyBookings();
      int deletedCount = 0;

      for (final booking in allBookings) {
        final status = (booking['status'] ?? '').toString().toLowerCase();
        final updatedAt = booking['updatedAt']?.toString();

        // Skip active bookings
        if (['pending', 'upcoming', 'started'].contains(status)) {
          continue;
        }

        // Check if older than 24 hours
        if (updatedAt != null) {
          try {
            final updateTime = DateTime.parse(updatedAt);
            final diff = DateTime.now().difference(updateTime);

            if (diff.inHours >= 24) {
              final dealId = booking['id'] ?? booking['dealId'];
              if (dealId != null && dealId is String) {
                await deleteBooking(dealId);
                deletedCount++;
                print('✅ Deleted old booking: $dealId (Status: $status)');
              }
            }
          } catch (_) {
            // Skip if date parsing fails
          }
        }
      }

      print('✅ Cleanup complete: $deletedCount bookings deleted');
      return deletedCount;
    } catch (e) {
      print('❌ Cleanup error: $e');
      return 0;
    }
  }

  /// ✅ Schedule auto-cleanup (call periodically)
  void scheduleAutoCleanup({int intervalHours = 6}) {
    // This will be called by a timer or background service
    // Implement in main.dart or using a service
  }

  // ==================== 🆕 BULK OPERATIONS ====================

  /// ✅ Get booking count by status
  Future<Map<String, int>> getBookingCounts() async {
    final bookings = await getMyBookings();
    final counts = {
      'all': bookings.length,
      'upcoming': 0,
      'confirmed': 0,
      'completed': 0,
      'cancelled': 0,
    };

    for (final b in bookings) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      final tabStatus = (b['tabStatus'] ?? '').toString().toLowerCase();

      if (tabStatus == 'upcoming' ||
          status == 'pending' ||
          status == 'started') {
        counts['upcoming'] = (counts['upcoming'] ?? 0) + 1;
      } else if (tabStatus == 'confirmed' || status == 'confirmed') {
        counts['confirmed'] = (counts['confirmed'] ?? 0) + 1;
      } else if (status == 'completed') {
        counts['completed'] = (counts['completed'] ?? 0) + 1;
      } else if (status == 'cancelled') {
        counts['cancelled'] = (counts['cancelled'] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// ✅ Get bookings by status
  Future<List<Map<String, dynamic>>> getBookingsByStatus(String status) async {
    final allBookings = await getMyBookings();
    return allBookings.where((b) {
      final bStatus = (b['status'] ?? '').toString().toLowerCase();
      final tabStatus = (b['tabStatus'] ?? '').toString().toLowerCase();

      if (status == 'all') return true;
      if (status == 'upcoming') {
        return tabStatus == 'upcoming' ||
            bStatus == 'pending' ||
            bStatus == 'started';
      }
      if (status == 'confirmed') {
        return tabStatus == 'confirmed' || bStatus == 'confirmed';
      }
      return bStatus == status;
    }).toList();
  }

  // ==================== 🆕 DEAL STATUS HELPERS ====================

  /// ✅ Check if deal can be cancelled
  static bool canCancelDeal(String status) {
    return ['pending', 'upcoming', 'started'].contains(status.toLowerCase());
  }

  /// ✅ Check if deal can be tracked
  static bool canTrackDeal(String status) {
    return ['confirmed', 'started'].contains(status.toLowerCase());
  }

  /// ✅ Check if deal is completed
  static bool isDealCompleted(String status) {
    return status.toLowerCase() == 'completed';
  }

  /// ✅ Check if deal is cancelled
  static bool isDealCancelled(String status) {
    return status.toLowerCase() == 'cancelled';
  }

  /// ✅ Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'started':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// ✅ Get status label
  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'started':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

// ==================== EXTENSIONS ====================

/// ✅ Extension for booking visibility checks
extension BookingVisibility on Map<String, dynamic> {
  bool get isVisible => FirestoreService.isBookingVisible(this);

  bool get canCancel => ['pending', 'upcoming', 'started']
      .contains((this['status'] ?? '').toString().toLowerCase());

  bool get canTrack => ['confirmed', 'started']
      .contains((this['status'] ?? '').toString().toLowerCase());

  bool get isCompleted =>
      (this['status'] ?? '').toString().toLowerCase() == 'completed';

  bool get isCancelled =>
      (this['status'] ?? '').toString().toLowerCase() == 'cancelled';

  Color get statusColor =>
      FirestoreService.getStatusColor((this['status'] ?? '').toString());

  String get statusLabel =>
      FirestoreService.getStatusLabel((this['status'] ?? '').toString());

  bool get isOld => _isOlderThan24Hours();

  bool _isOlderThan24Hours() {
    final updatedAt = this['updatedAt']?.toString();
    if (updatedAt == null) return false;
    try {
      final date = DateTime.parse(updatedAt);
      return DateTime.now().difference(date).inHours >= 24;
    } catch (_) {
      return false;
    }
  }
}
