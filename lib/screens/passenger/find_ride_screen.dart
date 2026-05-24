import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/user_provider.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/places_autocomplete_field.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});
  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();
  String _selectedType = 'all';
  bool   _isSearching  = false;
  List<RideModel> _results = [];
  bool _showMap = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng _defaultLocation = const LatLng(31.5204, 74.3587);
  double _pickupLat = 0;
  double _pickupLng = 0;
  double _dropLat = 0;
  double _dropLng = 0;

  final _types = ['all', 'office', 'random', 'delivery', 'tour'];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _defaultLocation = LatLng(position.latitude, position.longitude));
        _mapController?.animateCamera(CameraUpdate.newLatLng(_defaultLocation));
      }
    } catch (_) {}
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    for (final ride in _results) {
      if (ride.startLat == 0.0 && ride.startLng == 0.0) continue;
      markers.add(Marker(
        markerId: MarkerId(ride.id),
        position: LatLng(ride.startLat, ride.startLng),
        infoWindow: InfoWindow(
          title: ride.captainName,
          snippet: '${ride.startLocation} → ${ride.endLocation} • Rs ${ride.suggestedFare}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onTap: () {
          Navigator.pushNamed(context, '/fare-negotiate', arguments: ride);
        },
      ));
    }
    setState(() => _markers = markers);
  }

  Future<void> _search() async {
    if (_fromCtrl.text.isEmpty || _toCtrl.text.isEmpty) {
      AppHelpers.showSnackBar(context, 'Please enter pickup and drop locations', isError: true);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final rideService = Provider.of<RideService>(context, listen: false);
      final results = await rideService.findRides(
        startLocation: _fromCtrl.text.trim(),
        endLocation:   _toCtrl.text.trim(),
        type: _selectedType == 'all' ? null : _selectedType,
      );
      setState(() => _results = results);
      _updateMarkers();
      if (results.isEmpty && mounted) {
        AppHelpers.showSnackBar(context, 'No rides found for this route');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Search failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.dark, AppColors.moss],
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text('Find a Ride', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _showMap = !_showMap),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _showMap ? Icons.list_rounded : Icons.map_rounded,
                            color: AppColors.white, size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.sage.withOpacity(0.3), width: 1),
                      boxShadow: [BoxShadow(color: AppColors.dark.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        PlacesAutocompleteField(
                          controller: _fromCtrl,
                          label: 'Pickup location',
                          icon: Icons.trip_origin,
                          onPlaceSelected: (latLng) {
                            setState(() {
                              _pickupLat = latLng.latitude;
                              _pickupLng = latLng.longitude;
                              _defaultLocation = latLng;
                            });
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(latLng),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        PlacesAutocompleteField(
                          controller: _toCtrl,
                          label: 'Drop location',
                          icon: Icons.location_on_outlined,
                          onPlaceSelected: (latLng) {
                            setState(() {
                              _dropLat = latLng.latitude;
                              _dropLng = latLng.longitude;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSearching ? null : _search,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.cream, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: _isSearching
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                                : const Text('Search Rides', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _types.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final t = _types[i];
                      final isSelected = _selectedType == t;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.sage.withOpacity(0.3)),
                          ),
                          child: Text(t[0].toUpperCase() + t.substring(1), style: TextStyle(color: isSelected ? AppColors.white : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: _showMap
                      ? Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _defaultLocation,
                                zoom: 13,
                              ),
                              onMapCreated: (controller) => _mapController = controller,
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: false,
                            ),
                            if (_results.isEmpty)
                              const Center(
                                child: Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Search rides to see them on map',
                                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : _results.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_rounded, color: AppColors.sage.withOpacity(0.4), size: 64),
                                  const SizedBox(height: 12),
                                  const Text('Search to find available rides', style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: _results.length + 1,
                              itemBuilder: (context, i) {
                                if (i == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                                    child: Row(
                                      children: [
                                        const Text('Available Rides', style: TextStyle(color: AppColors.bark, fontWeight: FontWeight.w800, fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                                          child: Text('${_results.length}', style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return _RideResultCard(ride: _results[i - 1]);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RideResultCard extends StatelessWidget {
  final RideModel ride;
  const _RideResultCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final vehicle = ride.displayVehicle;
    final isFull = ride.isFull;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sage.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: AppColors.bark.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 22, backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(ride.captainName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.captainName, style: const TextStyle(color: AppColors.bark, fontSize: 15, fontWeight: FontWeight.w800)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.primary, size: 14),
                        const SizedBox(width: 4),
                        Text('Rating ${ride.captainRating}', style: const TextStyle(color: AppColors.sage, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isFull ? Colors.red.withOpacity(0.1) : AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ride.seatsLabel,
                  style: TextStyle(
                    color: isFull ? Colors.red : AppColors.bark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          VehicleInfoChip(vehicleText: vehicle),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.sage.withOpacity(0.2)),
          const SizedBox(height: 20),
          Row(
            children: [
              Column(children: [const Icon(Icons.circle, color: AppColors.success, size: 10), Container(width: 1.5, height: 24, color: AppColors.sage.withOpacity(0.3)), const Icon(Icons.circle, color: AppColors.primary, size: 10)]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.startLocation, style: const TextStyle(color: AppColors.bark, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Text(ride.endLocation, style: const TextStyle(color: AppColors.bark, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _RideChip(icon: Icons.access_time_rounded, label: '${ride.departureTime.hour}:${ride.departureTime.minute.toString().padLeft(2, '0')}'),
              const SizedBox(width: 8),
              _RideChip(icon: Icons.event_seat_rounded, label: ride.seatsLabel),
              const Spacer(),
              Text('Rs ${ride.suggestedFare}', style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isFull ? null : () => Navigator.pushNamed(context, '/fare-negotiate', arguments: ride),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.cream, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(isFull ? 'Ride full' : 'Negotiate & Book', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isAlert;
  const _RideChip({required this.icon, required this.label, this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: isAlert ? AppColors.primary.withOpacity(0.1) : AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14, color: isAlert ? AppColors.primary : AppColors.bark), const SizedBox(width: 6), Text(label, style: TextStyle(color: isAlert ? AppColors.primary : AppColors.bark, fontSize: 12, fontWeight: FontWeight.w700))],
      ),
    );
  }
}
