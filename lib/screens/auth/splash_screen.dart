import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/session_storage.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _pulseScale;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutQuart);

    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeIn);
    _contentSlide = Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.02), weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.02, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _logoCtrl.forward();
    Future.delayed(
        const Duration(milliseconds: 400), () => _contentCtrl.forward());
    _pulseCtrl.repeat();

    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      final loggedIn = await SessionStorage.isLoggedIn();
      if (!mounted) return;
      if (!loggedIn) return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    final user = await auth.restoreSession();
    if (!mounted) return;
    if (user == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setUser(user);

    final role =
        user.role.isNotEmpty ? user.role : await SessionStorage.getRole();
    if (!mounted) return;

    if (role == 'captain') {
      final status =
          (user.captainVerificationStatus ?? '').trim().toLowerCase();
      if (status == 'pending_verification') {
        Navigator.pushReplacementNamed(context, '/verification-pending');
      } else if (status == 'verified' || user.isVerified) {
        Navigator.pushReplacementNamed(context, '/captain-home');
      } else {
        Navigator.pushReplacementNamed(context, '/captain-register');
      }
    } else if (role == 'passenger' || role == 'customer') {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/role-select');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userModel = await authService.signInWithGoogle();
      if (!mounted || userModel == null) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUser(userModel);

      final role = await SessionStorage.getRole();
      if (!mounted) return;

      if (role != null && role.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/role-select');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.bark,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _contentCtrl.dispose();
    _pulseCtrl.dispose();
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
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bark, AppColors.moss],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 60,
                  child: Center(
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.moss,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                                Icons.directions_car_filled_rounded,
                                color: AppColors.cream,
                                size: 44),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'CarPool',
                            style: GoogleFonts.playfairDisplay(
                              color: AppColors.cream,
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SAVE FUEL · SHARE RIDES · EARN',
                            style: GoogleFonts.inter(
                              color: AppColors.olive,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 40,
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Column(
                          children: [
                            const _FeatureRow(
                                icon: Icons.check_circle_outline_rounded,
                                text: 'Instant booking'),
                            const SizedBox(height: 14),
                            const _FeatureRow(
                                icon: Icons.check_circle_outline_rounded,
                                text: 'Verified captains'),
                            const SizedBox(height: 14),
                            const _FeatureRow(
                                icon: Icons.check_circle_outline_rounded,
                                text: 'Flexible fares'),
                            const Spacer(),
                            ScaleTransition(
                              scale: _pulseScale,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _signInWithGoogle,
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: AppColors.bark,
                                              strokeWidth: 2))
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const _GoogleIcon(),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Continue with Google',
                                                style: GoogleFonts.inter(
                                                  color: AppColors.bark,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Secure authentication powered by Google',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppColors.cream.withOpacity(0.3),
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 16,
                            ),
                          ],
                        ),
                      ),
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

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.olive, size: 16),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      padding: const EdgeInsets.all(0),
      child: Image.network(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_"G"_logo.svg/24px-Google_"G"_logo.svg.png',
        errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.g_mobiledata_rounded,
            color: Colors.blue,
            size: 20),
      ),
    );
  }
}
