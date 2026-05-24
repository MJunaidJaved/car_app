import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/places_autocomplete_field.dart';
import '../../utils/captain_profile_utils.dart';
import '../../models/ride_model.dart';
import '../../providers/user_provider.dart';
import '../../services/ride_service.dart';

class PostRideScreen extends StatefulWidget {
  const PostRideScreen({super.key});
  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _fromCtrl  = TextEditingController();
  final _toCtrl    = TextEditingController();
  final _fareCtrl  = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '1');
  final _descCtrl  = TextEditingController();

  String    _rideType    = 'office';
  bool      _isLoading   = false;
  DateTime  _date        = DateTime.now();
  TimeOfDay _time        = const TimeOfDay(hour: 8, minute: 0);
  bool      _isRecurring = false;

  double _startLat = 0.0;
  double _startLng = 0.0;
  double _endLat   = 0.0;
  double _endLng   = 0.0;

  final _types = ['office', 'random', 'delivery', 'tour'];

  String get _aiSuggestedFare => 'Rs 120';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('type')) {
        setState(() => _rideType = args['type']);
      }
      final seats = Provider.of<UserProvider>(context, listen: false)
          .user
          ?.vehicleSeats;
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
    super.dispose();
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

  Future<void> _pickLocationOnMap({required bool isStart}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    LatLng initial = LatLng(position.latitude, position.longitude);

    if (!mounted) return;

    final confirmed = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MapPickerSheet(initialPosition: initial),
    );

    if (confirmed == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        confirmed.latitude,
        confirmed.longitude,
      );
      final place = placemarks.first;
      final address =
          '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}';
      setState(() {
        if (isStart) {
          _startLat = confirmed.latitude;
          _startLng = confirmed.longitude;
          _fromCtrl.text = address;
        } else {
          _endLat = confirmed.latitude;
          _endLng = confirmed.longitude;
          _toCtrl.text = address;
        }
      });
    } catch (_) {
      setState(() {
        if (isStart) {
          _startLat = confirmed.latitude;
          _startLng = confirmed.longitude;
        } else {
          _endLat = confirmed.latitude;
          _endLng = confirmed.longitude;
        }
      });
    }
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final rideService  = Provider.of<RideService>(context, listen: false);
      final user         = userProvider.currentUser;

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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
        }
        return;
      }

      if (_startLat == 0.0 && _startLng == 0.0) {
        AppHelpers.showSnackBar(
          context,
          'Select pickup from location suggestions',
          isError: true,
        );
        return;
      }
      if (_endLat == 0.0 && _endLng == 0.0) {
        AppHelpers.showSnackBar(
          context,
          'Select destination from location suggestions',
          isError: true,
        );
        return;
      }

      final departureTime = DateTime(
        _date.year, _date.month, _date.day,
        _time.hour, _time.minute,
      );

      await rideService.postRide(
        startLocation:   _fromCtrl.text.trim(),
        endLocation:     _toCtrl.text.trim(),
        suggestedFare:   double.tryParse(_fareCtrl.text) ?? 0.0,
        totalSeats:      int.tryParse(_seatsCtrl.text) ?? 1,
        rideType:        _rideType,
        departureTime:   departureTime.toIso8601String(),
        acceptsDelivery: _rideType == 'delivery',
        startLat:        _startLat,
        startLng:        _startLng,
        endLat:          _endLat,
        endLng:          _endLng,
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
            top: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bark, AppColors.moss],
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
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.white, size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Post a Ride', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                            Text('Fill your empty seats', style: TextStyle(color: Color(0xAAFFFFFF), fontSize: 13)),
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
                                  validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Enter pickup' : null,
                                  onPlaceSelected: (latLng) {
                                    setState(() {
                                      _startLat = latLng.latitude;
                                      _startLng = latLng.longitude;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                PlacesAutocompleteField(
                                  controller: _toCtrl,
                                  label: 'To',
                                  icon: Icons.location_on_outlined,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Enter destination'
                                      : null,
                                  onPlaceSelected: (latLng) {
                                    setState(() {
                                      _endLat = latLng.latitude;
                                      _endLng = latLng.longitude;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      final temp = _fromCtrl.text;
                                      _fromCtrl.text = _toCtrl.text;
                                      _toCtrl.text = temp;
                                      final tmpLat = _startLat;
                                      final tmpLng = _startLng;
                                      setState(() {
                                        _startLat = _endLat;
                                        _startLng = _endLng;
                                        _endLat = tmpLat;
                                        _endLng = tmpLng;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.moss.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.swap_vert_rounded, color: AppColors.moss, size: 20),
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
                              spacing: 10, runSpacing: 10,
                              children: _types.map((t) {
                                final selected = _rideType == t;
                                return GestureDetector(
                                  onTap: () => setState(() => _rideType = t),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected ? AppColors.moss : AppColors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected ? AppColors.moss : AppColors.sage.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      t[0].toUpperCase() + t.substring(1),
                                      style: TextStyle(
                                        color: selected ? AppColors.white : AppColors.sage,
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
                                      const Icon(Icons.auto_awesome_rounded, color: AppColors.moss, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'AI suggests: $_aiSuggestedFare based on distance',
                                          style: const TextStyle(color: AppColors.bark, fontSize: 13, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _fareCtrl.text = '120',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(color: AppColors.moss, borderRadius: BorderRadius.circular(8)),
                                          child: const Text('Use', style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w800)),
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
                                    if (v == null || v.isEmpty) return 'Enter fare';
                                    if (double.tryParse(v) == null) return 'Enter valid amount';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                AppField(
                                  controller: _seatsCtrl,
                                  label: 'Available seats',
                                  icon: Icons.event_seat_rounded,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Enter seats';
                                    final n = int.tryParse(v);
                                    if (n == null || n < 1 || n > 6) return '1 to 6 seats';
                                    return null;
                                  },
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
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: AppColors.sage.withOpacity(0.3), width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.calendar_today_rounded, color: AppColors.moss, size: 18),
                                              const SizedBox(width: 10),
                                              Text(
                                                '${_date.day}/${_date.month}/${_date.year}',
                                                style: const TextStyle(color: AppColors.bark, fontSize: 14, fontWeight: FontWeight.w700),
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
                                                colorScheme: const ColorScheme.light(primary: AppColors.moss, onPrimary: AppColors.white),
                                              ),
                                              child: child!,
                                            ),
                                          );
                                          if (picked != null) setState(() => _time = picked);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: AppColors.bg,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: AppColors.sage.withOpacity(0.3), width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.access_time_rounded, color: AppColors.moss, size: 18),
                                              const SizedBox(width: 10),
                                              Text(
                                                _time.format(context),
                                                style: const TextStyle(color: AppColors.bark, fontSize: 14, fontWeight: FontWeight.w700),
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Recurring Ride', style: TextStyle(color: AppColors.bark, fontWeight: FontWeight.w700, fontSize: 14)),
                                        Text('Repeat for daily commute', style: TextStyle(color: AppColors.sage, fontSize: 12)),
                                      ],
                                    ),
                                    Switch.adaptive(
                                      value: _isRecurring,
                                      onChanged: (v) => setState(() => _isRecurring = v),
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
                                hintText: 'e.g. Lahore to Murree, scenic route, AC car',
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
                                  ? const CircularProgressIndicator(color: AppColors.white)
                                  : Text(
                                _rideType == 'tour' ? 'Create Tour Event' : 'Post Ride',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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

class _MapPickerSheet extends StatefulWidget {
  final LatLng initialPosition;
  const _MapPickerSheet({required this.initialPosition});

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  late LatLng _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.sage.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap to select location',
            style: TextStyle(color: AppColors.bark, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.initialPosition,
                  zoom: 14,
                ),
                onTap: (latLng) => setState(() => _selected = latLng),
                markers: {
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: _selected,
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.moss,
                foregroundColor: AppColors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────

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
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.dark, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}