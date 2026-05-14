import 'package:flutter/material.dart';
import '../../widgets/app_widgets.dart';

class DealConfirmedScreen extends StatelessWidget {
  const DealConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.handshake, size: 70, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              const Text('Deal Confirmed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 16),
              const Text(
                'The ride deal has been finalized. Both parties have been notified. Get ready for the journey!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: TealButton(
                  label: 'View Active Ride',
                  isLoading: false,
                  onTap: () => Navigator.pushReplacementNamed(context, '/active-ride'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
