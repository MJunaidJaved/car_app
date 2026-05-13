import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import '../models/deal_model.dart';
import '../models/wallet_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // RIDE OPERATIONS
  
  // Post a new ride
  Future<String> postRide(RideModel ride) async {
    try {
      DocumentReference docRef = await _firestore.collection('rides').add(ride.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to post ride: $e');
    }
  }

  // Get active rides (for customers)
  Stream<List<RideModel>> getActiveRides() {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'active')
        .orderBy('departureTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList());
  }

  // Get rides by captain
  Stream<List<RideModel>> getRidesByCaptain(String captainId) {
    return _firestore
        .collection('rides')
        .where('captainId', isEqualTo: captainId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList());
  }

  // Get ride by ID
  Future<RideModel?> getRideById(String rideId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('rides').doc(rideId).get();
      if (doc.exists) {
        return RideModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get ride: $e');
    }
  }

  // Update ride status
  Future<void> updateRideStatus(String rideId, String status) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({'status': status});
    } catch (e) {
      throw Exception('Failed to update ride status: $e');
    }
  }

  // Update available seats
  Future<void> updateAvailableSeats(String rideId, int seats) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({'availableSeats': seats});
    } catch (e) {
      throw Exception('Failed to update seats: $e');
    }
  }

  // DEAL OPERATIONS
  
  // Create a deal
  Future<String> createDeal(DealModel deal) async {
    try {
      DocumentReference docRef = await _firestore.collection('deals').add(deal.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create deal: $e');
    }
  }

  // Get deals for a ride
  Stream<List<DealModel>> getDealsForRide(String rideId) {
    return _firestore
        .collection('deals')
        .where('rideId', isEqualTo: rideId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DealModel.fromFirestore(doc)).toList());
  }

  // Get deals by customer
  Stream<List<DealModel>> getDealsByCustomer(String customerId) {
    return _firestore
        .collection('deals')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DealModel.fromFirestore(doc)).toList());
  }

  // Get deals by captain
  Stream<List<DealModel>> getDealsByCaptain(String captainId) {
    return _firestore
        .collection('deals')
        .where('captainId', isEqualTo: captainId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DealModel.fromFirestore(doc)).toList());
  }

  // Update deal status
  Future<void> updateDealStatus(String dealId, String status) async {
    try {
      Map<String, dynamic> updateData = {'status': status};
      if (status == 'confirmed') {
        updateData['confirmedAt'] = FieldValue.serverTimestamp();
      }
      await _firestore.collection('deals').doc(dealId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update deal status: $e');
    }
  }

  // Confirm deal and deduct fee
  Future<void> confirmDeal(String dealId, String captainId, double platformFee) async {
    try {
      // Update deal status
      await updateDealStatus(dealId, 'confirmed');
      
      // Deduct platform fee from captain's wallet
      await deductFromWallet(captainId, platformFee, 'Deal confirmation fee');
      
      // Add transaction record
      await _firestore.collection('transactions').add({
        'walletId': captainId,
        'type': 'deduction',
        'amount': platformFee,
        'reference': dealId,
        'description': 'Platform fee (10%)',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to confirm deal: $e');
    }
  }

  // Add rating to deal
  Future<void> addRating(String dealId, double rating, String? review) async {
    try {
      await _firestore.collection('deals').doc(dealId).update({
        'rating': rating,
        'review': review,
      });
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }

  // WALLET OPERATIONS
  
  // Get wallet
  Future<WalletModel?> getWallet(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('wallets').doc(userId).get();
      if (doc.exists) {
        return WalletModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get wallet: $e');
    }
  }

  // Stream wallet
  Stream<WalletModel?> streamWallet(String userId) {
    return _firestore.collection('wallets').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return WalletModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Add funds to wallet
  Future<void> addToWallet(String userId, double amount, String reference) async {
    try {
      DocumentReference walletRef = _firestore.collection('wallets').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot walletDoc = await transaction.get(walletRef);
        double currentBalance = (walletDoc.data() as Map<String, dynamic>)['balance'] ?? 0.0;
        
        transaction.update(walletRef, {
          'balance': currentBalance + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      // Add transaction record
      await _firestore.collection('transactions').add({
        'walletId': userId,
        'type': 'topup',
        'amount': amount,
        'reference': reference,
        'description': 'Wallet top-up',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add funds: $e');
    }
  }

  // Deduct from wallet
  Future<void> deductFromWallet(String userId, double amount, String description) async {
    try {
      DocumentReference walletRef = _firestore.collection('wallets').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot walletDoc = await transaction.get(walletRef);
        double currentBalance = (walletDoc.data() as Map<String, dynamic>)['balance'] ?? 0.0;
        
        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }
        
        transaction.update(walletRef, {
          'balance': currentBalance - amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to deduct funds: $e');
    }
  }

  // Get transactions
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('walletId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList());
  }

  // Search rides by location
  Future<List<RideModel>> searchRides({
    String? startLocation,
    String? endLocation,
    DateTime? date,
  }) async {
    try {
      Query query = _firestore.collection('rides').where('status', isEqualTo: 'active');

      if (startLocation != null && startLocation.isNotEmpty) {
        // For MVP, using simple contains search
        // In production, use proper geolocation search
        query = query.where('startLocation', isGreaterThanOrEqualTo: startLocation);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to search rides: $e');
    }
  }
}
