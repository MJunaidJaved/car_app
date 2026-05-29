// api_config.dart
// API Configuration for the CarPool backend hosted on Hugging Face

class ApiConfig {
  // 🚀 Hugging Face Live Direct URL (Sahi Space - Huzaifa1435)
  static const String baseUrl = 'https://huzaifa1435-carpool.hf.space/api';

  // ============= AUTH ENDPOINTS =============
  static const String syncUser = '$baseUrl/auth/sync';
  static const String getProfile = '$baseUrl/auth/profile';
  static const String updateProfile = '$baseUrl/auth/profile';
  static const String updateCaptainProfile = '$baseUrl/auth/profile/captain';
  static const String updateFcmToken = '$baseUrl/auth/fcm-token';

  // ============= RIDE ENDPOINTS =============
  static const String postRide = '$baseUrl/rides';          // Post a new ride
  static const String getActiveRides = '$baseUrl/rides';    // Get active rides (GET)
  static const String getMyRides = '$baseUrl/rides/my';     // Captain's own rides

  // ============= CUSTOMER REQUEST ENDPOINTS =============
  static const String postCustomerRequest = '$baseUrl/customer-requests';
  static const String getCustomerRequests = '$baseUrl/customer-requests';
  static const String getMyCustomerRequests = '$baseUrl/customer-requests/my';

  // Dynamic Endpoints ke liye functions (agar URL mein ID pass karni ho)
  static String getRideById(String rideId) => '$baseUrl/rides/$rideId';
  static String updateRideStatus(String rideId) => '$baseUrl/rides/$rideId/status';
  static String updateRideLocation(String rideId) => '$baseUrl/rides/$rideId/location';
  
  static String getCustomerRequestById(String requestId) => '$baseUrl/customer-requests/$requestId';
  static String updateCustomerRequestStatus(String requestId) => '$baseUrl/customer-requests/$requestId/status';
}
