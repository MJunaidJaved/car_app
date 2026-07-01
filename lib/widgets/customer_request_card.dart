import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/ride_model.dart';

class CustomerRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;
  final VoidCallback onDetailsTap;

  const CustomerRequestCard({
    super.key,
    required this.request,
    required this.onTap,
    required this.onDetailsTap,
  });

  String _locationLabel(dynamic value, {String fallback = ''}) {
    final label = RideModel.formatLocationLabel(value);
    return label.isEmpty ? fallback : label;
  }

  Widget _miniPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sage.withValues(alpha:0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.bark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desiredFare = request['desiredFare'];
    final distance = double.tryParse((request['distanceKm'] ?? '').toString());
    final distanceLabel = distance == null
        ? 'Distance unavailable'
        : '${distance.toStringAsFixed(1)} km away';
    final status = (request['status'] ?? 'open').toString().toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ivory),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_locationLabel(request['startLocation'], fallback: 'From')} -> ${_locationLabel(request['endLocation'], fallback: 'To')}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.bark,
              ),
            ),
            if ((request['pickupLocation'] ?? '')
                .toString()
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Exact pickup: ${_locationLabel(request['pickupLocation'])}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.sage,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if ((request['dropLocation'] ?? '')
                .toString()
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Exact drop: ${_locationLabel(request['dropLocation'])}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.sage,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$distanceLabel | ${desiredFare == null ? 'Offer your fare' : 'Budget Rs $desiredFare'}',
                    style: const TextStyle(
                      color: AppColors.moss,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: AppColors.bark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _miniPill((request['vehicleType'] ?? 'car').toString().toUpperCase()),
                _miniPill((request['rideMode'] ?? 'solo').toString().toUpperCase()),
                if ((request['city'] ?? '').toString().trim().isNotEmpty)
                  _miniPill(request['city'].toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tap Details to view request and send fare offer.',
                    style: TextStyle(
                      color: AppColors.sage,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: onDetailsTap,
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

