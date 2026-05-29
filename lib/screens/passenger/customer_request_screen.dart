import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/ride_model.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/places_autocomplete_field.dart';

class CustomerRequestScreen extends StatefulWidget {
  const CustomerRequestScreen({super.key});

  @override
  State<CustomerRequestScreen> createState() => _CustomerRequestScreenState();
}

class _ResolvedLocation {
  final double lat;
  final double lng;

  const _ResolvedLocation({required this.lat, required this.lng});
}

class _CustomerRequestScreenState extends State<CustomerRequestScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _dropPointCtrl = TextEditingController();
  DateTime _requestedAt = DateTime.now().add(const Duration(hours: 1));
  bool _loading = true;
  bool _posting = false;
  List<Map<String, dynamic>> _requests = [];
  GoogleMapController? _mapController;
  LatLng _mapCenter = const LatLng(31.5204, 74.3587);
  LatLng? _fromLatLng;
  LatLng? _toLatLng;
  bool _mapTapSetsDrop = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMine();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadMine(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _pickupCtrl.dispose();
    _dropPointCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<Position?> _position() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Set<Marker> _requestMarkers() {
    return {
      if (_fromLatLng != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: _fromLatLng!,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      if (_toLatLng != null)
        Marker(
          markerId: const MarkerId('drop'),
          position: _toLatLng!,
          infoWindow: const InfoWindow(title: 'Drop'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };
  }

  Future<void> _useCurrentPickup() async {
    final pos = await _position();
    if (pos == null) return;
    final latLng = LatLng(pos.latitude, pos.longitude);
    _fromLatLng = latLng;
    _mapCenter = latLng;
    _fromCtrl.text = 'Current location';
    try {
      final marks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      ).timeout(const Duration(seconds: 4));
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
      setState(() {});
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    }
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
      _toLatLng = latLng;
      final label = await _labelForLatLng(latLng);
      if (label.isNotEmpty) _toCtrl.text = label;
    } else {
      _fromLatLng = latLng;
      _mapCenter = latLng;
      final label = await _labelForLatLng(latLng);
      if (label.isNotEmpty) _fromCtrl.text = label;
    }
    if (!mounted) return;
    setState(() {});
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  Future<void> _loadMine({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final res = await ApiService.get('/customer-requests/my');
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(res['requests'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postRequest() async {
    if (_fromCtrl.text.trim().isEmpty ||
        _toCtrl.text.trim().isEmpty ||
        _posting) {
      AppHelpers.showSnackBar(
        context,
        'Please enter both From and To locations.',
        isError: true,
      );
      return;
    }
    if (_fromLatLng == null || _toLatLng == null) {
      AppHelpers.showSnackBar(
        context,
        'Select both From and To on the map or autocomplete before posting.',
        isError: true,
      );
      return;
    }
    setState(() => _posting = true);
    try {
      final pos = await _position();
      final fromLocation = _ResolvedLocation(
        lat: _fromLatLng!.latitude,
        lng: _fromLatLng!.longitude,
      );
      final toLocation = _ResolvedLocation(
        lat: _toLatLng!.latitude,
        lng: _toLatLng!.longitude,
      );
      await ApiService.post('/customer-requests', {
        'startLocation': _fromCtrl.text.trim(),
        'endLocation': _toCtrl.text.trim(),
        'pickupLocation': _pickupCtrl.text.trim().isNotEmpty
            ? _pickupCtrl.text.trim()
            : _fromCtrl.text.trim(),
        if (_dropPointCtrl.text.trim().isNotEmpty)
          'dropLocation': _dropPointCtrl.text.trim(),
        'requestedAt': _requestedAt.toUtc().toIso8601String(),
        'startLat': fromLocation.lat,
        'startLng': fromLocation.lng,
        'endLat': toLocation.lat,
        'endLng': toLocation.lng,
        if (pos != null) 'customerLat': pos.latitude,
        if (pos != null) 'customerLng': pos.longitude,
      });
      _fromCtrl.clear();
      _toCtrl.clear();
      _pickupCtrl.clear();
      _dropPointCtrl.clear();
      _fromLatLng = null;
      _toLatLng = null;
      await _loadMine();
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Request posted. Captains notified.');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Post failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: _requestedAt,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_requestedAt),
    );
    if (time == null) return;
    setState(() {
      _requestedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<Map<String, dynamic>?> _responseDialog({
    required String title,
    required String pickupInitial,
    bool askCounter = false,
  }) async {
    final pickupCtrl = TextEditingController(text: pickupInitial);
    final counterCtrl = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pickupCtrl,
              decoration: const InputDecoration(
                labelText: 'Exact pickup point',
                hintText: 'e.g. House gate, shop name, street',
                border: OutlineInputBorder(),
              ),
            ),
            if (askCounter) ...[
              const SizedBox(height: 12),
              TextField(
                controller: counterCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Adjust fare',
                  prefixText: 'Rs ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pickup = pickupCtrl.text.trim();
              final counter =
                  askCounter ? double.tryParse(counterCtrl.text.trim()) : null;
              if (pickup.isEmpty) return;
              if (askCounter && (counter == null || counter <= 0)) return;
              Navigator.pop(ctx, {
                'pickupLocation': pickup,
                if (counter != null) 'counterFare': counter,
              });
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    pickupCtrl.dispose();
    counterCtrl.dispose();
    return result;
  }

  Future<void> _respond(
    String requestId,
    String offerId,
    String action, {
    required String pickupInitial,
  }) async {
    final payload = await _responseDialog(
      title: action == 'accept' ? 'Done with this fare' : 'Counter offer',
      pickupInitial: pickupInitial,
      askCounter: action == 'counter',
    );
    if (payload == null) return;
    try {
      await ApiService.patch('/customer-requests/$requestId/offers/$offerId', {
        'action': action,
        'pickupLocation': payload['pickupLocation'],
        if (action == 'counter') 'counterFare': payload['counterFare'],
      });
      await _loadMine();
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Action failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Post Ride Request'),
        backgroundColor: AppColors.bark,
        foregroundColor: AppColors.white,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: NotificationBell(
              iconColor: AppColors.white,
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMine(showLoading: false),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  PlacesAutocompleteField(
                    controller: _fromCtrl,
                    label: 'From',
                    icon: Icons.trip_origin,
                    onChanged: (_) {
                      _fromLatLng = null;
                    },
                    onPlaceSelected: (latLng) {
                      setState(() {
                        _fromLatLng = latLng;
                        _mapCenter = latLng;
                      });
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(latLng),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _useCurrentPickup,
                      icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                      label: const Text('Use current pickup'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PlacesAutocompleteField(
                    controller: _toCtrl,
                    label: 'To',
                    icon: Icons.location_on_outlined,
                    onChanged: (_) {
                      _toLatLng = null;
                    },
                    onPlaceSelected: (latLng) {
                      setState(() => _toLatLng = latLng);
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(latLng),
                      );
                    },
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
                      setState(() => _mapTapSetsDrop = values.first);
                    },
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 170,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _mapCenter,
                          zoom: 13,
                        ),
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        markers: _requestMarkers(),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        onTap: _selectMapPoint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pickupCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Exact pickup point',
                      hintText: 'e.g. Main gate, shop name, street',
                    ),
                  ),
                  TextField(
                    controller: _dropPointCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Exact drop point',
                      hintText: 'e.g. Office gate, building entrance',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Day and time'),
                    subtitle: Text(
                      '${_requestedAt.day}/${_requestedAt.month}/${_requestedAt.year} ${_requestedAt.hour.toString().padLeft(2, '0')}:${_requestedAt.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: TextButton(
                      onPressed: _pickDateTime,
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _posting ? null : _postRequest,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(_posting ? 'Posting...' : 'Post request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.moss,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'My Posted Requests',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_requests.isEmpty)
              const Text(
                'No posted requests yet.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              ..._requests.map(_requestCard),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final start = RideModel.formatLocationLabel(request['startLocation']);
    final end = RideModel.formatLocationLabel(request['endLocation']);
    final pickup = RideModel.formatLocationLabel(request['pickupLocation']);
    final drop = RideModel.formatLocationLabel(request['dropLocation']);
    final offers = List<Map<String, dynamic>>.from(request['offers'] ?? []);
    offers.sort((a, b) {
      final aFare =
          double.tryParse((a['counterFare'] ?? a['fare'] ?? 0).toString()) ?? 0;
      final bFare =
          double.tryParse((b['counterFare'] ?? b['fare'] ?? 0).toString()) ?? 0;
      return aFare.compareTo(bFare);
    });
    final acceptedPhone = (request['acceptedCaptainPhone'] ?? '').toString();
    final requestedAt = DateTime.tryParse(
      (request['requestedAt'] ?? '').toString(),
    );
    final requestedLabel = requestedAt == null
        ? '-'
        : '${requestedAt.toLocal().day}/${requestedAt.toLocal().month}/${requestedAt.toLocal().year} ${TimeOfDay.fromDateTime(requestedAt.toLocal()).format(context)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${start.isEmpty ? 'From' : start} -> ${end.isEmpty ? 'To' : end}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (pickup.isNotEmpty)
            Text(
              'Exact pickup: $pickup',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          if (drop.isNotEmpty)
            Text(
              'Exact drop: $drop',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          Text(
            'Time: $requestedLabel',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          Text('Status: ${(request['status'] ?? '').toString().toUpperCase()}'),
          if (acceptedPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Captain: $acceptedPhone',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => dialPhone(context, acceptedPhone),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
                TextButton.icon(
                  onPressed: () => openWhatsApp(context, acceptedPhone),
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          ...offers.map((offer) {
            final offerId = (offer['id'] ?? '').toString();
            final requestId = (request['id'] ?? '').toString();
            final pickupInitial = pickup.isNotEmpty ? pickup : start;
            final vehicle = (offer['captainVehicleInfo'] ??
                    offer['captainVehicleType'] ??
                    '')
                .toString()
                .trim();
            final registration =
                (offer['captainVehicleRegistration'] ?? '').toString().trim();
            final seats = (offer['availableSeats'] ?? '').toString();
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${offer['captainName'] ?? 'Captain'} offered Rs ${offer['fare']}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (vehicle.isNotEmpty)
                    Text(
                      'Vehicle: $vehicle',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  if (registration.isNotEmpty)
                    Text(
                      'Reg: $registration',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  if (seats.isNotEmpty && seats != 'null')
                    Text(
                      'Available seats: $seats',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  if ((offer['counterFare'] ?? '').toString().isNotEmpty)
                    Text('Counter: Rs ${offer['counterFare']}'),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _respond(
                            requestId,
                            offerId,
                            'counter',
                            pickupInitial: pickupInitial,
                          ),
                          child: const Text('Adjust Fare'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _respond(
                            requestId,
                            offerId,
                            'accept',
                            pickupInitial: pickupInitial,
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
