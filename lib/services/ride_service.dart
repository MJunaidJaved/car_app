import 'package:flutter/foundation.dart';
import '../models/ride_model.dart';
import 'api_service.dart';

class RideService with ChangeNotifier {
  Future<void> postRide({
    required String startLocation,
    required String endLocation,
    required double suggestedFare,
    required int totalSeats,
    required String rideType,
    required String vehicleType,
    required String rideMode,
    required String departureTime,
    double startLat = 0.0,
    double startLng = 0.0,
    double endLat = 0.0,
    double endLng = 0.0,
    bool acceptsDelivery = false,
    String? tourType,
    int? maxPassengers,
    String? cargoType,
    double? weightCapacity,
    String? truckSize,
    String? exactLocation,
    String? exactDropLocation,
  }) async {
    try {
      await ApiService.post('/rides', {
        'startLocation': startLocation,
        'endLocation': endLocation,
        'suggestedFare': suggestedFare,
        'totalSeats': totalSeats,
        'rideType': rideType,
        'vehicleType': vehicleType,
        'rideMode': rideMode,
        'departureTime': departureTime,
        'startLat': startLat,
        'startLng': startLng,
        'endLat': endLat,
        'endLng': endLng,
        'acceptsDelivery': acceptsDelivery,
        if (tourType != null) 'tourType': tourType,
        if (maxPassengers != null) 'maxPassengers': maxPassengers,
        if (cargoType != null) 'cargoType': cargoType,
        if (weightCapacity != null) 'weightCapacity': weightCapacity,
        if (truckSize != null) 'truckSize': truckSize,
        if (exactLocation != null && exactLocation.trim().isNotEmpty)
          'exactLocation': exactLocation.trim(),
        if (exactDropLocation != null && exactDropLocation.trim().isNotEmpty)
          'exactDropLocation': exactDropLocation.trim(),
      });
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }

  Future<List<RideModel>> findRides({
    String? startLocation,
    String? endLocation,
    String? type,
    String? rideMode,
    double? userLat,
    double? userLng,
    double radiusKm = 15,
  }) async {
    final queryParams = <String, String>{
      if (startLocation != null && startLocation.isNotEmpty)
        'startLocation': startLocation,
      if (endLocation != null && endLocation.isNotEmpty)
        'endLocation': endLocation,
      if (type != null && type.isNotEmpty && type != 'all') 'rideType': type,
      if (rideMode != null &&
          rideMode.isNotEmpty &&
          rideMode.toLowerCase() != 'all')
        'rideMode': rideMode,
      if (userLat != null) 'lat': userLat.toString(),
      if (userLng != null) 'lng': userLng.toString(),
      if (userLat != null && userLng != null) 'radiusKm': radiusKm.toString(),
    };

    Map<String, dynamic> response;
    try {
      response = await ApiService.get('/rides', queryParams: queryParams);
    } catch (e) {
      rethrow;
    }
    final ridesData = response['rides'] as List<dynamic>? ?? [];
    return ridesData
        .map((r) => RideModel.fromMap(
            r as Map<String, dynamic>, r['id']?.toString() ?? ''))
        .toList();
  }

  Future<RideModel?> getRideById(String rideId) async {
    final response = await ApiService.get('/rides/$rideId');
    final data = response['ride'] as Map<String, dynamic>?;
    if (data == null) return null;
    return RideModel.fromMap(data, data['id']?.toString() ?? rideId);
  }

  Future<List<RideModel>> getCaptainRides() async {
    final response = await ApiService.get('/rides/my-rides');
    final ridesData = response['rides'] as List<dynamic>? ?? [];
    return ridesData
        .map((r) => RideModel.fromMap(
            r as Map<String, dynamic>, r['id']?.toString() ?? ''))
        .toList();
  }
}
