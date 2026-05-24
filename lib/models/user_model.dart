import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final bool isVerified;
  final String? photoUrl;
  final String? captainVerificationStatus;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String? cnic;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehicleRegistration;
  final int? vehicleYear;
  final int? vehicleSeats;
  final String? city;
  final String? vehiclePhotoUrl;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
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
    this.vehicleColor,
    this.vehicleRegistration,
    this.vehicleYear,
    this.vehicleSeats,
    this.city,
    this.vehiclePhotoUrl,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.rating = 0.0,
    this.totalRides = 0,
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
      isVerified: data['isVerified'] ?? false,
      photoUrl: data['photoUrl'] as String?,
      captainVerificationStatus: data['captainVerificationStatus'] as String?,
      cnicFrontUrl: data['cnicFrontUrl'] as String?,
      cnicBackUrl: data['cnicBackUrl'] as String?,
      cnic: data['cnic'] as String?,
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
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRides: data['totalRides'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
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
      if (cnic != null) 'cnic': cnic,
      if (vehicleMake != null) 'vehicleMake': vehicleMake,
      if (vehicleModel != null) 'vehicleModel': vehicleModel,
      if (vehicleColor != null) 'vehicleColor': vehicleColor,
      if (vehicleRegistration != null) 'vehicleRegistration': vehicleRegistration,
      if (vehicleYear != null) 'vehicleYear': vehicleYear,
      if (vehicleSeats != null) 'vehicleSeats': vehicleSeats,
      if (city != null) 'city': city,
      if (vehiclePhotoUrl != null) 'vehiclePhotoUrl': vehiclePhotoUrl,
      if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
      if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
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
    String? vehicleColor,
    String? vehicleRegistration,
    int? vehicleYear,
    int? vehicleSeats,
    String? city,
    String? vehiclePhotoUrl,
    String? emergencyContactName,
    String? emergencyContactPhone,
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
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleSeats: vehicleSeats ?? this.vehicleSeats,
      city: city ?? this.city,
      vehiclePhotoUrl: vehiclePhotoUrl ?? this.vehiclePhotoUrl,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayVehicle {
    final parts = [
      vehicleMake,
      vehicleModel,
      vehicleColor,
      vehicleRegistration,
    ].where((p) => p != null && p!.trim().isNotEmpty).map((p) => p!.trim());
    return parts.join(' • ');
  }

  String get uid => id;
}
