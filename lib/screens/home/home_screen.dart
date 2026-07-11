import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import 'passenger_home_screen.dart';
import 'captain_home_screen.dart';
import '../auth/role_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    setState(() => _isLoading = true);
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // Fetch profile from backend
      final response = await ApiService.get('/auth/profile');
      final userData = response['user'];
      final role = (userData['role'] ?? '').toString().toLowerCase().trim();

      // Update provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null) {
        final updatedUser = userProvider.user?.copyWith(role: role);
        if (updatedUser != null) {
          userProvider.setUser(updatedUser);
        }
      }

      setState(() => _role = role);
    } catch (e) {
      debugPrint('Error loading user role: $e');
      setState(() => _role = '');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_role == 'captain') {
      return const CaptainHomeScreen();
    } else if (_role == 'passenger' || _role == 'customer') {
      return const PassengerHomeScreen();
    } else {
      return const RoleSelectScreen();
    }
  }
}
