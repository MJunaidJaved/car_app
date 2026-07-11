import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/notification_bell.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key});

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  List<RideModel> _tours = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadTours();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadTours(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTours({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final rides = await Provider.of<RideService>(context, listen: false)
          .findRides(type: 'tour');
      if (mounted) {
        setState(() {
          _tours = rides;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tours',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Live tour rides from captains',
                              style: TextStyle(
                                color: AppColors.cream,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      NotificationBell(
                        icon: Icons.notifications_outlined,
                        iconColor: AppColors.white,
                        backgroundColor: AppColors.white.withValues(alpha:0.15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _tours.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tour_outlined,
                                    size: 64,
                                    color: AppColors.moss.withValues(alpha:0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No tour rides posted yet.',
                                    style: TextStyle(
                                      color: AppColors.sage,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _loadTours(showLoading: false),
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: _tours.length,
                                itemBuilder: (context, i) {
                                  final ride = _tours[i];
                                  return _TourCard(
                                    ride: ride,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/tour-detail',
                                      arguments: ride,
                                    ),
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
}

class _TourCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onTap;

  const _TourCard({required this.ride, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha:0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ride.startLocation} -> ${ride.endLocation}',
              style: const TextStyle(
                color: AppColors.bark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${ride.captainName} - ${ride.availableSeats} seats left',
              style: const TextStyle(color: AppColors.sage, fontSize: 13),
            ),
            if ((ride.exactLocation ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Exact pickup: ${ride.exactLocation}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
            if ((ride.exactDropLocation ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Exact drop: ${ride.exactDropLocation}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rs ${ride.suggestedFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.moss,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.moss,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

