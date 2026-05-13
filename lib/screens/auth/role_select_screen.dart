import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/session_storage.dart';
import '../../providers/user_provider.dart';
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

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});
  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;
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
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (_selected == null || _isBusy) return;

    if (_selected == 'captain') {
      setState(() => _isBusy = true);
      try {
        final userProvider =
            Provider.of<UserProvider>(context, listen: false);
        await SessionStorage.setRole('captain');
        if (!mounted) return;
        final model = await SessionStorage.loadUserModel();
        if (model != null) userProvider.setUser(model);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/captain-register');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
      return;
    }

    setState(() => _isBusy = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final userProvider =
          Provider.of<UserProvider>(context, listen: false);
      final model = await auth.savePassengerRoleAndProfile();
      if (!mounted) return;
      userProvider.setUser(model);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
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
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Full teal top half
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: size.height * 0.45,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, _C.primary],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),

          Positioned(
            top: -50, left: -50,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.white.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Header text on teal
                    const Text(
                      'How will you\nuse CarPool?',
                      style: TextStyle(
                        color:       _C.white,
                        fontSize:    30,
                        fontWeight:  FontWeight.w800,
                        letterSpacing: -0.5,
                        height:      1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your role to get started',
                      style: TextStyle(
                        color:    _C.white.withOpacity(0.7),
                        fontSize: 15,
                      ),
                    ),

                    SizedBox(height: size.height * 0.06),

                    // Passenger Card
                    _RoleCard(
                      title:       'Passenger',
                      subtitle:    'Find rides, save money,\ntravel comfortably',
                      icon:        Icons.person_rounded,
                      isSelected:  _selected == 'passenger',
                      onTap: () => setState(() => _selected = 'passenger'),
                    ),
                    const SizedBox(height: 16),

                    // Captain Card
                    _RoleCard(
                      title:       'Captain',
                      subtitle:    'Post rides, earn money,\nfill your empty seats',
                      icon:        Icons.directions_car_filled_rounded,
                      isSelected:  _selected == 'captain',
                      onTap: () => setState(() => _selected = 'captain'),
                    ),

                    const Spacer(),

                    // CTA
                    AnimatedOpacity(
                      opacity:  _selected != null ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 250),
                      child: TealButton(
                        label:     'Continue as ${_selected == null ? '...' : _selected![0].toUpperCase() + _selected!.substring(1)}',
                        isLoading: _isBusy,
                        onTap:     _proceed,
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
        curve:    Curves.easeInOut,
        padding:  const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        isSelected ? _C.primary : _C.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? _C.primary : _C.light,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:      isSelected
                  ? _C.primary.withOpacity(0.3)
                  : _C.dark.withOpacity(0.07),
              blurRadius: 20,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color:        isSelected
                    ? _C.white.withOpacity(0.2)
                    : _C.light.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? _C.white : _C.primary,
                size:  28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:      isSelected ? _C.white : _C.textDark,
                      fontSize:   18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:    isSelected
                          ? _C.white.withOpacity(0.8)
                          : _C.textMuted,
                      fontSize: 13,
                      height:   1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? _C.white : _C.light,
              size:  24,
            ),
          ],
        ),
      ),
    );
  }
}