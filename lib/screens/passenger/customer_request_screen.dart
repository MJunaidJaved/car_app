import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/ride_model.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/phone_utils.dart';
import '../../navigation/app_navigator.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/places_autocomplete_field.dart';
import '../../widgets/skeleton_loader.dart';
import '../map_picker_screen.dart';

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
  final _fareCtrl = TextEditingController();
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
  String _requestFilter = 'all';
  String? _waitingRequestId;
  bool _showPostForm = true;
  String? _fromError;
  String? _toError;
  String? _editingRequestId;

  String? _currentUserName(BuildContext context) {
    try {
      return Provider.of<UserProvider>(context).user?.name;
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMine();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (_waitingRequestId == null) {
          _loadMine(showLoading: false);
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _pickupCtrl.dispose();
    _dropPointCtrl.dispose();
    _fareCtrl.dispose();
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

  Future<LatLng?> _geocodeText(String value) async {
    final query = value.trim();
    if (query.isEmpty) return null;
    try {
      final locations =
          await locationFromAddress(query).timeout(const Duration(seconds: 5));
      if (locations.isEmpty) return null;
      return LatLng(locations.first.latitude, locations.first.longitude);
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
        final list = List<Map<String, dynamic>>.from(res['requests'] ?? []);
        setState(() {
          if (list.isNotEmpty || _requests.isEmpty) {
            _requests = list;
          }
          _loading = false;
          if (_waitingRequestId != null) {
            final still = _requests.any((r) => r['id'] == _waitingRequestId);
            if (!still && list.isNotEmpty) _waitingRequestId = null;
          }
        });
      }
    } catch (e) {
      debugPrint('CustomerRequestScreen: load mine failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _upsertPostedRequest(Map<String, dynamic> request) {
    final requestId = (request['id'] ?? '').toString();
    if (requestId.isEmpty) return;
    final next = List<Map<String, dynamic>>.from(_requests);
    final index =
        next.indexWhere((r) => (r['id'] ?? '').toString() == requestId);
    final normalized = <String, dynamic>{
      ...request,
      'offers': List<Map<String, dynamic>>.from(request['offers'] ?? const []),
    };
    if (index >= 0) {
      next[index] = normalized;
    } else {
      next.insert(0, normalized);
    }
    _requests = next;
  }

  Map<String, dynamic>? get _waitingRequest {
    if (_waitingRequestId == null) return null;
    for (final r in _requests) {
      if (r['id'] == _waitingRequestId) return r;
    }
    return null;
  }

  String _timeAgo(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  Future<void> _openMapPicker({required bool isPickup}) async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          title: isPickup ? 'Pickup location' : 'Drop location',
          initialLat: isPickup ? _fromLatLng?.latitude : _toLatLng?.latitude,
          initialLng: isPickup ? _fromLatLng?.longitude : _toLatLng?.longitude,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (isPickup) {
        _fromLatLng = LatLng(result.lat, result.lng);
        _fromCtrl.text = result.address;
        _pickupCtrl.text = result.address;
        _fromError = null;
      } else {
        _toLatLng = LatLng(result.lat, result.lng);
        _toCtrl.text = result.address;
        _dropPointCtrl.text = result.address;
        _toError = null;
      }
    });
  }

  Future<void> _postRequest() async {
    if (_posting) return;
    final fromEmpty = _fromCtrl.text.trim().isEmpty;
    final toEmpty = _toCtrl.text.trim().isEmpty;
    if (fromEmpty || toEmpty) {
      setState(() {
        _fromError = fromEmpty ? 'Enter pickup area' : null;
        _toError = toEmpty ? 'Enter drop area' : null;
      });
      return;
    }
    setState(() => _posting = true);
    try {
      final pos = await _position();
      final fromLatLng =
          _fromLatLng ?? await _geocodeText(_fromCtrl.text.trim());
      final toLatLng = _toLatLng ?? await _geocodeText(_toCtrl.text.trim());
      final fromLocation = _ResolvedLocation(
        lat: fromLatLng?.latitude ?? pos?.latitude ?? 0,
        lng: fromLatLng?.longitude ?? pos?.longitude ?? 0,
      );
      final toLocation = _ResolvedLocation(
        lat: toLatLng?.latitude ?? pos?.latitude ?? 0,
        lng: toLatLng?.longitude ?? pos?.longitude ?? 0,
      );
      final desiredFare = double.tryParse(_fareCtrl.text.trim());
      final body = {
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
        if (desiredFare != null && desiredFare > 0) 'desiredFare': desiredFare,
        if (pos != null) 'customerLat': pos.latitude,
        if (pos != null) 'customerLng': pos.longitude,
      };

      Map<String, dynamic> res;
      if (_editingRequestId != null && _editingRequestId!.isNotEmpty) {
        res = await ApiService.patch('/customer-requests/${_editingRequestId!}', body);
      } else {
        res = await ApiService.post('/customer-requests', body);
      }

      final request = res['request'] as Map<String, dynamic>?;
      final newId = request?['id']?.toString();
      setState(() {
        if (request != null) _upsertPostedRequest(request);
        _fromLatLng = fromLatLng ?? _fromLatLng;
        _toLatLng = toLatLng ?? _toLatLng;
        _showPostForm = false;
        _waitingRequestId = newId;
        _fromError = null;
        _toError = null;
        _requestFilter = 'all';
        _editingRequestId = null;
      });
      await _loadMine(showLoading: false);
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Request posted. Waiting for offers…');
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

  Future<void> _acceptOffer(
    Map<String, dynamic> request,
    Map<String, dynamic> offer,
  ) async {
    final requestId = (request['id'] ?? '').toString();
    final offerId = (offer['id'] ?? '').toString();
    final pickupInitial = RideModel.formatLocationLabel(
      request['pickupLocation'] ?? request['startLocation'],
    );
    try {
      final res = await ApiService.patch(
        '/customer-requests/$requestId/offers/$offerId',
        {
          'action': 'accept',
          if (pickupInitial.isNotEmpty) 'pickupLocation': pickupInitial,
        },
      );
      await _loadMine();
      if (!mounted) return;
      final rideId = res['rideId']?.toString();
      final dealId = res['dealId']?.toString();
      final phone =
          (offer['captainPhone'] ?? request['acceptedCaptainPhone'] ?? '')
              .toString();
      final captainName = (offer['captainName'] ?? 'Captain').toString();
      final vehicle =
          (offer['captainVehicleInfo'] ?? offer['captainVehicleType'] ?? '')
              .toString();
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Captain accepted',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightBlue,
                    ),
              ),
              const SizedBox(height: 12),
              Text(captainName,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (phone.isNotEmpty)
                Text(phone, style: const TextStyle(color: AppColors.dustyBlue)),
              if (vehicle.isNotEmpty)
                Text('Vehicle: $vehicle',
                    style: const TextStyle(color: AppColors.dustyBlue)),
              const SizedBox(height: 16),
              if (phone.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () => dialPhone(ctx, phone),
                  icon: const Icon(Icons.call),
                  label: const Text('Call Captain'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => openWhatsApp(ctx, phone),
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp Captain'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (rideId != null &&
                      rideId.isNotEmpty &&
                      dealId != null &&
                      dealId.isNotEmpty) {
                    AppNavigator.state?.pushNamed(
                      '/active-ride',
                      arguments: {
                        'rideId': rideId,
                        'dealId': dealId,
                      },
                    );
                  } else {
                    AppNavigator.state?.pushNamed('/my-bookings');
                  }
                },
                child: const Text('View Active Ride'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Accept failed: $e', isError: true);
      }
    }
  }

  Future<void> _counterOffer(
    Map<String, dynamic> request,
    Map<String, dynamic> offer,
  ) async {
    final requestId = (request['id'] ?? '').toString();
    final offerId = (offer['id'] ?? '').toString();
    final fareCtrl = TextEditingController(
      text: (offer['fare'] ?? '').toString(),
    );
    final messageCtrl = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Counter offer',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.midnightBlue,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fareCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Your counter fare',
                prefixText: 'Rs ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(fareCtrl.text.trim());
                if (amount == null || amount <= 0) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Send counter'),
            ),
          ],
        ),
      ),
    );
    final amount = double.tryParse(fareCtrl.text.trim());
    fareCtrl.dispose();
    messageCtrl.dispose();
    if (submitted != true || amount == null || amount <= 0) return;
    try {
      await ApiService.patch('/customer-requests/$requestId/offers/$offerId', {
        'action': 'counter',
        'counterFare': amount,
      });
      await _loadMine();
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Counter sent to captain');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Counter failed: $e', isError: true);
      }
    }
  }

  Future<void> _deleteRequest(Map<String, dynamic> request) async {
    final requestId = (request['id'] ?? '').toString();
    if (requestId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text(
          'This will remove your posted request and cancel pending captain offers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.delete('/customer-requests/$requestId');
      if (!mounted) return;
      setState(() {
        _requests.removeWhere((r) => (r['id'] ?? '').toString() == requestId);
        if (_waitingRequestId == requestId) {
          _waitingRequestId = null;
          _showPostForm = true;
        }
      });
      AppHelpers.showSnackBar(context, 'Request deleted');
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Delete failed: $e', isError: true);
      }
    }
  }

  void _prefillFromRequest(Map<String, dynamic> request) {
    _fromCtrl.text = RideModel.formatLocationLabel(request['startLocation']);
    _toCtrl.text = RideModel.formatLocationLabel(request['endLocation']);
    _pickupCtrl.text = RideModel.formatLocationLabel(request['pickupLocation']);
    _dropPointCtrl.text =
        RideModel.formatLocationLabel(request['dropLocation']);
    final fare = request['desiredFare'];
    _fareCtrl.text = fare == null ? '' : fare.toString();
    final sLat = (request['startLat'] as num?)?.toDouble();
    final sLng = (request['startLng'] as num?)?.toDouble();
    final eLat = (request['endLat'] as num?)?.toDouble();
    final eLng = (request['endLng'] as num?)?.toDouble();
    if (sLat != null && sLng != null) _fromLatLng = LatLng(sLat, sLng);
    if (eLat != null && eLng != null) _toLatLng = LatLng(eLat, eLng);
    final reqAt = DateTime.tryParse((request['requestedAt'] ?? '').toString());
    if (reqAt != null) _requestedAt = reqAt.toLocal();
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUserName(context);
    final visibleRequests = _requests.where((request) {
      final status = (request['status'] ?? '').toString().toLowerCase();
      if (_requestFilter == 'completed') {
        return ['accepted', 'completed'].contains(status);
      }
      if (_requestFilter == 'all') return true;
      return ['open', 'countered'].contains(status);
    }).toList();

    final waiting = _waitingRequest;
    final waitingExpired = waiting != null &&
        ['expired', 'cancelled'].contains(
          (waiting['status'] ?? '').toString().toLowerCase(),
        );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(waiting != null && !waitingExpired
            ? 'Waiting for offers'
            : 'Post Ride Request'),
        backgroundColor: AppColors.deepNavy,
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
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _loadMine(showLoading: false),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SignedInChip(
                  role: 'Customer',
                  name: userName,
                ),
                const SizedBox(height: 12),
                if (waiting != null && !waitingExpired) ...[
                  _buildWaitingHeader(waiting),
                  const SizedBox(height: 16),
                  const Text(
                    'Captain Offers',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  _buildOffersStream(
                    (_waitingRequestId ?? waiting['id'] ?? '').toString(),
                    waiting,
                  ),
                  const SizedBox(height: 24),
                ],
                if (_showPostForm && (waiting == null || waitingExpired))
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Select route on map',
                          style: TextStyle(
                            color: AppColors.bark,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Type From and To, use current location, or tap the map for more accurate nearby matching.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
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
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => _mapTapSetsDrop = false),
                                icon: const Icon(Icons.trip_origin_rounded,
                                    size: 18),
                                label: const Text('Tap map for From'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: !_mapTapSetsDrop
                                      ? AppColors.sky
                                      : AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: _useCurrentPickup,
                                icon: const Icon(Icons.gps_fixed_rounded,
                                    size: 18),
                                label: const Text('Current pickup'),
                              ),
                            ),
                          ],
                        ),
                        if (_fromLatLng != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'From map: ${_fromLatLng!.latitude.toStringAsFixed(5)}, ${_fromLatLng!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: AppColors.moss,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => _mapTapSetsDrop = true),
                                icon: const Icon(Icons.flag_rounded, size: 18),
                                label: const Text('Tap map for To'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _mapTapSetsDrop
                                      ? AppColors.sky
                                      : AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_toLatLng != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'To map: ${_toLatLng!.latitude.toStringAsFixed(5)}, ${_toLatLng!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: AppColors.moss,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            height: 240,
                            child: Stack(
                              children: [
                                GoogleMap(
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
                                Positioned(
                                  left: 12,
                                  top: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _mapTapSetsDrop
                                          ? 'Tap map to set To'
                                          : 'Tap map to set From',
                                      style: const TextStyle(
                                        color: AppColors.bark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_fromLatLng == null || _toLatLng == null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha:0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha:0.35),
                              ),
                            ),
                            child: const Text(
                              'Map is optional. Text route will be used if you do not tap the map.',
                              style: TextStyle(
                                color: AppColors.bark,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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
                        TextField(
                          controller: _fareCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Your fare budget',
                            prefixText: 'Rs ',
                            hintText: 'Optional',
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
                            label:
                                Text(_posting ? 'Posting...' : 'Post request'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.moss,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'My Posted Requests',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _waitingRequestId = null;
                            _showPostForm = true;
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Active'),
                        selected: _requestFilter == 'active',
                        onSelected: (_) =>
                            setState(() => _requestFilter = 'active'),
                      ),
                      ChoiceChip(
                        label: const Text('Completed'),
                        selected: _requestFilter == 'completed',
                        onSelected: (_) =>
                            setState(() => _requestFilter = 'completed'),
                      ),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _requestFilter == 'all',
                        onSelected: (_) =>
                            setState(() => _requestFilter = 'all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const SkeletonList(item: RequestCardSkeleton(), count: 3)
                  else if (visibleRequests.isEmpty)
                    const Text(
                      'No posted requests yet.',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else
                    ...visibleRequests.map(
                      (request) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _requestCard(request),
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (waitingExpired) _buildExpiredOverlay(waiting),
        ],
      ),
    );
  }

  Widget _buildWaitingHeader(Map<String, dynamic> request) {
    final start = RideModel.formatLocationLabel(request['startLocation']);
    final end = RideModel.formatLocationLabel(request['endLocation']);
    final vehicle = (request['vehicleType'] ?? 'car').toString();
    final fare = request['desiredFare'];
    final posted = _timeAgo(request['createdAt']?.toString());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ivory),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$start → $end',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.midnightBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text('Vehicle: $vehicle',
              style: const TextStyle(color: AppColors.dustyBlue)),
          if (fare != null && '$fare'.trim().isNotEmpty)
            Text(
              'Desired fare: Rs $fare',
              style: const TextStyle(
                color: AppColors.midnightBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (posted.isNotEmpty)
            Text('Posted $posted',
                style: const TextStyle(
                  color: AppColors.dustyBlue,
                  fontSize: 12,
                )),
        ],
      ),
    );
  }

  Widget _buildOffersStream(String requestId, Map<String, dynamic> request) {
    if (requestId.isEmpty) {
      return const Text(
        'Unable to load offers.',
        style: TextStyle(color: AppColors.error),
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('customerRideOffers')
          .where('requestId', isEqualTo: requestId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Could not load offers: ${snapshot.error}',
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          );
        }
        if (!snapshot.hasData) {
          return const Column(
            children: [
              RequestCardSkeleton(),
              SizedBox(height: 12),
            ],
          );
        }
        final offers = snapshot.data!.docs
            .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
            .toList();
        if (offers.isEmpty) {
          return Column(
            children: [
              const RequestCardSkeleton(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PulsingDot(),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Waiting for captains nearby...',
                      style: TextStyle(
                        color: AppColors.dustyBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        final merged = Map<String, dynamic>.from(request)..['offers'] = offers;
        return _requestCard(merged);
      },
    );
  }

  Widget _buildExpiredOverlay(Map<String, dynamic> request) {
    return Positioned.fill(
      child: Container(
        color: AppColors.deepNavy.withValues(alpha:0.92),
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_off_outlined,
                  color: AppColors.white, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Your request has expired. No captain accepted in time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _prefillFromRequest(request);
                  setState(() {
                    _waitingRequestId = null;
                    _showPostForm = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.midnightBlue,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Post Again'),
              ),
            ],
          ),
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
    final acceptedName = (request['acceptedCaptainName'] ?? '').toString();
    final requestStatus = (request['status'] ?? '').toString().toLowerCase();
    final finalFare = (request['finalFare'] ?? '').toString();
    final offerCount = offers.length;
    final canDelete = ['open', 'countered', 'expired', 'cancelled', '']
        .contains(requestStatus);
    final requestedAt = DateTime.tryParse(
      (request['requestedAt'] ?? '').toString(),
    );
    final requestedLabel = requestedAt == null
        ? '-'
        : '${requestedAt.toLocal().day}/${requestedAt.toLocal().month}/${requestedAt.toLocal().year} ${TimeOfDay.fromDateTime(requestedAt.toLocal()).format(context)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ivory),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha:0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.moss,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
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
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 1.5, top: 2, bottom: 2),
                      child: Container(
                        width: 3,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
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
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$offerCount offers',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (AppHelpers.hasDisplayValue(pickup))
            Text(
              'Exact pickup: $pickup',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          if (AppHelpers.hasDisplayValue(drop))
            Text(
              'Exact drop: $drop',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          Text(
            'Time: $requestedLabel',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: requestedLabel,
              ),
              _InfoPill(
                icon: Icons.bolt_rounded,
                label: requestStatus.toUpperCase(),
              ),
            ],
          ),
          if (finalFare.isNotEmpty && finalFare != 'null')
            Text(
              'Final fare: Rs $finalFare',
              style: const TextStyle(
                color: AppColors.moss,
                fontWeight: FontWeight.w900,
              ),
            ),
          if (acceptedPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${acceptedName.isEmpty ? 'Captain' : acceptedName}: $acceptedPhone',
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
                if (request['status'] == 'accepted' || request['status'] == 'completed')
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/active-ride',
                        arguments: {'requestId': request['id'], 'mode': 'tracking'},
                      );
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Track'),
                  ),
              ],
            ),
          ],
          if (canDelete) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _prefillFromRequest(request);
                        setState(() {
                          _editingRequestId = (request['id'] ?? '').toString();
                          _waitingRequestId = null;
                          _showPostForm = true;
                        });
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit', maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        minimumSize: const Size.fromHeight(36),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteRequest(request),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Delete', maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      minimumSize: const Size.fromHeight(36),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          ...offers.map((offer) {
            final offerId = (offer['id'] ?? '').toString();
            final requestId = (request['id'] ?? '').toString();
            final offerStatus =
                (offer['status'] ?? '').toString().toLowerCase();
            final isChosen = request['acceptedOfferId'] == offerId ||
                offerStatus == 'accepted' ||
                offerStatus == 'completed';
            final canRespond = ['open', 'countered'].contains(requestStatus) &&
                ['offered', 'countered'].contains(offerStatus);
            final captainPhone = isChosen
                ? (offer['captainPhone'] ?? acceptedPhone).toString()
                : '';
            final vehicle = (offer['captainVehicleInfo'] ??
                    offer['captainVehicleType'] ??
                    '')
                .toString()
                .trim();
            final registration =
                (offer['captainVehicleRegistration'] ?? '').toString().trim();
            final seats = (offer['availableSeats'] ?? '').toString();
            final vehiclePhoto =
                (offer['captainVehiclePhotoUrl'] ?? '').toString().trim();
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceBlue,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.skyBlue.withValues(alpha:0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 58,
                          height: 58,
                          child: vehiclePhoto.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: vehiclePhoto,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.white,
                                    child: const Icon(
                                      Icons.directions_car_rounded,
                                      color: AppColors.moss,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppColors.white,
                                  child: const Icon(
                                    Icons.directions_car_rounded,
                                    color: AppColors.moss,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${offer['captainName'] ?? 'Captain'} offered Rs ${offer['fare']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Offer status: ${offerStatus.toUpperCase()}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  if (captainPhone.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Captain WhatsApp: $captainPhone',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => dialPhone(context, captainPhone),
                          icon: const Icon(Icons.call),
                          label: const Text('Call'),
                        ),
                        TextButton.icon(
                          onPressed: () => openWhatsApp(context, captainPhone),
                          icon: const Icon(Icons.chat),
                          label: const Text('WhatsApp'),
                        ),
                      ],
                    ),
                  ],
                  if (canRespond) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 110,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () => _counterOffer(request, offer),
                            child: const Text('Counter', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size.fromHeight(36),
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () => _acceptOffer(request, offer),
                              child: const Text('Accept', maxLines: 1, overflow: TextOverflow.ellipsis),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                minimumSize: const Size.fromHeight(36),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SignedInChip extends StatelessWidget {
  final String role;
  final String? name;

  const _SignedInChip({
    required this.role,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        (name == null || name!.trim().isEmpty) ? 'ShareWay user' : name!.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withValues(alpha:0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha:0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$role - $displayName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.ivory),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.moss),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.deepNavy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_ctrl),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.midnightBlue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

