import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class _C {
  static const primary   = Color(0xFF39988E);
  static const dark      = Color(0xFF1F6059);
  static const light     = Color(0xFFB6D7D1);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF0D1F1E);
  static const textMuted = Color(0xFF7A9E9B);
  static const accent    = Color(0xFFE2F1EF);
}

class CaptainHomeScreen extends StatelessWidget {
  const CaptainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final p = user?.photoUrl;
    final hasPhoto = p != null && p.isNotEmpty;
    
    final pendingVerification = user?.captainVerificationStatus == 'pending_verification';

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: _C.light,
                            backgroundImage: hasPhoto ? NetworkImage(p as String) : null,
                            child: !hasPhoto
                                ? Text(
                                    (user?.name ?? 'C')[0].toUpperCase(),
                                    style: const TextStyle(color: _C.dark, fontWeight: FontWeight.w800, fontSize: 18),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Captain ${user?.name ?? ''}',
                                style: const TextStyle(
                                  color: _C.textDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star_rounded, color: Colors.amber[600], size: 14),
                                  const SizedBox(width: 4),
                                  const Text('4.9 Rating', style: TextStyle(color: _C.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/notifications'),
                          child: Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: _C.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _C.light.withOpacity(0.5)),
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: _C.dark, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (pendingVerification) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, color: Color(0xFFFF9800), size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Verification Pending',
                                    style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your documents are under review. You can accept requests soon.',
                                    style: TextStyle(color: _C.textDark.withOpacity(0.7), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Operations Dashboard
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DashboardCard(
                            title: 'Earnings Today',
                            value: 'Rs 3,450',
                            icon: Icons.account_balance_wallet_rounded,
                            onTap: () => Navigator.pushNamed(context, '/earnings'),
                            highlight: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                         Expanded(
                          child: _DashboardCard(
                            title: 'Requests',
                            value: '12 New',
                            icon: Icons.hail_rounded,
                            onTap: () => Navigator.pushNamed(context, '/requests'),
                            highlight: false,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Active Route Status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _C.dark,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: _C.dark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: _C.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                      child: const Text('NO ACTIVE ROUTE', style: TextStyle(color: _C.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Ready to drive?',
                                      style: TextStyle(color: _C.white, fontSize: 20, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Post a ride to start earning', style: TextStyle(color: _C.white.withOpacity(0.7), fontSize: 14)),
                                  ],
                                ),
                                Container(
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(
                                    color: _C.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _C.white.withOpacity(0.2), width: 4),
                                  ),
                                  child: const Icon(Icons.power_settings_new_rounded, color: _C.white, size: 28),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/post-ride'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _C.primary,
                                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                              ),
                              child: const Center(
                                child: Text('POST A RIDE NOW', style: TextStyle(color: _C.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Recent Activity
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(color: _C.textDark, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/my-rides'),
                          child: const Text('See all', style: TextStyle(color: _C.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _ActivityCard(title: 'Ride Completed', subtitle: 'Gulberg to DHA', time: '2 hours ago', amount: '+ Rs 450'),
                  _ActivityCard(title: 'Fare Negotiated', subtitle: 'Passenger agreed to Rs 300', time: '4 hours ago', amount: null),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Nav
          Positioned(bottom: 0, left: 0, right: 0, child: _CaptainBottomNav()),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? _C.white : _C.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: highlight ? _C.primary.withOpacity(0.3) : _C.light.withOpacity(0.5)),
          boxShadow: highlight ? [BoxShadow(color: _C.primary.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: highlight ? _C.primary.withOpacity(0.1) : _C.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: highlight ? _C.primary : _C.textDark, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(color: highlight ? _C.primary : _C.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: _C.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String? amount;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.time,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.light.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(amount != null ? Icons.check_circle_outline_rounded : Icons.handshake_outlined, color: _C.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _C.textDark, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: _C.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (amount != null) Text(amount!, style: const TextStyle(color: _C.primary, fontSize: 14, fontWeight: FontWeight.w800)),
              if (amount != null) const SizedBox(height: 4),
              Text(time, style: const TextStyle(color: _C.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaptainBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const activeIndex = 0;

    void onNavTap(int index) {
      if (index == activeIndex) return;
      switch (index) {
        case 1: Navigator.pushNamed(context, '/post-ride'); break;
        case 2: Navigator.pushNamed(context, '/requests'); break; // Requests
        case 3: Navigator.pushNamed(context, '/earnings'); break;
        case 4: Navigator.pushNamed(context, '/profile'); break;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: _C.white,
        boxShadow: [
          BoxShadow(color: _C.dark.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Home', active: true, onTap: () => onNavTap(0)),
          _NavItem(icon: Icons.add_circle_outline_rounded, label: 'Post', active: false, onTap: () => onNavTap(1)),
          _NavItem(icon: Icons.list_alt_rounded, label: 'Requests', active: false, onTap: () => onNavTap(2)),
          _NavItem(icon: Icons.bar_chart_rounded, label: 'Earnings', active: false, onTap: () => onNavTap(3)),
          _NavItem(icon: Icons.person_outline_rounded, label: 'Profile', active: false, onTap: () => onNavTap(4)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? _C.primary : _C.textMuted, size: 24),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: active ? _C.primary : _C.textMuted,
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          if (active) ...[
            const SizedBox(height: 4),
            Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: _C.primary)),
          ] else const SizedBox(height: 8),
        ],
      ),
    );
  }
}
