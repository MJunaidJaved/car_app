import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'api_service.dart';

/// Captain: push GPS to backend. Passenger: listen to ride doc for captain position.
class LocationTrackingService {
  Timer? _captainTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _rideSub;

  void startCaptainTracking(String rideId) {
    stopCaptainTracking();
    _captainTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await ApiService.patch('/rides/$rideId/location', {
          'lat': pos.latitude,
          'lng': pos.longitude,
        });
      } catch (e) {
        debugPrint('Captain location update failed: $e');
      }
    });
  }

  void stopCaptainTracking() {
    _captainTimer?.cancel();
    _captainTimer = null;
  }

  void listenCaptainOnRide({
    required String rideId,
    required void Function(LatLng? location) onLocation,
  }) {
    _rideSub?.cancel();
    _rideSub = FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data();
      final lat = (data?['captainLat'] as num?)?.toDouble();
      final lng = (data?['captainLng'] as num?)?.toDouble();
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        onLocation(LatLng(lat, lng));
      }
    });
  }

  void stopListening() {
    _rideSub?.cancel();
    _rideSub = null;
  }

  void dispose() {
    stopCaptainTracking();
    stopListening();
  }
}
