import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'navigation/app_navigator.dart';
import 'services/fcm_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/ride_service.dart';

import 'providers/user_provider.dart';

import 'models/ride_model.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/auth/captain_register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/account_created_screen.dart';
import 'screens/auth/verification_pending_screen.dart';

import 'screens/home/home_screen.dart';
import 'screens/home/captain_home_screen.dart';
import 'screens/driver/post_ride_screen.dart';
import 'screens/driver/my_rides_screen.dart';

import 'screens/passenger/find_ride_screen.dart';
import 'screens/passenger/my_bookings_screen.dart';
import 'screens/passenger/customer_request_screen.dart';
import 'screens/ride/fare_negotiate_screen.dart';

import 'screens/ride/active_ride_screen.dart';

import 'screens/wallet/wallet_screen.dart';
import 'screens/captain/earnings_screen.dart';

import 'screens/profile/profile_screen.dart';
import 'screens/profile/referral_screen.dart';
import 'screens/captain/requests_screen.dart';
import 'screens/captain/customer_requests_screen.dart';
import 'screens/ride/deal_confirmed_screen.dart';
import 'screens/ride/rate_review_screen.dart';
import 'screens/tours/tours_screen.dart';
import 'screens/tours/tour_detail_screen.dart';
import 'screens/tours/tour_booked_screen.dart';
import 'screens/notifications/notifications_screen.dart';

import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  await FcmService.initialize();
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final screen = (message.data['screen'] ?? '').toString();
    final type = (message.data['type'] ?? '').toString();
    if (type == 'customer_offer') {
      AppNavigator.state?.pushNamed('/customer-request');
      return;
    }
    if (screen == 'find-ride') {
      AppNavigator.state?.pushNamed('/find-ride');
      return;
    }
    if (screen == 'my-rides') {
      AppNavigator.state?.pushNamed('/my-rides');
      return;
    }
    if (screen == 'customer-requests') {
      AppNavigator.state?.pushNamed('/customer-requests');
    }
  });
  Provider.debugCheckInvalidValueType = null;
  runApp(const CarPoolApp());
}

class CarPoolApp extends StatelessWidget {
  const CarPoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        ChangeNotifierProvider<RideService>(
          create: (_) => RideService(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'CarPool App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == '/fare-negotiate') {
            final ride = settings.arguments as RideModel?;
            if (ride == null) return null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => FareNegotiateScreen(ride: ride),
            );
          }
          if (settings.name == '/tour-detail') {
            final ride = settings.arguments as RideModel?;
            if (ride == null) return null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => TourDetailScreen(ride: ride),
            );
          }
          return null;
        },
        routes: {
          '/': (context) => const SplashScreen(),

          '/gate': (context) =>
              const SplashScreen(), // Redirect to splash which handles session

          '/role-select': (context) => const RoleSelectScreen(),

          '/captain-register': (context) => const CaptainRegisterScreen(),

          '/verification-pending': (context) =>
              const VerificationPendingScreen(),

          '/account-created': (context) => const AccountCreatedScreen(),

          '/login': (context) => const LoginScreen(),

          '/signup': (context) => const SignupScreen(),

          '/home': (context) => const HomeScreen(),

          '/captain-home': (context) => const CaptainHomeScreen(),

          '/post-ride': (context) => const PostRideScreen(),

          '/my-rides': (context) => const MyRidesScreen(),

          '/find-ride': (context) => const FindRideScreen(),

          '/my-bookings': (context) => const MyBookingsScreen(),

          '/customer-request': (context) => const CustomerRequestScreen(),

          '/customer-requests': (context) =>
              const CaptainCustomerRequestsScreen(),

          '/wallet': (context) => const WalletScreen(),

          '/profile': (context) => const ProfileScreen(),

          '/active-ride': (context) => const ActiveRideScreen(),

          '/earnings': (context) => const EarningsScreen(),

          '/requests': (context) => const RequestsScreen(),

          '/deal-confirmed': (context) => const DealConfirmedScreen(),

          '/rate-review': (context) => const RateReviewScreen(),

          '/tours': (context) => const ToursScreen(),

          '/tour-booked': (context) => const TourBookedScreen(),

          '/notifications': (context) => const NotificationsScreen(),

          '/referral': (context) => const ReferralScreen(),
        },
      ),
    );
  }
}
