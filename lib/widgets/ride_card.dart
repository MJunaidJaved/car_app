import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride_model.dart';
import '../providers/user_provider.dart';
import '../utils/app_colors.dart';
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
    final primaryThemeColor = AppColors.vehicleColor(ride.vehicleType);
    final secondaryAccent = AppColors.darkRoyalBlue;
    final routeColor = AppColors.deepNavy;
    final dateLabel = ride.displayDeparture.isNotEmpty
        ? ride.displayDeparture
        : AppHelpers.formatDateTime(ride.departureTime);
    final vehicleLabel = ride.displayVehicle.isNotEmpty
        ? ride.displayVehicle
        : ride.vehicleType.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryThemeColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: primaryThemeColor.withOpacity(0.06),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryThemeColor, secondaryAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: primaryThemeColor.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ride.startLocation.isEmpty ? 'From' : ride.startLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: routeColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: primaryThemeColor,
                            size: 26,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ride.endLocation.isEmpty ? 'To' : ride.endLocation,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: routeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (AppHelpers.hasDisplayValue(ride.exactLocation) ||
                      AppHelpers.hasDisplayValue(ride.exactDropLocation)) ...[
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (AppHelpers.hasDisplayValue(ride.exactLocation))
                          Text(
                            'From exact: ${ride.exactLocation}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (AppHelpers.hasDisplayValue(ride.exactDropLocation))
                          Text(
                            'To exact: ${ride.exactDropLocation}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(Icons.watch_later_outlined, size: 18, color: primaryThemeColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[850],
                          ),
                        ),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppHelpers.getRideTypeColor(ride.rideType).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppConstants.rideTypeLabels[ride.rideType] ?? ride.rideType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppHelpers.getRideTypeColor(ride.rideType),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24, thickness: 1),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildColorfulBadge(
                        icon: Icons.payments_outlined,
                        label: AppHelpers.formatCurrency(ride.suggestedFare),
                        bgColor: Colors.green[50]!,
                        textColor: Colors.green[800]!,
                        iconColor: Colors.green[700]!,
                      ),
                      
                      _buildColorfulBadge(
                        icon: Icons.airline_seat_recline_normal_rounded,
                        label: '${ride.availableSeats} of ${ride.totalSeats} seats',
                        bgColor: Colors.orange[50]!,
                        textColor: Colors.orange[800]!,
                        iconColor: Colors.orange[700]!,
                      ),
                      
                      _buildColorfulBadge(
                        icon: Icons.directions_car_rounded,
                        label: vehicleLabel,
                        bgColor: primaryThemeColor.withOpacity(0.1),
                        textColor: primaryThemeColor,
                        iconColor: primaryThemeColor,
                      ),
                    ],
                  ),

                  if (!isCaptainView || showActions) ...[
                    const Divider(height: 24, thickness: 1),
                    Row(
                      children: [
                        if (!isCaptainView) ...[
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: primaryThemeColor.withOpacity(0.1),
                            child: Text(
                              ride.captainName.isNotEmpty
                                  ? AppHelpers.nameInitial(ride.captainName, fallback: 'C')
                                  : 'C',
                              style: TextStyle(
                                color: primaryThemeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ride.captainName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: AppColors.goldStar),
                                    const SizedBox(width: 2),
                                    Text(
                                      ride.captainRating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (showActions)
                          Expanded(
                            flex: isCaptainView ? 1 : 0,
                            child: isCaptainView
                                ? _CaptainActions(ride: ride)
                                : _PassengerActions(ride: ride),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorfulBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: iconColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
    final fareController =
        TextEditingController(text: ride.suggestedFare.toString());
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
        AppHelpers.showSnackBar(context, 'Failed to send request',
            isError: true);
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
