import 'package:flutter/material.dart';

/// Legacy captain phone/SMS flow — replaced by Google Sign-In + captain register.
/// Keeps the route alive; forwards to captain registration.
class CaptainPhoneScreen extends StatefulWidget {
  const CaptainPhoneScreen({super.key});

  @override
  State<CaptainPhoneScreen> createState() => _CaptainPhoneScreenState();
}

class _CaptainPhoneScreenState extends State<CaptainPhoneScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/captain-register');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
