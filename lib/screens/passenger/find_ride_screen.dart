import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/ride_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/places_autocomplete_field.dart';
import '../../widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────
class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});
  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  GoogleMapController? _mapController;

  // State
  bool _mapMode = false; // false = list view, true = map view
  bool _showResultsList = false;
  bool _isSearching = false;
  final bool _pickingDrop = false; // which pin is being placed
  List<RideModel> _results = [];
  String? _lastDocId;
  bool _hasMore = false;
  bool _loadingMore = false;
  final _listScrollCtrl = ScrollController();
  RideModel? _selectedRide; // tapped marker
  String _selectedType = 'all';
  String _rideModeFilter = 'all';

  // Location
  LatLng _center = const LatLng(31.5204, 74.3587); // Lahore default
  LatLng? _fromLatLng;
  LatLng? _toLatLng;

  // Map UI
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  late AnimationController _sheetAnim;
  late Animation<double> _sheetSlide;

  // Map picking mode — crosshair pin on center
  bool _mapPicking = false;
  bool _pickingPickup = false;

  @override
  void initState() {
    super.initState();
    _sheetAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _sheetSlide =
        CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic);
    _listScrollCtrl.addListener(_onListScroll);
    _getUserLocation().then((_) {
      if (mounted) _search();
    });
  }

  void _onListScroll() {
    if (!_hasMore || _loadingMore || _isSearching) return;
    if (_listScrollCtrl.position.pixels <
        _listScrollCtrl.position.maxScrollExtent - 200) {
      return;
    }
    _loadMore();
  }

  @override
  void dispose() {
    _listScrollCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _mapController?.dispose();
    _sheetAnim.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────
  Future<void> _getUserLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final loc = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _center = loc);
      _mapController?.animateCamera(CameraUpdate.newLatLng(loc));
    } catch (_) {}
  }

  Future<void> _useCurrentAsPickup() async {
    await _getUserLocation();
    setState(() {
      _fromLatLng = _center;
      _fromCtrl.text = 'Current location';
    });
    _updateMarkers();
  }

  // ── Search ────────────────────────────────
  Future<void> _loadMore() async {
    if (_lastDocId == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final rideService = Provider.of<RideService>(context, listen: false);
      final searchPoint = _fromLatLng ?? _center;
      final page = await rideService.findRidesPage(
        startLocation: _fromLatLng == null ? _fromCtrl.text.trim() : null,
        endLocation: _toCtrl.text.trim().isEmpty ? null : _toCtrl.text.trim(),
        type: _selectedType,
        rideMode: _rideModeFilter,
        userLat: searchPoint.latitude,
        userLng: searchPoint.longitude,
        afterDocId: _lastDocId,
      );
      if (!mounted) return;
      setState(() {
        _results = [..._results, ...page.rides];
        _hasMore = page.hasMore;
        _lastDocId = page.lastDocId;
        _loadingMore = false;
      });
      _updateMarkers();
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _search() async {
    setState(() {
      _isSearching = true;
      _selectedRide = null;
      _lastDocId = null;
      _hasMore = false;
    });
    _sheetAnim.reverse();

    try {
      final rideService = Provider.of<RideService>(context, listen: false);
      final searchPoint = _fromLatLng ?? _center;

      final page = await rideService.findRidesPage(
        startLocation: _fromLatLng == null ? _fromCtrl.text.trim() : null,
        endLocation: _toCtrl.text.trim().isEmpty ? null : _toCtrl.text.trim(),
        type: _selectedType,
        rideMode: _rideModeFilter,
        userLat: searchPoint.latitude,
        userLng: searchPoint.longitude,
      );
      final results = page.rides;

      results.sort((a, b) {
        final da = AppHelpers.distanceKm(
          searchPoint.latitude,
          searchPoint.longitude,
          a.startLat,
          a.startLng,
        );
        final db = AppHelpers.distanceKm(
          searchPoint.latitude,
          searchPoint.longitude,
          b.startLat,
          b.startLng,
        );
        return da.compareTo(db);
      });

      setState(() {
        _results = results;
        _hasMore = page.hasMore;
        _lastDocId = page.lastDocId;
        _showResultsList = !_mapMode && results.isNotEmpty;
      });
      _updateMarkers();

      // Fit all markers on map
      if (_mapMode && results.isNotEmpty) {
        _fitMarkersOnMap(results);
      }

      if (results.isEmpty && mounted) {
        AppHelpers.showSnackBar(context, 'No rides found');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Search failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ── Markers ───────────────────────────────
  void _updateMarkers() {
    final markers = <Marker>{};

    for (final ride in _results) {
      if (ride.startLat == 0.0 && ride.startLng == 0.0) continue;
      final isSelected = _selectedRide?.id == ride.id;
      markers.add(Marker(
        markerId: MarkerId(ride.id),
        position: LatLng(ride.startLat, ride.startLng),
        icon: isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () => _onMarkerTapped(ride),
        zIndexInt: isSelected ? 2 : 1,
      ));
    }

    // Pickup pin
    if (_fromLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('__pickup__'),
        position: _fromLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Your Pickup'),
        zIndexInt: 3,
      ));
    }

    // Drop pin
    if (_toLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('__drop__'),
        position: _toLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Your Drop'),
        zIndexInt: 3,
      ));
    }

    // Polyline pickup to drop
    final polylines = <Polyline>{};
    if (_fromLatLng != null && _toLatLng != null) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [_fromLatLng!, _toLatLng!],
        color: AppColors.primary,
        width: 3,
        patterns: [PatternItem.dash(16), PatternItem.gap(8)],
      ));
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  void _onMarkerTapped(RideModel ride) {
    setState(() => _selectedRide = ride);
    _updateMarkers();
    _sheetAnim.forward();
    _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(ride.startLat, ride.startLng), 14));
  }

  void _fitMarkersOnMap(List<RideModel> rides) {
    if (rides.isEmpty) return;
    double minLat = rides.first.startLat;
    double maxLat = rides.first.startLat;
    double minLng = rides.first.startLng;
    double maxLng = rides.first.startLng;
    for (final r in rides) {
      minLat = math.min(minLat, r.startLat);
      maxLat = math.max(maxLat, r.startLat);
      minLng = math.min(minLng, r.startLng);
      maxLng = math.max(maxLng, r.startLng);
    }
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01)),
      80,
    ));
  }

  // ── Map picking mode ──────────────────────
  void _startMapPicking(bool pickupMode) {
    setState(() {
      _mapPicking = true;
      _pickingPickup = pickupMode;
      _mapMode = true;
    });
  }

  void _confirmMapPin() {
    if (_pickingPickup) {
      setState(() {
        _fromLatLng = _center;
        _fromCtrl.text = 'Map pin';
        _mapPicking = false;
      });
    } else {
      setState(() {
        _toLatLng = _center;
        _toCtrl.text = 'Map pin';
        _mapPicking = false;
      });
    }
    _updateMarkers();
  }



  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final user = Provider.of<UserProvider>(context).user;
    final isFemale = (user?.gender ?? '').toLowerCase() == 'female';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _showResultsList
          ? _buildResultsListView(isFemale)
          : (_mapMode ? _buildMapView(isFemale) : _buildListView(isFemale)),
    );
  }

  Widget _buildResultsListView(bool isFemale) {
    final fromText = _fromCtrl.text.isEmpty ? 'Current Location' : _fromCtrl.text;
    final toText = _toCtrl.text.isEmpty ? 'Anywhere' : _toCtrl.text;

    return Stack(
      children: [
        // Header gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 220,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showResultsList = false),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search Results',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$fromText ➔ $toText',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _mapMode = true;
                          _showResultsList = false;
                        });
                        if (_results.isNotEmpty) _fitMarkersOnMap(_results);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.map_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Map',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Results view
              Expanded(
                child: ListView.builder(
                  controller: _listScrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: _results.length + 1 + (_loadingMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_loadingMore && i == _results.length + 1) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 8),
                        child: Row(
                          children: [
                            const Text(
                              'Available Rides',
                              style: TextStyle(
                                  color: AppColors.bark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                '${_results.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final ride = _results[i - 1];
                    return _RideResultCard(
                      ride: ride,
                      onBookNow: () => Navigator.pushNamed(
                        context,
                        '/fare-negotiate',
                        arguments: ride,
                      ),
                      onViewOnMap: () {
                        setState(() {
                          _selectedRide = ride;
                          _mapMode = true;
                          _showResultsList = false;
                        });
                        _sheetAnim.forward();
                        _updateMarkers();
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(LatLng(ride.startLat, ride.startLng)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  //  MAP VIEW
  // ─────────────────────────────────────────
  Widget _buildMapView(bool isFemale) {
    return Stack(
      children: [
        // Full-screen map
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 13),
          onMapCreated: (c) {
            _mapController = c;
            if (_results.isNotEmpty) _fitMarkersOnMap(_results);
          },
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onCameraMove: (pos) {
            _center = pos.target;
          },
          onTap: (_) {
            if (_selectedRide != null) {
              setState(() => _selectedRide = null);
              _sheetAnim.reverse();
              _updateMarkers();
            }
          },
        ),

        // Crosshair pin for map picking mode
        if (_mapPicking)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _pickingPickup
                        ? 'Move map to set pickup'
                        : 'Move map to set drop',
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  Icons.location_pin,
                  size: 48,
                  color: _pickingPickup ? AppColors.primary : AppColors.error,
                ),
                const SizedBox(height: 48), // offset for pin base
              ],
            ),
          ),

        // Top bar
        SafeArea(
          child: Column(
            children: [
              _buildMapTopBar(),
              if (!_mapPicking) _buildMapSearchCard(),
            ],
          ),
        ),

        // Confirm pin button
        if (_mapPicking)
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: ElevatedButton.icon(
              onPressed: _confirmMapPin,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _pickingPickup ? 'Set this as Pickup' : 'Set this as Drop',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
          ),

        // My location button
        if (!_mapPicking)
          Positioned(
            bottom: _selectedRide != null ? 310 : 40,
            right: 16,
            child: _MapFab(
              icon: Icons.my_location,
              onTap: _getUserLocation,
            ),
          ),

        // Search button (when no ride selected)
        if (!_mapPicking && _selectedRide == null)
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _search,
              icon: _isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.search_rounded),
              label: Text(
                _isSearching
                    ? 'Searching...'
                    : 'Search Rides (${_results.length} found)',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
          ),

        // Ride preview sheet from tapped marker
        if (_selectedRide != null && !_mapPicking)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(_sheetSlide),
              child: _RidePreviewSheet(
                ride: _selectedRide!,
                onClose: () {
                  setState(() => _selectedRide = null);
                  _sheetAnim.reverse();
                  _updateMarkers();
                },
                onBookNow: () => Navigator.pushNamed(
                  context,
                  '/fare-negotiate',
                  arguments: _selectedRide,
                ),
              ),
            ),
          ),

        // Results count badge
        if (!_mapPicking && _results.isNotEmpty && _selectedRide == null)
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.dark.withValues(alpha:0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_results.length} ride${_results.length == 1 ? '' : 's'} found - tap a pin',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _MapFab(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if (_mapPicking) {
                setState(() => _mapPicking = false);
              } else {
                setState(() => _mapMode = false);
              }
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha:0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.moss, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fromCtrl.text.isEmpty
                          ? 'Tap to search rides'
                          : '${_fromCtrl.text} to ${_toCtrl.text.isEmpty ? 'anywhere' : _toCtrl.text}',
                      style: const TextStyle(
                          color: AppColors.bark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _MapFab(
            icon: Icons.list_rounded,
            onTap: () => setState(() => _mapMode = false),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSearchCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            // Pickup row
            Row(
              children: [
                const Icon(Icons.trip_origin,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _fromCtrl.text.isEmpty ? 'Pickup location' : _fromCtrl.text,
                    style: TextStyle(
                      color: _fromCtrl.text.isEmpty
                          ? AppColors.sage
                          : AppColors.bark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _startMapPicking(true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Pin',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _useCurrentAsPickup,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.gps_fixed,
                        color: AppColors.primary, size: 16),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, color: AppColors.line),
            ),
            // Drop row
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _toCtrl.text.isEmpty
                        ? 'Drop location (optional)'
                        : _toCtrl.text,
                    style: TextStyle(
                      color: _toCtrl.text.isEmpty
                          ? AppColors.sage
                          : AppColors.bark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _startMapPicking(false),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Pin',
                        style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                if (_toLatLng != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() {
                      _toLatLng = null;
                      _toCtrl.clear();
                      _updateMarkers();
                    }),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.sage),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  LIST VIEW
  // ─────────────────────────────────────────
  Widget _buildListView(bool isFemale) {
    return Stack(
      children: [
        // Header gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 300,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('Find a Ride',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _mapMode = true),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.map_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Search card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.dark.withValues(alpha:0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    children: [
                      PlacesAutocompleteField(
                        controller: _fromCtrl,
                        label: 'Pickup location',
                        icon: Icons.trip_origin,
                        onChanged: (_) => _fromLatLng = null,
                        onPlaceSelected: (latLng) {
                          _fromLatLng = latLng;
                          _center = latLng;
                          _mapController
                              ?.animateCamera(CameraUpdate.newLatLng(latLng));
                          _updateMarkers();
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: _useCurrentAsPickup,
                            icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                            label: const Text('Use current location'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _mapMode = true);
                              _startMapPicking(true);
                            },
                            icon: const Icon(Icons.pin_drop_outlined, size: 16),
                            label: const Text('Pin on map'),
                          ),
                        ],
                      ),
                      PlacesAutocompleteField(
                        controller: _toCtrl,
                        label: 'Drop location (optional)',
                        icon: Icons.location_on_outlined,
                        onChanged: (_) => _toLatLng = null,
                        onPlaceSelected: (latLng) {
                          _toLatLng = latLng;
                          _updateMarkers();
                        },
                      ),
                      const SizedBox(height: 8),
                      // Mini map preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 130,
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                    target: _fromLatLng ?? _center, zoom: 13),
                                onMapCreated: (c) => _mapController = c,
                                markers: _markers,
                                polylines: _polylines,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                                onTap: (latLng) {
                                  setState(() {
                                    _fromLatLng = latLng;
                                    _center = latLng;
                                    _fromCtrl.text = 'Map pin';
                                  });
                                  _mapController?.animateCamera(
                                      CameraUpdate.newLatLng(latLng));
                                  _updateMarkers();
                                },
                              ),
                              // Expand to full map button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _mapMode = true),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha:0.15),
                                          blurRadius: 8,
                                        )
                                      ],
                                    ),
                                    child: const Icon(Icons.fullscreen,
                                        size: 18, color: AppColors.bark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSearching ? null : _search,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Search Rides',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Vehicle type filter
              _buildTypeFilter(isFemale),
              const SizedBox(height: 12),

              // Ride mode chips
              _buildModeChips(),
              const SizedBox(height: 10),

              // Results
              Expanded(child: _buildResultsList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilter(bool isFemale) {
    final types = [
      'all',
      'car',
      'bike',
      'bus',
      'truck',
      'shazore',
      if (isFemale) 'ladies'
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final t = types[i];
          final sel = _selectedType == t;
          return GestureDetector(
            onTap: () async {
              setState(() => _selectedType = t);
              await _search();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: sel
                        ? AppColors.primary
                        : AppColors.sage.withValues(alpha:0.3)),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha:0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Text(
                t[0].toUpperCase() + t.substring(1),
                style: TextStyle(
                    color: sel ? Colors.white : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final m in ['all', 'share', 'solo']) ...[
          ChoiceChip(
            label: Text(m[0].toUpperCase() + m.substring(1)),
            selected: _rideModeFilter == m,
            onSelected: (_) async {
              setState(() => _rideModeFilter = m);
              await _search();
            },
          ),
          if (m != 'solo') const SizedBox(width: 10),
        ]
      ],
    );
  }

  Widget _buildResultsList() {
    if (_isSearching) {
      return const SkeletonList(item: RideCardSkeleton(), count: 4);
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_rounded,
                color: AppColors.sage.withValues(alpha:0.4), size: 64),
            const SizedBox(height: 12),
            const Text('No rides found nearby',
                style: TextStyle(
                    color: AppColors.bark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text(
              'Post your route request so captains near you can send fare offers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/customer-request'),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Post Ride Request'),
            ),
          ]),
        ),
      );
    }
    return ListView.builder(
      controller: _listScrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _results.length + 1 + (_loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (_loadingMore && i == _results.length + 1) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Row(children: [
              const Text('Available Rides',
                  style: TextStyle(
                      color: AppColors.bark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${_results.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              // View on map button
              GestureDetector(
                onTap: () async {
                  setState(() => _mapMode = true);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (_results.isNotEmpty) _fitMarkersOnMap(_results);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.map_outlined,
                          color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text('View on map',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ]),
          );
        }
        final ride = _results[i - 1];
        return _RideResultCard(
          ride: ride,
          onBookNow: () =>
              Navigator.pushNamed(context, '/fare-negotiate', arguments: ride),
          onViewOnMap: () {
            setState(() {
              _mapMode = true;
              _selectedRide = ride;
            });
            _updateMarkers();
            _sheetAnim.forward();
            Future.delayed(const Duration(milliseconds: 200), () {
              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
                  LatLng(ride.startLat, ride.startLng), 15));
            });
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Ride Preview Sheet (shown when marker tapped)
// ─────────────────────────────────────────────
class _RidePreviewSheet extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onClose;
  final VoidCallback onBookNow;

  const _RidePreviewSheet({
    required this.ride,
    required this.onClose,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final isFemale = (user?.gender ?? '').toLowerCase() == 'female';
    final isFull = ride.isFull;
    final isLadiesLocked = ride.isLadiesRide && !isFemale;
    final dateLabel = ride.displayDeparture.isNotEmpty
        ? ride.displayDeparture
        : AppHelpers.formatDateTime(ride.departureTime);
    final vehicleLabel = ride.displayVehicle.isNotEmpty
        ? ride.displayVehicle
        : ride.vehicleType.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Captain row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final dummyUserModel = UserModel(
                      id: ride.captainId,
                      email: '',
                      name: ride.captainName,
                      phone: ride.captainPhone ?? '',
                      role: 'captain',
                      vehicleModel: ride.vehicleInfo ?? '',
                      vehicleRegistration: '',
                      vehicleSeats: ride.totalSeats,
                      vehiclePhotoUrl: ride.vehiclePhotoUrl,
                      captainVehicleType: ride.vehicleType,
                      rating: ride.captainRating,
                      totalRides: 0,
                      createdAt: DateTime.now(),
                    );
                    Navigator.pushNamed(context, '/profile', arguments: dummyUserModel);
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(alpha:0.1),
                        child: Text(
                            AppHelpers.nameInitial(ride.captainName, fallback: 'C'),
                            style: const TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ride.captainName,
                                style: const TextStyle(
                                    color: AppColors.bark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.primary, size: 14),
                              const SizedBox(width: 4),
                              Text('${ride.captainRating}',
                                  style: const TextStyle(
                                      color: AppColors.sage,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: AppColors.sage)),
            ],
          ),

          const SizedBox(height: 14),

          if ((ride.vehiclePhotoUrl ?? '').trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: ride.vehiclePhotoUrl!.trim(),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 150,
                  color: AppColors.surfaceBlue,
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: AppColors.moss,
                    size: 42,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(ride.startLocation.isEmpty ? 'From' : ride.startLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.bark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: AppColors.primary, size: 22),
                ),
                Expanded(
                  child: Text(ride.endLocation.isEmpty ? 'To' : ride.endLocation,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.bark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Chip(Icons.access_time_rounded, dateLabel),
              _Chip(Icons.event_seat_rounded, ride.seatsLabel),
              _Chip(Icons.directions_car_outlined, vehicleLabel),
              Text('Rs ${ride.suggestedFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (isFull || isLadiesLocked) ? null : onBookNow,
              icon: const Icon(Icons.price_change_outlined),
              label: Text(
                isLadiesLocked
                    ? 'Female passengers only'
                    : isFull
                        ? 'Ride Full'
                        : 'Book Now',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Ride Result Card (list view)
// ─────────────────────────────────────────────
class _RideResultCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onBookNow;
  final VoidCallback onViewOnMap;

  const _RideResultCard({
    required this.ride,
    required this.onBookNow,
    required this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final isFemale = (user?.gender ?? '').toLowerCase() == 'female';
    final isFull = ride.isFull;
    final isLadiesLocked = ride.isLadiesRide && !isFemale;
    final dateLabel = ride.departureDisplay != null && ride.departureDisplay!.isNotEmpty
        ? ride.departureDisplay!
        : AppHelpers.formatDateTime(ride.departureTime);
    final vehicleLabel = ride.displayVehicle.isNotEmpty
        ? ride.displayVehicle
        : ride.vehicleType.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha:0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha:0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Captain
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final dummyUserModel = UserModel(
                      id: ride.captainId,
                      email: '',
                      name: ride.captainName,
                      phone: ride.captainPhone ?? '',
                      role: 'captain',
                      vehicleModel: ride.vehicleInfo ?? '',
                      vehicleRegistration: '',
                      vehicleSeats: ride.totalSeats,
                      vehiclePhotoUrl: ride.vehiclePhotoUrl,
                      captainVehicleType: ride.vehicleType,
                      rating: ride.captainRating,
                      totalRides: 0,
                      createdAt: DateTime.now(),
                    );
                    Navigator.pushNamed(context, '/profile', arguments: dummyUserModel);
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(alpha:0.1),
                        child: Text(
                            AppHelpers.nameInitial(ride.captainName, fallback: 'C'),
                            style: const TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ride.captainName,
                                style: const TextStyle(
                                    color: AppColors.bark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.primary, size: 14),
                              const SizedBox(width: 4),
                              Text('${ride.captainRating}',
                                  style: const TextStyle(
                                      color: AppColors.sage,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // View on map button
              GestureDetector(
                onTap: onViewOnMap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_outlined,
                      color: AppColors.primary, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isFull
                      ? AppColors.error.withValues(alpha:0.1)
                      : AppColors.accent.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(ride.seatsLabel,
                    style: TextStyle(
                        color: isFull ? AppColors.error : AppColors.bark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),

          if (ride.isLadiesRide) ...[
            const SizedBox(height: 10),
            const _Chip(Icons.woman_2_outlined, 'Ladies Ride'),
          ],

          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.sage.withValues(alpha:0.2)),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(ride.startLocation.isEmpty ? 'From' : ride.startLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.bark,
                          fontSize: 15,
                          fontWeight: FontWeight.w900)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: AppColors.primary, size: 24),
                ),
                Expanded(
                  child: Text(ride.endLocation.isEmpty ? 'To' : ride.endLocation,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.bark,
                          fontSize: 15,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          if ((ride.exactLocation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('From exact: ${ride.exactLocation}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
          if ((ride.exactDropLocation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('To exact: ${ride.exactDropLocation}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],

          const SizedBox(height: 16),

          // Bottom info
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(Icons.access_time_rounded, dateLabel),
                    _Chip(Icons.event_seat_rounded, ride.seatsLabel),
                    _Chip(Icons.directions_car_outlined, vehicleLabel),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Amber background
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                ),
                child: Text(
                  'Rs ${ride.suggestedFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFB45309), // Amber text
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (isFull || isLadiesLocked) ? null : onBookNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.price_change_outlined),
              label: Text(
                isLadiesLocked ? 'Female passengers only' : 'Book Now',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Small helpers
// ─────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.accent.withValues(alpha: 0.12);
    Color fg = AppColors.bark;

    if (icon == Icons.access_time_rounded) {
      bg = const Color(0xFFE0F2FE); // sky blue
      fg = const Color(0xFF0369A1);
    } else if (icon == Icons.event_seat_rounded) {
      bg = const Color(0xFFDCFCE7); // green
      fg = const Color(0xFF15803D);
    } else if (icon == Icons.woman_2_outlined) {
      bg = const Color(0xFFFCE7F3); // pink
      fg = const Color(0xFFBE185D);
    } else if (icon == Icons.directions_car_outlined) {
      bg = const Color(0xFFF3E8FF); // purple
      fg = const Color(0xFF7E22CE);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.12),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(icon, color: AppColors.bark, size: 20),
      ),
    );
  }
}
