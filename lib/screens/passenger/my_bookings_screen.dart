import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../services/deal_realtime_service.dart';
import '../../utils/phone_utils.dart';
import '../../utils/deal_status_utils.dart';
import 'package:provider/provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String _selectedFilter = 'all';
  final _filters = ['all', 'upcoming', 'completed', 'cancelled'];
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  final _realtime = DealRealtimeService();

  @override
  void initState() {
    super.initState();
    _realtime.listenPassengerBookings(
      onData: (bookings) {
        if (mounted)
          setState(() {
            _bookings = bookings;
            _loading = false;
          });
      },
      onError: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  void dispose() {
    _realtime.stop();
    super.dispose();
  }

  Future<void> _cancelBooking(String dealId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This will cancel your ride request.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .cancelDeal(dealId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Cancel failed: $e'), duration: const Duration(seconds: 2)));
      }
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
                  colors: [AppColors.dark, AppColors.primary],
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Bookings',
                              style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          Text('Your booked rides',
                              style: TextStyle(
                                  color: Color(0xAAFFFFFF), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final f = _filters[i];
                      final isSelected = _selectedFilter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            f[0].toUpperCase() + f.substring(1),
                            style: TextStyle(
                                color: isSelected
                                    ? AppColors.dark
                                    : AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Builder(
                          builder: (context) {
                            final filtered = _bookings.where((b) {
                              if (_selectedFilter == 'all') return true;
                              final status = b['status'] ?? '';
                              if (_selectedFilter == 'upcoming') {
                                return status == 'pending' ||
                                    status == 'confirmed' ||
                                    status == 'started';
                              }
                              return status == _selectedFilter;
                            }).toList();

                            if (filtered.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        color: AppColors.moss.withOpacity(0.3),
                                        size: 64),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No bookings yet. Find a ride to get started.',
                                      style: TextStyle(
                                          color: AppColors.sage,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final b = filtered[i];
                                final ride =
                                    b['ride'] as Map<String, dynamic>? ?? {};
                                final rideId = b['rideId'] ?? ride['id'] ?? '';
                                final dealId = b['id'] ?? '';
                                final captain =
                                    b['captain'] as Map<String, dynamic>? ?? {};
                                final captainPhone =
                                    b['captainPhone']?.toString() ??
                                        captain['phone']?.toString() ??
                                        ride['captainPhone']?.toString() ??
                                        '';
                                return _BookingCard(
                                  dealId: dealId,
                                  captainName: ride['captainName'] ?? 'Captain',
                                  startLocation: ride['startLocation'] ?? '',
                                  endLocation: ride['endLocation'] ?? '',
                                  fare: (b['agreedFare'] ?? 0).toDouble(),
                                  status: b['status'] ?? 'pending',
                                  rideId: rideId,
                                  captainPhone: captainPhone,
                                  canRate: b['status'] == 'completed' &&
                                      b['rating'] == null,
                                  onCancel: () => _cancelBooking(dealId),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String dealId;
  final String rideId;
  final String captainName;
  final String startLocation;
  final String endLocation;
  final double fare;
  final String status;
  final String captainPhone;
  final bool canRate;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.dealId,
    required this.rideId,
    required this.captainName,
    required this.startLocation,
    required this.endLocation,
    required this.fare,
    required this.status,
    required this.captainPhone,
    this.canRate = false,
    required this.onCancel,
  });

  Color get _statusColor {
    switch (status) {
      case 'confirmed':
        return AppColors.moss;
      case 'started':
        return AppColors.primary;
      case 'completed':
        return AppColors.bark;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.sage;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'started':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canTrack = canTrackDeal(status);
    final canCancel = canCancelDeal(status);
    final isRevealed =
        status == 'confirmed' || status == 'started' || status == 'completed';
    final displayPhone = isRevealed ? captainPhone : '03**-*****';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.light),
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.moss.withOpacity(0.1),
                child: Text(
                  captainName.isNotEmpty ? captainName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.moss,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(captainName,
                    style: const TextStyle(
                        color: AppColors.bark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(_statusLabel,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.light),
          const SizedBox(height: 16),
          Text(startLocation,
              style: const TextStyle(
                  color: AppColors.bark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(endLocation,
              style: const TextStyle(
                  color: AppColors.bark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.light),
            ),
            child: Row(
              children: [
                Icon(
                  isRevealed ? Icons.phone_rounded : Icons.lock_outline_rounded,
                  color: isRevealed ? AppColors.moss : AppColors.sage,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayPhone,
                        style: const TextStyle(
                          color: AppColors.bark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!isRevealed)
                        const Text(
                          'Revealed after captain accepts',
                          style: TextStyle(
                            color: AppColors.sage,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isRevealed && captainPhone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.call_rounded, color: AppColors.moss),
                    onPressed: () => dialPhone(context, captainPhone),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Rs ${fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.moss,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const Spacer(),
              if (canCancel)
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w700)),
                ),
              if (canTrack)
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/active-ride',
                      arguments: {'rideId': rideId, 'dealId': dealId}),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bark,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0),
                  child: Text(status == 'started' ? 'Track Live' : 'Track',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              if (canRate)
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/rate-review',
                      arguments: dealId),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bg,
                      foregroundColor: AppColors.moss,
                      side: const BorderSide(color: AppColors.moss),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0),
                  child: const Text('Rate Now',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


