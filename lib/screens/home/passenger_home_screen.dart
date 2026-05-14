import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class _C {
  static const primary   = Color(0xFF414833); // Primary Action
  static const dark      = Color(0xFF414833); // Header/Black
  static const accent    = Color(0xFF737A5D); // Accent
  static const black     = Color(0xFF414833);
  static const white     = Color(0xFFF5E3D2);
  static const textDark  = Color(0xFF414833);
  static const textMuted = Color(0xFF737A5D);
  static const bg        = Color(0xFFF5E3D2);
}

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final p = user?.photoUrl;
    final hasPhoto = p != null && p.isNotEmpty;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Background Gradient for header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 240,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, Color(0xFF414833)], // Darker shades for depth
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
            child: Column(
              children: [
                Expanded(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Where to next,',
                                      style: TextStyle(
                                        color: _C.white.withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      user?.name ?? 'Passenger',
                                      style: const TextStyle(
                                        color: _C.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/notifications'),
                                child: Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: _C.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(Icons.notifications_outlined, color: _C.white, size: 22),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/profile'),
                                child: CircleAvatar(
                                  radius: 21,
                                  backgroundColor: _C.white.withOpacity(0.2),
                                  backgroundImage: hasPhoto ? NetworkImage(p as String) : null,
                                  child: !hasPhoto
                                      ? Text(
                                          (user?.name ?? 'P')[0].toUpperCase(),
                                          style: const TextStyle(color: _C.white, fontWeight: FontWeight.w700, fontSize: 16),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Search Hero Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _C.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Find a ride',
                                  style: TextStyle(
                                    color: _C.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/find-ride'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _C.bg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.search_rounded, color: _C.primary, size: 24),
                                        SizedBox(width: 12),
                                        Text(
                                          'Where are you going?',
                                          style: TextStyle(
                                            color: _C.textMuted,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Category Tabs Redesign
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _CategoryTab(label: 'Daily Commute', icon: Icons.work_outline_rounded, isSelected: true),
                                const SizedBox(width: 12),
                                _CategoryTab(label: 'Intercity', icon: Icons.location_city_rounded, isSelected: false),
                                const SizedBox(width: 12),
                                _CategoryTab(label: 'University', icon: Icons.school_outlined, isSelected: false),
                                const SizedBox(width: 12),
                                _CategoryTab(label: 'Events', icon: Icons.event_outlined, isSelected: false),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Live Ride Feed
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Available Rides Near You',
                                style: TextStyle(
                                  color: _C.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/find-ride'),
                                child: const Text(
                                  'See all',
                                  style: TextStyle(
                                    color: _C.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        const _LiveRideCard(
                          from: 'Gulberg, Lahore',
                          to: 'DHA Phase 5',
                          time: 'In 15 mins',
                          price: 'Rs 150',
                          seatsLeft: 2,
                          captainName: 'Ahmed A.',
                        ),
                        const _LiveRideCard(
                          from: 'Johar Town',
                          to: 'Model Town',
                          time: 'In 45 mins',
                          price: 'Rs 120',
                          seatsLeft: 1,
                          captainName: 'Bilal M.',
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Nav
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _PassengerBottomNav(),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, height: 76,
      decoration: BoxDecoration(
        color: isSelected ? _C.primary : _C.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? null : Border.all(color: const Color(0xFFCCBFA3), width: 1),
        boxShadow: isSelected ? [
          BoxShadow(
            color: _C.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? _C.white : _C.textMuted, size: 24),
          const SizedBox(height: 6),
          Text(
            label.split(' ')[0], // Short label
            style: TextStyle(
              color: isSelected ? _C.white : _C.textDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRideCard extends StatelessWidget {
  final String from;
  final String to;
  final String time;
  final String price;
  final int seatsLeft;
  final String captainName;

  const _LiveRideCard({
    required this.from,
    required this.to,
    required this.time,
    required this.price,
    required this.seatsLeft,
    required this.captainName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car_rounded, color: _C.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from → $to',
                  style: const TextStyle(
                    color: _C.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: _C.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(time, style: const TextStyle(color: _C.textMuted, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline_rounded, color: _C.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text('$seatsLeft seat${seatsLeft > 1 ? 's' : ''}', style: const TextStyle(color: _C.textMuted, fontSize: 12)),
                  ],
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
                  color: _C.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  captainName,
                  style: const TextStyle(
                    color: _C.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

class _PassengerBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const activeIndex = 0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    void onNavTap(int index) {
      if (index == activeIndex) return;
      switch (index) {
        case 1: Navigator.pushNamed(context, '/find-ride'); break;
        case 2: Navigator.pushNamed(context, '/tours'); break;
        case 3: Navigator.pushNamed(context, '/wallet'); break;
        case 4: Navigator.pushNamed(context, '/profile'); break;
      }
    }

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: bottomPadding > 0 ? bottomPadding : 16,
      ),
      decoration: BoxDecoration(
        color: _C.white,
        border: const Border(top: BorderSide(color: Color(0xFFCCBFA3), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Home', active: true, onTap: () => onNavTap(0)),
          _NavItem(icon: Icons.search_rounded, label: 'Explore', active: false, onTap: () => onNavTap(1)),
          _NavItem(icon: Icons.map_outlined, label: 'Tours', active: false, onTap: () => onNavTap(2)),
          _NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', active: false, onTap: () => onNavTap(3)),
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
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? _C.primary : _C.textMuted, size: 26),
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
              Container(
                width: 20, height: 3,
                decoration: BoxDecoration(
                  color: _C.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ] else const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}



