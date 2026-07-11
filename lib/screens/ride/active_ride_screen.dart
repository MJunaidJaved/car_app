import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/deal_status_utils.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_tracking_service.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/deal_chat_panel.dart';
import '../../widgets/co_riders_section.dart';
import '../../widgets/skeleton_loader.dart';
import '../../models/ride_model.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});
  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  bool _showSosConfirm = false;
  bool _loading = true;
  String? _rideId;
  String? _dealId;
  Map<String, dynamic>? _deal;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _captainLocation;
  LatLng _defaultLocation = const LatLng(31.5204, 74.3587);
  final _locationService = LocationTrackingService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _dealSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _rideDealsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _rideSub;
  List<Map<String, dynamic>> _confirmedPassengers = [];
  bool _isCaptain = false;
  bool _customerRequestMode = false;
  String? _requestId;
  Map<String, dynamic>? _customerRequest;
  Timer? _captainLocationTimer;

  String get _captainName =>
      _deal?['captain']?['name'] ?? _deal?['ride']?['captainName'] ?? 'Captain';
  String get _start => _deal?['ride']?['startLocation'] ?? '';
  String get _end => _deal?['ride']?['endLocation'] ?? '';
  double get _fare => (_deal?['agreedFare'] ?? 0).toDouble();

  // ✅ Get rideMode for Share/Solo label
  String get _rideMode {
    final ride = _deal?['ride'] as Map<String, dynamic>?;
    return ride?['rideMode']?.toString() ?? 'share';
  }

  String get _vehicle {
    final rideInfo = _deal?['ride']?['vehicleInfo'];
    final fromRide = RideModel.formatVehicleInfo(rideInfo);
    if (fromRide.isNotEmpty) return fromRide;
    final c = _deal?['captain'] as Map<String, dynamic>?;
    if (c == null) return '';
    return '${c['vehicleMake'] ?? ''} ${c['vehicleModel'] ?? ''} ${c['vehicleColor'] ?? ''} ${c['vehicleRegistration'] ?? ''}'
        .trim();
  }

  String get _captainPhone {
    final c = _deal?['captain'] as Map<String, dynamic>?;
    return c?['phone']?.toString() ?? '';
  }

  String get _dealStatus => _deal?['status']?.toString() ?? '';
  String get _captainDistanceLabel {
    if (_captainLocation == null || _deal == null) {
      return 'Distance unavailable';
    }
    final pickupLat = (_deal!['passengerPickupLat'] ?? 0).toDouble();
    final pickupLng = (_deal!['passengerPickupLng'] ?? 0).toDouble();
    final baseLat = pickupLat != 0 ? pickupLat : _defaultLocation.latitude;
    final baseLng = pickupLng != 0 ? pickupLng : _defaultLocation.longitude;
    final meters = Geolocator.distanceBetween(
      _captainLocation!.latitude,
      _captainLocation!.longitude,
      baseLat,
      baseLng,
    );
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km away';
  }

  String get _statusHeaderLabel {
    if (!_isCaptain) {
      final boarding = _deal?['boardingStatus']?.toString() ?? '';
      if (boarding == 'boarded') return 'You are boarded';
      if (boarding == 'arrived') return 'Captain has arrived';
      if (_dealStatus == 'started') return 'Ride in progress';
      if (_dealStatus == 'confirmed') return 'Captain is on the way';
    }
    return dealStatusLabel(_dealStatus);
  }

  Color get _statusHeaderColor => dealStatusColor(_dealStatus);

  String get _captainInitial =>
      _captainName.isNotEmpty ? _captainName[0].toUpperCase() : 'C';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _rideId = args?['rideId']?.toString();
      _dealId = args?['dealId']?.toString();
      _requestId = args?['requestId']?.toString();
      _customerRequestMode = args?['customerRequestMode'] == true;
      final user = Provider.of<UserProvider>(context, listen: false).user;
      _isCaptain = user?.role == 'captain';
      if (_customerRequestMode && _requestId != null) {
        await _loadCustomerRequest();
      } else {
        await _loadDealOnce();
      }
      _subscribeDealStream();
      if (_isCaptain && _rideId != null) {
        await _loadConfirmedPassengers();
        _subscribeRideDeals();
      }
    });
  }

  Future<void> _loadConfirmedPassengers() async {
    if (_rideId == null) return;
    try {
      final res = await Provider.of<FirestoreService>(context, listen: false)
          .getConfirmedPassengers(_rideId!);
      if (mounted) {
        setState(() {
          _confirmedPassengers =
          List<Map<String, dynamic>>.from(res['passengers'] ?? []);
        });
        _refreshPassengerMarkers();
      }
    } catch (_) {}
  }

  void _subscribeRideDeals() {
    if (_rideId == null) return;
    _rideDealsSub?.cancel();
    _rideDealsSub = FirebaseFirestore.instance
        .collection('deals')
        .where('rideId', isEqualTo: _rideId)
        .snapshots()
        .listen((_) => _loadConfirmedPassengers());
  }

  Future<void> _setBoarding(String dealId, String status) async {
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .updateBoardingStatus(dealId: dealId, boardingStatus: status);
      await _loadConfirmedPassengers();
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Update failed: $e',
          isError: true,
        );
      }
    }
  }

  void _refreshPassengerMarkers() {
    final markers = <Marker>{
      ..._markers.where((m) => m.markerId.value == 'captain'),
    };

    final ride = _deal?['ride'] as Map<String, dynamic>? ?? {};
    final startLat = (ride['startLat'] ?? 0).toDouble();
    final startLng = (ride['startLng'] ?? 0).toDouble();
    final endLat = (ride['endLat'] ?? 0).toDouble();
    final endLng = (ride['endLng'] ?? 0).toDouble();
    if (startLat != 0 && startLng != 0) {
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: LatLng(startLat, startLng),
        infoWindow: InfoWindow(title: _start),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    if (endLat != 0 && endLng != 0) {
      markers.add(Marker(
        markerId: const MarkerId('end'),
        position: LatLng(endLat, endLng),
        infoWindow: InfoWindow(title: _end),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    if (!_isCaptain && _deal != null) {
      final lat = (_deal!['passengerPickupLat'] ?? 0).toDouble();
      final lng = (_deal!['passengerPickupLng'] ?? 0).toDouble();
      if (lat != 0 && lng != 0) {
        markers.add(Marker(
          markerId: const MarkerId('my_pickup'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: 'Your pickup',
            snippet: _deal!['passengerPickupAddress']?.toString(),
          ),
          icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ));
      }
    }

    if (_isCaptain) {
      for (final p in _confirmedPassengers) {
        final lat = (p['passengerPickupLat'] ?? 0).toDouble();
        final lng = (p['passengerPickupLng'] ?? 0).toDouble();
        if (lat == 0 && lng == 0) continue;
        final dealId = p['dealId']?.toString() ?? p['id']?.toString() ?? '';
        final boardingStatus = (p['boardingStatus'] ?? 'waiting').toString();
        final dropped = boardingStatus == 'dropped';
        final boarded = boardingStatus == 'boarded';
        final arrived = boardingStatus == 'arrived';
        markers.add(Marker(
          markerId: MarkerId('p_$dealId'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: p['customerName']?.toString() ??
                p['firstName']?.toString() ??
                'Passenger',
            snippet: p['passengerPickupAddress']?.toString(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            dropped
                ? BitmapDescriptor.hueViolet
                : boarded
                ? BitmapDescriptor.hueGreen
                : arrived
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueYellow,
          ),
        ));
      }
    }

    if (mounted) setState(() => _markers = markers);
  }

  Future<void> _loadDealOnce() async {
    if (_dealId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final deal = await Provider.of<FirestoreService>(context, listen: false)
          .getDeal(_dealId!);
      if (mounted) {
        setState(() {
          _deal = deal;
          _loading = false;
          _rideId ??= deal['rideId']?.toString();
        });
      }
      await _initMap();
      _startLocationTrackingIfNeeded();
      _subscribeRideLocationStream();
      if (_isCaptain && _rideId != null) _startCaptainLocationUpdates();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCustomerRequest() async {
    try {
      final res = await ApiService.get('/customer-requests/my');
      final list = List<Map<String, dynamic>>.from(res['requests'] ?? []);
      Map<String, dynamic>? req;
      for (final r in list) {
        if (r['id']?.toString() == _requestId) {
          req = r;
          break;
        }
      }
      if (req != null && mounted) {
        setState(() {
          _customerRequest = req;
          _loading = false;
        });
        _refreshCustomerRequestMap(req);
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _refreshCustomerRequestMap(Map<String, dynamic> request) {
    final lat = (request['startLat'] as num?)?.toDouble() ?? 0;
    final lng = (request['startLng'] as num?)?.toDouble() ?? 0;
    if (lat == 0 || lng == 0) return;
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: request['pickupLocation']?.toString() ?? 'Pickup',
          ),
        ),
      };
      _defaultLocation = LatLng(lat, lng);
    });
  }

  void _subscribeRideLocationStream() {
    if (_rideId == null) return;
    _rideSub?.cancel();
    _rideSub = FirebaseFirestore.instance
        .collection('rides')
        .doc(_rideId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;
      final ride = snap.data() ?? {};
      final lat = (ride['captainLat'] as num?)?.toDouble();
      final lng = (ride['captainLng'] as num?)?.toDouble();
      if (lat == null || lng == null || lat == 0 || lng == 0) return;
      final loc = LatLng(lat, lng);
      setState(() {
        _captainLocation = loc;
        _markers = {
          ..._markers.where((m) => m.markerId.value != 'captain'),
          Marker(
            markerId: const MarkerId('captain'),
            position: loc,
            infoWindow: InfoWindow(title: _captainName),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        };
      });
      _updateCaptainPolyline();
    });
  }

  void _updateCaptainPolyline() {
    if (_captainLocation == null || _deal == null) return;
    final pickupLat = (_deal!['passengerPickupLat'] ?? 0).toDouble();
    final pickupLng = (_deal!['passengerPickupLng'] ?? 0).toDouble();
    if (pickupLat == 0 && pickupLng == 0) return;
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('captain_to_pickup'),
          points: [_captainLocation!, LatLng(pickupLat, pickupLng)],
          color: AppColors.midnightBlue,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    });
  }

  void _subscribeDealStream() {
    if (_dealId == null) return;
    _dealSub?.cancel();
    _dealSub = FirebaseFirestore.instance
        .collection('deals')
        .doc(_dealId)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists || !mounted) return;
      final data = <String, dynamic>{'id': snap.id, ...?snap.data()};
      final prevStatus = _dealStatus;
      setState(() => _deal = {...?_deal, ...data});
      if (data['status'] == 'started' && prevStatus != 'started') {
        _startLocationTrackingIfNeeded();
      }
      if (_deal?['ride'] == null && _rideId != null) {
        await _loadDealOnce();
      }
    });
  }

  void _startCaptainLocationUpdates() {
    _captainLocationTimer?.cancel();
    _captainLocationTimer =
        Timer.periodic(const Duration(seconds: 15), (_) async {
          if (_rideId == null) return;
          try {
            final pos = await Geolocator.getCurrentPosition();
            await ApiService.patch('/rides/$_rideId/location', {
              'lat': pos.latitude,
              'lng': pos.longitude,
            });
          } catch (_) {}
        });
  }

  void _startLocationTrackingIfNeeded() {
    if (_rideId == null) return;
    _locationService.listenCaptainOnRide(
      rideId: _rideId!,
      onLocation: (loc) {
        if (loc == null || !mounted) return;
        setState(() {
          _captainLocation = loc;
          _markers = {
            ..._markers.where((m) => m.markerId.value != 'captain'),
            Marker(
              markerId: const MarkerId('captain'),
              position: loc,
              infoWindow: InfoWindow(title: _captainName),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
            ),
          };
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(loc));
      },
    );
  }

  Future<void> _cancelBooking() async {
    if (_dealId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text(
          'Are you sure you want to cancel? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .cancelDeal(_dealId!);
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Booking cancelled');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Cancel failed: $e', isError: true);
      }
    }
  }

  Future<void> _startRideAsCaptain() async {
    if (_dealId == null || _rideId == null) return;
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .startDeal(_dealId!);
      _locationService.startCaptainTracking(_rideId!);
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Ride started for this passenger');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Start failed: $e', isError: true);
      }
    }
  }

  Future<void> _initMap() async {
    // Get passenger current location
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _defaultLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {}

    // If ride has coordinates, add markers
    if (_deal != null) {
      final ride = _deal!['ride'] as Map<String, dynamic>? ?? {};
      final startLat = (ride['startLat'] ?? 0.0).toDouble();
      final startLng = (ride['startLng'] ?? 0.0).toDouble();

      _refreshPassengerMarkers();

      // Move camera to start location if available
      if (startLat != 0.0 && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(startLat, startLng), 13),
        );
      }
    }
  }

  void _triggerSOS() {
    setState(() => _showSosConfirm = true);
  }

  // Helper method to open WhatsApp using url_launcher
  void openWhatsApp(BuildContext context, String phone) async {
    if (phone.isEmpty) {
      AppHelpers.showSnackBar(context, 'Phone number not available');
      return;
    }
    // Remove any non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) {
      AppHelpers.showSnackBar(context, 'Invalid phone number');
      return;
    }
    // Add country code if not present
    final formattedPhone =
    cleanPhone.startsWith('92') ? cleanPhone : '92$cleanPhone';
    final url = 'https://wa.me/$formattedPhone';

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppHelpers.showSnackBar(context, 'Could not open WhatsApp');
      }
    } catch (e) {
      AppHelpers.showSnackBar(context, 'Error opening WhatsApp', isError: true);
    }
  }

  Widget _buildCustomerRequestRide(BuildContext context) {
    final req = _customerRequest!;
    final captainName = (req['acceptedCaptainName'] ?? 'Captain').toString();
    final phone = (req['acceptedCaptainPhone'] ?? '').toString();
    final start = req['startLocation']?.toString() ?? '';
    final end = req['endLocation']?.toString() ?? '';
    final fare = req['finalFare'] ?? req['desiredFare'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Active ride'),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition:
              CameraPosition(target: _defaultLocation, zoom: 14),
              markers: _markers,
              myLocationEnabled: true,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Captain is on the way',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.midnightBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(captainName,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('$start → $end',
                    style: const TextStyle(color: AppColors.dustyBlue)),
                if (fare != null)
                  Text(
                    'Agreed fare: Rs $fare',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightBlue,
                    ),
                  ),
                const SizedBox(height: 12),
                if (phone.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => dialPhone(context, phone),
                    icon: const Icon(Icons.call),
                    label: const Text('Call Captain'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dealSub?.cancel();
    _rideDealsSub?.cancel();
    _rideSub?.cancel();
    _captainLocationTimer?.cancel();
    _locationService.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: SkeletonList(item: RideCardSkeleton(), count: 2),
      );
    }

    if (_customerRequestMode && _customerRequest != null) {
      return _buildCustomerRequestRide(context);
    }

    final screenHeight = MediaQuery.of(context).size.height;

    // ✅ Get rideMode for Share/Solo label
    final isShareRide = _rideMode.toLowerCase() != 'solo';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _defaultLocation,
                zoom: 13,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _initMap();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dark.withValues(alpha: 0.02),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusHeaderColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusHeaderLabel,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // SOS Button
                  GestureDetector(
                    onTap: _triggerSOS,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.sos,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.sos.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom ride card with scroll fix
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: const Border(
                    top: BorderSide(color: AppColors.line, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dark.withValues(alpha: 0.02),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Bold Share/Solo label at the top
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color:
                          (isShareRide ? Colors.green : Colors.deepOrange)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isShareRide ? 'SHARE RIDE' : 'SOLO RIDE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: isShareRide
                                ? Colors.green[800]
                                : Colors.deepOrange[800],
                          ),
                        ),
                      ),

                      // Captain info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              _captainInitial,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _captainName,
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: AppColors.primary, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _vehicle.isNotEmpty
                                            ? _vehicle
                                            : 'Vehicle details',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Call button
                          GestureDetector(
                            onTap: () => dialPhone(context, _captainPhone),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: AppColors.line),
                      const SizedBox(height: 24),

                      // Route progress
                      Row(
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.circle,
                                  color: AppColors.success, size: 10),
                              Container(
                                  width: 1.5,
                                  height: 36,
                                  color: AppColors.line),
                              const Icon(Icons.circle,
                                  color: AppColors.primary, size: 10),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_start,
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    )),
                                const SizedBox(height: 24),
                                Text(_end,
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _captainLocation != null
                                      ? 'Captain live'
                                      : 'Waiting for captain',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (_captainLocation != null)
                                  Text(
                                    _captainDistanceLabel,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Fare chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoChip(
                            icon: Icons.payments_rounded,
                            label:
                            'Rs ${_fare.toStringAsFixed(0)}  •  Agreed fare',
                          ),
                          GestureDetector(
                            onTap: () => openWhatsApp(context, _captainPhone),
                            child: const _InfoChip(
                              icon: Icons.chat_rounded,
                              label: 'WhatsApp',
                            ),
                          ),
                        ],
                      ),

                      if (_rideId != null && !_isCaptain)
                        CoRidersSection(
                          rideId: _rideId!,
                          currentUserId:
                          Provider.of<UserProvider>(context, listen: false)
                              .user
                              ?.id,
                        ),
                      if (_dealId != null) ...[
                        const SizedBox(height: 16),
                        DealChatPanel(dealId: _dealId!, height: 160),
                      ],

                      const SizedBox(height: 24),

                      if (_isCaptain &&
                          (_dealStatus == 'confirmed' ||
                              _dealStatus == 'started')) ...[
                        if (_confirmedPassengers.isNotEmpty) ...[
                          const Text(
                            'Confirmed passengers',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._confirmedPassengers.map((p) {
                            final dealId = p['dealId']?.toString() ?? '';
                            final name = p['customerName']?.toString() ??
                                p['firstName']?.toString() ??
                                'Passenger';
                            final pickup =
                                p['passengerPickupAddress']?.toString() ?? '';
                            final phone = p['customerPhone']?.toString() ?? '';
                            final status =
                            (p['boardingStatus']?.toString() ?? 'waiting');
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  Text(pickup,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      )),
                                  if (phone.trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                dialPhone(context, phone),
                                            icon:
                                            const Icon(Icons.call_outlined),
                                            label: const Text('Call'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                openWhatsApp(context, phone),
                                            icon:
                                            const Icon(Icons.chat_outlined),
                                            label: const Text('WhatsApp'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.moss,
                                              foregroundColor: AppColors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Step 1: captain reached passenger pickup
                                      if (status == 'waiting')
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: dealId.isEmpty
                                                ? null
                                                : () => _setBoarding(
                                                dealId, 'arrived'),
                                            child: const Text('Mark Arrived'),
                                          ),
                                        ),
                                      // Step 2: passenger boarded
                                      if (status == 'arrived')
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: dealId.isEmpty
                                                ? null
                                                : () => _setBoarding(
                                                dealId, 'boarded'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.bark,
                                              foregroundColor: AppColors.white,
                                            ),
                                            child: const Text('Picked Up'),
                                          ),
                                        ),
                                      // Step 3: dropped off
                                      if (status == 'boarded') ...[
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: dealId.isEmpty
                                                ? null
                                                : () => _setBoarding(
                                                dealId, 'dropped'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.moss,
                                              foregroundColor: AppColors.white,
                                            ),
                                            child: const Text('Dropped'),
                                          ),
                                        ),
                                      ],
                                      if (status == 'dropped')
                                        const Expanded(
                                          child: Text(
                                            'Passenger dropped',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppColors.moss,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                      ],
                      if (_isCaptain && _dealStatus == 'confirmed') ...[
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _startRideAsCaptain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bark,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Start Ride',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                )),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!_isCaptain && canCancelDeal(_dealStatus))
                        TextButton(
                          onPressed: _cancelBooking,
                          child: const Text('Cancel booking',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      if (!_isCaptain &&
                          (_deal?['boardingStatus']?.toString() == 'boarded' ||
                              _dealStatus == 'started'))
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_deal?['boardingStatus']?.toString() ==
                                'boarded' ||
                                _dealStatus == 'started')
                                ? () async {
                              try {
                                if (_dealId != null) {
                                  await Provider.of<FirestoreService>(
                                      context,
                                      listen: false)
                                      .completeDeal(_dealId!);
                                }
                              } catch (e) {
                                if (mounted) {
                                  AppHelpers.showSnackBar(
                                    context,
                                    'Error: $e',
                                    isError: true,
                                  );
                                }
                                return;
                              }
                              if (mounted) {
                                Navigator.pushNamed(
                                    context, '/rate-review',
                                    arguments: _dealId);
                              }
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.moss,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor:
                              AppColors.sage.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              (_deal?['boardingStatus']?.toString() ==
                                  'boarded' ||
                                  _dealStatus == 'started')
                                  ? 'I have arrived'
                                  : 'Waiting to board',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // SOS Confirmation overlay
          if (_showSosConfirm)
            Positioned.fill(
              child: Container(
                color: AppColors.dark.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.line, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Send SOS Alert?',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'This will alert emergency contacts\nand share your live location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _showSosConfirm = false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textDark,
                                  side: const BorderSide(color: AppColors.line),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Cancel',
                                    style:
                                    TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _showSosConfirm = false);
                                  AppHelpers.showSnackBar(
                                    context,
                                    'SOS Alert Sent to Emergency Contacts!',
                                    isError: true,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Send SOS',
                                    style:
                                    TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// _InfoChip widget - defined as a separate widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
