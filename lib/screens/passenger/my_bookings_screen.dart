import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../services/deal_realtime_service.dart';
import '../../utils/phone_utils.dart';
import '../../utils/deal_status_utils.dart';
import '../../utils/helpers.dart';
import '../../widgets/notification_bell.dart';
import 'package:provider/provider.dart';
import '../../models/ride_model.dart';

/// Parses a value that the backend/Firestore may hand back as num, String,
/// or null into a double, instead of crashing on `.toDouble()` when the
/// value happens to be a String (or missing). A crash here previously threw
/// inside ListView's itemBuilder, which Flutter silently swallows per-item —
/// the booking count badge (computed straight from the raw list) still
/// showed correctly, while the actual card for that booking rendered as a
/// near-invisible error box instead of the booking. This is why "the tab
/// number shows but the booking doesn't appear".
double _safeDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String _selectedFilter = 'all';
  final _filters = ['all', 'upcoming', 'confirmed', 'completed'];
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  final _realtime = DealRealtimeService();

  bool _isVisibleBooking(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toLowerCase();
    if (['pending', 'confirmed', 'started'].contains(status)) {
      return true;
    }
    if (['completed', 'cancelled'].contains(status)) {
      final completedAt = booking['completedAt'] ??
          booking['updatedAt'] ??
          booking['createdAt'];
      if (completedAt != null) {
        try {
          final date = DateTime.parse(completedAt.toString());
          final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
          return date.isAfter(threeDaysAgo);
        } catch (_) {
          return false;
        }
      }
      return false;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _realtime.listenPassengerBookings(
      onData: (bookings) {
        if (mounted) {
          setState(() {
            _bookings = List<Map<String, dynamic>>.from(bookings)
                .where((b) => _isVisibleBooking(b))
                .toList();
            _loading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('MyBookingsScreen: bookings stream error: $e');
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  Future<void> _refreshBookings() async {
    try {
      final bookings = await Provider.of<FirestoreService>(
        context,
        listen: false,
      ).getMyBookings();
      if (mounted) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(bookings)
              .where((b) => _isVisibleBooking(b))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('MyBookingsScreen: manual refresh error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _realtime.stop();
    super.dispose();
  }

  Future<void> _cancelBooking(String dealId) async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text(
          'Are you sure you want to cancel? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await service.cancelDeal(dealId);
      await _refreshBookings();
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Booking cancelled');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Cancel failed: $e',
          isError: true,
        );
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
          // ✅ Gradient Background
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
                // ✅ AppBar with proper spacing
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
                      ),
                      NotificationBell(
                        icon: Icons.notifications_outlined,
                        iconColor: AppColors.white,
                        backgroundColor:
                        AppColors.white.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Filter Chips - Properly visible
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
                      final count = _bookingCount(f);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                f.isNotEmpty
                                    ? f[0].toUpperCase() + f.substring(1)
                                    : f,
                                style: TextStyle(
                                    color: isSelected
                                        ? AppColors.dark
                                        : AppColors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.white
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.white
                                          : AppColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ BOOKINGS LIST - Proper scrollable area
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshBookings,
                    color: AppColors.moss,
                    child: _loading
                        ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 300,
                          child:
                          Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    )
                        : Builder(
                      builder: (context) {
                        final filtered = _bookings.where((b) {
                          if (_selectedFilter == 'all') return true;
                          final status = (b['status'] ?? '')
                              .toString()
                              .toLowerCase();
                          final tabStatus = (b['tabStatus'] ?? '')
                              .toString()
                              .toLowerCase();
                          if (_selectedFilter == 'upcoming') {
                            return tabStatus == 'upcoming' ||
                                status == 'pending' ||
                                status == 'started';
                          }
                          if (_selectedFilter == 'confirmed') {
                            return tabStatus == 'confirmed' ||
                                status == 'confirmed';
                          }
                          return status == _selectedFilter;
                        }).toList();

                        if (filtered.isEmpty) {
                          return ListView(
                            physics:
                            const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                                20, 80, 20, 100),
                            children: [
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        color: AppColors.moss
                                            .withValues(alpha: 0.3),
                                        size: 64),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No bookings yet. Find a ride to get started.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.sage,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final b = filtered[i];
                            // ✅ Defensive: never let one malformed
                            // booking record silently blank out the
                            // whole card. If anything below throws,
                            // fall back to a clearly visible minimal
                            // card instead of an easy-to-miss error
                            // sliver, so the booking is always seen.
                            try {
                              final ride = b['ride']
                              as Map<String, dynamic>? ??
                                  {};
                              final rideId =
                                  b['rideId'] ?? ride['id'] ?? '';
                              final dealId = b['id'] ?? '';
                              final captain = b['captain']
                              as Map<String, dynamic>? ??
                                  {};
                              final captainPhone =
                                  b['captainPhone']?.toString() ??
                                      captain['phone']?.toString() ??
                                      ride['captainPhone']?.toString() ??
                                      '';
                              return _BookingCard(
                                dealId: dealId.toString(),
                                captainName:
                                ride['captainName'] ?? 'Captain',
                                startLocation:
                                RideModel.formatLocationLabel(
                                  ride['startLocation'],
                                ),
                                endLocation:
                                RideModel.formatLocationLabel(
                                  ride['endLocation'],
                                ),
                                fare: _safeDouble(b['agreedFare']),
                                status:
                                (b['status'] ?? 'pending').toString(),
                                rideId: rideId.toString(),
                                captainPhone: captainPhone,
                                pickupAddress:
                                RideModel.formatLocationLabel(
                                  b['passengerPickupAddress'] ??
                                      ride['exactLocation'],
                                ),
                                dropAddress:
                                RideModel.formatLocationLabel(
                                  b['passengerDropAddress'] ??
                                      ride['exactDropLocation'],
                                ),
                                rideMode: (b['ride']?['rideMode'] ??
                                    'share')
                                    .toString(),
                                canRate: b['status'] == 'completed' &&
                                    (b['canRate'] == true ||
                                        b['rating'] == null),
                                onCancel: () => _cancelBooking(
                                    dealId.toString()),
                                onRated: _refreshBookings,
                              );
                            } catch (e, st) {
                              debugPrint(
                                  'MyBookingsScreen: booking card build failed: $e\n$st');
                              return _BrokenBookingCard(
                                status: (b['status'] ?? '').toString(),
                                onCancel: () {
                                  final dealId =
                                  (b['id'] ?? '').toString();
                                  if (dealId.isNotEmpty) {
                                    _cancelBooking(dealId);
                                  }
                                },
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _bookingCount(String filter) {
    return _bookings.where((b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      final tabStatus = (b['tabStatus'] ?? '').toString().toLowerCase();
      if (filter == 'all') return true;
      if (filter == 'upcoming') {
        return tabStatus == 'upcoming' ||
            status == 'pending' ||
            status == 'started';
      }
      if (filter == 'confirmed') {
        return tabStatus == 'confirmed' || status == 'confirmed';
      }
      return status == filter;
    }).length;
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
  final String pickupAddress;
  final String dropAddress;
  final String rideMode;
  final bool canRate;
  final VoidCallback onCancel;
  final Future<void> Function()? onRated;

  const _BookingCard({
    required this.dealId,
    required this.rideId,
    required this.captainName,
    required this.startLocation,
    required this.endLocation,
    required this.fare,
    required this.status,
    required this.captainPhone,
    this.pickupAddress = '',
    this.dropAddress = '',
    this.rideMode = 'share',
    this.canRate = false,
    required this.onCancel,
    this.onRated,
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
        return AppColors.error;
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
    final isShareRide = rideMode.toLowerCase() != 'solo';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.light),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Captain Info Row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.moss.withValues(alpha: 0.1),
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
                    color: _statusColor.withValues(alpha: 0.1),
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

          // ✅ Share/Solo Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: (isShareRide ? Colors.green : Colors.deepOrange)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isShareRide ? 'SHARE RIDE' : 'SOLO RIDE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: isShareRide ? Colors.green[800] : Colors.deepOrange[800],
              ),
            ),
          ),

          // ✅ Location Details with proper styling
          Text(
            startLocation,
            style: const TextStyle(
              color: AppColors.bark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (pickupAddress.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '📍 $pickupAddress',
              style: const TextStyle(
                color: AppColors.sage,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            endLocation,
            style: const TextStyle(
              color: AppColors.bark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (dropAddress.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '📍 $dropAddress',
              style: const TextStyle(
                color: AppColors.sage,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // ✅ Phone Details
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
                if (isRevealed && captainPhone.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.call_rounded, color: AppColors.moss),
                    onPressed: () => dialPhone(context, captainPhone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_rounded, color: AppColors.moss),
                    onPressed: () => openWhatsApp(context, captainPhone),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ✅ Fare and Buttons
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
                          color: AppColors.error, fontWeight: FontWeight.w700)),
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
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      '/rate-review',
                      arguments: dealId,
                    );
                    await onRated?.call();
                  },
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

/// Shown instead of a booking card when that record's data couldn't be
/// read safely (see the try/catch around _BookingCard construction above).
/// Keeps the booking visible and lets the user still cancel it, rather
/// than it silently disappearing from the list.
class _BrokenBookingCard extends StatelessWidget {
  final String status;
  final VoidCallback onCancel;

  const _BrokenBookingCard({
    required this.status,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.light),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.isNotEmpty
                      ? 'Booking (${status[0].toUpperCase()}${status.substring(1)})'
                      : 'Booking',
                  style: const TextStyle(
                    color: AppColors.bark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Some details couldn\'t load. Pull down to refresh.',
                  style: TextStyle(
                    color: AppColors.sage,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
