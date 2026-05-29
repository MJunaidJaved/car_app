import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String id;
  final String captainId;
  final String captainName;
  final String? captainPhone;
  final String startLocation;
  final String endLocation;
  final String? exactLocation;
  final String? exactDropLocation;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final DateTime departureTime;
  final int availableSeats;
  final int totalSeats;
  final double suggestedFare;
  final String rideType; // 'office', 'random', 'delivery', 'tour'
  final String vehicleType; // 'car', 'bike', 'truck', 'tour'
  final String rideMode; // 'solo' or 'share'
  final bool isShazoreRide;
  final bool isLadiesRide;
  final String? captainGender;
  final String? tourType;
  final int? maxPassengers;
  final String? cargoType;
  final double? weightCapacity;
  final String? truckSize;
  final String status; // 'active', 'filled', 'completed', 'cancelled'
  final bool full;
  final bool acceptsDelivery;
  final String? vehicleInfo;
  final double captainRating;
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.captainId,
    required this.captainName,
    this.captainPhone,
    required this.startLocation,
    required this.endLocation,
    this.exactLocation,
    this.exactDropLocation,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.departureTime,
    required this.availableSeats,
    required this.totalSeats,
    required this.suggestedFare,
    required this.rideType,
    this.vehicleType = 'car',
    this.rideMode = 'share',
    this.isShazoreRide = false,
    this.isLadiesRide = false,
    this.captainGender,
    this.tourType,
    this.maxPassengers,
    this.cargoType,
    this.weightCapacity,
    this.truckSize,
    this.status = 'active',
    this.full = false,
    this.acceptsDelivery = false,
    this.vehicleInfo,
    this.captainRating = 0.0,
    required this.createdAt,
  });

  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideModel.fromMap(data, doc.id);
  }

  factory RideModel.fromMap(Map<String, dynamic> data, String id) {
    return RideModel(
      id: id,
      captainId: data['captainId'] ?? '',
      captainName: data['captainName'] ?? '',
      captainPhone: data['captainPhone'] as String?,
      startLocation: data['startLocation'] ?? '',
      endLocation: data['endLocation'] ?? '',
      exactLocation: data['exactLocation'] as String?,
      exactDropLocation: data['exactDropLocation'] as String?,
      startLat: (data['startLat'] ?? 0.0).toDouble(),
      startLng: (data['startLng'] ?? 0.0).toDouble(),
      endLat: (data['endLat'] ?? 0.0).toDouble(),
      endLng: (data['endLng'] ?? 0.0).toDouble(),
      departureTime: _parseDate(data['departureTime']),
      availableSeats: data['availableSeats'] ?? 0,
      totalSeats: data['totalSeats'] ?? 0,
      suggestedFare: (data['suggestedFare'] ?? 0.0).toDouble(),
      rideType: data['rideType'] ?? 'random',
      vehicleType: (data['vehicleType'] ?? 'car').toString(),
      rideMode: (data['rideMode'] ?? 'share').toString(),
      isShazoreRide: data['isShazoreRide'] == true,
      isLadiesRide: data['isLadiesRide'] == true,
      captainGender: data['captainGender'] as String?,
      tourType: data['tourType'] as String?,
      maxPassengers: data['maxPassengers'] != null
          ? int.tryParse(data['maxPassengers'].toString())
          : null,
      cargoType: data['cargoType'] as String?,
      weightCapacity: data['weightCapacity'] != null
          ? double.tryParse(data['weightCapacity'].toString())
          : null,
      truckSize: data['truckSize'] as String?,
      status: data['status'] ?? 'active',
      full: data['full'] == true || (data['availableSeats'] ?? 0) <= 0,
      acceptsDelivery: data['acceptsDelivery'] ?? false,
      vehicleInfo: data['vehicleInfo'],
      captainRating: (data['captainRating'] ?? 0.0).toDouble(),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) return DateTime.now();
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap({bool forFirestore = false}) {
    return {
      'captainId': captainId,
      'captainName': captainName,
      if (captainPhone != null) 'captainPhone': captainPhone,
      'startLocation': startLocation,
      'endLocation': endLocation,
      if (exactLocation != null && exactLocation!.trim().isNotEmpty)
        'exactLocation': exactLocation,
      if (exactDropLocation != null && exactDropLocation!.trim().isNotEmpty)
        'exactDropLocation': exactDropLocation,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'departureTime': forFirestore
          ? Timestamp.fromDate(departureTime)
          : departureTime.toIso8601String(),
      'availableSeats': availableSeats,
      'totalSeats': totalSeats,
      'suggestedFare': suggestedFare,
      'rideType': rideType,
      'vehicleType': vehicleType,
      'rideMode': rideMode,
      'isShazoreRide': isShazoreRide,
      'isLadiesRide': isLadiesRide,
      if (captainGender != null) 'captainGender': captainGender,
      if (tourType != null) 'tourType': tourType,
      if (maxPassengers != null) 'maxPassengers': maxPassengers,
      if (cargoType != null) 'cargoType': cargoType,
      if (weightCapacity != null) 'weightCapacity': weightCapacity,
      if (truckSize != null) 'truckSize': truckSize,
      'status': status,
      'acceptsDelivery': acceptsDelivery,
      'vehicleInfo': vehicleInfo,
      'captainRating': captainRating,
      'createdAt': forFirestore
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  RideModel copyWith({
    String? id,
    String? captainId,
    String? captainName,
    String? captainPhone,
    String? startLocation,
    String? endLocation,
    String? exactLocation,
    String? exactDropLocation,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    DateTime? departureTime,
    int? availableSeats,
    int? totalSeats,
    double? suggestedFare,
    String? rideType,
    String? vehicleType,
    String? rideMode,
    bool? isShazoreRide,
    bool? isLadiesRide,
    String? captainGender,
    String? tourType,
    int? maxPassengers,
    String? cargoType,
    double? weightCapacity,
    String? truckSize,
    String? status,
    bool? full,
    bool? acceptsDelivery,
    String? vehicleInfo,
    double? captainRating,
    DateTime? createdAt,
  }) {
    return RideModel(
      id: id ?? this.id,
      captainId: captainId ?? this.captainId,
      captainName: captainName ?? this.captainName,
      captainPhone: captainPhone ?? this.captainPhone,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      exactLocation: exactLocation ?? this.exactLocation,
      exactDropLocation: exactDropLocation ?? this.exactDropLocation,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      totalSeats: totalSeats ?? this.totalSeats,
      suggestedFare: suggestedFare ?? this.suggestedFare,
      rideType: rideType ?? this.rideType,
      vehicleType: vehicleType ?? this.vehicleType,
      rideMode: rideMode ?? this.rideMode,
      isShazoreRide: isShazoreRide ?? this.isShazoreRide,
      isLadiesRide: isLadiesRide ?? this.isLadiesRide,
      captainGender: captainGender ?? this.captainGender,
      tourType: tourType ?? this.tourType,
      maxPassengers: maxPassengers ?? this.maxPassengers,
      cargoType: cargoType ?? this.cargoType,
      weightCapacity: weightCapacity ?? this.weightCapacity,
      truckSize: truckSize ?? this.truckSize,
      status: status ?? this.status,
      full: full ?? this.full,
      acceptsDelivery: acceptsDelivery ?? this.acceptsDelivery,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      captainRating: captainRating ?? this.captainRating,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Formats vehicleInfo whether stored as map or legacy string.
  static String formatVehicleInfo(dynamic info) {
    if (info == null) return '';
    if (info is String) return info.trim();
    if (info is Map) {
      final parts = <String?>[
        info['make']?.toString(),
        info['model']?.toString(),
        info['color']?.toString(),
        info['registration']?.toString(),
      ]
          .whereType<String>()
          .where((p) => p.trim().isNotEmpty)
          .map((p) => p.trim());
      return parts.join(' • ');
    }
    return info.toString();
  }

  String get displayVehicle => formatVehicleInfo(vehicleInfo);

  bool get isFull => full || availableSeats <= 0 || status == 'filled';

  String get seatsLabel {
    if (isFull) return 'Full';
    if (totalSeats > 0) {
      return '$availableSeats of $totalSeats seats left';
    }
    return '$availableSeats seats left';
  }

  // Convenience getters for compatibility
  String get from => startLocation;
  String get to => endLocation;
  bool get isRecurring => false;
  double get offeredFare => suggestedFare;
}
