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
      final hasVehicle = userData['vehicleMake'] != null &&
          userData['vehicleMake'].toString().trim().isNotEmpty;

      if (status == 'pending_verification') {
        Navigator.pushReplacementNamed(context, '/verification-pending');
      } else if (status == 'verified' || isVerified) {
        Navigator.pushReplacementNamed(context, '/captain-home');
      } else if (hasVehicle) {
        Navigator.pushReplacementNamed(context, '/captain-home');
      } else {
        Navigator.pushReplacementNamed(context, '/captain-register');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _proceed() async {
    if (_selected == null || _isBusy) return;
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
              height: size.height * 0.45,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.dark, AppColors.moss],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        const Text(
                          'How will you\nuse CarPool?',
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
                            color: AppColors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: size.height * 0.06),
                        _RoleCard(
                          title: 'Passenger',
                          subtitle:
                              'Find rides, save money,\ntravel comfortably',
                          icon: Icons.person_rounded,
                          isSelected: _selected == 'passenger',
                          onTap: () => setState(() => _selected = 'passenger'),
                        ),
                        const SizedBox(height: 16),
                        _RoleCard(
                          title: 'Captain',
                          subtitle:
                              'Post rides, earn money,\nfill your empty seats',
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.dark : AppColors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.light,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.black.withOpacity(0.1)
                  : Colors.black.withOpacity(0.02),
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
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
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
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white.withOpacity(0.7)
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
    );
  }
}
