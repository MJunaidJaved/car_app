import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/ride_service.dart';
import '../../services/api_service.dart';
import '../../models/ride_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/skeleton_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/bottom_nav_item.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _selectedCategory = 0;
  String _rideModeFilter = 'all';
  List<RideModel> _nearbyRides = [];
  Map<String, String> _doneDealCaptainPhoneByRide = {};
  List<Map<String, dynamic>> _recentBookings = [];
  List<Map<String, dynamic>> _recentCustomerRequests = [];
  bool _loadingRides = true;
  double? _userLat;
  double? _userLng;
  Timer? _refreshTimer;

  bool _isDashboardBookingActive(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toLowerCase();
    if (!['pending', 'confirmed', 'started'].contains(status)) return false;
    final ride = booking['ride'] as Map<String, dynamic>? ?? {};
    final rideStatus = (ride['status'] ?? '').toString().toLowerCase();
    if (rideStatus.isNotEmpty &&
        rideStatus != 'active' &&
        rideStatus != 'in_progress') {
      return false;
    }
    final departure = DateTime.tryParse(
      (ride['departureTime'] ?? booking['departureTime'] ?? '').toString(),
    );
    if (departure == null) return true;
    return departure.isAfter(DateTime.now());
  }

  List<Map<String, dynamic>> _categoriesFor(bool isFemale) => [
        {
          'label': 'Daily',
          'icon': Icons.home_work_outlined,
          'type': 'all',
          'color': AppColors.vehicleColor('all'),
        },
        {
          'label': 'Car',
          'icon': Icons.directions_car_outlined,
          'type': 'car',
          'color': AppColors.vehicleColor('car'),
        },
        {
          'label': 'Bike',
          'icon': Icons.two_wheeler_outlined,
          'type': 'bike',
          'color': AppColors.vehicleColor('bike'),
        },
        {
          'label': 'Bus',
          'icon': Icons.directions_bus_outlined,
          'type': 'bus',
          'color': AppColors.vehicleColor('bus'),
        },
        {
          'label': 'Truck',
          'icon': Icons.local_shipping_outlined,
          'type': 'truck',
          'color': AppColors.vehicleColor('truck'),
        },
        {
          'label': 'Shazore',
          'icon': Icons.fire_truck_outlined,
          'type': 'shazore',
          'color': AppColors.vehicleColor('shazore'),
        },
        if (isFemale)
          {
            'label': 'Ladies',
            'icon': Icons.woman_2_outlined,
            'type': 'ladies',
            'color': AppColors.vehicleColor('ladies'),
          },
      ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadRides(showLoading: false),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCustomerPhone());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    } catch (_) {}
    await _loadRides();
  }

  double _distanceScore(RideModel ride) {
    if (_userLat == null || _userLng == null) return double.maxFinite;
    return AppHelpers.distanceKm(
      _userLat!,
      _userLng!,
      ride.startLat,
      ride.startLng,
    );
  }

  Future<void> _loadRides({
    String? type,
    String? rideMode,
    String? startLocation,
    String? endLocation,
    bool showLoading = true,
  }) async {
    if (showLoading) setState(() => _loadingRides = true);
    try {
      final rideService = Provider.of<RideService>(context, listen: false);
      final ridesFuture = rideService.findRides(
        startLocation: startLocation,
        endLocation: endLocation,
        type: type,
        rideMode: rideMode ?? _rideModeFilter,
        userLat: _userLat,
        userLng: _userLng,
      );
      final dealsFuture = _loadDoneDeals();
      final customerRequestsFuture = _loadCustomerRequests();
      final rides = await ridesFuture;
      await dealsFuture;
      await customerRequestsFuture;
      rides.sort((a, b) {
        final byDistance = _distanceScore(a).compareTo(_distanceScore(b));
        if (byDistance != 0) return byDistance;
        return b.createdAt.compareTo(a.createdAt);
      });
      if (mounted) {
        setState(() {
          _nearbyRides = rides;
          _loadingRides = false;
        });
      }
    } catch (_) {
      if (mounted && showLoading) setState(() => _loadingRides = false);
    }
  }

  Future<void> _loadDoneDeals() async {
    try {
      final res = await ApiService.get('/deals/my-bookings');
      final bookings = List<Map<String, dynamic>>.from(
        res['bookings'] ?? [],
      ).where((b) => _isDashboardBookingActive(b)).toList();
      bookings.sort((a, b) {
        final aAt = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
      final map = <String, String>{};
      for (final b in bookings) {
        final status = (b['status'] ?? '').toString().toLowerCase();
        if (!['confirmed', 'started', 'completed'].contains(status)) continue;
        final rideId = (b['rideId'] ?? '').toString();
        if (rideId.isEmpty) continue;
        final phone = (b['captainPhone'] ??
                b['captain']?['phone'] ??
                b['ride']?['captainPhone'] ??
                '')
            .toString()
            .trim();
        if (phone.isNotEmpty) map[rideId] = phone;
      }
      if (mounted) {
        setState(() {
          _doneDealCaptainPhoneByRide = map;
          _recentBookings = bookings;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCustomerRequests() async {
    try {
      final res = await ApiService.get('/customer-requests/my');
      final requests = List<Map<String, dynamic>>.from(res['requests'] ?? []);
      requests.sort((a, b) {
        final aAt = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
      if (mounted) {
        setState(() => _recentCustomerRequests = requests.take(5).toList());
      }
    } catch (_) {}
  }

  Future<void> _ensureCustomerPhone() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    final role = user.role.toLowerCase();
    if (role != 'passenger' && role != 'customer') return;
    if (user.phone.trim().isNotEmpty) return;
    if (!mounted) return;

    final ctrl = TextEditingController();
    bool validPhone(String value) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      return digits.length >= 10 && digits.length <= 13;
    }

    final phone = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Add WhatsApp / Contact Number'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '03XXXXXXXXX',
            labelText: 'WhatsApp Number',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final value = ctrl.text.trim();
              if (!validPhone(value)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter a valid phone number (03XXXXXXXXX).',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(ctx, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (phone == null || phone.isEmpty) return;
    try {
      final res = await ApiService.patch('/auth/profile', {'phone': phone});
      final updated = user.copyWith(
        phone: (res['user']?['phone'] ?? phone).toString(),
      );
      userProvider.setUser(updated);
    } catch (_) {}
  }

  String _formatDeparture(DateTime? dt) {
    if (dt == null) return 'Soon';
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Departed';
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes} mins';
    if (diff.inHours < 24) return 'In ${diff.inHours} hrs';
    return AppHelpers.formatDateTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final isFemaleUser = (user?.gender ?? '').toLowerCase() == 'female';
    final categories = _categoriesFor(isFemaleUser);
    final p = user?.photoUrl;
    final hasPhoto = p != null && p.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.veryLightBlue, AppColors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 240,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 180,
                      left: -10,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ],
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
                      type: categories[_selectedCategory]['type'] as String?,
                      rideMode: _rideModeFilter,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Passenger',
                                        style: TextStyle(
                                          color: AppColors.white
                                              .withValues(alpha: 0.8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        user?.name ?? 'User',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                          shadows: [
                                            Shadow(
                                              color: AppColors.dark,
                                              blurRadius: 6,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                NotificationBell(
                                  icon: Icons.notifications_outlined,
                                  iconColor: AppColors.white,
                                  backgroundColor:
                                      AppColors.white.withValues(alpha: 0.15),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/profile'),
                                  child: CircleAvatar(
                                    radius: 21,
                                    backgroundColor:
                                        AppColors.white.withValues(alpha: 0.2),
                                    backgroundImage: hasPhoto
                                        ? CachedNetworkImageProvider(p)
                                        : null,
                                    child: !hasPhoto
                                        ? Text(
                                            ((user?.name ?? '').isNotEmpty
                                                    ? user!.name
                                                    : 'P')[0]
                                                .toUpperCase(),
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
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.dark.withValues(alpha: 0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Search where you go',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.sage
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          '/find-ride',
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.search_rounded,
                                                color: AppColors.primary,
                                                size: 24,
                                              ),
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
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await Navigator.pushNamed(
                                          context,
                                          '/customer-request',
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.edit_location_alt_outlined,
                                      ),
                                      label: const Text(
                                        'Post where you want to go',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.moss,
                                        foregroundColor: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  // ✅ REMOVED: Book, Bookings, Request, Tours boxes
                                  // Old GridView with 4 boxes is REMOVED
                                  const SizedBox(height: 16),
                                ],
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
                                  'Recent Requests',
                                  style: TextStyle(
                                    color: AppColors.dark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/customer-request',
                                  ),
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
                          const SizedBox(height: 12),
                          if (_recentCustomerRequests.isNotEmpty)
                            ..._recentCustomerRequests.map((request) {
                              final start = RideModel.formatLocationLabel(
                                request['startLocation'],
                              );
                              final end = RideModel.formatLocationLabel(
                                request['endLocation'],
                              );
                              final status =
                                  (request['status'] ?? 'open').toString();
                              final desiredFare =
                                  (request['desiredFare'] ?? '').toString();
                              final offers = List<Map<String, dynamic>>.from(
                                request['offers'] ?? const [],
                              );
                              final requestedAtStr =
                                  request['requestedAtDisplay'] ??
                                      request['displayDateTime'] ??
                                      request['requestedAt'] ??
                                      request['createdAt'];
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  10,
                                ),
                                child: GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/customer-request',
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.skyBlue.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(top: 4),
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                start.isEmpty ? 'From' : start,
                                                style: const TextStyle(
                                                  color: AppColors.moss,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 1.5, top: 2, bottom: 2),
                                          child: Container(
                                            width: 3,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(1),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(top: 4),
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                end.isEmpty ? 'To' : end,
                                                style: const TextStyle(
                                                  color: AppColors.rose,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (requestedAtStr != null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.watch_later_outlined,
                                                  size: 16,
                                                  color: AppColors.moss),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  AppHelpers
                                                      .formatDateTimeValue(
                                                          requestedAtStr),
                                                  style: const TextStyle(
                                                    color: AppColors.dark,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              desiredFare.isEmpty ||
                                                      desiredFare == 'null'
                                                  ? '${offers.length} offers'
                                                  : 'Rs $desiredFare | ${offers.length} offers',
                                              style: const TextStyle(
                                                color: AppColors.moss,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            Text(
                                              status.toUpperCase(),
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            })
                          else if (_recentBookings.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'No recent requests yet.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            )
                          else
                            ..._recentBookings.map((b) {
                              final dealId = (b['id'] ?? '').toString();
                              final rideId = (b['rideId'] ?? '').toString();
                              final start = RideModel.formatLocationLabel(
                                b['ride']?['startLocation'],
                              );
                              final end = RideModel.formatLocationLabel(
                                b['ride']?['endLocation'],
                              );
                              final fare = (b['agreedFare'] ?? 0).toString();
                              final status = (b['status'] ?? '').toString();
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  10,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    if (dealId.isEmpty) {
                                      Navigator.pushNamed(
                                        context,
                                        '/my-bookings',
                                      );
                                      return;
                                    }
                                    Navigator.pushNamed(
                                      context,
                                      '/active-ride',
                                      arguments: {
                                        'rideId': rideId,
                                        'dealId': dealId,
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.sage
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(top: 4),
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                start.isEmpty
                                                    ? 'Unknown start'
                                                    : start,
                                                style: const TextStyle(
                                                  color: AppColors.moss,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 1.5, top: 2, bottom: 2),
                                          child: Container(
                                            width: 3,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(1),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(top: 4),
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                end.isEmpty
                                                    ? 'Unknown destination'
                                                    : end,
                                                style: const TextStyle(
                                                  color: AppColors.rose,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if ((b['ride']?['departureTime'] ??
                                                b['departureTime']) !=
                                            null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.watch_later_outlined,
                                                  size: 16,
                                                  color: AppColors.moss),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  AppHelpers
                                                      .formatDateTimeValue(b[
                                                                  'ride']?[
                                                              'departureTime'] ??
                                                          b['departureTime']),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.electricBlue,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Rs $fare',
                                              style: const TextStyle(
                                                color: AppColors.moss,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              status.toUpperCase(),
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: _rideModeFilter == 'all',
                                  onSelected: (_) {
                                    setState(() => _rideModeFilter = 'all');
                                    _loadRides(
                                      type: categories[_selectedCategory]
                                          ['type'] as String?,
                                      rideMode: 'all',
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                ChoiceChip(
                                  label: const Text('Share'),
                                  selected: _rideModeFilter == 'share',
                                  onSelected: (_) {
                                    setState(() => _rideModeFilter = 'share');
                                    _loadRides(
                                      type: categories[_selectedCategory]
                                          ['type'] as String?,
                                      rideMode: 'share',
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                ChoiceChip(
                                  label: const Text('Solo'),
                                  selected: _rideModeFilter == 'solo',
                                  onSelected: (_) {
                                    setState(() => _rideModeFilter = 'solo');
                                    _loadRides(
                                      type: categories[_selectedCategory]
                                          ['type'] as String?,
                                      rideMode: 'solo',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: categories.asMap().entries.map((
                                entry,
                              ) {
                                final i = entry.key;
                                final cat = entry.value;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: i == categories.length - 1 ? 0 : 6,
                                    ),
                                    child: _CategoryTab(
                                      label: cat['label'],
                                      icon: cat['icon'],
                                      color: cat['color'] as Color? ??
                                          AppColors.primary,
                                      isSelected: _selectedCategory == i,
                                      onTap: () {
                                        setState(() => _selectedCategory = i);
                                        _loadRides(
                                          type: cat['type'] as String?,
                                          rideMode: _rideModeFilter,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Available Rides',
                                  style: TextStyle(
                                    color: AppColors.dark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/find-ride',
                                  ),
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
                            const SkeletonList(
                              item: RideCardSkeleton(),
                              count: 4,
                            )
                          else if (_nearbyRides.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'No rides available right now. Try Find a Ride to search.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            )
                          else
                            ..._nearbyRides.map(
                              (ride) => GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/find-ride'),
                                child: _LiveRideCard(
                                  ride: ride,
                                  from: ride.startLocation,
                                  to: ride.endLocation,
                                  time: _formatDeparture(ride.departureTime),
                                  price:
                                      'Rs ${ride.suggestedFare.toStringAsFixed(0)}',
                                  seatsLeft: ride.availableSeats,
                                  captainName: ride.captainName,
                                  doneDealPhone:
                                      _doneDealCaptainPhoneByRide[ride.id],
                                  onBookNow: () => Navigator.pushNamed(
                                    context,
                                    '/fare-negotiate',
                                    arguments: ride,
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 84,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
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

class _PassengerQuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PassengerQuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, AppColors.deepNavy, 0.18)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.white, size: 19),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.bark,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, 0.15)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? Colors.transparent : color.withValues(alpha: 0.25),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.28 : 0.10),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : color,
              size: 21,
            ),
            const SizedBox(height: 5),
            Flexible(
              child: Text(
                label.split(' ')[0],
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textDark,
                  fontSize: 9.5,
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

class _LiveRideCard extends StatelessWidget {
  final RideModel ride;
  final String from;
  final String to;
  final String time;
  final String price;
  final int seatsLeft;
  final String captainName;
  final String? doneDealPhone;
  final VoidCallback onBookNow;

  const _LiveRideCard({
    required this.ride,
    required this.from,
    required this.to,
    required this.time,
    required this.price,
    required this.seatsLeft,
    required this.captainName,
    this.doneDealPhone,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final isFemaleUser = (user?.gender ?? '').toLowerCase() == 'female';
    final isLadiesLocked = ride.isLadiesRide && !isFemaleUser;
    final dtLabel = AppHelpers.formatDateTime(ride.departureTime);
    final vehicleColor = AppColors.vehicleColor(ride.vehicleType);

    return Hero(
      tag: 'ride_${ride.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vehicleColor.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: vehicleColor.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: AppColors.vehicleGradient(ride.vehicleType),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: vehicleColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.trip_origin,
                            color: Colors.green, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            from.isEmpty ? 'From' : from,
                            style: const TextStyle(
                              color: AppColors.moss,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        width: 1.5,
                        height: 10,
                        color: AppColors.sage.withValues(alpha: 0.5),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.red, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            to.isEmpty ? 'To' : to,
                            style: const TextStyle(
                              color: AppColors.rose,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.moss),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dtLabel,
                      style: const TextStyle(
                        color: AppColors.bark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$seatsLeft seats left',
                    style: TextStyle(
                      color:
                          seatsLeft == 1 ? AppColors.error : AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: vehicleColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      ride.vehicleType.toUpperCase(),
                      style: TextStyle(
                        color: vehicleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (ride.isLadiesRide) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.ladiesPink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Ladies',
                        style: TextStyle(
                          color: AppColors.ladiesPink,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    captainName,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isLadiesLocked
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            '/fare-negotiate',
                            arguments: ride,
                          ),
                  child: Text(
                    isLadiesLocked
                        ? 'Female passengers only'
                        : 'Book / Details',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if ((doneDealPhone ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => dialPhone(context, doneDealPhone),
                        icon: const Icon(Icons.call_rounded),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => openWhatsApp(context, doneDealPhone),
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PassengerBottomNav extends StatefulWidget {
  const _PassengerBottomNav();

  @override
  State<_PassengerBottomNav> createState() => _PassengerBottomNavState();
}

class _PassengerBottomNavState extends State<_PassengerBottomNav> {
  Timer? _badgeTimer;
  int _homeBadge = 0;
  int _bookingBadge = 0;
  int _profileBadge = 0;

  @override
  void initState() {
    super.initState();
    _loadBadges();
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadBadges(),
    );
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBadges() async {
    try {
      final res = await ApiService.get('/notifications/summary');
      final byType = Map<String, dynamic>.from(res['byType'] ?? {});
      int sumTypes(List<String> types) => types.fold<int>(
            0,
            (sum, type) => sum + (int.tryParse('${byType[type] ?? 0}') ?? 0),
          );
      if (!mounted) return;
      setState(() {
        _homeBadge = sumTypes([
          'new_ride',
          'customer_offer',
          'customer_counter',
          'customer_request_accepted',
        ]);
        _bookingBadge = sumTypes([
          'new_deal',
          'deal_confirmed',
          'deal_cancelled',
          'deal_counter',
          'ride_started',
          'ride_completed',
          'deal_message',
          'passenger_boarded',
        ]);
        final total = int.tryParse('${res['unreadCount'] ?? 0}') ?? 0;
        _profileBadge = total - _homeBadge - _bookingBadge;
        if (_profileBadge < 0) _profileBadge = 0;
      });
    } catch (_) {}
  }

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
          Navigator.pushNamed(context, '/profile');
          break;
      }
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 14,
          bottom: bottomPadding > 0 ? bottomPadding : 16,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: true,
                badgeCount: _homeBadge,
                onTap: () => onNavTap(0),
              ),
            ),
            Expanded(
              child: NavItem(
                icon: Icons.map_outlined,
                label: 'Tours',
                active: false,
                onTap: () => onNavTap(1),
              ),
            ),
            Expanded(
              child: NavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Bookings',
                active: false,
                badgeCount: _bookingBadge,
                onTap: () => onNavTap(2),
              ),
            ),
            Expanded(
              child: NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                active: false,
                badgeCount: _profileBadge,
                onTap: () => onNavTap(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
