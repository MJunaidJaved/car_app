import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/location_tracking_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/deal_chat_panel.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _rideId;
  List<Map<String, dynamic>> _deals = [];
  bool _loading = true;
  final _locationService = LocationTrackingService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _dealsSub;
  Timer? _pollTimer;
  int _totalSeats = 0;
  int _confirmedSeats = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rideId = ModalRoute.of(context)?.settings.arguments as String?;
      _loadDeals();
      _subscribeDeals();
      _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadDeals());
    });
  }

  void _subscribeDeals() {
    if (_rideId == null) return;
    _dealsSub?.cancel();
    _dealsSub = FirebaseFirestore.instance
        .collection('deals')
        .where('rideId', isEqualTo: _rideId)
        .snapshots()
        .listen((_) => _loadDeals());
  }

  void _updateSeatCounts() {
    _confirmedSeats = _deals
        .where((d) => ['confirmed', 'started', 'completed'].contains(d['status']))
        .length;
    final ride = _deals.isNotEmpty ? _deals.first['ride'] as Map<String, dynamic>? : null;
    _totalSeats = (ride?['totalSeats'] ?? 0) as int;
    if (_totalSeats == 0 && _rideId != null) {
      FirebaseFirestore.instance.collection('rides').doc(_rideId).get().then((doc) {
        if (doc.exists && mounted) {
          setState(() => _totalSeats = (doc.data()?['totalSeats'] ?? 0) as int);
        }
      });
    }
  }

  Future<void> _loadDeals() async {
    if (_rideId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final service = Provider.of<FirestoreService>(context, listen: false);
      final deals = await service.getRideDeals(_rideId!);
      if (mounted) {
        setState(() {
          _deals = deals;
          _loading = false;
        });
        _updateSeatCounts();
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    }
  }

  Future<void> _accept(String dealId) async {
    try {
      await Provider.of<FirestoreService>(context, listen: false).confirmDeal(dealId);
      await Provider.of<UserProvider>(context, listen: false).reloadWallet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request accepted — commission deducted')));
        await _loadDeals();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _startRide(String dealId) async {
    if (_rideId == null) return;
    try {
      await Provider.of<FirestoreService>(context, listen: false).startDeal(dealId);
      _locationService.startCaptainTracking(_rideId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride started — sharing your location')),
        );
        await _loadDeals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _decline(String dealId) async {
    try {
      await Provider.of<FirestoreService>(context, listen: false).cancelDeal(dealId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request declined')));
        await _loadDeals();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _dealsSub?.cancel();
    _pollTimer?.cancel();
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
            top: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bark, AppColors.moss],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
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
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ride Requests', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            Text(
                              _totalSeats > 0
                                  ? '$_confirmedSeats / $_totalSeats seats confirmed'
                                  : 'Accept or decline passengers',
                              style: const TextStyle(color: Color(0xAAFFFFFF), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                      labelColor: AppColors.bark,
                      unselectedLabelColor: AppColors.white,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Pending'),
                        Tab(text: 'Confirmed'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
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

  Widget _buildConfirmedList() {
    if (_confirmed.isEmpty) {
      return const Center(
        child: Text(
          'No confirmed passengers yet.',
          style: TextStyle(color: AppColors.sage, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _confirmed.length,
      itemBuilder: (context, i) {
        final d = _confirmed[i];
        final customer = d['customer'] as Map<String, dynamic>? ?? {};
        final name = customer['name'] ?? d['customerName'] ?? 'Passenger';
        final pickup = d['passengerPickupAddress']?.toString() ?? '';
        final drop = d['passengerDropAddress']?.toString() ?? '';
        final lat = (d['passengerPickupLat'] ?? 0).toDouble();
        final lng = (d['passengerPickupLng'] ?? 0).toDouble();
        final dealId = d['id']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.moss.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('Rs ${(d['agreedFare'] ?? 0).toString()}', style: const TextStyle(color: AppColors.moss, fontWeight: FontWeight.w800)),
              if (pickup.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Pickup: $pickup', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
              if (drop.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Drop: $drop', style: const TextStyle(fontSize: 12, color: AppColors.sage)),
              ],
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
              if (d['status'] == 'confirmed' && dealId.isNotEmpty) ...[
                const SizedBox(height: 12),
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

  Widget _buildList(List<Map<String, dynamic>> deals, {required bool isPending}) {
    if (deals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPending ? Icons.hail_rounded : Icons.history_rounded, color: AppColors.moss.withOpacity(0.3), size: 64),
            const SizedBox(height: 12),
            Text(
              isPending ? 'No pending requests.' : 'No responded requests yet.',
              style: const TextStyle(color: AppColors.sage, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: deals.length,
      itemBuilder: (context, i) {
        final d = deals[i];
        final customer = d['customer'] as Map<String, dynamic>? ?? {};
        final name = customer['name'] ?? d['customerName'] ?? 'Passenger';
        final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
        final fare = (d['agreedFare'] ?? 0).toDouble();
        final dealId = d['id'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.sage.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.moss.withOpacity(0.1),
                    child: Text(initials, style: const TextStyle(color: AppColors.moss, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.bark)),
                        Text('${(customer['rating'] ?? 0).toString()} rating', style: const TextStyle(color: AppColors.sage, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('Rs ${fare.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.moss, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
              if ((d['customerMessage'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(d['customerMessage'], style: const TextStyle(color: AppColors.sage, fontSize: 13)),
              ],
              if (isPending &&
                  (d['passengerPickupAddress']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Pickup: ${d['passengerPickupAddress']}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
              if (!isPending && dealId.isNotEmpty) ...[
                const SizedBox(height: 12),
                DealChatPanel(dealId: dealId, height: 120),
              ],
              if (!isPending) ...[
                const SizedBox(height: 12),
                Text('Status: ${d['status']}', style: const TextStyle(color: AppColors.bark, fontWeight: FontWeight.w700)),
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
                      child: const Text('Start Ride', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
                if (d['status'] == 'started') ...[
                  const SizedBox(height: 8),
                  const Text('Location sharing active', style: TextStyle(color: AppColors.moss, fontSize: 12)),
                ],
              ],
              if (isPending) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _decline(dealId),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _accept(dealId),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.moss, foregroundColor: AppColors.white),
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
