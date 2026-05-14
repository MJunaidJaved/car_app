import 'package:flutter/material.dart';
import '../../widgets/app_widgets.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Refer & Earn', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.card_giftcard, size: 100, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text('Invite Your Friends!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 16),
            const Text(
              'Share your referral code with your friends and get Rs 50 credit in your wallet for every friend who signs up and completes their first ride.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CARPOOL2024', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 2)),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied to clipboard!')));
                    },
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: TealButton(
                label: 'Share Referral Link',
                isLoading: false,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
