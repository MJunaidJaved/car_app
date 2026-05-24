import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../services/ride_service.dart';
import '../../models/ride_model.dart';
import '../../utils/app_colors.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _selectedCategory = 0;
  List<RideModel> _nearbyRides = [];
  bool _loadingRides = true;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Daily Commute', 'icon': Icons.work_outline_rounded, 'type': 'office'},
    {'label': 'Intercity', 'icon': Icons.location_city_rounded, 'type': 'random'},
    {'label': 'University', 'icon': Icons.school_outlined, 'type': 'office'},
    {'label': 'Events', 'icon': Icons.event_outlined, 'type': 'random'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides({String? type}) async {
    setState(() => _loadingRides = true);
    try {
      final rides = await Provider.of<RideService>(context, listen: false)
          .findRides(type: type);
      if (mounted) {
        setState(() {
          _nearbyRides = rides.take(5).toList();
          _loadingRides = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRides = false);
    }
  }

  String _formatDeparture(DateTime? dt) {
    if (dt == null) return 'Soon';
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Departed';
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes} mins';
    if (diff.inHours < 24) return 'In ${diff.inHours} hrs';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

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
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 240,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.dark, AppColors.moss],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadRides(
                      type: _categories[_selectedCategory]['type'] as String?,
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                          color: AppColors.white.withOpacity(0.7),
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        user?.name ?? 'Passenger',
                                        style: const TextStyle(
                                          color: AppColors.white,
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
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(Icons.notifications_outlined,
                                        color: AppColors.white, size: 22),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/profile'),
                                  child: CircleAvatar(
                                    radius: 21,
                                    backgroundColor: AppColors.white.withOpacity(0.2),
                                    backgroundImage:
                                        hasPhoto ? NetworkImage(p as String) : null,
                                    child: !hasPhoto
                                        ? Text(
                                            (user?.name ?? 'P')[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.dark.withOpacity(0.06),
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
                                      color: AppColors.textDark,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/find-ride'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: AppColors.sage.withOpacity(0.3)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.search_rounded,
                                              color: AppColors.primary, size: 24),
                                          SizedBox(width: 12),
                                          Text(
                                            'Where are you going?',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: _categories.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final cat = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        right: i == _categories.length - 1 ? 0 : 12),
                                    child: _CategoryTab(
                                      label: cat['label'],
                                      icon: cat['icon'],
                                      isSelected: _selectedCategory == i,
                                      onTap: () {
                                        setState(() => _selectedCategory = i);
                                        _loadRides(type: cat['type'] as String?);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Available Rides Near You',
                                  style: TextStyle(
                                    color: AppColors.dark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/find-ride'),
                                  child: const Text(
                                    'See all',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_loadingRides)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_nearbyRides.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'No rides available right now. Try Find a Ride to search.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            )
                          else
                            ..._nearbyRides.map((ride) => GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/fare-negotiate',
                                    arguments: ride,
                                  ),
                                  child: _LiveRideCard(
                                    from: ride.startLocation,
                                    to: ride.endLocation,
                                    time: _formatDeparture(ride.departureTime),
                                    price: 'Rs ${ride.suggestedFare.toStringAsFixed(0)}',
                                    seatsLeft: ride.availableSeats,
                                    captainName: ride.captainName,
                                  ),
                                )),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 76,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(color: AppColors.sage.withOpacity(0.3)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? AppColors.white : AppColors.textMuted,
                size: 24),
            const SizedBox(height: 6),
            Text(
              label.split(' ')[0],
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sage.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from → $to',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(time,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline_rounded,
                        color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text('$seatsLeft seat${seatsLeft > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
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
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  captainName,
                  style: const TextStyle(
                    color: AppColors.dark,
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
        case 1:
          Navigator.pushNamed(context, '/tours');
          break;
        case 2:
          Navigator.pushNamed(context, '/my-bookings');
          break;
        case 3:
          Navigator.pushNamed(context, '/wallet');
          break;
        case 4:
          Navigator.pushNamed(context, '/profile');
          break;
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
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.sage.withOpacity(0.2))),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, -6),
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
              onTap: () => onNavTap(0)),
          _NavItem(
              icon: Icons.map_outlined,
              label: 'Tours',
              active: false,
              onTap: () => onNavTap(1)),
          _NavItem(
              icon: Icons.calendar_today_outlined,
              label: 'Bookings',
              active: false,
              onTap: () => onNavTap(2)),
          _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              active: false,
              onTap: () => onNavTap(3)),
          _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              active: false,
              onTap: () => onNavTap(4)),
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

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

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
            Icon(icon,
                color: active ? AppColors.primary : AppColors.textMuted,
                size: 26),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ] else
              const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}
