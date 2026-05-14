import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/session_storage.dart';
import '../../providers/user_provider.dart';

class _C {
  static const primary   = Color(0xFF414833); // Primary Action
  static const dark      = Color(0xFF414833); // Header/Black
  static const accent    = Color(0xFF737A5D); // Accent
  static const black     = Color(0xFF414833);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF414833);
  static const textMuted = Color(0xFF737A5D);
  static const bg        = Color(0xFFF5E3D2);
}

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
    
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutQuart);
    
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeIn);
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));
    
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.02), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.02, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _contentCtrl.forward());
    _pulseCtrl.repeat();

    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final loggedIn = await SessionStorage.isLoggedIn();
    if (!mounted) return;
    if (!loggedIn) return;

    final user = await SessionStorage.loadUserModel();
    if (!mounted) return;
    if (user == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setUser(user);

    final role = await SessionStorage.getRole();
    if (!mounted) return;

    if (role != null && role.isNotEmpty) {
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
            backgroundColor: _C.dark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _C.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E3323), Color(0xFF414833)],
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
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: _C.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.directions_car_filled_rounded, color: _C.black, size: 44),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'CarPool',
                            style: GoogleFonts.playfairDisplay(
                              color: _C.white,
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PREMIUM CITY TRANSIT',
                            style: GoogleFonts.inter(
                              color: _C.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
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
                            const _FeatureRow(icon: Icons.check_circle_outline_rounded, text: 'Instant booking'),
                            const SizedBox(height: 14),
                            const _FeatureRow(icon: Icons.check_circle_outline_rounded, text: 'Verified captains'),
                            const SizedBox(height: 14),
                            const _FeatureRow(icon: Icons.check_circle_outline_rounded, text: 'Flexible fares'),
                            const Spacer(),
                            
                            ScaleTransition(
                              scale: _pulseScale,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _signInWithGoogle,
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: _C.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _isLoading
                                      ? const Center(child: CircularProgressIndicator(color: _C.black, strokeWidth: 2))
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const _GoogleIcon(),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Continue with Google',
                                                style: GoogleFonts.inter(
                                                  color: _C.black,
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
                                color: _C.white.withOpacity(0.3),
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
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
        Icon(icon, color: _C.accent, size: 16),
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
      width: 20, height: 20,
      padding: const EdgeInsets.all(0),
      child: Image.network(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_logo.svg/24px-Google_\"G\"_logo.svg.png',
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, color: Colors.blue, size: 20),
      ),
    );
  }
}



