import 'dart:async';

import '../models/deal_model.dart';
import '../models/ride_model.dart';
import '../models/wallet_model.dart';
import 'ride_service.dart';

/// Frontend stub — no Firestore. Backend team replaces with real persistence.
class FirestoreService {
  Future<String> postRide(RideModel ride) async => ride.id;

  Stream<List<RideModel>> getActiveRides() =>
      Stream<List<RideModel>>.value(RideService.demoRides);

  Stream<List<RideModel>> getRidesByCaptain(String captainId) =>
      Stream<List<RideModel>>.value(RideService.demoRides);

  Future<RideModel?> getRideById(String rideId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    try {
      return RideService.demoRides.firstWhere((r) => r.id == rideId);
    } catch (_) {
      return RideService.demoRides.isEmpty ? null : RideService.demoRides.first;
    }
  }

  Future<void> updateRideStatus(String rideId, String status) async {}

  Future<void> updateAvailableSeats(String rideId, int seats) async {}

  Future<String> createDeal(DealModel deal) async => 'local-deal';

  Stream<List<DealModel>> getDealsForRide(String rideId) =>
      Stream<List<DealModel>>.value(const []);

  Stream<List<DealModel>> getDealsByCustomer(String customerId) =>
      Stream<List<DealModel>>.value(const []);

  Stream<List<DealModel>> getDealsByCaptain(String captainId) =>
      Stream<List<DealModel>>.value(const []);

  Future<void> updateDealStatus(String dealId, String status) async {}

  Future<void> confirmDeal(
    String dealId,
    String captainId,
    double platformFee,
  ) async {}

  Future<void> addRating(
    String dealId,
    double rating,
    String? review,
  ) async {}

  Future<WalletModel?> getWallet(String userId) async => null;

  Stream<WalletModel?> streamWallet(String userId) =>
      Stream<WalletModel?>.value(null);

  Future<void> addToWallet(
    String userId,
    double amount,
    String reference,
  ) async {}

  Future<void> deductFromWallet(
    String userId,
    double amount,
    String description,
  ) async {}

  Stream<List<TransactionModel>> getTransactions(String userId) =>
      Stream<List<TransactionModel>>.value(const []);

  Future<List<RideModel>> searchRides({
    String? startLocation,
    String? endLocation,
    DateTime? date,
  }) async =>
      RideService.demoRides;
}
