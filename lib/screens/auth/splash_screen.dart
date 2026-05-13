import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/session_storage.dart';
import '../../providers/user_provider.dart';

class _C {
  static const primary   = Color(0xFF39988E);
  static const dark      = Color(0xFF1F6059);
  static const light     = Color(0xFFB6D7D1);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF0D1F1E);
  static const textMuted = Color(0xFF7A9E9B);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // Check if already logged in
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    await Future.delayed(const Duration(milliseconds: 500));
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
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _C.dark,
      body: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            top: 80, right: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60, left: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.primary.withOpacity(0.15),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: size.height * 0.12),

                      // Logo
                      Center(
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color:        _C.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _C.white.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.directions_car_filled_rounded,
                            color: _C.white,
                            size:  42,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // App name
                      const Center(
                        child: Text(
                          'CarPool',
                          style: TextStyle(
                            color:        _C.white,
                            fontSize:     38,
                            fontWeight:   FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Your Trip. Our Driver.',
                          style: TextStyle(
                            color:    _C.white.withOpacity(0.55),
                            fontSize: 15,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Feature pills
                      _FeaturePill(
                        icon:  Icons.savings_outlined,
                        label: 'Save money on daily commute',
                      ),
                      const SizedBox(height: 10),
                      _FeaturePill(
                        icon:  Icons.verified_user_outlined,
                        label: 'Verified captains, safe rides',
                      ),
                      const SizedBox(height: 10),
                      _FeaturePill(
                        icon:  Icons.handshake_outlined,
                        label: 'Negotiate your own fare',
                      ),

                      const SizedBox(height: 40),

                      // Google Sign In Button
                      GestureDetector(
                        onTap: _isLoading ? null : _signInWithGoogle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height:   56,
                          decoration: BoxDecoration(
                            color:        _isLoading
                                ? _C.white.withOpacity(0.7)
                                : _C.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:      _C.dark.withOpacity(0.3),
                                blurRadius: 20,
                                offset:     const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(
                                      color:       _C.primary,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    // Google G icon
                                    Container(
                                      width: 24, height: 24,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: const _GoogleIcon(),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        color:      _C.textDark,
                                        fontSize:   16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Terms note
                      Center(
                        child: Text(
                          'By continuing, you agree to our Terms & Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:    _C.white.withOpacity(0.4),
                            fontSize: 12,
                            height:   1.5,
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.06),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Google G icon drawn manually — no image asset needed
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GooglePainter(),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // Blue
    final blue = Paint()..color = const Color(0xFF4285F4);
    // Red
    final red  = Paint()..color = const Color(0xFFEA4335);
    // Yellow
    final yel  = Paint()..color = const Color(0xFFFBBC05);
    // Green
    final grn  = Paint()..color = const Color(0xFF34A853);

    // Draw simplified G
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -1.57, 3.14, false,
      blue..style = PaintingStyle.stroke
           ..strokeWidth = size.width * 0.18,
    );

    // Horizontal bar
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.09,
          r, size.height * 0.18),
      blue..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        _C.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _C.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: _C.light, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color:    _C.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}