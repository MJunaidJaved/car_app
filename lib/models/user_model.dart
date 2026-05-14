import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role; // '' until role select; then captain | passenger | customer
  final bool isVerified;
  final String? photoUrl;
  /// When role is captain: pending_verification | approved | rejected
  final String? captainVerificationStatus;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String? cnic;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleRegistration;
  final double rating;
  final int totalRides;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.isVerified = false,
    this.photoUrl,
    this.captainVerificationStatus,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.cnic,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleRegistration,
    this.rating = 0.0,
    this.totalRides = 0,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'customer',
      isVerified: data['isVerified'] ?? false,
      photoUrl: data['photoUrl'] as String?,
      captainVerificationStatus: data['captainVerificationStatus'] as String?,
      cnicFrontUrl: data['cnicFrontUrl'] as String?,
      cnicBackUrl: data['cnicBackUrl'] as String?,
      cnic: data['cnic'],
      vehicleMake: data['vehicleMake'],
      vehicleModel: data['vehicleModel'],
      vehicleRegistration: data['vehicleRegistration'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRides: data['totalRides'] ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (captainVerificationStatus != null)
        'captainVerificationStatus': captainVerificationStatus,
      if (cnicFrontUrl != null) 'cnicFrontUrl': cnicFrontUrl,
      if (cnicBackUrl != null) 'cnicBackUrl': cnicBackUrl,
      'cnic': cnic,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleRegistration': vehicleRegistration,
      'rating': rating,
      'totalRides': totalRides,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    bool? isVerified,
    String? photoUrl,
    String? captainVerificationStatus,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? cnic,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleRegistration,
    double? rating,
    int? totalRides,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      photoUrl: photoUrl ?? this.photoUrl,
      captainVerificationStatus:
          captainVerificationStatus ?? this.captainVerificationStatus,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      cnic: cnic ?? this.cnic,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convenience getter for compatibility
  String get uid => id;
}



