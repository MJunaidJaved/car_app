import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ Added for kDebugMode
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async'; // ✅ Added for Timer

import 'navigation/app_navigator.dart';
import 'services/fcm_service.dart';
import 'services/api_service.dart';
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
import 'screens/profile/edit_profile_screen.dart';
import 'screens/captain/requests_screen.dart';
import 'screens/captain/customer_requests_screen.dart';
import 'screens/ride/deal_confirmed_screen.dart';
import 'screens/ride/rate_review_screen.dart';
import 'screens/tours/tours_screen.dart';
import 'screens/tours/tour_detail_screen.dart';
import 'screens/tours/tour_booked_screen.dart';
import 'screens/notifications/notifications_screen.dart';

import 'utils/app_theme.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Contain widget-build errors instead of letting them blow up into a
  // full-screen (or giant-overflow) red error box. Any single widget that
  // throws during build now renders as a small, bounded, friendly card in
  // its own place instead of a wall of stack-trace text that can also
  // trigger huge RenderFlex overflow warnings around it. This does not
  // hide bugs from developers — in debug mode the full error is still
  // printed to the console — it just keeps the *UI* smooth for the user.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFFF3F3),
      child: Text(
        // ✅ In debug builds, show the real exception text so it can be
        // read straight off the device/screenshot instead of guessing.
        // Release builds keep the generic, user-safe message.
        kDebugMode
            ? details.exceptionAsString()
            : 'Something went wrong loading this.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFB3261E),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  };

  await dotenv.load(fileName: ".env");
  ApiService.wakeBackend();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await FcmService.initialize();
  Provider.debugCheckInvalidValueType = null;

  // ✅ AUTO-CLEANUP: Schedule cleanup every 6 hours
  _scheduleAutoCleanup();

  runApp(const ShareWayApp());
}

// ✅ AUTO-CLEANUP FUNCTION
void _scheduleAutoCleanup() {
  Timer.periodic(const Duration(hours: 6), (timer) async {
    try {
      final firestoreService = FirestoreService();
      final count = await firestoreService.cleanupOldBookings();
      debugPrint('✅ Auto-cleanup: $count bookings deleted');
    } catch (e) {
      debugPrint('❌ Auto-cleanup error: $e');
    }
  });

  // ✅ Run initial cleanup after 1 minute
  Timer(const Duration(minutes: 1), () async {
    try {
      final firestoreService = FirestoreService();
      final count = await firestoreService.cleanupOldBookings();
      debugPrint('✅ Initial cleanup: $count bookings deleted');
    } catch (e) {
      debugPrint('❌ Initial cleanup error: $e');
    }
  });
}

class ShareWayApp extends StatelessWidget {
  const ShareWayApp({super.key});

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
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'ShareWay',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: '/',
          builder: (context, child) {
            // ✅ "Work on all devices": some phones ship with a much
            // larger system font-size / accessibility text-scale setting.
            // Screens in this app use several fixed-height rows (tab
            // bars, chip rows, header rows) that were never designed to
            // grow with a 1.3x–2x text scale, and that mismatch is what
            // produces large, seemingly random overflow errors on some
            // devices but not others. Clamping the scale keeps text
            // readable while keeping every fixed-height layout intact on
            // every device.
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.15,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
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

            '/edit-profile': (context) => const EditProfileScreen(),

            '/active-ride': (context) => const ActiveRideScreen(),

            '/earnings': (context) => const EarningsScreen(),

            '/requests': (context) => const RequestsScreen(),

            '/deal-confirmed': (context) => const DealConfirmedScreen(),

            '/rate-review': (context) => const RateReviewScreen(),

            '/tours': (context) => const ToursScreen(),

            '/tour-booked': (context) => const TourBookedScreen(),

            '/notifications': (context) => const NotificationsScreen(),
          },
        ), // Closes MaterialApp
      ), // Closes Container
    ); // Closes MultiProvider
  }
}
