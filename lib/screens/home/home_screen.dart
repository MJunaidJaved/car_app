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
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final userProvider = Provider.of<UserProvider>(context);
    final user         = userProvider.user;
    final isCaptain    = user?.role == 'captain';

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Teal header
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
                  // ── Top bar ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning,',
                                style: TextStyle(
                                  color:    _C.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                user?.name ?? 'User',
                                style: const TextStyle(
                                  color:      _C.white,
                                  fontSize:   20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification bell
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color:        _C.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: _C.white, size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Avatar
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: _C.white.withOpacity(0.2),
                          child: Text(
                            (user?.name ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color:      _C.white,
                              fontWeight: FontWeight.w700,
                              fontSize:   16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Map Preview Card ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: _C.light.withOpacity(0.5),
                        boxShadow: [
                          BoxShadow(
                            color:      _C.dark.withOpacity(0.15),
                            blurRadius: 20,
                            offset:     const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // Map placeholder — replace with GoogleMap widget
                            Container(
                              color: const Color(0xFFE8F4F3),
                              child: Center(
                                child: Icon(
                                  Icons.map_outlined,
                                  color: _C.primary.withOpacity(0.3),
                                  size:  64,
                                ),
                              ),
                            ),
                            // Live indicator
                            Positioned(
                              top: 12, left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:        _C.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:      _C.dark.withOpacity(0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7, height: 7,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color:      _C.textDark,
                                        fontSize:   11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Open map button
                            Positioned(
                              bottom: 12, right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color:        _C.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Open Map',
                                  style: TextStyle(
                                    color:      _C.white,
                                    fontSize:   12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Quick Actions ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: isCaptain
                        ? _CaptainQuickActions()
                        : _PassengerQuickActions(),
                  ),

                  const SizedBox(height: 20),

                  // ── Stats Row ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Rides',
                            value: '24',
                            icon:  Icons.directions_car_filled_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: isCaptain ? 'Earned' : 'Saved',
                            value: 'Rs 1,240',
                            icon:  Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Trust Score',
                            value: '4.8',
                            icon:  Icons.verified_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Recent Rides ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Rides',
                          style: TextStyle(
                            color:      _C.textDark,
                            fontSize:   17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'See all',
                          style: TextStyle(
                            color:    _C.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _RecentRideCard(
                    from:   'Gulberg, Lahore',
                    to:     'DHA Phase 5',
                    date:   'Today, 8:00 AM',
                    price:  'Rs 120',
                    status: 'Completed',
                  ),
                  _RecentRideCard(
                    from:   'Johar Town',
                    to:     'Model Town',
                    date:   'Yesterday, 9:15 AM',
                    price:  'Rs 90',
                    status: 'Completed',
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── Bottom Nav ───────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomNav(isCaptain: isCaptain),
          ),
        ],
      ),
    );
  }
}

class _PassengerQuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            label: 'Find Ride',
            icon:  Icons.search_rounded,
            onTap: () => Navigator.pushNamed(context, '/find-ride'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            label: 'My Bookings',
            icon:  Icons.bookmark_outline_rounded,
            onTap: () => Navigator.pushNamed(context, '/my-bookings'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            label: 'Wallet',
            icon:  Icons.account_balance_wallet_outlined,
            onTap: () => Navigator.pushNamed(context, '/wallet'),
          ),
        ),
      ],
    );
  }
}

class _CaptainQuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            label: 'Post Ride',
            icon:  Icons.add_circle_outline_rounded,
            onTap: () => Navigator.pushNamed(context, '/post-ride'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            label: 'My Rides',
            icon:  Icons.list_alt_rounded,
            onTap: () => Navigator.pushNamed(context, '/my-rides'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            label: 'Earnings',
            icon:  Icons.bar_chart_rounded,
            onTap: () => Navigator.pushNamed(context, '/earnings'),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:        _C.white,
          borderRadius: BorderRadius.circular(18),
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
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color:        _C.light.withOpacity(0.4),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: _C.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color:      _C.textDark,
                fontSize:   12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      _C.dark.withOpacity(0.07),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _C.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color:      _C.textDark,
              fontSize:   15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color:    _C.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRideCard extends StatelessWidget {
  final String from;
  final String to;
  final String date;
  final String price;
  final String status;

  const _RecentRideCard({
    required this.from,
    required this.to,
    required this.date,
    required this.price,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      _C.dark.withOpacity(0.07),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color:        _C.light.withOpacity(0.4),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: _C.primary, size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from → $to',
                  style: const TextStyle(
                    color:      _C.textDark,
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: const TextStyle(
                    color: _C.textMuted, fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color:      _C.primary,
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        _C.light.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color:    _C.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final bool isCaptain;
  const _BottomNav({required this.isCaptain});

  String _routeForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return isCaptain ? '/post-ride' : '/find-ride';
      case 2:
        return isCaptain ? '/my-rides' : '/my-bookings';
      case 3:
        return '/wallet';
      case 4:
        return '/profile';
      default:
        return '/home';
    }
  }

  @override
  Widget build(BuildContext context) {
    const activeIndex = 0;

    void onNavTap(int index) {
      final route = _routeForIndex(index);
      if (index == activeIndex) return;
      Navigator.pushNamed(context, route);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: _C.white,
        boxShadow: [
          BoxShadow(
            color:      _C.dark.withOpacity(0.08),
            blurRadius: 20,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: true,
            onTap: () => onNavTap(0),
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            label: isCaptain ? 'Post' : 'Find',
            active: false,
            onTap: () => onNavTap(1),
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Rides',
            active: false,
            onTap: () => onNavTap(2),
          ),
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            active: false,
            onTap: () => onNavTap(3),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            active: false,
            onTap: () => onNavTap(4),
          ),
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

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
              color:      active ? _C.primary : _C.textMuted,
              fontSize:   10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (active) ...[
            const SizedBox(height: 4),
            Container(
              width: 4, height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _C.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}