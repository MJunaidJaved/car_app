import 'package:flutter/material.dart';

import '../services/deal_chat_service.dart';
import '../utils/app_colors.dart';

class CoRidersSection extends StatelessWidget {
  final String rideId;
  final String? currentUserId;

  const CoRidersSection({
    super.key,
    required this.rideId,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final chat = DealChatService();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chat.coRidersStream(rideId),
      builder: (context, snap) {
        final riders = snap.data ?? [];
        if (riders.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.moss.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_rounded, color: AppColors.moss, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Sharing this ride',
                    style: TextStyle(
                      color: AppColors.bark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...riders.map((r) {
                final name = r['firstName']?.toString() ?? 'Guest';
                final area = r['pickupArea']?.toString() ?? 'Along route';
                final boarded = r['boardingStatus'] == 'boarded';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$name · $area${boarded ? ' · boarded' : ''}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

