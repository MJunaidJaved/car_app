import 'api_service.dart';
import '../models/ride_model.dart';

/// API facade for deals (legacy name kept for minimal call-site churn).
class FirestoreService {
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
      if (passengerDropAddress != null) 'passengerDropAddress': passengerDropAddress,
    });
    final dealId = response['dealId'] as String?;
    if (dealId == null) throw Exception('No dealId in response');
    return dealId;
  }

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

  Future<Map<String, dynamic>> getDeal(String dealId) async {
    final response = await ApiService.get('/deals/$dealId');
    return response['deal'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getRideDeals(String rideId) async {
    final response = await ApiService.get('/deals/ride/$rideId');
    return List<Map<String, dynamic>>.from(response['deals'] ?? []);
  }

  Future<Map<String, dynamic>> getConfirmedPassengers(String rideId) async {
    return ApiService.get('/deals/ride/$rideId/confirmed');
  }

  Future<void> rateDeal(String dealId, int rating, String review) async {
    await ApiService.patch('/deals/$dealId/rate', {
      'rating': rating,
      'review': review,
    });
  }

  Future<RideModel?> getRideById(String rideId) async {
    try {
      final response = await ApiService.get('/rides/$rideId');
      if (response['ride'] != null) {
        return RideModel.fromMap(response['ride'] as Map<String, dynamic>, rideId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
