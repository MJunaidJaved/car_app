import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/ride_model.dart';
import '../utils/helpers.dart';

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

  @override
  Widget build(BuildContext context) {
    final desiredFare = request['desiredFare'] ?? request['offered_price'];
    final passengers = request['passengers'] ?? 1;
    final distance = double.tryParse((request['distanceKm'] ?? '').toString());
    final distanceLabel = distance == null
        ? 'Distance unavailable'
        : '${distance.toStringAsFixed(1)} km away';
    final status = (request['status'] ?? 'open').toString().toUpperCase();
    final requestedAtStr = request['requestedAtDisplay'] ?? request['displayDateTime'] ?? request['requestedAt'];
    final vehicleType = (request['vehicleType'] ?? 'car').toString().toUpperCase();
    
    const primaryThemeColor = Color(0xFF1E293B);
    const accentColor = Color(0xFFE11D48);
    const routeColor = Color(0xFF0F172A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryThemeColor.withOpacity(0.06),
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
            color: accentColor.withOpacity(0.08),
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, Colors.orangeAccent],
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
                        color: accentColor.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _locationLabel(request['startLocation'], fallback: 'From'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: routeColor,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward_rounded,
                                color: accentColor, size: 24),
                          ),
                          Expanded(
                            child: Text(
                              _locationLabel(request['endLocation'], fallback: 'To'),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: routeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    if (requestedAtStr != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.watch_later_outlined, size: 18, color: accentColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppHelpers.formatDateTimeValue(requestedAtStr),
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
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                    ],

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildColorfulBadge(
                          icon: Icons.payments_outlined,
                          label: desiredFare == null ? 'Offer Fare' : 'Budget: Rs ${desiredFare.toStringAsFixed(0)}',
                          bgColor: Colors.green[50]!,
                          textColor: Colors.green[800]!,
                          iconColor: Colors.green[700]!,
                        ),
                        
                        _buildColorfulBadge(
                          icon: Icons.airline_seat_recline_normal_rounded,
                          label: '$passengers seat${passengers > 1 ? "s" : ""}',
                          bgColor: Colors.orange[50]!,
                          textColor: Colors.orange[800]!,
                          iconColor: Colors.orange[700]!,
                        ),
                        
                        _buildColorfulBadge(
                          icon: Icons.directions_car_rounded,
                          label: vehicleType,
                          bgColor: Colors.purple[50]!,
                          textColor: Colors.purple[800]!,
                          iconColor: Colors.purple[700]!,
                        ),
                        
                        _buildColorfulBadge(
                          icon: Icons.map_outlined,
                          label: distanceLabel,
                          bgColor: Colors.blue[50]!,
                          textColor: Colors.blue[800]!,
                          iconColor: Colors.blue[700]!,
                        ),
                      ],
                    ),

                    const Divider(height: 24, thickness: 1),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: accentColor.withOpacity(0.1),
                          child: Text(
                            request['customerName'] != null && request['customerName'].toString().isNotEmpty
                                ? AppHelpers.nameInitial(request['customerName'].toString(), fallback: 'P')
                                : 'P',
                            style: const TextStyle(
                              color: accentColor,
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
                                request['customerName']?.toString() ?? 'Customer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                request['city']?.toString() ?? 'Pakistan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        ElevatedButton(
                          onPressed: onDetailsTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
