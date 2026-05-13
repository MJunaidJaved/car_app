import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride_model.dart';
import '../providers/user_provider.dart';
import '../utils/helpers.dart';

class RideCard extends StatelessWidget {
  final RideModel ride;
  final bool showActions;
  final bool isCaptainView;

  const RideCard({
    super.key,
    required this.ride,
    this.showActions = false,
    this.isCaptainView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Route
            Row(
              children: [
                Icon(
                  Icons.trip_origin,
                  color: AppHelpers.getRideTypeColor(ride.rideType),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.startLocation,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ride.endLocation,
                              style: TextStyle(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppHelpers.getRideTypeColor(ride.rideType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppConstants.rideTypeLabels[ride.rideType] ?? ride.rideType,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppHelpers.getRideTypeColor(ride.rideType),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Details Row
            Row(
              children: [
                // Captain Info
                if (!isCaptainView) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      ride.captainName.isNotEmpty ? ride.captainName[0].toUpperCase() : 'C',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.captainName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            ride.captainRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                ],

                // Seats
                _InfoChip(
                  icon: Icons.airline_seat_recline_normal,
                  text: '${ride.availableSeats} seats',
                ),
                const SizedBox(width: 8),

                // Fare
                _InfoChip(
                  icon: Icons.attach_money,
                  text: AppHelpers.formatCurrency(ride.suggestedFare),
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Time & Vehicle
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  AppHelpers.formatDateTime(ride.departureTime),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                if (ride.vehicleInfo != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    ride.vehicleInfo!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),

            // Tags
            if (ride.acceptsDelivery) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Accepts Delivery',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            if (showActions) ...[
              const SizedBox(height: 12),
              if (isCaptainView)
                _CaptainActions(ride: ride)
              else
                _PassengerActions(ride: ride),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.blue),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptainActions extends StatelessWidget {
  final RideModel ride;

  const _CaptainActions({required this.ride});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              if (context.mounted) {
                AppHelpers.showSnackBar(context, 'Ride marked complete (demo)');
              }
            },
            child: const Text('Mark Complete'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              if (context.mounted) {
                AppHelpers.showSnackBar(context, 'Ride cancelled (demo)');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}

class _PassengerActions extends StatelessWidget {
  final RideModel ride;

  const _PassengerActions({required this.ride});

  Future<void> _sendRequest(BuildContext context) async {
    final fareController = TextEditingController(text: ride.suggestedFare.toString());
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Ride Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fareController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Your Offer (Rs.)',
                prefixText: 'Rs. ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'Any special requirements...',
              ),
              maxLines: 2,
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
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        AppHelpers.showSnackBar(context, 'Please login', isError: true);
        return;
      }

      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Request sent (demo — no server)');
      }
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Failed to send request', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _sendRequest(context),
        icon: const Icon(Icons.send),
        label: const Text('Send Request'),
      ),
    );
  }
}
