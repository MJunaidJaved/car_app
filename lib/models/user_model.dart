import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String? gender;
  final bool isVerified;
  final String? photoUrl;
  final String? captainVerificationStatus;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehicleRegistration;
  final int? vehicleYear;
  final int? vehicleSeats;
  final String? city;
  final String? vehiclePhotoUrl;
  final String? captainVehicleType;
  final double rating;
  final int totalRides;
  final int reviewCount;
  final int completedRides;
  final List<Map<String, dynamic>> recentReviews;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.gender,
    this.isVerified = false,
    this.photoUrl,
    this.captainVerificationStatus,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleRegistration,
    this.vehicleYear,
    this.vehicleSeats,
    this.city,
    this.vehiclePhotoUrl,
    this.captainVehicleType,
    this.rating = 0.0,
    this.totalRides = 0,
    this.reviewCount = 0,
    this.completedRides = 0,
    this.recentReviews = const [],
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'customer',
      gender: data['gender'] as String?,
      isVerified: data['isVerified'] ?? false,
      photoUrl: data['photoUrl'] as String?,
      captainVerificationStatus: data['captainVerificationStatus'] as String?,
      vehicleMake: data['vehicleMake'] as String?,
      vehicleModel: data['vehicleModel'] as String?,
      vehicleColor: data['vehicleColor'] as String?,
      vehicleRegistration: data['vehicleRegistration'] as String?,
      vehicleYear: data['vehicleYear'] != null
          ? int.tryParse(data['vehicleYear'].toString())
          : null,
      vehicleSeats: data['vehicleSeats'] != null
          ? int.tryParse(data['vehicleSeats'].toString())
          : null,
      city: data['city'] as String?,
      vehiclePhotoUrl: data['vehiclePhotoUrl'] as String?,
      captainVehicleType: data['captainVehicleType'] as String?,
      rating: (data['averageRating'] ?? data['rating'] ?? 0.0).toDouble(),
      totalRides: int.tryParse((data['totalRides'] ?? 0).toString()) ?? 0,
      reviewCount:
          int.tryParse((data['reviewCount'] ?? data['totalReviews'] ?? 0).toString()) ??
              0,
      completedRides:
          int.tryParse((data['completedRides'] ?? data['totalRides'] ?? 0).toString()) ??
              0,
      recentReviews: data['recentReviews'] is List
          ? List<Map<String, dynamic>>.from(data['recentReviews'])
          : const [],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ??
                  DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      if (gender != null) 'gender': gender,
      'isVerified': isVerified,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (captainVerificationStatus != null)
        'captainVerificationStatus': captainVerificationStatus,
      if (vehicleMake != null) 'vehicleMake': vehicleMake,
      if (vehicleModel != null) 'vehicleModel': vehicleModel,
      if (vehicleColor != null) 'vehicleColor': vehicleColor,
      if (vehicleRegistration != null)
        'vehicleRegistration': vehicleRegistration,
      if (vehicleYear != null) 'vehicleYear': vehicleYear,
      if (vehicleSeats != null) 'vehicleSeats': vehicleSeats,
      if (city != null) 'city': city,
      if (vehiclePhotoUrl != null) 'vehiclePhotoUrl': vehiclePhotoUrl,
      if (captainVehicleType != null) 'captainVehicleType': captainVehicleType,
      'rating': rating,
      'totalRides': totalRides,
      'reviewCount': reviewCount,
      'completedRides': completedRides,
      'recentReviews': recentReviews,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? gender,
    bool? isVerified,
    String? photoUrl,
    String? captainVerificationStatus,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    String? vehicleRegistration,
    int? vehicleYear,
    int? vehicleSeats,
    String? city,
    String? vehiclePhotoUrl,
    String? captainVehicleType,
    double? rating,
    int? totalRides,
    int? reviewCount,
    int? completedRides,
    List<Map<String, dynamic>>? recentReviews,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      isVerified: isVerified ?? this.isVerified,
      photoUrl: photoUrl ?? this.photoUrl,
      captainVerificationStatus:
          captainVerificationStatus ?? this.captainVerificationStatus,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleSeats: vehicleSeats ?? this.vehicleSeats,
      city: city ?? this.city,
      vehiclePhotoUrl: vehiclePhotoUrl ?? this.vehiclePhotoUrl,
      captainVehicleType: captainVehicleType ?? this.captainVehicleType,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      reviewCount: reviewCount ?? this.reviewCount,
      completedRides: completedRides ?? this.completedRides,
      recentReviews: recentReviews ?? this.recentReviews,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayVehicle {
    final parts = [
      captainVehicleType,
      vehicleModel,
      vehicleRegistration,
    ].where((p) => p != null && p.trim().isNotEmpty).map((p) => p!.trim());
    return parts.join(' • ');
  }

  String get uid => id;
}
