import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'firestore_service.dart'; // ✅ Added for isBookingVisible

/// Real-time passenger bookings via Firestore, with API polling fallback.
class DealRealtimeService {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Timer? _pollTimer;

  void listenPassengerBookings({
    required void Function(List<Map<String, dynamic>> bookings) onData,
    void Function(Object error)? onError,
  }) {
    stop();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _startPolling(onData, onError);
      return;
    }

    try {
      _subscription = FirebaseFirestore.instance
          .collection('deals')
          .where('customerId', isEqualTo: uid)
          .snapshots()
          .listen(
        (snap) async {
          final bookings = <Map<String, dynamic>>[];
          for (final doc in snap.docs) {
            var deal = <String, dynamic>{'id': doc.id, ...doc.data()};
            deal = await _attachRide(deal);
            final normalized = _normalizeBooking(deal);

            // ✅ AUTO-DELETE: Only add visible bookings
            if (FirestoreService.isBookingVisible(normalized)) {
              bookings.add(normalized);
            }
          }
          bookings.sort((a, b) {
            final aT = a['createdAt']?.toString() ?? '';
            final bT = b['createdAt']?.toString() ?? '';
            return bT.compareTo(aT);
          });
          onData(bookings);
        },
        onError: (e) {
          debugPrint('DealRealtimeService stream error: $e');
          _startPolling(onData, onError);
        },
      );
    } catch (e) {
      debugPrint('DealRealtimeService init error: $e');
      _startPolling(onData, onError);
    }
  }

  void _startPolling(
    void Function(List<Map<String, dynamic>>) onData,
    void Function(Object error)? onError,
  ) {
    Future<void> fetch() async {
      try {
        final res = await ApiService.get('/deals/my-bookings');
        final allBookings =
            List<Map<String, dynamic>>.from(res['bookings'] ?? []);

        // ✅ AUTO-DELETE: Filter visible bookings
        final visibleBookings = allBookings
            .where((b) => FirestoreService.isBookingVisible(b))
            .toList();

        onData(visibleBookings);
      } catch (e) {
        onError?.call(e);
      }
    }

    fetch();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => fetch());
  }

  Future<Map<String, dynamic>> _attachRide(Map<String, dynamic> deal) async {
    final rideId = deal['rideId']?.toString();
    if (rideId == null || rideId.isEmpty) return deal;
    if (deal['ride'] != null) return deal;
    try {
      final res = await ApiService.get('/rides/$rideId');
      deal['ride'] = res['ride'];
    } catch (_) {}
    return deal;
  }

  Map<String, dynamic> _normalizeBooking(Map<String, dynamic> deal) {
    final status = (deal['status'] ?? 'pending').toString().toLowerCase();
    final ride = deal['ride'] as Map<String, dynamic>? ?? {};
    final departure = DateTime.tryParse(
      (ride['departureTime'] ?? deal['departureTime'] ?? '').toString(),
    );
    final isCompleted = status == 'completed';
    final isConfirmed = status == 'confirmed';
    final isUpcoming = ['pending', 'confirmed', 'started'].contains(status) &&
        (departure == null ||
            departure.isAfter(DateTime.now()) ||
            status == 'started');
    return {
      ...deal,
      'status': status,
      'bookingStatus': status,
      'tabStatus': isCompleted
          ? 'completed'
          : isConfirmed
              ? 'confirmed'
              : isUpcoming
                  ? 'upcoming'
                  : status,
      'isUpcoming': isUpcoming,
      'isConfirmed': isConfirmed,
      'isCompleted': isCompleted,
      'canRate': isCompleted && deal['rating'] == null,
      // ✅ Add updatedAt for auto-delete
      'updatedAt': deal['updatedAt'] ?? deal['createdAt'],
    };
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
