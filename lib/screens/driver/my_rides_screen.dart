import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/ride_service.dart';
import '../../models/ride_model.dart';

class _C {
  static const primary   = Color(0xFF414833); // Primary Action
  static const dark      = Color(0xFF414833); // Header/Black
  static const accent    = Color(0xFF737A5D); // Accent
  static const black     = Color(0xFF414833);
  static const white     = Color(0xFFF5E3D2);
  static const textDark  = Color(0xFF414833);
  static const textMuted = Color(0xFF737A5D);
  static const bg        = Color(0xFFF5E3D2);
}

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});
  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'all';
  final _filters = ['all', 'active', 'completed', 'cancelled'];

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
          // Gradient header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, Color(0xFF414833)],
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
                            'My Rides',
                            style: TextStyle(
                              color:      _C.white,
                              fontSize:   20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Your posted rides',
                            style: TextStyle(
                              color:    Color(0xAAFFFFFF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Post new ride
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/post-ride'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color:        _C.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: _C.white, size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Filter chips
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding:         const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount:       _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final f          = _filters[i];
                      final isSelected = _selectedFilter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding:  const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color:        isSelected ? _C.white : _C.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? _C.white
                                  : _C.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            f[0].toUpperCase() + f.substring(1),
                            style: TextStyle(
                              color:      isSelected ? _C.primary : _C.white,
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Rides list
                Expanded(
                  child: FutureBuilder<List<RideModel>>(
                    future: Provider.of<RideService>(context, listen: false)
                        .getCaptainRides(userProvider.user!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: _C.white,
                          ),
                        );
                      }

                      final rides = snapshot.data ?? [];

                      if (rides.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_car_outlined,
                                color: _C.accent.withOpacity(0.4),
                                size:  64,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No rides posted yet',
                                style: TextStyle(
                                  color:      _C.textMuted,
                                  fontSize:   15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, '/post-ride'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color:        _C.primary,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Post Your First Ride',
                                    style: TextStyle(
                                      color:      _C.white,
                                      fontSize:   14,
                                      fontWeight: FontWeight.w800,
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
                        itemCount:   rides.length,
                        itemBuilder: (context, i) =>
                            _CaptainRideCard(ride: rides[i]),
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

class _CaptainRideCard extends StatelessWidget {
  final RideModel ride;
  const _CaptainRideCard({required this.ride});

  Color get _statusColor {
    switch (ride.status) {
      case 'active':    return const Color(0xFF4A7C59);
      case 'completed': return _C.primary;
      case 'cancelled': return const Color(0xFF414833);
      default:          return _C.textMuted;
    }
  }

  String get _statusLabel {
    switch (ride.status) {
      case 'active':    return 'Active';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default:          return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCBFA3), width: 1),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row — route + status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle,
                            color: Color(0xFF4A7C59), size: 10),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ride.from,
                            style: const TextStyle(
                              color:      _C.textDark,
                              fontSize:   15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                          width: 1.5, height: 16,
                          color: const Color(0xFFCCBFA3)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.circle,
                            color: _C.primary, size: 10),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ride.to,
                            style: const TextStyle(
                              color:      _C.textDark,
                              fontSize:   15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:        _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color:      _statusColor,
                    fontSize:   11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFCCBFA3)),
          const SizedBox(height: 20),

          // Bottom info row
          Row(
            children: [
              _InfoPill(
                icon:  Icons.access_time_rounded,
                label: '${ride.departureTime.hour}:${ride.departureTime.minute.toString().padLeft(2, '0')} ${ride.departureTime.hour >= 12 ? 'PM' : 'AM'}',
              ),
              const SizedBox(width: 10),
              _InfoPill(
                icon:  Icons.event_seat_rounded,
                label: '${ride.availableSeats ?? 0} seats',
              ),
              const Spacer(),
              Text(
                'Rs ${ride.offeredFare ?? '--'}',
                style: const TextStyle(
                  color:      _C.primary,
                  fontSize:   18,
                  fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        _C.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.black, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color:      _C.black,
              fontSize:   12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


