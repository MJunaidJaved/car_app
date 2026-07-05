import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../utils/helpers.dart';
import '../../utils/captain_profile_utils.dart';

/// Session bootstrap: checks Firebase auth, restores profile, navigates based on role
class AppGateScreen extends StatefulWidget {
  const AppGateScreen({super.key});

  @override
  State<AppGateScreen> createState() => _AppGateScreenState();
}

class _AppGateScreenState extends State<AppGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    try {
      // Check FirebaseAuth
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // Not logged in → go to login
        debugPrint('AppGateScreen: No Firebase user, navigating to /login');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // User exists, fetch profile from API
      debugPrint(
          'AppGateScreen: Firebase user found: ${currentUser.email}, fetching profile');
      try {
        final response = await ApiService.get('/auth/profile');
        final userData = response['user'] as Map<String, dynamic>;

        final user = UserModel.fromMap(userData, currentUser.uid);

        // Set user in provider
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(user);
        }

        if (mounted) {
          if (user.role == 'captain') {
            final status =
                (user.captainVerificationStatus ?? '').trim().toLowerCase();
            if (!CaptainProfileUtils.isProfileComplete(user)) {
              Navigator.pushReplacementNamed(context, '/captain-register');
            } else if (status == 'pending_verification') {
              Navigator.pushReplacementNamed(context, '/verification-pending');
            } else if (status == 'verified' || user.isVerified) {
              Navigator.pushReplacementNamed(context, '/captain-home');
            } else {
              Navigator.pushReplacementNamed(context, '/captain-register');
            }
          } else if (user.role == 'passenger' || user.role == 'customer') {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/role-select');
          }
        }
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.code == 'USER_NOT_FOUND') {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/role-select');
          }
          return;
        }
        debugPrint('AppGateScreen: API error fetching profile: $e');
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          AppHelpers.showSnackBar(
            context,
            'Session expired. Please log in again.',
            isError: true,
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        debugPrint('AppGateScreen: API error fetching profile: $e');
        // Profile fetch failed, clear Firebase and go to login
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          AppHelpers.showSnackBar(
            context,
            'Session expired. Please log in again.',
            isError: true,
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      debugPrint('AppGateScreen: Unexpected error: $e');
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'An error occurred. Please try again.',
          isError: true,
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
