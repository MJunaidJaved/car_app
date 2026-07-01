import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/session_storage.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;
  String? _gender;
  String? _existingRole;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillProfile());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _prefillProfile() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final role = (user?.role ?? '').trim().toLowerCase();
    final gender = (user?.gender ?? '').trim().toLowerCase();
    if (!mounted) return;
    setState(() {
      if (role == 'captain' || role == 'passenger' || role == 'customer') {
        _existingRole = role == 'customer' ? 'passenger' : role;
      }
      if (gender == 'male' || gender == 'female') {
        _gender = gender;
      }
    });
  }

  void _navigateForRole(Map<String, dynamic> userData, String role) {
    if (role == 'captain') {
      final status = (userData['captainVerificationStatus'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final isVerified = userData['isVerified'] == true;
      bool hasText(String key) =>
          (userData[key] ?? '').toString().trim().isNotEmpty;
      final profileComplete = hasText('vehicleMake') &&
          hasText('vehicleModel') &&
          hasText('vehicleColor') &&
          hasText('vehicleRegistration') &&
          hasText('vehiclePhotoUrl') &&
          hasText('captainVehicleType') &&
          hasText('city');

      if (!profileComplete) {
        Navigator.pushReplacementNamed(context, '/captain-register');
      } else if (status == 'pending_verification') {
        Navigator.pushReplacementNamed(context, '/verification-pending');
      } else if (status == 'verified' || isVerified) {
        Navigator.pushReplacementNamed(context, '/captain-home');
      } else {
        Navigator.pushReplacementNamed(context, '/captain-register');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _proceed() async {
    if (_isBusy) return;
    if (_selected == null) return;
    if (_gender == null) {
      AppHelpers.showSnackBar(context, 'Please select gender', isError: true);
      return;
    }

    setState(() => _isBusy = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final selectedRole = _selected!;
      final genderToSave = _gender!;

      final syncResponse = await ApiService.post('/auth/sync', {
        'role': selectedRole,
        'gender': genderToSave,
      });
      await SessionStorage.setRole(selectedRole);

      // Force token refresh and fetch the saved backend profile before routing.
      await firebaseUser.getIdToken(true);
      final userData = Map<String, dynamic>.from(syncResponse['user'] ?? {});

      if (userProvider.user != null) {
        final updatedUser = userProvider.user?.copyWith(
          role: selectedRole,
          gender: genderToSave,
        );
        userProvider.setUser(updatedUser!);
      }

      if (mounted) {
        _navigateForRole(userData, selectedRole);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final size = MediaQuery.of(context).size;
    final headerHeight = math.min(size.height * 0.45, 280.0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: headerHeight,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        const Text(
                          'How will you\nuse ShareWay?',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _existingRole == null
                              ? 'Choose your role to get started'
                              : 'Choose role for this login',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha:0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _RoleCard(
                          title: 'Passenger',
                          subtitle:
                              'Find rides, save money, and travel comfortably',
                          icon: Icons.person_rounded,
                          isSelected: _selected == 'passenger',
                          onTap: () => setState(() => _selected = 'passenger'),
                        ),
                        const SizedBox(height: 16),
                        _RoleCard(
                          title: 'Captain',
                          subtitle:
                              'Post rides, earn money, and fill your empty seats',
                          icon: Icons.directions_car_filled_rounded,
                          isSelected: _selected == 'captain',
                          onTap: () => setState(() => _selected = 'captain'),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.light,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select gender',
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Used for ladies rides and safe ride matching',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _GenderCard(
                                      label: 'Male',
                                      icon: Icons.man_rounded,
                                      isSelected: _gender == 'male',
                                      onTap: () =>
                                          setState(() => _gender = 'male'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _GenderCard(
                                      label: 'Female',
                                      icon: Icons.woman_rounded,
                                      isSelected: _gender == 'female',
                                      onTap: () =>
                                          setState(() => _gender = 'female'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 24),
                        AnimatedOpacity(
                          opacity:
                              _selected != null && _gender != null ? 1.0 : 0.4,
                          duration: const Duration(milliseconds: 250),
                          child: AppButton(
                            label:
                                'Continue as ${_selected == null ? '...' : _selected![0].toUpperCase() + _selected!.substring(1)}',
                            isLoading: _isBusy,
                            onTap: _proceed,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<bool>(isSelected),
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.dark : AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.light,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.dark.withValues(alpha:0.1)
                    : AppColors.dark.withValues(alpha:0.02),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha:0.2)
                      : AppColors.primary.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.dark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.white.withValues(alpha:0.7)
                            : AppColors.textMuted,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.light,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52, // Enforce minimum 52px height for accessibility tap target
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.dark : AppColors.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.light,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

