import 'package:flutter/material.dart';
import '../../widgets/app_widgets.dart';

class TourBookedScreen extends StatelessWidget {
  const TourBookedScreen({super.key});

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
                width: 100,
                height: 100,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 60, color: AppColors.white),
              ),
              const SizedBox(height: 32),
              const Text('Tour Booked!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 16),
              const Text(
                'Your adventure is confirmed. Check your email for the itinerary and payment instructions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: TealButton(
                  label: 'Go to Home',
                  isLoading: false,
                  onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
