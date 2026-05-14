import 'package:flutter/foundation.dart';
import '../models/ride_model.dart';

class RideService with ChangeNotifier {
  static List<RideModel> get demoRides {
    final now = DateTime.now();
    return [
      RideModel(
        id: 'demo-1',
        captainId: 'captain-demo',
        captainName: 'Ahmed Khan',
        startLocation: 'Gulberg III, Lahore',
        endLocation: 'DHA Phase 5',
        startLat: 31.52,
        startLng: 74.35,
        endLat: 31.47,
        endLng: 74.41,
        departureTime: now.add(const Duration(hours: 2)),
        availableSeats: 2,
        totalSeats: 4,
        suggestedFare: 120,
        rideType: 'office',
        status: 'active',
        captainRating: 4.8,
        createdAt: now,
        vehicleInfo: 'Toyota Corolla · LEA-123',
      ),
      RideModel(
        id: 'demo-2',
        captainId: 'captain-demo-2',
        captainName: 'Sara Malik',
        startLocation: 'Johar Town',
        endLocation: 'Model Town',
        startLat: 31.46,
        startLng: 74.28,
        endLat: 31.48,
        endLng: 74.32,
        departureTime: now.add(const Duration(hours: 5)),
        availableSeats: 1,
        totalSeats: 3,
        suggestedFare: 90,
        rideType: 'random',
        status: 'active',
        captainRating: 4.6,
        createdAt: now.subtract(const Duration(hours: 1)),
        vehicleInfo: 'Honda Civic · RWP-902',
      ),
      RideModel(
        id: 'demo-3',
        captainId: 'captain-demo-3',
        captainName: 'Bilal Hussain',
        startLocation: 'Allama Iqbal Town',
        endLocation: 'Airport Road',
        startLat: 31.43,
        startLng: 74.29,
        endLat: 31.52,
        endLng: 74.40,
        departureTime: now.add(const Duration(days: 1, hours: 3)),
        availableSeats: 3,
        totalSeats: 4,
        suggestedFare: 150,
        rideType: 'delivery',
        status: 'active',
        acceptsDelivery: true,
        captainRating: 4.9,
        createdAt: now.subtract(const Duration(hours: 3)),
        vehicleInfo: 'Suzuki Swift · LHR-441',
      ),
    ];
  }

  Future<void> postRide({
    required String captainId,
    required String from,
    required String to,
    required double offeredFare,
    required int availableSeats,
    required String rideType,
    required String departureTime,
    required bool isRecurring,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    debugPrint('Local demo: posted ride $from → $to');
  }

  Future<List<RideModel>> findRides({
    required String from,
    required String to,
    String? type,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    var list = List<RideModel>.from(demoRides);
    if (type != null && type.isNotEmpty && type != 'all') {
      list = list.where((r) => r.rideType == type).toList();
    }
    return list;
  }

  Future<List<RideModel>> getCaptainRides(String captainId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return demoRides;
  }

  Future<List<RideModel>> getPassengerBookings(String passengerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final base = demoRides;
    return [
      base[0].copyWith(status: 'upcoming'),
      base[1].copyWith(status: 'completed'),
    ];
  }
}



