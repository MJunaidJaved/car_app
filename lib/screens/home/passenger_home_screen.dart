import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../services/ride_service.dart';
import '../../services/api_service.dart';
import '../../models/ride_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/places_autocomplete_field.dart';

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
  List<Map<String, dynamic>> _postedRequests = [];
  bool _loadingRides = true;
  double? _userLat;
  double? _userLng;
  final _homeFromCtrl = TextEditingController();
  final _homeToCtrl = TextEditingController();
  LatLng? _homeFromLatLng;
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
        {'label': 'Daily', 'icon': Icons.home_work_outlined, 'type': 'all'},
        {'label': 'Car', 'icon': Icons.directions_car_outlined, 'type': 'car'},
        {'label': 'Bike', 'icon': Icons.two_wheeler_outlined, 'type': 'bike'},
        {'label': 'Bus', 'icon': Icons.directions_bus_outlined, 'type': 'bus'},
        {
          'label': 'Truck',
          'icon': Icons.local_shipping_outlined,
          'type': 'truck'
        },
        {
          'label': 'Shazore',
          'icon': Icons.fire_truck_outlined,
          'type': 'shazore'
        },
        if (isFemale)
          {'label': 'Ladies', 'icon': Icons.woman_2_outlined, 'type': 'ladies'},
      ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadRides(showLoading: false),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCustomerPhone());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _homeFromCtrl.dispose();
    _homeToCtrl.dispose();
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
    final dLat = ride.startLat - _userLat!;
    final dLng = ride.startLng - _userLng!;
    return (dLat * dLat) + (dLng * dLng);
  }

  Future<void> _loadRides({
    String? type,
    String? rideMode,
    String? startLocation,
    String? endLocation,
    LatLng? searchLatLng,
    bool showLoading = true,
  }) async {
    if (showLoading) setState(() => _loadingRides = true);
    try {
      final rideService = Provider.of<RideService>(context, listen: false);
      final effectiveLat = searchLatLng?.latitude ?? _userLat;
      final effectiveLng = searchLatLng?.longitude ?? _userLng;
      final ridesFuture = rideService.findRides(
        startLocation: searchLatLng == null ? startLocation : null,
        endLocation: endLocation,
        type: type,
        rideMode: rideMode ?? _rideModeFilter,
        userLat: effectiveLat,
        userLng: effectiveLng,
        radiusKm: 20,
      );
      final dealsFuture = _loadDoneDeals();
      final postedFuture = _loadPostedRequests();
      final rides = await ridesFuture;
      await Future.wait([dealsFuture, postedFuture]);
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

  Future<void> _searchHomeRides(List<Map<String, dynamic>> categories) async {
    await _loadRides(
      type: categories[_selectedCategory]['type'] as String?,
      rideMode: _rideModeFilter,
      startLocation: _homeFromCtrl.text.trim(),
      endLocation: _homeToCtrl.text.trim(),
      searchLatLng: _homeFromLatLng,
    );
  }

  void _clearHomeSearch(List<Map<String, dynamic>> categories) {
    _homeFromCtrl.clear();
    _homeToCtrl.clear();
    _homeFromLatLng = null;
    _loadRides(
      type: categories[_selectedCategory]['type'] as String?,
      rideMode: _rideModeFilter,
    );
  }

  Future<void> _loadPostedRequests() async {
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
      if (mounted) setState(() => _postedRequests = requests);
    } catch (_) {}
  }

  double _bestOfferFare(Map<String, dynamic> request) {
    final offers = List<Map<String, dynamic>>.from(request['offers'] ?? []);
    if (offers.isEmpty) return 0;
    offers.sort((a, b) {
      final aFare =
          double.tryParse((a['counterFare'] ?? a['fare'] ?? 0).toString()) ?? 0;
      final bFare =
          double.tryParse((b['counterFare'] ?? b['fare'] ?? 0).toString()) ?? 0;
      return aFare.compareTo(bFare);
    });
    return double.tryParse(
          (offers.first['counterFare'] ?? offers.first['fare'] ?? 0).toString(),
        ) ??
        0;
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
    return DateFormat('MMM d, h:mm a').format(dt);
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
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
                                        'Where to next,',
                                        style: TextStyle(
                                          color: AppColors.white.withOpacity(
                                            0.7,
                                          ),
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
                                NotificationBell(
                                  icon: Icons.notifications_outlined,
                                  iconColor: AppColors.white,
                                  backgroundColor:
                                      AppColors.white.withOpacity(0.15),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/profile'),
                                  child: CircleAvatar(
                                    radius: 21,
                                    backgroundColor:
                                        AppColors.white.withOpacity(0.2),
                                    backgroundImage:
                                        hasPhoto ? NetworkImage(p) : null,
                                    child: !hasPhoto
                                        ? Text(
                                            (user?.name ?? 'P')[0]
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
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await Navigator.pushNamed(
                                          context,
                                          '/customer-request',
                                        );
                                        await _loadPostedRequests();
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
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/find-ride',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.sage.withOpacity(
                                            0.3,
                                          ),
                                        ),
                                      ),
                                      child: const Row(
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
                                  'My Posted Requests',
                                  style: TextStyle(
                                    color: AppColors.dark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      '/customer-request',
                                    );
                                    await _loadPostedRequests();
                                  },
                                  child: const Text(
                                    'Details',
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
                          if (_postedRequests.isEmpty)
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
                                  'You have not posted any ride request yet.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            )
                          else
                            ..._postedRequests.map((request) {
                              final offers = List<Map<String, dynamic>>.from(
                                request['offers'] ?? [],
                              );
                              final bestFare = _bestOfferFare(request);
                              final status = (request['status'] ?? 'open')
                                  .toString()
                                  .toUpperCase();
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  10,
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      '/customer-request',
                                    );
                                    await _loadPostedRequests();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: offers.isEmpty
                                            ? AppColors.line
                                            : AppColors.primary
                                                .withOpacity(0.28),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              AppColors.dark.withOpacity(0.035),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${RideModel.formatLocationLabel(request['startLocation']).isEmpty ? 'From' : RideModel.formatLocationLabel(request['startLocation'])} -> ${RideModel.formatLocationLabel(request['endLocation']).isEmpty ? 'To' : RideModel.formatLocationLabel(request['endLocation'])}',
                                          style: const TextStyle(
                                            color: AppColors.dark,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if ((request['pickupLocation'] ?? '')
                                            .toString()
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Exact pickup: ${RideModel.formatLocationLabel(request['pickupLocation'])}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        if ((request['dropLocation'] ?? '')
                                            .toString()
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Exact drop: ${RideModel.formatLocationLabel(request['dropLocation'])}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                offers.isEmpty
                                                    ? 'No captain offers yet'
                                                    : '${offers.length} offers, best Rs ${bestFare.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: AppColors.moss,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.bg,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                status,
                                                style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              await Navigator.pushNamed(
                                                context,
                                                '/customer-request',
                                              );
                                              await _loadPostedRequests();
                                            },
                                            icon: const Icon(
                                              Icons.receipt_long_rounded,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Details',
                                            ),
                                          ),
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
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: AppColors.sage.withOpacity(0.25),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.dark.withOpacity(0.04),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Search rides by map location',
                                    style: TextStyle(
                                      color: AppColors.bark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  PlacesAutocompleteField(
                                    controller: _homeFromCtrl,
                                    label: 'From area',
                                    icon: Icons.my_location_rounded,
                                    onChanged: (_) {
                                      _homeFromLatLng = null;
                                    },
                                    onPlaceSelected: (latLng) {
                                      _homeFromLatLng = latLng;
                                      _searchHomeRides(categories);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  PlacesAutocompleteField(
                                    controller: _homeToCtrl,
                                    label: 'To / drop area',
                                    icon: Icons.flag_rounded,
                                    onChanged: (_) {},
                                    onPlaceSelected: (latLng) {
                                      _searchHomeRides(categories);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _searchHomeRides(categories),
                                          icon: const Icon(
                                            Icons.search_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Search'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      OutlinedButton(
                                        onPressed: () =>
                                            _clearHomeSearch(categories),
                                        child: const Text('Clear'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
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
                                    '/my-bookings',
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
                          if (_recentBookings.isEmpty)
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
                              final route =
                                  '${start.isEmpty ? 'Unknown' : start} -> ${end.isEmpty ? 'Unknown' : end}';
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
                                        color: AppColors.sage.withOpacity(0.25),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          route,
                                          style: const TextStyle(
                                            color: AppColors.dark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
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
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: categories.asMap().entries.map((
                                  entry,
                                ) {
                                  final i = entry.key;
                                  final cat = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right:
                                          i == categories.length - 1 ? 0 : 12,
                                    ),
                                    child: _CategoryTab(
                                      label: cat['label'],
                                      icon: cat['icon'],
                                      isSelected: _selectedCategory == i,
                                      onTap: () {
                                        setState(() => _selectedCategory = i);
                                        _loadRides(
                                          type: cat['type'] as String?,
                                          rideMode: _rideModeFilter,
                                        );
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
                                  'Daily Nearby Rides',
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
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator()),
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
                                  borderRadius: BorderRadius.circular(20),
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
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.textMuted,
              size: 24,
            ),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$from -> $to',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((ride.exactLocation ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Exact pickup: ${ride.exactLocation}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if ((ride.exactDropLocation ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Exact drop: ${ride.exactDropLocation}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RideInfoChip(
                          icon: Icons.access_time_rounded,
                          label: time,
                        ),
                        _RideInfoChip(
                          icon: Icons.person_outline_rounded,
                          label: '$seatsLeft seat${seatsLeft > 1 ? 's' : ''}',
                        ),
                        if (ride.rideMode.isNotEmpty)
                          _RideInfoChip(
                            icon: Icons.swap_horiz_rounded,
                            label: ride.rideMode.toUpperCase(),
                          ),
                        if (ride.rideType.isNotEmpty)
                          _RideInfoChip(
                            icon: Icons.category_outlined,
                            label: ride.rideType.toUpperCase(),
                          ),
                      ],
                    ),
                    if (ride.isLadiesRide) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Ladies Ride',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 92),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        captainName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/fare-negotiate',
                arguments: ride,
              ),
              child: const Text('Details'),
            ),
          ),
          const SizedBox(height: 10),
          if ((doneDealPhone ?? '').trim().isNotEmpty &&
              ['confirmed', 'started'].contains(ride.status)) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => dialPhone(context, doneDealPhone),
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Call Now'),
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
            const SizedBox(height: 8),
            Text(
              'Captain: $doneDealPhone',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLadiesLocked ? null : onBookNow,
                icon: const Icon(Icons.price_change_outlined),
                label: Text(
                  isLadiesLocked ? 'Female passengers only' : 'Book Now',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RideInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RideInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sage.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      const Duration(seconds: 2),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: true,
              badgeCount: _homeBadge,
              onTap: () => onNavTap(0),
            ),
            const SizedBox(width: 18),
            _NavItem(
              icon: Icons.map_outlined,
              label: 'Tours',
              active: false,
              onTap: () => onNavTap(1),
            ),
            const SizedBox(width: 18),
            _NavItem(
              icon: Icons.calendar_today_outlined,
              label: 'Bookings',
              active: false,
              badgeCount: _bookingBadge,
              onTap: () => onNavTap(2),
            ),
            const SizedBox(width: 18),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              active: false,
              badgeCount: _profileBadge,
              onTap: () => onNavTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.badgeCount = 0,
    required this.onTap,
  });

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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: active ? AppColors.primary : AppColors.textMuted,
                  size: 26,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -9,
                    top: -8,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 17, minHeight: 17),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
