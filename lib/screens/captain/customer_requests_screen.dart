import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/ride_model.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/skeleton_loader.dart';

class CaptainCustomerRequestsScreen extends StatefulWidget {
  const CaptainCustomerRequestsScreen({super.key});

  @override
  State<CaptainCustomerRequestsScreen> createState() =>
      _CaptainCustomerRequestsScreenState();
}

class _CaptainCustomerRequestsScreenState
    extends State<CaptainCustomerRequestsScreen> {
  bool _loading = true;
  bool _captainOffline = false;
  List<Map<String, dynamic>> _requests = [];
  Timer? _refreshTimer;
  String _requestFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadRequests(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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

  Future<void> _loadRequests({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final pos = await _position();
      final res = await ApiService.get(
        '/customer-requests',
        queryParams: {
          if (pos != null) 'lat': pos.latitude.toString(),
          if (pos != null) 'lng': pos.longitude.toString(),
        },
      );
      if (mounted) {
        setState(() {
          _captainOffline = res['offline'] == true;
          _requests = List<Map<String, dynamic>>.from(res['requests'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _offer(
    String requestId, {
    double? presetFare,
    String? editOfferId,
    String? initialMessage,
  }) async {
    final fareCtrl = TextEditingController(
      text: presetFare != null && presetFare > 0
          ? presetFare.toStringAsFixed(0)
          : '',
    );
    final messageCtrl = TextEditingController(text: initialMessage ?? '');
    String? fareError;
    final fare = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(editOfferId != null ? 'Edit offer' : 'Make offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fareCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your fare (Rs)',
                  prefixText: 'Rs ',
                  border: OutlineInputBorder(),
                ),
              ),
              if (fareError != null) ...[
                const SizedBox(height: 6),
                Text(
                  fareError!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: messageCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(fareCtrl.text.trim());
                if (value == null || value <= 0) {
                  setDialogState(
                    () => fareError = 'Enter a valid fare amount',
                  );
                  return;
                }
                if (value < 50) {
                  setDialogState(
                    () => fareError = 'Minimum fare is Rs 50',
                  );
                  return;
                }
                Navigator.pop(ctx, value);
              },
              child: Text(editOfferId != null ? 'Update Offer' : 'Send Offer'),
            ),
          ],
        ),
      ),
    );
    final message = messageCtrl.text.trim();
    fareCtrl.dispose();
    messageCtrl.dispose();
    if (fare == null || fare <= 0) return;

    try {
      if (editOfferId != null && editOfferId.isNotEmpty) {
        await ApiService.patch(
          '/customer-requests/$requestId/offers/$editOfferId',
          {
            'fare': fare,
            if (message.isNotEmpty) 'message': message,
          },
        );
        if (mounted) {
          AppHelpers.showSnackBar(context, 'Offer updated');
        }
      } else {
        await ApiService.post('/customer-requests/$requestId/offers', {
          'fare': fare,
          if (message.isNotEmpty) 'message': message,
        });
        if (mounted) {
          AppHelpers.showSnackBar(context, 'Offer sent to customer');
        }
      }
      await _loadRequests(showLoading: false);
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('OFFER_EXISTS')) {
          AppHelpers.showSnackBar(
            context,
            'You already have an offer. Use Edit Offer instead.',
            isError: true,
          );
        } else {
          AppHelpers.showSnackBar(context, 'Offer failed: $e', isError: true);
        }
      }
    }
  }

  // ✅ FIXED: Added captainId in request body + WhatsApp/Call buttons
  Future<void> _doneAtCustomerFare(Map<String, dynamic> request) async {
    final requestId = (request['id'] ?? '').toString();
    final desiredFare =
        double.tryParse((request['desiredFare'] ?? '').toString());
    if (requestId.isEmpty || desiredFare == null || desiredFare < 50) {
      AppHelpers.showSnackBar(
        context,
        'Customer fare is missing. Use Make Offer instead.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Done at customer fare?'),
        content: Text(
          'Accept this request at Rs ${desiredFare.toStringAsFixed(0)}. This will confirm the ride and reveal contact numbers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final captainId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (captainId.isEmpty) {
        AppHelpers.showSnackBar(context, 'You are not logged in',
            isError: true);
        return;
      }

      final res = await ApiService.post(
        '/customer-requests/$requestId/accept-fare',
        {
          'captainId': captainId,
          'fare': desiredFare,
        },
      );

      await _loadRequests(showLoading: false);
      if (!mounted) return;

      AppHelpers.showSnackBar(context, 'Ride confirmed at customer fare');

      final customerPhone =
          (res['customerPhone'] ?? res['customer']?['phone'] ?? '').toString();
      final customerName =
          (res['customerName'] ?? request['customerName'] ?? 'Customer')
              .toString();
      final pickupLabel = (res['pickupLocation'] ??
              request['pickupLocation'] ??
              request['startLocation'])
          ?.toString();

      // ✅ Updated bottom sheet with WhatsApp & Call buttons
      if (customerPhone.isNotEmpty) {
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.moss.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.moss,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '✅ Ride Confirmed!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.moss,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Fare: Rs ${desiredFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: AppColors.moss),
                          const SizedBox(width: 8),
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone,
                              color: AppColors.sage, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            customerPhone,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (pickupLabel != null && pickupLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.sage, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pickupLabel,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ✅ WhatsApp Button
                ElevatedButton.icon(
                  onPressed: () => openWhatsApp(ctx, customerPhone),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text(
                    'Chat on WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ✅ Call Button
                OutlinedButton.icon(
                  onPressed: () => dialPhone(ctx, customerPhone),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text(
                    'Call Customer',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.moss),
                    foregroundColor: AppColors.moss,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final rideId = res['rideId']?.toString();
                    final dealId = res['dealId']?.toString();
                    if (rideId != null &&
                        rideId.isNotEmpty &&
                        dealId != null &&
                        dealId.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        '/active-ride',
                        arguments: {'rideId': rideId, 'dealId': dealId},
                      );
                    } else {
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    'View Active Ride',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.sage),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final rideId = res['rideId']?.toString();
        final dealId = res['dealId']?.toString();
        if (rideId != null &&
            rideId.isNotEmpty &&
            dealId != null &&
            dealId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/active-ride',
            arguments: {'rideId': rideId, 'dealId': dealId},
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Done failed: $e', isError: true);
      }
    }
  }

  void _openRequestSheet(Map<String, dynamic> request) {
    final start = RideModel.formatLocationLabel(request['startLocation']);
    final end = RideModel.formatLocationLabel(request['endLocation']);
    final pickup = RideModel.formatLocationLabel(request['pickupLocation']);
    final drop = RideModel.formatLocationLabel(request['dropLocation']);
    final lat = (request['startLat'] as num?)?.toDouble() ?? 0;
    final lng = (request['startLng'] as num?)?.toDouble() ?? 0;
    final desiredFare = (request['desiredFare'] as num?)?.toDouble();
    final requestId = (request['id'] ?? '').toString();
    final customerName = (request['customerName'] ?? 'Customer').toString();
    final vehicleType = (request['vehicleType'] ?? 'car').toString();
    final distance = double.tryParse((request['distanceKm'] ?? '').toString());
    final requestStatus = (request['status'] ?? '').toString().toLowerCase();

    final captainId = FirebaseAuth.instance.currentUser?.uid ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('customerRideOffers')
            .where('requestId', isEqualTo: requestId)
            .snapshots(),
        builder: (context, offerSnap) {
          Map<String, dynamic>? myOffer;
          if (offerSnap.hasData) {
            for (final doc in offerSnap.data!.docs) {
              final data = doc.data();
              if (data['captainId'] == captainId) {
                myOffer = {'id': doc.id, ...data};
                break;
              }
            }
          }
          myOffer ??= request['myOffer'] as Map<String, dynamic>?;
          final offerStatus =
              (myOffer?['status'] ?? '').toString().toLowerCase();
          final counterFare = myOffer?['counterFare'];
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.ivory,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: start,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.moss,
                          ),
                        ),
                        const TextSpan(
                          text: '  →  ',
                          style: TextStyle(
                              color: AppColors.midnightBlue,
                              fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: end,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pickup != null && pickup.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Pickup: $pickup',
                        style: const TextStyle(color: AppColors.dustyBlue)),
                  ],
                  if (drop != null && drop.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Drop: $drop',
                        style: const TextStyle(color: AppColors.dustyBlue)),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    distance == null
                        ? 'Distance unavailable'
                        : '${distance.toStringAsFixed(1)} km away · $vehicleType',
                    style: const TextStyle(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (desiredFare != null && desiredFare > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Desired fare: Rs ${desiredFare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.midnightBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  if (lat != 0 && lng != 0) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 140,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(lat, lng),
                            zoom: 14,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('pickup'),
                              position: LatLng(lat, lng),
                            ),
                          },
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    ),
                  ],
                  if (myOffer != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      offerStatus == 'countered'
                          ? 'Countered by passenger · Rs $counterFare'
                          : 'Your offer: ${offerStatus.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.midnightBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (desiredFare != null &&
                      desiredFare >= 50 &&
                      ['open', 'countered'].contains(requestStatus)) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _doneAtCustomerFare(request);
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(
                        'Done at Rs ${desiredFare.toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Not Interested'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            final editId = myOffer?['id']?.toString();
                            if (editId != null && editId.isNotEmpty) {
                              _offer(
                                requestId,
                                presetFare:
                                    (myOffer?['fare'] as num?)?.toDouble() ??
                                        desiredFare,
                                editOfferId: editId,
                                initialMessage: myOffer?['message']?.toString(),
                              );
                            } else {
                              _offer(requestId, presetFare: desiredFare);
                            }
                          },
                          child: Text(
                            myOffer != null ? 'Edit Offer' : 'Make Offer',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (offerStatus == 'accepted' &&
                      requestStatus == 'accepted') ...[
                    const SizedBox(height: 14),
                    Divider(color: AppColors.line),
                    const SizedBox(height: 14),
                    Text(
                      'Contact Customer',
                      style: TextStyle(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if ((request['customerPhone'] as String?)?.isNotEmpty ??
                            false)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => dialPhone(context,
                                  (request['customerPhone'] ?? '').toString()),
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('Call'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        if ((request['customerPhone'] as String?)?.isNotEmpty ??
                            false)
                          const SizedBox(width: 10),
                        if ((request['customerPhone'] as String?)?.isNotEmpty ??
                            false)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => openWhatsApp(context,
                                  (request['customerPhone'] ?? '').toString()),
                              icon: const Icon(Icons.chat, size: 18),
                              label: const Text('WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        if ((request['customerPhone'] as String?)?.isNotEmpty ??
                            false)
                          const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(
                                context,
                                '/active-ride',
                                arguments: {
                                  'requestId': requestId,
                                  'mode': 'tracking'
                                },
                              );
                            },
                            icon: const Icon(Icons.location_on, size: 18),
                            label: const Text('Track'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (offerStatus == 'countered' && counterFare != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final amount =
                                  double.tryParse(counterFare.toString());
                              if (amount != null) {
                                Navigator.pop(ctx);
                                _acceptCounter(
                                  requestId,
                                  amount,
                                  offerId: myOffer?['id']?.toString(),
                                );
                              }
                            },
                            child: const Text('Accept Counter'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _offer(
                                requestId,
                                presetFare: double.tryParse(
                                  (request['desiredFare'] ?? counterFare)
                                      .toString(),
                                ),
                                editOfferId: myOffer?['id']?.toString(),
                              );
                            },
                            child: const Text('New Counter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleRequests = _requests.where((request) {
      final status = (request['status'] ?? '').toString().toLowerCase();
      if (_requestFilter == 'completed') {
        return ['accepted', 'completed'].contains(status);
      }
      if (_requestFilter == 'all') return true;
      return ['open', 'countered'].contains(status);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Customer Requests'),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadRequests(showLoading: false),
        child: Column(
          children: [
            if (_captainOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.deepNavy.withValues(alpha: 0.9),
                child: const Text(
                  'You are offline. Go online on the home screen to receive requests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
              ),
            Expanded(
              child: _loading
                  ? const SkeletonList(item: RequestCardSkeleton(), count: 5)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Active'),
                              selected: _requestFilter == 'active',
                              onSelected: (_) =>
                                  setState(() => _requestFilter = 'active'),
                              selectedColor: AppColors.moss,
                              labelStyle: TextStyle(
                                color: _requestFilter == 'active'
                                    ? AppColors.white
                                    : AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Completed'),
                              selected: _requestFilter == 'completed',
                              onSelected: (_) =>
                                  setState(() => _requestFilter = 'completed'),
                              selectedColor: AppColors.moss,
                              labelStyle: TextStyle(
                                color: _requestFilter == 'completed'
                                    ? AppColors.white
                                    : AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('All'),
                              selected: _requestFilter == 'all',
                              onSelected: (_) =>
                                  setState(() => _requestFilter = 'all'),
                              selectedColor: AppColors.moss,
                              labelStyle: TextStyle(
                                color: _requestFilter == 'all'
                                    ? AppColors.white
                                    : AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (visibleRequests.isEmpty) ...[
                          const SizedBox(height: 140),
                          const Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 64, color: AppColors.sage),
                                SizedBox(height: 12),
                                Text(
                                  'No customer requests yet.',
                                  style: TextStyle(
                                    color: AppColors.sage,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Requests will appear here when customers post.',
                                  style: TextStyle(
                                    color: AppColors.sage,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          ...visibleRequests.map(_requestCard),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _acceptCounter(
    String requestId,
    double fare, {
    String? offerId,
  }) async {
    try {
      if (offerId != null && offerId.isNotEmpty) {
        await ApiService.patch(
            '/customer-requests/$requestId/offers/$offerId', {
          'fare': fare,
          'message': 'Accepted your counter fare',
        });
      } else {
        await ApiService.post('/customer-requests/$requestId/offers', {
          'fare': fare,
          'message': 'Accepted your counter fare',
        });
      }
      await _loadRequests(showLoading: false);
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Counter accepted');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Failed: $e', isError: true);
      }
    }
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final status = (request['status'] ?? '').toString();
    final customerName = (request['customerName'] ?? 'Customer').toString();
    final start = RideModel.formatLocationLabel(request['startLocation']);
    final end = RideModel.formatLocationLabel(request['endLocation']);
    final distance = double.tryParse((request['distanceKm'] ?? '').toString());
    final desiredFare = request['desiredFare'];
    final vehicleType = (request['vehicleType'] ?? 'car').toString();
    final posted = _timeAgo(request['createdAt']?.toString());
    final myOffer = request['myOffer'] as Map<String, dynamic>?;
    final offerStatus = (myOffer?['status'] ?? '').toString().toLowerCase();
    final counterFare = myOffer?['counterFare'];
    final requestId = (request['id'] ?? '').toString();
    final desiredFareAmount =
        double.tryParse((request['desiredFare'] ?? '').toString());
    final canDoneAtFare = desiredFareAmount != null &&
        desiredFareAmount >= 50 &&
        ['open', 'countered'].contains(status.toLowerCase());

    final rideMode = (request['rideMode'] ?? 'share').toString();
    final isShare = rideMode.toLowerCase() == 'share';

    return GestureDetector(
      onTap: () => _openRequestSheet(request),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ivory),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_pin_circle_rounded,
                    color: AppColors.moss,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.deepNavy,
                    ),
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
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: (isShare ? Colors.green : Colors.deepOrange)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isShare ? 'SHARE' : 'SOLO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: isShare ? Colors.green[800] : Colors.deepOrange[800],
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
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    start.isEmpty ? 'From' : start,
                    style: const TextStyle(
                      color: AppColors.midnightBlue,
                      fontSize: 13,
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
                      color: AppColors.midnightBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.watch_later_outlined,
                    size: 16, color: AppColors.moss),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppHelpers.formatDateTimeValue(
                        request['requestedAtDisplay'] ??
                            request['displayDateTime'] ??
                            request['requestedAt'] ??
                            request['createdAt']),
                    style: const TextStyle(
                      color: AppColors.midnightBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              distance == null
                  ? 'Distance unavailable'
                  : '${distance.toStringAsFixed(1)} km · $vehicleType',
              style: const TextStyle(color: AppColors.dustyBlue, fontSize: 13),
            ),
            if (desiredFare != null && '$desiredFare'.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBlue,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.ivory),
                  ),
                  child: Text(
                    'Budget Rs $desiredFare',
                    style: const TextStyle(
                      color: AppColors.midnightBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            if (posted.isNotEmpty)
              Text(
                posted,
                style: const TextStyle(
                  color: AppColors.dustyBlue,
                  fontSize: 12,
                ),
              ),
            if (myOffer != null) ...[
              const SizedBox(height: 8),
              Text(
                offerStatus == 'countered'
                    ? 'Countered by passenger · Rs $counterFare'
                    : 'Your offer: ${offerStatus == 'accepted' ? 'Accepted' : offerStatus == 'offered' ? 'Offered' : offerStatus.toUpperCase()}',
                style: const TextStyle(
                  color: AppColors.midnightBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (offerStatus == 'countered' && counterFare != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final amount =
                              double.tryParse(counterFare.toString());
                          if (amount != null) {
                            _acceptCounter(
                              requestId,
                              amount,
                              offerId: myOffer['id']?.toString(),
                            );
                          }
                        },
                        child: const Text('Accept Counter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.moss,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _offer(
                          requestId,
                          presetFare: double.tryParse(
                            (request['desiredFare'] ?? counterFare).toString(),
                          ),
                        ),
                        child: const Text('New Counter'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 10),
            if (canDoneAtFare) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _doneAtCustomerFare(request),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    'Done at Rs ${desiredFareAmount.toStringAsFixed(0)}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.moss,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openRequestSheet(request),
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('View details and send fare'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.moss),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
