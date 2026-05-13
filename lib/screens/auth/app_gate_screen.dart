import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../services/app_mode_service.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import 'role_select_screen.dart';

/// Cold start: restore passenger session or send captain to phone flow / role picker.
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
    final persona = await AppModeService.getPersona();
    if (!mounted) return;

    if (persona == 'customer') {
      await CustomerFlow.signInAndOpenHome(context);
      return;
    }
    if (persona == 'captain') {
      await CaptainFlow.resumeOrPhone(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const RoleSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class CustomerFlow {
  CustomerFlow._();

  static Future<void> signInAndOpenHome(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final nav = Navigator.of(context);

    try {
      final user = await auth.signInOrRestoreCustomerSession();
      await auth.ensureCustomerUserDocument(user.uid);
      final data = await auth.getUserData(user.uid);
      if (data != null) {
        userProvider.setUser(data);
      }
      if (!context.mounted) return;
      nav.pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      if (!context.mounted) return;
      AppHelpers.showSnackBar(context, '$e', isError: true);
      await AppModeService.clearPersona();
      if (!context.mounted) return;
      nav.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const RoleSelectScreen()),
      );
    }
  }
}

class CaptainFlow {
  CaptainFlow._();

  static Future<void> resumeOrPhone(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final nav = Navigator.of(context);

    final cur = auth.currentUser;
    if (cur != null && !cur.isAnonymous) {
      final data = await auth.getUserData(cur.uid);
      if (data != null && data.role == 'captain') {
        userProvider.setUser(data);
        if (!context.mounted) return;
        nav.pushNamedAndRemoveUntil('/home', (_) => false);
        return;
      }
      final phone = cur.phoneNumber;
      if (phone != null && phone.isNotEmpty) {
        if (!context.mounted) return;
        nav.pushReplacementNamed('/captain-register');
        return;
      }
    }

    if (!context.mounted) return;
    nav.pushReplacementNamed('/captain-phone');
  }
}
