import 'package:flutter/material.dart';
import '../../models/ride_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';

class TourDetailScreen extends StatelessWidget {
  final RideModel ride;
  const TourDetailScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final dt = ride.departureTime;
    final dateStr = AppHelpers.formatDateTime(dt);

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
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Tour Details',
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: const Center(
                            child: Icon(Icons.landscape_rounded,
                                size: 72, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${ride.startLocation} → ${ride.endLocation}',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              '${ride.captainRating} · ${ride.captainName}',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(dateStr,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          '${ride.availableSeats}/${ride.totalSeats} seats · ${ride.vehicleInfo}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Rs ${ride.suggestedFare.toStringAsFixed(0)} per seat',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                                context, '/fare-negotiate',
                                arguments: ride),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Request to Join',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                      ],
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

