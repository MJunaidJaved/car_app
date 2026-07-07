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
  final VoidCallback? onDeleted; // ✅ Callback for delete

  const BookingCard({
    super.key,
    required this.deal,
    this.onDeleted,
  });

  Future<void> _callCaptain(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) return;
    final formattedPhone =
        cleanPhone.startsWith('92') ? cleanPhone : '92$cleanPhone';
    final url = 'https://wa.me/$formattedPhone';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ✅ DELETE BOOKING FUNCTION
  Future<void> _deleteBooking(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Booking?'),
        content: const Text(
          'Are you sure you want to delete this booking? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.deleteBooking(deal.id);

      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Booking deleted successfully');
        onDeleted?.call(); // ✅ Refresh parent
      }
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showSnackBar(
          context,
          'Failed to delete: $e',
          isError: true,
        );
      }
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

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.success;
      case 'started':
        return AppColors.primary;
      case 'completed':
        return AppColors.moss;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.sage;
    }
  }

  // Helper method to format currency
  String _formatCurrency(double amount) {
    return 'Rs ${amount.toStringAsFixed(0)}';
  }

  // ✅ Check if booking can be deleted (completed/cancelled only)
  bool get _canDelete {
    final status = deal.status.toLowerCase();
    return status == 'completed' || status == 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return FutureBuilder<RideModel?>(
      future: firestoreService.getRideById(deal.rideId),
      builder: (context, snapshot) {
        final ride = snapshot.data;

        // ✅ Get rideMode for Share/Solo label
        final isShareRide =
            (deal.rideMode ?? 'share').toString().toLowerCase() != 'solo';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge + Delete Button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _getStatusColor(deal.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        deal.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(deal.status),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // ✅ DELETE BUTTON (Only for completed/cancelled)
                    if (_canDelete)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteBooking(context),
                        tooltip: 'Delete booking',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    Text(
                      AppHelpers.formatDateTime(deal.createdAt),
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ✅ Bold Share/Solo label at the top
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      color: isShareRide
                          ? Colors.green[800]
                          : Colors.deepOrange[800],
                    ),
                  ),
                ),

                // Route Info
                if (ride != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ride.startLocation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 2, top: 2, bottom: 2),
                          child: Container(
                            width: 3,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ride.endLocation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Show exact pickup and drop locations
                        if ((ride.exactLocation != null &&
                                ride.exactLocation!.isNotEmpty) ||
                            (ride.exactDropLocation != null &&
                                ride.exactDropLocation!.isNotEmpty)) ...[
                          const SizedBox(height: 8),
                          if (ride.exactLocation != null &&
                              ride.exactLocation!.isNotEmpty)
                            Text(
                              'Exact pickup: ${ride.exactLocation}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (ride.exactDropLocation != null &&
                              ride.exactDropLocation!.isNotEmpty)
                            Text(
                              'Exact drop: ${ride.exactDropLocation}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        AppHelpers.formatDateTime(ride.departureTime),
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600),
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
                      _formatCurrency(deal.agreedFare),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),

                // Customer Accept Button - When captain has countered
                if (deal.status == 'pending' &&
                    deal.lastCounterBy == 'captain') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final firestoreService =
                              Provider.of<FirestoreService>(
                            context,
                            listen: false,
                          );
                          await firestoreService.confirmDeal(deal.id);
                          if (context.mounted) {
                            AppHelpers.showSnackBar(
                              context,
                              'Booking confirmed! Captain contact revealed.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppHelpers.showSnackBar(
                              context,
                              'Failed to confirm: $e',
                              isError: true,
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        'Accept Rs ${deal.agreedFare.toStringAsFixed(0)} & Confirm',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.moss,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                // Contact Actions - When confirmed or started
                if (deal.status == 'confirmed' || deal.status == 'started') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
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
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                deal.customerPhone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _callCaptain(deal.customerPhone),
                              icon: const Icon(Icons.call,
                                  color: AppColors.primary),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _openWhatsApp(deal.customerPhone),
                              icon:
                                  const Icon(Icons.chat, color: AppColors.moss),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Rate button for completed rides
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

                // Rating display if already rated
                if (deal.rating != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.goldStar.withValues(alpha: 0.1),
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
