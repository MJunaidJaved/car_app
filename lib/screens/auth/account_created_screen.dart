import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class AccountCreatedScreen extends StatefulWidget {
  const AccountCreatedScreen({super.key});
  @override
  State<AccountCreatedScreen> createState() => _AccountCreatedScreenState();
}

class _AccountCreatedScreenState extends State<AccountCreatedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.bark,
      body: Stack(
        children: [
          // Simple Confetti effect
          ...List.generate(25, (index) => _ConfettiPiece(index: index)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    // Animated check icon
                    Center(
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.success.withValues(alpha:0.3),
                                width: 3),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.success,
                            size: 58,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      "Documents submitted",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your Captain profile is under admin review.\nAccess unlocks after approval.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.sage.withValues(alpha:0.8),
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Status checklist card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppColors.sage.withValues(alpha:0.3), width: 1),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: const Column(
                        children: [
                          _StatusItem(
                            icon: Icons.link_rounded,
                            label: 'Google account linked securely',
                            isDone: true,
                          ),
                          SizedBox(height: 18),
                          _StatusItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Wallet created',
                            isDone: true,
                          ),
                          SizedBox(height: 18),
                          _StatusItem(
                            icon: Icons.description_outlined,
                            label: 'Docs under review (24 hrs)',
                            isDone: false,
                            isPending: true,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // CTA - Navigate to HomeScreen (handles role-based navigation)
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Refresh user profile from backend
                          try {
                            final response =
                                await ApiService.get('/auth/profile');
                            final userData = response['user'];

                            if (mounted) {
                              final userProvider = Provider.of<UserProvider>(
                                  context,
                                  listen: false);
                              if (userProvider.user != null) {
                                final updatedUser = userProvider.user?.copyWith(
                                  role: userData['role'],
                                  captainVerificationStatus:
                                      userData['captainVerificationStatus'],
                                  isVerified: userData['isVerified'] ?? false,
                                );
                                userProvider.setUser(updatedUser!);
                              }
                            }
                          } catch (e) {
                            debugPrint('Error refreshing profile: $e');
                          }

                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/gate');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.moss,
                          foregroundColor: AppColors.cream,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Check Verification Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        "You'll be notified once your Captain account is approved",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.sage.withValues(alpha:0.7),
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPiece extends StatefulWidget {
  final int index;
  const _ConfettiPiece({required this.index});

  @override
  State<_ConfettiPiece> createState() => _ConfettiPieceState();
}

class _ConfettiPieceState extends State<_ConfettiPiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late double _left;
  late double _top;
  late Color _color;
  late double _size;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _left = random.nextDouble() * 400;
    _top = -20.0;
    _size = random.nextDouble() * 10 + 5;
    // Using the earthy palette for confetti
    _color = [
      AppColors.primary,
      AppColors.dark,
      AppColors.accent,
      AppColors.light
    ][random.nextInt(4)];

    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + random.nextInt(1000)));
    _ctrl.forward();
    _ctrl.addListener(() {
      if (mounted) {
        setState(() {
          _top += 5;
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _left,
      top: _top,
      child: RotationTransition(
        turns: _ctrl,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
              color: _color,
              shape:
                  widget.index % 2 == 0 ? BoxShape.circle : BoxShape.rectangle),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final bool isPending;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.isDone,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isPending
                ? AppColors.accent.withValues(alpha:0.12)
                : AppColors.primary.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: isPending ? AppColors.accent : AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.bark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.access_time_rounded,
          color: isDone ? AppColors.success : AppColors.sage,
          size: 22,
        ),
      ],
    );
  }
}

