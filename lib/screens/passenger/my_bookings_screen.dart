import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/ride_service.dart';
import '../../models/ride_model.dart';

class _C {
  static const primary   = Color(0xFF39988E);
  static const dark      = Color(0xFF1F6059);
  static const light     = Color(0xFFB6D7D1);
  static const bg        = Color(0xFFF5F5F5);
  static const white     = Color(0xFFFFFFFF);
  static const textDark  = Color(0xFF0D1F1E);
  static const textMuted = Color(0xFF7A9E9B);
}

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String _selectedFilter = 'all';
  final _filters = ['all', 'upcoming', 'completed', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, _C.primary],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color:        _C.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _C.white, size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Bookings',
                            style: TextStyle(
                              color:      _C.white,
                              fontSize:   20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Your booked rides',
                            style: TextStyle(
                              color:    Color(0xAAFFFFFF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Filter chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    padding:          const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection:  Axis.horizontal,
                    itemCount:        _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f          = _filters[i];
                      final isSelected = _selectedFilter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding:  const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _C.white
                                : _C.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? _C.primary
                                  : _C.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            f[0].toUpperCase() + f.substring(1),
                            style: TextStyle(
                              color:      isSelected ? _C.primary : _C.white,
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Bookings list
                Expanded(
                  child: FutureBuilder<List<RideModel>>(
                    future: Provider.of<RideService>(context, listen: false)
                        .getPassengerBookings(userProvider.user!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: _C.primary),
                        );
                      }

                      final bookings = snapshot.data ?? [];

                      if (bookings.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark_outline_rounded,
                                color: _C.light,
                                size:  64,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No bookings yet',
                                style: TextStyle(
                                  color:      _C.textMuted,
                                  fontSize:   15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, '/find-ride'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color:        _C.primary,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Find a Ride',
                                    style: TextStyle(
                                      color:      _C.white,
                                      fontSize:   14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        physics:     const BouncingScrollPhysics(),
                        padding:     const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount:   bookings.length,
                        itemBuilder: (context, i) =>
                            _BookingCard(ride: bookings[i]),
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
  final RideModel ride;
  const _BookingCard({required this.ride});

  Color get _statusColor {
    switch (ride.status) {
      case 'upcoming':  return const Color(0xFFFF9800);
      case 'completed': return _C.primary;
      case 'cancelled': return Colors.red;
      default:          return _C.textMuted;
    }
  }

  String get _statusLabel {
    switch (ride.status) {
      case 'upcoming':  return 'Upcoming';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default:          return 'Confirmed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      _C.dark.withOpacity(0.07),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Captain + status
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _C.light.withOpacity(0.5),
                child: Text(
                  (ride.captainName ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(
                    color:      _C.primary,
                    fontWeight: FontWeight.w700,
                    fontSize:   14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.captainName ?? 'Captain',
                      style: const TextStyle(
                        color:      _C.textDark,
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFC107), size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${ride.captainRating ?? 4.8}  •  Trust Score',
                          style: const TextStyle(
                              color: _C.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color:      _statusColor,
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF0F0F0), height: 1),
          const SizedBox(height: 12),

          // Route
          Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.circle,
                      color: _C.primary, size: 10),
                  Container(
                      width: 2, height: 20, color: _C.light),
                  Icon(Icons.circle_outlined,
                      color: _C.primary, size: 10),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.from,
                      style: const TextStyle(
                        color:      _C.textDark,
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ride.to,
                      style: const TextStyle(
                        color:      _C.textDark,
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs ${ride.offeredFare ?? '--'}',
                style: const TextStyle(
                  color:      _C.primary,
                  fontSize:   16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom chips
          Row(
            children: [
              _InfoPill(
                icon:  Icons.access_time_rounded,
                label: '${ride.departureTime.hour}:${ride.departureTime.minute.toString().padLeft(2, '0')} ${ride.departureTime.hour >= 12 ? 'PM' : 'AM'}',
              ),
              const SizedBox(width: 8),
              _InfoPill(
                icon:  Icons.event_seat_rounded,
                label: '${ride.availableSeats ?? 1} seat booked',
              ),
              const Spacer(),
              // Active ride CTA
              if (ride.status == 'upcoming')
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                      context, '/active-ride'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:        _C.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Track Ride',
                      style: TextStyle(
                        color:      _C.white,
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        _C.light.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.primary, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color:      _C.primary,
              fontSize:   11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}