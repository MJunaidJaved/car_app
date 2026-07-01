import 'dart:async';
import 'dart:math' as math;
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
  late AnimationController _shimmerCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _pulseScale;
  late Animation<double> _shimmerAnim;

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

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(_shimmerCtrl);

    _logoCtrl.forward();
    Future.delayed(
        const Duration(milliseconds: 400), () => _contentCtrl.forward());
    _pulseCtrl.repeat();
    _shimmerCtrl.repeat();

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
    setState(() {
      _isLoading = true;
      _pulseCtrl.stop(); // Stop pulse to prevent jank
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userModel = await authService.signInWithGoogle();
      if (!mounted || userModel == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _pulseCtrl.repeat();
          });
        }
        return;
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUser(userModel);

      final role = userModel.role.isNotEmpty
          ? userModel.role
          : await SessionStorage.getRole();
      if (!mounted) return;

      if (role == 'captain') {
        final status =
            (userModel.captainVerificationStatus ?? '').trim().toLowerCase();
        if (status == 'pending_verification') {
          Navigator.pushReplacementNamed(context, '/verification-pending');
        } else if (status == 'verified' || userModel.isVerified) {
          Navigator.pushReplacementNamed(context, '/captain-home');
        } else {
          Navigator.pushReplacementNamed(context, '/captain-register');
        }
      } else if (role == 'passenger' || role == 'customer') {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (role != null && role.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/role-select');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pulseCtrl.repeat();
        });
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
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _contentCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
            ),
          ),

          // floating circular background blobs
          const Positioned.fill(
            child: _FloatingBlobsBackground(),
          ),

          // Bottom blur gradient above button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 240,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withValues(alpha:0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 55,
                  child: Center(
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.deepNavy.withValues(alpha:0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/shareway_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'ShareWay',
                            style: GoogleFonts.playfairDisplay(
                              color: AppColors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SAVE FUEL · SHARE RIDES · EARN',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 45,
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
                              text: 'Instant booking',
                              delayMs: 0,
                            ),
                            const SizedBox(height: 14),
                            const _FeatureRow(
                              icon: Icons.check_circle_outline_rounded,
                              text: 'Verified captains',
                              delayMs: 150,
                            ),
                            const SizedBox(height: 14),
                            const _FeatureRow(
                              icon: Icons.check_circle_outline_rounded,
                              text: 'Flexible fares',
                              delayMs: 300,
                            ),
                            const Spacer(),
                            ScaleTransition(
                              scale: _pulseScale,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _signInWithGoogle,
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.deepNavy
                                            .withValues(alpha:0.16),
                                        blurRadius: 22,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: AppColors.white,
                                              strokeWidth: 2))
                                      : AnimatedBuilder(
                                          animation: _shimmerAnim,
                                          builder: (context, child) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.white,
                                                    AppColors.white,
                                                    AppColors.white
                                                        .withValues(alpha:0.7),
                                                    AppColors.white,
                                                    AppColors.white,
                                                  ],
                                                  stops: [
                                                    0.0,
                                                    math.max(
                                                        0.0,
                                                        _shimmerAnim.value -
                                                            0.3),
                                                    math.max(
                                                        0.0,
                                                        math.min(
                                                            1.0,
                                                            _shimmerAnim
                                                                .value)),
                                                    math.min(
                                                        1.0,
                                                        _shimmerAnim.value +
                                                            0.3),
                                                    1.0,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: child,
                                            );
                                          },
                                          child: const Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _GoogleIcon(),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Continue with Google',
                                                  style: TextStyle(
                                                    color: AppColors.deepNavy,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Secure authentication powered by Google',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha:0.68),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
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

class _FloatingBlobsBackground extends StatefulWidget {
  const _FloatingBlobsBackground();

  @override
  State<_FloatingBlobsBackground> createState() =>
      _FloatingBlobsBackgroundState();
}

class _FloatingBlobsBackgroundState extends State<_FloatingBlobsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final dx1 = size.width * 0.12 * math.sin(t * 2 * math.pi);
        final dy1 = size.height * 0.1 * math.cos(t * 2 * math.pi);
        final dx2 = size.width * 0.08 * math.cos(t * 1.5 * math.pi);
        final dy2 = size.height * 0.08 * math.sin(t * 1.5 * math.pi);

        return Stack(
          children: [
            Positioned(
              left: size.width * 0.05 + dx1,
              top: size.height * 0.15 + dy1,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.skyBlue.withValues(alpha:0.12),
                      AppColors.skyBlue.withValues(alpha:0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: size.width * 0.05 + dx2,
              bottom: size.height * 0.25 + dy2,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.electricBlue.withValues(alpha:0.1),
                      AppColors.electricBlue.withValues(alpha:0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: size.width * 0.25 + dx2,
              bottom: size.height * 0.05 + dy1,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.cyan.withValues(alpha:0.1),
                      AppColors.cyan.withValues(alpha:0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureRow extends StatefulWidget {
  final IconData icon;
  final String text;
  final int delayMs;

  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.delayMs,
  });

  @override
  State<_FeatureRow> createState() => _FeatureRowState();
}

class _FeatureRowState extends State<_FeatureRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.olive, size: 16),
          const SizedBox(width: 12),
          Text(
            widget.text,
            style: TextStyle(
              color: AppColors.white.withValues(alpha:0.7),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.textMuted.withValues(alpha:0.3)),
      ),
      alignment: Alignment.center,
      child: RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          children: [
            TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
          ],
        ),
      ),
    );
  }
}

