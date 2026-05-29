import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_widgets.dart';
import '../../utils/captain_profile_utils.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/ride_service.dart';
import '../../widgets/places_autocomplete_field.dart';

class PostRideScreen extends StatefulWidget {
  const PostRideScreen({super.key});
  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _fareCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '1');
  final _descCtrl = TextEditingController();
  final _exactLocationCtrl = TextEditingController();
  final _exactDropLocationCtrl = TextEditingController();

  String _rideType = 'random';
  String _rideMode = 'share';
  bool _isLoading = false;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _isRecurring = false;

  double _startLat = 0.0;
  double _startLng = 0.0;
  double _endLat = 0.0;
  double _endLng = 0.0;
  GoogleMapController? _mapController;
  bool _mapTapSetsDrop = false;

  final _types = ['office', 'random', 'delivery', 'tour'];

  String get _aiSuggestedFare => 'Rs 120';

  String _vehicleTypeForCaptain(UserModel? user) {
    final saved = (user?.captainVehicleType ?? '').trim().toLowerCase();
    if (['car', 'bike', 'bus', 'truck', 'shazore'].contains(saved)) {
      return saved;
    }
    return 'car';
  }

  int _vehicleSeatLimit(UserModel? user) {
    final seats = user?.vehicleSeats ?? 0;
    return seats > 0 ? seats : 60;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('type')) {
        setState(() => _rideType = args['type']);
      }
      final seats =
          Provider.of<UserProvider>(context, listen: false).user?.vehicleSeats;
      if (seats != null && seats > 0) {
        _seatsCtrl.text = seats.toString();
      }
    });
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fareCtrl.dispose();
    _seatsCtrl.dispose();
    _descCtrl.dispose();
    _exactLocationCtrl.dispose();
    _exactDropLocationCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _routeMarkers() {
    return {
      if (_startLat != 0.0 && _startLng != 0.0)
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(_startLat, _startLng),
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      if (_endLat != 0.0 && _endLng != 0.0)
        Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(_endLat, _endLng),
          infoWindow: const InfoWindow(title: 'Drop'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };
  }

  LatLng get _mapCenter {
    if (_startLat != 0.0 && _startLng != 0.0)
      return LatLng(_startLat, _startLng);
    if (_endLat != 0.0 && _endLng != 0.0) return LatLng(_endLat, _endLng);
    return const LatLng(31.5204, 74.3587);
  }

  Future<String> _labelForLatLng(LatLng latLng) async {
    try {
      final marks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      ).timeout(const Duration(seconds: 4));
      if (marks.isEmpty) return '';
      final p = marks.first;
      return [
        p.name,
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
      ].where((v) => (v ?? '').trim().isNotEmpty).join(', ');
    } catch (_) {
      return '';
    }
  }

  Future<void> _selectMapPoint(LatLng latLng) async {
    if (_mapTapSetsDrop) {
      _endLat = latLng.latitude;
      _endLng = latLng.longitude;
      final label = await _labelForLatLng(latLng);
      if (label.isNotEmpty) _toCtrl.text = label;
    } else {
      _startLat = latLng.latitude;
      _startLng = latLng.longitude;
      final label = await _labelForLatLng(latLng);
      if (label.isNotEmpty) _fromCtrl.text = label;
    }
    if (!mounted) return;
    setState(() {});
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  Future<void> _useCurrentPickupLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      _startLat = pos.latitude;
      _startLng = pos.longitude;
      try {
        final marks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude)
                .timeout(const Duration(seconds: 4));
        if (marks.isNotEmpty) {
          final p = marks.first;
          final label = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((v) => (v ?? '').trim().isNotEmpty).join(', ');
          if (label.isNotEmpty) _fromCtrl.text = label;
        }
      } catch (_) {}
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Pickup location added from GPS');
        setState(() {});
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(_startLat, _startLng)),
        );
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Could not get current location: $e',
            isError: true);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.moss,
            onPrimary: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final rideService = Provider.of<RideService>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        AppHelpers.showSnackBar(context, 'User not found', isError: true);
        return;
      }

      if (!CaptainProfileUtils.isVerified(user)) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Verification required'),
              content: const Text(
                'Your documents are under review. You will be notified once verified.',
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK')),
              ],
            ),
          );
        }
        return;
      }

      if (!CaptainProfileUtils.isProfileComplete(user)) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Profile incomplete'),
              content: const Text(
                'Complete your captain profile (photo, vehicle, CNIC, city) from the home screen checklist before posting rides.',
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK')),
              ],
            ),
          );
        }
        return;
      }

      final departureTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );
      if (!departureTime.isAfter(DateTime.now())) {
        AppHelpers.showSnackBar(
          context,
          'Select a future date and time for the ride.',
          isError: true,
        );
        return;
      }

      if (_startLat == 0.0 ||
          _startLng == 0.0 ||
          _endLat == 0.0 ||
          _endLng == 0.0) {
        AppHelpers.showSnackBar(
          context,
          'Select From and To from map, current location, or autocomplete suggestions.',
          isError: true,
        );
        return;
      }

      final seatCount = int.tryParse(_seatsCtrl.text) ?? 1;
      final maxVehicleSeats = _vehicleSeatLimit(user);
      if (_rideType == 'tour' && seatCount > maxVehicleSeats) {
        AppHelpers.showSnackBar(
          context,
          'Tour seats cannot exceed your registered vehicle seats ($maxVehicleSeats).',
          isError: true,
        );
        return;
      }

      await rideService.postRide(
        startLocation: _fromCtrl.text.trim(),
        endLocation: _toCtrl.text.trim(),
        suggestedFare: double.tryParse(_fareCtrl.text) ?? 0.0,
        totalSeats: seatCount,
        rideType: _rideType,
        vehicleType: _vehicleTypeForCaptain(user),
        rideMode: _rideMode,
        departureTime: departureTime.toUtc().toIso8601String(),
        acceptsDelivery: _rideType == 'delivery',
        startLat: _startLat,
        startLng: _startLng,
        endLat: _endLat,
        endLng: _endLng,
        exactLocation: _exactLocationCtrl.text.trim(),
        exactDropLocation: _exactDropLocationCtrl.text.trim(),
        tourType: _rideType == 'tour' ? _rideMode : null,
        maxPassengers: _rideType == 'tour' ? seatCount : null,
      );

      if (mounted) {
        AppHelpers.showSnackBar(context, 'Ride posted successfully!');
        Navigator.pushReplacementNamed(context, '/my-rides');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().contains('429')
            ? 'Too many requests. Please wait a moment.'
            : e.toString();
        AppHelpers.showSnackBar(context, errorMsg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bark, AppColors.moss],
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
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
                              color: AppColors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Post a Ride',
                                style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                            Text('Fill your empty seats',
                                style: TextStyle(
                                    color: Color(0xAAFFFFFF), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Route Card
                          _SectionCard(
                            title: 'Route',
                            child: Column(
                              children: [
                                PlacesAutocompleteField(
                                  controller: _fromCtrl,
                                  label: 'From',
                                  icon: Icons.my_location_rounded,
                                  onChanged: (_) {
                                    _startLat = 0.0;
                                    _startLng = 0.0;
                                  },
                                  onPlaceSelected: (latLng) {
                                    _startLat = latLng.latitude;
                                    _startLng = latLng.longitude;
                                    setState(() {});
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLng(latLng),
                                    );
                                  },
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Enter pickup'
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: _useCurrentPickupLocation,
                                    icon: const Icon(Icons.gps_fixed_rounded,
                                        size: 18),
                                    label: const Text('Use current pickup'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                PlacesAutocompleteField(
                                  controller: _toCtrl,
                                  label: 'To',
                                  icon: Icons.location_on_outlined,
                                  onChanged: (_) {
                                    _endLat = 0.0;
                                    _endLng = 0.0;
                                  },
                                  onPlaceSelected: (latLng) {
                                    _endLat = latLng.latitude;
                                    _endLng = latLng.longitude;
                                    setState(() {});
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLng(latLng),
                                    );
                                  },
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Enter destination'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment(
                                      value: false,
                                      icon: Icon(Icons.trip_origin_rounded),
                                      label: Text('Map sets From'),
                                    ),
                                    ButtonSegment(
                                      value: true,
                                      icon: Icon(Icons.place_rounded),
                                      label: Text('Map sets To'),
                                    ),
                                  ],
                                  selected: {_mapTapSetsDrop},
                                  onSelectionChanged: (values) {
                                    setState(
                                      () => _mapTapSetsDrop = values.first,
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: 170,
                                    child: GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: _mapCenter,
                                        zoom: 13,
                                      ),
                                      onMapCreated: (controller) =>
                                          _mapController = controller,
                                      markers: _routeMarkers(),
                                      myLocationEnabled: true,
                                      myLocationButtonEnabled: false,
                                      zoomControlsEnabled: false,
                                      onTap: _selectMapPoint,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _exactLocationCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Exact pickup note',
                                    hintText:
                                        'e.g. Main gate, Street 4, near mosque',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _exactDropLocationCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Exact drop note',
                                    hintText:
                                        'e.g. Office gate, building entrance',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      final temp = _fromCtrl.text;
                                      _fromCtrl.text = _toCtrl.text;
                                      _toCtrl.text = temp;
                                      final tempLat = _startLat;
                                      final tempLng = _startLng;
                                      _startLat = _endLat;
                                      _startLng = _endLng;
                                      _endLat = tempLat;
                                      _endLng = tempLng;
                                      setState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.moss.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.swap_vert_rounded,
                                          color: AppColors.moss, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Ride Type Card
                          _SectionCard(
                            title: 'Ride Type',
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _types.map((t) {
                                final selected = _rideType == t;
                                return GestureDetector(
                                  onTap: () => setState(() => _rideType = t),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.moss
                                          : AppColors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.moss
                                            : AppColors.sage.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      t[0].toUpperCase() + t.substring(1),
                                      style: TextStyle(
                                        color: selected
                                            ? AppColors.white
                                            : AppColors.sage,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 14),

                          _SectionCard(
                            title: 'Ride Mode',
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: ['share', 'solo'].map((mode) {
                                final selected = _rideMode == mode;
                                return ChoiceChip(
                                  label: Text(mode[0].toUpperCase() +
                                      mode.substring(1)),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(() {
                                      _rideMode = mode;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Fare & Seats Card
                          _SectionCard(
                            title: 'Fare & Seats',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.moss.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded,
                                          color: AppColors.moss, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'AI suggests: $_aiSuggestedFare based on distance',
                                          style: const TextStyle(
                                              color: AppColors.bark,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _fareCtrl.text = '120',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                              color: AppColors.moss,
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: const Text('Use',
                                              style: TextStyle(
                                                  color: AppColors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppField(
                                  controller: _fareCtrl,
                                  label: 'Your fare (Rs)',
                                  icon: Icons.payments_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Enter fare';
                                    if (double.tryParse(v) == null)
                                      return 'Enter valid amount';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _seatsCtrl,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Enter seats';
                                    final n = int.tryParse(v);
                                    final user = Provider.of<UserProvider>(
                                      context,
                                      listen: false,
                                    ).user;
                                    final limit = _rideType == 'tour'
                                        ? _vehicleSeatLimit(user)
                                        : 60;
                                    if (n == null || n < 1 || n > limit) {
                                      return '1 to $limit seats';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Available seats',
                                    prefixIcon:
                                        const Icon(Icons.event_seat_rounded),
                                    helperText: _rideMode == 'solo'
                                        ? 'Solo booking, but seats can match your vehicle'
                                        : _rideType == 'tour'
                                            ? 'Tour seats cannot exceed your registered vehicle'
                                            : null,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Schedule Card
                          _SectionCard(
                            title: 'Schedule',
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _pickDate,
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: AppColors.bg,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: AppColors.sage
                                                    .withOpacity(0.3),
                                                width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.calendar_today_rounded,
                                                  color: AppColors.moss,
                                                  size: 18),
                                              const SizedBox(width: 10),
                                              Text(
                                                '${_date.day}/${_date.month}/${_date.year}',
                                                style: const TextStyle(
                                                    color: AppColors.bark,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: _time,
                                            builder: (context, child) => Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme:
                                                    const ColorScheme.light(
                                                        primary: AppColors.moss,
                                                        onPrimary:
                                                            AppColors.white),
                                              ),
                                              child: child!,
                                            ),
                                          );
                                          if (picked != null)
                                            setState(() => _time = picked);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: AppColors.bg,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: AppColors.sage
                                                    .withOpacity(0.3),
                                                width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.access_time_rounded,
                                                  color: AppColors.moss,
                                                  size: 18),
                                              const SizedBox(width: 10),
                                              Text(
                                                _time.format(context),
                                                style: const TextStyle(
                                                    color: AppColors.bark,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Recurring Ride',
                                            style: TextStyle(
                                                color: AppColors.bark,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        Text('Repeat for daily commute',
                                            style: TextStyle(
                                                color: AppColors.sage,
                                                fontSize: 12)),
                                      ],
                                    ),
                                    Switch.adaptive(
                                      value: _isRecurring,
                                      onChanged: (v) =>
                                          setState(() => _isRecurring = v),
                                      activeColor: AppColors.moss,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          if (_rideType == 'tour') ...[
                            const SizedBox(height: 14),
                            _SectionCard(
                              title: 'Tour Details',
                              child: AppField(
                                controller: _descCtrl,
                                label: 'Tour Description',
                                hintText:
                                    'e.g. Lahore to Murree, scenic route, AC car',
                                icon: Icons.description_outlined,
                                maxLines: 3,
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _post,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: AppColors.white)
                                  : Text(
                                      _rideType == 'tour'
                                          ? 'Create Tour Event'
                                          : 'Post Ride',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map Picker Sheet ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
