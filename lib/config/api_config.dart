// api_config.dart
// API Configuration for the ShareWay backend

class ApiConfig {
  static const String baseUrl = 'https://huzaifa1435-carpool-final.hf.space/api';

  // ============= AUTH ENDPOINTS =============
  static const String syncUser = '$baseUrl/auth/sync';
  static const String getProfile = '$baseUrl/auth/profile';
  static const String updateProfile = '$baseUrl/auth/profile';
  static const String updateCaptainProfile = '$baseUrl/auth/profile/captain';
  static const String updateFcmToken = '$baseUrl/auth/fcm-token';

  // ============= RIDE ENDPOINTS =============
  static const String postRide = '$baseUrl/rides';
  static const String getActiveRides = '$baseUrl/rides';
  static const String getMyRides = '$baseUrl/rides/my-rides';

  // ============= DEAL ENDPOINTS =============
  static const String createDeal = '$baseUrl/deals';
  static const String getMyBookings = '$baseUrl/deals/my-bookings';
  static String getDeal(String dealId) => '$baseUrl/deals/$dealId';
  static String confirmDeal(String dealId) => '$baseUrl/deals/$dealId/confirm';
  static String cancelDeal(String dealId) => '$baseUrl/deals/$dealId/cancel';
  static String counterDeal(String dealId) => '$baseUrl/deals/$dealId/counter';
  static String startDeal(String dealId) => '$baseUrl/deals/$dealId/start';
  static String completeDeal(String dealId) =>
      '$baseUrl/deals/$dealId/complete';
  static String rateDeal(String dealId) => '$baseUrl/deals/$dealId/rate';
  static String getRideDeals(String rideId) => '$baseUrl/deals/ride/$rideId';
  static String getConfirmedPassengers(String rideId) =>
      '$baseUrl/deals/ride/$rideId/confirmed';
  static String updateBoardingStatus(String dealId) =>
      '$baseUrl/deals/$dealId/boarding';
  static String notifyDealMessage(String dealId) =>
      '$baseUrl/deals/$dealId/notify-message';

  // ============= CUSTOMER REQUEST ENDPOINTS =============
  static const String postCustomerRequest = '$baseUrl/customer-requests';
  static const String getCustomerRequests = '$baseUrl/customer-requests';
  static const String getMyCustomerRequests = '$baseUrl/customer-requests/my';

  // ============= WALLET ENDPOINTS =============
  static const String getWallet = '$baseUrl/wallet';
  static const String getTransactions = '$baseUrl/wallet/transactions';
  static const String topUpWallet = '$baseUrl/wallet/topup';
  static const String getEarningsSummary = '$baseUrl/wallet/earnings-summary';

  // ============= NOTIFICATION ENDPOINTS =============
  static const String getNotifications = '$baseUrl/notifications';

  // Dynamic endpoints (IDs in path)
  static String getRideById(String rideId) => '$baseUrl/rides/$rideId';
  static String updateRideStatus(String rideId) =>
      '$baseUrl/rides/$rideId/status';
  static String updateRideLocation(String rideId) =>
      '$baseUrl/rides/$rideId/location';

  static String getCustomerRequestById(String requestId) =>
      '$baseUrl/customer-requests/$requestId';
  static String createCustomerOffer(String requestId) =>
      '$baseUrl/customer-requests/$requestId/offers';
  static String respondCustomerOffer(String requestId, String offerId) =>
      '$baseUrl/customer-requests/$requestId/offers/$offerId';
}