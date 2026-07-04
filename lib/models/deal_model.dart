import 'package:cloud_firestore/cloud_firestore.dart';

class DealModel {
  final String id;
  final String rideId;
  final String captainId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final double agreedFare;
  final double platformFee;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final String? customerMessage;
  final double? rating;
  final String? review;

  DealModel({
    required this.id,
    required this.rideId,
    required this.captainId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.agreedFare,
    required this.platformFee,
    this.status = 'pending',
    this.confirmedAt,
    required this.createdAt,
    this.customerMessage,
    this.rating,
    this.review,
  });

  factory DealModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DealModel.fromMap(data, doc.id);
  }

  factory DealModel.fromMap(Map<String, dynamic> data, String id) {
    return DealModel(
      id: id,
      rideId: data['rideId'] ?? '',
      captainId: data['captainId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      agreedFare: (data['agreedFare'] ?? 0.0).toDouble(),
      platformFee: (data['platformFee'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      confirmedAt: _parseDate(data['confirmedAt']),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      customerMessage: data['customerMessage'],
      rating:
          data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      review: data['review'],
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
    };
  }

  DealModel copyWith({
    String? id,
    String? rideId,
    String? captainId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    double? agreedFare,
    double? platformFee,
    String? status,
    DateTime? confirmedAt,
    DateTime? createdAt,
    String? customerMessage,
    double? rating,
    String? review,
  }) {
    return DealModel(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      captainId: captainId ?? this.captainId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      agreedFare: agreedFare ?? this.agreedFare,
      platformFee: platformFee ?? this.platformFee,
      status: status ?? this.status,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt ?? this.createdAt,
      customerMessage: customerMessage ?? this.customerMessage,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }
}
