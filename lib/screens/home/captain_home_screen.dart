import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/captain_profile_utils.dart';

class CaptainHomeScreen extends StatefulWidget {
  const CaptainHomeScreen({super.key});

  @override
  State<CaptainHomeScreen> createState() => _CaptainHomeScreenState();
}

class _CaptainHomeScreenState extends State<CaptainHomeScreen> {
  bool _isOnline = true;
  Map<String, dynamic>? _activeRide;
  List<Map<String, dynamic>> _latestRides = [];
  Map<String, int> _pendingRequestsByRide = {};
  double _walletBalance = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(31.5204, 74.3587);
  bool _mapReady = false;

  bool _isDashboardRideActive(Map<String, dynamic> ride) {
    final status = (ride['status'] ?? '').toString().toLowerCase();
    if (status == 'active' || status == 'in_progress') return true;
    final dt = DateTime.tryParse((ride['departureTime'] ?? '').toString());
    if (dt == null) return true;
    return dt.isAfter(DateTime.now().subtract(const Duration(minutes: 5)));
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _initLocation();
  }

  Future<void> _loadDashboard() async {
    try {
      final ridesRes = await ApiService.get('/rides/my-rides');
      final rides = List<Map<String, dynamic>>.from(ridesRes['rides'] ?? []);
      final dashboardRides =
          rides.where((ride) => _isDashboardRideActive(ride)).toList();
      rides.sort((a, b) {
        final aAt = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
      Map<String, dynamic>? active;
      for (final r in dashboardRides) {
        if (r['status'] == 'active') {
          active = r;
          break;
        }
      }
      final walletRes = await ApiService.get('/wallet');
      final txRes = await ApiService.get('/wallet/transactions');
      final pendingMap = <String, int>{};
      for (final ride in dashboardRides.take(10)) {
        final rideId = (ride['id'] ?? '').toString();
        if (rideId.isEmpty) continue;
        try {
          final dealsRes = await ApiService.get('/deals/ride/$rideId');
          final deals = List<Map<String, dynamic>>.from(dealsRes['deals'] ?? []);
          pendingMap[rideId] = deals
              .where((d) => (d['status'] ?? '').toString().toLowerCase() == 'pending')
              .length;
        } catch (_) {
          pendingMap[rideId] = 0;
        }
      }
      if (mounted) {
        setState(() {
          _activeRide = active;
          _latestRides = dashboardRides.take(10).toList();
          _pendingRequestsByRide = pendingMap;
          _walletBalance = (walletRes['wallet']?['balance'] ?? 0).toDouble();
          _recentTransactions =
              List<Map<String, dynamic>>.from(txRes['transactions'] ?? [])
                  .take(3)
                  .toList();
        });
      }
    } catch (_) {}
  }

  String _formatTxTime(dynamic createdAt) {
    final dt = DateTime.tryParse(createdAt?.toString() ?? '');
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  void _tryOpenPostRide(BuildContext context, {Map<String, dynamic>? args}) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (!CaptainProfileUtils.isProfileComplete(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Complete your captain profile checklist before posting rides.'),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/post-ride', arguments: args);
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _mapReady = true;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentLocation),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _mapReady = true);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    final pendingVerification =
        user?.captainVerificationStatus == 'pending_verification';
    final profileItems = CaptainProfileUtils.checklist(user);
    final profileComplete = CaptainProfileUtils.isProfileComplete(user);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top bar - Avatar with initials only (no photo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.moss.withOpacity(0.1),
                            child: Text(
                              (user?.name ?? 'C')[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.bark,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
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
                                  color: AppColors.bark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: AppColors.moss, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    (user?.totalRides ?? 0) == 0
                                        ? 'New Captain'
                                        : '${(user?.rating ?? 0).toStringAsFixed(1)} Rating',
                                    style: const TextStyle(
                                        color: AppColors.sage,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/notifications'),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.sage.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.notifications_none_rounded,
                                color: AppColors.bark, size: 22),
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
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user_outlined,
                                color: Colors.orange, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Documents Under Review',
                                    style: TextStyle(
                                      color: AppColors.bark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Admin approval is required before you can post rides.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (!profileComplete) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.sage.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Complete your profile to post rides',
                              style: TextStyle(
                                color: AppColors.bark,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...profileItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.complete
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_outlined,
                                      size: 18,
                                      color: item.complete
                                          ? AppColors.success
                                          : Colors.redAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: item.complete
                                              ? AppColors.bark
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (user?.captainVerificationStatus == null ||
                                (user?.cnicFrontUrl?.isEmpty ?? true))
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/captain-register',
                                ),
                                child: const Text('Complete registration'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Live Map with Online/Offline overlay
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 200,
                        child: Stack(
                          children: [
                            // Google Map
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _currentLocation,
                                zoom: 14,
                              ),
                              onMapCreated: (controller) {
                                _mapController = controller;
                                if (_mapReady) {
                                  controller.animateCamera(
                                    CameraUpdate.newLatLng(_currentLocation),
                                  );
                                }
                              },
                              markers: {
                                Marker(
                                  markerId: const MarkerId('captain'),
                                  position: _currentLocation,
                                  infoWindow:
                                      const InfoWindow(title: 'Your Location'),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    _isOnline
                                        ? BitmapDescriptor.hueGreen
                                        : BitmapDescriptor.hueRed,
                                  ),
                                ),
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                            ),

                            // Online/Offline overlay at bottom of map
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.bark.withOpacity(0.92),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isOnline
                                              ? 'Waiting for requests...'
                                              : 'Go online to start earning',
                                          style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          _isOnline
                                              ? 'Visible to passengers'
                                              : 'Currently Offline',
                                          style: TextStyle(
                                              color: AppColors.white
                                                  .withOpacity(0.7),
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _isOnline = !_isOnline),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _isOnline
                                              ? AppColors.moss
                                              : AppColors.sage.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.white
                                                  .withOpacity(0.2),
                                              width: 2),
                                        ),
                                        child: const Icon(
                                            Icons.power_settings_new_rounded,
                                            color: AppColors.white,
                                            size: 20),
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
                  ),

                  const SizedBox(height: 24),

                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Wallet Balance',
                            value: 'Rs ${_walletBalance.toStringAsFixed(0)}',
                            icon: Icons.payments_rounded,
                            onTap: () =>
                                Navigator.pushNamed(context, '/wallet'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Active Ride',
                            value: _activeRide != null ? '1' : '0',
                            icon: Icons.inbox_rounded,
                            onTap: () {
                              if (_activeRide != null) {
                                Navigator.pushNamed(context, '/requests',
                                    arguments: _activeRide!['id']);
                              } else {
                                Navigator.pushNamed(context, '/my-rides');
                              }
                            },
                            isBadge: _activeRide != null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                          color: AppColors.bark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickActionCard(
                            label: 'Post a Ride',
                            icon: Icons.directions_car_rounded,
                            onTap: () => _tryOpenPostRide(context),
                          ),
                          const SizedBox(width: 16),
                          _QuickActionCard(
                            label: 'Create Tour',
                            icon: Icons.map_rounded,
                            onTap: () => _tryOpenPostRide(
                              context,
                              args: {'type': 'tour'},
                            ),
                          ),
                          const SizedBox(width: 16),
                          _QuickActionCard(
                            label: 'My Rides',
                            icon: Icons.list_alt_rounded,
                            onTap: () =>
                                Navigator.pushNamed(context, '/my-rides'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Recent Requests Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Requests',
                          style: TextStyle(
                              color: AppColors.bark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_activeRide != null) {
                              Navigator.pushNamed(context, '/requests',
                                  arguments: _activeRide!['id']);
                            } else {
                              Navigator.pushNamed(context, '/my-rides');
                            }
                          },
                          child: const Text('See all',
                              style: TextStyle(
                                  color: AppColors.moss,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_latestRides.isNotEmpty)
                    ..._latestRides.map((ride) {
                      final rideId = (ride['id'] ?? '').toString();
                      final start = (ride['startLocation'] ?? 'Unknown').toString();
                      final end = (ride['endLocation'] ?? 'Unknown').toString();
                      final fare = (ride['suggestedFare'] ?? 0).toString();
                      final status = (ride['status'] ?? '').toString();
                      final pendingCount = _pendingRequestsByRide[rideId] ?? 0;
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: GestureDetector(
                          onTap: () {
                            if (rideId.isEmpty) return;
                            Navigator.pushNamed(
                              context,
                              '/requests',
                              arguments: rideId,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.sage.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$start -> $end',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.bark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rs $fare',
                                      style: const TextStyle(
                                        color: AppColors.moss,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.bg,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.bark,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (pendingCount > 0) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'New requests: $pendingCount',
                                    style: const TextStyle(
                                      color: AppColors.moss,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Tap to open ride details and all customer requests',
                                        style: TextStyle(
                                          color: AppColors.sage,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton(
                                      onPressed: () {
                                        if (rideId.isEmpty) return;
                                        Navigator.pushNamed(
                                          context,
                                          '/requests',
                                          arguments: rideId,
                                        );
                                      },
                                      child: const Text('Details'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                          'No active rides. Post a ride to receive requests.',
                          style: TextStyle(color: AppColors.sage)),
                    ),
                  const SizedBox(height: 30),

                  // Recent Activity Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Recent Activity',
                      style: TextStyle(
                          color: AppColors.bark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_recentTransactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('No recent transactions yet.',
                          style: TextStyle(color: AppColors.sage)),
                    )
                  else
                    ..._recentTransactions
                        .where((tx) =>
                            (tx['type'] ?? '').toString().toLowerCase() !=
                            'commission')
                        .map((tx) {
                      final type = tx['type']?.toString() ?? '';
                      final amount = (tx['amount'] ?? 0).toDouble();
                      final isCredit = type.contains('earning') ||
                          type.contains('topup') ||
                          type == 'refund';
                      return _ActivityCard(
                        title: tx['description']?.toString() ?? type,
                        subtitle: type.replaceAll('_', ' '),
                        time: _formatTxTime(tx['createdAt']),
                        amount:
                            '${isCredit ? '+' : '-'} Rs ${amount.toStringAsFixed(0)}',
                      );
                    }),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // Bottom Nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _CaptainBottomNav(
              onPostRide: () => _tryOpenPostRide(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool isBadge;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.onTap,
      this.isBadge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.sage.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: AppColors.bark.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.moss, size: 20),
                if (isBadge)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    color: AppColors.bark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(
                    color: AppColors.sage,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.sage.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: AppColors.bark.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Icon(icon, color: AppColors.moss, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.bark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String amount;

  const _ActivityCard(
      {required this.title,
      required this.subtitle,
      required this.time,
      required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sage.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.moss, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.bark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style:
                        const TextStyle(color: AppColors.sage, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(
                      color: AppColors.bark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Text(time,
                  style: const TextStyle(color: AppColors.sage, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaptainBottomNav extends StatelessWidget {
  final VoidCallback onPostRide;

  const _CaptainBottomNav({required this.onPostRide});

  @override
  Widget build(BuildContext context) {
    const activeIndex = 0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    void onNavTap(int index) {
      if (index == activeIndex) return;
      switch (index) {
        case 0:
          break;
        case 1:
          onPostRide();
          break;
        case 2:
          Navigator.pushNamed(context, '/my-rides');
          break;
        case 3:
          Navigator.pushNamed(context, '/requests');
          break;
        case 4:
          Navigator.pushNamed(context, '/profile');
          break;
      }
    }

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomPadding > 0 ? bottomPadding : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
            top: BorderSide(color: AppColors.sage.withOpacity(0.2), width: 1)),
        boxShadow: [
          BoxShadow(
              color: AppColors.bark.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, -6))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Home',
              active: activeIndex == 0,
              onTap: () => onNavTap(0)),
          _NavItem(
              icon: Icons.add_circle_outline_rounded,
              label: 'Post Ride',
              active: activeIndex == 1,
              onTap: () => onNavTap(1)),
          _NavItem(
              icon: Icons.directions_car_rounded,
              label: 'My Rides',
              active: activeIndex == 2,
              onTap: () => onNavTap(2)),
          _NavItem(
              icon: Icons.inbox_rounded,
              label: 'Requests',
              active: activeIndex == 3,
              onTap: () => onNavTap(3)),
          _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              active: activeIndex == 4,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppColors.moss : AppColors.sage, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.moss : AppColors.sage,
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

