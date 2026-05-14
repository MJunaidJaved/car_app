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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DealModel(
      id: doc.id,
      rideId: data['rideId'] ?? '',
      captainId: data['captainId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      agreedFare: (data['agreedFare'] ?? 0.0).toDouble(),
      platformFee: (data['platformFee'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      customerMessage: data['customerMessage'],
      rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      review: data['review'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'captainId': captainId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'agreedFare': agreedFare,
      'platformFee': platformFee,
      'status': status,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
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



