import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/helpers.dart';

// ─── Brand Colors ────────────────────────────────────────────────────────────
class _C {
  static const primary    = Color(0xFF39988E); // Mediterranean Green
  static const dark       = Color(0xFF1F6059); // Dark Teal
  static const light      = Color(0xFFB6D7D1); // Jet Stream Blue
  static const bg         = Color(0xFFF5F5F5); // Off white
  static const white      = Color(0xFFFFFFFF);
  static const textDark   = Color(0xFF0D1F1E);
  static const textMuted  = Color(0xFF7A9E9B);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  bool _isLoading       = false;
  bool _obscurePassword = true;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService  = Provider.of<AuthService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await authService.signIn(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final userData =
      await authService.getUserData(authService.currentUser!.uid);
      if (userData != null) {
        userProvider.setUser(userData);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Status bar icons white on teal header
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:            Colors.transparent,
      statusBarIconBrightness:   Brightness.light,
    ));

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ── Teal header blob ────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: size.height * 0.42,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, _C.primary],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          // ── Decorative circles ───────────────────────────────────────────
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 60, right: 20,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.white.withOpacity(0.08),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Logo area (on teal) ────────────────────────────
                      SizedBox(height: size.height * 0.06),
                      _LogoSection(),

                      SizedBox(height: size.height * 0.05),

                      // ── White card ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color:        _C.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color:       _C.dark.withOpacity(0.12),
                                blurRadius:  24,
                                offset:      const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize:   24,
                                    fontWeight: FontWeight.w700,
                                    color:      _C.textDark,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sign in to continue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:    _C.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Email
                                _TealField(
                                  controller:  _emailCtrl,
                                  label:       'Email address',
                                  icon:        Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Enter your email';
                                    if (!AppHelpers.isValidEmail(v))
                                      return 'Enter a valid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                _TealField(
                                  controller:   _passwordCtrl,
                                  label:        'Password',
                                  icon:         Icons.lock_outline_rounded,
                                  obscureText:  _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _C.textMuted,
                                      size:  20,
                                    ),
                                    onPressed: () => setState(
                                            () => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Enter your password';
                                    if (v.length < 6)
                                      return 'Minimum 6 characters';
                                    return null;
                                  },
                                ),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                    ),
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color:    _C.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Sign In button
                                _TealButton(
                                  label:     'Sign In',
                                  isLoading: _isLoading,
                                  onTap:     _signIn,
                                ),

                                const SizedBox(height: 20),

                                // Divider
                                Row(children: [
                                  Expanded(child: Divider(color: _C.light)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                          color: _C.textMuted, fontSize: 13),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: _C.light)),
                                ]),

                                const SizedBox(height: 20),

                                // Sign up link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account?  ",
                                      style: TextStyle(
                                          color: _C.textMuted, fontSize: 14),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                          context, '/signup'),
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color:      _C.primary,
                                          fontSize:   14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Terms
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'By signing in, you agree to our Terms of Service\nand Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:    _C.textMuted,
                            fontSize: 12,
                            height:   1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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

// ─── Logo Section ─────────────────────────────────────────────────────────────
class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon badge
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color:        _C.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _C.white.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: _C.white,
            size:  38,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'CarPool',
          style: TextStyle(
            color:       _C.white,
            fontSize:    32,
            fontWeight:  FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your Trip. Our Driver.',
          style: TextStyle(
            color:    _C.white.withOpacity(0.75),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Reusable Teal Input Field ────────────────────────────────────────────────
class _TealField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _TealField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText  = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscureText,
      keyboardType: keyboardType,
      validator:    validator,
      style: const TextStyle(
        color:      _C.textDark,
        fontSize:   15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText:    label,
        labelStyle:   TextStyle(color: _C.textMuted, fontSize: 14),
        prefixIcon:   Icon(icon, color: _C.primary, size: 20),
        suffixIcon:   suffixIcon,
        filled:       true,
        fillColor:    const Color(0xFFF0F7F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: _C.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ─── Reusable Teal CTA Button ─────────────────────────────────────────────────
class _TealButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _TealButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primary,
          foregroundColor: _C.white,
          disabledBackgroundColor: _C.light,
          elevation:   0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(
            color:       _C.white,
            strokeWidth: 2.5,
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            fontSize:    16,
            fontWeight:  FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}