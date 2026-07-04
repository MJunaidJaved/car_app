import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/ride_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/location_tracking_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/deal_chat_panel.dart';
import '../../widgets/skeleton_loader.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _rideId;
  RideModel? _ride;
  List<Map<String, dynamic>> _deals = [];
  bool _loading = true;
  bool _rideLoading = true;
  bool _refreshingDeals = false;
  final _locationService = LocationTrackingService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _dealsSub;
  int _totalSeats = 0;
  int _confirmedSeats = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rideId = ModalRoute.of(context)?.settings.arguments as String?;
      _loadRide();
      _loadDeals(showLoading: true);
      _subscribeDeals();
    });
  }

  void _subscribeDeals() {
    if (_rideId == null) return;
    _dealsSub?.cancel();
    _dealsSub = FirebaseFirestore.instance
        .collection('deals')
        .where('rideId', isEqualTo: _rideId)
        .snapshots()
        .listen((_) => _loadDeals(showLoading: false));
  }

  Future<void> _loadRide() async {
    if (_rideId == null) {
      setState(() => _rideLoading = false);
      return;
    }
    try {
      final service = Provider.of<FirestoreService>(context, listen: false);
      final ride = await service.getRideById(_rideId!);
      if (mounted) {
        setState(() {
          _ride = ride;
          _rideLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _rideLoading = false);
    }
  }

  void _updateSeatCounts() {
    _confirmedSeats = _deals
        .where(
          (d) => ['confirmed', 'started', 'completed'].contains(d['status']),
        )
        .length;
    _totalSeats = _ride?.totalSeats ?? 0;
    if (_totalSeats == 0 && _rideId != null) {
      FirebaseFirestore.instance.collection('rides').doc(_rideId).get().then((
        doc,
      ) {
        if (doc.exists && mounted) {
          setState(() => _totalSeats = (doc.data()?['totalSeats'] ?? 0) as int);
        }
      });
    }
  }

  Future<void> _loadDeals({bool showLoading = false}) async {
    if (_rideId == null) {
      setState(() => _loading = false);
      return;
    }
    if (_refreshingDeals) return;
    _refreshingDeals = true;
    if (showLoading && mounted && _deals.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final service = Provider.of<FirestoreService>(context, listen: false);
      final deals = await service.getRideDeals(_rideId!);
      if (mounted) {
        setState(() {
          _deals = deals;
          _loading = false;
        });
        _updateSeatCounts();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppHelpers.showSnackBar(context, 'Failed to load: $e', isError: true);
      }
    } finally {
      _refreshingDeals = false;
    }
  }

  Future<void> _accept(String dealId) async {
    try {
      await Provider.of<FirestoreService>(
        context,
        listen: false,
      ).confirmDeal(dealId);
      await Provider.of<UserProvider>(context, listen: false).reloadWallet();
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Request accepted');
        await _loadDeals(showLoading: false);
        _tabCtrl.animateTo(1);
      }
    } catch (e) {
      final insufficient = _parseInsufficientBalance(e.toString());
      if (insufficient != null && mounted) {
        final topUp = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Wallet Balance Low'),
            content: Text(
              'Wallet balance Rs.${insufficient.current.toStringAsFixed(0)}. Need Rs.${insufficient.required.toStringAsFixed(0)} to confirm. Top up?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Top Up'),
              ),
            ],
          ),
        );
        if (topUp == true && mounted) {
          Navigator.pushNamed(context, '/wallet');
        }
        return;
      }
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  _InsufficientBalanceData? _parseInsufficientBalance(String errorText) {
    try {
      final start = errorText.indexOf('{');
      if (start == -1) return null;
      final jsonPart = errorText.substring(start);
      final payload = jsonDecode(jsonPart) as Map<String, dynamic>;
      if (payload['code'] != 'INSUFFICIENT_BALANCE') return null;
      final required = (payload['required'] as num?)?.toDouble() ?? 0;
      final current = (payload['current'] as num?)?.toDouble() ?? 0;
      return _InsufficientBalanceData(required: required, current: current);
    } catch (_) {
      return null;
    }
  }

  Future<void> _startRide(String dealId) async {
    if (_rideId == null) return;
    try {
      await Provider.of<FirestoreService>(
        context,
        listen: false,
      ).startDeal(dealId);
      _locationService.startCaptainTracking(_rideId!);
      if (mounted) {
        AppHelpers.showSnackBar(
            context, 'Ride started - sharing your location');
        await _loadDeals(showLoading: false);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _counter(String dealId, double currentFare) async {
    final controller = TextEditingController(
      text: currentFare > 0 ? currentFare.toStringAsFixed(0) : '',
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adjust Fare'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Your price (Rs)',
            prefixText: 'Rs ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              Navigator.pop(ctx, value);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null) return;

    try {
      await Provider.of<FirestoreService>(
        context,
        listen: false,
      ).counterDeal(dealId, amount);
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Adjusted fare sent');
        await _loadDeals(showLoading: false);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _dealsSub?.cancel();
    _locationService.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _pending =>
      _deals.where((d) => d['status'] == 'pending').toList();

  List<Map<String, dynamic>> get _confirmed => _deals
      .where((d) => ['confirmed', 'started'].contains(d['status']))
      .toList();

  List<Map<String, dynamic>> get _responded => _deals
      .where((d) => !['pending', 'confirmed', 'started'].contains(d['status']))
      .toList();

  @override
  Widget build(BuildContext context) {
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
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
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
                            color: AppColors.white.withValues(alpha:0.15),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ride Requests',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _totalSeats > 0
                                  ? '$_confirmedSeats / $_totalSeats seats confirmed'
                                  : 'Accept or decline passengers',
                              style: const TextStyle(
                                color: Color(0xAAFFFFFF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor: AppColors.bark,
                      unselectedLabelColor: AppColors.white,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      tabs: [
                        Tab(child: _tabLabel('Pending', _pending.length)),
                        Tab(child: _tabLabel('Confirmed', _confirmed.length)),
                        Tab(child: _tabLabel('History', _responded.length)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const SkeletonList(item: RequestCardSkeleton(), count: 4)
                      : TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _buildList(_pending, isPending: true),
                            _buildConfirmedList(),
                            _buildList(_responded, isPending: false),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactActions(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return const Text(
        'Customer phone not available yet',
        style: TextStyle(color: AppColors.sage, fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer: $phone',
          style: const TextStyle(
            color: AppColors.bark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => dialPhone(context, phone),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Call'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => openWhatsApp(context, phone),
                icon: const Icon(Icons.chat_outlined),
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
    );
  }

  Widget _buildRideSummaryCard() {
    if (_rideLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: RideCardSkeleton(),
      );
    }
    if (_ride == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('Ride details unavailable.'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ivory),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_ride!.startLocation} → ${_ride!.endLocation}',
              style: const TextStyle(
                color: AppColors.bark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (AppHelpers.hasDisplayValue(_ride!.exactLocation)) ...[
              const SizedBox(height: 6),
              Text(
                'Exact pickup: ${_ride!.exactLocation}',
                style: const TextStyle(
                  color: AppColors.sage,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (AppHelpers.hasDisplayValue(_ride!.exactDropLocation)) ...[
              const SizedBox(height: 6),
              Text(
                'Exact drop: ${_ride!.exactDropLocation}',
                style: const TextStyle(
                  color: AppColors.sage,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Fare Rs ${_ride!.suggestedFare.toStringAsFixed(0)} · ${AppHelpers.formatDateTime(_ride!.departureTime)}',
              style: const TextStyle(
                color: AppColors.moss,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markBoarded(String dealId) async {
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .updateBoardingStatus(dealId: dealId, boardingStatus: 'boarded');
      await _loadDeals(showLoading: false);
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Passenger marked as boarded');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Update failed: $e', isError: true);
      }
    }
  }

  Widget _tabLabel(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmedList() {
    if (_confirmed.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildRideSummaryCard(),
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'No confirmed passengers yet.',
              style: TextStyle(color: AppColors.sage, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _confirmed.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _buildRideSummaryCard();
        final d = _confirmed[i - 1];
        final customer = d['customer'] as Map<String, dynamic>? ?? {};
        final name = customer['name'] ?? d['customerName'] ?? 'Passenger';
        final customerPhone =
            customer['phone'] ?? d['customerPhone'] ?? d['passengerPhone'];
        final pickup =
            RideModel.formatLocationLabel(d['passengerPickupAddress']);
        final drop = RideModel.formatLocationLabel(d['passengerDropAddress']);
        final lat = (d['passengerPickupLat'] ?? 0).toDouble();
        final lng = (d['passengerPickupLng'] ?? 0).toDouble();
        final dealId = d['id']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.moss.withValues(alpha:0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                'Rs ${(d['agreedFare'] ?? 0).toString()}',
                style: const TextStyle(
                  color: AppColors.moss,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (pickup.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Pickup: $pickup',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (drop.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Drop: $drop',
                  style: const TextStyle(fontSize: 12, color: AppColors.sage),
                ),
              ],
              const SizedBox(height: 10),
              _contactActions(customerPhone?.toString()),
              if (lat != 0 && lng != 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 120,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(lat, lng),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId('pickup_$dealId'),
                          position: LatLng(lat, lng),
                          infoWindow: InfoWindow(title: name, snippet: pickup),
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
              if (['confirmed', 'started'].contains(d['status']) &&
                  dealId.isNotEmpty &&
                  (d['boardingStatus'] ?? 'waiting') != 'boarded') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _markBoarded(dealId),
                    child: const Text('Mark Passenger as Boarded'),
                  ),
                ),
              ],
              if (d['status'] == 'confirmed' && dealId.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _startRide(dealId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bark,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Start Ride (all passengers)'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> deals, {
    required bool isPending,
  }) {
    if (deals.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildRideSummaryCard(),
          const SizedBox(height: 32),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPending ? Icons.hail_rounded : Icons.history_rounded,
                  color: AppColors.moss.withValues(alpha:0.3),
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  isPending
                      ? 'No pending requests.'
                      : 'No done/history requests yet.',
                  style: const TextStyle(
                    color: AppColors.sage,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: deals.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _buildRideSummaryCard();
        final d = deals[i - 1];
        final customer = d['customer'] as Map<String, dynamic>? ?? {};
        final name = customer['name'] ?? d['customerName'] ?? 'Passenger';
        final customerPhone =
            customer['phone'] ?? d['customerPhone'] ?? d['passengerPhone'];
        final initials =
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
        final fare = (d['agreedFare'] ?? 0).toDouble();
        final dealId = d['id'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.sage.withValues(alpha:0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.moss.withValues(alpha:0.1),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.moss,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.bark,
                          ),
                        ),
                        Text(
                          '${(customer['rating'] ?? 0).toString()} rating',
                          style: const TextStyle(
                            color: AppColors.sage,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs ${fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.moss,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if ((d['customerMessage'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  d['customerMessage'],
                  style: const TextStyle(color: AppColors.sage, fontSize: 13),
                ),
              ],
              if (isPending &&
                  RideModel.formatLocationLabel(d['passengerPickupAddress'])
                      .isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Exact pickup: ${RideModel.formatLocationLabel(d['passengerPickupAddress'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (isPending &&
                  RideModel.formatLocationLabel(d['passengerDropAddress'])
                      .isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Exact drop: ${RideModel.formatLocationLabel(d['passengerDropAddress'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (!isPending && dealId.isNotEmpty) ...[
                const SizedBox(height: 12),
                DealChatPanel(dealId: dealId, height: 120),
                const SizedBox(height: 12),
                _contactActions(customerPhone?.toString()),
              ],
              if (!isPending) ...[
                const SizedBox(height: 12),
                Text(
                  'Status: ${d['status']}',
                  style: const TextStyle(
                    color: AppColors.bark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (d['status'] == 'confirmed') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startRide(dealId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bark,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text(
                        'Start Ride',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
                if (d['status'] == 'started') ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Location sharing active',
                    style: TextStyle(color: AppColors.moss, fontSize: 12),
                  ),
                ],
              ],
              if (isPending) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _counter(dealId, fare),
                        child: const Text('Adjust Fare'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _accept(dealId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.moss,
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;

  const _SummaryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sage.withValues(alpha:0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.bark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InsufficientBalanceData {
  final double required;
  final double current;
  _InsufficientBalanceData({required this.required, required this.current});
}

