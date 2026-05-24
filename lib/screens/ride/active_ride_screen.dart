import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/deal_status_utils.dart';
import '../../services/firestore_service.dart';
import '../../services/location_tracking_service.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/deal_chat_panel.dart';
import '../../widgets/co_riders_section.dart';
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
  List<Map<String, dynamic>> _confirmedPassengers = [];
  bool _isCaptain = false;

  String get _captainName =>
      _deal?['captain']?['name'] ?? _deal?['ride']?['captainName'] ?? 'Captain';
  String get _start => _deal?['ride']?['startLocation'] ?? '';
  String get _end => _deal?['ride']?['endLocation'] ?? '';
  double get _fare => (_deal?['agreedFare'] ?? 0).toDouble();
  String get _vehicle {
    final rideInfo = _deal?['ride']?['vehicleInfo'];
    final fromRide = RideModel.formatVehicleInfo(rideInfo);
    if (fromRide.isNotEmpty) return fromRide;
    final c = _deal?['captain'] as Map<String, dynamic>?;
    if (c == null) return '';
    return '${c['vehicleMake'] ?? ''} ${c['vehicleModel'] ?? ''} ${c['vehicleColor'] ?? ''} ${c['vehicleRegistration'] ?? ''}'.trim();
  }

  String get _captainPhone {
    final c = _deal?['captain'] as Map<String, dynamic>?;
    return c?['phone']?.toString() ?? '';
  }

  String get _dealStatus => _deal?['status']?.toString() ?? '';

  String get _statusHeaderLabel => dealStatusLabel(_dealStatus);

  Color get _statusHeaderColor => dealStatusColor(_dealStatus);

  String get _captainInitial =>
      _captainName.isNotEmpty ? _captainName[0].toUpperCase() : 'C';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _rideId = args?['rideId']?.toString();
      _dealId = args?['dealId']?.toString();
      final user = Provider.of<UserProvider>(context, listen: false).user;
      _isCaptain = user?.role == 'captain';
      await _loadDealOnce();
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $e')));
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ));
      }
    }

    if (_isCaptain) {
      for (final p in _confirmedPassengers) {
        final lat = (p['passengerPickupLat'] ?? 0).toDouble();
        final lng = (p['passengerPickupLng'] ?? 0).toDouble();
        if (lat == 0 && lng == 0) continue;
        final dealId = p['dealId']?.toString() ?? p['id']?.toString() ?? '';
        final boarded = p['boardingStatus'] == 'boarded';
        final dropped = p['boardingStatus'] == 'dropped';
        markers.add(Marker(
          markerId: MarkerId('p_$dealId'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: p['customerName']?.toString() ?? p['firstName']?.toString() ?? 'Passenger',
            snippet: p['passengerPickupAddress']?.toString(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            dropped
                ? BitmapDescriptor.hueViolet
                : boarded
                    ? BitmapDescriptor.hueGreen
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
      final deal = await Provider.of<FirestoreService>(context, listen: false).getDeal(_dealId!);
      if (mounted) {
        setState(() {
          _deal = deal;
          _loading = false;
          _rideId ??= deal['rideId']?.toString();
        });
      }
      await _initMap();
      _startLocationTrackingIfNeeded();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
        content: const Text('Your booking will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await Provider.of<FirestoreService>(context, listen: false).cancelDeal(_dealId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
      }
    }
  }

  Future<void> _startRideAsCaptain() async {
    if (_dealId == null || _rideId == null) return;
    try {
      await Provider.of<FirestoreService>(context, listen: false).startDeal(_dealId!);
      _locationService.startCaptainTracking(_rideId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride started — passengers notified')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Start failed: $e')));
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
      final endLat = (ride['endLat'] ?? 0.0).toDouble();
      final endLng = (ride['endLng'] ?? 0.0).toDouble();

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

  @override
  void dispose() {
    _dealSub?.cancel();
    _rideDealsSub?.cancel();
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color:        AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusHeaderColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusHeaderLabel,
                          style: const TextStyle(
                            color:      AppColors.textDark,
                            fontSize:   12,
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
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color:        AppColors.sos,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:      AppColors.sos.withOpacity(0.3),
                            blurRadius: 15,
                            offset:     const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            color:      AppColors.white,
                            fontSize:   14,
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

          // Bottom ride card
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                border: const Border(top: BorderSide(color: Color(0xFFCCBFA3), width: 1)),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.02),
                    blurRadius: 30,
                    offset:     const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Captain info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          _captainInitial,
                          style: const TextStyle(
                            color:      AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize:   20,
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
                                const Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _vehicle.isNotEmpty ? _vehicle : 'Vehicle details',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
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
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color:        AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.phone_rounded,
                            color: AppColors.primary, size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Color(0xFFCCBFA3)),
                  const SizedBox(height: 24),

                  // Route progress
                  Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.circle, color: Color(0xFF4A7C59), size: 10),
                          Container(
                              width: 1.5, height: 36, color: const Color(0xFFCCBFA3)),
                          const Icon(Icons.circle, color: AppColors.primary, size: 10),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_start, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 24),
                            Text(_end, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:        AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _captainLocation != null ? 'Captain nearby' : 'Waiting for captain',
                          style: const TextStyle(
                            color:      AppColors.primary,
                            fontSize:   12,
                            fontWeight: FontWeight.w800,
                          ),
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
                        label: 'Rs ${_fare.toStringAsFixed(0)}  •  Agreed fare',
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Live location sharing enabled')));
                        },
                        child: const _InfoChip(
                          icon:  Icons.share_location_rounded,
                          label: 'Share Live',
                        ),
                      ),
                    ],
                  ),

                  if (_rideId != null && !_isCaptain)
                    CoRidersSection(
                      rideId: _rideId!,
                      currentUserId: Provider.of<UserProvider>(context, listen: false).user?.id,
                    ),
                  if (_dealId != null) ...[
                    const SizedBox(height: 16),
                    DealChatPanel(dealId: _dealId!, height: 160),
                  ],

                  const SizedBox(height: 24),

                  if (_isCaptain && (_dealStatus == 'confirmed' || _dealStatus == 'started')) ...[
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
                        final name = p['customerName']?.toString() ?? p['firstName']?.toString() ?? 'Passenger';
                        final pickup = p['passengerPickupAddress']?.toString() ?? '';
                        final status = p['boardingStatus']?.toString() ?? 'waiting';
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
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(pickup, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (status != 'boarded' && status != 'dropped')
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: dealId.isEmpty
                                            ? null
                                            : () => _setBoarding(dealId, 'boarded'),
                                        child: const Text('Boarded'),
                                      ),
                                    ),
                                  if (status == 'boarded') ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: dealId.isEmpty
                                            ? null
                                            : () => _setBoarding(dealId, 'dropped'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.moss,
                                          foregroundColor: AppColors.white,
                                        ),
                                        child: const Text('Dropped'),
                                      ),
                                    ),
                                  ],
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Start Ride', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!_isCaptain && canCancelDeal(_dealStatus))
                    TextButton(
                      onPressed: _cancelBooking,
                      child: const Text('Cancel booking', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                    ),
                  if (!_isCaptain && (_dealStatus == 'started' || _dealStatus == 'confirmed'))
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _dealStatus == 'started'
                            ? () async {
                                try {
                                  if (_dealId != null) {
                                    await Provider.of<FirestoreService>(context, listen: false)
                                        .completeDeal(_dealId!);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')));
                                  }
                                  return;
                                }
                                if (mounted) {
                                  Navigator.pushNamed(context, '/rate-review',
                                      arguments: _dealId);
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.moss,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.sage.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          _dealStatus == 'started'
                              ? 'Complete Ride'
                              : 'Waiting for captain to start',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // SOS Confirmation overlay
          if (_showSosConfirm)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color:        AppColors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color:        AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.primary, size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Send SOS Alert?',
                          style: TextStyle(
                            color:      AppColors.textDark,
                            fontSize:   22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'This will alert emergency contacts\nand share your live location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted, fontSize: 15,
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
                                  side: const BorderSide(color: Color(0xFFCCBFA3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ElevatedButton(
                                  onPressed: () {
                                    setState(() => _showSosConfirm = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('SOS Alert Sent to Emergency Contacts!'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: const Text(
                                    'Send SOS',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary, fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


