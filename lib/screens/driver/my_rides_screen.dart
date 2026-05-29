import 'dart:async';

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/notification_bell.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});
  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _rides = [];
  bool _loading = true;
  String _typeFilter = 'All';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadRides();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadRides(showLoading: false),
    );
  }

  Future<void> _loadRides({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final res = await ApiService.get('/rides/my-rides');
      setState(() {
        _rides = List<Map<String, dynamic>>.from(res['rides'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteRide(String rideId) async {
    try {
      await ApiService.patch('/rides/$rideId/status', {'status': 'cancelled'});
      await _loadRides(showLoading: false);
      if (mounted) AppHelpers.showSnackBar(context, 'Ride removed');
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabCtrl.dispose();
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
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
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
            child: RefreshIndicator(
              onRefresh: () => _loadRides(showLoading: false),
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppColors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Rides',
                                  style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800)),
                              Text('Manage your postings',
                                  style: TextStyle(
                                      color: Color(0xAAFFFFFF), fontSize: 13)),
                            ],
                          ),
                        ),
                        NotificationBell(
                          iconColor: AppColors.white,
                          backgroundColor: AppColors.white.withOpacity(0.15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                        indicator: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        labelColor: AppColors.bark,
                        unselectedLabelColor: AppColors.white,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                        tabs: const [
                          Tab(text: 'Active'),
                          Tab(text: 'Done'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children:
                            ['All', 'Office', 'Tour', 'Delivery'].map((filter) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(filter),
                              selected: _typeFilter == filter,
                              onSelected: (_) =>
                                  setState(() => _typeFilter = filter),
                              backgroundColor: AppColors.white,
                              selectedColor: AppColors.moss.withOpacity(0.2),
                              labelStyle: const TextStyle(
                                  color: AppColors.bark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                      color: AppColors.sage.withOpacity(0.2))),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        Builder(builder: (context) {
                          if (_loading)
                            return const Center(
                                child: CircularProgressIndicator());
                          final activeRides = _rides.where((r) {
                            final status =
                                (r['status'] ?? '').toString().toLowerCase();
                            if (status != 'active' && status != 'in_progress')
                              return false;
                            final departure = DateTime.tryParse(
                                (r['departureTime'] ?? '').toString());
                            if (departure != null &&
                                departure.isBefore(DateTime.now()))
                              return false;
                            if (_typeFilter == 'All') return true;
                            return (r['rideType'] ?? '')
                                    .toString()
                                    .toLowerCase() ==
                                _typeFilter.toLowerCase();
                          }).toList();
                          if (activeRides.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.directions_car_outlined,
                                      color: AppColors.moss.withOpacity(0.3),
                                      size: 64),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'No rides posted yet. Post your first ride.',
                                      style: TextStyle(
                                          color: AppColors.sage,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: activeRides.length,
                            itemBuilder: (context, i) {
                              final r = activeRides[i];
                              return _CaptainRideCard(
                                rideId: r['id'] ?? '',
                                startLocation: r['startLocation'] ?? '',
                                endLocation: r['endLocation'] ?? '',
                                departureTime: r['departureTime'] ?? '',
                                suggestedFare:
                                    (r['suggestedFare'] ?? 0).toDouble(),
                                availableSeats: r['availableSeats'] ?? 0,
                                totalSeats: r['totalSeats'] ?? 0,
                                rideType: r['rideType'] ?? 'office',
                                status: r['status'] ?? 'active',
                                exactLocation:
                                    (r['exactLocation'] ?? '').toString(),
                                exactDropLocation:
                                    (r['exactDropLocation'] ?? '').toString(),
                                onDelete: () => _deleteRide(r['id'] ?? ''),
                              );
                            },
                          );
                        }),
                        Builder(builder: (context) {
                          if (_loading)
                            return const Center(
                                child: CircularProgressIndicator());
                          final pastRides = _rides.where((r) {
                            if (r['status'] != 'completed' &&
                                r['status'] != 'cancelled') return false;
                            if (_typeFilter == 'All') return true;
                            return (r['rideType'] ?? '')
                                    .toString()
                                    .toLowerCase() ==
                                _typeFilter.toLowerCase();
                          }).toList();
                          if (pastRides.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history_rounded,
                                      color: AppColors.moss.withOpacity(0.3),
                                      size: 64),
                                  const SizedBox(height: 12),
                                  const Text('No done rides found.',
                                      style: TextStyle(
                                          color: AppColors.sage,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: pastRides.length,
                            itemBuilder: (context, i) {
                              final r = pastRides[i];
                              return _CaptainRideCard(
                                rideId: r['id'] ?? '',
                                startLocation: r['startLocation'] ?? '',
                                endLocation: r['endLocation'] ?? '',
                                departureTime: r['departureTime'] ?? '',
                                suggestedFare:
                                    (r['suggestedFare'] ?? 0).toDouble(),
                                availableSeats: r['availableSeats'] ?? 0,
                                totalSeats: r['totalSeats'] ?? 0,
                                rideType: r['rideType'] ?? 'office',
                                status: r['status'] ?? 'completed',
                                exactLocation:
                                    (r['exactLocation'] ?? '').toString(),
                                exactDropLocation:
                                    (r['exactDropLocation'] ?? '').toString(),
                                onDelete: null,
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/post-ride');
          if (context.mounted) _loadRides(showLoading: false);
        },
        backgroundColor: AppColors.moss,
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
      ),
    );
  }
}

class _CaptainRideCard extends StatelessWidget {
  final String rideId;
  final String startLocation;
  final String endLocation;
  final String departureTime;
  final double suggestedFare;
  final int availableSeats;
  final int totalSeats;
  final String rideType;
  final String status;
  final String exactLocation;
  final String exactDropLocation;
  final VoidCallback? onDelete;

  const _CaptainRideCard({
    required this.rideId,
    required this.startLocation,
    required this.endLocation,
    required this.departureTime,
    required this.suggestedFare,
    required this.availableSeats,
    required this.totalSeats,
    required this.rideType,
    required this.status,
    this.exactLocation = '',
    this.exactDropLocation = '',
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    final dt = DateTime.tryParse(departureTime) ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sage.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (rideType == 'tour' ? Colors.blue : AppColors.moss)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(rideType.toUpperCase(),
                    style: TextStyle(
                        color:
                            rideType == 'tour' ? Colors.blue : AppColors.moss,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
              Text(
                  '${dt.day}/${dt.month} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      color: AppColors.sage,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.moss, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(startLocation,
                      style: const TextStyle(
                          color: AppColors.bark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (exactLocation.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Exact pickup: $exactLocation',
                style: const TextStyle(
                  color: AppColors.sage,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(
                width: 2, height: 12, color: AppColors.sage.withOpacity(0.2)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.moss, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(endLocation,
                      style: const TextStyle(
                          color: AppColors.bark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (exactDropLocation.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Exact drop: $exactDropLocation',
                style: const TextStyle(
                  color: AppColors.sage,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _InfoPill(
                  icon: Icons.event_seat_rounded,
                  label: '$availableSeats/$totalSeats seats'),
              const Spacer(),
              Text('Rs ${suggestedFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.bark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/requests',
                          arguments: rideId),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.moss,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text('Requests',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/requests',
                          arguments: rideId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.bark,
                        side:
                            BorderSide(color: AppColors.sage.withOpacity(0.35)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Details',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: AppColors.moss.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14)),
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded,
                        color: AppColors.moss, size: 20),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Route link copied!'),
                            duration: Duration(seconds: 2))),
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14)),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 20),
                      onPressed: onDelete,
                    ),
                  ),
                ],
              ],
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.sage.withOpacity(0.1))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.moss, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.bark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
