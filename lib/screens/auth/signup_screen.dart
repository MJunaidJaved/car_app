import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_widgets.dart';

class _C {
  static const primary   = Color(0xFF39988E);
  static const dark      = Color(0xFF1F6059);
  static const light     = Color(0xFFB6D7D1);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF0D1F1E);
  static const textMuted = Color(0xFF7A9E9B);
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _isLoading      = false;
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService  = Provider.of<AuthService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await authService.signUp(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name:     _nameCtrl.text.trim(),
        phone:    _phoneCtrl.text.trim(),
        role:     'customer',
      );
      final userData =
          await authService.getUserData(authService.currentUser!.uid);
      if (userData != null) {
        userProvider.setUser(userData);
        if (mounted) Navigator.pushReplacementNamed(context, '/role-select');
      }
    } catch (e) {
      if (mounted)
        AppHelpers.showSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Teal header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: size.height * 0.32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, _C.primary],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          // Decorative circles
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
                      const SizedBox(height: 20),

                      // Back + Title on teal
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: _C.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: _C.white, size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: _C.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Join CarPool today',
                                  style: TextStyle(
                                    color: _C.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: size.height * 0.04),

                      // White form card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _C.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color:      _C.dark.withOpacity(0.12),
                                blurRadius: 24,
                                offset:     const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TealField(
                                  controller: _nameCtrl,
                                  label: 'Full Name',
                                  icon:  Icons.person_outline_rounded,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Enter your name' : null,
                                ),
                                const SizedBox(height: 14),
                                TealField(
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
                                const SizedBox(height: 14),
                                TealField(
                                  controller:  _phoneCtrl,
                                  label:       'Phone number',
                                  icon:        Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Enter your phone number';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TealField(
                                  controller:  _passwordCtrl,
                                  label:       'Password',
                                  icon:        Icons.lock_outline_rounded,
                                  obscureText: _obscurePass,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _C.textMuted, size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Enter a password';
                                    if (v.length < 6)
                                      return 'Minimum 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TealField(
                                  controller:  _confirmCtrl,
                                  label:       'Confirm Password',
                                  icon:        Icons.lock_outline_rounded,
                                  obscureText: _obscureConfirm,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _C.textMuted, size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureConfirm = !_obscureConfirm),
                                  ),
                                  validator: (v) {
                                    if (v != _passwordCtrl.text)
                                      return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                TealButton(
                                  label:     'Create Account',
                                  isLoading: _isLoading,
                                  onTap:     _signUp,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Already have an account?  ',
                                        style: TextStyle(
                                            color: _C.textMuted, fontSize: 14)),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Text('Sign In',
                                          style: TextStyle(
                                            color:      _C.primary,
                                            fontSize:   14,
                                            fontWeight: FontWeight.w700,
                                          )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'By signing up, you agree to our Terms of Service\nand Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _C.textMuted, fontSize: 12, height: 1.5),
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