import 'dart:async';

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/skeleton_loader.dart';
import 'package:flutter/services.dart';
import '../../models/ride_model.dart';
import '../../services/api_service.dart';
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
      // The request can resolve after the user has already navigated away
      // from this screen (e.g. the 20-second background refresh timer, or
      // simply backing out mid-request). Calling setState on an unmounted
      // State throws and crashes the app, so this guard is required both
      // on the success path and in the catch block below.
      if (!mounted) return;
      final rawRides = res['rides'];
      setState(() {
        _rides = rawRides is List
            ? rawRides
            .whereType<Object?>()
            .map((r) => r is Map
            ? Map<String, dynamic>.from(r)
            : <String, dynamic>{})
            .toList()
            : <Map<String, dynamic>>[];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelRide(String rideId) async {
    if (rideId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel ride?'),
        content: const Text(
          'This will remove the ride from active listings. Existing passengers should be informed before cancelling.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.patch('/rides/$rideId/status', {'status': 'cancelled'});
      if (!mounted) return;
      setState(() {
        final index =
        _rides.indexWhere((r) => (r['id'] ?? '').toString() == rideId);
        if (index >= 0) {
          _rides[index] = {
            ..._rides[index],
            'status': 'cancelled',
            'updatedAt': DateTime.now().toIso8601String(),
          };
        }
      });
      AppHelpers.showSnackBar(context, 'Ride cancelled');
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Cancel failed: $e', isError: true);
      }
    }
  }

  Future<void> _deleteRide(String rideId) async {
    if (rideId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ride?'),
        content: const Text(
            'This will permanently remove the ride from listings. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
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
      await ApiService.delete('/rides/$rideId');
      if (!mounted) return;
      setState(() {
        _rides.removeWhere((r) => (r['id'] ?? '').toString() == rideId);
      });
      AppHelpers.showSnackBar(context, 'Ride deleted');
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'Delete failed: $e', isError: true);
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
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
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
                              color: AppColors.white.withValues(alpha: 0.15),
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
                          backgroundColor:
                          AppColors.white.withValues(alpha: 0.15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.1),
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
                              selectedColor:
                              AppColors.moss.withValues(alpha: 0.2),
                              labelStyle: const TextStyle(
                                  color: AppColors.bark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                      color: AppColors.sage
                                          .withValues(alpha: 0.2))),
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
                          if (_loading) {
                            return const SkeletonList(
                              item: RideCardSkeleton(),
                              count: 4,
                            );
                          }
                          final activeRides = _rides.where((r) {
                            final status =
                            (r['status'] ?? '').toString().toLowerCase();
                            if (status != 'active' && status != 'in_progress') {
                              return false;
                            }
                            final departure = DateTime.tryParse(
                                (r['departureTime'] ?? '').toString());
                            if (departure != null &&
                                departure.isBefore(DateTime.now())) {
                              return false;
                            }
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
                                      color:
                                      AppColors.moss.withValues(alpha: 0.3),
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
                                key: ValueKey('active_${r['id'] ?? i}'),
                                rideId: r['id'] ?? '',
                                startLocation: RideModel.formatLocationLabel(
                                    r['startLocation']),
                                endLocation: RideModel.formatLocationLabel(
                                    r['endLocation']),
                                departureTime: r['departureTime'] ?? '',
                                suggestedFare:
                                (r['suggestedFare'] ?? 0).toDouble(),
                                availableSeats: r['availableSeats'] ?? 0,
                                totalSeats: r['totalSeats'] ?? 0,
                                vehicleInfo: RideModel.formatVehicleInfo(
                                  r['vehicleInfo'] ?? r['vehicleType'],
                                ),
                                rideType: r['rideType'] ?? 'office',
                                rideMode: (r['rideMode'] ?? 'share').toString(),
                                status: r['status'] ?? 'active',
                                exactLocation: RideModel.formatLocationLabel(
                                  r['exactLocation'],
                                ),
                                exactDropLocation:
                                RideModel.formatLocationLabel(
                                  r['exactDropLocation'],
                                ),
                                onCancel: () => _cancelRide(r['id'] ?? ''),
                                onEdit: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    '/post-ride',
                                    arguments: {'ride': r},
                                  );
                                  if (context.mounted) _loadRides(showLoading: false);
                                },
                                onDelete: () => _deleteRide(r['id'] ?? ''),
                              );
                            },
                          );
                        }),
                        Builder(builder: (context) {
                          if (_loading) {
                            return const SkeletonList(
                              item: RideCardSkeleton(),
                              count: 4,
                            );
                          }
                          final pastRides = _rides.where((r) {
                            if (r['status'] != 'completed' &&
                                r['status'] != 'cancelled') {
                              return false;
                            }
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
                                      color:
                                      AppColors.moss.withValues(alpha: 0.3),
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
                                key: ValueKey('past_${r['id'] ?? i}'),
                                rideId: r['id'] ?? '',
                                startLocation: RideModel.formatLocationLabel(
                                    r['startLocation']),
                                endLocation: RideModel.formatLocationLabel(
                                    r['endLocation']),
                                departureTime: r['departureTime'] ?? '',
                                suggestedFare:
                                (r['suggestedFare'] ?? 0).toDouble(),
                                availableSeats: r['availableSeats'] ?? 0,
                                totalSeats: r['totalSeats'] ?? 0,
                                vehicleInfo: RideModel.formatVehicleInfo(
                                  r['vehicleInfo'] ?? r['vehicleType'],
                                ),
                                rideType: r['rideType'] ?? 'office',
                                rideMode: (r['rideMode'] ?? 'share').toString(),
                                status: r['status'] ?? 'completed',
                                exactLocation: RideModel.formatLocationLabel(
                                  r['exactLocation'],
                                ),
                                exactDropLocation:
                                RideModel.formatLocationLabel(
                                  r['exactDropLocation'],
                                ),
                                onDelete: () => _deleteRide(r['id'] ?? ''),
                                isCompleted: true,
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
  final String vehicleInfo;
  final String rideType;
  final String rideMode;
  final String status;
  final String exactLocation;
  final String exactDropLocation;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? passengerPhone;
  final bool isCompleted;

  const _CaptainRideCard({
    super.key,
    required this.rideId,
    required this.startLocation,
    required this.endLocation,
    required this.departureTime,
    required this.suggestedFare,
    required this.availableSeats,
    required this.totalSeats,
    required this.vehicleInfo,
    required this.rideType,
    this.rideMode = 'share',
    required this.status,
    this.exactLocation = '',
    this.exactDropLocation = '',
    this.onCancel,
    this.onEdit,
    this.onDelete,
    this.passengerPhone,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = AppHelpers.formatDateTimeValue(departureTime);
    final isShareRide = rideMode.toLowerCase() != 'solo';
    final isTour = rideType.toLowerCase() == 'tour';
    final primaryThemeColor =
    isTour ? AppColors.emerald : AppColors.royalBlue;
    final secondaryAccent =
    isTour ? AppColors.success : AppColors.darkRoyalBlue;
    final routeColor = AppColors.deepNavy;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryThemeColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: primaryThemeColor.withOpacity(0.06),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryThemeColor, secondaryAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryThemeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rideType.toUpperCase(),
                          style: TextStyle(
                            color: primaryThemeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isShareRide
                                  ? Colors.green[50]
                                  : Colors.deepOrange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isShareRide ? 'SHARE' : 'SOLO',
                              style: TextStyle(
                                color: isShareRide
                                    ? Colors.green[800]
                                    : Colors.deepOrange[800],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == 'active'
                                  ? Colors.green[50]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status.toLowerCase() == 'active'
                                    ? Colors.green[800]
                                    : Colors.grey[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: primaryThemeColor.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            startLocation.isEmpty ? 'From' : startLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: routeColor,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded,
                            color: primaryThemeColor, size: 24),
                        Expanded(
                          child: Text(
                            endLocation.isEmpty ? 'To' : endLocation,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: routeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (AppHelpers.hasDisplayValue(exactLocation) ||
                      AppHelpers.hasDisplayValue(exactDropLocation)) ...[
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (AppHelpers.hasDisplayValue(exactLocation))
                          Text(
                            'From exact: $exactLocation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.sage,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (AppHelpers.hasDisplayValue(exactDropLocation))
                          Text(
                            'To exact: $exactDropLocation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.sage,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                  const Divider(height: 24, thickness: 1),
                  Row(
                    children: [
                      Icon(Icons.watch_later_outlined,
                          size: 16, color: primaryThemeColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.airline_seat_recline_normal_rounded,
                                size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              '$availableSeats/$totalSeats seats',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (vehicleInfo.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_car_rounded,
                                  size: 16, color: Colors.purple[700]),
                              const SizedBox(width: 4),
                              Text(
                                vehicleInfo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        AppHelpers.formatCurrency(suggestedFare),
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/requests',
                            arguments: rideId,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.moss,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            minimumSize: const Size.fromHeight(40),
                          ),
                          child: const Text(
                            'Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCompleted && (passengerPhone?.isNotEmpty ?? false)) ...[
                        SizedBox(
                          width: 80,
                          child: OutlinedButton.icon(
                            onPressed: () => dialPhone(context, passengerPhone!),
                            icon: const Icon(Icons.call, size: 16),
                            label: const Text('Call', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.bark,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              minimumSize: const Size.fromHeight(36),
                              side: BorderSide(color: AppColors.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: OutlinedButton.icon(
                            onPressed: () => openWhatsApp(context, passengerPhone!),
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('WhatsApp', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.bark,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              minimumSize: const Size.fromHeight(36),
                              side: BorderSide(color: AppColors.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else if (!isCompleted && onEdit != null) ...[
                        SizedBox(
                          width: 90,
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.bark,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              minimumSize: const Size.fromHeight(36),
                              side: BorderSide(color: AppColors.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (onDelete != null) ...[
                        SizedBox(
                          width: 90,
                          child: OutlinedButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Delete', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              minimumSize: const Size.fromHeight(36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
          border: Border.all(color: AppColors.sage.withValues(alpha: 0.1))),
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
