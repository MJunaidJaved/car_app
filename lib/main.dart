import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/grok_ai_service.dart';
import 'services/ride_service.dart';

import 'providers/user_provider.dart';
import 'providers/ride_provider.dart';

import 'models/ride_model.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/auth/app_gate_screen.dart';
import 'screens/auth/captain_phone_screen.dart';
import 'screens/auth/captain_register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/account_created_screen.dart';

import 'screens/home/home_screen.dart';

import 'screens/driver/post_ride_screen.dart';
import 'screens/driver/my_rides_screen.dart';

import 'screens/passenger/find_ride_screen.dart';
import 'screens/passenger/my_bookings_screen.dart';
import 'screens/ride/fare_negotiate_screen.dart';

import 'screens/ride/active_ride_screen.dart';

import 'screens/wallet/wallet_screen.dart';
import 'screens/captain/earnings_screen.dart';

import 'screens/profile/profile_screen.dart';

import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

        Provider<GrokAIService>(
          create: (_) => const GrokAIService(),
        ),

        Provider<RideService>(
          create: (_) => RideService(),
        ),

        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),

        ChangeNotifierProvider<RideProvider>(
          create: (_) => RideProvider(),
        ),
      ],

      child: MaterialApp(
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
          return null;
        },
        routes: {
          '/': (context) => const SplashScreen(),

          '/gate': (context) => const AppGateScreen(),

          '/role-select': (context) => const RoleSelectScreen(),

          '/captain-phone': (context) => const CaptainPhoneScreen(),

          '/captain-register': (context) =>
              const CaptainRegisterScreen(),

          '/account-created': (context) =>
              const AccountCreatedScreen(),

          '/login': (context) => const LoginScreen(),

          '/signup': (context) => const SignupScreen(),

          '/home': (context) => const HomeScreen(),

          '/post-ride': (context) => const PostRideScreen(),

          '/my-rides': (context) => const MyRidesScreen(),

          '/find-ride': (context) => const FindRideScreen(),

          '/my-bookings': (context) => const MyBookingsScreen(),

          '/wallet': (context) => const WalletScreen(),

          '/profile': (context) => const ProfileScreen(),

          '/active-ride': (context) => const ActiveRideScreen(),

          '/earnings': (context) => const EarningsScreen(),
        },
      ),
    );
  }
}
