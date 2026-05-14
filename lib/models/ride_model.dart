import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String id;
  final String captainId;
  final String captainName;
  final String startLocation;
  final String endLocation;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final DateTime departureTime;
  final int availableSeats;
  final int totalSeats;
  final double suggestedFare;
  final String rideType; // 'office', 'random', 'delivery', 'tour'
  final String status; // 'active', 'filled', 'completed', 'cancelled'
  final bool acceptsDelivery;
  final String? vehicleInfo;
  final double captainRating;
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.captainId,
    required this.captainName,
    required this.startLocation,
    required this.endLocation,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.departureTime,
    required this.availableSeats,
    required this.totalSeats,
    required this.suggestedFare,
    required this.rideType,
    this.status = 'active',
    this.acceptsDelivery = false,
    this.vehicleInfo,
    this.captainRating = 0.0,
    required this.createdAt,
  });

  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RideModel(
      id: doc.id,
      captainId: data['captainId'] ?? '',
      captainName: data['captainName'] ?? '',
      startLocation: data['startLocation'] ?? '',
      endLocation: data['endLocation'] ?? '',
      startLat: (data['startLat'] ?? 0.0).toDouble(),
      startLng: (data['startLng'] ?? 0.0).toDouble(),
      endLat: (data['endLat'] ?? 0.0).toDouble(),
      endLng: (data['endLng'] ?? 0.0).toDouble(),
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      availableSeats: data['availableSeats'] ?? 0,
      totalSeats: data['totalSeats'] ?? 0,
      suggestedFare: (data['suggestedFare'] ?? 0.0).toDouble(),
      rideType: data['rideType'] ?? 'random',
      status: data['status'] ?? 'active',
      acceptsDelivery: data['acceptsDelivery'] ?? false,
      vehicleInfo: data['vehicleInfo'],
      captainRating: (data['captainRating'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'captainId': captainId,
      'captainName': captainName,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'departureTime': Timestamp.fromDate(departureTime),
      'availableSeats': availableSeats,
      'totalSeats': totalSeats,
      'suggestedFare': suggestedFare,
      'rideType': rideType,
      'status': status,
      'acceptsDelivery': acceptsDelivery,
      'vehicleInfo': vehicleInfo,
      'captainRating': captainRating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RideModel copyWith({
    String? id,
    String? captainId,
    String? captainName,
    String? startLocation,
    String? endLocation,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    DateTime? departureTime,
    int? availableSeats,
    int? totalSeats,
    double? suggestedFare,
    String? rideType,
    String? status,
    bool? acceptsDelivery,
    String? vehicleInfo,
    double? captainRating,
    DateTime? createdAt,
  }) {
    return RideModel(
      id: id ?? this.id,
      captainId: captainId ?? this.captainId,
      captainName: captainName ?? this.captainName,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      totalSeats: totalSeats ?? this.totalSeats,
      suggestedFare: suggestedFare ?? this.suggestedFare,
      rideType: rideType ?? this.rideType,
      status: status ?? this.status,
      acceptsDelivery: acceptsDelivery ?? this.acceptsDelivery,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      captainRating: captainRating ?? this.captainRating,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convenience getters for compatibility
  String get from => startLocation;
  String get to => endLocation;
  bool get isRecurring => false; // Default value, can be added to model if needed
  double get offeredFare => suggestedFare;
}



