// config.dart
// API Configuration for the CarPool backend hosted on Hugging Face

class ApiConfig {
  // 🚀 Hugging Face Live Direct URL
  static const String baseUrl = 'https://huzaifa1313-carpool.hf.space';

  // ============= AUTH ENDPOINTS =============
  static const String syncUser = '$baseUrl/api/auth/sync';
  static const String getProfile = '$baseUrl/api/auth/profile';
  static const String updateProfile = '$baseUrl/api/auth/profile';
  static const String updateCaptainProfile = '$baseUrl/api/auth/profile/captain';
  static const String updateFcmToken = '$baseUrl/api/auth/fcm-token';

  // ============= RIDE ENDPOINTS =============
  static const String postRide = '$baseUrl/api/rides';          // Post a new ride
  static const String getActiveRides = '$baseUrl/api/rides';    // Get active rides (GET)
  static const String getMyRides = '$baseUrl/api/rides/my';     // Captain's own rides

  // Dynamic Endpoints ke liye functions (agar URL mein ID pass karni ho)
  static String getRideById(String rideId) => '$baseUrl/api/rides/$rideId';
  static String updateRideStatus(String rideId) => '$baseUrl/api/rides/$rideId/status';
  static String updateRideLocation(String rideId) => '$baseUrl/api/rides/$rideId/location';
}