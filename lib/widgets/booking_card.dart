import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deal_model.dart';
import '../models/ride_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingCard extends StatelessWidget {
  final DealModel deal;

  const BookingCard({super.key, required this.deal});

  Future<void> _callCaptain(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _rateRide(BuildContext context) async {
    double rating = 5.0;
    final reviewController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your experience?'),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: AppColors.goldStar,
              ),
              onRatingUpdate: (value) {
                rating = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reviewController,
              decoration: const InputDecoration(
                labelText: 'Review (Optional)',
                hintText: 'Share your experience...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.rateDeal(
        deal.id,
        rating.toInt(),
        reviewController.text.isNotEmpty ? reviewController.text : '',
      );

      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Thank you for your rating!');
      }
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Failed to submit rating',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return FutureBuilder<RideModel?>(
      future: firestoreService.getRideById(deal.rideId),
      builder: (context, snapshot) {
        final ride = snapshot.data;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppHelpers.getStatusColor(deal.status)
                            .withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        deal.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppHelpers.getStatusColor(deal.status),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppHelpers.formatDateTime(deal.createdAt),
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Route Info
                if (ride != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.trip_origin,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.startLocation,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(ride.endLocation),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        AppHelpers.formatDateTime(ride.departureTime),
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 24),

                // Fare Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fare',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      AppHelpers.formatCurrency(deal.agreedFare),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),

                // Actions based on status
                if (deal.status == 'confirmed') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.primary.withValues(alpha:0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Captain Contact',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                deal.customerPhone,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _callCaptain(deal.customerPhone),
                          icon:
                              const Icon(Icons.call, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],

                if (deal.status == 'completed' && deal.rating == null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _rateRide(context),
                      icon: const Icon(Icons.star),
                      label: const Text('Rate This Ride'),
                    ),
                  ),
                ],

                if (deal.rating != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.goldStar.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.goldStar),
                        const SizedBox(width: 8),
                        Text(
                          'You rated: ${deal.rating!.toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

