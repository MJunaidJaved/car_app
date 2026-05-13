import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';

class _C {
  static const primary   = Color(0xFF39988E);
  static const dark      = Color(0xFF1F6059);
  static const light     = Color(0xFFB6D7D1);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF0D1F1E);
  static const textMuted = Color(0xFF7A9E9B);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, _C.primary],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                        const SizedBox(width: 14),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            color: _C.white, fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _C.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: _C.white, size: 18,
                            ),
                            onPressed: () => Navigator.pushNamed(
                                context, '/wallet'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Avatar + name
                  Center(
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final p = user?.photoUrl;
                            final hasP =
                                p != null && p.isNotEmpty;
                            return Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor:
                                      _C.white.withOpacity(0.2),
                                  backgroundImage: hasP
                                      ? NetworkImage(p)
                                      : null,
                                  child: !hasP
                                      ? Text(
                                          (user?.name ?? 'U')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: _C.white,
                                            fontSize: 36,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      color:        const Color(0xFF4CAF50),
                                      shape:        BoxShape.circle,
                                      border: Border.all(
                                          color: _C.dark, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            color:      _C.white,
                            fontSize:   20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color:    _C.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Trust Score Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color:        _C.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color:      _C.dark.withOpacity(0.08),
                            blurRadius: 16,
                            offset:     const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TrustStat(
                              value: '4.9',
                              label: 'Trust Score',
                              icon:  Icons.verified_rounded,
                            ),
                          ),
                          Container(
                            width: 1, height: 40,
                            color: const Color(0xFFF0F0F0),
                          ),
                          Expanded(
                            child: _TrustStat(
                              value: '42',
                              label: 'Rides',
                              icon:  Icons.directions_car_filled_rounded,
                            ),
                          ),
                          Container(
                            width: 1, height: 40,
                            color: const Color(0xFFF0F0F0),
                          ),
                          Expanded(
                            child: _TrustStat(
                              value: '98%',
                              label: 'On-time',
                              icon:  Icons.timer_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Menu Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color:        _C.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color:      _C.dark.withOpacity(0.07),
                            blurRadius: 12,
                            offset:     const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _ProfileMenuItem(
                            icon:  Icons.person_outline_rounded,
                            label: 'Personal Info',
                            onTap: () {},
                          ),
                          _ProfileMenuItem(
                            icon:  Icons.notifications_outlined,
                            label: 'Notifications',
                            onTap: () => Navigator.pushNamed(
                                context, '/wallet'),
                          ),
                          _ProfileMenuItem(
                            icon:  Icons.shield_outlined,
                            label: 'Privacy & Safety',
                            onTap: () => Navigator.pushNamed(
                                context, '/earnings'),
                          ),
                          _ProfileMenuItem(
                            icon:  Icons.card_giftcard_rounded,
                            label: 'Referrals',
                            onTap: () => Navigator.pushNamed(
                                context, '/wallet'),
                          ),
                          _ProfileMenuItem(
                            icon:  Icons.help_outline_rounded,
                            label: 'Help & Support',
                            onTap: () => Navigator.pushNamed(
                                context, '/find-ride'),
                          ),
                          _ProfileMenuItem(
                            icon:  Icons.logout_rounded,
                            label: 'Sign Out',
                            isDestructive: true,
                            onTap: () async {
                              final authService = Provider.of<AuthService>(
                                  context, listen: false);
                              final userProvider =
                                  Provider.of<UserProvider>(context,
                                      listen: false);
                              await authService.signOut();
                              userProvider.clear();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/',
                                  (_) => false,
                                );
                              }
                            },
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _TrustStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: _C.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color:      _C.textDark,
            fontSize:   18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: _C.textMuted, fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showDivider;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.showDivider   = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap:   onTap,
          leading: Icon(
            icon,
            color: isDestructive ? Colors.red : _C.primary,
            size:  22,
          ),
          title: Text(
            label,
            style: TextStyle(
              color:      isDestructive ? Colors.red : _C.textDark,
              fontSize:   14,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: isDestructive
              ? null
              : const Icon(
                  Icons.chevron_right_rounded,
                  color: _C.textMuted,
                ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 2),
        ),
        if (showDivider)
          const Divider(
            color:   Color(0xFFF5F5F5),
            height:  1,
            indent:  56,
          ),
      ],
    );
  }
}