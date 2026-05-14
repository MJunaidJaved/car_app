import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/session_storage.dart';
import 'passenger_home_screen.dart';
import 'captain_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromPrefs());
  }

  Future<void> _syncFromPrefs() async {
    final u = await SessionStorage.loadUserModel();
    if (!mounted || u == null) return;
    Provider.of<UserProvider>(context, listen: false).setUser(u);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final isCaptain = user?.role == 'captain';

    if (isCaptain) {
      return const CaptainHomeScreen();
    } else {
      return const PassengerHomeScreen();
    }
  }
}