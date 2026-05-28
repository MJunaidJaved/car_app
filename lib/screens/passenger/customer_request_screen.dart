import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/phone_utils.dart';

class CustomerRequestScreen extends StatefulWidget {
  const CustomerRequestScreen({super.key});

  @override
  State<CustomerRequestScreen> createState() => _CustomerRequestScreenState();
}

class _ResolvedLocation {
  final double lat;
  final double lng;
  final String? city;

  const _ResolvedLocation({
    required this.lat,
    required this.lng,
    this.city,
  });
}

class _CustomerRequestScreenState extends State<CustomerRequestScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  DateTime _requestedAt = DateTime.now().add(const Duration(hours: 1));
  bool _loading = true;
  bool _posting = false;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadMine();
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
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

  Future<_ResolvedLocation?> _resolveAddress(
    String address, {
    Position? fallbackPosition,
  }) async {
    final clean = address.trim();
    if (clean.isEmpty) return null;
    try {
      final locations = await locationFromAddress('$clean, Pakistan')
          .timeout(const Duration(seconds: 5));
      if (locations.isNotEmpty) {
        final loc = locations.first;
        String? city;
        try {
          final places = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          ).timeout(const Duration(seconds: 4));
          if (places.isNotEmpty) {
            city = (places.first.locality?.trim().isNotEmpty == true)
                ? places.first.locality!.trim()
                : places.first.administrativeArea?.trim();
          }
        } catch (_) {}
        return _ResolvedLocation(
          lat: loc.latitude,
          lng: loc.longitude,
          city: city,
        );
      }
    } catch (_) {}

    if (fallbackPosition == null) return null;
    return _ResolvedLocation(
      lat: fallbackPosition.latitude,
      lng: fallbackPosition.longitude,
    );
  }

  Future<void> _loadMine() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both From and To locations.'), duration: Duration(seconds: 2)),
      );
      return;
    }
    setState(() => _posting = true);
    try {
      final pos = await _position();
      final fromLocation = await _resolveAddress(
        _fromCtrl.text,
        fallbackPosition: pos,
      );
      final toLocation = await _resolveAddress(_toCtrl.text);
      await ApiService.post('/customer-requests', {
        'startLocation': _fromCtrl.text.trim(),
        'endLocation': _toCtrl.text.trim(),
        'requestedAt': _requestedAt.toUtc().toIso8601String(),
        if (fromLocation != null) 'startLat': fromLocation.lat,
        if (fromLocation != null) 'startLng': fromLocation.lng,
        if (toLocation != null) 'endLat': toLocation.lat,
        if (toLocation != null) 'endLng': toLocation.lng,
        if (pos != null) 'customerLat': pos.latitude,
        if (pos != null) 'customerLng': pos.longitude,
        if ((fromLocation?.city ?? '').isNotEmpty) 'city': fromLocation!.city,
      });
      _fromCtrl.clear();
      _toCtrl.clear();
      await _loadMine();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request posted. Captains notified.'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post failed: $e'), duration: const Duration(seconds: 2)),
        );
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
      _requestedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), duration: const Duration(seconds: 2)),
        );
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadMine,
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
                  TextField(controller: _fromCtrl, decoration: const InputDecoration(labelText: 'From')),
                  TextField(controller: _toCtrl, decoration: const InputDecoration(labelText: 'To')),
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
            const Text('Captain Offers', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_requests.isEmpty)
              const Text('No posted requests yet.', style: TextStyle(color: AppColors.textMuted))
            else
              ..._requests.map(_requestCard),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final offers = List<Map<String, dynamic>>.from(request['offers'] ?? []);
    offers.sort((a, b) {
      final aFare = double.tryParse((a['counterFare'] ?? a['fare'] ?? 0).toString()) ?? 0;
      final bFare = double.tryParse((b['counterFare'] ?? b['fare'] ?? 0).toString()) ?? 0;
      return aFare.compareTo(bFare);
    });
    final acceptedPhone = (request['acceptedCaptainPhone'] ?? '').toString();
    final requestedAt = DateTime.tryParse((request['requestedAt'] ?? '').toString());
    final requestedLabel = requestedAt == null
        ? '-'
        : '${requestedAt.toLocal().day}/${requestedAt.toLocal().month}/${requestedAt.toLocal().year} ${TimeOfDay.fromDateTime(requestedAt.toLocal()).format(context)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${request['startLocation']} -> ${request['endLocation']}', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('Time: $requestedLabel', style: const TextStyle(color: AppColors.textMuted)),
          Text('Status: ${(request['status'] ?? '').toString().toUpperCase()}'),
          if (acceptedPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Captain: $acceptedPhone', style: const TextStyle(fontWeight: FontWeight.w800)),
            Row(children: [
              TextButton.icon(onPressed: () => dialPhone(context, acceptedPhone), icon: const Icon(Icons.call), label: const Text('Call')),
              TextButton.icon(onPressed: () => openWhatsApp(context, acceptedPhone), icon: const Icon(Icons.chat), label: const Text('WhatsApp')),
            ]),
          ],
          const SizedBox(height: 8),
          ...offers.map((offer) {
            final offerId = (offer['id'] ?? '').toString();
            final requestId = (request['id'] ?? '').toString();
            final pickupInitial =
                (request['pickupLocation'] ?? request['startLocation'] ?? '')
                    .toString();
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
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${offer['captainName'] ?? 'Captain'} offered Rs ${offer['fare']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                if (vehicle.isNotEmpty)
                  Text('Vehicle: $vehicle', style: const TextStyle(color: AppColors.textMuted)),
                if (registration.isNotEmpty)
                  Text('Reg: $registration', style: const TextStyle(color: AppColors.textMuted)),
                if (seats.isNotEmpty && seats != 'null')
                  Text('Available seats: $seats', style: const TextStyle(color: AppColors.textMuted)),
                if ((offer['counterFare'] ?? '').toString().isNotEmpty) Text('Counter: Rs ${offer['counterFare']}'),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => _respond(requestId, offerId, 'counter', pickupInitial: pickupInitial), child: const Text('Adjust Fare'))),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton(onPressed: () => _respond(requestId, offerId, 'accept', pickupInitial: pickupInitial), child: const Text('Done'))),
                ]),
              ]),
            );
          }),
        ],
      ),
    );
  }
}


