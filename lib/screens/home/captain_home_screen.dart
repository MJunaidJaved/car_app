import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/ride_model.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/captain_profile_utils.dart';
import '../../widgets/notification_bell.dart';

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
  List<Map<String, dynamic>> _recentDealRequests = [];
  List<Map<String, dynamic>> _nearbyCustomerRequests = [];
  double _walletBalance = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(31.5204, 74.3587);
  bool _mapReady = false;
  Timer? _refreshTimer;

  bool _isDashboardRideActive(Map<String, dynamic> ride) {
    final status = (ride['status'] ?? '').toString().toLowerCase();
    if (status.isNotEmpty && status != 'active' && status != 'in_progress') {
      return false;
    }
    final dt = DateTime.tryParse((ride['departureTime'] ?? '').toString());
    if (dt == null) return true;
    return dt.isAfter(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _initLocation();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadDashboard(),
    );
  }

  Future<void> _syncOnlineStatus() async {
    try {
      await ApiService.patch('/auth/status', {'isOnline': _isOnline});
    } catch (_) {}
  }

  Future<void> _loadDashboard() async {
    try {
      final results = await Future.wait([
        ApiService.get('/auth/profile'),
        ApiService.get('/rides/my-rides'),
        ApiService.get('/wallet'),
        ApiService.get('/wallet/transactions'),
        ApiService.get(
          '/customer-requests',
          queryParams: {
            if (_mapReady) 'lat': _currentLocation.latitude.toString(),
            if (_mapReady) 'lng': _currentLocation.longitude.toString(),
          },
        ),
      ]);

      final profileRes = results[0];
      final ridesRes = results[1];
      final walletRes = results[2];
      final txRes = results[3];
      final customerReqRes = results[4];

      final user = profileRes['user'] as Map<String, dynamic>?;
      if (user != null && mounted) {
        setState(() {
          _isOnline = user['isOnline'] != false;
        });
      }
      
      final rides = List<Map<String, dynamic>>.from(ridesRes['rides'] ?? []);
      final activeDashboardRides =
          rides.where((ride) => _isDashboardRideActive(ride)).toList();
      rides.sort((a, b) {
        final aAt = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
      Map<String, dynamic>? active;
      for (final r in activeDashboardRides) {
        if (r['status'] == 'active') {
          active = r;
          break;
        }
      }
      final pendingMap = <String, int>{};
      final recentDealRequests = <Map<String, dynamic>>[];
      final topRides = rides.take(20).toList();
      final dealFutures = topRides.map((ride) async {
        final rideId = (ride['id'] ?? '').toString();
        if (rideId.isEmpty) return null;
        try {
          final dealsRes = await ApiService.get('/deals/ride/$rideId');
          return {'ride': ride, 'dealsRes': dealsRes};
        } catch (_) {
          return {'ride': ride, 'dealsRes': null};
        }
      });
      
      final dealResults = await Future.wait(dealFutures);
      
      for (final result in dealResults) {
        if (result == null) continue;
        final ride = result['ride'] as Map<String, dynamic>;
        final rideId = (ride['id'] ?? '').toString();
        final dealsRes = result['dealsRes'];
        
        if (dealsRes != null) {
          final deals = List<Map<String, dynamic>>.from(dealsRes['deals'] ?? []);
          pendingMap[rideId] = deals.where((d) => (d['status'] ?? '').toString().toLowerCase() == 'pending').length;
          for (final deal in deals) {
            final status = (deal['status'] ?? '').toString().toLowerCase();
            if (!['pending', 'confirmed', 'started'].contains(status)) continue;
            recentDealRequests.add({
              ...deal,
              'rideId': rideId,
              'rideStartLocation': ride['startLocation'],
              'rideEndLocation': ride['endLocation'],
              'rideDepartureTime': ride['departureTime'],
            });
          }
        } else {
          pendingMap[rideId] = 0;
        }
      }
      recentDealRequests.sort((a, b) {
        final aAt = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
      if (mounted) {
        setState(() {
          _activeRide = active;
          _latestRides = rides.take(20).toList();
          _pendingRequestsByRide = pendingMap;
          _recentDealRequests = recentDealRequests.take(20).toList();
          _nearbyCustomerRequests = List<Map<String, dynamic>>.from(
            customerReqRes['requests'] ?? [],
          );
          _walletBalance = _asDouble(walletRes['wallet']?['balance']);
          _recentTransactions = List<Map<String, dynamic>>.from(
            txRes['transactions'] ?? [],
          );
        });
      }
    } catch (_) {
        try {
          final fallbackResults = await Future.wait([
            ApiService.get('/wallet'),
            ApiService.get('/wallet/transactions'),
          ]);
          if (mounted) {
            setState(() {
              _walletBalance = _asDouble(fallbackResults[0]['wallet']?['balance']);
              _recentTransactions = List<Map<String, dynamic>>.from(
                fallbackResults[1]['transactions'] ?? [],
              );
            });
          }
        } catch (_) {}
      }
  }

  String _formatTxTime(dynamic createdAt) {
    final dt = DateTime.tryParse(createdAt?.toString() ?? '');
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _locationLabel(dynamic value, {String fallback = ''}) {
    final label = RideModel.formatLocationLabel(value);
    return label.isEmpty ? fallback : label;
  }

  Widget _customerRequestSummaryCard(Map<String, dynamic> request) {
    final desiredFare = request['desiredFare'];
    final distance = double.tryParse((request['distanceKm'] ?? '').toString());
    final distanceLabel = distance == null
        ? 'Distance unavailable'
        : '${distance.toStringAsFixed(1)} km away';
    final status = (request['status'] ?? 'open').toString().toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: _openCustomerRequests,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sage.withValues(alpha:0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_locationLabel(request['startLocation'], fallback: 'From')} -> ${_locationLabel(request['endLocation'], fallback: 'To')}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.bark,
                ),
              ),
              if ((request['pickupLocation'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Exact pickup: ${_locationLabel(request['pickupLocation'])}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.sage,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if ((request['dropLocation'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Exact drop: ${_locationLabel(request['dropLocation'])}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.sage,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$distanceLabel | ${desiredFare == null ? 'Offer your fare' : 'Budget Rs $desiredFare'}',
                      style: const TextStyle(
                        color: AppColors.moss,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: AppColors.bark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniPill(
                    label: (request['vehicleType'] ?? 'car')
                        .toString()
                        .toUpperCase(),
                  ),
                  _MiniPill(
                    label: (request['rideMode'] ?? 'solo')
                        .toString()
                        .toUpperCase(),
                  ),
                  if ((request['city'] ?? '').toString().trim().isNotEmpty)
                    _MiniPill(label: request['city'].toString()),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tap Details to view request and send fare offer.',
                      style: TextStyle(
                        color: AppColors.sage,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _openCustomerRequests,
                    child: const Text('Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _tryOpenPostRide(BuildContext context, {Map<String, dynamic>? args}) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (!CaptainProfileUtils.isProfileComplete(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete your captain profile checklist before posting rides.',
          ),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/post-ride', arguments: args);
  }

  Future<void> _openRideRequests(String rideId) async {
    if (rideId.isEmpty) return;
    await Navigator.pushNamed(context, '/requests', arguments: rideId);
    if (!mounted) return;
    await _loadDashboard();
  }

  Future<void> _openCustomerRequests() async {
    await Navigator.pushNamed(context, '/customer-requests');
    if (!mounted) return;
    await _loadDashboard();
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
        await _loadDashboard();
        _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation));
      }
    } catch (_) {
      if (mounted) setState(() => _mapReady = true);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

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
                  if (!_isOnline)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepNavy.withValues(alpha:0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'You are offline. Toggle online to receive requests.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // Top bar - Avatar with initials only (no photo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.moss.withValues(alpha:0.1),
                            child: Text(
                              AppHelpers.nameInitial(user?.name, fallback: 'C'),
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
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.moss,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (user?.totalRides ?? 0) == 0
                                        ? 'New Captain'
                                        : '${(user?.rating ?? 0).toStringAsFixed(1)} Rating',
                                    style: const TextStyle(
                                      color: AppColors.sage,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        NotificationBell(
                          iconColor: AppColors.bark,
                          backgroundColor: AppColors.white,
                          borderColor: AppColors.sage.withValues(alpha:0.3),
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
                          color: AppColors.warning.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha:0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.warning,
                              size: 28,
                            ),
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
                            color: AppColors.sage.withValues(alpha:0.3),
                          ),
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
                                          : AppColors.error,
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
                            if (!profileComplete)
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
                            AbsorbPointer(
                              child: GoogleMap(
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
                                    infoWindow: const InfoWindow(
                                      title: 'Your Location',
                                    ),
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
                            ),

                            // Online/Offline overlay at bottom of map
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bark.withValues(alpha:0.92),
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
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          _isOnline
                                              ? 'Visible to passengers'
                                              : 'Currently Offline',
                                          style: TextStyle(
                                            color: AppColors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final next = !_isOnline;
                                        setState(() => _isOnline = next);
                                        await _syncOnlineStatus();
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _isOnline
                                              ? AppColors.moss
                                              : AppColors.sage.withValues(alpha:0.3),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.white.withOpacity(
                                              0.2,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.power_settings_new_rounded,
                                          color: AppColors.white,
                                          size: 20,
                                        ),
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
                                _openRideRequests(
                                  (_activeRide!['id'] ?? '').toString(),
                                );
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
                        fontWeight: FontWeight.w800,
                      ),
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
                          const SizedBox(width: 16),
                          _QuickActionCard(
                            label: 'Customer Requests',
                            icon: Icons.hail_rounded,
                            onTap: _openCustomerRequests,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customer rides',
                          style: TextStyle(
                            color: AppColors.bark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openCustomerRequests,
                          child: const Text(
                            'See all',
                            style: TextStyle(
                              color: AppColors.moss,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_nearbyCustomerRequests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'No customer posts right now.',
                        style: TextStyle(color: AppColors.sage),
                      ),
                    )
                  else
                    ..._nearbyCustomerRequests.map((request) {
                      final desiredFare = request['desiredFare'];
                      final distance = double.tryParse(
                        (request['distanceKm'] ?? '').toString(),
                      );
                      final distanceLabel = distance == null
                          ? 'Distance unavailable'
                          : '${distance.toStringAsFixed(1)} km away';
                      final status = (request['status'] ?? 'open')
                          .toString()
                          .toUpperCase();
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: GestureDetector(
                          onTap: _openCustomerRequests,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.sage.withValues(alpha:0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_locationLabel(request['startLocation'], fallback: 'From')} -> ${_locationLabel(request['endLocation'], fallback: 'To')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.bark,
                                  ),
                                ),
                                if ((request['pickupLocation'] ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Exact pickup: ${_locationLabel(request['pickupLocation'])}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.sage,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if ((request['dropLocation'] ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Exact drop: ${_locationLabel(request['dropLocation'])}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.sage,
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
                                        '$distanceLabel | ${desiredFare == null ? 'Offer your fare' : 'Budget Rs $desiredFare'}',
                                        style: const TextStyle(
                                          color: AppColors.moss,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.bg,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          color: AppColors.bark,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _MiniPill(
                                      label: (request['vehicleType'] ?? 'car')
                                          .toString()
                                          .toUpperCase(),
                                    ),
                                    _MiniPill(
                                      label: (request['rideMode'] ?? 'solo')
                                          .toString()
                                          .toUpperCase(),
                                    ),
                                    if ((request['city'] ?? '')
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                      _MiniPill(
                                        label: request['city'].toString(),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tap to open details and send fare offer.',
                                  style: TextStyle(
                                    color: AppColors.sage,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openCustomerRequests,
                          child: const Text(
                            'See all',
                            style: TextStyle(
                              color: AppColors.moss,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_recentDealRequests.isNotEmpty)
                    ..._recentDealRequests.take(8).map((deal) {
                      final rideId = (deal['rideId'] ?? '').toString();
                      final customer =
                          deal['customer'] as Map<String, dynamic>? ?? {};
                      final customerName = (customer['name'] ??
                              deal['customerName'] ??
                              'Customer')
                          .toString();
                      final fare = (deal['agreedFare'] ?? 0).toString();
                      final status = (deal['status'] ?? '').toString();
                      final start = _locationLabel(
                        deal['rideStartLocation'],
                        fallback: 'From',
                      );
                      final end = _locationLabel(
                        deal['rideEndLocation'],
                        fallback: 'To',
                      );
                      final pickup = _locationLabel(
                        deal['passengerPickupAddress'],
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (rideId.isEmpty) return;
                            _openRideRequests(rideId);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.sage.withValues(alpha:0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$customerName requested your ride',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.bark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$start -> $end',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.sage,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (pickup.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pickup: $pickup',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.sage,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.bg,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
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
                                        _openRideRequests(rideId);
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
                        'No booking or fare requests yet.',
                        style: TextStyle(color: AppColors.sage),
                      ),
                    ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 86),
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
              notificationCount: _pendingRequestsByRide.values.fold<int>(
                    0,
                    (sum, count) => sum + count,
                  ) +
                  _nearbyCustomerRequests
                      .where((r) => ['open', 'countered'].contains(
                            (r['status'] ?? '').toString().toLowerCase(),
                          ))
                      .length,
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    this.isBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sage.withValues(alpha:0.3)),
          boxShadow: AppColors.cardShadow,
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
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.bark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.sage,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sage.withValues(alpha:0.3)),
              boxShadow: AppColors.cardShadow,
            ),
            child: Icon(icon, color: AppColors.moss, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.bark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
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

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sage.withValues(alpha:0.1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.moss,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.bark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.sage, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: AppColors.bark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: AppColors.sage, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;

  const _MiniPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sage.withValues(alpha:0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.bark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CaptainBottomNav extends StatelessWidget {
  final VoidCallback onPostRide;
  final int notificationCount;

  const _CaptainBottomNav({
    required this.onPostRide,
    required this.notificationCount,
  });

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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            left: 4,
            right: 4,
            top: 12,
            bottom: bottomPadding > 0 ? bottomPadding : 16,
          ),
          decoration: const BoxDecoration(
            color: Color(0x33FFFFFF),
            border: Border(
              top: BorderSide(color: Color(0x55BDC4D4), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Home',
                  active: activeIndex == 0,
                  onTap: () => onNavTap(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Post Ride',
                  active: activeIndex == 1,
                  onTap: () => onNavTap(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.directions_car_rounded,
                  label: 'My Rides',
                  active: activeIndex == 2,
                  onTap: () => onNavTap(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.inbox_rounded,
                  label: 'Requests',
                  active: activeIndex == 3,
                  badgeCount: notificationCount,
                  onTap: () => onNavTap(3),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  active: activeIndex == 4,
                  onTap: () => onNavTap(4),
                ),
              ),
            ],
          ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: active ? AppColors.moss : AppColors.sage,
                size: 24,
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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

