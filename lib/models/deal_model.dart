import 'package:cloud_firestore/cloud_firestore.dart';

class DealModel {
  final String id;
  final String rideId;
  final String captainId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String captainPhone;
  final double agreedFare;
  final double platformFee;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final String? customerMessage;
  final double? rating;
  final String? review;

  // ✅ NEW FIELDS for counter functionality
  final String? lastCounterBy; // 'captain' or 'customer'
  final DateTime? lastCounterAt;

  // ✅ NEW FIELDS for passenger pickup/drop
  final double? passengerPickupLat;
  final double? passengerPickupLng;
  final String? passengerPickupAddress;
  final double? passengerDropLat;
  final double? passengerDropLng;
  final String? passengerDropAddress;
  final int? pickupOrder;
  final String boardingStatus;
  final bool phoneRevealed;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? captainName;
  final String? captainVehicleType;

  // ✅ NEW: rideMode field for Share/Solo
  final String? rideMode;

  DealModel({
    required this.id,
    required this.rideId,
    required this.captainId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.captainPhone,
    required this.agreedFare,
    required this.platformFee,
    this.status = 'pending',
    this.confirmedAt,
    required this.createdAt,
    this.customerMessage,
    this.rating,
    this.review,
    this.lastCounterBy,
    this.lastCounterAt,
    this.passengerPickupLat,
    this.passengerPickupLng,
    this.passengerPickupAddress,
    this.passengerDropLat,
    this.passengerDropLng,
    this.passengerDropAddress,
    this.pickupOrder,
    this.boardingStatus = 'waiting',
    this.phoneRevealed = false,
    this.updatedAt,
    this.completedAt,
    this.captainName,
    this.captainVehicleType,
    this.rideMode, // ✅ ADDED
  });

  factory DealModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DealModel.fromMap(data, doc.id);
  }

  factory DealModel.fromMap(Map<String, dynamic> data, String id) {
    // ✅ Try to get rideMode from ride object or directly from deal
    String? rideModeValue;
    if (data['ride'] != null && data['ride'] is Map<String, dynamic>) {
      rideModeValue = data['ride']['rideMode']?.toString();
    }
    if (rideModeValue == null || rideModeValue.isEmpty) {
      rideModeValue = data['rideMode']?.toString();
    }
    if (rideModeValue == null || rideModeValue.isEmpty) {
      rideModeValue = 'share'; // default
    }

    return DealModel(
      id: id,
      rideId: data['rideId'] ?? '',
      captainId: data['captainId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      captainPhone: data['captainPhone'] ?? '',
      agreedFare: (data['agreedFare'] ?? 0.0).toDouble(),
      platformFee: (data['platformFee'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      confirmedAt: _parseDate(data['confirmedAt']),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      customerMessage: data['customerMessage'],
      rating:
          data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      review: data['review'],
      // ✅ NEW FIELDS
      lastCounterBy: data['lastCounterBy']?.toString(),
      lastCounterAt: _parseDate(data['lastCounterAt']),
      passengerPickupLat: data['passengerPickupLat'] != null
          ? (data['passengerPickupLat'] as num).toDouble()
          : null,
      passengerPickupLng: data['passengerPickupLng'] != null
          ? (data['passengerPickupLng'] as num).toDouble()
          : null,
      passengerPickupAddress: data['passengerPickupAddress']?.toString(),
      passengerDropLat: data['passengerDropLat'] != null
          ? (data['passengerDropLat'] as num).toDouble()
          : null,
      passengerDropLng: data['passengerDropLng'] != null
          ? (data['passengerDropLng'] as num).toDouble()
          : null,
      passengerDropAddress: data['passengerDropAddress']?.toString(),
      pickupOrder: data['pickupOrder'] as int?,
      boardingStatus: data['boardingStatus']?.toString() ?? 'waiting',
      phoneRevealed: data['phoneRevealed'] == true,
      updatedAt: _parseDate(data['updatedAt']),
      completedAt: _parseDate(data['completedAt']),
      captainName: data['captainName']?.toString(),
      captainVehicleType: data['captainVehicleType']?.toString(),
      rideMode: rideModeValue, // ✅ ADDED
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap({bool forFirestore = false}) {
    return {
      'rideId': rideId,
      'captainId': captainId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'captainPhone': captainPhone,
      'agreedFare': agreedFare,
      'platformFee': platformFee,
      'status': status,
      'confirmedAt': confirmedAt != null
          ? (forFirestore
              ? Timestamp.fromDate(confirmedAt!)
              : confirmedAt!.toIso8601String())
          : null,
      'createdAt': forFirestore
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
      'customerMessage': customerMessage,
      'rating': rating,
      'review': review,
      // ✅ NEW FIELDS
      'lastCounterBy': lastCounterBy,
      'lastCounterAt': lastCounterAt != null
          ? (forFirestore
              ? Timestamp.fromDate(lastCounterAt!)
              : lastCounterAt!.toIso8601String())
          : null,
      'passengerPickupLat': passengerPickupLat,
      'passengerPickupLng': passengerPickupLng,
      'passengerPickupAddress': passengerPickupAddress,
      'passengerDropLat': passengerDropLat,
      'passengerDropLng': passengerDropLng,
      'passengerDropAddress': passengerDropAddress,
      'pickupOrder': pickupOrder,
      'boardingStatus': boardingStatus,
      'phoneRevealed': phoneRevealed,
      'updatedAt': updatedAt != null
          ? (forFirestore
              ? Timestamp.fromDate(updatedAt!)
              : updatedAt!.toIso8601String())
          : null,
      'completedAt': completedAt != null
          ? (forFirestore
              ? Timestamp.fromDate(completedAt!)
              : completedAt!.toIso8601String())
          : null,
      'captainName': captainName,
      'captainVehicleType': captainVehicleType,
      'rideMode': rideMode, // ✅ ADDED
    };
  }

  DealModel copyWith({
    String? id,
    String? rideId,
    String? captainId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? captainPhone,
    double? agreedFare,
    double? platformFee,
    String? status,
    DateTime? confirmedAt,
    DateTime? createdAt,
    String? customerMessage,
    double? rating,
    String? review,
    String? lastCounterBy,
    DateTime? lastCounterAt,
    double? passengerPickupLat,
    double? passengerPickupLng,
    String? passengerPickupAddress,
    double? passengerDropLat,
    double? passengerDropLng,
    String? passengerDropAddress,
    int? pickupOrder,
    String? boardingStatus,
    bool? phoneRevealed,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? captainName,
    String? captainVehicleType,
    String? rideMode, // ✅ ADDED
  }) {
    return DealModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      captainId: captainId ?? this.captainId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      captainPhone: captainPhone ?? this.captainPhone,
      agreedFare: agreedFare ?? this.agreedFare,
      platformFee: platformFee ?? this.platformFee,
      status: status ?? this.status,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt ?? this.createdAt,
      customerMessage: customerMessage ?? this.customerMessage,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      lastCounterBy: lastCounterBy ?? this.lastCounterBy,
      lastCounterAt: lastCounterAt ?? this.lastCounterAt,
      passengerPickupLat: passengerPickupLat ?? this.passengerPickupLat,
      passengerPickupLng: passengerPickupLng ?? this.passengerPickupLng,
      passengerPickupAddress:
          passengerPickupAddress ?? this.passengerPickupAddress,
      passengerDropLat: passengerDropLat ?? this.passengerDropLat,
      passengerDropLng: passengerDropLng ?? this.passengerDropLng,
      passengerDropAddress: passengerDropAddress ?? this.passengerDropAddress,
      pickupOrder: pickupOrder ?? this.pickupOrder,
      boardingStatus: boardingStatus ?? this.boardingStatus,
      phoneRevealed: phoneRevealed ?? this.phoneRevealed,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      captainName: captainName ?? this.captainName,
      captainVehicleType: captainVehicleType ?? this.captainVehicleType,
      rideMode: rideMode ?? this.rideMode, // ✅ ADDED
    );
  }

  // ✅ Helper getters for UI
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isStarted => status == 'started';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => ['pending', 'confirmed', 'started'].contains(status);
  bool get canCancel => ['pending', 'confirmed'].contains(status);
  bool get canTrack => ['confirmed', 'started'].contains(status);
  bool get canRate => status == 'completed' && rating == null;
  bool get isPhoneRevealed =>
      phoneRevealed || isConfirmed || isStarted || isCompleted;

  // ✅ Check if customer can accept (captain countered)
  bool get canCustomerAccept =>
      status == 'pending' && lastCounterBy == 'captain';

  // ✅ Check if Share or Solo ride
  bool get isShareRide => rideMode?.toLowerCase() != 'solo';
  bool get isSoloRide => rideMode?.toLowerCase() == 'solo';
}
