import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  String _referralCode(String uid) {
    if (uid.length >= 8) return uid.substring(0, 8).toUpperCase();
    return uid.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context).user?.id ?? '';
    final code = _referralCode(uid);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.dark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Refer & Earn', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.dark,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.card_giftcard_rounded, size: 48, color: AppColors.primary),
                              const SizedBox(height: 16),
                              const Text('Invite friends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
                              const SizedBox(height: 8),
                              Text(
                                'Share your code. When they sign up and complete a ride, you both earn wallet credit.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Your Referral Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.light),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                              ),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Code copied'), duration: Duration(seconds: 2)),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


